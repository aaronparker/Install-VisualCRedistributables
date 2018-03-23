# VcRedist

[![Build status](https://ci.appveyor.com/api/projects/status/ijnl2agu5ey3l1u7?svg=true)](https://ci.appveyor.com/project/aaronparker/install-visualcredistributables)

A PowerShell module for downloading and installing the [Microsoft Visual C++ Redistributables](https://support.microsoft.com/en-au/help/2977003/the-latest-supported-visual-c-downloads). The module also supports creating applications in the Microsoft Deployment Toolkit or System Center Configuration Manager to install the Redistributables.

## Visual C++ Redistributables

The Microsoft Visual C++ Redistributables are a core component of any Windows desktop deployment. Because multiple versions are often deployed they need to be imported into your deployment solution or installed locally, which can be time consuming. The aim of this module is to reduce the time required to import the Redistributables or install them locally.

## Documentation

Full documentation for the module is located on GitBook at [https://aaronparker.gitbooks.io/vcredist/content/](https://aaronparker.gitbooks.io/vcredist/content/)

## PowerShell Gallery

The VcRedist module is published to the PowerShell Gallery and can be found here: [VcRedist](https://www.powershellgallery.com/packages/VcRedist/). Install the module from the gallery with:

```powershell
Install-Module -Name VcRedist -Force
```