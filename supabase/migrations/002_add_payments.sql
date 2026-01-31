# Create bin directory
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\bin" | Out-Null

# Download latest Windows binary
$url = "https://github.com/supabase/cli/releases/latest/download/supabase_windows_amd64.tar.gz"
$output = "$env:TEMP\supabase.tar.gz"

Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing

# Extract
tar -xzf $output -C "$env:USERPROFILE\bin"

# Add to PATH for current session
$env:Path += ";$env:USERPROFILE\bin"

# Verify
& "$env:USERPROFILE\bin\supabase.exe" --version