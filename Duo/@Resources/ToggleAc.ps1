param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('script.master_ac_toggle', 'script.kids_ac_toggle')]
    [string]$Entity
)
$ErrorActionPreference = 'Stop'
try {
    $root = Split-Path -Parent $MyInvocation.MyCommand.Path
    $enc = New-Object System.Text.UnicodeEncoding $false, $true
    $text = [System.IO.File]::ReadAllText((Join-Path $root 'Variables.inc'), $enc)
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) { $text = $text.Substring(1) }
    function Read-Var([string]$name) {
        $found = [regex]::Match($text, "(?m)^$name=(.+)$")
        if (-not $found.Success) { throw "missing $name" }
        return $found.Groups[1].Value.Trim()
    }
    $token = Read-Var 'HAToken'
    $hostUrl = (Read-Var 'HAHost').TrimEnd('/')
    $body = '{"entity_id":"' + $Entity + '"}'
    Invoke-RestMethod -Method Post -Uri ($hostUrl + '/api/services/script/turn_on') -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json' -Body $body | Out-Null
    Write-Output 'ok'
} catch {
    Write-Output 'fail'
    exit 1
}