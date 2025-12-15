
if [file exists "work"] {vdel -all}
vlib work

vlog -64 -incr -mfcu -sv data_feeder.v
vlog -64 -incr -mfcu -sv tb_data_feeder.v

vopt -64 +acc=npr tb_data_feeder -o testbench_opt

vsim testbench_opt -wlf mywlf.wlf

#add log /* -r
add log sim:/tb_data_feeder/dut/*

run -all

dataset save

quit

