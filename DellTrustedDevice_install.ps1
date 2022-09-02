<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0
_Dev_Status_ = Test
Copyright Â© 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

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
   This PowerShell is for installation in Microsoft MEM for Dell Trusted Device

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell Trusted Device. It will be used as install file in Microsoft MEM win32 install.
   
#>

###################################################################
# Function for checking MSI File Version                          #
# used from:                                                      #
# https://gist.github.com/jstangroome/913062                      #
###################################################################

function Get-MsiProductVersion {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ | Test-Path -PathType Leaf})]
        [string]
        $Path
    )
    
    function Get-Property ($Object, $PropertyName, [object[]]$ArgumentList) {
        return $Object.GetType().InvokeMember($PropertyName, 'Public, Instance, GetProperty', $null, $Object, $ArgumentList)
    }

    function Invoke-Method ($Object, $MethodName, $ArgumentList) {
        return $Object.GetType().InvokeMember($MethodName, 'Public, Instance, InvokeMethod', $null, $Object, $ArgumentList)
    }

    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest

    #http://msdn.microsoft.com/en-us/library/aa369432(v=vs.85).aspx
    $msiOpenDatabaseModeReadOnly = 0
    $Installer = New-Object -ComObject WindowsInstaller.Installer

    $Database = Invoke-Method $Installer OpenDatabase  @($Path, $msiOpenDatabaseModeReadOnly)

    $View = Invoke-Method $Database OpenView  @("SELECT Value FROM Property WHERE Property='ProductVersion'")

    Invoke-Method $View Execute

    $Record = Invoke-Method $View Fetch
    if ($Record) {
        Write-Output (Get-Property $Record StringData 1)
    }

    Invoke-Method $View Close @()
    Remove-Variable -Name Record, View, Database, Installer

}

##### Variables
$InstallerName = Get-ChildItem .\*.msi | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
#[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.FileVersion
[Version]$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Trusted Device%'" | select -ExpandProperty Version
$ApplicationID_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Trusted Device%'" | Select-Object -ExpandProperty IdentifyingNumber

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

if ($ProgramVersion_target -gt $ProgramVersion_current)
    {
    msiexec.exe /x $ApplicationID_current /qn
    }

Else
    {
    Write-Host "Gleiche Version"
    Exit Code 0
    }


###################################################################
#Install new Software                                             #
###################################################################

msiexec.exe /x $InstallerName /qn

