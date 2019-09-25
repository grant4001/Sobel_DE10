set_global_assignment -entity "VIDEO_PLL" -library "lib_VIDEO_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "VIDEO_PLL" -library "lib_VIDEO_PLL" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "VIDEO_PLL" -library "lib_VIDEO_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_VIDEO_PLL" -name SPD_FILE [file join $::quartus(sip_path) "VIDEO_PLL.spd"]

set_global_assignment -library "lib_VIDEO_PLL" -name MISC_FILE [file join $::quartus(sip_path) "VIDEO_PLL_sim/VIDEO_PLL.vo"]
