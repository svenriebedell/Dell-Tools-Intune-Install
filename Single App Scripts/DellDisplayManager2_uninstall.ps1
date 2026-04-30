<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.1
_Dev_Status_ = Test
Copyright (c)2024 Dell Inc. or its subsidiaries. All Rights Reserved.

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

Change Log
    1.0.0   initial version
    1.1.0   add function get-installedcheck to control if uninstall/install is successful
            add MS EventLog LogName "Dell" Source "Dell Software Install" and "Dell Software Uninstall"
    1.1.1   correct issue to get program version

#>

<#
.Synopsis
   This PowerShell is for uninstall in Microsoft MEM for Dell Display Manager

.DESCRIPTION
   This PowerShell will uninstall a Device for Dell Display Manager. It will be used as install file in Microsoft MEM win32 install.
   
#>


##############################################
#### Function section                     ####
##############################################

function Get-installedcheck
    {

        param
            (
                
            )


        $AppCheck = Test-Path -Path 'C:\Program Files\Dell\Dell Display Manager 2\ddm.exe' #cover new folder
        If ($false -ne $AppCheck)
            {
                return $true
            }
        Else
            {
                $AppCheck = Test-Path -Path 'C:\Program Files\Dell\Dell Display Manager 2.0\ddm.exe' #cover old folder
                Write-Host "Old DDM Folder used by installation"
            }
                
        

        If ($false -ne $AppCheck)
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
$AppSearch = "ddm.exe" #Parameter to search in registry
$SoftwareName = "Dell Display Manager 2"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

# get version of existing installation#
$CheckFolder = Test-Path -Path 'C:\Program Files\Dell\Dell Display Manager 2\DDM.exe'
        

if ($false -eq $CheckFolder)
    {
            
        # get version of existing installation based old folder
        [Version]$ProgramVersion_current = (Get-ItemProperty -Path 'C:\Program Files\Dell\Dell Display Manager 2.0\DDM.exe').VersionInfo | Select-Object -ExpandProperty FileVersion
        $ApplicationID_current = "C:\Program Files\Dell\Dell Display Manager 2.0\Uninst.exe"
            
    }
Else
    {
                
        # get version of existing installation based new folder
        [Version]$ProgramVersion_current = (Get-ItemProperty -Path 'C:\Program Files\Dell\Dell Display Manager 2\DDM.exe').VersionInfo | Select-Object -ExpandProperty FileVersion
        $ApplicationID_current = "C:\Program Files\Dell\Dell Display Manager 2\Uninst.exe"
            
    }

        
$IDProcess = Get-Process | Where-Object {$_.ProcessName -ceq 'DDM'} | Select-Object -ExpandProperty ID

if ($null -ne $IDProcess)
    {

        Stop-Process -Id $IDProcess -Force

    }
                
                
Start-Process -FilePath $ApplicationID_current -ArgumentList "/S" -Wait
Start-Sleep -Seconds 10


#############################
# uninstall success check   #
#############################
$UninstallResult = Get-installedcheck -AppSearchString $AppSearch

If ($UninstallResult -eq $true)
    {

        Write-Host "uninstall is unsuccessful" -BackgroundColor Red

        $UninstallData = [PSCustomObject]@{
                                              Software = $SoftwareName
                                              Version = ($ProgramVersion_current).ToString()
                                              Uninstall = $false
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Error -EventId 11 -Message $UninstallData


    }
Else
    {

        Write-Host "uninstall is successful" -BackgroundColor Green

        $UninstallData = [PSCustomObject]@{
                                              Software = $SoftwareName
                                              Version = ($ProgramVersion_current).ToString()
                                              Uninstall = $true
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData

     }