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
###################################################################

function Get-MSIInformation 
{

 param (
    [IO.FileInfo] $MSI
)
 
if (!(Test-Path $MSI.FullName)) {
    throw "File '{0}' does not exist" -f $MSI.FullName
}
 
try {
    $windowsInstaller = New-Object -com WindowsInstaller.Installer
    $database = $windowsInstaller.GetType().InvokeMember(
        "OpenDatabase", "InvokeMethod", $Null,
        $windowsInstaller, @($MSI.FullName, 0)
    )
 
    $q = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
    $View = $database.GetType().InvokeMember(
        "OpenView", "InvokeMethod", $Null, $database, ($q)
    )
 
    $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)
    $record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null )
    $version = $record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $record, 1 )
 
    return $version
} catch {
    throw "Failed to get MSI file version: {0}." -f $_
 
    return $MSIInformation
}
}

##### Variables
$InstallerName = Get-ChildItem .\*.msi | Select-Object -ExpandProperty Name
$ProgramPath = (Get-Item .\$InstallerName).DirectoryName+ "\" + $InstallerName
[string]$ProgramVersion_target = Get-MSIInformation -MSI $ProgramPath
$ProgramVersion_target = $ProgramData_target | Where-Object{$_.Name -like 'Product*'}
$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Trusted%Device%'" | select -ExpandProperty Version
$ApplicationID_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Trusted%Device%'" | Select-Object -ExpandProperty IdentifyingNumber

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################

if ($ProgramVersion_target -gt $ProgramVersion_current)
    {
    #msiexec.exe /x $ApplicationID_current /qn

    Write-Output "Test 1"
    }

Else
    {
    Write-Host "Gleiche Version"
    Exit 0
    }


###################################################################
#Install new Software                                             #
###################################################################

msiexec.exe /x $InstallerName /qn



$MSI = "C:\Users\SvenRiebe\OneDrive - riebelab\Modern Deployment\Dell\Trusted Device\4.7.132\TrustedDevice-64bit.msi"

###############################################################
# Name:         GetMsiVersion.ps1
# Description:  Prints out MSI installer version
# Usage:        GetMsiVersion.ps1 <path to MSI>
# Credits:      http://stackoverflow.com/q/8743122/383673
###############################################################
param (
    [IO.FileInfo] $MSI
)
 
if (!(Test-Path $MSI.FullName)) {
    throw "File '{0}' does not exist" -f $MSI.FullName
}
 
try {
    $windowsInstaller = New-Object -com WindowsInstaller.Installer
    $database = $windowsInstaller.GetType().InvokeMember(
        "OpenDatabase", "InvokeMethod", $Null,
        $windowsInstaller, @($MSI.FullName, 0)
    )
 
    $q = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
    $View = $database.GetType().InvokeMember(
        "OpenView", "InvokeMethod", $Null, $database, ($q)
    )
 
    $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)
    $record = $View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null )
    $version = $record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $record, 1 )
 
    return $version
} catch {
    throw "Failed to get MSI file version: {0}." -f $_
}
