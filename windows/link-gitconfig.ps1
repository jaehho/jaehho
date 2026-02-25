# link-gitconfig.ps1
# Creates a symbolic link at the global Git config location pointing to this
# repo's copy of .gitconfig.
#
# Run once from an elevated prompt (or with Developer Mode enabled):
#   powershell -ExecutionPolicy Bypass -File link-gitconfig.ps1

$source = Join-Path (Split-Path $PSScriptRoot) "config\.gitconfig"
$target = Join-Path $HOME ".gitconfig"

if ((Get-Item $target -ErrorAction SilentlyContinue).LinkType -eq "SymbolicLink") {
    Write-Host "Symlink already exists: $target -> $((Get-Item $target).Target)"
    exit 0
}

if (Test-Path $target) {
    Write-Warning "A real file already exists at:`n  $target`nRemove or back it up before running this script."
    exit 1
}

New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
Write-Host "Created symlink:`n  $target`n  -> $source"
