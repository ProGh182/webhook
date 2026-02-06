$ErrorActionPreference = "Stop"

if (-not $env:REPO_URL) { throw "Missing REPO_URL" }
if (-not $env:DEPLOY_DIR) { throw "Missing DEPLOY_DIR" }
if (-not $env:TARGET_BRANCH) { $env:TARGET_BRANCH = "main" }

Write-Host "== Deploy started =="
Write-Host "Repo: $env:REPO_URL"
Write-Host "Dir:  $env:DEPLOY_DIR"
Write-Host "Branch: $env:TARGET_BRANCH"

$deployDir = $env:DEPLOY_DIR

if (-not (Test-Path "$deployDir\.git")) {
  Write-Host "Cloning..."
  git clone --branch $env:TARGET_BRANCH $env:REPO_URL $deployDir
} else {
  Write-Host "Pulling latest..."
  git -C $deployDir fetch --all
  git -C $deployDir checkout $env:TARGET_BRANCH
  git -C $deployDir pull --ff-only
}

Write-Host "Installing dependencies..."
Push-Location $deployDir
npm install

Write-Host "Starting app..."
$npmScripts = (npm run) | Out-String
if ($npmScripts -match "\sstart\s") {
  Write-Host "Starting with 'npm run start'..."
  Start-Process npm -ArgumentList "run start"
} elseif ($npmScripts -match "\sdev\s") {
  Write-Host "Starting with 'npm run dev'..."
  Start-Process npm -ArgumentList "run dev -- --host 0.0.0.0"
} else {
  throw "No start/dev script found"
}

Pop-Location
Write-Host "== Deploy done =="
