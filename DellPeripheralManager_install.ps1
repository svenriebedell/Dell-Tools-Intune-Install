<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.0
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

<#

Change Log
    1.0.0   initial version
    1.1.0   add check if uninstall/install is successful
            add MS EventLog LogName "Dell" Source "Dell Software Install" and "Dell Software Uninstall"


#>

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Peripheral Manager

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell Peripheral Manager. It will be used as install file in Microsoft MEM win32 install.
   
#>



##############################################
#### variable section                     ####
##############################################
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion
$SoftwareName = "Dell Peripheral Manager"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

##### Check first if Dell Peripheral Manager is installed by looking file path
$CheckInstall = Test-path -path 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe'

if($CheckInstall -eq $true)
   {
        [Version]$ProgramVersion_current = (Get-ItemProperty 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe').VersionInfo | Select-Object -ExpandProperty ProductVersion
        $ApplicationPath = "C:\Program Files\Dell\Dell Peripheral Manager\"
        $NameUninstallFile = "Uninstall.exe"
   }
else 
    {
        [Version]$ProgramVersion_current = $null
    }

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

If ($ProgramVersion_current -ne $null)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
            Start-Process -FilePath $ApplicationPath\$NameUninstallFile -ArgumentList "/S" -Wait 

            #############################
            # uninstall success check   #
            #############################
            $UninstallResult = Test-path -path 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe'

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

Start-Process -FilePath "$ProgramPath" -ArgumentList "/S" -Wait

#############################
# install success check     #
#############################
$UninstallResult = Test-path -path 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe'

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

       [Version]$ProgramVersion_current = (Get-ItemProperty 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe').VersionInfo | Select-Object -ExpandProperty ProductVersion

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