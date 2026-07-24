# Source Control Condition Checker Script
param (
    [string]$ProjectPath = "."
)

Write-Host "--- Git Status ---" -ForegroundColor Cyan
git status

Write-Host "`n--- Git Diff Summary ---" -ForegroundColor Cyan
git diff --stat
