import os
import subprocess
import yaml
import argparse
import shutil
import glob
import sys


tcl_script = """
set curr_wave [current_wave_config]
if { [string length $curr_wave] == 0 } {
    if { [llength [get_objects]] > 0 } {
        add_wave /  
        set_property needs_save false [current_wave_config]  
    } else {
        send_msg_id Add_Wave-1 WARNING "No top level signals found. Simulator will start without a wave window. If you want to open a wave window, go to 'File->New Waveform Configuration' or type 'create_wave_config' in the TCL console."
    }
}
run 100ms
"""

#get data from yaml file 
def load_yaml(path):
    try:
        with open(path, "r") as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Failed to parse YAML file '{path}': {e}")
        sys.exit(1)
    

#copy the xsim.ini file in the vivado directory to the current directory
def copy_xsim_ini(data, lib_map_path=None):
    if lib_map_path is None:
        vivado_path = os.environ.get("XILINX_VIVADO")
        lib_map_path = os.path.join(vivado_path, "data", "xsim")
        
    xsim_ini = "xsim.ini"
    src_file = os.path.join(lib_map_path, xsim_ini)
    print(src_file)
    if not os.path.exists(src_file):
        raise FileNotFoundError(f"Cannot find source xsim.ini at {src_file}")

    print(f"Copying {src_file} to current directory.")
    shutil.copy(src_file, xsim_ini)

    backup_file = xsim_ini + ".bak"
    shutil.copy(xsim_ini, backup_file)

    print("xsim.ini updated with local library mappings.")


#compile the src file and create a library
def compile_sources(data):
    vivado_path = os.environ.get("XILINX_VIVADO")
    lib_map_path = os.path.join(vivado_path, "data")
    commands = f"""
set -Eeuo pipefail
export RDI_DATADIR="{lib_map_path}"
"""
    subprocess.run(commands, shell=True, executable="/bin/bash", check=True)

    config_data         = data.get("config", {})
    compiled_libs       = data.get("compiled_libs", {})
    xvlog_opt           = []
    xvhdl_opt           = []

    if config_data.get("incremental_compilation"):
        xvlog_opt.append("--incr")
        xvhdl_opt.append("--incr")

    if config_data.get("relax_compilation"):
        xvlog_opt.append("--relax")
        xvhdl_opt.append("--relax")

    if "uvm" in compiled_libs:
        xvlog_opt       += ["-L", "uvm"]
        xvlog_opt       += ["-L", "uvm"]

    work_lib            = data.get("work_lib", "xil_defaultlib")
    src_groups          = data.get("src_groups", [])

    glbl_add = False
    for group in src_groups:
        name            = group.get("name", "unnamed")
        file_type       = group.get("file_type", "verilog").lower()
        include_dirs    = group.get("include_dirs", [])
        source_files    = group.get("src_files", [])

        if not source_files:
            print(f"[{name}] No source files provided. Skipping.")
            continue

        if file_type == "vhdl":
            cmd         = ["xvhdl"] + xvhdl_opt + ["-work", work_lib]
        else:
            cmd         = ["xvlog"] + xvlog_opt + ["-work", work_lib]
            if include_dirs is not None:
                for inc in include_dirs:
                    cmd += ["-i", inc]
            if not glbl_add:
                glbl_path = os.path.join(vivado_path, "data", "verilog", "src", "glbl.v")
                if not os.path.exists(glbl_path):
                    print(f"[ERROR] glbl.v not found at expected path: {glbl_path}")
                    sys.exit(1)
                cmd.append(glbl_path)
                glbl_add = True

            if file_type == "systemverilog":
                cmd.append("-sv")
            

        cmd             += source_files

        print(f"\n[{name}] Compiling ({file_type})...")
        print("Command:", ' '.join(cmd))

        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"\n[ERROR] Compilation failed with exit code {e.returncode}")
            sys.exit(e.returncode)


#link the compiled library with precompiled libraries and create a snapshot
def elaborate(data):
    xelab_opt           = ["xelab"]
    config              = data.get("config", {})

    if config.get("incremental_compilation"):
        xelab_opt.append("--incr")

    if config.get("relax_compilation"):
        xelab_opt.append("--relax")

    xelab_opt           += ["--debug", config.get("debug", "typical")]
    xelab_opt           += ["--mt", config.get("multi_threading", "8")]
    xelab_opt           += ["-L", data.get("work_lib", "xil_defaultlib")]

    compiled_libs       = data.get("compiled_libs", [])
    for comp_lib in compiled_libs:
        xelab_opt       += ["-L", comp_lib]

    snapshot            = data.get("snapshot", "tb_top")
    top_module          = data.get("top_module", "tb_top")
    work_lib            = data.get("work_lib", "xil_defaultlib")

    xelab_opt           += ["--snapshot", snapshot]
    xelab_opt.append(f"{work_lib}.{top_module}")
    xelab_opt.append(f"{work_lib}.glbl")
    xelab_opt           += ["-log", data.get("log", "elaborate.log")]

    print("\n[elaborate] Running elaboration...")
    print("Command:", ' '.join(xelab_opt))
    try:
        subprocess.run(xelab_opt, check=True)
    except subprocess.CalledProcessError as e:
        print(f"\n[ERROR] Elaboration failed with exit code {e.returncode}")
        sys.exit(e.returncode)


#run simulation using snapshot
def simulate(data):

    with open("cmd.tcl", "w") as f:
        f.write(tcl_script)
    xsim_opt            = ["xsim"]
    xsim_opt.append(data.get("snapshot", "tb_top"))
    xsim_opt            += ["-key", f"Behavioral:sim_1:Functional:{data.get('top_module', 'tb_top')}"]
    xsim_opt            += ["-tclbatch", data.get("tcl_batch", "cmd.tcl")]
    xsim_opt            += ["-log", data.get("log", "simulate.log")]

    if data.get("gui"):
        xsim_opt.append("-gui")

    print("\n[simulate] Running simulation...")
    print("Command:", ' '.join(xsim_opt))
    try:
        subprocess.run(xsim_opt, check=True)
    except subprocess.CalledProcessError as e:
        print(f"\n[ERROR] Simulation failed with exit code {e.returncode}")
        sys.exit(e.returncode)


#clean unwanted stuff
def clean_sim():
    patterns        = ["*.log", "*.vstf", "*.wlf", "*.tcl","*.do", "transcript", "*.top", "*.pb", "*.jou", "*.wdb", "*.str" ,"*.ini","*.bak"]
    dirs_to_remove  = ["work", "modelsim.ini", "questa.tops", "vsim_stacktrace.vstf", "vsim.wlf","xsim.dir", ".Xil"]

    for pattern in patterns:
        for file in glob.glob(pattern):
            print(f"Removing file: {file}")
            os.remove(file)

    for d in dirs_to_remove:
        if os.path.isdir(d):
            print(f"Removing directory: {d}")
            shutil.rmtree(d)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Vivado simulation flow controller")
    parser.add_argument("--compile",    action="store_true",    help="Compile sources using xvlog/xvhdl")
    parser.add_argument("--opt",  action="store_true",    help="Elaborate the design using xelab")
    parser.add_argument("--run",   action="store_true",    help="Run simulation using xsim")
    parser.add_argument("--clean",      action="store_true",    help="Clean all simulation-generated files")
    parser.add_argument("--yaml",       default="xsim_src.yaml", help="Path to YAML configuration file")
    parser.add_argument("--initlib",    action="store_true",    help="Copy and configure xsim.ini for local simulation")

    args = parser.parse_args()
    if args.yaml:
        yaml_data = load_yaml(args.yaml)

    if args.clean:
        clean_sim()

    if args.compile:
        compile_sources(yaml_data)

    if args.initlib:
        copy_xsim_ini(yaml_data)

    if args.opt:
        elaborate(yaml_data)

    if args.run:
        simulate(yaml_data)