param([string]$Godot = 'D:\godot\Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$artifactDirectory = Join-Path $projectDirectory 'artifacts'
New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
if (-not (Test-Path -LiteralPath $Godot)) { throw "Godot executable not found: $Godot" }
$importOutput = & $Godot --headless --path $projectDirectory --log-file (Join-Path $artifactDirectory 'import.log') --import 2>&1
if ($LASTEXITCODE -ne 0) { $importOutput | Write-Output; exit 1 }
foreach ($renderFps in @(30, 60, 144)) {
    $checkOutput = & $Godot --headless --path $projectDirectory --log-file (Join-Path $artifactDirectory "tests-$renderFps.log") --fixed-fps $renderFps --script res://tests/run_tests.gd 2>&1
    $resultLine = $checkOutput | Select-String '^RESULT:'
    if ($LASTEXITCODE -ne 0 -or -not $resultLine -or ($checkOutput | Select-String 'SCRIPT ERROR:')) {
        $checkOutput | Write-Output
        exit 1
    }
    Write-Output "Render $renderFps FPS / Physics 60 Hz: $resultLine"
    $feelOutput = & $Godot --headless --path $projectDirectory --log-file (Join-Path $artifactDirectory "feel-$renderFps.log") --fixed-fps $renderFps --script res://tests/test_movement_feel.gd 2>&1
    $feelResult = $feelOutput | Select-String '^FEEL RESULT:'
    if ($LASTEXITCODE -ne 0 -or -not $feelResult -or ($feelOutput | Select-String 'SCRIPT ERROR:')) { $feelOutput | Write-Output; exit 1 }
    Write-Output "Responsive movement at $renderFps FPS: $feelResult"
}
$overlayOutput = & $Godot --headless --path $projectDirectory --log-file (Join-Path $artifactDirectory 'overlay.log') --script res://tests/test_overlay.gd 2>&1
if ($LASTEXITCODE -ne 0 -or ($overlayOutput | Select-String 'SCRIPT ERROR:')) { $overlayOutput | Write-Output; exit 1 }
Write-Output 'Overlay configuration and layout checks: PASS'
$replayOutput = & $Godot --headless --path $projectDirectory --log-file (Join-Path $artifactDirectory 'replay_headless.log') --fixed-fps 60 --script res://tests/replay_playtest.gd 2>&1
$replayResult = $replayOutput | Select-String '^REPLAY RESULT:'
if ($LASTEXITCODE -ne 0 -or -not $replayResult -or ($replayOutput | Select-String 'SCRIPT ERROR:')) { $replayOutput | Write-Output; exit 1 }
Write-Output "Keyboard/mouse engine-event replay (60 FPS): $replayResult"
