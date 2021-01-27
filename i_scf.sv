// Intel SCFIFO experiment instanting for ModelSim
`timescale 1 ps / 1 ps

module i_scf

#( parameter DWIDTH = 8, AWIDTH = 8, SHOWAHEAD = "OFF" )

(
  input logic               clk_i, srst_i, 
  input logic               rdreq_i, wrreq_i,
  input logic  [DWIDTH-1:0] data_i,
  
  output logic              empty_o, full_o,
  output logic [DWIDTH-1:0] q_o,
  output logic [AWIDTH-1:0] usedw_o
);  

	scfifo	scfifo_component (
    .clock        ( clk_i ),
    .data         ( data_i ),
    .rdreq        ( rdreq_i ),
    .sclr         ( srst_i ),
    .wrreq        ( wrreq_i ),
    .empty        ( empty_o ),
    .full         ( full_o ),
    .q            ( q_o ),
    .usedw        ( usedw_o ),
		.aclr         (),
		.almost_empty (),
    .almost_full  (),
		.eccstatus    ());
	
  defparam
		scfifo_component.add_ram_output_register = "OFF",
		scfifo_component.intended_device_family  = "Cyclone V",
    scfifo_component.lpm_numwords            = ( ( 2**AWIDTH ) - 1 ),
		scfifo_component.lpm_showahead           = SHOWAHEAD,
		scfifo_component.lpm_type                = "scfifo",
		scfifo_component.lpm_width               = DWIDTH,
		scfifo_component.lpm_widthu              = AWIDTH,
		scfifo_component.overflow_checking       = "ON",
		scfifo_component.underflow_checking      = "ON",
		scfifo_component.use_eab                 = "ON";


endmodule
