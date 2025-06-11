<#
_author_ = Sven Riebe <sven_riebe@Dell.com>
_twitter_ = @SvenRiebe
_version_ = 1.0.1
_Dev_Status_ = Test
Copyright (C) 2025 Dell Inc. or its subsidiaries. All Rights Reserved.

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

<#Version Changes

    1.0.0     inital version
    1.0.1     Change Version and validate install type Headless or Full install of DDPM with different files
#>

<#
.Synopsis
   This PowerShell is for custom detection in Microsoft MEM for Dell Display Manager

.DESCRIPTION
   This PowerShell will check if Dell Display and Peripheral Manager 2.x is ready installed on a device. It will be used as custom detection in Microsoft MEM win32 install.
   
#>

######################################################################################################################
# Program with target Version
######################################################################################################################
$ProgramPathFullMode = $env:ProgramFiles + "\Dell\Dell Display and Peripheral Manager\ddpm.exe"
$ProgramPathHeadlessMode = $env:ProgramFiles + "\Dell\Dell Display and Peripheral Manager\Installer\setup.exe"
$ProgramVersion_target = '2.0.3.9' 

try
    {
        # check headless or full install DDPM
        $CheckInstallType = Test-Path $ProgramPathFullMode

        If($CheckInstallType)
            {
                # DDPM Full installed
                $ProgramVersion_current = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ProgramPathFullMode).FileVersion
            }
        else
            {
                # DDPM Headless installed or not installed
                $ProgramVersion_current = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ProgramPathHeadlessMode).FileVersion
            }
    }
catch
    {
        exit 1
    }

# Intune detection return

if($ProgramVersion_current -ge $ProgramVersion_target)
    {
        Write-Host "Found it!"
    }