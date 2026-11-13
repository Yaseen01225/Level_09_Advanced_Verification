`timescale 1ns / 1ps

//======================================================================
// PROJECT     : Verilog HDL Learning Roadmap
// DESIGN      : Parameterized Synchronous FIFO
// LEVEL       : 09 - Directed and Scoreboard Verification
// DEVELOPER   : Ghulam Yaseen Nangraj
// HDL         : Verilog-2001
// TOOL        : Vivado 2025.2.1
// DATE        : 13 November 2026
//======================================================================
//
// PROBLEM STATEMENT:
//----------------------------------------------------------------------
// Design a synchronous FIFO (First-In, First-Out) that can store data
// of a configurable width and depth.
//
// The FIFO must store incoming data in the order it is received and
// return the oldest stored data when a read is requested.
//
// It must prevent writing when full and reading when empty. It must
// also keep track of the number of stored data items and correctly
// manage its read and write pointers.
//
// The design must support FIFO depths that are not powers of two,
// such as a depth of 5.
//
// DESIGN REQUIREMENTS:
//----------------------------------------------------------------------
// 1. Use configurable parameters for data width and FIFO depth.
// 2. Use separate read and write pointers.
// 3. Generate FULL and EMPTY status flags.
// 4. Maintain an occupancy counter to track stored data items.
// 5. Support automatic pointer wraparound at the final memory address.
// 6. Use a synchronous, active-high reset.
// 7. Prevent writing when the FIFO is full.
// 8. Prevent reading when the FIFO is empty.
// 9. Support simultaneous accepted read and write operations.
// 10. Update the output data only when a read is accepted.
//
// DEFAULT CONFIGURATION:
//----------------------------------------------------------------------
// DATA_WIDTH  = 8 bits
// DEPTH       = 5 locations
// ADDR_WIDTH  = 3 bits
// COUNT_WIDTH = 4 bits
//
// DESIGN DESCRIPTION:
//----------------------------------------------------------------------
// This design implements a synchronous FIFO using an internal memory
// array, independent read and write pointers, status flags, and an
// occupancy counter.
//
// All read and write operations are controlled by the same clock.
//
// OPERATION:
//----------------------------------------------------------------------
// 1. WRITE:
//    A write is accepted when wr_en = 1 and FIFO is not full.
//
// 2. READ:
//    A read is accepted when rd_en = 1 and FIFO is not empty.
//
// 3. FULL:
//    Indicates that all FIFO memory locations contain valid data.
//
// 4. EMPTY:
//    Indicates that the FIFO contains no valid data.
//
// 5. OCCUPANCY:
//    Increases after an accepted write.
//    Decreases after an accepted read.
//    Remains unchanged after simultaneous accepted read and write.
//
// 6. POINTER WRAPAROUND:
//    Each pointer returns to address zero after reaching DEPTH-1.
//
// 7. RESET:
//    Clears the pointers, output register, and occupancy counter.
//
// IMPORTANT BEHAVIOR:
//----------------------------------------------------------------------
// - A write request while FULL is ignored.
// - A read request while EMPTY is ignored.
// - A simultaneous read and write are accepted independently according
//   to the FIFO's FULL and EMPTY status before the active clock edge.
// - When both operations are accepted, occupancy remains unchanged.
//
// VERIFICATION OBJECTIVES:
//----------------------------------------------------------------------
// 1. Verify reset and initial EMPTY condition.
// 2. Verify sequential write operations.
// 3. Verify the FULL flag at maximum occupancy.
// 4. Verify sequential read operations and data ordering.
// 5. Verify the EMPTY flag after all data is removed.
// 6. Verify occupancy counter updates.
// 7. Verify pointer wraparound for a non-power-of-two depth.
// 8. Verify simultaneous read and write operations.
//
// EXPECTED RESULT:
//----------------------------------------------------------------------
// The FIFO must preserve the order of accepted data, prevent invalid
// reads and writes, maintain correct status flags, and report the
// correct occupancy throughout its operation.
//
//======================================================================

module parameterized_sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 5,
    parameter ADDR_WIDTH = 3,
    parameter COUNT_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                     wr_en,
    input  wire [DATA_WIDTH-1:0]    data_in,

    input  wire                     rd_en,
    output reg  [DATA_WIDTH-1:0]    data_out,

    output wire                     full,
    output wire                     empty,
    output reg  [COUNT_WIDTH-1:0]   count
);

    //==================================================================
    // FIFO MEMORY
    //==================================================================

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //==================================================================
    // READ AND WRITE POINTERS
    //==================================================================

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    //==================================================================
    // STATUS FLAGS
    //==================================================================

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    //==================================================================
    // FIFO CONTROL LOGIC
    //==================================================================

    always @(posedge clk) begin

        if (rst) begin

            // Reset pointers, output and occupancy counter.
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
            data_out <= 0;

        end
        else begin

            //==========================================================
            // WRITE OPERATION
            //==========================================================

            if (wr_en && !full) begin

                mem[wr_ptr] <= data_in;

                // Wrap write pointer at the final valid memory address.
                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1'b1;

            end

            //==========================================================
            // READ OPERATION
            //==========================================================

            if (rd_en && !empty) begin

                data_out <= mem[rd_ptr];

                // Wrap read pointer at the final valid memory address.
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

            end

            //==========================================================
            // OCCUPANCY COUNTER
            //==========================================================

            case ({wr_en && !full, rd_en && !empty})

                2'b10: count <= count + 1'b1; // Write only
                2'b01: count <= count - 1'b1; // Read only
                2'b11: count <= count;        // Read and write
                2'b00: count <= count;        // No operation

            endcase

        end
    end

endmodule
