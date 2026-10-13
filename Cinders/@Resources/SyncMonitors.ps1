# Rewrites Monitor2.ini and Monitor3.ini from Overlay.ini.
# Run this after editing the cinder formulas in Overlay.ini.
# Turning displays on or off does not need this script. Refresh Cinders\Overlay for that.
# Do not call Rainmeter from here. A program started by the skin cannot reliably send bangs back.

$ErrorActionPreference = "Stop"

$resources = $PSScriptRoot
$cinders = Split-Path $resources -Parent
$overlayPath = Join-Path $cinders "Overlay\Overlay.ini"
$utf8 = New-Object System.Text.UTF8Encoding $false
$overlay = [System.IO.File]::ReadAllText($overlayPath, $utf8)

foreach ($n in 2, 3) {
    $copy = [regex]::Replace(
        $overlay,
        '\["powershell\.exe".*?SyncMonitors\.ps1"\]',
        ""
    )
    $copy = [regex]::Replace(
        $copy,
        "(?s)\r?\n; BEGIN MONITOR SWITCH.*?; END MONITOR SWITCH\r?\n?",
        "`r`n"
    )
    $copy = $copy.Replace('[!ActivateConfig "Cinders\Monitor2" "Monitor2.ini"]', "")
    $copy = $copy.Replace('[!ActivateConfig "Cinders\Monitor3" "Monitor3.ini"]', "")
    $copy = $copy.Replace("@1#", "@$n#")
    $copy = $copy.Replace("[!ZPos -2]", "")
    $copy += @"

[MeasureLayer]
Measure=Calc
Formula=#SCREENAREAHEIGHT@$n#
IfCondition=(#SCREENAREAHEIGHT@$n# < 800)
IfTrueAction=[!ZPos 2]
IfFalseAction=[!ZPos 0]
UpdateDivider=-1
DynamicVariables=1

[MeasureStay]
Measure=Calc
Formula=#Monitor$n#
IfCondition=(#Monitor$n# = 0)
IfTrueAction=[!DeactivateConfig "Cinders\Monitor$n"]
IfConditionMode=1
UpdateDivider=-1
DynamicVariables=1
"@
    $copy = $copy.Replace("on the primary monitor", "on monitor $n")
    $copy = $copy.Replace("for one monitor. This file is monitor 1, the primary screen.", "for monitor $n.")

    $dir = Join-Path $cinders "Monitor$n"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $dest = Join-Path $dir "Monitor$n.ini"
    [System.IO.File]::WriteAllText($dest, $copy, $utf8)
}
