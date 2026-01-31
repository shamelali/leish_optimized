$deployScript = @'
# PowerShell deployment script for Leish Studios
Write-Host "🎬 Leish Studios - PowerShell Deployment Script" -ForegroundColor Cyan

# Check prerequisites
$prereqs = @("node", "npm", "git")
foreach ($cmd in $prereqs) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Missing: $cmd" -ForegroundColor Red
        exit 1
    }
}

# Get credentials
$projectRef = Read-Host "Enter Supabase Project Ref"
$anonKey = Read-Host "Enter Supabase Anon Key"
$serviceRoleKey = Read-Host "Enter Service Role Key"
$resendKey = Read-Host "Enter Resend API Key"

$supabaseUrl = "https://$projectRef.supabase.co"

# Create directories
New-Item -ItemType Directory -Name "frontend" -Force | Out-Null
New-Item -ItemType Directory -Name "frontend\src" -Force | Out-Null
New-Item -ItemType Directory -Name "supabase" -Force | Out-Null

Write-Host "[SUCCESS] Directories created" -ForegroundColor Green
Write-Host "Next: Run the file creation commands separately" -ForegroundColor Yellow
'@

$deployScript | Out-File -FilePath "deploy.ps1" -Encoding UTF8