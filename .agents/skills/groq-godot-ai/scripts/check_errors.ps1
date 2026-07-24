# Godot 4 Console & Syntax Error Checker Script
param (
    [string]$GodotPath = "C:\Users\sahil\OneDrive\Desktop\Godot_v4.7.1.exe",
    [string]$ProjectPath = "."
)

Write-Host "--- Running Godot 4 Headless Verification ---" -ForegroundColor Cyan
& $GodotPath --path $ProjectPath --headless --check-only
if ($? -and ($global:LASTEXITCODE -eq 0 -or $null -eq $global:LASTEXITCODE)) {
    Write-Host "[OK] Godot 4 syntax check PASSED cleanly with 0 errors!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Godot 4 check FAILED!" -ForegroundColor Red
}

Write-Host "--- Checking for missing or invalid texture .import files ---" -ForegroundColor Cyan
$invalidImports = Get-ChildItem -Path "$ProjectPath/textures" -Filter "*.import" -ErrorAction SilentlyContinue | Where-Object {
    (Get-Content $_.FullName -Raw) -match "valid=false"
}

if ($invalidImports) {
    Write-Host "[WARNING] Found invalid texture .import files:" -ForegroundColor Red
    $invalidImports | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Yellow }
    Write-Host "Running Godot editor import trigger..." -ForegroundColor Cyan
    & $GodotPath --path $ProjectPath --headless --editor --quit | Out-Null
} else {
    Write-Host "[OK] All texture import files are valid!" -ForegroundColor Green
}
