# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

source $HDK_SHELL_DIR/build/scripts/params.tcl
source $HDK_SHELL_DIR/build/scripts/uram_options.tcl

set synth_options "-no_lc -shreg_min_size 10 -control_set_opt_threshold 16 $synth_uram_option"
set synth_directive "AlternateRoutability"

#Set psip to 1 to enable Physical Synthesis in Placer
set psip 0

set link 1

set opt 1
set opt_options    "-bufg_opt -control_set_merge -hier_fanout_limit 512 -muxf_remap -propconst -retarget -sweep"
set opt_directive  ""
set opt_preHookTcl  "$HDK_SHELL_DIR/build/scripts/check_uram.tcl"
set opt_postHookTcl "$HDK_SHELL_DIR/build/scripts/apply_debug_constraints.tcl"

set place 1
set place_options    ""
set place_directive  "ExtraNetDelay_high"
set place_preHookTcl ""
set place_postHookTcl ""

set phys_opt 1
set phys_options     ""
set phys_directive   "AggressiveExplore"
set phys_preHookTcl  ""
set phys_postHookTcl ""

set route 1
set route_options    ""
set route_directive  "Explore"
set route_preHookTcl ""
set route_postHookTcl ""

set route_phys_opt 1
set post_phys_options    ""
set post_phys_directive  ""
set post_phys_preHookTcl ""
set post_phys_postHookTcl ""


