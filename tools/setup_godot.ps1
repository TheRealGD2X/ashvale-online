# Sets up the 3D game (godot/) on this PC from the downloads it needs:
#   - Godot 4.7.2 (Godot_v4.7.2-stable_win64.exe.zip)            -> tools\godot\
#   - the Quaternius kits (Stylized Nature, Medieval Village, Fantasy Props MegaKits and
#     Universal Animation Library 1 + 2, the [Standard] zips)       -> godot\assets\...
# Safe to run again: it only copies what is missing or newer. Nothing is deleted.
# (Zip names contain [Standard]; square brackets are wildcards to PowerShell, hence -LiteralPath everywhere.)
#   powershell -ExecutionPolicy Bypass -File tools\setup_godot.ps1
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$dl = Join-Path $env:USERPROFILE "Downloads"
$tmp = Join-Path $env:TEMP "ashvale_setup"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

function Unzip($zipName, $dest) {
  # exact file name (the names contain [ ], which PowerShell's -Filter/-Path treat as wildcards)
  $zip = Get-ChildItem -LiteralPath $dl -File | Where-Object { $_.Name -eq $zipName } | Select-Object -First 1
  if (-not $zip) { Write-Host "  missing: $zipName (in Downloads)" -ForegroundColor Yellow; return $null }
  $out = Join-Path $tmp $dest
  $done = Join-Path $out ".unpacked"
  if (-not (Test-Path -LiteralPath $done)) {
    Write-Host "  unpacking $($zip.Name)..."
    if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }   # a half-finished earlier attempt (our own temp folder)
    Expand-Archive -LiteralPath $zip.FullName -DestinationPath $out -Force
    New-Item -ItemType File -Path $done | Out-Null
  }
  return $out
}

Write-Host "Godot engine"
$gd = Join-Path $repo "tools\godot"
if (-not (Test-Path (Join-Path $gd "Godot_v4.7.2-stable_win64.exe"))) {
  $z = Get-ChildItem -Path $dl -Filter "Godot_v4.7.2-stable_win64.exe.zip" | Select-Object -First 1
  if ($z) { Expand-Archive -LiteralPath $z.FullName -DestinationPath $gd -Force; Write-Host "  ok" } else { Write-Host "  missing Godot zip in Downloads" -ForegroundColor Yellow }
} else { Write-Host "  already there" }

$kits = @(
  @{ zip = "Stylized Nature MegaKit[Standard].zip"; key = "nature" },
  @{ zip = "Medieval Village MegaKit[Standard].zip"; key = "village" },
  @{ zip = "Fantasy Props MegaKit[Standard].zip"; key = "props" }
)
foreach ($k in $kits) {
  Write-Host "Kit: $($k.key)"
  $src = Unzip $k.zip $k.key
  if (-not $src) { continue }
  # the kit's glTF folder (holds .gltf + .bin + textures)
  $g = Get-ChildItem -LiteralPath $src -Recurse -Directory -Filter "glTF" | Where-Object { (Get-ChildItem -LiteralPath $_.FullName -Filter *.gltf).Count -gt 0 } | Select-Object -First 1
  if (-not $g) { Write-Host "  no glTF folder found in the zip" -ForegroundColor Yellow; continue }
  $dest = Join-Path $repo "godot\assets\$($k.key)"
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  robocopy "$($g.FullName)" "$dest" /E /XO /NFL /NDL /NJH /NJS /NP | Out-Null
  Write-Host "  $((Get-ChildItem $dest -Filter *.gltf).Count) models"
}

Write-Host "Animations"
$anims = Join-Path $repo "godot\assets\anims"
New-Item -ItemType Directory -Force -Path $anims | Out-Null
foreach ($a in @(@{ zip = "Universal Animation Library[Standard].zip"; glb = "UAL1_Standard.glb"; out = "UAL1.glb" }, @{ zip = "Universal Animation Library 2[Standard].zip"; glb = "UAL2_Standard.glb"; out = "UAL2.glb" })) {
  $src = Unzip $a.zip ($a.out -replace ".glb", "")
  if (-not $src) { continue }
  $f = Get-ChildItem -LiteralPath $src -Recurse -File | Where-Object { $_.Name -eq $a.glb } | Select-Object -First 1
  if (-not $f) { Write-Host "  $($a.glb) not found in the zip" -ForegroundColor Yellow; continue }
  Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $anims $a.out) -Force
  Write-Host "  $($a.out)"
}

Write-Host "Importing assets (first time takes a minute or two)..."
& (Join-Path $gd "Godot_v4.7.2-stable_win64_console.exe") --headless --path (Join-Path $repo "godot") --import
Write-Host "Done. Double-click 'Play Ashvale.bat' to play." -ForegroundColor Green
