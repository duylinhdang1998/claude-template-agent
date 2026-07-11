<#
================================================================================
 VFM Agent Company — Codex CLI installer (Windows / PowerShell)
================================================================================
 Usage:
   powershell -ExecutionPolicy Bypass -File codex\install.ps1              # global → %USERPROFILE%\.codex
   powershell -ExecutionPolicy Bypass -File codex\install.ps1 -Project .   # project → .\.agents\skills + .\AGENTS.md
   powershell -ExecutionPolicy Bypass -File codex\install.ps1 -Uninstall

 Env: CODEX_HOME overrides the Codex home (default: $HOME\.codex)

 Safe: skills tracked in a manifest (stale VFM skills cleaned on reinstall);
       AGENTS.md merged between markers; config.toml is never modified.
================================================================================
#>
param(
  [string]$Project = "",
  [switch]$Global,
  [switch]$Uninstall
)
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dist      = Join-Path $ScriptDir "dist"
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }

$MarkStart = "<!-- >>> VFM-AGENT-COMPANY (Codex) — managed block, do not edit inside >>> -->"
$MarkEnd   = "<!-- <<< VFM-AGENT-COMPANY (Codex) <<< -->"
$ManifestName = ".vfm-company-manifest"

# --- resolve destinations ----------------------------------------------------
if ($Project -ne "") {
  $ProjDir    = (Resolve-Path $Project).Path
  $SkillsDest = Join-Path $ProjDir ".agents\skills"
  $AgentsDest = Join-Path $ProjDir "AGENTS.md"
  $ConfigDir  = Join-Path $ProjDir ".codex"
  $Label      = "project ($ProjDir)"
} else {
  $SkillsDest = Join-Path $CodexHome "skills"
  $AgentsDest = Join-Path $CodexHome "AGENTS.md"
  $ConfigDir  = $CodexHome
  $Label      = "global ($CodexHome)"
}
$Manifest = Join-Path $SkillsDest $ManifestName

function Clean-Previous {
  if (Test-Path $Manifest) {
    Get-Content $Manifest | ForEach-Object {
      if ($_ -ne "") {
        $p = Join-Path $SkillsDest $_
        if (Test-Path $p) { Remove-Item -Recurse -Force $p }
      }
    }
    Remove-Item -Force $Manifest
  }
}

function Remove-Block([string]$file) {
  $lines = Get-Content $file
  $out = @(); $skip = $false
  foreach ($l in $lines) {
    if ($l -eq $MarkStart) { $skip = $true; continue }
    if ($l -eq $MarkEnd)   { $skip = $false; continue }
    if (-not $skip) { $out += $l }
  }
  ($out -join "`n").TrimEnd() | Set-Content -NoNewline $file
}

# --- uninstall ---------------------------------------------------------------
if ($Uninstall) {
  Write-Host "-> Uninstalling VFM Agent Company (Codex) from $Label"
  Clean-Previous
  if (Test-Path $AgentsDest) { Remove-Block $AgentsDest; Write-Host "  OK removed managed block from $AgentsDest" }
  Write-Host "Uninstalled. (config.toml MCP entries, if any, were left untouched.)"
  exit 0
}

# --- ensure dist -------------------------------------------------------------
if (-not (Test-Path (Join-Path $Dist "skills"))) {
  Write-Host "-> dist/ missing — building from .claude/ ..."
  if (-not (Get-Command python3 -ErrorAction SilentlyContinue) -and -not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "python3 required to build. Install Python 3, then re-run."
  }
  $py = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
  & $py (Join-Path $ScriptDir "build.py")
}

Write-Host "============================================================"
Write-Host "  VFM Agent Company -> Codex CLI"
Write-Host "  Install target: $Label"
Write-Host "============================================================"

# --- 1. skills ---------------------------------------------------------------
Write-Host "-> Installing skills ..."
Clean-Previous
New-Item -ItemType Directory -Force -Path $SkillsDest | Out-Null
$count = 0
Set-Content -Path $Manifest -Value $null
Get-ChildItem -Directory (Join-Path $Dist "skills") | ForEach-Object {
  $name = $_.Name
  $target = Join-Path $SkillsDest $name
  if (Test-Path $target) { Remove-Item -Recurse -Force $target }
  Copy-Item -Recurse -Force $_.FullName $target
  Add-Content -Path $Manifest -Value $name
  $count++
}
Write-Host "  OK $count skills -> $SkillsDest"

# --- 2. AGENTS.md ------------------------------------------------------------
Write-Host "-> Installing operating manual (AGENTS.md) ..."
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $AgentsDest) | Out-Null
$content = Get-Content (Join-Path $Dist "AGENTS.md") -Raw
$block = "$MarkStart`n$content`n$MarkEnd"

if (-not (Test-Path $AgentsDest)) {
  Set-Content -Path $AgentsDest -Value $block
  Write-Host "  OK created $AgentsDest"
} elseif (Select-String -Path $AgentsDest -SimpleMatch $MarkStart -Quiet) {
  $lines = Get-Content $AgentsDest
  $out = @(); $skip = $false; $inserted = $false
  foreach ($l in $lines) {
    if ($l -eq $MarkStart) { $out += $block; $skip = $true; $inserted = $true; continue }
    if ($l -eq $MarkEnd)   { $skip = $false; continue }
    if (-not $skip) { $out += $l }
  }
  ($out -join "`n") | Set-Content $AgentsDest
  Write-Host "  OK updated managed block in $AgentsDest"
} else {
  Add-Content -Path $AgentsDest -Value "`n$block"
  Write-Host "  OK appended managed block to $AgentsDest (existing content kept)"
}

# --- 3. MCP snippet ----------------------------------------------------------
Write-Host "-> Writing SEO MCP snippet ..."
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
$snippet = Join-Path $ConfigDir "config.toml.vfm-mcp-snippet"
Copy-Item -Force (Join-Path $Dist "config\mcp-servers.toml") $snippet
Write-Host "  OK $snippet"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Installed."
Write-Host "============================================================"
Write-Host ""
Write-Host "  Start Codex and run:   /work `"Build a task manager app`""
Write-Host "  SEO MCP (optional): add API keys in $snippet then paste"
Write-Host "  the [mcp_servers.*] blocks into $ConfigDir\config.toml"
Write-Host ""
