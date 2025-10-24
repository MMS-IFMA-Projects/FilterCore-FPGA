# FilterCore FPGA
- FPGA Module: ECP5 LFE5U-45 colorlight i9
- Language: System Verilog
------------------------------------------------------------
This module implements the control logic for the filtration system,
based on digital data from analog measurement sensors.

# Features:
- Automatic activation of the filtration system.
- Manual activation of the filtration system.

# Implementation Steps:
1. Clock Synchronization:
    - Maintains a common clock for Raspberry Pi Pico W and the FPGA.
2. Automatic Filtration System Activation:
    - Detection of analog sensor states.
    - Definition of criticality for pump A activation.
    - Activation of WATER FILTRATION.
3. Water Filtration:
    - Criticality check for pump A activation.
    - Activation of pump A at maximum power via PWM (filter A).
    - Detection of water level sensor state (filter B).
    - Activation of pump B at minimum power via PWM.
4. Manual Filtration System Activation:
    - Check state of button A.
    - Check current filtration state.
    - Activate/deactivate WATER FILTRATION.
