# Deployment Guide for Dell Client Management Tools for Microsoft Intune

Latest Version of document: **1.2.5**

## Changelog:
- 1.0.0   initial version
- 1.1.1   Updating some Text in Deployment Instruction like. DDM2.0 download
- 1.2.0   + renaming to Microsoft Intune  + Add separat informations and script to support Dell Display Manager 2.x + Add dependency app informations to Dell Optimizer to cover required .net 6 runtime since optimizer 4.0.201.0
- 1.2.1   Correct Display Manager 2 Install/Uninstall to run with PowerShell 32 Bit
- 1.2.2	  Update Install instruction Dell Support Assist, add .net 6.x dependency
- 1.2.3   Add Dell Peripheral Manager to this document
- 1.2.4 - Update Dell Trusted Device section from MSI to DUP deployment/Add MS Event logging for install and uninstall scripts
- 1.2.5 - Update on section Dell Support Assist for Business PC on prepare MSI and MST and update for the Install Script


## Description
This repository provide Deployment Guide and scripts you can use to install Dell Client Management Tools in Microsoft Intune.
You will find for all Applications scripts for install, uninstall and detection. The most of install scripts include a automatically uninstall of older version. For Dell Optimizer we use an inplace update and no uninstall in reason of using existing User configuration of Dell Optimizer in newer version as well. For Trusted Device we use inplace update to reduce the count of reboots.

This and more you will find in Deployment Guide **Install_Instruction_Dell_Tools_with_ MEM_V1_2_3.pdf** stored in this repository

This Guide covers deployment of the following **Dell Tools**
Dell Command | Monitor
Dell Command | Configure
Dell Command | Update Universal Application
Dell Optimizer
Dell Power Manager
Dell Trusted Device
Dell Display Manager
Dell SupportAssist for Business PC
Dell Peripheral Manager (New)

**Legal disclaimer:** THE INFORMATION IN THIS PUBLICATION IS PROVIDED 'AS-IS.' DELL MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY KIND WITH RESPECT TO THE INFORMATION IN THIS PUBLICATION, AND SPECIFICALLY DISCLAIMS IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. In no event shall Dell Technologies, its affiliates or suppliers, be liable for any damages whatsoever arising from or related to the information contained herein or actions that you decide to take based thereon, including any direct, indirect, incidental, consequential, loss of business profits or special damages, even if Dell Technologies, its affiliates or suppliers have been advised of the possibility of such damages.
