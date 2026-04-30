<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.0
_Dev_Status_ = Test
Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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
    1.1.0   add MS EventLog LogName "Dell" Source "Dell Software Uninstall"

#>

<#
.Synopsis
   This PowerShell is for uninstall in Microsoft MEM for Dell Peripheral Manager

.DESCRIPTION
   This PowerShell will uninstall a Device for Dell Peripheral Manager. It will be used as install file in Microsoft MEM win32 install.
   
#>

##############################################
#### variable section                     ####
##############################################
$SoftwareName = "Dell Peripheral Manager"
$ApplicationPath = "C:\Program Files\Dell\Dell Peripheral Manager\"
$NameUninstallFile = "Uninstall.exe"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

#############################
# uninstall Software        #
#############################
##### Check first if Dell Peripheral Manager is installed by looking registry path
$DDMPath = $ApplicationPath + "DPM.exe"
$CheckInstall = Test-path -path $DDMPath

if($CheckInstall -eq $true)
   {
      
      ##### Variables
      $ProgramVersion_current = (Get-ItemProperty $DDMPath).VersionInfo | Select-Object -ExpandProperty ProductVersion

      ###################################################################
      #uninstall Software                                               #
      ###################################################################

      Start-Process -FilePath $ApplicationPath\$NameUninstallFile -ArgumentList "/S" -Wait -NoNewWindow

      #############################
      # uninstall success check   #
      #############################
      $UninstallResult = Test-path -path 'C:\Program Files\Dell\Dell Peripheral Manager\DPM.exe'

      If ($UninstallResult -eq $true)
        {

            Write-Host "uninstall is unsuccessful" -BackgroundColor Red

            $UninstallData = [PSCustomObject]@{
                                                  Software = $SoftwareName
                                                  Version = $ProgramVersion_current
                                                  Uninstall = $false
                                              } | ConvertTo-Json
                
            Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Error -EventId 11 -Message $UninstallData


        }
      Else
        {

            Write-Host "uninstall is successful" -BackgroundColor Green

            $UninstallData = [PSCustomObject]@{
                                                Software = $SoftwareName
                                                Version = $ProgramVersion_current
                                                Uninstall = $true
                                              } | ConvertTo-Json
                
            Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData

        }
    }