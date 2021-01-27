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
logic [AWIDTH-1:0] mem_counter;
logic [DWIDTH-1:0] mem [mem_vol:0];
logic [DWIDTH-1:0] q_buf;
logic              inc_flag, dec_flag;

generate
  if ( SHOWAHEAD == "OFF" )
    begin
      always_ff @( posedge clk_i )
        if ( srst_i ) 
          begin
            wr_adr      <= 0;
            rd_adr      <= 0;
            mem_counter <= 0;
          end
        else
          begin
            if ( ( wrreq_i ) && ( !full_o ) )  wr_adr <= wr_adr + 1;
            if ( (rdreq_i)   && ( !empty_o ) ) rd_adr <= rd_adr + 1;

            if ( inc_flag ) mem_counter <= mem_counter + 1;
            if ( dec_flag ) mem_counter <= mem_counter - 1;

            if ( ( wrreq_i ) && ( !full_o ) )  mem[wr_adr] <= data_i;
            if ( ( rdreq_i ) && ( !empty_o ) ) q_o         <= mem[rd_adr];
 
          end

      assign empty_o  = ( mem_counter == 0 );
      assign full_o   = ( mem_counter == ( mem_vol - 1 ) );
      assign usedw_o  = ( empty_o ) ? 0 : mem_counter;
      assign inc_flag = ( wrreq_i && ( !full_o ) )  && ( ( !rdreq_i ) || ( rdreq_i && empty_o ) );
      assign dec_flag = ( rdreq_i && ( !empty_o ) ) && ( ( !wrreq_i ) || ( wrreq_i && full_o  ) );

    end
  else 
    begin
      always_ff @( posedge clk_i )
        if ( srst_i ) 
          begin
            wr_adr  <= 0;
            rd_adr  <= 0;
            empty_o <= 1;
          end
        else
          begin
            if  ( wrreq_i ) 
              begin
                wr_adr      <= wr_adr + 1;
                mem[wr_adr] <= data_i;
              end

            if ( rdreq_i ) rd_adr <= rd_adr + 1;

            if ( ( ( usedw_o == 1) && ( !rdreq_i ) ) || ( usedw_o>1 ) ) empty_o <= 0;

            if ( ( ( usedw_o ==1 ) && rdreq_i ) || (usedw_o == 0 ) )    empty_o <= 1;

            if ( !empty_o ) q_buf <= mem[rd_adr];

          end
 
      assign q_o     = ( ( usedw_o == 0 ) || (empty_o ) ) ? q_buf : mem[rd_adr];
      assign full_o  = ( usedw_o == ( mem_vol - 1 ) );
      assign usedw_o = ( wr_adr >= rd_adr ) ? ( wr_adr - rd_adr ) : ( mem_vol + wr_adr - rd_adr);

    end

endgenerate

endmodule
