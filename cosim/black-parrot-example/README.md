This shows a simple example of the proposed [BSG](http://bsg.ai) methodology for accelerating BlackParrot (or other accelerators) simulation on FPGA. There is a unified interface for a control program (implemented as "host code") to interact with the hardware device; which has both Verilator and Zynq PS (== ARM core) support.

See the [other examples](https://github.com/black-parrot-hdk/zynq-parrot/tree/multiple_axi_ports/cosim) to see how the cosimulation and shell infrastructure work.


### Note:
Comment out `# $BP_TOP_DIR/src/v/bp_core_minimal.sv` in the flist.vcs file

To change the matrix width for the matmult tests, first clean the software directory, then initialize the beebs submodule within `black-parrot-sdk`. Modify the required [value](https://github.com/mageec/beebs/blob/master/src/matmult/matmult.c#L54) before building tools and beebs in the software directory or alternatively, replace that matmult file with the one generated in this directory for quicker nbf generation (pre-built arrays).
