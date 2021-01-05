Function Create-Menu (){
    
    Param(
        [Parameter(Mandatory=$True)][String]$MenuTitle,
        [Parameter(Mandatory=$True)][array]$MenuOptions
    )

    $MaxValue = $MenuOptions.count-1
    $Selection = 0
    $EnterPressed = $False
    
    Clear-Host

    While($EnterPressed -eq $False){
        
        Write-Host "$MenuTitle"

        For ($i=0; $i -le $MaxValue; $i++){
            
            If ($i -eq $Selection){
                Write-Host -BackgroundColor Cyan -ForegroundColor Black "[ $($MenuOptions[$i]) ]"
            } Else {
                Write-Host "  $($MenuOptions[$i])  "
            }

        }

        $KeyInput = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode

        Switch($KeyInput){
            13{
                $EnterPressed = $True
                Return $Selection
                Clear-Host
                break
            }

            38{
                If ($Selection -eq 0){
                    $Selection = $MaxValue
                } Else {
                    $Selection -= 1
                }
                Clear-Host
                break
            }

            40{
                If ($Selection -eq $MaxValue){
                    $Selection = 0
                } Else {
                    $Selection +=1
                }
                Clear-Host
                break
            }
            Default{
                Clear-Host
            }
        }
    }
}

function Remove-EmptyFolders([string]$folder){
	Get-ChildItem $folder -Recurse | Where-Object{$_.PSIsContainer -and !(Get-ChildItem $_.Fullname -Recurse | Where-Object{!$_.PSIsContainer})} | remove-item -Force -Recurse -EA SilentlyContinue
}

function Check-FolderFile{
    param(
        [Parameter(Mandatory=$false)]
        [string]$FileName,

        [Parameter(Mandatory=$false)]
        [string]$FilePath,
    
        [Parameter(Mandatory=$false)]
        [string]$FileDescription
    )

    If (!$FileDescription){ $FileDescription=$FileName }
    If (!$FilePath){ $FilePath=$PSScriptRoot }
    Write-Host -NoNewline "Check $($FileDescription): "
    If (Test-Path $FilePath\$FileName) {
        Write-Host -ForegroundColor Green "PASSED "
    } else {
        Write-Host -ForegroundColor Red "FAILED "
        If (!$FileName) {
            Write-Host -ForegroundColor DarkBlue -NoNewline "$($FilePath) does not exist. "
            $confirmation = Read-Host "Should the directory be created for you? [YES/no]"
            if ($confirmation -eq 'YES') {
                New-Item -Path $FilePath -ItemType Directory
            } else {
                exit
            }
        }
    }
}

function Transfer-SDtoDisk {
    param (
        [Parameter(Mandatory, ParameterSetName='ActionType')]
        [ValidateSet('Copy','Move')]
        [string[]]$ActionType
    )
    Write-Host -BackgroundColor Blue "$($ActionType) RAW/ARW-files from SD-card"
    if (!(Test-Path $src_volume_import)) {
        Write-Host -ForegroundColor Red "Please insert SD-card to Volume $($src_volume_import)"
        [System.Media.SystemSounds]::Beep.Play();
        Write-Host "Press any key to continue ....."
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        $arw_files = Get-ChildItem -Recurse "$src_volume_import\*.$src_extension" 
        $c1 = 0
        Clear-Host
        foreach ($arw in $arw_files){
            $c1++
            Write-Progress -Id 0 -Activity "$($ActionType) RAW/ARW-files from SD-Card to convertation directory" -Status "Processing $($c1) of $($arw_files.count)" -CurrentOperation $arw -PercentComplete (($c1/$arw_files.Count) * 100)
            Start-Sleep -Milliseconds 200
            $x = $arw.LastWriteTime.ToShortDateString()
            $new_folder = Get-Date $x -Format yyyy-MM-dd
            $dst_path = "$convert_root_path\$($new_folder)\"
            if (!(Test-Path $dst_path)) {New-Item -Path $dst_path -ItemType Directory}
            if ($ActionType -eq "Copy") {
                Copy-Item $($arw.FullName) -Destination $dst_path
                Write-Host -NoNewline "$($ActionType) $($arw.FullName) to $($dst_path): "
                Write-Host -ForegroundColor Green "OK"
                Write-Progress -Activity 'Examining assemblies' -Completed
            }
            if ($ActionType -eq "Move") {
                Move-Item $($arw.FullName) -Destination $dst_path
                Write-Host -NoNewline "$($ActionType) $($arw.FullName) to $($dst_path): "
                Write-Host -ForegroundColor Green "OK"
                Write-Progress -Activity 'Examining assemblies' -Completed
            }
        }
    }    
}

function Convert-ARWtoDNG {
    Write-Host -BackgroundColor Blue "Convert ARW to DNG"
    $sourceFiles = Get-ChildItem -Path $convert_root_path -Recurse -Include *.$src_extension
    if ($sourceFiles.count -eq 0) {
        Write-Host -ForegroundColor Red "There are no files to convert in the directory $($convert_root_path)"
    } else {
        $c1 = 0
        Clear-Host
        ForEach ($file in $sourceFiles) {
            $c1++
            Write-Progress -Id 0 -Activity 'Converting ARW to DNG' -Status "Processing $($c1) of $($sourceFiles.count)" -CurrentOperation $file -PercentComplete (($c1/$sourceFiles.Count) * 100)
            Start-Sleep -Milliseconds 200
            $fullArgs = $dng_base_args + """$file"""
            $process = start-process $dng_exec_bin $fullArgs -Wait -PassThru
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
    }
}