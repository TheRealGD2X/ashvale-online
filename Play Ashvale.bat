@echo off
rem Ashvale Online - the 3D game. Double-click to play.
cd /d "%~dp0"
set GODOT=%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" (
  echo Setting up the game for the first time...
  powershell -ExecutionPolicy Bypass -File "%~dp0tools\setup_godot.ps1"
)
if not exist "%~dp0godot\.godot\imported" (
  "%~dp0tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%~dp0godot" --import
)
start "" "%GODOT%" --path "%~dp0godot" %*
