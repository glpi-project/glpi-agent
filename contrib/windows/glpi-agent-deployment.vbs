'
'  ------------------------------------------------------------------------
'  glpi-agent-deployment.vbs
'  Copyright (C) 2010-2017 by the FusionInventory Development Team.
'  Copyright (C) 2021 by the Teclib SAS
'  ------------------------------------------------------------------------
'
'  LICENSE
'
'  This file is part of GLPI Agent project.
'
'  This file is free software; you can redistribute it and/or modify it
'  under the terms of the GNU General Public License as published by the
'  Free Software Foundation; either version 2 of the License, or (at your
'  option) any later version.
'
'
'  This file is distributed in the hope that it will be useful, but WITHOUT
'  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
'  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
'  more details.
'
'  You should have received a copy of the GNU General Public License
'  along with this program; if not, write to the Free Software Foundation,
'  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA,
'  or see <http://www.gnu.org/licenses/>.
'
'  ------------------------------------------------------------------------
'
'  @package   GLPI Agent
'  @file      .\contrib\windows\glpi-agent-deployment.vbs
'  @author(s) Benjamin Accary <meldrone@orange.fr>
'             Christophe Pujol <chpujol@gmail.com>
'             Marc Caissial <marc.caissial@zenitique.fr>
'             Tomas Abad <tabadgp@gmail.com>
'             Guillaume Bougard <gbougard@teclib.com>
'  @copyright Copyright (c) 2010-2017 FusionInventory Team
'             Copyright (c) 2021 Teclib SAS
'  @license   GNU GPL version 2 or (at your option) any later version
'             http://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html
'  @link      http://www.glpi-project.org/
'  @since     2021
'
'  ------------------------------------------------------------------------
'

'
'
' Purpose:
'     GLPI Agent Unattended Deployment.
'
'

Option Explicit
Dim Reconfigure, Repair, Verbose
Dim Setup, SetupArchitecture, SetupLocation, SetupNightlyLocation, SetupOptions, SetupVersion, RunUninstallFusionInventoryAgent, UninstallOcsAgent

'
'
' USER SETTINGS
'
'

' SetupVersion
'    Setup version with the pattern <major>.<minor>.<release>[-<package>]
'
SetupVersion = "1.4"

' When using a nightly built version, uncomment the following SetupVersion definition line
' replacing gitABCDEFGH with the most recent git revision found on the nightly builds site
' In that case, SetupNightlyLocation will be selected as location in place of SetupLocation
'SetupVersion = "1.5-gitABCDEFGH"

' SetupLocation
'    Depending on your needs or your environment, you can use either a HTTP or
'    CIFS/SMB.
'
'    If you use HTTP, please, set to SetupLocation a URL:
'
'       SetupLocation = "http://host[:port]/[absolut_path]" or
'       SetupLocation = "https://host[:port]/[absolut_path]"
'
'    If you use CIFS, please, set to SetupLocation a UNC path name:
'
'       SetupLocation = "\\host\share\[path]"
'
'       You also must be sure that you have removed the "Open File Security Warning"
'       from programs accessed from that UNC.
'
' Location for Release Candidates
SetupLocation = "https://github.com/glpi-project/glpi-agent/releases/download/" & SetupVersion

' Location for Nightly Builds
SetupNightlyLocation = "https://nightly.glpi-project.org/glpi-agent"


' SetupArchitecture
'    The setup architecture can be 'x86', 'x64' or 'Auto'
'
'    If you set SetupArchitecture = "Auto" be sure that both installers are in
'    the same SetupLocation.
'
SetupArchitecture = "Auto"

' SetupOptions
'    Consult the online installer documentation to know its list of options.
'    See: https://glpi-agent.readthedocs.io/en/latest/installation/windows-command-line.html#command-line-parameters
'
'    You should use simple quotes (') to set between quotation marks those values
'    that require it; double quotes (") doesn't work with UNCs.
'
SetupOptions = "/quiet RUNNOW=1 SERVER='http://glpi.yourcompany.com/'"
'SetupOptions = "/quiet RUNNOW=1 SERVER='http://glpi.yourcompany.com/plugins/fusioninventory'"

' Setup
'    The installer file name. You should not have to modify this variable ever.
'
Setup = "GLPI-Agent-" & SetupVersion & "-" & SetupArchitecture & ".msi"

' Reconfigure
'    Just reconfigure the current installation if installed agent has the same version
'
Reconfigure = "Yes"

' Repair
'    Repair the installation when Setup is still installed.
'
Repair = "No"

' Verbose
'    Enable or disable the information messages.
'
'    It's advisable to use Verbose = "Yes" with 'cscript //nologo ...'.
'
Verbose = "No"

' RunUninstallFusionInventoryAgent
'    Set to "Yes" to first uninstall FusionInventory Agent
'    Also and unless SERVER or LOCAL are defined in SetupOptions, this script
'    will try to get them from FusionInventory-Agent configuration found in registry
'
RunUninstallFusionInventoryAgent = "No"

' UninstallOcsAgent
'    Enable or disable the uninstallation of OCS Agent
'
UninstallOcsAgent = "No"

'
'
' DO NOT EDIT BELOW
'
'

Function removeOCSAgents()
   On error resume next

   Dim Uninstall
   ' Uninstall agent ocs if is installed
   ' Verification on OS 32 Bits
   On error resume next
   Uninstall = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OCS Inventory Agent\UninstallString")
   If err.number = 0 then
      WshShell.Run "CMD.EXE /C net stop ""OCS INVENTORY SERVICE""",0,True
      WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles%\OCS Inventory Agent"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%SystemDrive%\ocs-ng"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C sc delete ""OCS INVENTORY""",0,True
   End If

   ' Verification on OS 64 Bits
   On error resume next
   Uninstall = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OCS Inventory Agent\UninstallString")
   If err.number = 0 then
      WshShell.Run "CMD.EXE /C net stop ""OCS INVENTORY SERVICE""",0,True
      WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles(x86)%\OCS Inventory Agent"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%SystemDrive%\ocs-ng"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C sc delete ""OCS INVENTORY""",0,True
   End If

   ' Verification Agent V2 on 32Bit
   On error resume next
   Uninstall = WshShell.RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OCS Inventory NG Agent\UninstallString")
   If err.number = 0 then
      WshShell.Run "CMD.EXE /C net stop ""OCS INVENTORY SERVICE""",0,True
      WshShell.Run "CMD.EXE /C taskkill /F /IM ocssystray.exe",0,True
      WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles%\OCS Inventory Agent"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%SystemDrive%\ocs-ng"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C sc delete ""OCS INVENTORY""",0,True
   End If

   ' Verification Agent V2 on 64Bit
   On error resume next
   Uninstall = WshShell.RegRead("HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OCS Inventory NG Agent\UninstallString")
   If err.number = 0 then
      WshShell.Run "CMD.EXE /C net stop ""OCS INVENTORY SERVICE""",0,True
      WshShell.Run "CMD.EXE /C taskkill /F /IM ocssystray.exe",0,True
      WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles%\OCS Inventory Agent"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%SystemDrive%\ocs-ng"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C sc delete ""OCS INVENTORY""",0,True
   End If
End Function

Function hasOption(opt)
   Dim regEx
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = False
   regEx.Pattern = "\b" & opt & "=.+\b"
   hasOption = regEx.Test(SetupOptions)
End Function

Function uninstallFusionInventoryAgent()
    Dim Uninstall, getValue

    ' Try to get SERVER and LOCAL from FIA configuration in registry if needed
    If not hasOption("SERVER") then
        On error resume next
        getValue = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\FusionInventory-Agent\server")
        If err.number = 0 And getValue <> "" then
           SetupOptions = SetupOptions & " SERVER='" & getValue & "'"
        End If
    End If
    If not hasOption("LOCAL") then
        On error resume next
        getValue = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\FusionInventory-Agent\local")
        If err.number = 0 And getValue <> "" then
           SetupOptions = SetupOptions & " LOCAL='" & getValue & "'"
        End If
    End If

    ' Verify normal case
    On error resume next
    Uninstall = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\UninstallString")
    If err.number = 0 then
        WshShell.Run "CMD.EXE /C net stop FusionInventory-Agent",0,True
        WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
        WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles%\FusionInventory-Agent"" /S /Q",0,True
    End If

    ' Verify FIA x86 is installed on x64 OS
    On error resume next
    Uninstall = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\UninstallString")
    If err.number = 0 then
        WshShell.Run "CMD.EXE /C net stop FusionInventory-Agent",0,True
        WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
        WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles(x86)%\FusionInventory-Agent"" /S /Q",0,True
    End If
End Function

Function AdvanceTime(nMinutes)
   Dim nMinimalMinutes, dtmTimeFuture
   ' As protection
   nMinimalMinutes = 5
   If nMinutes < nMinimalMinutes Then
      nMinutes = nMinimalMinutes
   End If
   ' Add nMinutes to the current time
   dtmTimeFuture = DateAdd ("n", nMinutes, Time)
   ' Format the result value
   '    The command AT accepts 'HH:MM' values only
   AdvanceTime = Hour(dtmTimeFuture) & ":" & Minute(dtmTimeFuture)
End Function

Function baseName (strng)
   Dim regEx
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = True
   regEx.Pattern = ".*[/\\]([^/\\]+)$"
   baseName = regEx.Replace(strng,"$1")
End Function

Function GetSystemArchitecture()
   Dim strSystemArchitecture
   Err.Clear
   ' Get operative system architecture
   On Error Resume Next
   strSystemArchitecture = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%")
   If Err.Number = 0 Then
      ' Check the operative system architecture
      Select Case strSystemArchitecture
         Case "x86"
            ' The system architecture is 32-bit
            GetSystemArchitecture = "x86"
         Case "AMD64"
            ' The system architecture is 64-bit
            GetSystemArchitecture = "x64"
         Case Else
            ' The system architecture is not supported
            GetSystemArchitecture = "NotSupported"
      End Select
   Else
      ' It has been not possible to get the system architecture
      GetSystemArchitecture = "Unknown"
   End If
End Function

Function isHttp(strng)
   Dim regEx, matches
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = True
   regEx.Pattern = "^(http(s?)).*"
   If regEx.Execute(strng).count > 0 Then
      isHttp = True
   Else
      isHttp = False
   End If
   Exit Function
End Function

Function isNightly(strng)
   Dim regEx, matches
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = True
   regEx.Pattern = "-(git[0-9a-f]{8})$"
   If regEx.Execute(strng).count > 0 Then
      isNightly = True
   Else
      isNightly = False
   End If
   Exit Function
End Function

Function IsInstallationNeeded(strSetupVersion, strSetupArchitecture, strSystemArchitecture)
   Dim strCurrentSetupVersion
   ' Compare the current version, whether it exists, with strSetupVersion
   If strSystemArchitecture = "x86" Then
      ' The system architecture is 32-bit
      ' Check if the subkey 'SOFTWARE\GLPI-Agent\Installer' exists
      On error resume next
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent\Installer\Version")
      If Err.Number = 0 Then
      ' The subkey 'SOFTWARE\GLPI-Agent\Installer' exists
         If strCurrentSetupVersion <> strSetupVersion Then
            ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
      ' The subkey 'SOFTWARE\GLPI-Agent\Installer' doesn't exist
         Err.Clear
         ShowMessage("Installation needed: " & strSetupVersion)
         IsInstallationNeeded = True
      End If
   Else
      ' The system architecture is 64-bit
      ' Check if the subkey 'SOFTWARE\Wow6432Node\GLPI-Agent\Installer' exists
      On error resume next
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\GLPI-Agent\Installer\Version")
      If Err.Number = 0 Then
      ' The subkey 'SOFTWARE\Wow6432Node\GLPI-Agent\Installer' exists
         If strCurrentSetupVersion <> strSetupVersion Then
            ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
         ' The subkey 'SOFTWARE\Wow6432Node\GLPI-Agent\Installer' doesn't exist
         Err.Clear
         ' Check if the subkey 'SOFTWARE\GLPI-Agent\Installer' exists
         On error resume next
         strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent\Installer\Version")
         If Err.Number = 0 Then
         ' The subkey 'SOFTWARE\GLPI-Agent\Installer' exists
            If strCurrentSetupVersion <> strSetupVersion Then
               ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
               IsInstallationNeeded = True
            End If
            Exit Function
         Else
            ' The subkey 'SOFTWARE\GLPI-Agent\Installer' doesn't exist
            Err.Clear
            ShowMessage("Installation needed: " & strSetupVersion)
            IsInstallationNeeded = True
         End If
      End If
   End If
End Function

Function IsSelectedReconfigure()
   If LCase(Reconfigure) <> "no" Then
      ShowMessage("Installation reconfigure: " & SetupVersion)
      IsSelectedReconfigure = True
   Else
      IsSelectedReconfigure = False
   End If
End Function

Function IsSelectedRepair()
   If LCase(Repair) <> "no" Then
      ShowMessage("Installation repairing: " & SetupVersion)
      IsSelectedRepair = True
   Else
      IsSelectedRepair = False
   End If
End Function

' http://www.ericphelps.com/scripting/samples/wget/index.html
Function SaveWebBinary(strSetupLocation, strSetup)
   Const adTypeBinary = 1
   Const adSaveCreateOverWrite = 2
   Const ForWriting = 2
   Dim web, varByteArray, strData, strBuffer, lngCounter, ado, strUrl
   strUrl = strSetupLocation & "/" & strSetup
   'On Error Resume Next
   'Download the file with any available object
   Err.Clear
   Set web = Nothing
   Set web = CreateObject("WinHttp.WinHttpRequest.5.1")
   If web Is Nothing Then Set web = CreateObject("WinHttp.WinHttpRequest")
   If web Is Nothing Then Set web = CreateObject("MSXML2.ServerXMLHTTP")
   If web Is Nothing Then Set web = CreateObject("Microsoft.XMLHTTP")
   web.Open "GET", strURL, False
   web.Send
   If Err.Number <> 0 Then
      SaveWebBinary = False
      Set web = Nothing
      Exit Function
   End If
   If web.Status <> "200" Then
      SaveWebBinary = False
      Set web = Nothing
      Exit Function
   End If
   varByteArray = web.ResponseBody
   Set web = Nothing
   'Now save the file with any available method
   On Error Resume Next
   Set ado = Nothing
   Set ado = CreateObject("ADODB.Stream")
   If ado Is Nothing Then
      Set fs = CreateObject("Scripting.FileSystemObject")
      Set ts = fs.OpenTextFile(baseName(strUrl), ForWriting, True)
      strData = ""
      strBuffer = ""
      For lngCounter = 0 to UBound(varByteArray)
         ts.Write Chr(255 And Ascb(Midb(varByteArray,lngCounter + 1, 1)))
      Next
      ts.Close
   Else
      ado.Type = adTypeBinary
      ado.Open
      ado.Write varByteArray
      ado.SaveToFile CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%") & "\" & strSetup, adSaveCreateOverWrite
      ado.Close
   End If
   SaveWebBinary = True
End Function

Function ShowMessage(strMessage)
   If LCase(Verbose) <> "no" Then
      WScript.Echo strMessage
   End If
End Function

'
'
' MAIN
'
'

Dim nMinutesToAdvance, strCmd, strSystemArchitecture, strTempDir, WshShell, strInstallOrRepair, bInstall
Set WshShell = WScript.CreateObject("WScript.shell")

nMinutesToAdvance = 5

If UninstallOcsAgent = "Yes" Then
   removeOCSAgents()
End If

If RunUninstallFusionInventoryAgent = "Yes" Then
    uninstallFusionInventoryAgent()
End If

' Get system architecture
strSystemArchitecture = GetSystemArchitecture()
If (strSystemArchitecture <> "x86") And (strSystemArchitecture <> "x64") Then
   ShowMessage("The system architecture is unknown or not supported.")
   ShowMessage("Deployment aborted!")
   WScript.Quit 1
Else
   ShowMessage("System architecture detected: " & strSystemArchitecture)
End If

' Check and auto detect SetupArchitecture
Select Case LCase(SetupArchitecture)
   Case "x86"
      ' The setup architecture is 32-bit
      SetupArchitecture = "x86"
      Setup = Replace(Setup, "x86", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture: " & SetupArchitecture)
   Case "x64"
      ' The setup architecture is 64-bit
      SetupArchitecture = "x64"
      Setup = Replace(Setup, "x64", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture: " & SetupArchitecture)
   Case "auto"
      ' Auto detection of SetupArchitecture
      SetupArchitecture = strSystemArchitecture
      Setup = Replace(Setup, "Auto", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture detected: " & SetupArchitecture)
   Case Else
      ' The setup architecture is not supported
      ShowMessage("The setup architecture '" & SetupArchitecture & "' is not supported.")
      WScript.Quit 2
End Select

' Check the relation between strSystemArchitecture and SetupArchitecture
If (strSystemArchitecture = "x86") And (SetupArchitecture = "x64") Then
   ' It isn't possible to execute a 64-bit setup on a 32-bit operative system
   ShowMessage("It isn't possible to execute a 64-bit setup on a 32-bit operative system.")
   ShowMessage("Deployment aborted!")
   WScript.Quit 3
End If

bInstall = False
strInstallOrRepair = "/i"

If IsInstallationNeeded(SetupVersion, SetupArchitecture, strSystemArchitecture) Then
   bInstall = True
ElseIf IsSelectedRepair() Then
   strInstallOrRepair = "/fa"
   bInstall = True
ElseIf IsSelectedReconfigure() Then
   If not hasOption("REINSTALL") Then
      SetupOptions = SetupOptions & " REINSTALL=feat_AGENT"
   End If
   bInstall = True
End If

If bInstall Then
   If isNightly(SetupVersion) Then
      SetupLocation = SetupNightlyLocation
   End If
   If isHttp(SetupLocation) Then
      ShowMessage("Downloading: " & SetupLocation & "/" & Setup)
      If SaveWebBinary(SetupLocation, Setup) Then
         strCmd = WshShell.ExpandEnvironmentStrings("%ComSpec%")
         strTempDir = WshShell.ExpandEnvironmentStrings("%TEMP%")
         ShowMessage("Running: MsiExec.exe " & strInstallOrRepair & " """ & strTempDir & "\" & Setup & """ " & SetupOptions)
         WshShell.Run "MsiExec.exe " & strInstallOrRepair & " """ & strTempDir & "\" & Setup & """ " & SetupOptions, 0, True
         ShowMessage("Scheduling: DEL /Q /F """ & strTempDir & "\" & Setup & """")
         WshShell.Run "AT.EXE " & AdvanceTime(nMinutesToAdvance) & " " & strCmd & " /C ""DEL /Q /F """"" & strTempDir & "\" & Setup & """""", 0, True
         ShowMessage("Deployment done!")
      Else
         ShowMessage("Error downloading '" & SetupLocation & "\" & Setup & "'!")
      End If
   Else
      ShowMessage("Running: MsiExec.exe " & strInstallOrRepair & " """ & SetupLocation & "\" & Setup & """ " & SetupOptions)
      WshShell.Run "MsiExec.exe " & strInstallOrRepair & " """ & SetupLocation & "\" & Setup & """ " & SetupOptions, 0, True
      ShowMessage("Deployment done!")
   End If
Else
   ShowMessage("It isn't needed the installation of '" & Setup & "'.")
End If
