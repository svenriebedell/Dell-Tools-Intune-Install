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
   This PowerShell is for custom detection for Microsoft MEM Dependency App for SupportAssist Cleanup

.DESCRIPTION
   This PowerShell will check if Dell SupportAssist is ready uninstalled on a device. It will be used as custom detection in Microsoft MEM win32 install.
   
#>

##### Varibles
$ProgramVersion_target = '3.4.0.35707' # need to be the same like the msi file
$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%SupportAssist%Business%'" | Select-Object -ExpandProperty Version
$Program_current = Get-CimInstance -ClassName Win32_Product | Where-Object {($_.Name -like "*Dell SupportAssist*" -and $_.Name -notlike "*OS Recovery*" -and $_.Name -notlike "Dell*SupportAssist*Remediation")} | Select-Object -ExpandProperty Name

######################################################################################################################
# Checking if a SupportAssist existing after Cleanup script                                                          #
######################################################################################################################


if ($null -eq $Program_current) 
    {
    
    Write-Host "Found it!"
    
    }
Else
    {

    ######################################################################################################################
    # Cover newest version is installed on the machine                                                                   #
    ######################################################################################################################

    if ($ProgramVersion_target -eq $ProgramVersion_current)
        {
        
        Write-Host "Found it!"

        }

    }