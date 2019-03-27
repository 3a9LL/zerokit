#ifndef __ELOCKER_SERVERNETCOMM_H_
#define __ELOCKER_SERVERNETCOMM_H_

#include <Windows.h>

class LockerServerNetcomm
{
public:
    enum Type {
        GetInfo = 0, // ��������� �� ������� ���������� � �������.
        SendVoucher = 1, // �������� ���� �������.
        CheckStatus = 2, // ������ �������.
        LoadRes = 3,
    };

    LockerServerNetcomm();
    ~LockerServerNetcomm();

    bool makeTransaction(int type);
    void nextHost();

    zgui_DeclareSingleton(LockerServerNetcomm)

private:
    bool parseHTTPResponse(const zgui::MemoryBlock& http, zgui::MemoryBlock& data);
    static const wchar_t* const _httpRequest;
    static const wchar_t* const _httpResRequest;
    zgui::String _host;
    int _port;
    //Random _random;
};

#endif // __ELOCKER_SERVERNETCOMM_H_
