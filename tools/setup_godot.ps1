# Sets up the 3D game (godot/) on this PC from the downloads it needs:
#   - Godot 4.7.2 (Godot_v4.7.2-stable_win64.exe.zip)            -> tools\godot\
#   - the Quaternius kits (Stylized Nature, Medieval Village, Fantasy Props MegaKits and
#     Universal Animation Library 1 + 2, the [Standard] zips)       -> godot\assets\...
#   - the paid [Source] packs (Universal Base Characters, Modular Character Outfits - Fantasy,
#     Bestiary - Dungeon Monsters Kit): zips or already-extracted folders -> godot\assets\licensed\...
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

# ---- the paid [Source] packs (characters, outfits, monsters): unpacked into godot\assets\licensed,
# which is never uploaded to GitHub (the licence forbids sharing the models themselves)
$lic = Join-Path $repo "godot\assets\licensed"
function SourcePack($name) {
  # use the folder if it was already extracted in Downloads, otherwise unpack the zip ourselves
  $dir = Get-ChildItem -LiteralPath $dl -Directory | Where-Object { $_.Name -eq "$($name)[Source]" } | Select-Object -First 1
  if ($dir) { return $dir.FullName }
  return (Unzip "$($name)[Source].zip" ($name -replace "[^A-Za-z]", ""))
}
function CopyFlat($from, $filter, $dest) {
  if (-not $from -or -not (Test-Path -LiteralPath $from)) { return 0 }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  $n = 0
  foreach ($f in (Get-ChildItem -LiteralPath $from -Recurse -File | Where-Object { $_.Name -like $filter })) {
    $to = Join-Path $dest $f.Name
    if (-not (Test-Path -LiteralPath $to) -or (Get-Item -LiteralPath $to).LastWriteTime -lt $f.LastWriteTime) { Copy-Item -LiteralPath $f.FullName -Destination $to -Force }
    $n++
  }
  return $n
}
Write-Host "Monsters (Bestiary [Source])"
$b = SourcePack "Bestiary - Dungeon Monsters Kit"
if ($b) {
  $glb = Get-ChildItem -LiteralPath $b -Recurse -Directory | Where-Object { $_.Name -like "GLB*" } | Select-Object -First 1
  if ($glb) { Write-Host "  $(CopyFlat $glb.FullName '*.glb' (Join-Path $lic 'monsters')) monsters" }
} else { Write-Host "  (not bought yet - the world will have no monsters)" -ForegroundColor Yellow }
Write-Host "Characters (Universal Base Characters [Source] + Modular Character Outfits - Fantasy [Source])"
$chars = Join-Path $lic "chars"
$u = SourcePack "Universal Base Characters"
if ($u) {
  $ex = Get-ChildItem -LiteralPath $u -Recurse -Directory | Where-Object { $_.Name -eq "Godot - UE" } | Select-Object -First 1
  foreach ($n in @("Regular_Male_OnlyHead", "Regular_Female_OnlyHead", "Regular_Male_FullBody", "Regular_Female_FullBody")) {
    foreach ($e in @(".gltf", ".bin")) { $f = Join-Path $ex.FullName ($n + $e); if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination $chars -Force } }
  }
  CopyFlat $ex.FullName "T_*.png" $chars | Out-Null
  $tex = Get-ChildItem -LiteralPath $u -Recurse -Directory | Where-Object { $_.Name -eq "Textures" -and $_.Parent.Name -eq "Base Characters" } | Select-Object -First 1
  if ($tex) { CopyFlat $tex.FullName "T_Regular_*Light*.png" $chars | Out-Null }
  $hair = Get-ChildItem -LiteralPath $u -Recurse -Directory | Where-Object { $_.Name -like "glTF (Godot*" -and $_.Parent.Name -eq "Rigged to Head Bone" } | Select-Object -First 1
  if ($hair) {
    foreach ($f in (Get-ChildItem -LiteralPath $hair.FullName -Recurse -File | Where-Object { $_.Name -notlike "*_Teen*" })) { Copy-Item -LiteralPath $f.FullName -Destination $chars -Force }
  }
  $hn = Get-ChildItem -LiteralPath $u -Recurse -Directory | Where-Object { $_.Name -eq "Normals Unity - Godot" } | Select-Object -First 1
  if ($hn) { CopyFlat $hn.FullName "*.png" $chars | Out-Null }
  Write-Host "  base bodies and hair ok"
} else { Write-Host "  (not bought yet)" -ForegroundColor Yellow }
$m = SourcePack "Modular Character Outfits - Fantasy"
if ($m) {
  $parts = Get-ChildItem -LiteralPath $m -Recurse -Directory | Where-Object { $_.Name -eq "Modular Parts" -and $_.Parent.Name -like "glTF*" } | Select-Object -First 1
  if ($parts) { Write-Host "  $(CopyFlat $parts.FullName '*.gltf' $chars) outfit pieces"; CopyFlat $parts.FullName "*.bin" $chars | Out-Null }
  $tex2 = Get-ChildItem -LiteralPath $m -Recurse -Directory | Where-Object { $_.Name -eq "Textures" } | Select-Object -First 1
  if ($tex2) {
    foreach ($f in (Get-ChildItem -LiteralPath $tex2.FullName -Recurse -File -Filter "*.png" | Where-Object { $_.DirectoryName -notlike "*Unreal*" -and $_.DirectoryName -notlike "*Base Chars*" })) {
      $to = Join-Path $chars $f.Name
      if (-not (Test-Path -LiteralPath $to)) { Copy-Item -LiteralPath $f.FullName -Destination $to }
    }
  }
} else { Write-Host "  (outfits not bought yet)" -ForegroundColor Yellow }

Write-Host "Importing assets (first time takes a minute or two)..."
& (Join-Path $gd "Godot_v4.7.2-stable_win64_console.exe") --headless --path (Join-Path $repo "godot") --import
Write-Host "Done. Double-click 'Play Ashvale.bat' to play." -ForegroundColor Green
