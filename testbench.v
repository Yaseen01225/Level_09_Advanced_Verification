
`timescale 1ns / 1ps

//======================================================================
// PROJECT     : Verilog HDL Learning Roadmap
// TESTBENCH   : tb_fifo_scoreboard
// LEVEL       : 09 - FIFO Scoreboard Verification
// DEVELOPER   : Ghulam Yaseen Nangraj
// HDL         : Verilog-2001
// SIMULATOR   : Vivado 2025.2.1
// DATE        : 13 November 2026
//======================================================================
// FIFO Scoreboard Verification is a testing method used to check whether 
// a FIFO (First-In, First-Out) design works correctly by comparing its 
// actual behavior with an independent reference model.
//======================================================================
//
// PROBLEM STATEMENT:
//----------------------------------------------------------------------
// Develop a testbench to verify a parameterized synchronous FIFO.
//
// The testbench must check that data is stored and read in the correct
// order. It must also verify the FIFO's FULL and EMPTY flags and make
// sure that its occupancy counter always shows the correct number of
// stored data items.
//
// An independent reference queue (scoreboard) will be used to compare
// the expected data with the actual FIFO output.
//
// VERIFICATION REQUIREMENTS:
//----------------------------------------------------------------------
// 1. Apply reset and verify the initial EMPTY condition.
// 2. Write data into the FIFO until it becomes FULL.
// 3. Verify the FULL flag and maximum occupancy.
// 4. Read all stored data and check the correct data order.
// 5. Verify the EMPTY flag after draining the FIFO.
// 6. Generate deterministic pseudo-random read/write requests.
// 7. Check accepted simultaneous read and write operations.
// 8. Verify that writes are blocked when FULL.
// 9. Verify that reads are blocked when EMPTY.
// 10. Compare FIFO occupancy after every transaction.
// 11. Report each verification result as PASS or FAIL.
// 12. Display a final verification summary.
//
// VERIFICATION METHOD:
//----------------------------------------------------------------------
// A reference queue acts as an independent model of the FIFO.
//
// Before each active clock edge, the testbench predicts which read and
// write operations will be accepted.
//
// After the clock edge, it:
//   - Compares accepted read data with the expected queue data.
//   - Updates the reference queue.
//   - Calculates the expected occupancy.
//   - Compares expected occupancy with the DUT occupancy.
//
// A fixed LFSR seed ensures repeatable random test sequences.
//
// TEST CONFIGURATION:
//----------------------------------------------------------------------
// DATA_WIDTH   = 8 bits
// DEPTH        = 5 locations
// ADDR_WIDTH   = 3 bits
// COUNT_WIDTH  = 4 bits
// CLOCK        = 100 MHz
// RANDOM_TESTS = 10 transactions
//
// DUT DEPENDENCY:
//----------------------------------------------------------------------
// parameterized_sync_fifo.v
//
// EXPECTED RESULT:
//----------------------------------------------------------------------
// All accepted reads must return the correct data in FIFO order.
// The FULL and EMPTY flags must operate correctly, and the occupancy
// counter must match the reference model.
//
// The test passes when all verification checks succeed.
//
//======================================================================


module tb_fifo_scoreboard;

    //==================================================================
    // 1. TEST PARAMETERS
    //==================================================================

    parameter DATA_WIDTH  = 8;
    parameter DEPTH       = 5;
    parameter ADDR_WIDTH  = 3;
    parameter COUNT_WIDTH = 4;


    //==================================================================
    // 2. TESTBENCH SIGNALS
    //==================================================================

    // Clock and reset.
    reg clk = 0;
    reg rst = 1;

    // FIFO control inputs.
    reg wr_en = 0;
    reg rd_en = 0;

    // FIFO input data.
    reg [DATA_WIDTH-1:0] data_in = 0;

    // FIFO output and status signals.
    wire [DATA_WIDTH-1:0] data_out;
    wire full;
    wire empty;

    // FIFO occupancy.
    wire [COUNT_WIDTH-1:0] count;


    //==================================================================
    // 3. DEVICE UNDER TEST (DUT)
    //==================================================================

    parameterized_sync_fifo #(
        .DATA_WIDTH  (DATA_WIDTH),
        .DEPTH       (DEPTH),
        .ADDR_WIDTH  (ADDR_WIDTH),
        .COUNT_WIDTH (COUNT_WIDTH)
    ) dut (
        .clk      (clk),
        .rst      (rst),

        .wr_en    (wr_en),
        .data_in  (data_in),

        .rd_en    (rd_en),
        .data_out (data_out),

        .full     (full),
        .empty    (empty),
        .count    (count)
    );


    //==================================================================
    // 4. CLOCK GENERATION
    //==================================================================

    // Toggle clock every 5 ns.
    // Clock period = 10 ns.
    // Clock frequency = 100 MHz.

    always #5 clk = ~clk;


    //==================================================================
    // 5. REFERENCE QUEUE (SCOREBOARD)
    //==================================================================

    // Independent memory used to predict the expected FIFO sequence.

    reg [DATA_WIDTH-1:0] expected [0:DEPTH-1];

    // Reference queue pointers.
    integer head;
    integer tail;

    // Expected number of occupied FIFO locations.
    integer model_count;


    //==================================================================
    // 6. RANDOM GENERATOR AND CONTROL VARIABLES
    //==================================================================

    integer i;

    // LFSR seed for deterministic pseudo-random generation.
    reg [31:0] seed;

    // Requested operations.
    reg do_write;
    reg do_read;

    // Predicted accepted operations.
    reg accept_write;
    reg accept_read;

    // Generated input data.
    reg [DATA_WIDTH-1:0] next_data;

    // Expected read data.
    reg [DATA_WIDTH-1:0] expected_read;


    //==================================================================
    // 7. VERIFICATION RESULT COUNTERS
    //==================================================================

    integer pass_count;
    integer fail_count;


    //==================================================================
    // 8. PASS/FAIL REPORTING TASK
    //==================================================================

    // This task records and displays every verification result.
    //
    // condition = 1 : PASS
    // condition = 0 : FAIL
    //
    // Case equality ensures unknown conditions are also reported
    // as failures rather than being silently ignored.

    task check_result;

        input condition;
        input [8*64-1:0] description;

        begin

            if (condition === 1'b1) begin

                pass_count = pass_count + 1;

                $display(
                    " [PASS] %0s",
                    description
                );

            end
            else begin

                fail_count = fail_count + 1;

                $display(
                    " [FAIL] %0s",
                    description
                );

            end

        end

    endtask


    //==================================================================
    // 9. MAIN TEST SEQUENCE
    //==================================================================

    initial begin

        //==============================================================
        // PHASE 0: INITIALIZATION AND RESET
        //==============================================================

        // Initialize reference queue pointers and occupancy.
        head        = 0;
        tail        = 0;
        model_count = 0;

        // Initialize LFSR.
        seed = 32'h13579BDF;

        // Initialize verification counters.
        pass_count = 0;
        fail_count = 0;

        // Display testbench information.
        $display("");
        $display("==============================================================");
        $display("             LEVEL 9 : FIFO SCOREBOARD TEST");
        $display("==============================================================");

        $display(" Project       : Verilog HDL Learning Roadmap");
        $display(" Testbench     : tb_fifo_scoreboard");
        $display(" Developer     : Ghulam Yaseen Nangraj");
        $display(" HDL           : Verilog-2001");
        $display(" Simulator     : Vivado 2025.2.1");

        $display("--------------------------------------------------------------");
        $display(" TEST CONFIGURATION");
        $display("--------------------------------------------------------------");

        $display(" Data Width    : %0d bits", DATA_WIDTH);
        $display(" FIFO Depth    : %0d locations", DEPTH);
        $display(" Address Width : %0d bits", ADDR_WIDTH);
        $display(" Count Width   : %0d bits", COUNT_WIDTH);
        $display(" Clock         : 100 MHz");
        $display(" Random Tests  : 20");

        $display("==============================================================");

        // Wait for reset to be sampled by the clock.
        @(posedge clk);

        #1;

        // Verify reset condition.
        check_result(
            (empty === 1'b1) && (count === 0),
            "FIFO reset and initial empty condition"
        );

        // Release synchronous reset on a falling edge.
        @(negedge clk);

        rst = 0;


        //==============================================================
        // PHASE 1: DIRECTED FIFO FILL
        //==============================================================

        $display("");
        $display("--------------------------------------------------------------");
        $display(" PHASE 1 : DIRECTED FIFO FILL");
        $display("--------------------------------------------------------------");

        // Write exactly DEPTH data words into the FIFO.
        for (i = 0; i < DEPTH; i = i + 1) begin

            // Apply write stimulus on the falling edge.
            @(negedge clk);

            wr_en   = 1;
            rd_en   = 0;
            data_in = i + 8'h20;

            // Wait for the write operation.
            @(posedge clk);

            // Update reference queue.
            expected[tail] = data_in;

            // Advance reference write pointer.
            tail = (tail + 1) % DEPTH;

            // Increase expected occupancy.
            model_count = model_count + 1;

            // Allow DUT nonblocking assignments to complete.
            #1;

            // Compare DUT occupancy against expected occupancy.
            check_result(
                count === model_count,
                "Directed FIFO fill occupancy"
            );

        end

        // Disable write requests.
        @(negedge clk);

        wr_en = 0;

        // Verify full condition.
        check_result(
            (full === 1'b1) && (count === DEPTH),
            "FIFO FULL flag and maximum occupancy"
        );


        //==============================================================
        // PHASE 2: DIRECTED FIFO DRAIN
        //==============================================================

        $display("");
        $display("--------------------------------------------------------------");
        $display(" PHASE 2 : DIRECTED FIFO DRAIN");
        $display("--------------------------------------------------------------");

        // Read exactly DEPTH data words from the FIFO.
        for (i = 0; i < DEPTH; i = i + 1) begin

            // Apply read request on the falling edge.
            @(negedge clk);

            rd_en = 1;

            // Obtain expected data before the read operation.
            expected_read = expected[head];

            // Wait for the active clock edge.
            @(posedge clk);

            // Allow output register to update.
            #1;

            // Compare actual FIFO output with expected data.
            check_result(
                data_out === expected_read,
                "Directed FIFO read data comparison"
            );

            // Advance reference read pointer.
            head = (head + 1) % DEPTH;

            // Decrease expected occupancy.
            model_count = model_count - 1;

            // Verify occupancy after every read.
            check_result(
                count === model_count,
                "Directed FIFO drain occupancy"
            );

        end

        // Disable read requests.
        @(negedge clk);

        rd_en = 0;

        // Verify empty condition.
        check_result(
            (empty === 1'b1) && (count === 0),
            "FIFO EMPTY flag and zero occupancy"
        );


        //==============================================================
        // PHASE 3: DETERMINISTIC PSEUDO-RANDOM TEST
        //==============================================================

        $display("");
        $display("--------------------------------------------------------------");
        $display(" PHASE 3 : PSEUDO-RANDOM SCOREBOARD TEST");
        $display("--------------------------------------------------------------");

        // Perform 20 pseudo-random transactions.
        for (i = 0; i < 20; i = i + 1) begin

            // Apply stimulus on the falling edge.
            @(negedge clk);


            //----------------------------------------------------------
            // 3.1 GENERATE NEXT LFSR VALUE
            //----------------------------------------------------------

            // Shift the LFSR and calculate XOR feedback.
            //
            // A fixed initial seed makes the sequence repeatable.

            seed = {
                seed[30:0],
                seed[31] ^ seed[21] ^ seed[1] ^ seed[0]
            };

            // Generate read and write requests.
            do_write = seed[0];
            do_read  = seed[3];

            // Generate input data.
            next_data = seed[15:8];

            // Apply generated signals to the DUT.
            wr_en   = do_write;
            rd_en   = do_read;
            data_in = next_data;


            //----------------------------------------------------------
            // 3.2 PREDICT ACCEPTED OPERATIONS
            //----------------------------------------------------------

            // A write is accepted only if FIFO is not full.
            // Use occupancy before the active clock edge.

            accept_write = do_write && (model_count < DEPTH);

            // A read is accepted only if FIFO is not empty.
            // Use occupancy before the active clock edge.

            accept_read = do_read && (model_count > 0);

            // Save expected data before updating the reference queue.
            if (accept_read)
                expected_read = expected[head];


            //----------------------------------------------------------
            // 3.3 WAIT FOR ACTIVE CLOCK EDGE
            //----------------------------------------------------------

            @(posedge clk);

            // Allow DUT nonblocking assignments to complete.
            #1;


            //----------------------------------------------------------
            // 3.4 VERIFY READ DATA
            //----------------------------------------------------------

            // Compare output only when a read was accepted.

            if (accept_read) begin

                check_result(
                    data_out === expected_read,
                    "Randomized FIFO read data comparison"
                );

            end


            //----------------------------------------------------------
            // 3.5 UPDATE REFERENCE QUEUE: READ
            //----------------------------------------------------------

            // Apply accepted read first.
            //
            // This advances the reference read pointer and decreases
            // the expected occupancy.

            if (accept_read) begin

                head = (head + 1) % DEPTH;

                model_count = model_count - 1;

            end


            //----------------------------------------------------------
            // 3.6 UPDATE REFERENCE QUEUE: WRITE
            //----------------------------------------------------------

            // Apply accepted write.
            //
            // This stores the new data, advances the write pointer
            // and increases expected occupancy.

            if (accept_write) begin

                expected[tail] = next_data;

                tail = (tail + 1) % DEPTH;

                model_count = model_count + 1;

            end


            //----------------------------------------------------------
            // 3.7 VERIFY RANDOMIZED OCCUPANCY
            //----------------------------------------------------------

            // Compare DUT occupancy with the reference model.

            check_result(
                count === model_count,
                "Randomized FIFO occupancy comparison"
            );

        end


        //==============================================================
        // PHASE 4: FINAL VERIFICATION REPORT
        //==============================================================

        // Disable further FIFO operations.
        @(negedge clk);

        wr_en = 0;
        rd_en = 0;

        $display("");
        $display("");
        $display("==============================================================");
        $display("                 FIFO VERIFICATION SUMMARY");
        $display("==============================================================");

        $display(" Project       : Verilog HDL Learning Roadmap");
        $display(" Testbench     : tb_fifo_scoreboard");
        $display(" Verification  : Level 09 - FIFO Scoreboard");
        $display(" Developer     : Ghulam Yaseen Nangraj");
        $display(" Date          : 13 November 2026");
        $display(" Simulator     : Vivado 2025.2.1");

        $display("--------------------------------------------------------------");
        $display(" FIFO CONFIGURATION");
        $display("--------------------------------------------------------------");

        $display(" Data Width    : %0d bits", DATA_WIDTH);
        $display(" FIFO Depth    : %0d locations", DEPTH);
        $display(" Address Width : %0d bits", ADDR_WIDTH);
        $display(" Count Width   : %0d bits", COUNT_WIDTH);
        $display(" Random Tests  : 20");

        $display("--------------------------------------------------------------");
        $display(" VERIFICATION RESULTS");
        $display("--------------------------------------------------------------");

        $display(" Total PASS    : %0d", pass_count);
        $display(" Total FAIL    : %0d", fail_count);
        $display(" Total Checks  : %0d", pass_count + fail_count);

        $display("--------------------------------------------------------------");

        // Display overall test result.
        if (fail_count == 0) begin

            $display("");
            $display("       +--------------------------------------+");
            $display("       |       OVERALL RESULT : PASS          |");
            $display("       +--------------------------------------+");
            $display("");
            $display("       ALL VERIFICATION CHECKS PASSED");

        end
        else begin

            $display("");
            $display("       +--------------------------------------+");
            $display("       |       OVERALL RESULT : FAIL          |");
            $display("       +--------------------------------------+");
            $display("");
            $display("       VERIFICATION ERRORS DETECTED");

        end

        $display("");
        $display("==============================================================");
        $display("                  END OF SIMULATION");
        $display("==============================================================");

        // Terminate simulation after displaying the summary.
        $finish;

    end

endmodule
