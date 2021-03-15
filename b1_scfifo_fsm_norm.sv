// SCFIFO FSM
`timescale 1 ps / 1 ps

module b1_scfifo_fsm_norm

#( parameter AWIDTH = 8 )

(
  input logic              clk_i, srst_i, 
  input logic              rdreq_i, wrreq_i,
  input logic [AWIDTH-1:0] usedw_o,

  output logic             empty_fsm, full_fsm, wr_ena, rd_ena, q_ena
 );  

localparam mem_vol = 2**AWIDTH;
enum int unsigned { ZERO_ST=0, NORM_ST=1, FULL_ST=2} state, nextstate;
   
  always_ff @( posedge clk_i ) begin
    if ( srst_i )
      state <= ZERO_ST;
     else
      state <=nextstate;
  end

  always_comb
    begin
      nextstate = ZERO_ST;
      case ( state )
        ZERO_ST: if ( wrreq_i ) nextstate = NORM_ST;
        
        NORM_ST: if ( ( usedw_o == 1 ) && ( rdreq_i ) && ( !wrreq_i ) )  
                                nextstate = ZERO_ST;
                  else 
                    if ( ( usedw_o == ( mem_vol - 1 ) ) && ( wrreq_i ) && ( !rdreq_i ) ) 
                                nextstate = FULL_ST;
                     else       nextstate = NORM_ST;

        FULL_ST: if ( rdreq_i ) nextstate = NORM_ST;
                  else          nextstate = FULL_ST;
        endcase
    end

  always_comb begin
    case(state)
      ZERO_ST: 
			  begin
				  wr_ena    = 1;
				  rd_ena    = 0;
				  empty_fsm = 1;
				  full_fsm  = 0;
          q_ena     = 0;
				end

      NORM_ST:
			  begin
				  wr_ena    = 1;
				  rd_ena    = 1;
				  empty_fsm = 0;
				  full_fsm  = 0;
          q_ena     = 0;
				end		

      FULL_ST:
			  begin
				  wr_ena    = 0;
				  rd_ena    = 1;
				  empty_fsm = 0;
				  full_fsm  = 1;
          q_ena     = 0;
				end		
    endcase
  end

endmodule
