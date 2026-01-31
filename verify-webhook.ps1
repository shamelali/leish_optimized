Write-Host "HitPay Webhook Configuration" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

$projectRef = Read-Host "Enter your Supabase project ref"
$hitpaySalt = Read-Host "Enter your HitPay Salt"

$webhookUrl = "https://$projectRef.supabase.co/functions/v1/payment-webhook"

Write-Host "`n=== Configuration Summary ===" -ForegroundColor Green
Write-Host "Webhook URL: $webhookUrl" -ForegroundColor Yellow
Write-Host ""
Write-Host "Set this in HitPay Dashboard:" -ForegroundColor Cyan
Write-Host "  Settings → API Keys & Webhooks → Add Webhook" -ForegroundColor Gray
Write-Host ""
Write-Host "Set this in Supabase Dashboard:" -ForegroundColor Cyan
Write-Host "  https://supabase.com/dashboard/project/$projectRef/functions" -ForegroundColor Gray
Write-Host "  Click 'payment-webhook' → Secrets tab" -ForegroundColor Gray
Write-Host ""
Write-Host "  HITPAY_SALT = $hitpaySalt" -ForegroundColor Green
Write-Host "  SUPABASE_URL = https://$projectRef.supabase.co" -ForegroundColor Green
Write-Host "  SUPABASE_SERVICE_ROLE_KEY = [from Project Settings → API]" -ForegroundColor Green

# Save to file
$config = @"
HitPay Webhook Configuration
============================
Webhook URL: $webhookUrl

Supabase Secrets:
HITPAY_SALT=$hitpaySalt
SUPABASE_URL=https://$projectRef.supabase.co
SUPABASE_SERVICE_ROLE_KEY=[get from Project Settings → API]

HitPay Dashboard:
https://dashboard.hitpayapp.com/settings/api-keys
"@

$config | Out-File -FilePath "webhook-config.txt" -Encoding UTF8
Write-Host "`nSaved to webhook-config.txt" -ForegroundColor Green