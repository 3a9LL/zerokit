.586
.MODEL FLAT, STDCALL
OPTION CASEMAP:NONE

.code

; ��������:
; 1. ���� ��������� ������� � IDT ������� � ��������� ���������� ���� Present, � ������������ GateType ~ Interrupt | Tarp
; 2. ��������� ����� ISR
; 3. ����������� ���������� ���� � ������ ��������� MZ, ����������� ����� �� ������� ������� ��������� ������ (80000000h)
; 4. ��� ����������� ��������� MZ, ��������� ������� ��������� PE
; 5. ��� ����������� ��������� PE, ���������� ����� ����

GetModuleBaseFromIDTEntry PROC C index:DWORD
	local idtr:FWORD
  
	cli
	sidt idtr                        ; ��������� ���������� �������� IDTR
	sti
   
	movzx ecx, word ptr idtr         ; ��������� ����� IDT
	shr ecx, 3                       ; �������� ���������� ��������� �������
	dec ecx
	
	cmp ecx, index			         ; ��������� �������������� IDT-�������
	jbe base_not_found                ; �� ��������� -> �������� �������

	mov ebx, index
	shl ebx, 3
	add ebx, dword ptr idtr + 2     ; ��������� ����� ���������� IDT-��������
	
	cmp byte ptr [ebx + 5], 80h      ; ��������� ��� P (��� �����������)
	jz base_not_found                ; ����� -> ��������� � ���������� IDT-��������
	mov al, byte ptr [ebx + 5]       ; ����� � al ����� GateType � ��������� ������� ������� � ������� ����� (Interrupt Gate, Trap Gate)
	and al, 06h
	cmp al, 06h
	jne base_not_found               ; �� �������� -> ��������� � ���������� IDT-��������
   
	movzx edx, word ptr [ebx + 6]
	shl edx, 16
	mov dx, word ptr [ebx]
	and dx, 0F000h
	mov ebx, edx

down_page:
	cmp edx, 80000000h
	jbe base_not_found
	cmp word ptr [edx], 5A4Dh        ; ��������� ��������� 'MZ'
	jne jump_down_to_page
	sub eax, eax
	mov eax, dword ptr [edx + 3Ch]
	cmp word ptr [edx + eax], 4550h  ; ��������� ��������� 'PE'
	jz base_found
jump_down_to_page:
	sub edx, 1000h
	jmp down_page
   
base_not_found:
   xor edx, edx

base_found:
   mov eax, edx
   ret
GetModuleBaseFromIDTEntry ENDP

END