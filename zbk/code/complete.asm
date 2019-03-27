org 200h

; ������ ������ � ��� ����� ���������, �. �. � ������ ��������� ������������� ������������ ������ ��������.
times 508 - ($ - $$) db 0x90

jmp    l_start

dw 0xAA55

; ������ ������ �������� MBR/VBR ��� � �� ���� �������� Stage0-���������� � ������������ �������� ������:
; 1. �������� � ���������� Stage1-����������.
; 2. �������� ���������� �� Stage1-���������.
; 3. � ������ ������������� �����-���� ������, �������� ���������� �� ��������� ��������� ������� (MBR/VBR).

; ����� ��������� ������ ��� �������� Stage1-������.
jmp preload
l_dap:
dap_size     db 10h
dap_reserved db 0
dap_sectors  dw 1
dap_buff_lo  dw 0
dap_buff_hi  dw 0
dap_start_lo dd 0 ; ���� �� ����� ��������� ������� ����� �������� �������� �� ������������� VBR.
dap_start_hi dd 0 ; 

l_dap_preload:
dap_pre_size     db 10h
dap_pre_reserved db 0
dap_pre_sectors  dw 16 ; 16 �������� ��� �����������.
dap_pre_buff_lo  dw 0x9090
dap_pre_buff_hi  dw 0
dap_pre_start_lo dd 0 ; ���� �� ����� ��������� ������� ����� �������� �������� �� ���� ������ �������.
dap_pre_start_hi dd 0 ; 

preload:
pushad ; ��������� ��������.
push   ds
push   es

; ��������������� �� ����� ������������ VBR-������.
mov    si, l_dap_preload
add    si, bp
mov    dl, [cs:bp + 0x40] ; dl - ����� ������������ �����.
mov    [si + 4], bp
; ������ ������ �������� ������ ����� ����������� FAT32-�����������.
mov    ah, 2
call   f_read_write_sectors
jc     halt_loader

mov    ax, bp
shr    ax, 4
mov    ds, ax
push   ax
push   after_preload
retf

l_start:
pushad ; ��������� ��������.
push   ds
push   es

; �������� ������������ VBR �� ������ 0x7C00.
cld
push   cs
pop    ds
xor    ax, ax
mov    es, ax
xor    si, si
mov    di, 0x7C00
mov    cx, 512
rep    movsb

after_preload:
; ��������� ���������� �� ��� �������� 13-�� ����������, ���� ��, �� �������� �� ��������� �������.
mov    bx, [ss:0x4C]
mov    es, [ss:0x4E]
cmp    dword [es:bx + 2], 0x74B0D47F ; ��������� ��������� ������� ������ INT 13h �����������.
jz     l_boot_active

; ���������� ���� �������.
l_decryptor:
mov    di, $ ; �������� �� ������ �������.
mov    dx, di
add    dx, 64
mov    cx, 7 ; ����� ���������� ��������� ��������.
shl    cx, 9 ; � cx ���������� ������ ���� �������.
sub    cx, 2 + 6 * 4
mov    si, 1536 + 2 + 6 * 4
xor    ebx, ebx ; � ebx ����� ������ crc32 ��� �������������� ������ �� ����������� ��������� 4 ������.
l_decrypt:
mov    al, [si] ; ��������� ��������� ���� ���� ������� � al.
xor    al, [cs:di] ; XOR-�� � ������ �����.
mov    [si], al ; ���������� ������������� ���� �������.
cmp    cx, 4
jle    skip_hash ; ��������� 4 ����� �������� ���-��������, ������� �� ������ �����������.
rol    ebx, 7
xor    bl, al
skip_hash:
inc    di ; ����������� ������� ������ �����.
inc    si ; ����������� ������� � ���� �������.
cmp    di, dx
jne     l_next_byte
sub    di, 64 ; ��������� �� ������ �����.
l_next_byte:
loop   l_decrypt

; ��������� ����������� ����� �������.
sub    si, 4
cmp    ebx, [si]
jne    l_boot_active

; �������� ���������� �������
call 0x600

l_boot_active:
push   cs
pop    ds
; ��������������� �� ����� ������������ VBR-������.
mov    si, l_dap
mov    dl, [cs:0x24] ; dl - ����� ������������ �����.
cmp    dl, 0x87
jb     normal_val
mov    dl, [cs:0x40] ; dl - ����� ������������ �����.
normal_val:
mov    [si + 6], cs

mov    ax, ds
shl    ax, 4
add    ax, si
sub    ax, 1024
cmp    ax, 0x7C02
jne    far_execution

; ��������� VBR ��������� ������ 15 �������� �� ����������� �������, ������� ��� � hiddenSectors ������� ������������ ��������.
; ��� ���� ��� � �� ������ 0x7E00
; � ���� ������ ����� ������� VBR � ����� �� ������ 0x7C00 � �������� ��� hiddenSectors, ���� ��� �� ������ l_dap.
mov    ah, 2
call   f_read_write_sectors
jc     halt_loader
mov    eax, [si + 8]
mov    [cs:0x1C], eax

far_execution:
mov    ah, 3
call   f_read_write_sectors
jc     halt_loader ; ���� �������� �����-�� ������, �� �������� � ��������� �������.
pop    es
pop    ds
popad ; ��������������� ��������.
mov    dl, [cs:0x24] ; dl - ����� ������������ �����.
jmp    0x0000:0x7C00 ; ������� ���������� ������������� ����������.
halt_loader:
hlt

; si - �������� �� DAP
; �����, ����� ds �������� ������ ��������, ������ �������� si ����� ��������� ������ �� DAP.
f_read_write_sectors:
pushad
; ��������� ����� �����.
mov    bp, dx
; setup read segment
push   word [si + 6] ; dap_st1_buff_hi
pop    es
; if read area below that 504mb use CHS enforcement. This needed for compatibility with some stupid BIOSes
push   ax
xor    eax, eax
cmp    dword [si + 12], eax ; dap_st1_start_hi
jnz    l_check_lba
cmp    dword [si + 8], 504 * 1024 * 2 ; dap_st1_start_lo
jb     l_chs_mode
l_check_lba:
; ����������� ��������� LBA ������.
mov    ah, 0x41
mov    bx, 0x55AA
int    0x13
jc     l_chs_mode
cmp    bx, 0xAA55
jnz    l_chs_mode
test   cl, 1
jz     l_chs_mode
; ������������� LBA ���������.
l_lba_mode:
pop    ax
or     ah, 0x40
;mov    si, l_dap
;mov    ah, 0x43
mov    dx, bp
jmp    l_read_write
l_chs_mode: 
; get drive geometry
mov    ah, 0x08
mov    dx, bp
push   es
int    0x13
pop    es
; if get geometry failed, then try to use LBA mode
jc l_lba_mode
; ����������� LBA � CHS.
and    cl, 0x3F
inc    dh
movzx  ecx, cl ; ecx - max_sect
movzx  edi, dh ; esi - max_head
mov    eax, [si + 8] ; dap_st1_start_lo
xor    edx, edx
div    ecx
inc    dx
mov    cl, dl
xor    dx, dx
div    edi
mov    dh, dl
mov    ch, al
shr    ax, 0x02
and    al, 0xC0
or     cl, al
pop    ax
mov    al, [si + 2] ; dap_st1_sectors
;mov    ah, 3
mov    bx, bp ; ��������� ����� �����.
mov    dl, bl
mov    bx, [si + 4] ; dap_st1_buff_lo
l_read_write:
push   es
int    0x13
pop    es
popad
ret

times 1022 - ($ - $$) db 0x90

dw 0xAA55

file "..\bin\module.bin"

nonalign_end_of_zbk:

times 4608 - ($ - $$) db 0x90

unused dw ($ - nonalign_end_of_zbk)