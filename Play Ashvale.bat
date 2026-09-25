@echo off
rem Ashvale Online - the 3D game. Double-click to play.
cd /d "%~dp0"
set GODOT=%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe
set NEED=0
if not exist "%GODOT%" set NEED=1
if not exist "%~dp0godot\assets\village" set NEED=1
if not exist "%~dp0godot\assets\anims\UAL1.glb" set NEED=1
if "%NEED%"=="1" (
  echo Setting up the game for the first time...
  powershell -ExecutionPolicy Bypass -File "%~dp0tools\setup_godot.ps1"
)
rem bring in any new or changed art (quick when nothing changed; a few minutes the first time)
echo Preparing the art...
"%~dp0tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%~dp0godot" --import
start "" "%GODOT%" --path "%~dp0godot" %*
