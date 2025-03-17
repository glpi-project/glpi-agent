
#include "customaction.h"

extern "C" VOID WINAPIV Log(PCSTR fmt, ...)
{
    static char szFmt[LOG_BUFFER_SIZE];
    static char szLog[LOG_BUFFER_SIZE];
    static BOOL bLogging = FALSE;

    if (isInitialized() && !bLogging)
    {
        bLogging = TRUE;

        HRESULT hr = StringCchPrintfA(szFmt, LOG_BUFFER_SIZE, "%s: %s", GetCustomActionName(), fmt);
        if (FAILED(hr))
            return;

        va_list args;
        va_start(args, fmt);
        hr = ::StringCchVPrintfA(szLog, LOG_BUFFER_SIZE, szFmt, args);
        va_end(args);
        if (FAILED(hr))
            return;

        PMSIHANDLE hLog = ::MsiCreateRecord(1);
        if (SUCCEEDED(hLog))
        {
            ::MsiRecordSetStringA(hLog, 0, szLog);
            ::MsiProcessMessage(GetInstallHandle(), INSTALLMESSAGE_INFO, hLog);
            ::MsiCloseHandle(hLog);
        }

        bLogging = FALSE;
    }
}
