#ifndef __SHARED_CONFIG_H_
#define __SHARED_CONFIG_H_

#define TYPE_STRING            0x01
#define TYPE_SIZET            0x02
#define TYPE_UINT32            0x03
#define TYPE_UINT16            0x04
#define TYPE_STRING_PATH    0x05
#define TYPE_BOOLEAN        0x06
#define TYPE_STRING_ARRAY    0x07
#define TYPE_CMDLINE        0x80    // ������� ������� ��������� ������� � ���, ��� �������� ��������� ������ ���� � ��������.


typedef void* (*FnConfigHandler)(char* name, int* pValueType);
typedef char* (*Fnline_parser_conf)(char** pItr, char* end);
typedef void (*Fnline_parser_conf_done)();

// ������� ��� ��������� ����� Java-���������������� ������.
char* line_parser_conf(char** pItr, char* end);
void line_parser_conf_done();

// ������� ��� ��������� ����� INI-���������������� ������.
char* line_parser_ini(char** pItr, char* end);
void line_parser_ini_done();


int config_load_from_buffer(char* data, size_t len, Fnline_parser_conf fnLineParser, Fnline_parser_conf_done fnLineParserDone, FnConfigHandler fnConfigHandler);
int config_load(const char* confPath, Fnline_parser_conf fnLineParser, Fnline_parser_conf_done fnLineParserDone, FnConfigHandler fnConfigHandler);

#define MAX_OPTIONS 16

#define OPT_FLAG_OPTIONAL    0x00 // ������������ ��������
#define OPT_FLAG_REQUIRED    0x01 // ������������ ��������.
#define OPT_FLAG_BOOLEAN    0x02 // �������� �������, �. �. ����� ��� ������������� ��� �������������. 
                                 // ��� ��������� ������� �����, ���� OPT_FLAG_REQUIRED ������������.

typedef void (*FnPrintUsage)();

#pragma pack(push, 1)

typedef struct cmd_option_helper
{
    char* shortLongName[2];
    char* description;
    char* badDescription;
    uint8_t flags;
    uint8_t valueType;
    void* pValue;
    int arraySize;            // ������ ���������� �������� ���������� ��������� � �������, ���� ��� ��������� TYPE_STRING_ARRAY.
} cmd_option_helper_t, *pcmd_option_helper_t;

typedef struct cmd_line_info
{
    int optionsCount; // ������������ ��������� ���������� ����� � ��������� ������.
    cmd_option_helper_t cmdOptionHelpers[MAX_OPTIONS];
} cmd_line_info_t, *pcmd_line_info_t;

#pragma pack(pop)

/* ������ ���������� ��������� cmd_option_helper_t

// ��������� ��������� ����������� ��� ��������� ���������.

typedef struct cmd_options
{
    char* binaryFile;        
    uint16_t heapSize;    
    uint64_t stackSize;    
    int debug;
} cmd_options_t, *pcmd_options_t;

// ������ ���������� ���������, ������� ����� ��������� �������� ���������� ��������� ������
cmd_options_t gCmdOptions;

// ...

// ��������� ���������� ��������� ���������� � ��������������� � ��������
cmd_line_info_t cmdLineInfo = {4,
{
 {{"h", "heap"}, "require positive integer", OPT_FLAG_OPTIONAL, TYPE_UINT16, (void*)&gCmdOptions.heapSize},
 {{"s", "stack"}, "require positive integer", OPT_FLAG_OPTIONAL, TYPE_UINT16, (void*)&gCmdOptions.stackSize},
 {{"d", "debug"}, "", OPT_FLAG_BOOLEAN, TYPE_BOOLEAN, (void*)&gCmdOptions.debug},
 {{"f", "file"}, "", OPT_FLAG_REQUIRED, TYPE_STRING, (void*)&gCmdOptions.binaryFile}
}
};

// ...

// ������������ ��������� ��������� ������
if (config_parse_cmdline(argc, argv, &cmdLineInfo, print_usage) != 0) {
    return 1;
}
*/
int config_parse_cmdline(int argc, char** argv, pcmd_line_info_t pCmdLineInfo, const char* appVersion);

#endif // __SHARED_CONFIG_H_
