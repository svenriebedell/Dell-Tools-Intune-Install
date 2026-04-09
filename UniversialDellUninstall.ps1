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
            [Parameter(mandatory=$true)][ValidateSet("Dell Core Services","Dell Digital Delivery","Dell Peripheral Core","Dell SupportAssist","Dell SupportAssist OS Recovery","Dell SupportAssist OS Recovery Plugin for Dell Update","Dell Display and Peripheral Manager","Dell Client Device Manager","Dell Command | Update","Dell Command | Configure","Dell Command | Endpoint Configure for Microsoft Intune","Dell Command | Monitor","Dell Trusted Device","Dell Optimizer","Dell Device Management Agent","Dell Pair","Microsoft Windows Desktop Runtime")][String]$DellTool="Dell Display and Peripheral Manager"
    )

##################################################
# Varible Section                            #####
##################################################
$DellSoftwareList = @(
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist OS Recovery"; SearchString = "Dell SupportAssist OS Recovery*";SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist OS Recovery Plugin for Dell Update"; SearchString = "Dell SupportAssist OS Recovery Plugin for Dell Update";SilentSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Core Services"; SearchString = "Dell Core Services"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist"; SearchString = "Dell Supportassist"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Display and Peripheral Manager"; SearchString = "Dell Display and Peripheral Manager"; SilentSwitch = "/uninst /silent"}
                        [PSCustomObject]@{NameParameter = "Dell Client Device Manager"; SearchString = "Dell Client Device Manager"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Update"; SearchString = "Dell Command | Update*"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Configure"; SearchString = "Dell Command | Configure"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Endpoint Configure for Microsoft Intune"; SearchString = "Dell Command | Endpoint Configure for Microsoft Intune"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Monitor"; SearchString = "Dell Command | Monitor"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Trusted Device"; SearchString = "Dell Trusted Device"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Optimizer"; SearchString = "Dell Optimizer"; SilentSwitch = "/Silent"}
                        [PSCustomObject]@{NameParameter = "Dell Device Management Agent"; SearchString = "Dell Device Management Agent"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Pair"; SearchString = "Dell Pair"; SilentSwitch = "/S"}
                        [PSCustomObject]@{NameParameter = "Dell Peripheral Core"; SearchString = "Dell Peripheral Core"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Dell Digital Delivery"; SearchString = "Dell Digital Delivery*"; SilentSwitch = "/qn"}
                        [PSCustomObject]@{NameParameter = "Microsoft Windows Desktop Runtime"; SearchString = "Microsoft Windows Desktop Runtime*(x64)*"; SilentSwitch = "/qn"}
                    )

# Operation translation
$opMap = @{
            "Equal"                 = "-eq"
            "Not equal"             = "-ne"
            "Less than"             = "-lt"
            "Less than or equal"    = "-le"
            "Greater than"          = "-gt"
            "Greater than or equal" = "-ge"
        }

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
                        If ($NamePattern -ne "Dell Optimizer")
                            {
                                Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                            }
                        else
                            {
                                Get-ItemProperty -Path $path -ErrorAction SilentlyContinue #| Where-Object {$_.InstallLocation -eq $null}
                            }
                    }
                catch
                    {
                        Write-Output "Path no found" | Out-Null
                    }
            }

        $operator = $opMap[$ISPattern]

        if($NamePattern -ne "Microsoft Windows Desktop Runtime*(x64)*")
            {
                $match = $items | Where-Object {$_.DisplayName -like $NamePattern -and (Invoke-Expression "[version]'$($_.DisplayVersion)' $operator [version]'$VersionPattern'")}
            }
        else
            {
                $match = $items | Where-Object {$_.DisplayName -like $NamePattern -and $_.PSParentPath -like "*\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -and (Invoke-Expression "[version]'$($_.DisplayVersion)' $operator [version]'$VersionPattern'")}
            }

        return $match
    }

function Uninstall-DellTool
    {
        param
            (
                [Parameter(Mandatory)][string]$NamePattern,
                [Parameter(Mandatory)][string]$AppID,
                [Parameter(Mandatory)][string]$UninstallString
            )

        # Uninstall by MSI
        if ($UninstallString -like "*msiexec*")
            {
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
        # Uninstall by executable
        elseif ($null -ne $UninstallString)
            {
                try
                    {
                        # select the searchstring for function
                        $Software = $DellSoftwareList | where-object {$_.NameParameter -eq $NamePattern}
                        $UninstallParameter = $Software.SilentSwitch

                        # prepare uninstall string
                        $ArgumentString = $UninstallString + " " + $UninstallParameter

                        Start-Process cmd.exe -ArgumentList "/c",$ArgumentString -Wait -NoNewWindow
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
                Write-Verbose "No uninstall string found for $NamePattern" -Verbose
                Return $false
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
        Write-Verbose "Event source Dell Software Uninstall exist." -Verbose
    }

#### Check if installed and if yes uninstall application
Try
    {
        # select the searchstring for function
        $Software = $DellSoftwareList | where-object {$_.NameParameter -eq $DellTool}

        #### get Software details
        $SoftwareDetails = Test-SoftwareInstalled -NamePattern $Software.SearchString -VersionPattern 0.0.0.0 -ISPattern "Greater than"

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
                $UninstallResult = Uninstall-DellTool -NamePattern $Software.NameParameter -AppID $SoftwareDetails.PSChildName -UninstallString $SoftwareDetails.UninstallString

                # Logging uninstall result
                if($UninstallResult -eq $true)
                    {
                        Write-Verbose "$DellTool is uninstalled successfully" -Verbose

                        $UninstallData = [PSCustomObject]@{
                                                            Software = $DellTool
                                                            Version = $($SoftwareDetails.DisplayVersion)
                                                            Uninstall = $true
                                                        } | ConvertTo-Json

                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                        Exit 0
                    }
                else
                    {
                        Write-Verbose "$DellTool uninstall failed" -Verbose

                        $UninstallData = [PSCustomObject]@{
                                                            Software = $DellTool
                                                            Version = $($SoftwareDetails.DisplayVersion)
                                                            Uninstall = $false
                                                        } | ConvertTo-Json

                        Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData
                        Exit 0
                    }
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