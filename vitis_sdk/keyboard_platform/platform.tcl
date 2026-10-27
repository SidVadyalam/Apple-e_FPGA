# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\sidva\Documents\Projects\FPGA\Apple IIe FPGA\vitis_sdk\keyboard_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\sidva\Documents\Projects\FPGA\Apple IIe FPGA\vitis_sdk\keyboard_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {keyboard_platform}\
-hw {C:\Users\sidva\Documents\School\2025 Fall\ECE 385 - Digital Systems Laboratory\Labs\Apple_IIe_FPGA\apple2e\working.xsa}\
-proc {microblaze_0} -os {standalone} -out {C:/Users/sidva/Documents/Projects/FPGA/Apple IIe FPGA/vitis_sdk}

platform write
platform generate -domains 
platform active {keyboard_platform}
platform generate
platform active {keyboard_platform}
platform config -updatehw {C:/Users/sidva/Documents/Projects/FPGA/Apple IIe FPGA/apple2e/working.xsa}
platform generate
platform config -updatehw {C:/Users/sidva/Documents/School/2025 Fall/ECE 385 - Digital Systems Laboratory/Labs/Apple_IIe_FPGA/apple2e/working.xsa}
platform config -updatehw {C:/Users/sidva/Documents/School/2025 Fall/ECE 385 - Digital Systems Laboratory/Labs/Apple_IIe_FPGA/apple2e/working.xsa}
platform config -updatehw {C:/Users/sidva/Documents/School/2025 Fall/ECE 385 - Digital Systems Laboratory/Labs/Apple_IIe_FPGA/apple2e/top_module.xsa}
platform generate -domains 
platform clean
platform generate
