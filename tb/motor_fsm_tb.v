`timescale 1ns/1ps

module motor_fsm_tb;

    // Testbench signals

    reg clk;
    reg reset;
    reg start_cmd;
    reg stop_cmd;
    reg fault;

    wire motor_run;
    wire fault_latched;
    wire [1:0] state;

    // State encoding
    // Must match the DUT

    localparam IDLE    = 2'b00;
    localparam RUNNING = 2'b01;
    localparam STOPPED = 2'b10;
    localparam FAULT   = 2'b11;

    // Error counter

    integer errors;

    // Device Under Test (DUT)

    motor_fsm dut (
        .clk(clk),
        .reset(reset),
        .start_cmd(start_cmd),
        .stop_cmd(stop_cmd),
        .fault(fault),
        .motor_run(motor_run),
        .fault_latched(fault_latched),
        .state(state)
    );


    // Clock generation
    // 10 ns clock period

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // Main test sequence

    initial begin

        // Initial values
        reset     = 1'b0;
        start_cmd = 1'b0;
        stop_cmd  = 1'b0;
        fault     = 1'b0;
        errors    = 0;


        // Waveform generationx

        $dumpfile("sim/motor_fsm.vcd");
        $dumpvars(0, motor_fsm_tb);

        // ========================================================
        // TEST 1
        // Reset -> IDLE
        // ========================================================

        $display("");
        $display("TEST 1: Reset -> IDLE");

        reset = 1'b1;

        wait_and_check(
            IDLE,
            1'b0,
            1'b0
        );

        reset = 1'b0;

        // ========================================================
        // TEST 2
        // IDLE remains IDLE when no command is given
        // ========================================================

        $display("TEST 2: IDLE -> IDLE");

        wait_and_check(
            IDLE,
            1'b0,
            1'b0
        );

        // ========================================================
        // TEST 3
        // IDLE -> RUNNING
        // ========================================================

        $display("TEST 3: IDLE -> RUNNING");

        start_cmd = 1'b1;

        wait_and_check(
            RUNNING,
            1'b1,
            1'b0
        );

        start_cmd = 1'b0;

        // ========================================================
        // TEST 4
        // RUNNING remains RUNNING
        // ========================================================

        $display("TEST 4: RUNNING -> RUNNING");

        wait_and_check(
            RUNNING,
            1'b1,
            1'b0
        );

        // ========================================================
        // TEST 5
        // RUNNING -> STOPPED
        // ========================================================

        $display("TEST 5: RUNNING -> STOPPED");

        stop_cmd = 1'b1;

        wait_and_check(
            STOPPED,
            1'b0,
            1'b0
        );

        stop_cmd = 1'b0;


        // ========================================================
        // TEST 6
        // STOPPED remains STOPPED
        // ========================================================

        $display("TEST 6: STOPPED -> STOPPED");

        wait_and_check(
            STOPPED,
            1'b0,
            1'b0
        );


        // ========================================================
        // TEST 7
        // STOPPED -> RUNNING
        // ========================================================

        $display("TEST 7: STOPPED -> RUNNING");

        start_cmd = 1'b1;

        wait_and_check(
            RUNNING,
            1'b1,
            1'b0
        );

        start_cmd = 1'b0;


        // ========================================================
        // TEST 8
        // RUNNING -> FAULT
        // ========================================================

        $display("TEST 8: RUNNING -> FAULT");

        fault = 1'b1;

        wait_and_check(
            FAULT,
            1'b0,
            1'b1
        );


        // ========================================================
        // TEST 9
        // FAULT remains latched even after fault signal clears
        // ========================================================

        $display("TEST 9: FAULT remains latched");

        fault = 1'b0;

        wait_and_check(
            FAULT,
            1'b0,
            1'b1
        );

        // ========================================================
        // TEST 10
        // START command cannot bypass FAULT state
        // ========================================================

        $display("TEST 10: START cannot bypass FAULT");

        start_cmd = 1'b1;

        wait_and_check(
            FAULT,
            1'b0,
            1'b1
        );

        start_cmd = 1'b0;


        // ========================================================
        // TEST 11
        // FAULT -> IDLE after reset
        // ========================================================

        $display("TEST 11: FAULT -> IDLE after reset");

        reset = 1'b1;

        wait_and_check(
            IDLE,
            1'b0,
            1'b0
        );

        reset = 1'b0;


        // ========================================================
        // TEST 12
        // IDLE -> FAULT directly
        // ========================================================

        $display("TEST 12: IDLE -> FAULT");

        fault = 1'b1;

        wait_and_check(
            FAULT,
            1'b0,
            1'b1
        );


        // Clear external fault
        fault = 1'b0;


        // ========================================================
        // TEST 13
        // Reset clears the latched fault
        // ========================================================

        $display("TEST 13: Reset clears latched fault");

        reset = 1'b1;

        wait_and_check(
            IDLE,
            1'b0,
            1'b0
        );

        reset = 1'b0;

        // ========================================================
        // TEST 14
        // STOPPED -> FAULT
        // ========================================================

        $display("TEST 14: STOPPED -> FAULT");

        // First move to RUNNING
        start_cmd = 1'b1;

        wait_and_check(
            RUNNING,
            1'b1,
            1'b0
        );

        start_cmd = 1'b0;

        // Then move to STOPPED
        stop_cmd = 1'b1;

        wait_and_check(
            STOPPED,
            1'b0,
            1'b0
        );

        stop_cmd = 1'b0;

        // Now trigger fault
        fault = 1'b1;

        wait_and_check(
            FAULT,
            1'b0,
            1'b1
        );


        // Clear external fault
        fault = 1'b0;


        // ========================================================
        // TEST 15
        // Final reset
        // ========================================================

        $display("TEST 15: Final reset -> IDLE");

        reset = 1'b1;

        wait_and_check(
            IDLE,
            1'b0,
            1'b0
        );

        reset = 1'b0;


        // ========================================================
        // Test summary
        // ========================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end
        else begin
            $display("TESTS FAILED: %0d errors", errors);
        end

        $display("========================================");
        $display("");

        $finish;

    end


    // ============================================================
    // Wait for clock edge and check outputs
    // ============================================================

    task wait_and_check;

        input [1:0] expected_state;
        input expected_motor_run;
        input expected_fault_latched;

        begin

            // Wait for the next rising edge
            @(posedge clk);

            // Give non-blocking assignments time to update
            #1;

            check_state(
                expected_state,
                expected_motor_run,
                expected_fault_latched
            );

        end

    endtask


    // ============================================================
    // State and output checker
    // ============================================================

    task check_state;

        input [1:0] expected_state;
        input expected_motor_run;
        input expected_fault_latched;

        begin

            // Check FSM state
            if (state !== expected_state) begin

                $display(
                    "ERROR at time %0t: Expected state %b, got %b",
                    $time,
                    expected_state,
                    state
                );

                errors = errors + 1;

            end


            // Check motor output
            if (motor_run !== expected_motor_run) begin

                $display(
                    "ERROR at time %0t: Expected motor_run=%b, got %b",
                    $time,
                    expected_motor_run,
                    motor_run
                );

                errors = errors + 1;

            end


            // Check fault latch
            if (fault_latched !== expected_fault_latched) begin

                $display(
                    "ERROR at time %0t: Expected fault_latched=%b, got %b",
                    $time,
                    expected_fault_latched,
                    fault_latched
                );

                errors = errors + 1;

            end


            // Print successful check
            if (
                (state === expected_state) &&
                (motor_run === expected_motor_run) &&
                (fault_latched === expected_fault_latched)
            ) begin

                $display(
                    "  PASS: state=%b, motor_run=%b, fault_latched=%b",
                    state,
                    motor_run,
                    fault_latched
                );

            end

        end

    endtask

endmodule