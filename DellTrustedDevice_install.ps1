<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.0
_Dev_Status_ = Test
Copyright (c)2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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

<#Change Log
    1.0.0     initial version
    1.1.0     add function get-msifileversion no more needed to edit var $ProgramVersion_target any more
              add MS EventLog LogName "Dell" Source "Dell Software Install" and "Dell Software Uninstall"

#>

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Trusted Device

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell Trusted Device. It will be used as install file in Microsoft MEM win32 install.
   
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

#### function based on https://stackoverflow.com/questions/8743122/how-do-i-find-the-msi-product-version-number-using-powershell

function Get-MsiFileVersion {
    param 
        (
            [Parameter(mandatory=$true)][string] $msiName
        )

    try {
        $FullPath = (Resolve-Path $msiName).Path
        $windowsInstaller = New-Object -com WindowsInstaller.Installer

        $database = $windowsInstaller.GetType().InvokeMember(
                "OpenDatabase", "InvokeMethod", $Null, 
                $windowsInstaller, @($FullPath, 0)
            )

        $q = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
        $View = $database.GetType().InvokeMember(
                "OpenView", "InvokeMethod", $Null, $database, ($q)
            )

        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)

        $record = $View.GetType().InvokeMember(
                "Fetch", "InvokeMethod", $Null, $View, $Null
            )

        [Version]$productVersion = $record.GetType().InvokeMember(
                "StringData", "GetProperty", $Null, $record, 1
            )

        $View.GetType().InvokeMember("Close", "InvokeMethod", $Null, $View, $Null)

        return $productVersion

    } catch {
        throw "Failed to get MSI file version the error was: {0}." -f $_
    }
}

##############################################
#### Varibles section                     ####
##############################################
$InstallerName = Get-ChildItem .\*.msi | Select-Object -ExpandProperty Name
$ProgramPath = (Get-Item .\$InstallerName).DirectoryName+ "\" + $InstallerName
$ProgramVersion_target = Get-MsiFileVersion -msiName $InstallerName
$AppSearch = "%Dell%Trusted%Device%" #Parameter to search in registry
$Program_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'"
[Version]$ProgramVersion_current = $Program_current.Version
$ArgumentString = '/i "'+$ProgramPath + '" /qn REBOOT=R'
$SoftwareName = $Program_current.Name


##############################################
#### Program section                     ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

##############################################
#### Program section                      ####
##############################################

#Checking if older Version is installed and uninstall this Version
If ($null -ne $ProgramVersion)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
        
            #Update Software by msi upgrade      
            Start-Process -FilePath msiexec.exe -ArgumentList "$ArgumentString" -Wait

            #############################
            # install success check     #
            #############################
            $UninstallResult = Get-installedcheck -AppSearchString $AppSearch
            [String]$VersionString = $ProgramVersion_target
            $Program_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'"
            $SoftwareName = $Program_current.Name

            If ($UninstallResult -ne $true)
                                                            {

                Write-Host "install is unsuccessful" -BackgroundColor Red
            
                $UninstallData = [PSCustomObject]@{
                                                    Software = $SoftwareName
                                                    Version = $VersionString
                                                    Install = $false
                                                    Reason = "Update failed"
                                                  } | ConvertTo-Json
                
                Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Error -EventId 11 -Message $UninstallData

            }
            Else
                                                                                                                                                {

               [Version]$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'" | Select-Object -ExpandProperty Version

               If ($ProgramVersion_current -ge $ProgramVersion_target)
                    {
            
                        Write-Host "install is successful" -BackgroundColor Green
            
                        $UninstallData = [PSCustomObject]@{
                                                            Software = $SoftwareName
                                                            Version = $VersionString
                                                            Install = $true
                                                            Reason = "Update"
                                                          } | ConvertTo-Json
                
                       Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData
                
                    }
               Else
                    {
                            
            
                       Write-Host "install is unsuccessful" -BackgroundColor red

            
                       $UninstallData = [PSCustomObject]@{
                                                           Software = $SoftwareName
                                                           Version = $VersionString
                                                           Install = $false
                                                           Reason = "Older Version installed $ProgramVersion_current"
                                                         } | ConvertTo-Json
                
                       Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData


                    }

            }
        }
    
    Else
        {
            Write-Host "same version is installed"

            $UninstallData = [PSCustomObject]@{
                                      Software = $SoftwareName
                                      Version = $ProgramVersion_current
                                      Install = $false
                                      Reason = "same version is installed"
                             } | ConvertTo-Json
                
            Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData




            Exit 0
        }

    }

Else
    {
    
        #Install new Software
        Start-Process -FilePath msiexec.exe -ArgumentList "$ArgumentString" -Wait

        #############################
        # install success check     #
        #############################
        $UninstallResult = Get-installedcheck -AppSearchString $AppSearch
        $Program_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'"
        [String]$VersionString = $ProgramVersion_target
        $SoftwareName = $Program_current.Name

        If ($UninstallResult -ne $true)
            {

                Write-Host "install is unsuccessful" -BackgroundColor Red
            
                $UninstallData = [PSCustomObject]@{
                                                    Software = "Trusted Device"
                                                    Version = $VersionString
                                                    Install = $false
                                                    Reason = "Installation failed"
                                                  } | ConvertTo-Json
                
                Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Error -EventId 11 -Message $UninstallData

            }
        Else
            {

               [Version]$ProgramVersion_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'" | Select-Object -ExpandProperty Version

               If ($ProgramVersion_current -ge $ProgramVersion_target)
                    {
            
                        Write-Host "install is successful" -BackgroundColor Green
            
                        $UninstallData = [PSCustomObject]@{
                                                            Software = $SoftwareName
                                                            Version = $VersionString
                                                            Install = $true
                                                            Reason = "Update/Install/Newer Version"
                                                          } | ConvertTo-Json
                
                       Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData
                
                    }
               Else
                    {
                            
            
                       Write-Host "install is unsuccessful" -BackgroundColor red

            
                       $UninstallData = [PSCustomObject]@{
                                                           Software = $SoftwareName
                                                           Version = $ProgramVersion_current
                                                           Install = $false
                                                           Reason = "Older Version installed $ProgramVersion_current"
                                                         } | ConvertTo-Json
                
                       Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData


                    }

            }
    
    }