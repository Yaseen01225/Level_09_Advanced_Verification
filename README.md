# Parameterized Synchronous FIFO — Level 09

A Verilog-2001 implementation of a parameterized synchronous First-In, First-Out (FIFO) memory, together with a self-checking testbench that uses an independent reference queue (scoreboard) to verify FIFO behavior.

| Project detail | Information |
|---|---|
| Project | Verilog HDL Learning Roadmap |
| Design | Parameterized Synchronous FIFO |
| Learning level | Level 09 — Directed and Scoreboard Verification |
| RTL module | `parameterized_sync_fifo` |
| Testbench | `tb_fifo_scoreboard` |
| HDL | Verilog-2001 |
| Target/simulation tool noted in source | Xilinx Vivado 2025.2.1 |
| Developer | Ghulam Yaseen Nangraj |
| Date in source | 13 November 2026 |

---

## 1. Project overview

A FIFO stores data in the order in which it arrives. The first data word written is the first data word read. FIFOs are widely used in digital systems to temporarily buffer data between blocks that produce and consume information at different times.

This project implements a **synchronous FIFO**: all state-changing operations are controlled by one clock. The design has configurable data width and depth, separate read and write pointers, `FULL` and `EMPTY` flags, and an occupancy counter.

The supplied testbench verifies the design using both directed transactions and deterministic pseudo-random read/write requests. A software-like reference queue predicts the expected FIFO contents and occupancy independently of the DUT.

## 2. Project objectives

The project is intended to help develop practical understanding of:

- FIFO memory organization and First-In, First-Out behavior.
- Parameterized RTL design in Verilog-2001.
- Read and write pointer management.
- Pointer wraparound for depths that are not powers of two.
- Full and empty detection using an occupancy counter.
- Blocking writes when full and reads when empty.
- Simultaneous read and write behavior.
- Self-checking testbench construction.
- Scoreboard/reference-model-based verification.
- Deterministic pseudo-random stimulus and PASS/FAIL reporting.

## 3. Project files

Keep the RTL and testbench in the same simulation project directory.

| File | Purpose |
|---|---|
| `design.v` | Synthesizable FIFO RTL. Defines `parameterized_sync_fifo`. |
| `testbench.v` | Simulation-only testbench. Defines `tb_fifo_scoreboard` and instantiates the FIFO. |
| `README.md` | Project description, interface reference, design behavior, and simulation instructions. |

**DUT dependency:** `testbench.v` instantiates `parameterized_sync_fifo`, so `design.v` must be included in the simulation sources.

## 4. Architecture

The FIFO contains four main elements:

1. **Memory array (`mem`)** — stores up to `DEPTH` words, each `DATA_WIDTH` bits wide.
2. **Write pointer (`wr_ptr`)** — identifies the memory location for the next accepted write.
3. **Read pointer (`rd_ptr`)** — identifies the oldest stored word to be read next.
4. **Occupancy counter (`count`)** — records how many valid words are currently stored.

The status flags are derived from the occupancy counter:

```verilog
assign full  = (count == DEPTH);
assign empty = (count == 0);
```

Conceptual data path:

```text
                 +----------------------------------+
 data_in ------->|                                  |
 wr_en --------->|       PARAMETERIZED FIFO         |
                 |                                  |
                 |   +--------------------------+   |
                 |   | Memory: DEPTH x WIDTH    |   |
                 |   +--------------------------+   |
                 |       ^                 |        |
                 |   Write pointer     Read pointer |
                 |       |                 |        |
 rd_en --------->|       Control and occupancy     |
 clk ----------->|       counter / status logic     |
 rst ----------->|                                  |
                 +------------------+---------------+
                                    |
                              data_out
                           full / empty / count
```

The diagram is conceptual; the actual implementation is the RTL in `design.v`.

## 5. Default configuration

The RTL and testbench use these default parameters:

| Parameter | Default | Description |
|---|---:|---|
| `DATA_WIDTH` | 8 | Number of bits in each stored word. |
| `DEPTH` | 5 | Number of words the FIFO can store. |
| `ADDR_WIDTH` | 3 | Width of the read and write pointers. |
| `COUNT_WIDTH` | 4 | Width of the occupancy counter. |

The default FIFO stores five 8-bit words, for a total storage capacity of 40 bits.

### Parameter sizing

Choose parameter widths so every required value is representable:

- `ADDR_WIDTH` must be at least `ceil(log2(DEPTH))`.
- `COUNT_WIDTH` must be at least `ceil(log2(DEPTH + 1))`, because the count must represent every value from zero through `DEPTH`.
- `DEPTH` must be a positive integer.
- The memory and pointer configuration must be consistent.

For example, a depth of 5 needs a 3-bit address pointer (addresses 0 through 4) and a 3-bit minimum count width (counts 0 through 5). This project's default `COUNT_WIDTH=4` provides additional range.

The RTL uses explicit comparisons against `DEPTH-1` to wrap pointers. Therefore, it supports non-power-of-two depths such as 5; it does not rely on natural binary overflow for pointer wraparound.

## 6. RTL interface reference

Module name: `parameterized_sync_fifo`

| Port | Direction | Width | Description |
|---|---|---:|---|
| `clk` | Input | 1 | FIFO clock. Operations occur on the rising edge. |
| `rst` | Input | 1 | Synchronous, active-high reset. |
| `wr_en` | Input | 1 | Requests a write. |
| `data_in` | Input | `DATA_WIDTH` | Data word presented for writing. |
| `rd_en` | Input | 1 | Requests a read. |
| `data_out` | Output | `DATA_WIDTH` | Registered data from an accepted read. |
| `full` | Output | 1 | High when occupancy equals `DEPTH`. |
| `empty` | Output | 1 | High when occupancy is zero. |
| `count` | Output | `COUNT_WIDTH` | Number of words currently stored. |

### Reset behavior

The reset is synchronous and active high. When `rst` is sampled high at a rising clock edge, the RTL clears:

- `wr_ptr`
- `rd_ptr`
- `count`
- `data_out`

The memory array itself is not cleared. This is normally acceptable for a FIFO because `count=0` marks the FIFO empty, so old memory contents are not valid FIFO data after reset. The testbench checks the empty flag and zero occupancy after reset.

### Read behavior

A read is accepted when:

```verilog
rd_en && !empty
```

On an accepted read, `data_out` is updated with the word at `mem[rd_ptr]`, and the read pointer advances. If the read pointer is at `DEPTH-1`, it wraps to zero.

A read request while empty is ignored. Since `data_out` is a register, it retains its previous value when no read is accepted.

### Write behavior

A write is accepted when:

```verilog
wr_en && !full
```

On an accepted write, `data_in` is stored at `mem[wr_ptr]`, and the write pointer advances. If the write pointer is at `DEPTH-1`, it wraps to zero.

A write request while full is ignored.

## 7. Occupancy and simultaneous operations

The occupancy counter is updated according to the operations accepted at the active clock edge.

| Accepted write | Accepted read | Occupancy action |
|---:|---:|---|
| 0 | 0 | Hold count |
| 1 | 0 | Increment count |
| 0 | 1 | Decrement count |
| 1 | 1 | Hold count |

The design determines acceptance using the `FULL` and `EMPTY` flags that exist **before** the active clock edge. Consequently:

- If the FIFO is full and both requests are asserted, the write is blocked and the read is accepted.
- If the FIFO is empty and both requests are asserted, the read is blocked and the write is accepted.
- If the FIFO is neither full nor empty and both requests are asserted, both operations are accepted and occupancy remains unchanged.

This is an important policy: a read on a full FIFO does not make a write acceptable on that same edge, and a write on an empty FIFO does not make a read acceptable on that same edge.

## 8. Testbench and scoreboard strategy

The testbench module is `tb_fifo_scoreboard`. It instantiates the DUT and maintains a separate reference memory with `head`, `tail`, and `model_count` variables.

For each transaction, the testbench predicts whether the requested read and write should be accepted using the model's pre-edge occupancy. It then compares the DUT output and occupancy with the expected values.

The scoreboard is independent of the DUT's internal memory and pointers. This helps detect errors that may not be visible by checking only the status flags.

### Verification phases

| Phase | Test activity | Main checks |
|---|---|---|
| Phase 0 | Initialize and apply reset | `empty=1` and `count=0` |
| Phase 1 | Write exactly `DEPTH` words | Occupancy after each write; `full=1` at capacity |
| Phase 2 | Read all stored words | FIFO data order; occupancy after each read; `empty=1` after draining |
| Phase 3 | Run 20 deterministic pseudo-random transactions | Accepted read data and occupancy against the scoreboard |
| Phase 4 | Print final report | PASS count, FAIL count, total checks, and overall result |

### Deterministic pseudo-random stimulus

The testbench uses a 32-bit linear-feedback shift register (LFSR) initialized with:

```verilog
seed = 32'h13579BDF;
```

The LFSR produces repeatable read requests, write requests, and input data. Using a fixed seed makes a failing sequence reproducible between simulation runs, which is useful for debugging.

### PASS/FAIL reporting

The `check_result` task increments `pass_count` or `fail_count` and prints a descriptive result. It uses case equality (`===`) so an unknown (`X`) result is not accidentally treated as a successful check.

At the end of simulation, the testbench prints the total number of checks and an overall PASS or FAIL message. A PASS means all checks implemented in this testbench succeeded; it is not a substitute for broader verification or hardware validation.

## 9. Running the simulation in Xilinx Vivado

1. Open Vivado and create a new RTL project, or open an existing project.
2. Add `design.v` as a **Design Source**.
3. Add `testbench.v` as a **Simulation Source**.
4. Confirm that both files are included in the simulation source set.
5. Set `tb_fifo_scoreboard` as the simulation top module.
6. Open **Run Simulation → Run Behavioral Simulation**.
7. Inspect the Tcl console and waveform window.
8. Review the PASS/FAIL messages and the final verification summary.

The testbench is intended for simulation. Do not select `tb_fifo_scoreboard` as the synthesis top module. The synthesizable design top is `parameterized_sync_fifo`.

### Optional command-line simulation

If Icarus Verilog is installed, the equivalent basic flow is:

```sh
iverilog -g2001 -s tb_fifo_scoreboard -o fifo_sim design.v testbench.v
vvp fifo_sim
```

Other Verilog-2001-compatible simulators can be used with their corresponding compile and run commands.

## 10. Signals worth observing in the waveform

Add these signals to the waveform viewer:

- `clk`, `rst`
- `wr_en`, `data_in`
- `rd_en`, `data_out`
- `full`, `empty`, `count`
- `dut.wr_ptr`, `dut.rd_ptr`
- Testbench model signals: `model_count`, `head`, `tail`
- Scoreboard prediction signals: `accept_write`, `accept_read`, `expected_read`

Observe the following situations:

1. Reset asserted at a rising edge.
2. Occupancy increasing from 0 to `DEPTH`.
3. `full` asserting when the final available location is filled.
4. Occupancy decreasing from `DEPTH` to 0 during reads.
5. `empty` asserting after the final stored word is read.
6. Pointer wraparound from address `DEPTH-1` to address 0.
7. Simultaneous read/write requests at intermediate occupancy.
8. Read requests while empty and write requests while full.

## 11. Important design considerations and limitations

- **Synchronous read:** `data_out` updates on the rising clock edge only when a read is accepted. This is not an asynchronous-read FIFO.
- **Reset does not clear memory:** reset clears the control state and output register, not every memory word.
- **No separate acceptance outputs:** the RTL does not expose `wr_accept` or `rd_accept` ports. Acceptance is determined internally from the request and status flag.
- **No programmable almost-full/almost-empty flags:** only `full` and `empty` are provided.
- **No independent clocks:** this is a single-clock FIFO, not an asynchronous clock-domain-crossing FIFO.
- **Memory inference is tool- and target-dependent:** the small array may map to registers or a memory resource depending on FPGA family, synthesis settings, and coding style. Review the Vivado synthesis report for the actual implementation.
- **Parameter validity matters:** use widths that can represent all addresses and occupancy values. The RTL does not include elaboration-time parameter validation.
- **Verification scope:** the supplied testbench checks reset state, directed filling/draining, read data, occupancy, and deterministic random transactions. Extend it for exhaustive corner cases, coverage, and additional parameter configurations.

## 12. Suggested extensions

After understanding and simulating the supplied project, consider these learning exercises:

1. Add explicit checks that a write request while full does not change occupancy or stored data.
2. Add explicit checks that a read request while empty does not change occupancy or `data_out`.
3. Add directed simultaneous read/write tests at empty, one-word occupancy, intermediate occupancy, and full.
4. Run the testbench with multiple legal parameter configurations, including depths 1, 3, 5, and 8.
5. Add randomized tests with a larger transaction count and configurable seed.
6. Add functional coverage counters for full, empty, pointer wraparound, and simultaneous operations.
7. Add optional `wr_accept` and `rd_accept` status outputs.
8. Explore a first-word-fall-through (FWFT) FIFO as a separate design.
9. Compare register-based FIFO implementation with block-RAM-oriented coding styles.
10. Add assertions or a formal verification harness for pointer, count, and data-order invariants.

## 13. Troubleshooting

| Symptom | Items to check |
|---|---|
| Module not found | Ensure `design.v` is included in simulation sources and the module is named `parameterized_sync_fifo`. |
| Testbench not selected | Set `tb_fifo_scoreboard` as the simulation top. |
| Unknown output data | Confirm reset was sampled on a rising edge and that a read was accepted before checking `data_out`. |
| Count mismatch | Inspect read/write acceptance, simultaneous-operation behavior, and pointer/occupancy updates. |
| Incorrect order | Inspect `wr_ptr`, `rd_ptr`, memory indexing, and wraparound logic. |
| Full/empty mismatch | Check the occupancy counter and the parameter widths. |
| Different random sequence expected | Confirm the LFSR seed and stimulus code have not changed. |

## 14. Source consistency note

The testbench header's test-configuration comment says `RANDOM_TESTS = 10`, but the executable test loop and simulation report use **20** transactions. The actual testbench therefore runs 20 pseudo-random transactions. Update the header comment to 20 if you want the source documentation to be consistent.

The testbench also displays a fixed `100 MHz` clock description. Its clock generator toggles every 5 ns, giving a 10 ns period and a 100 MHz simulation clock.

## 15. Expected result

When the design and testbench are compiled together and the testbench completes without verification errors, the final report should show:

- A nonzero PASS count.
- `FAIL` count equal to zero.
- `OVERALL RESULT : PASS`.

The exact number of checks is determined by the checks executed by the testbench. If any check fails, inspect the first failing transaction and its surrounding waveform activity before changing the RTL.

---

## License and usage

No license terms are specified in the supplied source files. Add a license notice here if you intend to distribute the project under a particular open-source or proprietary license.

## Author

**Ghulam Yaseen Nangraj**  
Verilog HDL Learning Roadmap  
HDL: Verilog-2001  
Tool noted in source: Xilinx Vivado 2025.2.1
