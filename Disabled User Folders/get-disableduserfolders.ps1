[CmdletBinding(SupportsShouldProcess=$True, ConfirmImpact="High")]
param(
   [Parameter(Mandatory=$True,Position=1)]
   [string]$filePath
)

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] “Administrator”))
{
    Write-Warning “You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!”
    Break
}

$folders = Get-ChildItem $filePath -Directory
$moveDate = get-date -format "yyyyMMdd"
$moveCount = 0
$activeCount = 0
$unknownCount = 0

if (!(Test-Path "$filePath\_Disabled Users")) {
    $null = New-Item -Name "_Disabled Users" -ItemType directory -Path $filepath
}

foreach ($f in $folders){
    if ($f.Name.StartsWith('_')) {
        Write-Verbose "$($f.Name) is not a home folder, skipping."
    } else {
        Try {
            $catch = Get-ADUser $f.Name -Properties Enabled, Description | Select-Object Enabled, Description -ErrorAction Stop
            if($catch.Enabled -eq $true){
                Write-Verbose "$($f.Name) is not disabled."
                $activeCount++
            } else {
                if($PSCmdlet.ShouldProcess("$($filepath)\$($f)", "Move folder to _Disabled Users.")){
                    Write-Output "$($f.Name) is disabled. AD Description: $($catch.Description)."
                    Move-Item -Path $filePath\$f -Destination "$filePath\_Disabled Users\$($moveDate)_$($f.Name)"
                    $moveCount++
                }
            }
        }
        Catch {
            Write-Output "$($f.Name) does not exist or is not named correctly."
            # Move-Item -Path $filePath\$f -Destination "$filePath\_Disabled Users"
            $unknownCount++            
        }
    }


}

Write-Output ""
Write-Output "=== Results ==="
Write-Output "Folders moved: $($moveCount)"
Write-Output "Folders still active: $($activeCount)"
Write-Output "Folders with unknown or incorrect names: $($unknownCount)" 