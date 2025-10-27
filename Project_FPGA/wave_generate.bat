@echo off
cls
echo [INFO] Starting simulation with Icarus Verilog...
echo.

REM --- Step 1: Compile all .sv files and create the simulation executable ---
echo [STEP 1/2] Compiling the project...
iverilog -g2012 -o design.vvp tb_design.sv design.sv filter_fsm.sv handshake_fsm.sv water_level.sv pwm_generator.sv

REM Check if compilation failed
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed. Check error messages above.
    pause
    goto :eof
)

REM --- Step 2: Run the simulation ---
echo [STEP 2/2] Running the simulation...
vvp design.vvp

echo.
echo --------------------------------------------------------------------
echo [SUCCESS] Simulation completed! The 'design.vcd' file has been generated.
echo --------------------------------------------------------------------

gtkwave design.vcd

pause