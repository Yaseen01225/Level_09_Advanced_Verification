==============================================================
             LEVEL 9 : FIFO SCOREBOARD TEST
==============================================================
 Project       : Verilog HDL Learning Roadmap
 Testbench     : tb_fifo_scoreboard
 Developer     : Ghulam Yaseen Nangraj
 HDL           : Verilog-2001
 Simulator     : Vivado 2025.2.1
--------------------------------------------------------------
 TEST CONFIGURATION
--------------------------------------------------------------
 Data Width    : 8 bits
 FIFO Depth    : 5 locations
 Address Width : 3 bits
 Count Width   : 4 bits
 Clock         : 100 MHz
 Random Tests  : 20
==============================================================
 [PASS] FIFO reset and initial empty condition

--------------------------------------------------------------
 PHASE 1 : DIRECTED FIFO FILL
--------------------------------------------------------------
 [PASS] Directed FIFO fill occupancy
 [PASS] Directed FIFO fill occupancy
 [PASS] Directed FIFO fill occupancy
 [PASS] Directed FIFO fill occupancy
 [PASS] Directed FIFO fill occupancy
 [PASS] FIFO FULL flag and maximum occupancy

--------------------------------------------------------------
 PHASE 2 : DIRECTED FIFO DRAIN
--------------------------------------------------------------
 [PASS] Directed FIFO read data comparison
 [PASS] Directed FIFO drain occupancy
 [PASS] Directed FIFO read data comparison
 [PASS] Directed FIFO drain occupancy
 [PASS] Directed FIFO read data comparison
 [PASS] Directed FIFO drain occupancy
 [PASS] Directed FIFO read data comparison
 [PASS] Directed FIFO drain occupancy
 [PASS] Directed FIFO read data comparison
 [PASS] Directed FIFO drain occupancy
 [PASS] FIFO EMPTY flag and zero occupancy

--------------------------------------------------------------
 PHASE 3 : PSEUDO-RANDOM SCOREBOARD TEST
--------------------------------------------------------------
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison
 [PASS] Randomized FIFO read data comparison
 [PASS] Randomized FIFO occupancy comparison


==============================================================
                 FIFO VERIFICATION SUMMARY
==============================================================
 Project       : Verilog HDL Learning Roadmap
 Testbench     : tb_fifo_scoreboard
 Verification  : Level 09 - FIFO Scoreboard
 Developer     : Ghulam Yaseen Nangraj
 Simulator     : Vivado 2025.2.1
--------------------------------------------------------------
 FIFO CONFIGURATION
--------------------------------------------------------------
 Data Width    : 8 bits
 FIFO Depth    : 5 locations
 Address Width : 3 bits
 Count Width   : 4 bits
 Random Tests  : 20
--------------------------------------------------------------
 VERIFICATION RESULTS
--------------------------------------------------------------
 Total PASS    : 48
 Total FAIL    : 0
 Total Checks  : 48
--------------------------------------------------------------

       +--------------------------------------+
       |       OVERALL RESULT : PASS          |
       +--------------------------------------+

       ALL VERIFICATION CHECKS PASSED

==============================================================
                  END OF SIMULATION
==============================================================