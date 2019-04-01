//============================================================================
//  Arcade: Sinistar
//
//  Port to MiSTer
//  Copyright (C) 2018 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S    // 1 - signed audio samples, 0 - unsigned
);

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : status[2] ? 8'd4 : 8'd1;
assign HDMI_ARY = status[1] ? 8'd9  : status[2] ? 8'd3 : 8'd1;

`include "build_id.v" 
localparam CONF_STR = {
	"A.INVADERS;;",
	"-;",
	"O1,Aspect Ratio,Original,Wide;", 
	"O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",  
	"-;",
	"O6,Display Coin Info,ON,OFF;",
//	"O6,Bonus Base,1500pts,1000pts;", // This can only be set before game start - change freezes play and no reset - could add code to reset on change??
	"O78,Bases,3,4,5,6;",
	"-;",
	"O9A,Colours,Original,colour1,colour2,colour3;",
	"-;",
	"T6,Reset;",
	"J,Fire,Start 1P,Start 2P;",
	"V,v2.00.",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_6, clk_12, clk_10;



pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_12),
	.outclk_2(clk_10),
	.outclk_3(clk_6)
);

reg ce_12, ce_6, ce_3, ce_1p5;
always @(posedge clk_sys) begin
	reg [3:0] div;
	
	div <= div + 1'd1;
	ce_12  <= !div[0:0];
	ce_6   <= !div[1:0];
	ce_3   <= !div[2:0];
	ce_1p5 <= !div[3:0];
end

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;

wire [15:0] joy_0, joy_1;
wire [15:0] joya;
wire        forced_scandoubler;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.joystick_analog_0(joya),
	.ps2_key(ps2_key)
);

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'h029: btn_fire         <= pressed; // space
			'h005: btn_one_player   <= pressed; // F1
			'h006: btn_two_players  <= pressed; // F2
			'hX6B: btn_left      	<= pressed; // left arrow
			'hX74: btn_right      	<= pressed; // right arrow
			'h004: btn_coin  			<= pressed; // F3
		endcase
	end
end

always @(posedge clk_sys) begin
	case(status[10:9])
		2'b00: begin
					ms_col	<= 3'b100;
					bs_col	<= 3'b010;
					sh_col	<= 3'b010;
					sc1_col	<= 3'b111;
					sc2_col	<= 3'b111;
					mn_col	<= 3'b111;
				 end
		2'b01: begin
					ms_col	<= 3'b100;
					bs_col	<= 3'b010;
					sh_col	<= 3'b110;
					sc1_col	<= 3'b011;
					sc2_col	<= 3'b101;
					mn_col	<= 3'b111;
				 end
		2'b10: begin
					ms_col	<= 3'b110;
					bs_col	<= 3'b001;
					sh_col	<= 3'b101;
					sc1_col	<= 3'b100;
					sc2_col	<= 3'b100;
					mn_col	<= 3'b111;
				 end
		2'b11: begin
					ms_col	<= 3'b101;
					bs_col	<= 3'b011;
					sh_col	<= 3'b001;
					sc1_col	<= 3'b110;
					sc2_col	<= 3'b100;
					mn_col	<= 3'b010;
				 end
	endcase
end

reg btn_right = 0;
reg btn_left = 0;
reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_fire = 0;
reg btn_coin = 0;

wire [2:0] ms_col;
wire [2:0] bs_col;
wire [2:0] sh_col;
wire [2:0] sc1_col;
wire [2:0] sc2_col;
wire [2:0] mn_col;

wire [15:0] joy = joy_0 | joy_1;


///////////////////////////////////////////////////////////////////


wire hblank, vblank;
wire hs, vs;
wire [3:0] r,g,b;

arcade_rotate_fx #(260,224,12,1) arcade_video
(
	.*,

	.clk_video(clk_sys),
	.ce_pix(ce_6),

	.RGB_in({r,g,b}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),
	
	.fx(status[5:3]),
	.forced_scandoubler(1'b0),
	.no_rotate(status[2])
);


reg info = 0;
reg bonus = 0;
reg newbonus = 0;
reg [1:0] bases = 2'b0;
assign info = status[6];
assign newbonus = 0;
assign bases = status[8:7];
wire [7:0] audio;
assign AUDIO_L = {audio, audio};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;
wire reset;
assign reset = (RESET | status[0] | status[6] | buttons[1] | ioctl_download);

invaders_top invaders_top
(

	.Clk(clk_10),
	.Clk_mem(clk_sys),
	.clk_vid(clk_6),

	.I_RESET(reset),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),

	.r(r),
	.g(g),
	.b(b),
	.hblnk(hblank),
	.vblnk(vblank),
	.hs(hs),
	.vs(vs),
	
	.audio_out(audio),
	.ms_col(ms_col),
	.bs_col(bs_col),
	.sh_col(sh_col),
	.sc1_col(sc1_col),
	.sc2_col(sc2_col),
	.mn_col(mn_col),
	.info(info),
	.bonus(bonus),
	.newbonus(newbonus),
	.bases(bases),
	.btn_coin(btn_coin | joy[5] | joy[6] | btn_one_player | btn_two_players),
	.btn_one_player(btn_one_player | joy[5]),
	.btn_two_player(btn_two_players | joy[6]),

	.btn_fire(btn_fire | joy[4]),
	.btn_right(btn_right | joy[0]),
	.btn_left(btn_left | joy[1])

);

endmodule
