<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.0
_Dev_Status_ = Test
Copyright ©2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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
                [Parameter(mandatory=$true)][string] $AppSearchString
            )


        $AppCheck = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "$AppSearchString" }


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
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion
$AppSearch = "Dell Display Manager" #Parameter to search in registry
$Program_current = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "$AppSearch" }
[Version]$ProgramVersion_current = $Program_current.DisplayVersion
$ApplicationID_current = $Program_current.QuietUninstallString
$SoftwareName = $Program_current.DisplayName + " 1"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

If ($null -ne $ProgramVersion_current)
    {


    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
    
            $IDProcess = Get-Process | Where-Object {$_.ProcessName -like 'ddm'} | Select-Object -ExpandProperty ID
            Stop-Process -Id $IDProcess -Force
            Start-Process cmd.exe -ArgumentList '/c',$ApplicationID_current -Wait

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
                                          Version = $Program_current.DisplayVersion
                                          Uninstall = $false
                                     } | ConvertTo-Json
                
                    Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Error -EventId 11 -Message $UninstallData


                }
            Else
                {

                    Write-Host "uninstall is successful" -BackgroundColor Green

                    $UninstallData = [PSCustomObject]@{
                                          Software = $SoftwareName
                                          Version = $Program_current.DisplayVersion
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

###################################################################
#Install new Software                                             #
###################################################################

Start-Process -FilePath ".\ddmsetup.exe" -ArgumentList '/verysilent /noupdate'
Start-Sleep -Seconds 15
Start-Process -FilePath "C:\Program Files (x86)\Dell\Dell Display Manager\ddm.exe"

#############################
# install success check     #
#############################
$Program_current = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "$AppSearch" }
$SoftwareName = $Program_current.DisplayName + " 1"
$UninstallResult = Get-installedcheck -AppSearchString $AppSearch

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

       [Version]$ProgramVersion_current = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match "Dell Display Manager" } | Select-Object -ExpandProperty DisplayVersion

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