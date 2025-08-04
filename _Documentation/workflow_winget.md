# Workflow for Winget

[Back to index](../README.MD)

## Introduction
This workflow will install a list with apps from a text file. Each line in the text file needs to be a valid winget app id. For more information you can check [this article](https://chosengambit.com/2024/11/ict/automate-winget-with-powershell-to-install-multiple-applications/).

## How to

- Extract **PowerShell-Structure-Main** to your computer.
- In the same directory as PowerShell-Structure-Main is located, add a **run.ps1** file and an **apps.txt** file.
- Inside **run.ps1** add: `.$PSScriptRoot\PowerShell-Structure-main\workflows\winget\main.ps1`
- Inside **apps.txt**, add a valid App Id on each line, such as: **BlenderFoundation.Blender**
- Open a PowerShell Terminal with Admin rights.
- Run command: `Set-ExecutionPolicy Bypass -Scope CurrentUser`
- Run Command: `.\run.ps1`

## What this does
This installs Winget and installs Blender.