`timescale 1 ps / 1 ps

module b1_scfifo_tb;

localparam DWIDTH = 8;
localparam AWIDTH = 8;
localparam SHOWAHEAD = "ON";
localparam MAX_DATA  = 2**AWIDTH;
localparam TEST_MULT = 8;

// test internal signal & var & common wire
bit              clk, reset; 
bit              d_rdreq_i, d_wrreq_i;
bit              d1_empty_o, d2_empty_o;
bit              d1_full_o, d2_full_o;
bit [DWIDTH-1:0] d_data_i;
bit [DWIDTH-1:0] d1_q_o, d2_q_o, d1_temp, d2_temp, temp_val;
bit [AWIDTH-1:0] d1_usedw_o, d2_usedw_o, d1_us_temp, d2_us_temp, us_temp_val;

task full_write;
  input int cyc_val;
  d_wrreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @( posedge clk )
        begin
          d_data_i = ( $urandom_range(2**DWIDTH - 1,0 ) );
          if ( ( d1_usedw_o == ( MAX_DATA-1 ) ) || ( ( d_wrreq_i == 1 ) && ( d1_usedw_o == ( MAX_DATA -2 ) ) ) || ( d1_full_o==1 ) ) d_wrreq_i = 0;
          else d_wrreq_i = 1;
        end 
    end  
  d_wrreq_i =0;
endtask

task rand_write;
  input int cyc_val;
  d_wrreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @(posedge clk)
        begin
          d_data_i = ( $urandom_range ( 2**DWIDTH - 1,0 ) );
          if ( ( d1_usedw_o == ( MAX_DATA-1 ) ) || ( ( d_wrreq_i == 1 ) && ( d1_usedw_o == ( MAX_DATA - 2 ) ) ) || ( d1_full_o==1) ) d_wrreq_i = 0;
          else d_wrreq_i = ( $urandom_range(1,0) );
        end  
    end
  d_wrreq_i = 0;
endtask

task more_write;
  input int cyc_val;
  int tempy;
  d_wrreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @(posedge clk)
        begin
          d_data_i = ( $urandom_range (2**DWIDTH - 1,0) );
          if ( (d1_usedw_o == ( MAX_DATA-1 ) ) || ( ( d_wrreq_i == 1 ) && ( d1_usedw_o == ( MAX_DATA -2 ) ) ) || ( d1_full_o==1 ) ) d_wrreq_i =0;
          else 
            begin
              tempy = ( $urandom_range(2,0) );
              if ( tempy>0 ) d_wrreq_i = 1; else d_wrreq_i = 0;
            end
        end  
    end
  d_wrreq_i = 0;
endtask

task full_read;
  input int cyc_val;
  d_rdreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @( posedge clk )
        begin
          if ( ( d1_usedw_o == 0 ) || ( ( d1_usedw_o==1 ) && ( d_rdreq_i==1 ) ) || ( d1_empty_o==1 ) ) d_rdreq_i=0;
          else d_rdreq_i = 1;
        end
    end
  d_rdreq_i = 0;
endtask
    
task rand_read;
  input int cyc_val;
  d_rdreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @(posedge clk)
        begin
          if ( ( d1_usedw_o == 0 ) || ( ( d1_usedw_o==1 ) && ( d_rdreq_i==1 ) ) || ( d1_empty_o==1 ) ) d_rdreq_i=0;
          else d_rdreq_i = ( $urandom_range(1,0) );
        end
    end
  d_rdreq_i = 0;
endtask

task more_read;
  input int cyc_val;
  int tempy;
  d_rdreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @( posedge clk )
        begin
          if ( ( d1_usedw_o == 0 ) || ( ( d1_usedw_o==1 ) && ( d_rdreq_i==1 ) ) || ( d1_empty_o==1 ) ) d_rdreq_i=0;
          else 
            begin
              tempy = ( $urandom_range(2,0) );
              if (tempy>0) d_rdreq_i = 1; else d_rdreq_i = 0;
            end
        end
    end
  d_rdreq_i = 0;
endtask

task no_long;
  input int takt_val;
  for ( int i=0; i<=takt_val;i++ )
    @(posedge clk);
  disable comparator;
endtask

task comparator;
  do 
    @( posedge clk )
      begin
        if ( ( d1_empty_o != d2_empty_o ) || ( d1_full_o != d2_full_o ) || ( d1_q_o != d2_q_o ) || ( d1_usedw_o != d2_usedw_o ) ) 
          begin 
            $display( "Test failed");
            $stop;
          end
      end 
  while (1);
endtask

// takt generator
initial 
  forever #5 clk = !clk;

// port mapping Intel scfifo as DUT1
i_scf #( DWIDTH, AWIDTH, SHOWAHEAD ) DUT1 (
  .clk_i   ( clk ),
  .srst_i  ( reset ),
  .rdreq_i ( d_rdreq_i ),
  .wrreq_i ( d_wrreq_i ),
  .data_i  ( d_data_i ),
  .empty_o ( d1_empty_o ),
  .full_o  ( d1_full_o ),
  .q_o     ( d1_q_o ),
  .usedw_o ( d1_usedw_o )
);

// port mapping B1_task scfifo as DUT2
b1_scfifo #( DWIDTH, AWIDTH, SHOWAHEAD ) DUT2 (
  .clk_i   ( clk ),
  .srst_i  ( reset ),
  .rdreq_i ( d_rdreq_i ),
  .wrreq_i ( d_wrreq_i ),
  .data_i  ( d_data_i ),
  .empty_o ( d2_empty_o ) ,
  .full_o  ( d2_full_o ),
  .q_o     ( d2_q_o ),
  .usedw_o ( d2_usedw_o )
);

// start initialization
initial 
  begin
    d_wrreq_i = 0;
    d_rdreq_i = 0;
    #10;
    @( posedge clk ) reset = 1'b1;
    @( posedge clk ) reset = 1'b0;	
    #10;

  fork
    full_write( 2**AWIDTH - 1 );
    comparator;
  join_any

  disable comparator;

  fork
    full_read( 2**AWIDTH - 1 );
    comparator;
  join_any

  disable comparator;

  fork
    more_write( TEST_MULT*( 2**AWIDTH ) );
    rand_read( TEST_MULT*( 2**AWIDTH ) );
    no_long( TEST_MULT*( 2**AWIDTH ) + 10 );
    comparator;
  join

  fork
    rand_write( TEST_MULT*( 2**AWIDTH ) );
    more_read( TEST_MULT*( 2**AWIDTH ) );
    no_long( TEST_MULT*( 2**AWIDTH ) + 10 );
    comparator;
  join


  $display (" Test sucsessful!");

  $stop;
  end
  
endmodule

