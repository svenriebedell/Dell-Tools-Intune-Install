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

<#Change Log
    1.0.0     initial version
    1.1.0     add function get-msifileversion no more needed to edit var $ProgramVersion_target any more
              add MS EventLog LogName "Dell" Source "Dell Software Install" and "Dell Software Uninstall"
    1.2.0     Installer migrated from MSI to DUP Format change script to run with the new format

#>

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Trusted Device

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell Trusted Device. It will be used as install file in Microsoft MEM win32 install.
   
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
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion
$AppSearch = "%Dell%Trusted%Device%" #Parameter to search in registry
$UninstallApp = Get-CimInstance -ClassName Win32_Product | Where-Object {$_.Name -like "Dell*Trusted*Device*"}
$SoftwareName = "Dell Trusted Device Agent"
[Version]$ProgramVersion_current = $UninstallApp.Version

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
            #############################
            # uninstall Software old    #
            #############################
            $Argument = "/x "+ $UninstallApp.PackageCache + " /qn REBOOT=ReallySuppress"
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


###################################################################
#Install new Software                                             #
###################################################################

Start-Process -FilePath "$ProgramPath" -ArgumentList "/s" -Wait

#############################
# install success check     #
#############################
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

       [Version]$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'" | Select-Object -ExpandProperty Version

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