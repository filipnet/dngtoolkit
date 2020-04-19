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
Write-Host -NoNewline "Check $($FileDescription) ($($FileName)): "
If (Test-Path $FilePath\$FileName) {
    Write-Host -ForegroundColor Green "PASSED "
}else{
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