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
foreach ($fixture in @('test_stair_editor', 'test_image_editor', 'test_image_map_ui', 'test_image_monastery_tower', 'test_sky_coverage', 'test_walkable_stairs', 'test_image_campaign', 'test_image_monastery_routes', 'test_image_monastery_branches', 'test_image_monastery_visual', 'test_paper_stage', 'test_stage_3d', 'test_campaign', 'test_continuation', 'test_connected', 'test_hit_feedback', 'test_claw_melee', 'test_campaign_state', 'test_campaign_session', 'test_campaign_dialogue_review', 'test_monastery_campaign', 'test_campaign_enemy', 'test_campaign_ui', 'test_campaign_residency', 'test_campaign_editor', 'test_arm_rig', 'test_combat_hud', 'test_environment_art', 'test_decor_support', 'test_foreground', 'export_game_text')) {
    $stageOutput = & $Godot --headless --path $projectDirectory --log-file (Join-Path $artifactDirectory "$fixture.log") --fixed-fps 60 --script "res://tests/$fixture.gd" -- --campaign-test 2>&1
    $stageResult = $stageOutput | Select-String 'STAGE RESULT:'
    if ($LASTEXITCODE -ne 0 -or -not $stageResult -or ($stageOutput | Select-String 'SCRIPT ERROR:')) { $stageOutput | Write-Output; exit 1 }
    Write-Output $stageResult
}

$editorOutput = & $Godot --headless --editor --path $projectDirectory --quit-after 600 --log-file (Join-Path $artifactDirectory 'editor-smoke.log') -- --map-editor-smoke 2>&1
$editorResult = $editorOutput | Select-String '^MAP EDITOR RESULT:'
if ($LASTEXITCODE -ne 0 -or -not $editorResult -or ($editorOutput | Select-String 'SCRIPT ERROR:')) { $editorOutput | Write-Output; exit 1 }
Write-Output $editorResult

$campaignEditorOutput = & $Godot --headless --editor --path $projectDirectory --quit-after 600 --log-file (Join-Path $artifactDirectory 'campaign-editor-smoke.log') -- --campaign-editor-smoke 2>&1
$campaignEditorResult = $campaignEditorOutput | Select-String 'CAMPAIGN EDITOR.*RESULT:'
if ($LASTEXITCODE -ne 0 -or -not $campaignEditorResult -or ($campaignEditorOutput | Select-String 'SCRIPT ERROR:')) { $campaignEditorOutput | Write-Output; exit 1 }
Write-Output $campaignEditorResult

$stairEditorOutput = & $Godot --headless --editor --path $projectDirectory --quit-after 600 --log-file (Join-Path $artifactDirectory 'stair-editor-smoke.log') -- --stair-editor-smoke 2>&1
$stairEditorResult = $stairEditorOutput | Select-String '^STAIR EDITOR SMOKE RESULT:'
if ($LASTEXITCODE -ne 0 -or -not $stairEditorResult -or ($stairEditorOutput | Select-String 'SCRIPT ERROR:')) { $stairEditorOutput | Write-Output; exit 1 }
Write-Output $stairEditorResult
