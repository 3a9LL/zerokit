#ifndef __DELAYEDWORKER_H_
#define __DELAYEDWORKER_H_

#include "globals.h"
#include "Poco/Thread.h"

/** ������ ����� ������������ ��� ���������� ���������� �� �������� � ���������� ������.

    ����� �� ���������� ���������� � �����, ������ �������� ��������� ����������������� ������� �� ����� � � ����������
    ������������ �� � ��������� ������.

    ����� �������� ���������� � ��������� ��������� ������� �� ����� �������.
*/
class DelayedWorker : Poco::Runnable
{
public:
    struct DelayedItem
    {
        Poco::UInt64 botId;
        Poco::UInt32 taskId;
        Poco::UInt32 taskGroupId;
        Poco::UInt8 tresId;
    };

    DelayedWorker(Globals* pGlobals);
    ~DelayedWorker();

    void addItem(DelayedItem& item);
    void signal() { _event.set(); }
    void run();

private:
    void processItems();

    Globals* _pGlobals;
    Poco::Thread _thread;
    std::list<DelayedItem> _items;
    Poco::FastMutex _mutex;
    Poco::Event _event;
    static char query[1024];
};

#endif // __DELAYEDWORKER_H_
