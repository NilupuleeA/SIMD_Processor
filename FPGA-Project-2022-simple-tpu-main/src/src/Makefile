# Makefile to control simulation flow using Python

SIMULATOR ?= xsim

ifeq ($(SIMULATOR), xsim)
	SCRIPT := run_xsim.py
	SOURCES_YAML := xsim_src.yaml
else ifeq ($(SIMULATOR), vsim)
	SCRIPT := run_vsim.py
	SOURCES_YAML := vsim_src.yaml
else ifeq ($(SIMULATOR), vcs)
	SCRIPT := run_vcs.py
	SOURCES_YAML := vcs_src.yaml
else
	$(error Unsupported SIMULATOR: $(SIMULATOR))
endif

# Python executable
PYTHON := python3

.PHONY: all setup com opt run clean help

all: setup com opt run

# Setup for simulator environment (copying xsim.ini, etc.)
setup:
	$(PYTHON) $(SCRIPT) --yaml $(SOURCES_YAML) --initlib

# Compile sources
com:
	$(PYTHON) $(SCRIPT) --compile

# Elaborate the design
opt:
	$(PYTHON) $(SCRIPT) --opt

# Run the simulation
run:
	$(PYTHON) $(SCRIPT) --run

# Clean up simulation files
clean:
	$(PYTHON) $(SCRIPT) --clean

# Help command to print out available options
help:
	$(PYTHON) $(SCRIPT) --help
