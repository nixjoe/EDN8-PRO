
`include "../base/defs.v"

module map_213
(map_out, bus, sys_cfg, ss_ctrl); //no mapper

	`include "../base/bus_in.v"
	`include "../base/map_out.v"
	`include "../base/sys_cfg_in.v"
	`include "../base/ss_ctrl_in.v"
	
	output [`BW_MAP_OUT-1:0]map_out;
	input [`BW_SYS_CFG-1:0]sys_cfg;
	
	
	assign sync_m2 = 1;
	assign mir_4sc = 0;//enable support for 4-screen mirroring. for activation should be ensabled in sys_cfg also
	assign srm_addr[12:0] = cpu_addr[12:0];
	assign prg_oe = cpu_rw;
	assign chr_oe = !ppu_oe;
	//*************************************************************  save state setup
	assign ss_rdat[7:0] =  
	ss_addr[7:0] == 0 ? {prg_bank[2:0], chr_bank[2:0], mirror, 1'd0} : 
	ss_addr[7:0] == 127 ? map_idx : 8'hff;
	//*************************************************************

	assign ram_we = !cpu_rw & ram_ce;
	assign ram_ce = 0;//cpu_addr[14:13] == 2'b11 & cpu_ce & m2;
	assign rom_ce = !cpu_ce;
	assign chr_ce = ciram_ce;
	assign chr_we = cfg_chr_ram ? !ppu_we & ciram_ce : 0;//if cfg_chr_ram == 1 means that we don't have CHR rom, only CHR ram
	
	//A10-Vmir, A11-Hmir
	assign ciram_a10 = !mirror ? ppu_addr[10] : ppu_addr[11];
	assign ciram_ce = !ppu_addr[13];
	
	assign prg_addr[13:0] = cpu_addr[13:0];
	assign prg_addr[16:14] = {prg_bank[2:1], cpu_addr[14]};//!cpu_addr[6] ? {prg_bank[2:1], cpu_addr[14]} : prg_bank[2:0];
	
	assign chr_addr[12:0] = ppu_addr[12:0];
	assign chr_addr[15:13] = chr_bank[2:0];
	
	reg [2:0]prg_bank;
	reg [2:0]chr_bank;
	reg mirror;
	
	always @(negedge m2)
	if(ss_act)
	begin
		if(ss_we & ss_addr[7:0] == 0) {prg_bank[2:0], chr_bank[2:0], mirror} <= cpu_dat[7:1];
	end
	else
	begin
		if(map_rst) begin
			prg_bank <= {2'b11, cpu_addr[14]};
		end
		
		if(!cpu_ce & !cpu_rw) begin
			
			prg_bank[2:0] <= cpu_addr[2:0];
			chr_bank[2:0] <= cpu_addr[5:3];
			mirror <= cpu_addr[0] ^ cpu_addr[6];
			
		end
	end
	
endmodule
