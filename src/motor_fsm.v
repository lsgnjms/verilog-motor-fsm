module motor_fsm (
    input wire clk,
    input wire reset,
    input wire start_cmd,
    input wire stop_cmd,
    input wire fault,

    output reg motor_run,
    output reg fault_latched,
    output wire [1:0] state
);

    // State encoding
    localparam IDLE    = 2'b00;
    localparam RUNNING = 2'b01;
    localparam STOPPED = 2'b10;
    localparam FAULT   = 2'b11;

    // State registers
    reg [1:0] current_state;
    reg [1:0] next_state;

    // Expose current state
    assign state = current_state;


    // ============================================================
    // State Register
    // ============================================================

    always @(posedge clk) begin

        if (reset) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end

    end


    // ============================================================
    // Next-State Logic
    // ============================================================

    always @(*) begin

        case (current_state)

            IDLE: begin

                if (fault) begin
                    next_state = FAULT;
                end
                else if (start_cmd) begin
                    next_state = RUNNING;
                end
                else begin
                    next_state = IDLE;
                end

            end


            RUNNING: begin

                if (fault) begin
                    next_state = FAULT;
                end
                else if (stop_cmd) begin
                    next_state = STOPPED;
                end
                else begin
                    next_state = RUNNING;
                end

            end


            STOPPED: begin

                if (fault) begin
                    next_state = FAULT;
                end
                else if (start_cmd) begin
                    next_state = RUNNING;
                end
                else begin
                    next_state = STOPPED;
                end

            end


            FAULT: begin

                if (reset) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = FAULT;
                end

            end


            default: begin
                next_state = IDLE;
            end

        endcase

    end


    // ============================================================
    // Output Logic
    // ============================================================

    always @(*) begin

        // Default outputs
        motor_run = 1'b0;
        fault_latched = 1'b0;

        case (current_state)

            IDLE: begin
                motor_run = 1'b0;
                fault_latched = 1'b0;
            end


            RUNNING: begin
                motor_run = 1'b1;
                fault_latched = 1'b0;
            end


            STOPPED: begin
                motor_run = 1'b0;
                fault_latched = 1'b0;
            end


            FAULT: begin
                motor_run = 1'b0;
                fault_latched = 1'b1;
            end


            default: begin
                motor_run = 1'b0;
                fault_latched = 1'b0;
            end

        endcase

    end

endmodule