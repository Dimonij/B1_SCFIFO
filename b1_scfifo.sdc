set_time_format -unit ns -decimal_places 3
create_clock -name {clk_100} -period 10.000 -waveform { 0.000 5.000 } [get_ports {clk_i}]
derive_pll_clocks