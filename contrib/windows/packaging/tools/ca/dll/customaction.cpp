
#include "customaction.h"

static HRESULT CheckIfCurrentProcIsElevated(BOOL* pbElevated)
{
    HRESULT hr = S_OK;
    HANDLE hToken = NULL;
    TOKEN_ELEVATION tokenElevated = { };
    DWORD cbToken = 0;
    static char szError[LOG_BUFFER_SIZE];

    if (!::OpenProcessToken(::GetCurrentProcess(), TOKEN_QUERY, &hToken))
    {
        return E_ABORT;
    }

    if (::GetTokenInformation(hToken, TokenElevation, &tokenElevated, sizeof(TOKEN_ELEVATION), &cbToken))
    {
        *pbElevated = (0 != tokenElevated.TokenIsElevated);
    }
    else
    {
        DWORD er = ::GetLastError();
        if (::FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NULL, er, 0, szError, LOG_BUFFER_SIZE, NULL)>0)
            Log("ERROR(%d): %s", er, szError);
        hr = HRESULT_FROM_WIN32(er);
        *pbElevated = FALSE;
    }

    CloseHandle(hToken);

    return hr;
}

/*
 * CheckElevatedCustomAction - entry point for CheckElevatedCustomAction Custom Action
 */
extern "C" UINT WINAPI CheckElevatedCustomAction(MSIHANDLE hInstall)
{
    HRESULT hr = S_OK;
    DWORD er = ERROR_SUCCESS;
    BOOL bElevated = FALSE;

    hr = initialize(hInstall, "CheckElevatedCustomACtion");
    if (FAILED(hr))
    {
        return finalize(ERROR_INSTALL_FAILURE);
    }

    hr = CheckIfCurrentProcIsElevated(&bElevated);
    if (bElevated)
    {
        Log("Running with elevated privilege");
    }
    else
    {
        if (FAILED(hr))
        {
            Log("Running without elevated privilege (0x%x)", hr);
        }
        else
        {
            Log("Running without elevated privilege");
        }

        PMSIHANDLE hError = ::MsiCreateRecord(2);
        if (SUCCEEDED(hError))
        {
            ::MsiRecordSetInteger(hError, 1, msierrWrongPrivilege);
            ::MsiRecordSetInteger(hError, 2, hr);
            ::MsiProcessMessage(hInstall, INSTALLMESSAGE(INSTALLMESSAGE_ERROR|MB_OK), hError);
            ::MsiCloseHandle(hError);
        }
        hr = E_ACCESSDENIED;
    }

    if (FAILED(hr))
    {
        er = ERROR_INSTALL_FAILURE;
    }

    return finalize(er);
}
