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
$dng_exec_path = $ConfigFile.settings.dng.binary
$dng_base_args = $ConfigFile.settings.dng.arguments
$WhatIfPreference = $ConfigFile.settings.other.testing
$disclaimer = $ConfigFile.settings.other.disclaimer

<#
.SYNOPSIS
Automatic conversion of multiple RAW files to DNG format with Adobe DNG Converter via PowerShell 

.DESCRIPTION
This PowerShell script supports Lightroom 6.14 on-premise users. Several actions are available.
For more information please refer to the README.TXT

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

Write-Host -NoNewline "Check PowerShell Version: "
if ($PSVersionTable.PSVersion.Major -gt 3)
{
	Write-Host -ForegroundColor Green "PASSED "
}else{
    Write-Host -ForegroundColor Red "FAILED "
	Write-Host -ForegroundColor DarkBlue "PowerShell major version 3 is required, you use version $($PSVersionTable.PSVersion.Major)"
}

Check-FolderFile -FileName "DNGToolKit_library.ps1" -FileDescription "DNGToolKit function library"
Check-FolderFile -FileName "Settings.xml" -FileDescription "Configuration XML-file"
Check-FolderFile -FileName "$dng_exec_path" -FileDescription "Adobe DNG Converter installation"
Check-FolderFile -FilePath "$convert_root_path" -FileDescription "Convertation path"
Check-FolderFile -FilePath "$workplace_root_path" -FileDescription "Workplace path"

Write-Host ""
Write-Host "$($disclaimer)"
Write-Host ""
Write-Host "Press any key to continue ....."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Generate menu
$OptionArray = @("Copy RAW/ARW-files from SD-Card","Move RAW/ARW-files from SD-Card","Convert ARW to DNG","Delete unused RAW/ARW-files","Quit and exit")
$Banner = "
DNGToolKit
Version 1.0
Author: Benedikt Filip
License: DNG ToolKit and all individual scripts are under the BSD 3-Clause license
-----------------------------------------------------------"
do {
	$MenuResult = Create-Menu -MenuTitle $Banner -MenuOptions $OptionArray
	Switch($MenuResult){
		0{
			# Copy RAW/ARW-files from SD-Card
			Write-Host -BackgroundColor Blue "Copy RAW/ARW-files from SD-card"
			if (!(Test-Path $src_volume_import)) {
				Write-Host -ForegroundColor Red "Please insert SD-card to Volume $($src_volume_import)"
			}else{
				$arw_files = Get-ChildItem -Recurse "$src_volume_import\*.$src_extension" 
				$c1 = 0
				Clear-Host
				foreach ($arw in $arw_files){
					$c1++
					Write-Progress -Id 0 -Activity 'Copy RAW/ARW-files from SD-Card to convertation directory' -Status "Processing $($c1) of $($arw_files.count)" -CurrentOperation $arw -PercentComplete (($c1/$arw_files.Count) * 100)
					Start-Sleep -Milliseconds 200
					$x = $arw.LastWriteTime.ToShortDateString()
					$new_folder = Get-Date $x -Format yyyy-MM-dd
					$dst_path = "$convert_root_path\$($new_folder)\"
					if (!(Test-Path $dst_path)) {New-Item -Path $dst_path -ItemType Directory}
					Copy-Item $($arw.FullName) -Destination $dst_path
					Write-Host -NoNewline "Copying $($arw.FullName) to $($dst_path): "
					Write-Host -ForegroundColor Green "OK"
					Write-Progress -Activity 'Examining assemblies' -Completed
				}
			}

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}

		1{
			# Move RAW/ARW-files from SD-Card
			Write-Host -BackgroundColor Blue "Move RAW/ARW-files from SD-card"
			if (!(Test-Path $src_volume_import)) {
				Write-Host -ForegroundColor Red "Please insert SD-card to Volume $($src_volume_import)"
			}else{
				$arw_files = Get-ChildItem -Recurse "$src_volume_import\*.$src_extension" 
				$c1 = 0
				Clear-Host
				foreach ($arw in $arw_files){
					$c1++
					Write-Progress -Id 0 -Activity 'Move RAW/ARW-files from SD-Card to convertation directory' -Status "Processing $($c1) of $($arw_files.count)" -CurrentOperation $arw -PercentComplete (($c1/$arw_files.Count) * 100)
					Start-Sleep -Milliseconds 200
					$x = $arw.LastWriteTime.ToShortDateString()
					$new_folder = Get-Date $x -Format yyyy-MM-dd
					$dst_path = "$convert_root_path\$($new_folder)\"
					if (!(Test-Path $dst_path)) {New-Item -Path $dst_path -ItemType Directory}
					Move-Item $($arw.FullName) -Destination $dst_path
					Write-Host -NoNewline "Moving $($arw.FullName) to $($dst_path): "
					Write-Host -ForegroundColor Green "OK"
					Write-Progress -Activity 'Examining assemblies' -Completed
				}
			}

			[System.Media.SystemSounds]::Beep.Play();
			Write-Host "Press any key to continue ....."
			$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}


		2{
			# Convert ARW to DNG
			Write-Host -BackgroundColor Blue "Convert ARW to DNG"
			$sourceFiles = Get-ChildItem -Path $convert_root_path -Recurse -Include *.$src_extension
			if ($sourceFiles.count -eq 0) {
				Write-Host -ForegroundColor Red "There are no files to convert in the directory $($convert_root_path)"
				Write-Host "Press any key to continue ....."
				$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			}else{
				$c1 = 0
				Clear-Host
				ForEach ($file in $sourceFiles) {
					$c1++
					Write-Progress -Id 0 -Activity 'Converting ARW to DNG' -Status "Processing $($c1) of $($sourceFiles.count)" -CurrentOperation $file -PercentComplete (($c1/$sourceFiles.Count) * 100)
					Start-Sleep -Milliseconds 200
					$fullArgs = $dng_base_args + """$file"""
					$process = start-process $dng_exec_path $fullArgs -Wait -PassThru
					if ($process.ExitCode -eq 0)
					{
						Write-Host -NoNewline "Converted $($file): "
						Write-Host -ForegroundColor Green "SUCCESS" 
					}
					else
					{
						Write-Host -NoNewline "Converted $($file): "
						Write-Host -ForegroundColor Red "ERROR OCCURED, TRY AGAIN" 
					}
					Write-Progress -Activity 'Examining assemblies' -Completed
				}

				Write-Host "Move subdirectories to Lighroom workplace directory" -ForegroundColor Cyan
				Get-ChildItem -Path $convert_root_path -Recurse | Move-Item -Destination $workplace_root_path

				[System.Media.SystemSounds]::Beep.Play();
				Write-Host "Press any key to continue ....."
				$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			}
		}

		3{
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
		4{
			# Quit and exit
			exit
		}
		Default{
			# Quit and exit
			exit
		}
	}
} while ($MenuResult -ne 4)