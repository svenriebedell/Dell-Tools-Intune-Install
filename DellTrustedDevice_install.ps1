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

 param(
        [System.IO.FileInfo]$MsiFile
	)
 

    $com_object = New-Object -com WindowsInstaller.Installer 
            
    $database = $com_object.GetType().InvokeMember("OpenDatabase","InvokeMethod",$Null,$com_object,@($MsiFile.FullName, 0)) 
 
    $query = "SELECT * FROM Property" 
    $View = $database.GetType().InvokeMember("OpenView","InvokeMethod",$Null,$database,($query)) 
 
    $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null) 
 
    $record = $View.GetType().InvokeMember("Fetch","InvokeMethod",$Null,$View,$Null) 

 
 
    $msi_props = @{} 
    while ($record -ne $null) { 
        $prop_name = $record.GetType().InvokeMember("StringData", "GetProperty", $Null, $record, 1) 
        $prop_value = $record.GetType().InvokeMember("StringData", "GetProperty", $Null, $record, 2) 
        $msi_props[$prop_name] = $prop_value 
        $record = $View.GetType().InvokeMember("Fetch","InvokeMethod",$Null,$View,$Null)
    }

        $MSIInformation = @{
                        "ProductName"=$msi_props.Item("ProductName");
                        "Manufacturer"=$msi_props.Item("Manufacturer");
                        "ProductVersion"=$msi_props.Item("ProductVersion");
                        "ProductCode"=$msi_props.Item("ProductCode");
                        "ProductLanguage"=$msi_props.Item("ProductLanguage")
                        "FileName"=$MSIFile.Name
                        }





    $view.Close()
    
    $database.Commit()
    $database = $null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($com_object) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
    
    rv com_object,database,view,record,MsiFile
    [system.gc]::Collect()
    [System.gc]::waitforpendingfinalizers()

    
    return $MSIInformation
}

##### Variables
$InstallerName = Get-ChildItem .\*.msi | Select-Object -ExpandProperty Name
$ProgramPath = (Get-Item .\$InstallerName).DirectoryName+ "\" + $InstallerName
$ProgramVersion_target = Get-MSIInformation -MsiFile $ProgramPath
[Version]$ProgramVersion_target = $ProgramData_target | Where-Object{$_.Name -like 'Product*'}
[Version]$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Trusted%Device%'" | select -ExpandProperty Version
$ApplicationID_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Trusted%Device%'" | Select-Object -ExpandProperty IdentifyingNumber

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

