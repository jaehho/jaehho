# link-profile.ps1
# Creates a symbolic link at the standard $PROFILE location pointing to this
# OneDrive-synced copy of the profile.
#
# Run once from an elevated prompt (or with Developer Mode enabled):
#   powershell -ExecutionPolicy Bypass -File link-profile.ps1

$source = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"
$target = $PROFILE  # e.g. C:\Users\<user>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

if ((Get-Item $target -ErrorAction SilentlyContinue).LinkType -eq "SymbolicLink") {
    Write-Host "Symlink already exists: $target -> $((Get-Item $target).Target)"
    exit 0
}

if (Test-Path $target) {
    Write-Warning "A real file already exists at:`n  $target`nRemove or back it up before running this script."
    exit 1
}

$targetDir = Split-Path $target
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
Write-Host "Created symlink:`n  $target`n  -> $source"
