typedef UINT32 (*FnCalcHash)(PUCHAR name, size_t sz);
/*
��������:

	������ ���� ������� ������� ��� ������� � PE ��������.

	����� ������������ ����� ����� ���������� ��������� ������� ������������� ��� ����� ����������:
	 * CALC_HASH(data, size) - ��������� 32-������ ��� ��� ��������� ������.
	 * DW_LDR_CONST - ��������-��������� ��������  PEB.Ldr
	 * DW_IN_MEMORY_ORDER_MODULE_LIST_CONST - ��������-��������� �������� PEB_LDR_DATA.InMemoryOrderModuleList.
	 * DW_DLL_BASE_CONST - ��������-��������� ��������  LDR_DATA_TABLE_ENTRY.InInitializationOrderLinks.
	 * DW_FULL_DLL_NAME - ��������-��������� �������� LDR_DATA_TABLE_ENTRY.FullDllName.
   
�����������:

   * shared_code/types.h
*/

#ifdef USE_PE_GET_USER_MODE_MODULE_BASE 
/**	������� ��������� ���� ������, ������������ � user-mode ������.

	����������� ������ ���������� ������ KeStackAttachProcess/KeUnstackDetachProcess.
*/
PVOID pe_get_user_mode_module_base(PEPROCESS pep, const char* name)
{
	PLIST_ENTRY pDllListHead = NULL;
	PLIST_ENTRY pDllListEntry = NULL;
	PUNICODE_STRING dllName;
	NTSTATUS ntStatus;
	PROCESS_BASIC_INFORMATION procInfo;
	ULONG retLen;
	UINT32 moduleHash;
	PVOID moduleBase = NULL;
	ANSI_STRING aName;
	UNICODE_STRING uName;
    PUCHAR pPebLdr;
	USE_GLOBAL_BLOCK

	RTL_INIT_ANSI_STRING(&aName, name);
	RTL_ANSI_STRING_TO_UNICODE_STRING(&uName, &aName, TRUE);
	moduleHash = CALC_HASH((PUCHAR)uName.Buffer, uName.Length);
	RTL_FREE_UNICODE_STRING(&uName);

    pPebLdr = *(PUCHAR*)((PUCHAR)pep + DW_PEB_CONST) + DW_LDR_CONST;
    
    if (!MM_IS_ADDRESS_VALID(pPebLdr) || !MM_IS_ADDRESS_VALID(*(PUCHAR*)pPebLdr + DW_IN_MEMORY_ORDER_MODULE_LIST_CONST))
        return NULL;

    pDllListEntry = pDllListHead = *(PVOID*)(*(PUCHAR*)pPebLdr + DW_IN_MEMORY_ORDER_MODULE_LIST_CONST);

	if (MM_IS_ADDRESS_VALID(pDllListHead)) {
        do {
			dllName = (PUNICODE_STRING)((PUCHAR)pDllListEntry + DW_FULL_DLL_NAME_CONST);

            if (dllName != NULL && dllName->Buffer != NULL && CALC_HASH((PUCHAR)dllName->Buffer, dllName->Length) == moduleHash) {
				moduleBase = *(PVOID*)((PUCHAR)pDllListEntry + DW_DLL_BASE_CONST);
				break;
			}
			pDllListEntry = pDllListEntry->Flink;
		} while (MM_IS_ADDRESS_VALID(pDllListEntry) && (pDllListEntry != pDllListHead));
	}

	return moduleBase;
}
#endif // USE_PE_GET_USER_MODE_MODULE_BASE 


/** ������ ������� ����� ������������ ��� ��� ������ �������������� �������� � user-mode �������, ��� � � kernel-mode.

	������ ��� user-mode ������ ������������������:

		KeStackAttachProcess(eProcess, &apcState);

		userModeFunc = pe_find_export_by_hash(moduleBase, funcHash);

		KeUnstackDetachProcess(&apcState);

	� �������� ������ ��� �������� ���-�������� ������������
*/
#ifdef USE_PE_FIND_EXPORT_BY_HASH 
PVOID pe_find_export_by_hash(PUCHAR moduleBase, UINT32 hashVal, FnCalcHash fnCalcHash)
{
	PIMAGE_DOS_HEADER dosHdr = (PIMAGE_DOS_HEADER)moduleBase;
	PIMAGE_NT_HEADERS ntHdr = (PIMAGE_NT_HEADERS)(moduleBase + dosHdr->e_lfanew);
	PIMAGE_EXPORT_DIRECTORY pExports;
	UINT32 i, NumberOfFuncNames;
	PUINT32 AddressOfNames, AddressOfFunctions;
	UINT16 index;
	PVOID apiVA = NULL;
	USE_GLOBAL_BLOCK;

	pExports = (PIMAGE_EXPORT_DIRECTORY)(moduleBase + ntHdr->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);

	NumberOfFuncNames = pExports->NumberOfNames;
	AddressOfNames = (PUINT32)(moduleBase + pExports->AddressOfNames);

	for (i = 0; i < NumberOfFuncNames; ++i) {
		PCHAR pThunkRVAtemp = (PCHAR)(moduleBase + *AddressOfNames);
		if (pThunkRVAtemp != NULL) {
			if (fnCalcHash(pThunkRVAtemp, 0) == hashVal) {
				UINT16* AddressOfNameOrdinals = (UINT16*)(moduleBase + pExports->AddressOfNameOrdinals);
				AddressOfNameOrdinals += (UINT16)i;
				index = *AddressOfNameOrdinals;
				AddressOfFunctions = (UINT32*)(moduleBase +  pExports->AddressOfFunctions);
				AddressOfFunctions += index;
				apiVA = (PVOID)(moduleBase + *AddressOfFunctions);
				break;
			}
		}
		AddressOfNames++;
	}

	return apiVA;
}
#endif // USE_PE_FIND_EXPORT_BY_HASH
