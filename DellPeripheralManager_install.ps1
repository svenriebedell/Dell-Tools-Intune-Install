<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0
_Dev_Status_ = Test
Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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
   This PowerShell is for installation in Microsoft MEM for Dell Peripheral Manager

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell Peripheral Manager. It will be used as install file in Microsoft MEM win32 install.
   
#>

##### Variables
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion

##### Check first if Dell Peripheral Manager is installed by looking registry path
$CheckInstall = Test-path -path 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe'

if($CheckInstall -eq $true)
   {
        [Version]$ProgramVersion_current = (Get-ItemProperty 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe').VersionInfo | Select-Object -ExpandProperty ProductVersion
        $ApplicationPath = "C:\Program Files\Dell\Dell Peripheral Manager\"
        $NameUninstallFile = "Uninstall.exe"
   }
else 
    {
        [Version]$ProgramVersion_current = $null
    }

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

If ($ProgramVersion_current -ne $null)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
            Start-Process -FilePath $ApplicationPath\$NameUninstallFile -ArgumentList "/S" -Wait
        }

    Else
        {
        Write-Host "same version is installed"
        Exit 0
        }
    }


###################################################################
#Install new Software                                             #
###################################################################

Start-Process -FilePath "$ProgramPath" -ArgumentList "/S" -Wait