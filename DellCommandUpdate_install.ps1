<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.2
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

<#Changelog:
    1.1 adding DCU configurations section after install as optional
    1.2 correct filter setting for $ProgramVersion_current
#>

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Command | Update

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell Command | Update. It will be used as install file in Microsoft MEM win32 install.
   
#>

##### Variables
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion
[Version]$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell Command%Update%'" | Select-Object -ExpandProperty Version
$ApplicationID_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Update%'" | Select-Object -ExpandProperty IdentifyingNumber

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################
If ($ProgramVersion_current -ne $null)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
        Start-Process -FilePath msiexec.exe -ArgumentList '/x $ApplicationID_current /qn' -Wait
        }

    Else
        {
        Write-Host "Same version is installed"
        
        Exit Code 0
        }

    }


###################################################################
#Install new Software                                             #
###################################################################

Start-Process -FilePath "$ProgramPath" -ArgumentList "/s" -Wait

###################################################################
#Optional configuration DCU                                       #
###################################################################

#Select Path of dcu-cli.exe
#$Path = (Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Update%'").InstallLocation
#cd $Path

#Set generic BIOS Password
#.\dcu-cli.exe /configure -biosPassword="Use your BIOS PW here" #please beware it could be visible in log if you don't want this use encryptedPassword and encryptedKey function

#Deactivate updates of Applications like DCU, DCM,etc.
#.\dcu-cli.exe /configure -updateType='bios,firmware,driver,utility,others'

#Lock setting in UI
#.\dcu-cli.exe /configure -lockSettings=enable