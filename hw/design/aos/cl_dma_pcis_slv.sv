// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

// Used with modifications by Joshua Landgraf

module cl_dma_pcis_slv
(
    input aclk,
    input rst_n [2:0],
    
    input  SoftRegReq  sys_softreg_req[8:0],
    output SoftRegResp sys_softreg_resp[8:0],
    
    axi_bus_t.master cl_axi_dma_bus,
    axi_bus_t.master cl_axi_mstr_bus [3:0],
    
    axi_bus_t.slave lcl_cl_sh_ddra,
    axi_bus_t.slave lcl_cl_sh_ddrb,
    axi_bus_t.slave lcl_cl_sh_ddrd,
    
    axi_bus_t.slave cl_sh_ddr_bus
);

//----------------------------
// Internal signals
//----------------------------

axi_bus_t cl_axi_bus_rs1 [4:1] ();
axi_bus_t cl_axi_bus_rs2 [4:1] ();
axi_bus_t cl_axi_bus_phys0 [4:0] ();
axi_bus_t cl_axi_bus_phys1 [4:0] ();

axi_bus_t cl_sh_ddr_q  [3:0]();
axi_bus_t cl_sh_ddr_q2 [3:0]();
axi_bus_t cl_sh_ddr_q3 [3:0]();

//----------------------------
// End Internal signals
//----------------------------

cy_stripe #(
    .INIT_MODE(0),
    .SR_ADDR('h18)
) cy_str (
    .clk(aclk),
    .rst(!rst_n[1]),
    
    .sr_req(sys_softreg_req[8]),
    
    .phys_m(cl_axi_dma_bus),
    .phys_s(cl_axi_bus_phys0[0])
);

genvar g;
for (g = 1; g < 5; g = g + 1) begin: gen_ar
	axi_reg ar1 (
		.clk(aclk),
		.rst_n(rst_n[1]),
		
		.axi_s(cl_axi_mstr_bus[g-1]),
		.axi_m(cl_axi_bus_rs1[g])
	);
end

for (g = 1; g < 5; g = g + 1) begin: gen_ab
	axi_buf ab (
		.clk(aclk),
		.rst(!rst_n[1]),
		
		.axi_s(cl_axi_bus_rs1[g]),
		.axi_m(cl_axi_bus_rs2[g])
	);
end

for (g = 1; g < 5; g = g + 1) begin: gen_vm
    //----------------------------
    // axi address translation modules
    //----------------------------
    axi_bus_t cl_axi_bus_mux0 [4:1] ();
    axi_bus_t cl_axi_bus_mux1 [4:1] ();
    axi_bus_t cl_axi_bus_mux2 [4:1] ();
    axi_bus_t cl_axi_bus_mux3 [4:1] ();
    axi_bus_t cl_axi_bus_mux4 [4:1] ();
    axi_bus_t cl_axi_bus_mux5 [4:1] ();
    axi_bus_t cl_axi_bus_mux6 [4:1] ();
    axi_bus_t cl_axi_bus_mux7 [4:1] ();
    axi_bus_t cl_axi_bus_mux8 [4:1] ();
    axi_bus_t cl_axi_bus_mux9 [4:1] ();
    axi_bus_t cl_axi_bus_mux10 [4:1] ();
    axi_bus_t cl_axi_bus_mux11 [4:1] ();
    
    axi_mux_2s #(
        .SR_ADDR('h10)
    ) mux0_0 (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1]),
        
        .axi_m(cl_axi_bus_rs2[g]),
        .axi_s0(cl_axi_bus_mux0[g]),
        .axi_s1(cl_axi_bus_mux1[g])
    );
    
	axi_reg phys_reg (
		.clk(aclk),
		.rst_n(rst_n[1]),
        
		.axi_s(cl_axi_bus_mux0[g]),
		.axi_m(cl_axi_bus_mux7[g])
	);

    axi_mux_2s #(
        .SR_ADDR('h18)
    ) mux1_0 (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1]),
        
        .axi_m(cl_axi_bus_mux1[g]),
        .axi_s0(cl_axi_bus_mux2[g]),
        .axi_s1(cl_axi_bus_mux3[g])
    );

    cy_tlb cytlb (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1+4]),
        .sr_resp(sys_softreg_resp[g-1+4]),
        
        .virt_m(cl_axi_bus_mux2[g]),
        .phys_s(cl_axi_bus_mux4[g])
    );
    
    axi_mux_2s #(
        .SR_ADDR('h20)
    ) mux2_0 (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1]),
        
        .axi_m(cl_axi_bus_mux4[g]),
        .axi_s0(cl_axi_bus_mux8[g]),
        .axi_s1(cl_axi_bus_mux10[g])
    );
    
    aos_axi aaxi (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .axi_m(cl_axi_bus_mux8[g]),
        .axi_s(cl_axi_bus_mux9[g])
    );
    
    axi_mux_2m #(
        .SR_ADDR('h20)
    ) mux2_1 (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1]),
        
        .axi_m0(cl_axi_bus_mux9[g]),
        .axi_m1(cl_axi_bus_mux10[g]),
        .axi_s(cl_axi_bus_mux11[g])
    );

    axi_tlb #(
        .SR_ID(g-1)
    ) atlb (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1]),
        .sr_resp(sys_softreg_resp[g-1]),
        
        .virt_m(cl_axi_bus_mux3[g]),
        .phys_s(cl_axi_bus_mux5[g])
    );

    axi_mux_2m #(
        .SR_ADDR('h18)
    ) mux1_1 (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1]),
        
        .axi_m0(cl_axi_bus_mux11[g]),
        .axi_m1(cl_axi_bus_mux5[g]),
        .axi_s(cl_axi_bus_mux6[g])
    );

    axi_mux_2m #(
        .SR_ADDR('h10)
    ) mux0_1 (
        .clk(aclk),
        .rst(!rst_n[1]),
        
        .sr_req(sys_softreg_req[g-1]),
        
        .axi_m0(cl_axi_bus_mux7[g]),
        .axi_m1(cl_axi_bus_mux6[g]),
        .axi_s(cl_axi_bus_phys0[g])
    );
end

for (g = 0; g < 5; g = g + 1) begin: gen_pr
	axi_reg phys_reg (
		.clk(aclk),
		.rst_n(rst_n[1]),
		
		.axi_s(cl_axi_bus_phys0[g]),
		.axi_m(cl_axi_bus_phys1[g])
	);
end


//----------------------------
// axi interconnect for DDR address decodes
//----------------------------
axi_xbar ax (
	.clk(aclk),
	.rst(!rst_n[1]),
	
	.axi_s(cl_axi_bus_phys1),
	.axi_m(cl_sh_ddr_q)
);


//----------------------------
// flop the output of interconnect for DDRC
//----------------------------
axi_reg ddrc_src_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q[2]),
	.axi_m(cl_sh_ddr_q2[2])
);

axi_reg ddrc_mid_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q2[2]),
	.axi_m(cl_sh_ddr_q3[2])
);

axi_reg ddrc_dst_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q3[2]),
	.axi_m(cl_sh_ddr_bus)
);


//----------------------------
// flop the output of interconnect for DDRA
// back to back for SLR crossing
//----------------------------
axi_reg ddra_src_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q[0]),
	.axi_m(cl_sh_ddr_q2[0])
);

axi_reg ddra_mid_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q2[0]),
	.axi_m(cl_sh_ddr_q3[0])
);

axi_reg ddra_dst_reg (
	.clk(aclk),
	.rst_n(rst_n[2]),
	
	.axi_s(cl_sh_ddr_q3[0]),
	.axi_m(lcl_cl_sh_ddra)
);


//----------------------------
// flop the output of interconnect for DDRB
// back to back for SLR crossing
//----------------------------
axi_reg ddrb_src_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q[1]),
	.axi_m(cl_sh_ddr_q2[1])
);

axi_reg ddrb_mid_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q2[1]),
	.axi_m(cl_sh_ddr_q3[1])
);

axi_reg ddrb_dst_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q3[1]),
	.axi_m(lcl_cl_sh_ddrb)
);


//----------------------------
// flop the output of interconnect for DDRD
// back to back for SLR crossing
//----------------------------
axi_reg ddrd_src_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q[3]),
	.axi_m(cl_sh_ddr_q2[3])
);

axi_reg ddrd_mid_reg (
	.clk(aclk),
	.rst_n(rst_n[1]),
	
	.axi_s(cl_sh_ddr_q2[3]),
	.axi_m(cl_sh_ddr_q3[3])
);

axi_reg ddrd_dst_reg (
	.clk(aclk),
	.rst_n(rst_n[0]),
	
	.axi_s(cl_sh_ddr_q3[3]),
	.axi_m(lcl_cl_sh_ddrd)
);


endmodule

