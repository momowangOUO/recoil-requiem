param(
    [string]$Godot = 'D:/godot/Godot_v4.7.2-stable_win64_console.exe',
    [string]$EvidenceDirectory = 'artifacts/navigation-20261027/package'
)
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
$taskEvidence = [IO.Path]::GetFullPath((Join-Path $taskProject $EvidenceDirectory))
$taskExe = Join-Path $taskProject 'builds/windows/RecoilRequiem.exe'
$taskChecks = Join-Path $taskProject 'artifacts/navigation-20261027/checks-final.log'
if (-not (Select-String 'STAIR EDITOR SMOKE RESULT: 13 checks, 0 failures' $taskChecks)) { throw 'Complete tools/run_checks.ps1 first.' }
if (Select-String '^ERROR:|SCRIPT ERROR:|[1-9][0-9]* failures' $taskChecks) { throw 'Regression log contains a failure.' }
foreach ($runtime in @('scripts/ui/campaign_ui.gd','scripts/lab/recoil_lab.gd','scripts/campaign/campaign_session.gd','scenes/rooms/image_monastery.tscn','data/campaign/monastery_text.json','data/campaign/chapter_staging.json')) {
    if ((Get-Item (Join-Path $taskProject $runtime)).LastWriteTimeUtc -gt (Get-Item $taskChecks).LastWriteTimeUtc) { throw "Run checks after changing $runtime." }
}
New-Item -ItemType Directory -Force $taskEvidence, (Join-Path $taskEvidence 'direct-exe') | Out-Null
Copy-Item -LiteralPath $taskChecks -Destination (Join-Path $taskEvidence 'checks.log')
function Invoke-Recorded([string]$label, [scriptblock]$command) {
    Write-Output "Running $label"
    $lines = @(& $command 2>&1)
    $code = $LASTEXITCODE
    $lines | Set-Content -LiteralPath (Join-Path $taskEvidence ($label+'.log')) -Encoding utf8
    if ($code -ne 0 -or ($lines | Select-String 'SCRIPT ERROR:|^ERROR:')) { throw "Verification failed: $label ($code); see its log." }
    $lines | Select-String 'STAGE RESULT:|EXPORT CONTENT CHECK:' | ForEach-Object { Write-Output $_.Line }
}
Invoke-Recorded 'export' { & $Godot --headless --path $taskProject --export-debug 'Windows Desktop' $taskExe }
Push-Location (Split-Path -Parent $taskExe)
try {
Invoke-Recorded 'package-check' { & $Godot --headless --main-pack $taskExe --script "$taskProject/tests/verify_export.gd" -- "--review-root=$taskProject/game-text" }
Invoke-Recorded 'package-capture' { & $Godot --main-pack $taskExe --fixed-fps 60 --script "$taskProject/tests/capture_monastery_rebuild.gd" -- --campaign-test --six-camera-views "--evidence-dir=$taskEvidence" }
Write-Output 'Running direct-exe'
$directStart = [DateTime]::UtcNow
$savedAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $taskEvidence 'player-flow-startup-user'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    $direct = Start-Process -FilePath $taskExe -ArgumentList @('--fixed-fps','60','--write-movie',('"'+$taskEvidence+'/direct-exe/start.png"'),'--log-file',('"'+$taskEvidence+'/direct-exe.log"'),'--quit-after','60') -WindowStyle Hidden -Wait -PassThru
} finally {
    $env:APPDATA = $savedAppData
}
if ($direct.ExitCode -ne 0 -or @(Get-ChildItem "$taskEvidence/direct-exe" -Filter '*.png' | Where-Object LastWriteTimeUtc -ge $directStart).Count -ne 60) { throw 'Direct EXE startup failed.' }
$rows = @()
foreach ($routeName in @('lift','maintenance')) {
    $routeArgs = @('--campaign-test',"--evidence-dir=$taskEvidence")
    if ($routeName -eq 'maintenance') { $routeArgs += '--maintenance' }
    Invoke-Recorded "replay_$routeName" { & $Godot --main-pack $taskExe --fixed-fps 60 --write-movie "$taskEvidence/replay_$routeName.avi" --script "$taskProject/tests/replay_monastery_rebuild.gd" -- @routeArgs }
    $resultText = @(Select-String 'REBUILD CONTINUOUS REPLAY STAGE RESULT:' "$taskEvidence/replay_$routeName.log" | ForEach-Object { $_.Line })
    if ($resultText.Count -ne 1 -or $resultText[0] -notmatch "route=$routeName complete=true" -or $resultText[0] -notmatch 'deaths=(\d+) resets=(\d+)') { throw "Incomplete route: $routeName" }
    if ([int]$Matches[2] -ne [int]$Matches[1]) { throw "Unexpected reset outside normal death recovery: $routeName" }
    $rows += [pscustomobject]@{route=$routeName;exit=0;result=$resultText;movie_bytes=(Get-Item "$taskEvidence/replay_$routeName.avi").Length}
    ConvertTo-Json -InputObject @($rows) -Depth 6 | Set-Content -LiteralPath "$taskEvidence/replay-results.json" -Encoding utf8
}
Invoke-Recorded 'camera-motion' { & $Godot --main-pack $taskExe --fixed-fps 60 --write-movie "$taskEvidence/camera-motion.avi" --script "$taskProject/tests/replay_background_clarity.gd" -- --campaign-test "--evidence-dir=$taskEvidence" }
$fingerprint = [ordered]@{
    date='2026-10-27'; engine=(& $Godot --version | Select-Object -First 1); build_kind='Windows Debug; installed export template'
    executable=@{file='builds/windows/RecoilRequiem.exe';bytes=(Get-Item $taskExe).Length;sha256=(Get-FileHash $taskExe -Algorithm SHA256).Hash.ToLowerInvariant()}
    regression=@{command='tools/run_checks.ps1';exit=0;log_sha256=(Get-FileHash $taskChecks -Algorithm SHA256).Hash.ToLowerInvariant()}
    evidence_method=@{normal_views='Controlled positions; not a playthrough';continuous_routes='Normal keyboard and mouse input against the EXE embedded pack; no teleport, invulnerability or task-state writes';motion='Independent fixture starts; continuous input inside each slice';direct_exe='Direct EXE startup, 60 native frames';human_playtest=$false}
    release_url='https://github.com/momowangOUO/recoil-requiem/releases/download/monastery-2026-10-27'
}
$fingerprint | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$taskEvidence/run-manifest.json" -Encoding utf8
Write-Output "Package verification complete: $taskEvidence"
} finally {
    Pop-Location
}
