// Intel SCFIFO analog
`timescale 1 ps / 1 ps

module b1_scfifo

#( parameter DWIDTH = 8, AWIDTH = 8, SHOWAHEAD = "OFF" )

(
  input logic               clk_i, srst_i, 
  input logic               rdreq_i, wrreq_i,
  input logic  [DWIDTH-1:0] data_i,
  
  output logic              empty_o, full_o,
  output logic [DWIDTH-1:0] q_o,
  output logic [AWIDTH-1:0] usedw_o
);  

localparam mem_vol = 2**AWIDTH;

logic [AWIDTH-1:0] wr_adr;
logic [AWIDTH-1:0] rd_adr;
logic [DWIDTH-1:0] mem [mem_vol:0];
logic [DWIDTH-1:0] q_buf;
logic              wr_ena, rd_ena, q_ena;
logic              empty_fsm, full_fsm;

// port mapping
generate
  if ( SHOWAHEAD == "ON" )
  b1_scfifo_fsm_sa #( AWIDTH ) b1_scfifo_fsm_core
(
  .clk_i   ( clk_i ),
  .srst_i  ( srst_i ),
  .rdreq_i ( rdreq_i ),
  .wrreq_i ( wrreq_i ),
  .wr_ena  ( wr_ena ),
  .rd_ena  ( rd_ena ),
  .q_ena   ( q_ena ),
    
  .empty_fsm ( empty_fsm ),
  .full_fsm  ( full_fsm ),
  .usedw_o   ( usedw_o )
);
  else
    b1_scfifo_fsm_norm #( AWIDTH ) b1_scfifo_fsm_core
(
  .clk_i   ( clk_i ),
  .srst_i  ( srst_i ),
  .rdreq_i ( rdreq_i ),
  .wrreq_i ( wrreq_i ),
  .wr_ena  ( wr_ena ),
  .rd_ena  ( rd_ena ),
  .q_ena   ( q_ena ),
    
  .empty_fsm ( empty_fsm ),
  .full_fsm  ( full_fsm ),
  .usedw_o   ( usedw_o )
);
endgenerate

generate
  if ( SHOWAHEAD == "OFF" )
    begin
      always_ff @( posedge clk_i )
        if ( srst_i ) 
          begin
            wr_adr      <= 0;
            rd_adr      <= 0;
          end
        else
          begin
            if ( ( wrreq_i ) && ( wr_ena ) ) 
              begin
                mem[wr_adr] <= data_i;
                wr_adr      <= wr_adr + 1;
              end
              
            if ( (rdreq_i) && ( rd_ena ) ) 
              begin
                q_o     <= mem[rd_adr];
                rd_adr  <= rd_adr + 1;
              end
          end

      assign full_o  = full_fsm;
      assign empty_o = empty_fsm;
      assign usedw_o = ( wr_adr >= rd_adr ) ? ( wr_adr - rd_adr ) : ( mem_vol + wr_adr - rd_adr);
    end
  else 
    begin
     always_ff @( posedge clk_i )
        if ( srst_i ) 
          begin
            wr_adr  <= 0;
            rd_adr  <= 0;
          end
        else
          begin
            if  ( ( wrreq_i ) && ( wr_ena ) )
              begin
                wr_adr      <= wr_adr + 1;
                mem[wr_adr] <= data_i;
              end

            if ( ( rdreq_i ) && ( rd_ena ) ) rd_adr <= rd_adr + 1;
            if ( !empty_fsm ) q_buf <= mem[rd_adr];
          end
  
      assign q_o     = ( ( usedw_o == 0 ) || (empty_fsm ) ) ? q_buf : mem[rd_adr];
      assign usedw_o = ( wr_adr >= rd_adr ) ? ( wr_adr - rd_adr ) : ( mem_vol + wr_adr - rd_adr);
      assign full_o  = full_fsm;
      assign empty_o = empty_fsm;

	  end

endgenerate

endmodule
