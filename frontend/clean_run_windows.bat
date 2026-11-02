@echo off

echo Cleaning npm dependencies...
rd /s /q node_modules
del /f /q package-lock.json

echo Installing npm dependencies...
pnpm install

REM tauri.conf.json bundles binaries\llama-helper as a sidecar; tauri dev fails without it
echo Building llama-helper sidecar...
pushd "%~dp0..\llama-helper"
cargo build
if errorlevel 1 (
    popd
    echo Failed to build llama-helper
    exit /b 1
)
popd
for /f "tokens=2" %%i in ('rustc -vV ^| findstr "host:"') do set "TARGET_TRIPLE=%%i"
if not exist "%~dp0src-tauri\binaries" mkdir "%~dp0src-tauri\binaries"
copy /Y "%~dp0..\target\debug\llama-helper.exe" "%~dp0src-tauri\binaries\llama-helper-%TARGET_TRIPLE%.exe" >nul

echo Building the project...
pnpm run tauri dev
