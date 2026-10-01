# Verilog Motor FSM

A Verilog implementation and simulation of a 4-state finite state
machine (FSM) for industrial motor control sequencing.

The design models a simplified PLC-style motor control sequence with
start, stop, fault detection, and fault-reset behavior.

## FSM States

  State     Encoding     Motor   Fault
  --------- ---------- ------- -------
  IDLE      `00`           OFF       0
  RUNNING   `01`            ON       0
  STOPPED   `10`           OFF       0
  FAULT     `11`           OFF       1

## State Transitions

``` text
                 start_cmd
        ┌────────────────────────┐
        │                        ▼
      IDLE ──────────────────> RUNNING
        ▲                         │
        │                         │ stop_cmd
        │                         ▼
        │                      STOPPED
        │                         │
        │                         │ start_cmd
        │                         └──────────> RUNNING
        │
        │ reset
        │
      FAULT <───────────────────────────────
        ▲
        │ fault
        │
        └──────── IDLE / RUNNING / STOPPED
```

A fault has priority over normal start/stop commands.

Once the FSM enters `FAULT`, the fault remains latched until reset.

## Inputs

  Signal        Description
  ------------- --------------------------
  `clk`         System clock
  `reset`       Synchronous reset
  `start_cmd`   Motor start command
  `stop_cmd`    Motor stop command
  `fault`       External fault condition

## Outputs

  Signal            Description
  ----------------- ----------------------------------------------
  `motor_run`       Indicates that the motor should be running
  `fault_latched`   Indicates that the FSM is in the FAULT state
  `state`           Current FSM state, exposed for verification

## Design Architecture

The FSM uses the standard three-part structure:

1.  State register
2.  Next-state combinational logic
3.  Output combinational logic

The state register updates on the rising edge of `clk`.

The next-state logic determines the next state based on the current
state and input conditions.

The output logic generates `motor_run` and `fault_latched` from the
current state.

## Verification

A dedicated Verilog testbench was developed to verify the FSM.

The testbench verifies:

-   Reset to IDLE
-   IDLE hold behavior
-   IDLE → RUNNING
-   RUNNING hold behavior
-   RUNNING → STOPPED
-   STOPPED hold behavior
-   STOPPED → RUNNING
-   RUNNING → FAULT
-   IDLE → FAULT
-   STOPPED → FAULT
-   Latched fault behavior
-   START command cannot bypass FAULT
-   FAULT → IDLE after reset
-   Motor output behavior
-   Fault output behavior

All 15 verification tests passed during simulation.

## Simulation

The design was simulated using:

-   Icarus Verilog
-   GTKWave

### Compile

``` bash
iverilog -o sim/motor_fsm_tb src/motor_fsm.v tb/motor_fsm_tb.v
```

### Run Simulation

``` bash
vvp sim/motor_fsm_tb
```

### View Waveform

``` bash
gtkwave sim/motor_fsm.vcd
```

The waveform confirms the expected state transitions, motor control
output, fault latching, and reset behavior.

## Project Structure

``` text
verilog-motor-fsm/
├── src/
│   └── motor_fsm.v
├── tb/
│   └── motor_fsm_tb.v
├── sim/
│   └── motor_fsm.vcd
├── docs/
│   └── waveform.png
└── README.md
```

## Waveform

The GTKWave simulation shows the clock, control inputs, FSM state, motor
output, and latched fault behavior.

![Motor FSM Simulation](docs/waveform.png)

## Purpose

This project demonstrates practical RTL design, finite state machine
implementation, synchronous digital logic, simulation, and
testbench-based verification using Verilog.

The control behavior is modeled on industrial motor sequencing and
PLC-style control logic.
