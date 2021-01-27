module b1_scfifo_top

#( parameter DWIDTH = 8, AWIDTH = 8, SHOWAHEAD = "ON" )

(
  input logic               clk_i, srst_i, 
  input logic               rdreq_i, wrreq_i,
  input logic  [DWIDTH-1:0] data_i,
  
  output logic              empty_o, full_o,
  output logic [DWIDTH-1:0] q_o,
  output logic [AWIDTH-1:0] usedw_o
);  

logic                srst_i_buf;
logic                rdreq_i_buf;
logic                wrreq_i_buf;
logic [DWIDTH - 1:0] data_i_buf;

logic                empty_o_buf;
logic                full_o_buf;
logic [DWIDTH - 1:0] q_o_buf;
logic [AWIDTH - 1:0] usedw_o_buf;

// port mapping
b1_scfifo #( DWIDTH, AWIDTH, SHOWAHEAD ) b1_scfifo_core_unit
(
  .clk_i   ( clk_i ),
  .srst_i  ( srst_i_buf ),
  .rdreq_i ( rdreq_i_buf ),
  .wrreq_i ( wrreq_i_buf ),
  .data_i  ( data_i_buf ),
  
  .empty_o ( empty_o_buf ),
  .full_o  ( full_o_buf ),
  .q_o     ( q_o_buf ),
  .usedw_o ( usedw_o_buf )
);

//data locking
always_ff @( posedge clk_i )
  begin
    srst_i_buf  <= srst_i;
    rdreq_i_buf <= rdreq_i;
    wrreq_i_buf <= wrreq_i;
    data_i_buf  <= data_i;
    
    empty_o     <= empty_o_buf;
    full_o      <= full_o_buf;
    q_o         <= q_o_buf;
    usedw_o     <= usedw_o_buf;
  end

endmodule
