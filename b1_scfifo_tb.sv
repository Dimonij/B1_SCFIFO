`timescale 1 ps / 1 ps

module b1_scfifo_tb;

localparam DWIDTH    = 8;
localparam AWIDTH    = 8;
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

int write_counter, read_counter, base_level;

task full_write_new;
  d_wrreq_i = 0;
  write_counter = 0;
   do
     begin
       @( posedge clk );
       d_wrreq_i = 1;
       d_data_i  = ( $urandom_range( 2**DWIDTH - 1,0 ) );
       if (!d1_full_o) write_counter++;
     end 
   while ( !( ( d1_usedw_o == 0 ) && ( d1_full_o == 1 ) && (write_counter>2) ) );
  d_wrreq_i =0;
  $display ("write_op make = %d, for SCFIFO_volume = %d words", write_counter-1, ( 2**AWIDTH ) );
endtask

task full_read_new;
  d_rdreq_i = 0;
  read_counter = 0;
   do
     begin
       @( posedge clk );
       d_rdreq_i = 1;
       if ( !d1_empty_o ) read_counter++; 
     end 
   while ( !( ( d1_usedw_o == 0 ) && ( d1_empty_o == 1 ) ) );
  d_rdreq_i =0;
  $display ("read_op  make = %d, for SCFIFO_volume = %d words", read_counter-1, ( 2**AWIDTH ) );
endtask

task sustain_write;
  input int cyc_val, fill_level;
  int tempy;
  d_wrreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @(posedge clk)
      begin
        d_data_i = ( $urandom_range ( 2**DWIDTH - 1,0 ) );
        if ( d1_usedw_o < fill_level )
          begin
            tempy = ( $urandom_range(3,0) );
            if ( tempy > 0 ) d_wrreq_i = 1; 
              else           d_wrreq_i = 0;
          end 
         else 
           if ( d1_usedw_o >= fill_level )
                begin
                 tempy = ( $urandom_range(2,0) );
                 if ( tempy == 0 ) d_wrreq_i = 1; 
                  else d_wrreq_i = 0;
                end
      end
    end       
  d_wrreq_i = 0;
endtask

task sustain_read;
  input int cyc_val, fill_level;
  int tempy;
  d_rdreq_i = 0;
  for ( int i=0; i<=cyc_val;i++ )
    begin
      @(posedge clk)
        begin
          if ( d1_usedw_o > fill_level )
            begin
              tempy = ( $urandom_range(3,0) );
              if ( tempy>0 ) d_rdreq_i = 1; 
               else          d_rdreq_i = 0;
            end 
          else 
            if ( d1_usedw_o <= fill_level )
              begin
                tempy = ( $urandom_range(2,0) );
                if ( tempy == 0 ) d_rdreq_i = 1; 
                 else             d_rdreq_i = 0;
              end
         end
     end       
  d_rdreq_i = 0;
endtask

task rand_op_more_read;
  input int cyc_val;
  int tempy;
  d_rdreq_i = 0;
  d_wrreq_i = 0;
  for (int i=0; i<=cyc_val;i++)
    @(posedge clk)
      begin
        d_data_i  = ( $urandom_range (2**DWIDTH - 1,0) );
        d_wrreq_i = ( $urandom_range(1,0 ) );
        tempy = ($urandom_range(2,0));
        if ( tempy>0 ) d_rdreq_i = 1; 
         else          d_rdreq_i = 0;
      end
  d_rdreq_i = 0;
  d_wrreq_i = 0;
endtask

task rand_op_more_write;
  input int cyc_val;
  int tempy;
  d_rdreq_i = 0;
  d_wrreq_i = 0;
  for (int i=0; i<=cyc_val;i++)
    @(posedge clk)
      begin
        d_data_i  = ( $urandom_range (2**DWIDTH - 1,0) );
        d_rdreq_i = ( $urandom_range(1,0) );
        tempy     = ( $urandom_range(2,0) );
        if ( tempy>0 ) d_wrreq_i = 1; 
         else          d_wrreq_i =0;
      end
  d_rdreq_i  = 0;
  d_wrreq_i = 0;   
endtask

task comparator;
  do 
    @( posedge clk )
      begin
        if ( d1_empty_o != d2_empty_o )  
          begin 
            $display( "Test failed: <EMPTY> signal mismatch at time:", $time);
            $stop;
          end
        if ( d1_full_o != d2_full_o ) 
          begin
            $display( "Test failed: <FULL> signal mismatch at time:", $time);
            $stop;
          end
        if ( d1_q_o != d2_q_o ) 
           begin
            $display ( "Test failed: <OUTPUT> value inequality at time:", $time);
            $stop;
           end
       if ( d1_usedw_o != d2_usedw_o )
          begin
            $display ("Test failed: <USED_WORD> value inequality at time:", $time);
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

$display("Start full write test...");
fork
  full_write_new;
  comparator;
join_any
disable comparator;
$display ("Full_write test ok");
$display (" ");

$display("Start full read test...");
fork
  full_read_new;
  comparator;
join_any
disable comparator;
$display ("Full_read test ok");
$display (" ");

$display ("Start multiple random read/write test near lower fill level...");
fork
  rand_op_more_read( 10*MAX_DATA );
  comparator;
join_any
disable comparator;
$display ("Multiple random read/write test near lower fill level ok");
$display (" ");

$display ("Start multiple random read/write test near top fill level...");
fork
  rand_op_more_write( 10*MAX_DATA );
  comparator;
join_any
disable comparator;
$display ("Multiple random read/write test near top fill level ok");
$display (" ");

$display ("Start floating read/write test near target fill level...");
for (int i=0;i<MAX_DATA; i++)
  begin
    base_level = $urandom_range( MAX_DATA-1,1 );
    fork
      sustain_read  ( 2*MAX_DATA,base_level );
      sustain_write ( 2*MAX_DATA,base_level );
      comparator;
    join_any
  disable comparator;
  disable sustain_read;
  disable sustain_write;
end
$display ("Floating read/write test near target fill level ok");
$display (" ");
$display ("All test sucsessful!");

$stop;
 end
  
endmodule

