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

<#
Change log

    1.0.0   initil version
    1.1.0   add function get-installedcheck for testing if application is installed correctly
            add MS EventLog LogName "Dell" Source "Dell Software Install" and "Dell Software Uninstall"

<#
.Synopsis
   This PowerShell is for installation in Microsoft MEM for Dell Optimizer

.DESCRIPTION
   This PowerShell will install/Optimizer a Device for Dell Optimizer. It will be used as install file in Microsoft MEM win32 install.
   
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


function get-uninstallstring
   {
      param 
         (
            [Parameter(mandatory=$true)][ValidateSet($true,$false)][string]$PowerShell64,
            [Parameter(mandatory=$true)][ValidateSet("Optimizer","WebView2","Runtime6","DDM","DPM")][string]$App,
            [Parameter(mandatory=$true)][ValidateSet("UninstallString","InstallLocation","Quietuninstallstring")][string]$Value
         )
      
      $AppSearch = switch ($App) 
         {
            Optimizer   {"Dell*Optimizer*Core"}
            WebView2    {"Microsoft*WebView2*"}
            Runtime6    {"Microsoft Windows Desktop Runtime - 6*(x64)*"}
            DDM         {"Dell*Display*Manager*"}
            DPM         {"Dell*Power*Manager*"}

            
         }


      if ($PowerShell64 -eq $true)
         {
            
            If (($AppSearch -like "*Display*") -or ($AppSearch -like "Dell*Power*"))
               {
                  # get 64 Bit uninstall
                  Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "$AppSearch" } | Select-Object -ExpandProperty $Value
               }
            
            else
               {
                  # get 32 Bit uninstall
                  Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "$AppSearch" } | Select-Object -ExpandProperty $Value
               }

            

         }
      else 
         {
            # get 32 Bit uninstall
            Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "$AppSearch" } | Select-Object -ExpandProperty $Value
         }
   
   
   }

##############################################
#### variable section                     ####
##############################################
$InstallerName = Get-ChildItem .\*.exe | Select-Object -ExpandProperty Name
$ProgramPath = ".\" + $InstallerName
[Version]$ProgramVersion_target = (Get-Command $ProgramPath).FileVersionInfo.ProductVersion
$AppSearch = "%Dell %Optimizer%" #Parameter to search in registry
$Program_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'"
[Version]$ProgramVersion_current = $Program_current.Version
$PS64 = [Environment]::Is64BitProcess # Check 32 or 64 bit PowerShell
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

If ($Null -ne $ProgramVersion_current)
    {

    if ($ProgramVersion_target -gt $ProgramVersion_current)
        {
            ########################################
            # Uninstall older Versions             #
            ########################################
            #### Get Uninstallstring from registry
            $ApplicationUninstallString = get-uninstallstring -PowerShell64 $PS64 -App Optimizer -Value UninstallString
            $ApplicationUninstallString = $ApplicationUninstallString + " /Silent"
            
            Start-Process cmd.exe -ArgumentList'/c',"$ApplicationUninstallString"  -Wait -NoNewWindow
            Start-Sleep -Seconds 15

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

            $UninstallData = [PSCustomObject]@{
                                      Software = $SoftwareName
                                      Version = ($ProgramVersion_target).ToString()
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

Start-Process -FilePath "$ProgramPath" -ArgumentList "/s" -Wait

#############################
# install success check     #
#############################
$Program_current = Get-CimInstance -ClassName Win32_Product -Filter "Name like '$AppSearch'"
[Version]$ProgramVersion_current = $Program_current.Version
$SoftwareName = $Program_current.Name
$UninstallResult = Get-installedcheck -AppSearchString $AppSearch

If ($UninstallResult -ne $true)
    {

        Write-Host "install is unsuccessful" -BackgroundColor Red
            
        $UninstallData = [PSCustomObject]@{
                                            Software = $SoftwareName
                                            Version = ($ProgramVersion_target).ToString()
                                            Install = $false
                                            Reason = "Installation failed"
                                          } | ConvertTo-Json
                
        Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Error -EventId 11 -Message $UninstallData

    }
Else
    {

       If ($ProgramVersion_current -ge $ProgramVersion_target)
            {
            
                Write-Host "install is successful" -BackgroundColor Green
            
                $UninstallData = [PSCustomObject]@{
                                                    Software = $SoftwareName
                                                    Version = ($ProgramVersion_target).ToString()
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
                                                   Version = ($ProgramVersion_target).ToString()
                                                   Install = $false
                                                   Reason = "Older Version installed $ProgramVersion_current"
                                                 } | ConvertTo-Json
                
               Write-EventLog -LogName Dell -Source "Dell Software Install" -EntryType Information -EventId 10 -Message $UninstallData


            }

    }