<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.1
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
    1.0.1   cleanup folder "Dell Display and Peripheral Manager" if parts stay after uninstall

#>

<#
.Synopsis
   This PowerShell is for uninstall in Microsoft MEM for Dell Display and Peripheral Manager 2.x

.DESCRIPTION
   This PowerShell will uninstall a Device for Dell Display and Peripheral Manager 2.x. It will be used as install file in Microsoft MEM win32 install.
   
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
$SoftwareName = "Dell Display and Peripheral Manager"
$ProgramPathUninstall = $env:ProgramFiles + "\Dell\Dell Display and Peripheral Manager\Installer\"
$ProgramPath = $env:ProgramFiles + "\Dell\Dell Display and Peripheral Manager\"
$ProgramName = "DDPM.exe"
$ProgramNameUninstall = "setup.exe"
$Argument = "/uninst /silent"

##############################################
#### program section                      ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

#  check if installed
$CheckInstalled = Get-installedcheck -FilePath $ProgramPath -FileName $ProgramName

if($CheckInstalled -eq $true)
    {
        # get version of program
        [Version]$ProgramVersion_current = (Get-Command $ProgramPath$ProgramName).FileVersionInfo.FileVersion

        # uninstall Software
        try
            {
                $UninstallPath = Join-Path $ProgramPathUninstall $ProgramNameUninstall
                Start-Process -WorkingDirectory $ProgramPathUninstall -FilePath $ProgramNameUninstall -ArgumentList $Argument -Wait -ErrorAction Stop

                # check cleanup folder
                $Checkfolder = Test-Path $ProgramPath

                if($Checkfolder -eq $true)
                    {
                        Write-Information "DDPM directory still found will deleted now"
                        Remove-Item -Path $ProgramPath -Recurse -Force
                    }

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
            }
    }
else 
    {
        Write-Host "software not found" -BackgroundColor Green

        $UninstallData = [PSCustomObject]@{
                                              Software = $SoftwareName
                                              Version = "not found"
                                              Uninstall = $true
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
    }