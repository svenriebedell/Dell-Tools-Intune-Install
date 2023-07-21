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
   This PowerShell is for custom detection in Microsoft MEM for Dell Command | Monitor

.DESCRIPTION
   This PowerShell will checki if Dell Command | Monitor is ready installed on a device. It will be used as custom detection in Microsoft MEM win32 install.
   
#>

######################################################################################################################
# Program with target Version
######################################################################################################################
$ProgramVersion_target = '10.9.1.11' # need to be the same like the exe file
$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Monitor%'" | Select-Object -ExpandProperty Version

if($ProgramVersion_current -eq $ProgramVersion_target)
    {
    Write-Host "Found it!"
    }