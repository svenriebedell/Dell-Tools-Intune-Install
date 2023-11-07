<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.1
_Dev_Status_ = Test
Copyright ©2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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
    1.1.0   add function get-installedcheck to control if uninstall/install is successful
            add MS EventLog LogName "Dell" Source "Dell Software Install" and "Dell Software Uninstall"
    1.1.1   Dell Support Assist Team renamed MST File to cover this flexible in future now MST will handle by Variable

#>

<#
.Synopsis
   This PowerShell is for installation on Microsoft MEM for Dell SupportAssist Business

.DESCRIPTION
   This PowerShell will install/Update a Device for Dell SupportAssist Business. It will be used as install file in Microsoft MEM win32 install.
   
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
#### variable section                     ####
##############################################
$InstallerName = Get-ChildItem .\*.msi | Select-Object -ExpandProperty Name
$MSTName = Get-ChildItem .\*.mst | Select-Object -ExpandProperty Name
$ProgramPath = $InstallerName
$MSTPath = $MSTName
$ProgramVersion_target = Get-MsiFileVersion -msiName $InstallerName
$AppSearch = "%Dell%Support%Business%" #Parameter to search in registry
$Program_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'"
[Version]$ProgramVersion_current = $Program_current.Version
$ApplicationID_current = $Program_current.IdentifyingNumber
$Argumentstring = "/i " + '"' + $ProgramPath + '" TRANSFORMS="' + $MSTPath + '" DEPLOYMENTKEY="Dell2023#" /norestart /qn /l+ "c:\SupportAssistMsi.log"'  #Your Deployment Key you generated before with the installer

$SoftwareName = $Program_current.Name


##############################################
#### Program section                     ####
##############################################

#### generate Logging Resources
New-EventLog -LogName "Dell" -Source "Dell Software Install" -ErrorAction Ignore
New-EventLog -LogName "Dell" -Source "Dell Software Uninstall" -ErrorAction Ignore

###################################################################
#Checking if older Version is installed and uninstall this Version#
###################################################################


If ($null -ne $ProgramVersion_current)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
            #############################
            # uninstall Software old    #
            #############################
            Start-Process -FilePath msiexec.exe -ArgumentList "/x $ApplicationID_current /qn" -Wait

            #############################
            # uninstall success check   #
            #############################
            $UninstallResult = Get-installedcheck -AppSearchString $AppSearch

            If ($UninstallResult -eq $true)
                {

                    Write-Host "uninstall is unsuccessful" -BackgroundColor Red
                    
                    $UninstallData = [PSCustomObject]@{
                                          Software = $SoftwareName
                                          Version = ($ProgramVersion_current).ToString()
                                          Uninstall = $false
                                     } | ConvertTo-Json
                
                    Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Error -EventId 11 -Message $UninstallData


                }
            Else
                {

                    Write-Host "uninstall is successful" -BackgroundColor Green

                    $UninstallData = [PSCustomObject]@{
                                          Software = $SoftwareName
                                          Version = ($ProgramVersion_current).ToString()
                                          Uninstall = $true
                                     } | ConvertTo-Json
                
                    Write-EventLog -LogName Dell -Source "Dell Software Uninstall" -EntryType Information -EventId 10 -Message $UninstallData

                }
        

        }

    Else
        {
            Write-Host "same version is installed"
            [String]$VersionString = $ProgramVersion_target

            $UninstallData = [PSCustomObject]@{
                                      Software = $SoftwareName
                                      Version = $VersionString
                                      Install = $false
                                      Reason = "same version is installed"
                             } | ConvertTo-Json
                
            Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData




            Exit 0
        }

    }

###################################################################
#Install new Software                                             #
###################################################################

Start-Process -FilePath msiexec.exe -ArgumentList $Argumentstring -Wait

#############################
# install success check     #
#############################
$Program_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'"
[Version]$ProgramVersion_current = $Program_current.Version
$SoftwareName = "Dell Support Assist for Business PCs"
$UninstallResult = Get-installedcheck -AppSearchString $AppSearch
[String]$VersionString = $ProgramVersion_target

If ($UninstallResult -ne $true)
    {

        Write-Host "install is unsuccessful" -BackgroundColor Red
            
        $UninstallData = [PSCustomObject]@{
                                            Software = $SoftwareName
                                            Version = $VersionString
                                            Install = $false
                                            Reason = "Installation failed"
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Error -EventId 11 -Message $UninstallData

    }
Else
    {
       If ($ProgramVersion_current -ge $VersionString)
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
                                                   Version = $VersionString
                                                   Install = $false
                                                   Reason = "Older Version installed $ProgramVersion_current"
                                                 } | ConvertTo-Json
                
               Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData


            }

    }