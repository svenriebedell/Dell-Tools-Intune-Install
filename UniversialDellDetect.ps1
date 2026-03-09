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

#>
param(
            [Parameter(mandatory=$true)][ValidateSet("Dell SupportAssist","Dell Display and Peripheral Manager","Dell Client Device Manager","Dell | Command Update","Dell | Command Configure","Dell Command | Endpoint Configure for Microsoft Intune","Dell Command | Monitor","Dell Trusted-Device","Dell Optimizer","Dell Device Management Agent",".Net RunTime8",".Net RunTime9")][String]$DellTool,
            [Parameter(mandatory=$true)][ValidateSet("Equal","Not equal","Less than","Less than or equal","Greater than","Greater than or equal")][String]$VersionIS,
            [Parameter(mandatory=$true)][Version]$Version
    )

##################################################
# Varible Section                            #####
##################################################
$DellSoftwareList = @(
                        [PSCustomObject]@{NameParameter = "Dell SupportAssist"; SearchString = "Dell SupportAssist"}
                        [PSCustomObject]@{NameParameter = "Dell Display and Peripheral Manager"; SearchString = "Dell Display and Peripheral Manager"}
                        [PSCustomObject]@{NameParameter = "Dell Client Device Manager"; SearchString = "Dell Client Device Manager"}
                        [PSCustomObject]@{NameParameter = "Dell | Command Configure"; SearchString = "Dell | Command Configure"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Endpoint Configure for Microsoft Intune"; SearchString = "Dell Command | Endpoint Configure for Microsoft Intune"}
                        [PSCustomObject]@{NameParameter = "Dell Command | Monitor"; SearchString = "Dell Command | Monitor"}
                        [PSCustomObject]@{NameParameter = "Dell Trusted-Device"; SearchString = "Dell Trusted-Device"}
                        [PSCustomObject]@{NameParameter = "Dell Optimizer"; SearchString = "Dell Optimizer"}
                        [PSCustomObject]@{NameParameter = "Dell Device Management Agent"; SearchString = "Dell Device Management Agent"}
                        [PSCustomObject]@{NameParameter = ".Net RunTime8"; SearchString = ".Net RunTime8"}
                        [PSCustomObject]@{NameParameter = ".Net RunTime9"; SearchString = ".Net RunTime9"}
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
                $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.DisplayVersion -eq $VersionPattern ) }
            }
        ## Not equal
        elseIf ($ISPattern -eq "Not equal")
            {
                $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.DisplayVersion -ne $VersionPattern ) }
            }
        ## Less than
        elseIf ($ISPattern -eq "Less than")
            {
                $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.DisplayVersion -lt $VersionPattern ) }
            }
        ## Less than or equal
        elseIf ($ISPattern -eq "Less than or equal")
            {
                $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.DisplayVersion -le $VersionPattern ) }
            }
        ## Greater than
        elseIf ($ISPattern -eq "Greater than")
            {
                $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.DisplayVersion -gt $VersionPattern ) }
            }
        ## Greater than or equal
        elseIf ($ISPattern -eq "Greater than or equal")
            {
                $match = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -like "$NamePattern" -and $_.DisplayVersion -ge $VersionPattern ) }
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

    }