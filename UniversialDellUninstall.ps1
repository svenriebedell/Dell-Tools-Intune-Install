<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0
_Dev_Status_ = Test
Copyright ©2026 Dell Inc. or its subsidiaries. All Rights Reserved.

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
.Synopsis
   This PowerShell is for uninstall Dell tools by Name and in Microsoft Intune or other solutions like this.

.DESCRIPTION
   This PowerShell will check if the requested Dell Software is installed and uninstall it.
   This script support the following applications
        - Dell Core Services
        - Dell SupportAssist
        - Dell SupportAssist OS Recovery
        - Dell Display and Peripheral Manager
        - Dell Client Device Manager
        - Dell Command | Update (Universal App and Classic)
        - Dell Command | Configure
        - Dell Command | Endpoint Configure for Microsoft Intune
        - Dell Command | Monitor
        - Dell Trusted Device
        - Dell Optimizer
        - Dell Device Management Agent
        - Microsoft Windows Desktop Runtime (because some Dell tools require this as preparation)

        .Parameter DellTool
        Value is the Name of Dell Application to looking for like example Dell Trusted Device

        .Parameter VersionIS
        Value is the operator for the version compare supported are:
            - Equal
            - Not equal
            - Less than
            - Less than or equal
            - Greater than
            - Greater than or equal

        .Parameter Version
        Value is the version of Dell Application to looking for like 5.6.0 or 2.2.0.19 depends on the tool.


        Changelog:
            1.0.0   Initial Version

        .Example
        This will looking if Dell Command | Update is installed and uninstall this software
        UniversialDellUninstall.ps1 -DellTool 'Dell Command | Update'

#>
param(
            [Parameter(mandatory=$true)][ValidateSet("Dell Core Services","Dell SupportAssist","Dell SupportAssist OS Recovery","Dell Display and Peripheral Manager","Dell Client Device Manager","Dell Command | Update","Dell Command | Configure","Dell Command | Endpoint Configure for Microsoft Intune","Dell Command | Monitor","Dell Trusted Device","Dell Optimizer","Dell Device Management Agent","Microsoft Windows Desktop Runtime")][String]$DellTool="Dell Command | Update"
    )

##################################################
# Varible Section                            #####
##################################################
$DellSoftwareList = @(
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist OS Recovery"; SearchString = "Dell SupportAssist OS Recovery*"; UninstallType = "msi"; UninstallString = "msiexec /x";SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Core Services"; SearchString = "Dell Core Services"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist"; SearchString = "Dell Supportassist"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Display and Peripheral Manager"; SearchString = "Dell Display and Peripheral Manager"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Client Device Manager"; SearchString = "Dell Client Device Manager"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Update"; SearchString = "Dell Command | Update*"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Configure"; SearchString = "Dell Command | Configure"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Endpoint Configure for Microsoft Intune"; SearchString = "Dell Command | Endpoint Configure for Microsoft Intune"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Monitor"; SearchString = "Dell Command | Monitor"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Trusted Device"; SearchString = "Dell Trusted Device"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Optimizer"; SearchString = "Dell Optimizer"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Device Management Agent"; SearchString = "Dell Device Management Agent"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Microsoft Windows Desktop Runtime"; SearchString = "Microsoft Windows Desktop Runtime*(x64)*"; UninstallType = "msi"; UninstallString = "msiexec /x"; SilentSwitch = "/qn"}
                    )

##################################################
# Function Section                           #####
##################################################
function Test-SoftwareInstalled
    {
        param(
                    [Parameter(Mandatory)][string]$NamePattern,
                    [Parameter(Mandatory)][string]$ISPattern,
                    [Parameter(Mandatory)][Version]$VersionPattern
            )

        # Uninstall-Path (64-bit & 32-bit)
        $paths = @(
                    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )

        $items = foreach ($path in $paths)
            {
                try
                    {
                        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                    }
                catch
                    {
                        Write-Output "Path no found" | Out-Null
                    }
            }

        # Search for DisplayName and DisplayVersion with different operators for DisplayVersion
        ## Equal
        If ($ISPattern -eq "Equal")
            {
                If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                    {
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and [version]$_.DisplayVersion -eq $VersionPattern ) }
                    }
                else
                    {
                        # get Version of MS Runtime only by WOW6232Node possible
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.PSParentPath -like "*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -and [version]$_.DisplayVersion -eq $VersionPattern ) }
                    }
            }
        ## Not equal
        elseIf ($ISPattern -eq "Not equal")
            {
                If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                    {
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and [version]$_.DisplayVersion -ne $VersionPattern ) }
                    }
                else
                    {
                        # get Version of MS Runtime only by WOW6232Node possible
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.PSParentPath -like "*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -and [version]$_.DisplayVersion -ne $VersionPattern ) }
                    }
            }
        ## Less than
        elseIf ($ISPattern -eq "Less than")
            {
                If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                    {
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and [version]$_.DisplayVersion -lt $VersionPattern ) }
                    }
                else
                    {
                        # get Version of MS Runtime only by WOW6232Node possible
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.PSParentPath -like "*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -and [version]$_.DisplayVersion -lt $VersionPattern ) }
                    }
            }
        ## Less than or equal
        elseIf ($ISPattern -eq "Less than or equal")
            {
                If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                    {
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and [version]$_.DisplayVersion -le $VersionPattern ) }
                    }
                else
                    {
                        # get Version of MS Runtime only by WOW6232Node possible
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.PSParentPath -like "*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -and [version]$_.DisplayVersion -le $VersionPattern ) }
                    }
            }
        ## Greater than
        elseIf ($ISPattern -eq "Greater than")
            {
                If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                    {
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and [version]$_.DisplayVersion -gt $VersionPattern ) }
                    }
                else
                    {
                        # get Version of MS Runtime only by WOW6232Node possible
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.PSParentPath -like "*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -and [version]$_.DisplayVersion -gt $VersionPattern ) }
                    }
            }
        ## Greater than or equal
        elseIf ($ISPattern -eq "Greater than or equal")
            {
                If ($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
                    {
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and [version]$_.DisplayVersion -ge $VersionPattern ) }
                    }
                else
                    {
                        # get Version of MS Runtime only by WOW6232Node possible
                        $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.PSParentPath -like "*\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -and [version]$_.DisplayVersion -ge $VersionPattern ) }
                    }
            }
        else
            {
                exit 1
            }
        return $match
    }

function Uninstall-DellTool
    {
        param
            (
                [Parameter(Mandatory)][string]$NamePattern,
                [Parameter(Mandatory)][string]$UninstallType,
                [Parameter(Mandatory)][string]$AppID
            )

        If ($UninstallType -eq "MSI")
            {
                # Uninstall by MSI
                try
                    {
                        Start-Process "msiexec.exe" -ArgumentList "/x $AppID /qn /norestart" -Wait -NoNewWindow
                        Return $true
                    }
                catch
                    {
                        Write-Verbose "Failed to uninstall $NamePattern" -Verbose
                        Return $false
                    }
            }
        else
            {
                #Uninstall by Full uninstall string
                try
                    {
                        Return $true
                    }
                catch
                    {
                        Write-Verbose "Failed to uninstall $NamePattern" -Verbose
                        Return $false
                    }
            }
    }
##################################################
# Program Section                            #####
##################################################

#### generate Logging Resources
try
    {
        [System.Diagnostics.EventLog]::CreateEventSource("Dell Software Uninstall", "Dell")
        Write-Verbose "Event source Dell Software Uninstall created for log Dell." -Verbose
    }
catch
    {
        Write-Verbose "Event source Dell Software Uninstall fail to create for log Dell." -Verbose
        return $false
    }

#### Check if installed and if yes uninstall application
Try
    {
        # select the searchstring for function
        $SoftwareName = $DellSoftwareList | where-object {$_.NameParameter -eq $DellTool} | select-object -ExpandProperty Searchstring

        #### get Software details
        $SoftwareDetails =Test-SoftwareInstalled -NamePattern $SoftwareName -VersionPattern 0.0.0.0 -ISPattern "Greater than"

        If($null -ne $SoftwareDetails)
            {
                Write-Verbose "$($SoftwareDetails.DisplayName) is installed with version $($SoftwareDetails.DisplayVersion)" -Verbose
                $UninstallData = [PSCustomObject]@{
                                                      Software = $($SoftwareDetails.DisplayName)
                                                      Version = $($SoftwareDetails.DisplayVersion)
                                                      Uninstall = "started now"
                                                  } | ConvertTo-Json

                Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData


                # call uninstall function
                Uninstall-Software -NamePattern $SoftwareName -UninstallType $SoftwareDetails.UninstallType -AppID $SoftwareDetails.AppID
            }
        else
            {
                Write-Verbose "$DellTool is not installed script will exit here" -Verbose

                $UninstallData = [PSCustomObject]@{
                                                      Software = $DellTool
                                                      Version = "not installed"
                                                      Uninstall = $true
                                                  } | ConvertTo-Json

                Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                Exit 0
            }
    }
Catch
    {
        Write-Output "Script failed: $($_.Exception.Message)"
        Exit 1
    }