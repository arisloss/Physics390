#
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create a project
open_project -reset hls_counter

# Add design files
add_files counter.cpp
# Add test bench & files
add_files -tb example_counter.cpp

# Set the top-level function
set_top counter

# ########################################################
# Create a solution
open_solution -reset solution1 -flow_target vivado

# Define technology and clock rate
set_part  {XC7VX690T-FFG1761-2}
create_clock -period "200MHz"

# Set variable to select which steps to execute
set hls_exec 3


csim_design
# Set any optimization directives
# End of directives

if {$hls_exec == 1} {
    # Run Synthesis and Exit
    csynth_design
    
} elseif {$hls_exec == 2} {
    # Run Synthesis, RTL Simulation and Exit
    csynth_design
    
    cosim_design
} elseif {$hls_exec == 3} { 
    # Run Synthesis, RTL Simulation, RTL implementation and Exit
    csynth_design
    
    cosim_design
    export_design -format ip_catalog
} else {
    # Default is to exit after setup
    csynth_design
}

exit
