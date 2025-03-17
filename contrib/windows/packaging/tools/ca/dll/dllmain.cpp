
#include "customaction.h"

static BOOL bInitialized = FALSE;
static MSIHANDLE hInstall;
static MSIHANDLE hDatabase;
static PCSTR szCustomActionName;

extern "C" PCSTR WINAPI GetCustomActionName()
{
    return szCustomActionName;
}

extern "C" MSIHANDLE WINAPI GetInstallHandle()
{
    return hInstall;
}

extern "C" BOOL WINAPI isInitialized()
{
    return bInitialized;
}

extern "C" HRESULT WINAPI initialize(MSIHANDLE hInst, PCSTR szName)
{
    HRESULT hr = S_OK;

    bInitialized = TRUE;
    hInstall = hInst;
    hDatabase = ::MsiGetActiveDatabase(hInstall);
    szCustomActionName = szName;

    return hr;
}

extern "C" UINT WINAPI finalize(UINT iRet)
{
    if (hDatabase)
    {
        ::MsiCloseHandle(hDatabase);
    }

    hDatabase = hInstall = (MSIHANDLE)NULL;
    bInitialized = FALSE;
    szCustomActionName = NULL;

    return iRet;
}

extern "C" BOOL WINAPI DllMain(HINSTANCE hInstanceDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    return TRUE;
}
