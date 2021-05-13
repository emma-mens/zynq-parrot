`include "bsg_defines.v"

`timescale 1 ns / 1 ps

	module example_axi_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	
	//--------------------------------------------------------------------------------
	// USER MODIFY -- Configure your accelerator interface by setting these parameters
	//--------------------------------------------------------------------------------
	//
	// Change these parameters to change the number of CSRs, input FIFOs and output FIFOs.
	//
	// note: we automatically create a "elements avail" CSR for the input FIFO
	//       and a "free space avail" csr for each output FIFO
	//
	// if the PS reads from the FIFO and it is empty, it will return bogus data.
	// if the PS writes to a FIFO and it is full, it will be dropped.
	//
	// reading the FIFO csrs tells you how many consecutive words you can read/write before
	// checking the csr again/

	localparam num_regs_lp = 4;         // number of user CSRs
	localparam num_fifo_in_lp = 1;      // number of input FIFOs (from PL to PS)
	localparam num_fifo_out_lp = 1;     // number of output FIFOs (from PS to PL)


	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

        // this correspond to the number of word addresses that can be read by PS
        localparam read_addr_bit_width_lp = num_fifo_out_lp+num_fifo_in_lp+num_fifo_out_lp+1; // plus 1 for no data at addr 4

        // this corresponds to the number of addresses that can be written by PS
        localparam write_addr_bit_width_lp = num_fifo_in_lp;

        wire [read_addr_bit_width_lp-1:0] slv_rd_sel_one_hot;
        wire [write_addr_bit_width_lp-1:0]  slv_wr_sel_one_hot;

        bsg_decode_with_v #(.num_out_p(read_addr_bit_width_lp)) decode_rd
          (.i(axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
           ,.v_i(slv_reg_rden)
           ,.o(slv_rd_sel_one_hot)
           );

	bsg_decode_with_v #(.num_out_p(write_addr_bit_width_lp)) decode_wr
         (.i(axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
          ,.v_i(slv_reg_wren)
          ,.o(slv_wr_sel_one_hot)
          );


	wire in_fifo_ready_lo, in_fifo_valid_lo, in_fifo_yumi_li, in_fifo_valid_li;
        wire [C_S_AXI_DATA_WIDTH-1:0] in_fifo_data_lo;
        wire [`BSG_WIDTH(4)-1:0]    in_fifo_ctrs;
        wire [C_S_AXI_DATA_WIDTH-1:0]    in_fifo_ctrs_full, in_fifo_ctrs_free;


	assign in_fifo_ctrs_full = (C_S_AXI_DATA_WIDTH) ' (in_fifo_ctrs);
	assign in_fifo_ctrs_free = 4 - in_fifo_ctrs_full;

	assign in_fifo_valid_li = in_fifo_ready_lo & slv_wr_sel_one_hot[0];

	bsg_fifo_1r1w_small #(.width_p(C_S_AXI_DATA_WIDTH), .els_p(4)) fifo_i
	  (.clk_i(S_AXI_ACLK)
	   ,.reset_i(~S_AXI_ARESETN)
	   ,.v_i(in_fifo_valid_li)
	   ,.ready_o(in_fifo_ready_lo)
	   ,.data_i(S_AXI_WDATA)

	   ,.v_o(in_fifo_valid_lo)
	   ,.data_o(in_fifo_data_lo)
	   ,.yumi_i(in_fifo_yumi_li)
	   );

	always @(negedge S_AXI_ACLK)
	  begin
	     assert(~S_AXI_ARESETN | ~slv_wr_sel_one_hot[0] | in_fifo_ready_lo)
	       else $error("write to full fifo");
	  end

        bsg_flow_counter #(.els_p(4)
 			  ,.count_free_p(1)
 			  ) bfc_i
 	 (.clk_i(S_AXI_ACLK)
 	  ,.reset_i(~S_AXI_ARESETN)
 	  ,.v_i(in_fifo_valid_li)
 	  ,.ready_i(in_fifo_ready_lo)
 	  ,.yumi_i(in_fifo_yumi_li)
 	  ,.count_o(in_fifo_ctrs)
 	  );

	logic [C_S_AXI_DATA_WIDTH-1:0] out_fifo_data_r, out_fifo_data_li;
        logic  			       out_fifo_valid_lo, out_fifo_ready_lo, out_fifo_valid_li, out_fifo_yumi_li;
        logic [`BSG_WIDTH(4)-1:0]      out_fifo_ctrs;
        logic [C_S_AXI_DATA_WIDTH-1:0] out_fifo_ctrs_full, out_fifo_ctrs_free;


	assign out_fifo_data_li = in_fifo_data_lo;
	assign out_fifo_valid_li = in_fifo_valid_lo;

	assign in_fifo_yumi_li = out_fifo_valid_li & out_fifo_ready_lo;

	assign out_fifo_ctrs_full = (C_S_AXI_DATA_WIDTH) ' (out_fifo_ctrs);
	assign out_fifo_ctrs_free = 4 - out_fifo_ctrs_full;


	assign out_fifo_yumi_li = out_fifo_valid_lo & slv_rd_sel_one_hot[4:3]; 

	bsg_fifo_1r1w_small #(.width_p(C_S_AXI_DATA_WIDTH), .els_p(4)) fifo_o
	  (.clk_i(S_AXI_ACLK)
	   ,.reset_i(~S_AXI_ARESETN)
	   ,.v_i(out_fifo_valid_li)
	   ,.ready_o(out_fifo_ready_lo)

	   ,.data_i(out_fifo_data_li)

	   ,.v_o(out_fifo_valid_lo)  
	   ,.data_o(out_fifo_data_r)
	   // only deque if it is not empty =) and there is a read request at address 12
	   ,.yumi_i(out_fifo_valid_lo & slv_rd_sel_one_hot[4:3])
	   );

        bsg_flow_counter #(.els_p(4)
 			  ,.count_free_p(0)
 			  ) bfc_o
 	 (.clk_i(S_AXI_ACLK)
 	  ,.reset_i(~S_AXI_ARESETN)
 	  ,.v_i(out_fifo_valid_li)
 	  ,.ready_i(out_fifo_ready_lo)
 	  ,.yumi_i(out_fifo_yumi_li)
 	  ,.count_o(out_fifo_ctrs)
 	  );
 
 	always @(negedge S_AXI_ACLK)
 	  begin
 	     assert(~S_AXI_ARESETN | ~slv_rd_sel_one_hot[4:3] | out_fifo_valid_lo)
 	       else $error("read from empty fifo"); // out_fifo_data_r <= -1;
 
 	  end


	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	 
     else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

	// output read by PS in the following order
	// 0: input fifo # of free spots
	// 4: in the assignment spec, this is a write port so we return bogus
	//    data for reads
	// 8: output fifo # of elements
	// C: output fifo head
	// .data_i({out_fifo_data_r, out_fifo_ctrs_full, 4'hx, in_fifo_ctrs_free})
        bsg_mux_one_hot #(.width_p(C_S_AXI_DATA_WIDTH),.els_p(read_addr_bit_width_lp)) muxoh
	  (.data_i({out_fifo_data_r, out_fifo_ctrs_full, in_fifo_ctrs_full, out_fifo_ctrs_free}) //in_fifo_ctrs_free}) 32'hx
	   ,.sel_one_hot_i(slv_rd_sel_one_hot)
	   ,.data_o(reg_data_out)
	   );

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
                if (~out_fifo_valid_lo & slv_rd_sel_one_hot[4:3])
		  begin
			axi_rdata <= -32'h1; // send -1 if output fifo is empty
		  end
		else
	          begin
	            axi_rdata <= reg_data_out;     // register read data
	          end   
	    end
	end    

	// Add user logic here

	// User logic ends

	endmodule
