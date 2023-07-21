<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.2.0
_Dev_Status_ = Test
Copyright (c)2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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

<#Change log
    
    1.0.0   initial version
    1.1.0   Update Filter
    1.2.0   problems with GUID move to PackageCache to uninstall MSI.
            add function get-installedcheck to control if uninstall is successful
            add MS EventLog LogName "Dell" Source "Dell Software Uninstall"

#>

<#
.Synopsis
   This PowerShell is for uninstall in Microsoft MEM for Dell Command | Update

.DESCRIPTION
   This PowerShell will uninstall a Device for Dell Command | Update. It will be used as install file in Microsoft MEM win32 install.
   
#>

##############################################
#### Function section                     ####
##############################################

function Get-installedcheck
    {

        param
            (
                [Parameter(mandatory=$true)][string] $AppSearchString
            )


        $AppCheck = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearchString'"

        If ($null -ne $AppCheck)
            {
                return $true
            }
        Else
            {
                return $false
            }

    }


##############################################
#### variable section                     ####
##############################################
$UninstallApp = Get-CimInstance -ClassName Win32_Product | Where-Object {$_.Name -like "Dell*Command*Update*"}
$AppSearch = "%Dell Command%Update%" #Parameter to search in registry
$SoftwareName = $UninstallApp.Name


##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

#############################
# uninstall Software        #
#############################
$Argument = "/x "+ $UninstallApp.PackageCache + " /qn"
Start-Process -FilePath msiexec.exe -ArgumentList "$Argument" -Wait

#############################
# uninstall success check   #
#############################
$UninstallResult = Get-installedcheck -AppSearchString $AppSearch

If ($UninstallResult -eq $true)
    {

        Write-Host "uninstall is unsuccessful" -BackgroundColor Red

        $UninstallData = [PSCustomObject]@{
                                              Software = $SoftwareName
                                              Version = $UninstallApp.Version
                                              Uninstall = $false
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Error -EventId 11 -Message $UninstallData


    }
Else
    {

        Write-Host "uninstall is successful" -BackgroundColor Green

        $UninstallData = [PSCustomObject]@{
                                            Software = $SoftwareName
                                            Version = $UninstallApp.Version
                                            Uninstall = $true
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData

    }