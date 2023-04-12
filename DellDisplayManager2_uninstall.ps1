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
   This PowerShell is for uninstall in Microsoft MEM for Dell Display Manager

.DESCRIPTION
   This PowerShell will uninstall a Device for Dell Display Manager. It will be used as install file in Microsoft MEM win32 install.
   
#>

##### Variables
$ApplicationID_current = "C:\Program Files\Dell\Dell Display Manager 2\Uninst.exe"

###################################################################
#uninstall Software                                               #
###################################################################

$IDProcess = Get-Process | Where-Object {$_.ProcessName -ceq 'DDM'} | Select-Object -ExpandProperty ID
Stop-Process -Id $IDProcess -Force

Start-Process $ApplicationID_current -ArgumentList '/S' -Wait