# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/reet/Desktop/ECE385/FinalProject/vitis_sdk/mb_usb_hdmi_top/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/reet/Desktop/ECE385/FinalProject/vitis_sdk/mb_usb_hdmi_top/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {mb_usb_hdmi_top}\
-hw {/home/reet/Desktop/ECE385/FinalProject/apple2e/mb_usb_hdmi_top.xsa}\
-out {/home/reet/Desktop/ECE385/FinalProject/vitis_sdk}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {mb_usb_hdmi_top}
platform generate -quick
platform generate
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/mb_usb_hdmi_top.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/mb_usb_hdmi_top.xsa}
platform generate -domains 
platform active {mb_usb_hdmi_top}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform active {mb_usb_hdmi_top}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains standalone_microblaze_0 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform active {mb_usb_hdmi_top}
platform config -updatehw {/home/reet/Downloads/top_module.xsa}
platform generate -domains standalone_microblaze_0 
platform config -updatehw {/home/reet/Downloads/top_module(1).xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Downloads/top_module(1).xsa}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Downloads/top_module(1).xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Downloads/top_module(1).xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Downloads/top_module(1).xsa}
platform generate -domains 
platform active {mb_usb_hdmi_top}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform active {mb_usb_hdmi_top}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains standalone_microblaze_0 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module1.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module2.xsa}
platform generate -domains 
platform active {mb_usb_hdmi_top}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module3.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module4.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module5.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module6.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module7.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module8.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module7.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module9.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module8.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module9.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module10.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module10.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module11.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module12.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module13.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module14.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module15.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module16.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module17.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module18.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module19.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module20.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module21.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module22.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module23.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module24.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module25.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module26.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module26.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module27.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module28.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module29.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module30.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module31.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module32.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module33.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module33.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module30.xsa}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module31.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module34.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module34.xsa}
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module35.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module36.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module37.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module38.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module39.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module40.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module41.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module42.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module43.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module44.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module30.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/top_module31.xsa}
platform generate -domains 
platform config -updatehw {/home/reet/Desktop/ECE385/FinalProject/apple2e/working.xsa}
platform generate -domains 
