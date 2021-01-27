vlib work

vlog -sv b1_scfifo.sv
vlog -sv i_scf.sv

vlog -sv b1_scfifo_tb.sv

vsim -novopt -L altera_mf_ver work.b1_scfifo_tb

add log -r /*
add wave -r *

run -all
