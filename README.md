# DNG ToolKit

Automatic conversion of multiple RAW files to DNG format with Adobe DNG Converter via PowerShell 

## REQUIREMENTS

- PowerShell version 3 and above
- For this script to work you need to install the free Adobe DNG Converter. https://helpx.adobe.com/photoshop/using/adobe-dng-converter.html#DownloadtheDNGConverter 

## INSTALL AND USAGE

- Make sure that the requirements (see REQUIREMENTS) are fulfilled
- Download a zip file and uncompress it
- Adjust the settings in Settings.xml to your environment and requirements
- Start the PowerShell script using the supplied DNGToolKit.bat
- Select the action you want to perform from the menu

You want to test the script before it actually moves/copies files or executes actions?
Set the following variable of Settings.xml to $true - <testing>$true</testing> 

## FEATURES

This PowerShell script supports Lightroom 6.14 (and below) on-premise users. Several actions are available.

- Move or Copy RAW files from an external storage device to subfolders sorted by date of recording
- Automatic convertation of the imported folders into DNG format via command line
- Automatic deletion of rejected and deleted ARW files (by Lightroom) in the working directory

The syntax of the Adobe DNG Converter command line arguments can be found here:
https://wwwimages2.adobe.com/content/dam/acom/en/products/photoshop/pdfs/dng_commandline.pdf

The default parameters are as follows, but can be customized via Settings.xml
 -u Output uncompressed DNG files
 -p1 Set JPEG preview size to medium size (default)
 -fl Embed fast load data
 -cr7.1 Set Camera Raw compatibility to 7.1 and later

## DIRECTORIES

- DNGToolKit.ps1 - The main PowerShell script with the program logic
- Settings.xml - Configuration file to adapt to the own needs and system environment
- DNGToolkit.bat - The start script that skips the PowerShell execution policy
- Library.ps1 - Functions required by the main script have been swapped out due to readability
- README.md - The manual for this PowerShell Script
- LICENSE - The license notes for this PowerShell script

## HISTORY

2020-04-18 - Added to BSD 3-Clause License, Initial creation of README.md, LICENSE

## LICENSE

DNG ToolKit and all individual scripts are under the BSD 3-Clause license unless explicitly noted otherwise. Please refer to the LICENSE
