set_param project.enableReportConfiguration 0
load_feature core
current_fileset
xsim {tb_top} -autoloadwcfg -tclbatch {cmd.tcl} -key Behavioral:sim_1:Functional:tb_top
