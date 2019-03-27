#ifndef __GLOBAL_CONFIG_H_
#define __GLOBAL_CONFIG_H_

typedef struct _global_config
{
	char* socketPath;		// ���� � ����� ������
	char* syslogIdent;		// ������������� ��� syslog
	unsigned short logWarnings;	// ���� ������ � ��� ��������������� ���������
	unsigned short logInfos;	// ���� ������ � ��� �������������� ���������
	char* dbHost;			// ���� ����
	unsigned short dbPort;	// ���� ����
	char* dbName;			// ��� ��
	char* dbUser;			// ��� ������������ ��� ������� � ��
	char* dbPassword;		// ������ ������������
	size_t dbPoolSize;		// ������ ���� ���������� � �����
	size_t requestPoolSize;	// ������ ���� ������ ��������
	size_t httpPostBodySize;	// ������ ���� ������ ��� ���� POST �������
	char* geoipDataFile;		// ���� � ����� ������ GeoIP
} global_config_t;


#endif // __GLOBAL_CONFIG_H_
