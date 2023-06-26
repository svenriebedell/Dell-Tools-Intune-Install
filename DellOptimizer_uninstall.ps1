<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.1.0
_Dev_Status_ = Test
Copyright © 2023 Dell Inc. or its subsidiaries. All Rights Reserved.

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
   This PowerShell is for uninstall in Microsoft MEM for Dell Optimizer

.DESCRIPTION
   This PowerShell will uninstall a Device for Dell Optimizer. It will be used as install file in Microsoft MEM win32 install.
   
#>

<#
   Changelog
      1.0.0 initial Version
      1.1.0 Solves the problem of renaming the Optimizer service and added uninstalling Microsoft Windows Desktop Runtime 6.x, Dell Power Manager Service, Dell Display Manager 2.x and Microsoft Edge WebView2 Runtime as a selectable option


#>

##### Variables

$WebViewUninstall = $true  # $true/$false to enable/disable uninstall of Microsoft Edge WebView2, be careful and check if other applications need this app before you uninstall this software
$RuntimeUninstall = $true  # $true/$false to enable/disable uninstall of Microsoft Windows Desktop Runtime 6.x, be careful and check if other applications need this app before you uninstall this software
$DDMUninstall = $true  # $true/$false to enable/disable uninstall of Dell Display Manager 2.x
$DPMUninstall = $true  # $true/$false to enable/disable uninstall of Dell Power Manager Service
$PS64 = [Environment]::Is64BitProcess # Check 32 or 64 bit PowerShell


###################################################################
# function section                                                #
###################################################################

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
            Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -like "$Appfull" } | Select-Object -ExpandProperty $Value
         }
   
   
   }

###################################################################
# Program section                                                 #
###################################################################

#### Get Uninstallstring from registry
$ApplicationUninstallString = get-uninstallstring -PowerShell64 $PS64 -App Optimizer -Value UninstallString
$ApplicationUninstallString = $ApplicationUninstallString + " /Silent"
#### Uninstall Dell Optimizer
Start-Process cmd.exe -ArgumentList'/c',"$ApplicationUninstallString"  -Wait -NoNewWindow
Start-Sleep -Seconds 30


##################################
# Uninstall additional Software  #
##################################

#### uninstall Microsoft Edge WebView2 and/or Microsoft Windows Desktop Runtime 6.x if enabled
If($WebViewUninstall -eq $true)
   {
      $WebViewUninstallString = get-uninstallstring -PowerShell64 $PS64 -App WebView2 -Value UninstallString
      
      If($null -ne $WebViewUninstallString)
         {
            Write-Host "WebView2 Runtime found"
            $WebViewUninstallString = $WebViewUninstallString +" --force-uninstall"
            Start-Process cmd.exe -ArgumentList'/c',"$WebViewUninstallString"  -Wait -NoNewWindow

         }
      
   }

If($RuntimeUninstall -eq $true)
   {
      $Runtime6UninstallString = get-uninstallstring -PowerShell64 $PS64 -App Runtime6 -Value Quietuninstallstring

      If($null -ne $Runtime6UninstallString)
         {
            Write-Host "Desktop Runtime 6 found"
            Start-Process cmd.exe -ArgumentList'/c',"$Runtime6UninstallString" -Wait -NoNewWindow
         }
      
   }

If($DDMUninstall -eq $true)
   {
      
      $DDMUninstallString = get-uninstallstring -PowerShell64 $PS64 -App DDM -Value UninstallString
      
      If($null -ne $DDMUninstallString)
         {
            Write-Host "Display Manager 2"
            Start-Process -FilePath $DDMUninstallString -ArgumentList "/S" -Wait -NoNewWindow
         }
      else
         {
            
            # Cover problem of PS32 can not access 64 Bit Registry
            $CheckPath = Test-Path "C:\Program Files\Dell\Dell Display Manager 2\uninst.exe"
            
            If ($CheckPath -eq $true)
               {
                  Write-Host "Display Manager 2"
                  $DDMUninstallString = "C:\Program Files\Dell\Dell Display Manager 2\uninst.exe /S"
                  Start-Process -FilePath "C:\Program Files\Dell\Dell Display Manager 2\uninst.exe" -ArgumentList "/S" -Wait -NoNewWindow

               }

         }
      
   }

If($DPMUninstall -eq $true)
   {
      
      $DPMUninstallString = Get-CimInstance -ClassName Win32_Product -Filter "Name like '%Dell%Power%Manager%'" | Select-Object -ExpandProperty IdentifyingNumber
      
      If($null -ne $DPMUninstallString)
         {
            Write-Host "Dell Power Manager Service"
            Start-Process -FilePath msiexec.exe -ArgumentList "/x $DPMUninstallString /qn" -Wait
         }
      
   }