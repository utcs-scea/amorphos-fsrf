# This script segment is generated automatically by AutoPilot

# clear list
if {${::AESL::PGuard_autoexp_gen}} {
    cg_default_interface_gen_dc_begin
    cg_default_interface_gen_bundle_begin
    AESL_LIB_XILADAPTER::native_axis_begin
}

# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 614 \
    name data \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data \
    op interface \
    ports { data_address0 { O 4 vector } data_ce0 { O 1 bit } data_q0 { I 15 vector } data_address1 { O 4 vector } data_ce1 { O 1 bit } data_q1 { I 15 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 615 \
    name data1 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data1 \
    op interface \
    ports { data1_address0 { O 4 vector } data1_ce0 { O 1 bit } data1_q0 { I 1 vector } data1_address1 { O 4 vector } data1_ce1 { O 1 bit } data1_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data1'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 616 \
    name data2 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data2 \
    op interface \
    ports { data2_address0 { O 4 vector } data2_ce0 { O 1 bit } data2_q0 { I 1 vector } data2_address1 { O 4 vector } data2_ce1 { O 1 bit } data2_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data2'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 617 \
    name data3 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data3 \
    op interface \
    ports { data3_address0 { O 4 vector } data3_ce0 { O 1 bit } data3_q0 { I 1 vector } data3_address1 { O 4 vector } data3_ce1 { O 1 bit } data3_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data3'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 618 \
    name data4 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data4 \
    op interface \
    ports { data4_address0 { O 4 vector } data4_ce0 { O 1 bit } data4_q0 { I 1 vector } data4_address1 { O 4 vector } data4_ce1 { O 1 bit } data4_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data4'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 619 \
    name data5 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data5 \
    op interface \
    ports { data5_address0 { O 4 vector } data5_ce0 { O 1 bit } data5_q0 { I 1 vector } data5_address1 { O 4 vector } data5_ce1 { O 1 bit } data5_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data5'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 620 \
    name data6 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data6 \
    op interface \
    ports { data6_address0 { O 4 vector } data6_ce0 { O 1 bit } data6_q0 { I 1 vector } data6_address1 { O 4 vector } data6_ce1 { O 1 bit } data6_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data6'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 621 \
    name data7 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data7 \
    op interface \
    ports { data7_address0 { O 4 vector } data7_ce0 { O 1 bit } data7_q0 { I 1 vector } data7_address1 { O 4 vector } data7_ce1 { O 1 bit } data7_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data7'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 622 \
    name data8 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data8 \
    op interface \
    ports { data8_address0 { O 4 vector } data8_ce0 { O 1 bit } data8_q0 { I 1 vector } data8_address1 { O 4 vector } data8_ce1 { O 1 bit } data8_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data8'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 623 \
    name data9 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data9 \
    op interface \
    ports { data9_address0 { O 4 vector } data9_ce0 { O 1 bit } data9_q0 { I 1 vector } data9_address1 { O 4 vector } data9_ce1 { O 1 bit } data9_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data9'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 624 \
    name data10 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data10 \
    op interface \
    ports { data10_address0 { O 4 vector } data10_ce0 { O 1 bit } data10_q0 { I 1 vector } data10_address1 { O 4 vector } data10_ce1 { O 1 bit } data10_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data10'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 625 \
    name data11 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data11 \
    op interface \
    ports { data11_address0 { O 4 vector } data11_ce0 { O 1 bit } data11_q0 { I 1 vector } data11_address1 { O 4 vector } data11_ce1 { O 1 bit } data11_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data11'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 626 \
    name data12 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data12 \
    op interface \
    ports { data12_address0 { O 4 vector } data12_ce0 { O 1 bit } data12_q0 { I 1 vector } data12_address1 { O 4 vector } data12_ce1 { O 1 bit } data12_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data12'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 627 \
    name data13 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data13 \
    op interface \
    ports { data13_address0 { O 4 vector } data13_ce0 { O 1 bit } data13_q0 { I 1 vector } data13_address1 { O 4 vector } data13_ce1 { O 1 bit } data13_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data13'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 628 \
    name data14 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data14 \
    op interface \
    ports { data14_address0 { O 4 vector } data14_ce0 { O 1 bit } data14_q0 { I 1 vector } data14_address1 { O 4 vector } data14_ce1 { O 1 bit } data14_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data14'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 629 \
    name data15 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data15 \
    op interface \
    ports { data15_address0 { O 4 vector } data15_ce0 { O 1 bit } data15_q0 { I 1 vector } data15_address1 { O 4 vector } data15_ce1 { O 1 bit } data15_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data15'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 630 \
    name data16 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data16 \
    op interface \
    ports { data16_address0 { O 4 vector } data16_ce0 { O 1 bit } data16_q0 { I 15 vector } data16_address1 { O 4 vector } data16_ce1 { O 1 bit } data16_q1 { I 15 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data16'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 631 \
    name data17 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data17 \
    op interface \
    ports { data17_address0 { O 4 vector } data17_ce0 { O 1 bit } data17_q0 { I 1 vector } data17_address1 { O 4 vector } data17_ce1 { O 1 bit } data17_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data17'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 632 \
    name data18 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data18 \
    op interface \
    ports { data18_address0 { O 4 vector } data18_ce0 { O 1 bit } data18_q0 { I 1 vector } data18_address1 { O 4 vector } data18_ce1 { O 1 bit } data18_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data18'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 633 \
    name data19 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data19 \
    op interface \
    ports { data19_address0 { O 4 vector } data19_ce0 { O 1 bit } data19_q0 { I 1 vector } data19_address1 { O 4 vector } data19_ce1 { O 1 bit } data19_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data19'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 634 \
    name data20 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data20 \
    op interface \
    ports { data20_address0 { O 4 vector } data20_ce0 { O 1 bit } data20_q0 { I 1 vector } data20_address1 { O 4 vector } data20_ce1 { O 1 bit } data20_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data20'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 635 \
    name data21 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data21 \
    op interface \
    ports { data21_address0 { O 4 vector } data21_ce0 { O 1 bit } data21_q0 { I 1 vector } data21_address1 { O 4 vector } data21_ce1 { O 1 bit } data21_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data21'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 636 \
    name data22 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data22 \
    op interface \
    ports { data22_address0 { O 4 vector } data22_ce0 { O 1 bit } data22_q0 { I 1 vector } data22_address1 { O 4 vector } data22_ce1 { O 1 bit } data22_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data22'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 637 \
    name data23 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data23 \
    op interface \
    ports { data23_address0 { O 4 vector } data23_ce0 { O 1 bit } data23_q0 { I 1 vector } data23_address1 { O 4 vector } data23_ce1 { O 1 bit } data23_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data23'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 638 \
    name data24 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data24 \
    op interface \
    ports { data24_address0 { O 4 vector } data24_ce0 { O 1 bit } data24_q0 { I 1 vector } data24_address1 { O 4 vector } data24_ce1 { O 1 bit } data24_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data24'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 639 \
    name data25 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data25 \
    op interface \
    ports { data25_address0 { O 4 vector } data25_ce0 { O 1 bit } data25_q0 { I 1 vector } data25_address1 { O 4 vector } data25_ce1 { O 1 bit } data25_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data25'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 640 \
    name data26 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data26 \
    op interface \
    ports { data26_address0 { O 4 vector } data26_ce0 { O 1 bit } data26_q0 { I 1 vector } data26_address1 { O 4 vector } data26_ce1 { O 1 bit } data26_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data26'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 641 \
    name data27 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data27 \
    op interface \
    ports { data27_address0 { O 4 vector } data27_ce0 { O 1 bit } data27_q0 { I 1 vector } data27_address1 { O 4 vector } data27_ce1 { O 1 bit } data27_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data27'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 642 \
    name data28 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data28 \
    op interface \
    ports { data28_address0 { O 4 vector } data28_ce0 { O 1 bit } data28_q0 { I 1 vector } data28_address1 { O 4 vector } data28_ce1 { O 1 bit } data28_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data28'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 643 \
    name data29 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data29 \
    op interface \
    ports { data29_address0 { O 4 vector } data29_ce0 { O 1 bit } data29_q0 { I 1 vector } data29_address1 { O 4 vector } data29_ce1 { O 1 bit } data29_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data29'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 644 \
    name data30 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data30 \
    op interface \
    ports { data30_address0 { O 4 vector } data30_ce0 { O 1 bit } data30_q0 { I 1 vector } data30_address1 { O 4 vector } data30_ce1 { O 1 bit } data30_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data30'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 645 \
    name data31 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data31 \
    op interface \
    ports { data31_address0 { O 4 vector } data31_ce0 { O 1 bit } data31_q0 { I 1 vector } data31_address1 { O 4 vector } data31_ce1 { O 1 bit } data31_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data31'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 646 \
    name data32 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data32 \
    op interface \
    ports { data32_address0 { O 4 vector } data32_ce0 { O 1 bit } data32_q0 { I 15 vector } data32_address1 { O 4 vector } data32_ce1 { O 1 bit } data32_q1 { I 15 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data32'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 647 \
    name data33 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data33 \
    op interface \
    ports { data33_address0 { O 4 vector } data33_ce0 { O 1 bit } data33_q0 { I 1 vector } data33_address1 { O 4 vector } data33_ce1 { O 1 bit } data33_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data33'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 648 \
    name data34 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data34 \
    op interface \
    ports { data34_address0 { O 4 vector } data34_ce0 { O 1 bit } data34_q0 { I 1 vector } data34_address1 { O 4 vector } data34_ce1 { O 1 bit } data34_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data34'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 649 \
    name data35 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data35 \
    op interface \
    ports { data35_address0 { O 4 vector } data35_ce0 { O 1 bit } data35_q0 { I 1 vector } data35_address1 { O 4 vector } data35_ce1 { O 1 bit } data35_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data35'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 650 \
    name data36 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data36 \
    op interface \
    ports { data36_address0 { O 4 vector } data36_ce0 { O 1 bit } data36_q0 { I 1 vector } data36_address1 { O 4 vector } data36_ce1 { O 1 bit } data36_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data36'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 651 \
    name data37 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data37 \
    op interface \
    ports { data37_address0 { O 4 vector } data37_ce0 { O 1 bit } data37_q0 { I 1 vector } data37_address1 { O 4 vector } data37_ce1 { O 1 bit } data37_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data37'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 652 \
    name data38 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data38 \
    op interface \
    ports { data38_address0 { O 4 vector } data38_ce0 { O 1 bit } data38_q0 { I 1 vector } data38_address1 { O 4 vector } data38_ce1 { O 1 bit } data38_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data38'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 653 \
    name data39 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data39 \
    op interface \
    ports { data39_address0 { O 4 vector } data39_ce0 { O 1 bit } data39_q0 { I 1 vector } data39_address1 { O 4 vector } data39_ce1 { O 1 bit } data39_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data39'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 654 \
    name data40 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data40 \
    op interface \
    ports { data40_address0 { O 4 vector } data40_ce0 { O 1 bit } data40_q0 { I 1 vector } data40_address1 { O 4 vector } data40_ce1 { O 1 bit } data40_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data40'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 655 \
    name data41 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data41 \
    op interface \
    ports { data41_address0 { O 4 vector } data41_ce0 { O 1 bit } data41_q0 { I 1 vector } data41_address1 { O 4 vector } data41_ce1 { O 1 bit } data41_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data41'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 656 \
    name data42 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data42 \
    op interface \
    ports { data42_address0 { O 4 vector } data42_ce0 { O 1 bit } data42_q0 { I 1 vector } data42_address1 { O 4 vector } data42_ce1 { O 1 bit } data42_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data42'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 657 \
    name data43 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data43 \
    op interface \
    ports { data43_address0 { O 4 vector } data43_ce0 { O 1 bit } data43_q0 { I 1 vector } data43_address1 { O 4 vector } data43_ce1 { O 1 bit } data43_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data43'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 658 \
    name data44 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data44 \
    op interface \
    ports { data44_address0 { O 4 vector } data44_ce0 { O 1 bit } data44_q0 { I 1 vector } data44_address1 { O 4 vector } data44_ce1 { O 1 bit } data44_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data44'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 659 \
    name data45 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data45 \
    op interface \
    ports { data45_address0 { O 4 vector } data45_ce0 { O 1 bit } data45_q0 { I 1 vector } data45_address1 { O 4 vector } data45_ce1 { O 1 bit } data45_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data45'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 660 \
    name data46 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data46 \
    op interface \
    ports { data46_address0 { O 4 vector } data46_ce0 { O 1 bit } data46_q0 { I 1 vector } data46_address1 { O 4 vector } data46_ce1 { O 1 bit } data46_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data46'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 661 \
    name data47 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data47 \
    op interface \
    ports { data47_address0 { O 4 vector } data47_ce0 { O 1 bit } data47_q0 { I 1 vector } data47_address1 { O 4 vector } data47_ce1 { O 1 bit } data47_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data47'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 662 \
    name data48 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data48 \
    op interface \
    ports { data48_address0 { O 4 vector } data48_ce0 { O 1 bit } data48_q0 { I 15 vector } data48_address1 { O 4 vector } data48_ce1 { O 1 bit } data48_q1 { I 15 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data48'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 663 \
    name data49 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data49 \
    op interface \
    ports { data49_address0 { O 4 vector } data49_ce0 { O 1 bit } data49_q0 { I 1 vector } data49_address1 { O 4 vector } data49_ce1 { O 1 bit } data49_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data49'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 664 \
    name data50 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data50 \
    op interface \
    ports { data50_address0 { O 4 vector } data50_ce0 { O 1 bit } data50_q0 { I 1 vector } data50_address1 { O 4 vector } data50_ce1 { O 1 bit } data50_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data50'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 665 \
    name data51 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data51 \
    op interface \
    ports { data51_address0 { O 4 vector } data51_ce0 { O 1 bit } data51_q0 { I 1 vector } data51_address1 { O 4 vector } data51_ce1 { O 1 bit } data51_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data51'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 666 \
    name data52 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data52 \
    op interface \
    ports { data52_address0 { O 4 vector } data52_ce0 { O 1 bit } data52_q0 { I 1 vector } data52_address1 { O 4 vector } data52_ce1 { O 1 bit } data52_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data52'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 667 \
    name data53 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data53 \
    op interface \
    ports { data53_address0 { O 4 vector } data53_ce0 { O 1 bit } data53_q0 { I 1 vector } data53_address1 { O 4 vector } data53_ce1 { O 1 bit } data53_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data53'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 668 \
    name data54 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data54 \
    op interface \
    ports { data54_address0 { O 4 vector } data54_ce0 { O 1 bit } data54_q0 { I 1 vector } data54_address1 { O 4 vector } data54_ce1 { O 1 bit } data54_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data54'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 669 \
    name data55 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data55 \
    op interface \
    ports { data55_address0 { O 4 vector } data55_ce0 { O 1 bit } data55_q0 { I 1 vector } data55_address1 { O 4 vector } data55_ce1 { O 1 bit } data55_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data55'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 670 \
    name data56 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data56 \
    op interface \
    ports { data56_address0 { O 4 vector } data56_ce0 { O 1 bit } data56_q0 { I 1 vector } data56_address1 { O 4 vector } data56_ce1 { O 1 bit } data56_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data56'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 671 \
    name data57 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data57 \
    op interface \
    ports { data57_address0 { O 4 vector } data57_ce0 { O 1 bit } data57_q0 { I 1 vector } data57_address1 { O 4 vector } data57_ce1 { O 1 bit } data57_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data57'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 672 \
    name data58 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data58 \
    op interface \
    ports { data58_address0 { O 4 vector } data58_ce0 { O 1 bit } data58_q0 { I 1 vector } data58_address1 { O 4 vector } data58_ce1 { O 1 bit } data58_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data58'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 673 \
    name data59 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data59 \
    op interface \
    ports { data59_address0 { O 4 vector } data59_ce0 { O 1 bit } data59_q0 { I 1 vector } data59_address1 { O 4 vector } data59_ce1 { O 1 bit } data59_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data59'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 674 \
    name data60 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data60 \
    op interface \
    ports { data60_address0 { O 4 vector } data60_ce0 { O 1 bit } data60_q0 { I 1 vector } data60_address1 { O 4 vector } data60_ce1 { O 1 bit } data60_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data60'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 675 \
    name data61 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data61 \
    op interface \
    ports { data61_address0 { O 4 vector } data61_ce0 { O 1 bit } data61_q0 { I 1 vector } data61_address1 { O 4 vector } data61_ce1 { O 1 bit } data61_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data61'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 676 \
    name data62 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data62 \
    op interface \
    ports { data62_address0 { O 4 vector } data62_ce0 { O 1 bit } data62_q0 { I 1 vector } data62_address1 { O 4 vector } data62_ce1 { O 1 bit } data62_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data62'"
}
}


# XIL_BRAM:
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc ::AESL_LIB_XILADAPTER::xil_bram_gen] == "::AESL_LIB_XILADAPTER::xil_bram_gen"} {
eval "::AESL_LIB_XILADAPTER::xil_bram_gen { \
    id 677 \
    name data63 \
    reset_level 1 \
    sync_rst true \
    dir I \
    corename data63 \
    op interface \
    ports { data63_address0 { O 4 vector } data63_ce0 { O 1 bit } data63_q0 { I 1 vector } data63_address1 { O 4 vector } data63_ce1 { O 1 bit } data63_q1 { I 1 vector } } \
} "
} else {
puts "@W \[IMPL-110\] Cannot find bus interface model in the library. Ignored generation of bus interface for 'data63'"
}
}


# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id -1 \
    name ap_ctrl \
    type ap_ctrl \
    reset_level 1 \
    sync_rst true \
    corename ap_ctrl \
    op interface \
    ports { ap_start { I 1 bit } ap_ready { O 1 bit } ap_done { O 1 bit } ap_idle { O 1 bit } ap_continue { I 1 bit } } \
} "
}

# Direct connection:
if {${::AESL::PGuard_autoexp_gen}} {
eval "cg_default_interface_gen_dc { \
    id -2 \
    name ap_return \
    type ap_return \
    reset_level 1 \
    sync_rst true \
    corename ap_return \
    op interface \
    ports { ap_return { O 1 vector } } \
} "
}


# Adapter definition:
set PortName ap_clk
set DataWd 1 
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc cg_default_interface_gen_clock] == "cg_default_interface_gen_clock"} {
eval "cg_default_interface_gen_clock { \
    id -3 \
    name ${PortName} \
    reset_level 1 \
    sync_rst true \
    corename apif_ap_clk \
    data_wd ${DataWd} \
    op interface \
}"
} else {
puts "@W \[IMPL-113\] Cannot find bus interface model in the library. Ignored generation of bus interface for '${PortName}'"
}
}


# Adapter definition:
set PortName ap_rst
set DataWd 1 
if {${::AESL::PGuard_autoexp_gen}} {
if {[info proc cg_default_interface_gen_reset] == "cg_default_interface_gen_reset"} {
eval "cg_default_interface_gen_reset { \
    id -4 \
    name ${PortName} \
    reset_level 1 \
    sync_rst true \
    corename apif_ap_rst \
    data_wd ${DataWd} \
    op interface \
}"
} else {
puts "@W \[IMPL-114\] Cannot find bus interface model in the library. Ignored generation of bus interface for '${PortName}'"
}
}



# merge
if {${::AESL::PGuard_autoexp_gen}} {
    cg_default_interface_gen_dc_end
    cg_default_interface_gen_bundle_end
    AESL_LIB_XILADAPTER::native_axis_end
}


