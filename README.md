# Deployment Scripts for Dell Tools
### For use with Microsoft Intune and other deployment tools

> **🆕 Update:** I have introduced **universal scripts** for the installation,
> uninstallation, and detection of Dell Tools.
> *Legacy scripts remain available in the repository.*



## ✨ New Features

- **Universal Multi-App Scripts**
  A single, streamlined script structure designed to cover multiple Dell applications.

- **Expanded Dell SupportAssist Options**
  Now it supports various installation methods:
  - Installer EXE
  - Installer MSI
  - Registration via ADMX or MST
  
  *(Previously limited to MSI and MST only.)*



## 📦 Supported Applications

| Application | Install | Uninstall | Detection |
|:--|:--:|:--:|:--:|
| Dell Core Services | ✅ | ✅ | ✅ |
| Dell SupportAssist | ✅ | ✅ | ✅ |
| Dell SupportAssist Remediation | — | ✅ | ✅ |
| Dell SupportAssist OS Recovery Plugin for Dell Update | ✅ | ✅ | ✅ |
| Dell Device Management Agent | ✅ | ✅ | ✅ |
| Dell Pair | ✅ | ✅ | ✅ |
| Dell Peripheral Core | — | ✅ | ✅ |
| Dell Digital Delivery | ✅ | ✅ | ✅ |
| Dell Command Update (Universal App and Classic) | ✅ | ✅ | ✅ |
| Dell Command Configure | ✅ | ✅ | ✅ |
| Dell Command Endpoint Configure for Microsoft Intune | ✅ | ✅ | ✅ |
| Dell Command Monitor | ✅ | ✅ | ✅ |
| Dell Trusted Device | ✅ | ✅ | ✅ |
| Dell Optimizer | ✅ | ✅ | ✅ |
| Microsoft Windows Desktop Runtime | ✅ | ✅ | ✅ |
| ASP.NET Core Runtime | ✅ | ✅ | ✅ |


## 📦 Not Supported Applications by universal scripts (you need to use the single scripts if needed)
- Dell Power Manager
- Dell Peripheral Manager
- Dell Display Manager 1 and 2
- Dell SupportAssist OS Recovery Plugin for Dell Update


# Dell Tools Intune Install – Universal Scripts

A set of **universal PowerShell scripts** that simplify deploying, detecting, and removing Dell Client Management Tools through **Microsoft Intune** (or any other Win32-app deployment solution).



## ⚙️ Prerequisites

- Windows 10 / 11
- PowerShell 5.1 or later
- Administrator privileges
- Microsoft Intune (recommended) or any Win32-app deployment tool

## ⚙️ Files
.\UniversalDellInstall.ps1
.\UniversalDellUninstall.ps1
.\UniversalDellDetection.ps1


## 📜 Scripts Reference

### 1 · Detection Script – `UniversalDellDetection.ps1`

Use this as a **custom detection rule** in Intune to verify whether a specific Dell tool is installed at the correct version.

*Detection Script – Detection_Dell_Tools.ps1*

#### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-DellTool` | Yes | Name of the Dell application to look for (e.g., `'Dell Trusted Device'`). |
| `-VersionIS` | Yes | Comparison operator for the version check. |
| `-Version` | Yes | Target version string (e.g., `5.6.0` or `2.2.0.19`). |

#### Supported `-VersionIS` Operators

| Operator | Meaning |
|----------|---------|
| `Equal` | Installed version **=** target |
| `Not equal` | Installed version **≠** target |
| `Less than` | Installed version **<** target |
| `Less than or equal` | Installed version **≤** target |
| `Greater than` | Installed version **>** target |
| `Greater than or equal` | Installed version **≥** target |

#### Example

```powershell
# Check that Dell Command | Update version 5.6.0 is installed
.\UniversalDellDetection.ps1 -DellTool 'Dell Command | Update' -VersionIS Equal -Version 5.6.0
```

---

### 2 · Install Script – `UniversalDellInstall.ps1`

Executes the installation of the specified Dell application, with an optional clean-uninstall-first workflow.

#### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-DellTool` | Yes | Name of the Dell application to install. |
| `-UninstallOldVersion` | Yes | `$True` – remove the previous version before installing. `$False` – perform an in-place upgrade. |

> **⚠️ Caution:** Some tools perform deregistration or require a reboot during uninstall. Use `$True` only when a clean slate is necessary.

#### Examples

```powershell
# In-place upgrade (recommended for most scenarios)
.\UniversalDellInstall.ps1 -DellTool 'Dell Command | Update' -UninstallOldVersion $False

# Clean install – removes existing version first
.\UniversalDellInstall.ps1 -DellTool 'Dell Command | Update' -UninstallOldVersion $True
```

---

### 3 · Uninstall Script – `UniversalDellUninstall.ps1`

Cleanly removes the targeted software. Supports removing a single tool, **all** recognized Dell tools at once, or even shared prerequisites.

#### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-DellTool` | Yes | Name of the Dell application, or `'AllDell'` to remove every recognized Dell tool. |

#### Examples

```powershell
# Remove a specific tool
.\UniversalDellUninstall.ps1 -DellTool 'Dell Command | Update'

# Remove ALL recognized Dell tools
.\UniversalDellUninstall.ps1 -DellTool 'AllDell'

# Remove a shared prerequisite
.\UniversalDellUninstall.ps1 -DellTool 'Microsoft Windows Desktop Runtime 8'
```

---

## 🔄 Parameter Fallback Logic

The scripts accept parameters at runtime. However, if your deployment platform **does not support passing script parameters**, each script contains an internal fallback section where you can hard-code the target Dell tool and options. This ensures compatibility across all deployment methods.
<img width="925" height="117" alt="image" src="https://github.com/user-attachments/assets/a6e70cbc-d078-403f-b049-4563884d1967" />


# Deployment by Microsoft Intune

> **Tip:** For detailed Intune packaging and deployment walkthroughs, see the [Microsoft Intune Win32 app documentation](https://learn.microsoft.com/mem/intune/apps/apps-win32-app-management).

**Prerequisites**
If you want to install the Dell Device Management Agent or Dell SupportAssist by MST to need to modify the universalinstall.ps1 to add your registration information's.
<img width="2000" height="82" alt="image-1" src="https://github.com/user-attachments/assets/c3e3cf33-0420-4d9b-9371-a3250d0b2f33" />

otherwise the installation will fail or not register the device to Dell Device Management Console or Dell Techdirect.

**Step 1: Download the required tool or using my https://github.com/svenriebedell/DellApp-Download-Manager to having a local repository of all tools**

**Step 2: Create a new a new IntuneWin package**
<img width="1864" height="188" alt="image-3" src="https://github.com/user-attachments/assets/31df03ed-beb9-40c2-afe7-80cc42cd5547" />

**Step 3: Upload the IntuneWin package to Microsoft Intune**
<img width="1136" height="321" alt="image-4" src="https://github.com/user-attachments/assets/7d82feb0-a094-4e39-8805-0e637d79a878" />


**Step 4: Prepare scripts and upload to Intune**
<img width="2016" height="219" alt="image-5" src="https://github.com/user-attachments/assets/57247cb7-0569-419b-8c61-a64b27c6d565" />

You need to work with the fallback section in these scripts to set the parameters, because intune not support call the script with parameters.

**Step 5: Upload these scripts to Intune**
<img width="1277" height="618" alt="image-6" src="https://github.com/user-attachments/assets/842e3310-7e46-4f30-8e8e-b219c7f5d7ab" />

<img width="1291" height="995" alt="image-7" src="https://github.com/user-attachments/assets/159fb8f0-8c27-45b0-8c5b-8ede19c2ed31" />

**Step 6: Assign the application to the required devices**
<img width="1541" height="865" alt="image-8" src="https://github.com/user-attachments/assets/c4ef9700-9074-4a1d-93f6-40f84ff03cb2" />



# Classic Single App Deployment scripts

**Old**

Latest Version of document: **1.2.5**

## Changelog:
- 1.0.0   initial version
- 1.1.1   Updating some Text in Deployment Instruction like. DDM2.0 download
- 1.2.0   + renaming to Microsoft Intune  + Add separat information's and script to support Dell Display Manager 2.x + Add dependency app information's to Dell Optimizer to cover required .net 6 runtime since optimizer 4.0.201.0
- 1.2.1   Correct Display Manager 2 Install/Uninstall to run with PowerShell 32 Bit
- 1.2.2	  Update Install instruction Dell Support Assist, add .net 6.x dependency
- 1.2.3   Add Dell Peripheral Manager to this document
- 1.2.4 - Update Dell Trusted Device section from MSI to DUP deployment/Add MS Event logging for install and uninstall scripts
- 1.2.5 - Update on section Dell Support Assist for Business PC on prepare MSI and MST and update for the Install Script


## Description
This repository provide Deployment Guide and scripts you can use to install Dell Client Management Tools in Microsoft Intune.
You will find for all Applications scripts for install, uninstall and detection. The most of install scripts include a automatically uninstall of older version. For Dell Optimizer we use an inplace update and no uninstall in reason of using existing User configuration of Dell Optimizer in newer version as well. For Trusted Device we use inplace update to reduce the count of reboots.

This and more you will find in Deployment Guide **Install_Instruction_Dell_Tools_with_ MEM_V1_2_5.pdf** stored in this repository

This Guide covers deployment of the following **Dell Tools**
Dell Command Monitor
Dell Command Configure
Dell Command Update Universal Application
Dell Optimizer
Dell Power Manager
Dell Trusted Device
Dell Display Manager
Dell SupportAssist for Business PC
Dell Peripheral Manager (New)

**Legal disclaimer:** THE INFORMATION IN THIS PUBLICATION IS PROVIDED 'AS-IS.' DELL MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO THE INFORMATION IN THIS PUBLICATION, AND SPECIFICALLY DISCLAIMS IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. In no event shall Dell Technologies, its affiliates or suppliers, be liable for any damages whatsoever arising from or related to the information contained herein or actions that you decide to take based thereon, including any direct, indirect, incidental, consequential, loss of business profits or special damages, even if Dell Technologies, its affiliates or suppliers have been advised of the possibility of such damages.