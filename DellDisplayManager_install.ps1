<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0
_Dev_Status_ = Test
Copyright Â© 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

No implied support and test in test environment/device before using in any production environment.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Display Manager

.DESCRIPTION
   This PowerShell will install/Display Manager a Device for Dell Display Manager. It will be used as install file in Microsoft MEM win32 install.
   
#>

##### Variables
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion
[Version]$ProgramVersion_current = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "Dell Display Manager" } | Select-Object -ExpandProperty DisplayVersion
$ApplicationID_current = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "Dell Display Manager" } | Select-Object -ExpandProperty QuietUninstallString

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

If ($ProgramVersion_current -ne $null)
    {


    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
    
        $IDProcess = Get-Process | Where-Object {$_.ProcessName -like 'ddm'} | select -ExpandProperty ID
        Stop-Process -Id $IDProcess -Force
        Start-Process cmd.exe -ArgumentList '/c',$ApplicationID_current -Wait

        Start-Sleep -Seconds 10
    
        }

    Else
        {
        Write-Host "Gleiche Version"
        Exit 0

        }
    }

###################################################################
#Install new Software                                             #
###################################################################

Start-Process -FilePath ".\ddmsetup.exe" -ArgumentList '/verysilent /noupdate'
Start-Sleep -Seconds 15
Start-Process -FilePath "C:\Program Files (x86)\Dell\Dell Display Manager\ddm.exe"

Exit 0