@echo off
setlocal
REM ============================================================
REM 🚀 Flash bitstream using openFPGALoader
REM
REM This script is designed to be placed in your project's
REM *root* directory (the parent folder of 'build').
REM It will automatically find its own location.
REM ============================================================

REM --- USER CONFIGURATION ---
REM !! EDIT THIS PATH if your OSS CAD Suite is installed elsewhere.
set OSSCAD=C:\oss-cad-suite
REM ----------------------------


REM --- PROJECT CONFIGURATION ---
REM These paths are *relative* to this script's location.
set BUILD_DIR=build
set BIT_FILE=%BUILD_DIR%\impl\filtercore_impl.bit
set BOARD=colorlight-i9
REM -----------------------------


REM 1. Activate OSS CAD Suite environment
echo [INFO] Activating OSS CAD Suite environment from: %OSSCAD%
if not exist "%OSSCAD%\environment.bat" (
    echo [ERROR] OSS CAD environment.bat not found at: %OSSCAD%
    echo Please edit this .bat file and set the correct 'OSSCAD' path.
    goto :error
)
call "%OSSCAD%\environment.bat"


REM 2. Change to the script's own directory
REM %~dp0 expands to the Drive and Path of this .bat file.
echo [INFO] Changing directory to script's location...
cd /d "%~dp0"
echo [INFO] Current directory: %cd%


REM 3. Check if the 'build' directory exists (NEW CHECK)
echo [INFO] Looking for build directory: %BUILD_DIR%
if not exist "%BUILD_DIR%\" (
    echo [ERROR] '%BUILD_DIR%' directory not found in: %cd%
    echo Please run the Lattice synthesis (or build process) first to create this directory.
    goto :error
)
echo [INFO] '%BUILD_DIR%' directory found.


REM 4. Check if the bitstream file exists (inside the build dir)
echo [INFO] Looking for bitstream at: %BIT_FILE%
if not exist "%BIT_FILE%" (
    echo [ERROR] Bitstream file not found at: %cd%\%BIT_FILE%
    echo Please check the 'BIT_FILE' variable in this script or run the synthesis first.
    goto :error
)


REM 5. Execute flashing
echo [INFO] Starting flash... (Board: %BOARD%)
openFPGALoader.exe -b %BOARD% --unprotect-flash -f --verify "%BIT_FILE%"

if %ERRORLEVEL% neq 0 (
    echo [ERROR] openFPGALoader failed! (Error code: %ERRORLEVEL%)
    goto :error
)


echo ============================================================
echo ✅ Process finished successfully!
echo ============================================================
goto :endscript

:error
echo ============================================================
echo ❌ Process FAILED!
echo ============================================================
goto :endscript

:endscript
echo.
echo Press any key to exit...
pause