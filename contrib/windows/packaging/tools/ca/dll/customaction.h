
#if _WIN32_MSI < 150
#define _WIN32_MSI 150
#endif

#include <windows.h>
#include <msiquery.h>
#include <strsafe.h>

#define msierrWrongPrivilege                      25000
#define msierrUACNotSupported                     25001
#define msierrNotEnoughtPrivilege                 25002

#define LOG_BUFFER_SIZE                           512

#define CloseHandle(x) if (x) { ::CloseHandle(x); x = NULL; }

// dllmain.cpp
extern "C" HRESULT WINAPI initialize(MSIHANDLE hInst, PCSTR szCustomActionName);
extern "C" UINT WINAPI finalize(UINT iRet);
extern "C" MSIHANDLE WINAPI GetInstallHandle();
extern "C" BOOL WINAPI isInitialized();
extern "C" PCSTR WINAPI GetCustomActionName();

// log.cpp
extern "C" VOID WINAPIV Log(PCSTR fmt, ...);
