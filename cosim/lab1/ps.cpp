//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.


#include <stdlib.h>
#include <stdio.h>
#include "bp_zynq_pl.h"

int main(int argc, char **argv) {
        bp_zynq_pl *zpl = new bp_zynq_pl(argc, argv);

	// this program just communicates with a "loopback accelerator"
	// that has 4 control registers that you can read and write
	
	int val1 = 0xDEADBEEF;
	int val2 = 0xCAFEBABE;
	int mask1 = 0xf;
	int mask2 = 0xf;
	

	// Testig for Lab 1
	
	// Start with an input fifo of size 4 that's empty
	assert( zpl->axil_read(0x0 + ADDR_BASE) == 4);
	
	// Write to input fifo
	zpl->axil_write(0x4 + ADDR_BASE, val1, mask1);
	// Input fifo size decrements by 1
	assert( zpl->axil_read(0x0 + ADDR_BASE) == 3);

	// Another write to input fifo
	zpl->axil_write(0x4 + ADDR_BASE, val2, mask2);
	// Size decrements by one again
	assert( zpl->axil_read(0x0 + ADDR_BASE) == 2);

	// Check that output fifo has the two items we sent to PL
	assert( zpl->axil_read(0x8 + ADDR_BASE) == 2);
	// Read item from output fifo
	assert( (zpl->axil_read(0xC + ADDR_BASE) == (val1)));
	// output fifo has only one item left
	assert( zpl->axil_read(0x8 + ADDR_BASE) == 1);
	// input fifo size up to 3
	assert( zpl->axil_read(0x0 + ADDR_BASE) == 3);

	// Read again from output fifo
	assert( (zpl->axil_read(0xC + ADDR_BASE) == (val2)));
	// output fifo is empty
        assert( zpl->axil_read(0x8 + ADDR_BASE) == 0);
	// input fifo is empty
	assert( zpl->axil_read(0x0 + ADDR_BASE) == 4);

	assert( (zpl->axil_read(0xC + ADDR_BASE) == (-1)));
	// assert( (zpl->axil_read(0x0 + ADDR_BASE) == (val1)));
	// assert( (zpl->axil_read(0x4 + ADDR_BASE) == (val2)));
	
	zpl->done();

	delete zpl;
	exit(EXIT_SUCCESS);
}

