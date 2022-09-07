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
   This PowerShell is for installation in Microsoft MEM for Dell SupportAssist Business

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell SupportAssist Business. It will be used as install file in Microsoft MEM win32 install.
   
#>

##### Variables
$InstallerName = Get-ChildItem .\*.msi | Select-Object -ExpandProperty Name
$ProgramPath = $InstallerName
[Version]$ProgramVersion_target = "3.2.0.87"  #need to change to Version of MSI File
[Version]$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Support%Business%'" | select -ExpandProperty Version
#$ApplicationID_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Support%Business%'" | Select-Object -ExpandProperty IdentifyingNumber
$Argumentstring = '/i ' + '"' + $ProgramPath + '" TRANSFORMS="SupportAssistConfig.mst" DEPLOYMENTKEY="Dell2022#" /qn'


###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################


If ($ProgramVersion_current -ne $null)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
        Start-Process -FilePath msiexec.exe -ArgumentList "/x $ApplicationID_current /qn" -Wait
       
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

Start-Process -FilePath msiexec.exe -ArgumentList $Argumentstring -Wait