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
   This PowerShell is for custom detection in Microsoft intune Dell Peripheral Manager

.DESCRIPTION
   This PowerShell will checki if Dell Peripheral Manager is ready installed on a device. It will be used as custom detection in Microsoft Intune win32 install.
   
#>

######################################################################################################################
# Program with target Version
######################################################################################################################
$ProgramVersion_target = '1.7.7' # need to be the same like the exe file
$filePath = 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe'

if (Test-Path $filePath)
    {
        [Version]$ProgramVersion_current = (Get-ItemProperty $filePath).VersionInfo | Select-Object -ExpandProperty ProductVersion
    }
else
    {
        Write-Output "File not found."
    }

if($ProgramVersion_current -ge $ProgramVersion_target)
    {
        Write-Host "Found it!"
    }