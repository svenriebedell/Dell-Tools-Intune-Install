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
   This PowerShell is for custom detection in Microsoft Intune or other solutions like this to detect Dell Tool by Name and Version.

.DESCRIPTION
   This PowerShell will check if the requested Dell Software is installed and checking if the Version is correct. As far the Software found by Name and the version is matched the script will return a "Found it"

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
        This will looking if Dell Command | Update is installed and the version must be equal 5.6.0
        UniversialDellDetect.ps1 -DellTool 'Dell Command | Update' -VersionIS Equal -Version 5.6.0

#>
param(
            [Parameter(mandatory=$true)][ValidateSet("Dell Core Services","Dell SupportAssist","Dell SupportAssist OS Recovery","Dell Display and Peripheral Manager","Dell Client Device Manager","Dell Command | Update","Dell Command | Configure","Dell Command | Endpoint Configure for Microsoft Intune","Dell Command | Monitor","Dell Trusted Device","Dell Optimizer","Dell Device Management Agent","Microsoft Windows Desktop Runtime")][String]$DellTool,
            [Parameter(mandatory=$true)][ValidateSet("Equal","Not equal","Less than","Less than or equal","Greater than","Greater than or equal")][String]$VersionIS,
            [Parameter(mandatory=$true)][Version]$Version
    )

##################################################
# Varible Section                            #####
##################################################
$DellSoftwareList = @(
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist OS Recovery"; SearchString = "Dell SupportAssist OS Recovery*"}                        
                        [PSCustomObject]@{NameParameter = "Dell Core Services"; SearchString = "Dell Core Services"}
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist"; SearchString = "Dell Supportassist"}
                        [PSCustomObject]@{NameParameter = "Dell Display and Peripheral Manager"; SearchString = "Dell Display and Peripheral Manager"}
                        [PSCustomObject]@{NameParameter = "Dell Client Device Manager"; SearchString = "Dell Client Device Manager"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Update"; SearchString = "Dell Command | Update*"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Configure"; SearchString = "Dell Command | Configure"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Endpoint Configure for Microsoft Intune"; SearchString = "Dell Command | Endpoint Configure for Microsoft Intune"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Monitor"; SearchString = "Dell Command | Monitor"}
                        [PSCustomObject]@{NameParameter = "Dell Trusted Device"; SearchString = "Dell Trusted Device"}
                        [PSCustomObject]@{NameParameter = "Dell Optimizer"; SearchString = "Dell Optimizer"}
                        [PSCustomObject]@{NameParameter = "Dell Device Management Agent"; SearchString = "Dell Device Management Agent"}
                        [PSCustomObject]@{NameParameter = "Microsoft Windows Desktop Runtime"; SearchString = "Microsoft Windows Desktop Runtime*(x64)*"}
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

##################################################
# Program Section                            #####
##################################################

Try
    {
        $SoftwareName = $DellSoftwareList | where-object {$_.NameParameter -eq $DellTool} | select-object -ExpandProperty Searchstring

        if(Test-SoftwareInstalled -NamePattern $SoftwareName -VersionPattern $Version -ISPattern $VersionIS)
            {
                Write-Host "Found it!"
            }
    }
Catch
    {
        Write-Output "Script failed: $($_.Exception.Message)"
        Exit 1
    }