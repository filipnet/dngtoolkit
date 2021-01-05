[CmdletBinding()]
param ()

# Import function library
. "$PSScriptRoot\Library.ps1"

# Import settings from config file
[xml]$ConfigFile = Get-Content "Settings.xml"

$src_volume_import = $ConfigFile.settings.folders.sdcard
$src_extension = $ConfigFile.settings.environment.extension
$convert_root_path = $ConfigFile.settings.folders.convertation
$workplace_root_path = $ConfigFile.settings.folders.workplace
$dng_exec_path = $ConfigFile.settings.dng.path
$dng_exec_bin = $ConfigFile.settings.dng.binary
$dng_base_args = $ConfigFile.settings.dng.arguments
$WhatIfPreference = $false # $ConfigFile.settings.other.testing
$disclaimer = $ConfigFile.settings.other.disclaimer

<#
.SYNOPSIS
Automatic conversion of multiple RAW files to DNG format with Adobe DNG Converter via PowerShell 
.DESCRIPTION
This PowerShell script supports Lightroom 6.14 on-premise users. Several actions are available.
For more information please refer to the README.MD
.EXAMPLE
./DNGToolKit.bat
.NOTES
Author:         Benedikt Filip
License:        DNG ToolKit and all individual scripts are under the BSD 3-Clause license
.LINK
https:/www.filipnet.de
#>

# Check on start
Clear-Host
Write-Host -BackgroundColor Blue "Check system environments on startup"
Write-Host ""

Write-Host -NoNewline "Check Whatif: "
 if ($WhatIfPreference)
{
 	Write-Host -ForegroundColor Green "ENABLED "
}else{
 	Write-Host -ForegroundColor Yellow "DISABLED "
}

Write-Host -NoNewline "Check PowerShell Version: "
if ($PSVersionTable.PSVersion.Major -gt 3)
{
	Write-Host -ForegroundColor Green "PASSED "
}else{
    Write-Host -ForegroundColor Red "FAILED "
	Write-Host -ForegroundColor DarkBlue "PowerShell major version 3 is required, you use version $($PSVersionTable.PSVersion.Major)"
}

Check-FolderFile -FileName "Library.ps1" -FileDescription "DNGToolKit function library"
Check-FolderFile -FileName "Settings.xml" -FileDescription "Configuration XML-file"
Check-FolderFile -FilePath "$dng_exec_path" -FileDescription "Adobe DNG Converter installation"
Check-FolderFile -FilePath "$convert_root_path" -FileDescription "Convertation path"
Check-FolderFile -FilePath "$workplace_root_path" -FileDescription "Workplace path"

Write-Host ""
Write-Host "$($disclaimer)"
Write-Host ""
Write-Host "Press any key to continue ....."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Generate menu
$OptionArray = @("Copy RAW/ARW-files from SD-Card","Copy RAW/ARW-files from SD-Card & Convert","Move RAW/ARW-files from SD-Card","Move RAW/ARW-files from SD-Card & Convert","Convert ARW to DNG","Delete unused RAW/ARW-files","Delete ARW from memory card (attention)","Quit and exit")
$Banner = "
DNGToolKit
Latest version: https://github.com/filipnet/dngtoolkit
Author: Benedikt Filip
License: DNG ToolKit and all individual scripts are under the BSD 3-Clause license
-----------------------------------------------------------"
do {
	$MenuResult = Create-Menu -MenuTitle $Banner -MenuOptions $OptionArray
	Switch($MenuResult){
		0{
			# Copy RAW/ARW-files from SD-Card
			Transfer-SDtoDisk -ActionType Copy

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		1{
			# Copy RAW/ARW-files from SD-Card & Convert
			Transfer-SDtoDisk -ActionType Copy
			Convert-ARWtoDNG

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		2{
			# Move RAW/ARW-files from SD-Card
			Transfer-SDtoDisk -ActionType Move

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		3{
			# Move RAW/ARW-files from SD-Card & Convert
			Transfer-SDtoDisk -ActionType Move
			Convert-ARWtoDNG

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		4{
			# Convert ARW to DNG
			Convert-ARWtoDNG

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		5{
			# Delete unused RAW/ARW-files
			Write-Host -BackgroundColor Blue "Delete unused RAW/ARW-files"
			$arw = Get-ChildItem -r -force -include *.arw -ErrorAction SilentlyContinue $workplace_root_path | Sort-Object -Unique
			Clear-Host
			foreach ($rawFile in $arw) {
				$dngFile = join-path $rawFile.DirectoryName "$($rawFile.BaseName).DNG"
				if (Test-Path $dngFile) {
					Write-Host -NoNewline "DNG for $rawFile exist: "
					Write-Host -ForegroundColor Green "KEEP" 
				} else {
					Write-Host -NoNewline "DNG for $rawFile not exist: "
					Write-Host -ForegroundColor Red "DELETE"
					remove-item $rawFile
				}
			}
			Write-Host "Deleting empty folders" -ForegroundColor Red
			Get-ChildItem $workplace_root_path -Recurse | Where-Object{$_.PSIsContainer -and !(Get-ChildItem $_.Fullname -Recurse | Where-Object{!$_.PSIsContainer})} | Format-Table Name,CreationTime,LastAccessTime,LastWriteTime -AutoSize
			Remove-EmptyFolders $workplace_root_path
			
			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		6{
			# Delete ARW from memory card
			Write-Host -BackgroundColor Blue "Delete RAW/ARW-files from memory card"
			$confirmation = Read-Host -Prompt 'Are you really sure you would like to delete all photos from your memory card? Type YES and press enter'

			if ($confirmation -contains "YES") {
				Write-Host "Your confirmation input was [$confirmation]"  so all photos from your memory card would be erased.
				$arw = Get-ChildItem -r -force -include *.arw -ErrorAction SilentlyContinue $src_volume_import | Sort-Object -Unique
				Clear-Host
				foreach ($rawFile in $arw) {
					Write-Host -NoNewline "$rawFile : "
					Write-Host -ForegroundColor Red "DELETE"
					remove-item $rawFile
				}
			} else {
				Write-Warning -Message "Your input is not valid" 
			}

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		7{
			# Quit and exit
			exit
		}

		Default{
			# Quit and exit
			exit
		}
	}
} while ($MenuResult -ne 7)