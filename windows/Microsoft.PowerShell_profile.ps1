function mililabTunnel {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("start", "stop", "status")]
        [string]$Action
    )

    switch ($Action) {
        "start" {
            $existing = Get-Job -Name "mililabTunnel" -ErrorAction SilentlyContinue
            if ($existing) { Write-Host "Tunnel already running (State: $($existing.State))"; return }
            $pass = Read-Host -Prompt "dev.ee.cooper.edu password" -AsSecureString
            $plainpass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
            Start-Job -Name "mililabTunnel" -ScriptBlock {
                plink -P 31415 -pw $using:plainpass -L 14000:10.5.1.124:4000 jaeho.cho@dev.ee.cooper.edu -N
            }
            Write-Host "mililab tunnel started. Connect NoMachine to localhost:14000"
        }
        "stop" {
            Stop-Job -Name "mililabTunnel" -ErrorAction SilentlyContinue
            Remove-Job -Name "mililabTunnel" -ErrorAction SilentlyContinue
            Write-Host "mililab tunnel stopped."
        }
        "status" {
            $job = Get-Job -Name "mililabTunnel" -ErrorAction SilentlyContinue
            if ($job) { Write-Host "State: $($job.State) | HasMoreData: $($job.HasMoreData)" }
            else { Write-Host "No tunnel running." }
        }
    }
}
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
