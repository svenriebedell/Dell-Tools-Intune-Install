<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.0
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

#>

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Display Manager

.DESCRIPTION
   This PowerShell will install/Display Manager a Device for . It will be used as install file in Microsoft MEM win32 install.
   
#>

##############################################
#### Function section                     ####
##############################################

function Get-installedcheck
    {

        param
            (
                [Parameter(Mandatory=$true)]$FilePath,
                [Parameter(Mandatory=$true)]$FileName
            )

        $AppCheck = Test-Path -Path $FilePath$FileName

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
$ProgramPathInstall = $env:ProgramFiles + "\Dell\Dell Display and Peripheral Manager\"
$ProgramNameInstall = "DDPM.exe"
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.FileVersion
$SoftwareName = "Dell Display and Peripheral Manager"
$Argument = "/Silent /TelemetryConsent=false /InAppUpdateLock"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore


###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

$ExistCheck = Get-installedcheck -FilePath $ProgramPathInstall -FileName $ProgramNameInstall

If ($ExistCheck -eq $true )
    {
        # get version of program
        [Version]$ProgramVersion_current = (Get-Command $ProgramPathInstall$ProgramNameInstall).FileVersionInfo.FileVersion

        if ($ProgramVersion_target -gt $ProgramVersion_current)
            {
                # uninstall Software
                try
                    {
                        Start-Process -FilePath $ProgramPathUninstall$ProgramNameUninstall -ArgumentList $Argument -Wait -ErrorAction Stop

                        Write-Host "uninstall is successful" -BackgroundColor Green

                        $UninstallData = [PSCustomObject]@{
                                                            Software = $SoftwareName
                                                            Version = ($ProgramVersion_current).ToString()
                                                            Uninstall = $true
                                                        } | ConvertTo-Json
                                
                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                    }
                catch
                    {
                        Write-Host "uninstall is unsuccessful" -BackgroundColor Red

                        $UninstallData = [PSCustomObject]@{
                                                            Software = $SoftwareName
                                                            Version = ($ProgramVersion_current).ToString()
                                                            Uninstall = $false
                                                        } | ConvertTo-Json
                                
                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Error -EventId 11 -Message $UninstallData

                        Exit 1
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
        Write-Host "No Dell Display and Peripheral Manager installed"
    }

###################################################################
#Install new Software                                             #
###################################################################
try
    {
        Start-Process -FilePath $ProgramPath -ArgumentList $Argument -Wait -ErrorAction Stop
        Write-Host "install is successful" -BackgroundColor Green
            
        $UninstallData = [PSCustomObject]@{
                                            Software = $SoftwareName
                                            Version = ($ProgramVersion_target).ToString()
                                            Install = $true
                                            Reason = "Update/Install/Newer Version"
                                          } | ConvertTo-Json
        
       Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData
    }
catch
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