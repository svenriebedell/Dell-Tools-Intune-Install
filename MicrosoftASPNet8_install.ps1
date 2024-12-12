<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.0
_Dev_Status_ = Test
Copyright © 2024 Dell Inc. or its subsidiaries. All Rights Reserved.

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

Changelog
    1.0.0   initial version

#>

<#
.Synopsis
   This PowerShell is for install Microsoft ASP .net 8.x by Intune

.DESCRIPTION
   This PowerShell will install Microsoft ASP .net 8.x on the device. It will be used as install file in Microsoft MEM win32 install.
   
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
$ApplicationID_current = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "Microsoft*ASP*Core*8*(x64)*" } | Select-Object -ExpandProperty Quietuninstallstring 
$AppSearch = "Microsoft%Windows%%Runtime%8%(x64)%" #Parameter to search in registry
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion
[Version]$ProgramVersion_current = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "Microsoft*ASP*Core*8*(x64)*" } | Select-Object -ExpandProperty DisplayVersion

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

If ($ProgramVersion_current -ne $null)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
            
            #############################
            # uninstall Software old    #
            #############################
            
            Start-Process cmd.exe -ArgumentList '/c',$ApplicationID_current -Wait -NoNewWindow

            #############################
            # uninstall success check   #
            #############################
            $UninstallResult = Get-installedcheck -AppSearchString $AppSearch

            If ($UninstallResult -eq $true)
                {

                    Write-Host "uninstall is unsuccessful" -BackgroundColor Red
                    #Exit 1

                }
            Else
                {

                    Write-Host "uninstall is successful" -BackgroundColor Green
                    #Exit 0

                }
        }

    Else
        {
            Write-Host "same version is installed"
            Exit 0
        }
    }


###################################################################
#Install new Software                                             #
###################################################################

Start-Process -FilePath "$ProgramPath" -ArgumentList "/install /quiet /norestart" -Wait

#############################
# install success check   #
#############################
$UninstallResult = Get-installedcheck -AppSearchString $AppSearch

If ($UninstallResult -ne $true)
    {

        Write-Host "install is unsuccessful" -BackgroundColor Red
        #Exit 1

    }
Else
    {

        Write-Host "install is successful" -BackgroundColor Green
        #Exit 0

    }