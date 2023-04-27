/*
 *  ---------------------------------------------------------------------------
 *  GLPI-AgentMonitor.cpp
 *  Copyright (C) 2023 Leonardo Bernardes (redddcyclone)
 *  ---------------------------------------------------------------------------
 * 
 *  LICENSE
 * 
 *  This file is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at your
 *  option) any later version.
 *
 *
 *  This file is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software Foundation,
 *  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA,
 *  or see <http://www.gnu.org/licenses/>.
 * 
 *  ---------------------------------------------------------------------------
 * 
 *  @author(s) Leonardo Bernardes (redddcyclone)
 *  @license   GNU GPL version 2 or (at your option) any later version
 *             http://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html
 *  @link      http://www.glpi-project.org
 *  @since     2023
 * 
 *  ---------------------------------------------------------------------------
 */


//-[LIBRARIES]-----------------------------------------------------------------

#pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")
#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "version.lib")
#pragma comment(lib, "Winhttp.lib")


//-[DEFINES]-------------------------------------------------------------------

#define SERVICE_NAME L"GLPI-Agent"
#define USERAGENT_NAME L"GLPI-AgentMonitor"


//-[INCLUDES]------------------------------------------------------------------

#include <vector>
#include <windows.h>
#include <winhttp.h>
#include <shellapi.h>
#include <CommCtrl.h>
#include <gdiplus.h>
#include "framework.h"
#include "resource.h"


//-[GLOBALS AND OTHERS]--------------------------------------------------------

using namespace std;

// Main window message processing callback
LRESULT CALLBACK DlgProc(HWND, UINT, WPARAM, LPARAM);

// App instance
HINSTANCE hInst;

// WinHTTP connection and session handles
HINTERNET hSession, hConn;

// Runtime variables
BOOL glpiAgentOk = true;
BOOL running = false;

// GDI+ related
Gdiplus::GdiplusStartupInput gdiplusStartupInput;
ULONG_PTR gdiplusToken;

// Taskbar icon identifier
NOTIFYICONDATA nid = { sizeof(nid) };
// Taskbar icon interaction message ID
UINT const WMAPP_NOTIFYCALLBACK = WM_APP + 1;

// Dynamic text colors
COLORREF colorSvcStatus = RGB(0, 0, 0);

// Global string buffer
WCHAR szBuffer[256];
DWORD dwBufferLen = sizeof(szBuffer) / sizeof(WCHAR);


//-[APP FUNCTIONS]-------------------------------------------------------------

// Load resource embedded PNG file as a bitmap 
BOOL LoadPNGAsBitmap(HMODULE hInstance, LPCWSTR pName, LPCWSTR pType, HBITMAP *bitmap) 
{
    Gdiplus::Bitmap* m_pBitmap;

    HRSRC hResource = FindResource(hInstance, pName, pType);
    if (!hResource)
        return false;
    DWORD imageSize = SizeofResource(hInstance, hResource);
    if (!imageSize)
        return false;
    HGLOBAL tempRes = LoadResource(hInstance, hResource);
    if (!tempRes)
        return false;
    const void* pResourceData = LockResource(tempRes);
    if (!pResourceData)
        return false;

    HGLOBAL m_hBuffer = GlobalAlloc(GMEM_MOVEABLE, imageSize);
    if (m_hBuffer) {
        void* pBuffer = GlobalLock(m_hBuffer);
        if (pBuffer) {
            CopyMemory(pBuffer, pResourceData, imageSize);
            IStream* pStream = NULL;
            if (CreateStreamOnHGlobal(m_hBuffer, FALSE, &pStream) == S_OK) {
                m_pBitmap = Gdiplus::Bitmap::FromStream(pStream);
                pStream->Release();
                if (m_pBitmap) {
                    if (m_pBitmap->GetLastStatus() == Gdiplus::Ok) {
                        m_pBitmap->GetHBITMAP(0, bitmap);
                        return true;
                    }
                    delete m_pBitmap;
                    m_pBitmap = NULL;
                }
            }
            m_pBitmap = NULL;
            GlobalUnlock(m_hBuffer);
        }
        GlobalFree(m_hBuffer);
        m_hBuffer = NULL;
    }
    return false;
}

// Shows a window and force it to appear over all others
VOID ShowWindowFront(HWND hWnd, int nCmdShow) 
{
    ShowWindow(hWnd, nCmdShow);
    HWND hCurWnd = GetForegroundWindow();
    DWORD dwMyID = GetCurrentThreadId();
    DWORD dwCurID = GetWindowThreadProcessId(hCurWnd, NULL);
    AttachThreadInput(dwCurID, dwMyID, TRUE);
    SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE);
    SetWindowPos(hWnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_SHOWWINDOW | SWP_NOSIZE | SWP_NOMOVE);
    SetForegroundWindow(hWnd);
    SetFocus(hWnd);
    SetActiveWindow(hWnd);
    AttachThreadInput(dwCurID, dwMyID, FALSE);
}

// Loads the specified strings from the resources and shows a message box
VOID LoadStringAndMessageBox(HINSTANCE hIns, HWND hWn, UINT msgResId, UINT titleResId, UINT mbFlags)
{
    WCHAR szBuf[256], szTitleBuf[128];
    LoadString(hIns, msgResId, szBuf, sizeof(szBuf) / sizeof(WCHAR));
    LoadString(hIns, titleResId, szTitleBuf, sizeof(szTitleBuf) / sizeof(WCHAR));
    MessageBox(hWn, szBuf, szTitleBuf, mbFlags);
}

// Requests GLPI Agent status via HTTP and stores it on a wide-char string
VOID GetAgentStatus(HWND hWnd, LPWSTR szAgStatus, DWORD dwAgStatusLen)
{
    DWORD dwSize = 0;
    DWORD dwDownloaded;
    vector<BYTE> responseBody;

    LoadString(hInst, IDS_ERR_NOTRESPONDING, szAgStatus, dwAgStatusLen);

    if (running)
    {
        HINTERNET hReq = WinHttpOpenRequest(hConn, L"GET", L"/status", NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES,
            WINHTTP_FLAG_BYPASS_PROXY_CACHE);

        WinHttpSendRequest(hReq, WINHTTP_NO_ADDITIONAL_HEADERS, NULL, WINHTTP_NO_REQUEST_DATA, NULL, NULL, NULL);

        if (WinHttpReceiveResponse(hReq, NULL)) {
            do {
                dwSize = 0;

                if (!WinHttpQueryDataAvailable(hReq, &dwSize))
                    break;
                if (dwSize == 0)
                    break;

                size_t dwOffset = responseBody.size();
                responseBody.resize(dwOffset + dwSize);

                if (!WinHttpReadData(hReq, &responseBody[dwOffset], dwSize, &dwDownloaded))
                    break;
                if (dwDownloaded == 0)
                    break;
                
                dwSize -= dwDownloaded;
            } while (dwSize > 0);

            size_t respSize = responseBody.size() + 1;
            size_t cnvChars = 0;
            // Must remove "status: " from the string (respSize - 8)
            mbstowcs_s(&cnvChars, szAgStatus, respSize - 8, (LPCSTR)&responseBody[8], _TRUNCATE);
        }
        WinHttpCloseHandle(hReq);
    }
    else
        LoadString(hInst, IDS_ERR_NOTRUNNING, szAgStatus, dwAgStatusLen);
}

// Requests an inventory via HTTP
VOID ForceInventory(HWND hWnd)
{
    if (running)
    {
        if (glpiAgentOk)
        {
            HINTERNET hReq = WinHttpOpenRequest(hConn, L"GET", L"/now", NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES,
                WINHTTP_FLAG_BYPASS_PROXY_CACHE);

            if (WinHttpSendRequest(hReq, WINHTTP_NO_ADDITIONAL_HEADERS, NULL, WINHTTP_NO_REQUEST_DATA, NULL, NULL, NULL)) 
            {
                if (WinHttpReceiveResponse(hReq, NULL)) {
                    DWORD dwStatusCode = 0;
                    DWORD dwSize = sizeof(dwStatusCode);

                    if (!WinHttpQueryHeaders(hReq, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                        WINHTTP_HEADER_NAME_BY_INDEX, &dwStatusCode, &dwSize, WINHTTP_NO_HEADER_INDEX))
                    {
                        LoadStringAndMessageBox(hInst, hWnd, IDS_ERR_FORCEINV_NORESPONSE, IDS_ERROR, MB_OK | MB_ICONERROR);
                    }
                    else {
                        if (dwStatusCode != 200)
                            LoadStringAndMessageBox(hInst, hWnd, IDS_ERR_FORCEINV_NOTALLOWED, IDS_ERROR, MB_OK | MB_ICONERROR);
                        else
                            LoadStringAndMessageBox(hInst, hWnd, IDS_MSG_FORCEINV_OK, IDS_APP_TITLE, MB_OK | MB_ICONINFORMATION);
                    }
                }
            }
            WinHttpCloseHandle(hReq);
        }
        else
            LoadStringAndMessageBox(hInst, hWnd, IDS_ERR_AGENTERR, IDS_ERROR, MB_OK | MB_ICONERROR);
    }
    else
        LoadStringAndMessageBox(hInst, hWnd, IDS_ERR_NOTRUNNING, IDS_ERROR, MB_OK | MB_ICONERROR);
}

// Updates the main window statuses
VOID CALLBACK UpdateStatus(HWND hWnd, UINT message, UINT idTimer, DWORD dwTime)
{
    SC_HANDLE hSc = OpenSCManager(NULL, SERVICES_ACTIVE_DATABASE, SERVICE_QUERY_STATUS);
    SC_HANDLE hSvc = OpenService(hSc, SERVICE_NAME, SERVICE_QUERY_STATUS);
    SERVICE_STATUS svcStatus;
    BOOL querySvcOk = QueryServiceStatus(hSvc, &svcStatus);
    if (querySvcOk)
        running = svcStatus.dwCurrentState == SERVICE_RUNNING;

    if (IsWindowVisible(hWnd))
    {
        // Agent version
        HKEY hk;
        LONG lRes;
        WCHAR szKey[MAX_PATH];
        DWORD dwValue = -1;
        DWORD dwValueLen = sizeof(dwValue);

        // We can find the agent version under the Installer subkey, value "Version"
        lRes = RegOpenKeyEx(HKEY_LOCAL_MACHINE, L"SOFTWARE\\GLPI-Agent\\Installer", 0, KEY_READ | KEY_WOW64_64KEY, &hk);
        if (lRes != ERROR_SUCCESS)
        {
            lRes = RegOpenKeyEx(HKEY_LOCAL_MACHINE, L"SOFTWARE\\GLPI-Agent\\Installer", 0, KEY_READ | KEY_WOW64_64KEY, &hk);
            if (lRes != ERROR_SUCCESS) {
                LoadString(hInst, IDS_ERR_AGENTNOTFOUND, szBuffer, dwBufferLen);
                SetDlgItemText(hWnd, IDC_AGENTVER, szBuffer);
            }
        }
        if (lRes == ERROR_SUCCESS)
        {
            WCHAR szValue[128];
            DWORD szValueLen = sizeof(szValue);
            lRes = RegQueryValueEx(hk, L"Version", 0, NULL, (LPBYTE)szValue, &szValueLen);
            if (lRes != ERROR_SUCCESS)
            {
                LoadString(hInst, IDS_ERR_AGENTVERNOTFOUND, szBuffer, dwBufferLen);
                SetDlgItemText(hWnd, IDC_AGENTVER, szBuffer);
            }
            else
                wsprintf(szBuffer, L"GLPI Agent %s", szValue);
                SetDlgItemText(hWnd, IDC_AGENTVER, szBuffer);
        }


        // Startup type
        wsprintf(szKey, L"SYSTEM\\CurrentControlSet\\Services\\%s", SERVICE_NAME);
        lRes = RegOpenKeyEx(HKEY_LOCAL_MACHINE, szKey, 0, KEY_READ | KEY_WOW64_64KEY, &hk);
        if (lRes == ERROR_SUCCESS)
        {
            lRes = RegQueryValueEx(hk, L"Start", 0, NULL, (LPBYTE)&dwValue, &dwValueLen);
            if (lRes == ERROR_SUCCESS)
            {
                switch (dwValue)
                {
                    case SERVICE_BOOT_START:
                        LoadString(hInst, IDS_SVCSTART_BOOT, szBuffer, dwBufferLen);
                        break;
                    case SERVICE_SYSTEM_START:
                        LoadString(hInst, IDS_SVCSTART_SYSTEM, szBuffer, dwBufferLen);
                        break;
                    case SERVICE_AUTO_START:
                    {
                        lRes = RegQueryValueEx(hk, L"DelayedAutostart", 0, NULL, (LPBYTE)&dwValue, &dwValueLen);
                        if (lRes == ERROR_SUCCESS)
                            LoadString(hInst, IDS_SVCSTART_DELAYEDAUTO, szBuffer, dwBufferLen);
                        else
                            LoadString(hInst, IDS_SVCSTART_AUTO, szBuffer, dwBufferLen);
                        break;
                    }
                    case SERVICE_DEMAND_START:
                        LoadString(hInst, IDS_SVCSTART_MANUAL, szBuffer, dwBufferLen);
                        break;
                    case SERVICE_DISABLED:
                        LoadString(hInst, IDS_SVCSTART_DISABLED, szBuffer, dwBufferLen);
                        break;
                    default:
                        LoadString(hInst, IDS_ERR_UNKSVCSTART, szBuffer, dwBufferLen);
                }
                SetDlgItemText(hWnd, IDC_STARTTYPE, szBuffer);
            }
            else
            {
                LoadString(hInst, IDS_ERR_UNKSVCSTART, szBuffer, dwBufferLen);
                SetDlgItemText(hWnd, IDC_STARTTYPE, szBuffer);
            }
        }
        else
        {
            LoadString(hInst, IDS_ERR_REGFAIL, szBuffer, dwBufferLen);
            SetDlgItemText(hWnd, IDC_STARTTYPE, szBuffer);
        }


        // Service running status
        if (querySvcOk) {
            switch (svcStatus.dwCurrentState)
            {
                case SERVICE_STOPPED:
                    LoadString(hInst, IDS_SVC_STOPPED, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(255, 0, 0);
                    break;
                case SERVICE_RUNNING:
                    LoadString(hInst, IDS_SVC_RUNNING, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(0, 127, 0);
                    break;
                case SERVICE_PAUSED:
                    LoadString(hInst, IDS_SVC_PAUSED, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(255, 165, 0);
                    break;
                case SERVICE_CONTINUE_PENDING:
                    LoadString(hInst, IDS_SVC_CONTINUEPENDING, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(255, 165, 0);
                    break;
                case SERVICE_PAUSE_PENDING:
                    LoadString(hInst, IDS_SVC_PAUSEPENDING, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(255, 165, 0);
                    break;
                case SERVICE_START_PENDING:
                    LoadString(hInst, IDS_SVC_STARTPENDING, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(255, 165, 0);
                    break;
                case SERVICE_STOP_PENDING:
                    LoadString(hInst, IDS_SVC_STOPPENDING, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(255, 165, 0);
                    break;
                default:
                    LoadString(hInst, IDS_ERR_SERVICE, szBuffer, dwBufferLen);
                    colorSvcStatus = RGB(255, 0, 0);
                    break;
            }
        }
        else
        {
            LoadString(hInst, IDS_ERR_SERVICE, szBuffer, dwBufferLen);
            colorSvcStatus = RGB(255, 0, 0);
        }
        SetDlgItemText(hWnd, IDC_SERVICESTATUS, szBuffer);


        // Agent status
        WCHAR szAgStatus[128];
        GetAgentStatus(hWnd, szAgStatus, sizeof(szAgStatus) / sizeof(WCHAR));
        SetDlgItemText(hWnd, IDC_AGENTSTATUS, szAgStatus);
    }


    // Taskbar icon routine
    if (!running)
    {
        if (glpiAgentOk)
        {
            LoadIconMetric(hInst, MAKEINTRESOURCE(IDI_GLPIERR), LIM_LARGE, &nid.hIcon);
            LoadString(hInst, IDS_GLPINOTIFYERROR, nid.szTip, ARRAYSIZE(nid.szTip));
            Shell_NotifyIcon(NIM_MODIFY, &nid);
            glpiAgentOk = false;
        }
    }
    else
    {
        if (!glpiAgentOk)
        {
            LoadIconMetric(hInst, MAKEINTRESOURCE(IDI_GLPIOK), LIM_LARGE, &nid.hIcon);
            LoadString(hInst, IDS_GLPINOTIFY, nid.szTip, ARRAYSIZE(nid.szTip));
            Shell_NotifyIcon(NIM_MODIFY, &nid);
            glpiAgentOk = true;
        }
    }

    CloseServiceHandle(hSvc);
    CloseServiceHandle(hSc);
}


//-[MAIN FUNCTIONS]------------------------------------------------------------

// Entry point
int APIENTRY wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPWSTR lpCmdLine, _In_ int nCmdShow)
{
    hInst = hInstance;

    // Read app version
    WCHAR szFileName[MAX_PATH];
    GetModuleFileName(NULL, szFileName, MAX_PATH);
    DWORD dwSize = GetFileVersionInfoSize(szFileName, 0);
    VS_FIXEDFILEINFO* lpFfi = NULL;
    UINT uFfiLen = 0;
    WCHAR* szVerBuffer = new WCHAR[dwSize];
    GetFileVersionInfo(szFileName, 0, dwSize, szVerBuffer);
    VerQueryValue(szVerBuffer, L"\\", (LPVOID*)&lpFfi, &uFfiLen);
    DWORD dwVerMaj = HIWORD(lpFfi->dwFileVersionMS);
    DWORD dwVerMin = LOWORD(lpFfi->dwFileVersionMS);

    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

    // Load agent settings
    HKEY hk;
    WCHAR szKey[MAX_PATH];
    WCHAR szValueBuf[MAX_PATH];
    DWORD szValueBufLen = sizeof(szValueBuf);
    DWORD dwPort = 62354;

    wsprintf(szKey, L"SOFTWARE\\%s", SERVICE_NAME);
    LONG lRes = RegOpenKeyEx(HKEY_LOCAL_MACHINE, szKey, 0, KEY_READ | KEY_WOW64_64KEY, &hk);
    if (lRes != ERROR_SUCCESS)
    {
        wsprintf(szKey, L"SOFTWARE\\WOW6432Node\\%s", SERVICE_NAME);
        lRes = RegOpenKeyEx(HKEY_LOCAL_MACHINE, szKey, 0, KEY_READ | KEY_WOW64_64KEY, &hk);
        if (lRes != ERROR_SUCCESS) {
            LoadStringAndMessageBox(hInst, NULL, IDS_ERR_AGENTSETTINGS, IDS_ERROR, MB_OK | MB_ICONERROR);
            return -10;
        }
    }
    if (lRes == ERROR_SUCCESS)
    {   
        // Get HTTPD port
        lRes = RegQueryValueEx(hk, L"httpd-port", 0, NULL, (LPBYTE)szValueBuf, &szValueBufLen);
        if (lRes != ERROR_SUCCESS) {
            LoadStringAndMessageBox(hInst, NULL, IDS_ERR_HTTPDPORT, IDS_ERROR, MB_OK | MB_ICONERROR);
            return -30;
        }
        else
            dwPort = _wtoi(szValueBuf);
    }

    // Create WinHTTP handles
    WCHAR szUserAgent[64];
    wsprintf(szUserAgent, L"%s/%d.%d", USERAGENT_NAME, dwVerMaj, dwVerMin);

    hSession = WinHttpOpen(szUserAgent, WINHTTP_ACCESS_TYPE_NO_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, NULL);
    hConn = WinHttpConnect(hSession, L"127.0.0.1", (INTERNET_PORT)dwPort, 0);

    //-------------------------------------------------------------------------

    HWND hWnd = CreateDialog(hInst, MAKEINTRESOURCE(IDD_MAIN), NULL, (DLGPROC)DlgProc);
    if (!hWnd) {
        LoadStringAndMessageBox(hInst, NULL, IDS_ERR_MAINWINDOW, IDS_ERROR, MB_OK | MB_ICONERROR);
        return -40;
    }

    HICON icon = (HICON)LoadImage(hInst, MAKEINTRESOURCE(IDI_GLPIOK), IMAGE_ICON, 0, 0, LR_DEFAULTCOLOR | LR_DEFAULTSIZE);
    SendMessage(hWnd, WM_SETICON, ICON_SMALL, (LPARAM)icon);
    SendMessage(hWnd, WM_SETICON, ICON_BIG, (LPARAM)icon);

    // Taskbar icon
    nid.hWnd = hWnd;
    nid.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP;
    nid.uCallbackMessage = WMAPP_NOTIFYCALLBACK;
    LoadIconMetric(hInst, MAKEINTRESOURCE(IDI_GLPIOK), LIM_LARGE, &nid.hIcon);
    LoadString(hInst, IDS_GLPINOTIFY, nid.szTip, ARRAYSIZE(nid.szTip));
    Shell_NotifyIcon(NIM_ADD, &nid);
    nid.uVersion = NOTIFYICON_VERSION_4;
    Shell_NotifyIcon(NIM_SETVERSION, &nid);

    HBITMAP hLogo = nullptr;
    LoadPNGAsBitmap(hInst, MAKEINTRESOURCE(IDB_LOGO), L"PNG", &hLogo);
    SendMessage(GetDlgItem(hWnd, IDC_PCLOGO), STM_SETIMAGE, IMAGE_BITMAP, (LPARAM)hLogo);

    WCHAR szVer[20];
    wsprintf(szVer, L"v%d.%d", dwVerMaj, dwVerMin);
    SetDlgItemText(hWnd, IDC_VERSION, szVer);

    LoadString(hInst, IDS_APP_TITLE, szBuffer, dwBufferLen);
    SetWindowText(hWnd, szBuffer);
    SetDlgItemText(hWnd, IDC_STATIC_TITLE, szBuffer);

    LoadString(hInst, IDS_STATIC_INFO, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDC_GBMAIN, szBuffer);

    LoadString(hInst, IDS_STATIC_AGENTVER, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDC_STATIC_AGENTVER, szBuffer);
    LoadString(hInst, IDS_STATIC_SERVICESTATUS, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDC_STATIC_SERVICESTATUS, szBuffer);
    LoadString(hInst, IDS_STATIC_STARTTYPE, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDC_STATIC_STARTTYPE, szBuffer);

    LoadString(hInst, IDS_LOADING, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDC_AGENTVER, szBuffer);
    SetDlgItemText(hWnd, IDC_SERVICESTATUS, szBuffer);
    SetDlgItemText(hWnd, IDC_STARTTYPE, szBuffer);
    SetDlgItemText(hWnd, IDC_AGENTSTATUS, szBuffer);

    LoadString(hInst, IDS_STATIC_AGENTSTATUS, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDC_GBSTATUS, szBuffer);

    LoadString(hInst, IDS_FORCEINV, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDFORCE, szBuffer);
    LoadString(hInst, IDS_CLOSE, szBuffer, dwBufferLen);
    SetDlgItemText(hWnd, IDCLOSE, szBuffer);

    //-------------------------------------------------------------------------

    UpdateStatus(hWnd, NULL, NULL, NULL);
    SetTimer(hWnd, IDT_UPDSTATUS, 2000, (TIMERPROC)UpdateStatus);

    //-------------------------------------------------------------------------

    // Main message loop
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int) msg.wParam;
}

LRESULT CALLBACK DlgProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_COMMAND:
        {
            switch (LOWORD(wParam))
            {
                // Force inventory
                case IDFORCE:
                case ID_RMENU_FORCE:
                    ForceInventory(hWnd);
                    break;
                // Close
                case IDCLOSE:
                    EndDialog(hWnd, NULL);
                    break;
                // Open
                case ID_RMENU_OPEN:
                    ShowWindowFront(hWnd, SW_SHOW);
                    UpdateStatus(hWnd, NULL, NULL, NULL);
                    break;
                // Exit
                case ID_RMENU_EXIT:
                    // wParam and lParam are randomly chosen values
                    PostMessage(hWnd, WM_CLOSE, 0xBEBAF7F3, 0xC0CAF7F3);
                    break;
            }
            break;
        }
        case WM_CTLCOLORSTATIC:
        {
            HDC hdc = (HDC)wParam;
            SetBkMode(hdc, TRANSPARENT);
            switch(GetDlgCtrlID((HWND)lParam))
            {
                case IDC_SERVICESTATUS:
                    SetTextColor(hdc, colorSvcStatus);
                    return (LRESULT)GetSysColorBrush(COLOR_MENU);
            }
            break;
        }
        // Taskbar icon callback
        case WMAPP_NOTIFYCALLBACK:
        {
            switch (LOWORD(lParam))
            {
                // Left click
                case NIN_SELECT:
                    ShowWindowFront(hWnd, SW_SHOW);
                    UpdateStatus(hWnd, NULL, NULL, NULL);
                    break;
                // Right click
                case WM_CONTEXTMENU:
                {
                    POINT const pt = { LOWORD(wParam), HIWORD(wParam) };
                    HMENU hMenu = LoadMenu(hInst, MAKEINTRESOURCE(IDR_RMENU));
                    if (hMenu)
                    {
                        MENUITEMINFO mi = { sizeof(MENUITEMINFO) };
                        GetMenuItemInfo(hMenu, ID_RMENU_OPEN, false, &mi);
                        mi.fMask = MIIM_TYPE | MIIM_DATA;

                        LoadString(hInst, IDS_RMENU_OPEN, szBuffer, dwBufferLen);
                        mi.dwTypeData = szBuffer;
                        SetMenuItemInfo(hMenu, ID_RMENU_OPEN, false, &mi);
                        LoadString(hInst, IDS_RMENU_FORCE, szBuffer, dwBufferLen);
                        mi.dwTypeData = szBuffer;
                        SetMenuItemInfo(hMenu, ID_RMENU_FORCE, false, &mi);
                        LoadString(hInst, IDS_RMENU_EXIT, szBuffer, dwBufferLen);
                        mi.dwTypeData = szBuffer;
                        SetMenuItemInfo(hMenu, ID_RMENU_EXIT, false, &mi);

                        HMENU hSubMenu = GetSubMenu(hMenu, 0);
                        if (hSubMenu)
                        {
                            SetForegroundWindow(hWnd);
                            UINT uFlags = TPM_RIGHTBUTTON;
                            if (GetSystemMetrics(SM_MENUDROPALIGNMENT) != 0)
                                uFlags |= TPM_RIGHTALIGN;
                            else
                                uFlags |= TPM_LEFTALIGN;
                            TrackPopupMenuEx(hSubMenu, uFlags, pt.x, pt.y, hWnd, NULL);
                        }

                        DestroyMenu(hMenu);
                    }
                    break;
                }
            }
            break;
        }
        case WM_CLOSE:
        {
            // Right-click Exit button
            if (wParam == 0xBEBAF7F3 && lParam == 0xC0CAF7F3)
                DestroyWindow(hWnd);
            else
                EndDialog(hWnd, NULL);
            break;
        }
        case WM_DESTROY:
        {
            WinHttpCloseHandle(hConn);
            WinHttpCloseHandle(hSession);

            Gdiplus::GdiplusShutdown(gdiplusToken);

            // Remove taskbar icon
            Shell_NotifyIcon(NIM_DELETE, &nid);

            PostQuitMessage(0);
            break;
        }
    }
    return 0;
}