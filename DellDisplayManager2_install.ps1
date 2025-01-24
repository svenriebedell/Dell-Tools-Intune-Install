<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.0
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
    1.1.2   adding disable Telemetry to the install parameter

#>

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Display Manager

.DESCRIPTION
   This PowerShell will install/Display Manager a Device for Dell Display Manager. It will be used as install file in Microsoft MEM win32 install.
   
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
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.FileVersion
$AppSearch = "ddm.exe" #Parameter to search in registry
$SoftwareName = "Dell Display Manager 2"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore


###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

If ((Get-installedcheck) -eq $true )
    {
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

        if ($ProgramVersion_target -gt $ProgramVersion_current)
            {
        
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
        

            }

        Else
            {
                Write-Host "same version is installed"

                $UninstallData = [PSCustomObject]@{
                                          Software = $SoftwareName
                                          Version = ($ProgramVersion_target).ToString()
                                          Install = $false
                                          Reason = "same version is installed"
                                 } | ConvertTo-Json
                
                Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData




                Exit 0
            }
    }
Else
    {
        Write-Host "No Dell Display Manager 2 was installed"
    }

###################################################################
#Install new Software                                             #
###################################################################
Start-Process -FilePath $ProgramPath -ArgumentList '/verysilent /TelemetryConsent="disable" /NotifyUpdate="disable"'
Start-Sleep -Seconds 10

#############################
# install success check     #
#############################
$UninstallResult = Get-installedcheck

If ($UninstallResult -ne $true)
    {

        Write-Host "install is unsuccessful" -BackgroundColor Red
            
        $UninstallData = [PSCustomObject]@{
                                            Software = $SoftwareName
                                            Version = ($ProgramVersion_target).ToString()
                                            Install = $false
                                            Reason = "Installation failed"
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Error -EventId 11 -Message $UninstallData

    }
Else
    {

       [Version]$ProgramVersion_current = (Get-ItemProperty -Path 'C:\Program Files\Dell\Dell Display Manager 2\DDM.exe').VersionInfo | Select-Object -ExpandProperty FileVersion

       If ($ProgramVersion_current -ge $ProgramVersion_target)
            {
            
                Write-Host "install is successful" -BackgroundColor Green
            
                $UninstallData = [PSCustomObject]@{
                                                    Software = $SoftwareName
                                                    Version = ($ProgramVersion_target).ToString()
                                                    Install = $true
                                                    Reason = "Update/Install/Newer Version"
                                                  } | ConvertTo-Json
                
               Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData
                
            }
       Else
            {
                            
            
               Write-Host "install is unsuccessful" -BackgroundColor red

            
               $UninstallData = [PSCustomObject]@{
                                                   Software = $SoftwareName
                                                   Version = ($ProgramVersion_target).ToString()
                                                   Install = $false
                                                   Reason = "Older Version installed $ProgramVersion_current"
                                                 } | ConvertTo-Json
                
               Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData


            }

    }