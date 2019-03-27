#ifndef __GLOBAL_CONFIG_H_
#define __GLOBAL_CONFIG_H_

typedef struct _global_config
{
	char* socketPath;		// ���� � ����� ������
	char* syslogIdent;		// ������������� ��� syslog
	char* filesPathPrefix;      // 
	uint16_t logWarnings;       // ���� ������ � ��� ��������������� ���������
	uint16_t logInfos;          // ���� ������ � ��� �������������� ���������
	char* dbHost;			// ���� ����
	uint16_t dbPort;            // ���� ����
	char* dbName;			// ��� ��
	char* dbUser;			// ��� ������������ ��� ������� � ��
	char* dbPassword;		// ������ ������������
	size_t dbPoolSize;		// ������ ���� ���������� � �����
	size_t minPoolSize;		// ����������� ������ �����.
	size_t maxPoolSize;		// ������������ ������ �����.
	size_t httpPostBodySize;	// ������ ���� ������ ��� ���� POST �������
	uint16_t tasksPerConn;      // ������������ ���������� ���������� ������� �� ���� ����������.
	char* geoipDataFile;		// ���� � ����� ������ GeoIP
} global_config_t;

#endif // __GLOBAL_CONFIG_H_
