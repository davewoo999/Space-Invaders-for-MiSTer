-- Space Invaders top level for
-- ps/2 keyboard interface with sound and scan doubler MikeJ
--
-- Version : 0300
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--      0241 : First release
--
--      0242 : added the ROM from mw8080.vhd
--
--      0300 : MikeJ tidy up for audio release

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity invaders_top is
	port(
		Clk					: in std_logic;
		Clk_mem				: in std_logic;
		clk_vid				: in std_logic;
		I_RESET				: in std_logic;
		
		dn_addr          	: in std_logic_vector(15 downto 0);
		dn_data         	: in std_logic_vector(7 downto 0);
		dn_wr					: in std_logic;
		
		hdmi_r				: out std_logic_vector(2 downto 0);
		hdmi_g				: out std_logic_vector(2 downto 0);
		hdmi_b				: out std_logic_vector(2 downto 0);
		hdmi_hblnk		: out std_logic;
		hdmi_vblnk		: out std_logic;
		hdmi_hs				: out std_logic;
		hdmi_vs				: out std_logic;
		
		vga_r						: out std_logic_vector(7 downto 0);
		vga_g						: out std_logic_vector(7 downto 0);
		vga_b						: out std_logic_vector(7 downto 0);

		vga_hs						: out std_logic;
		vga_vs						: out std_logic;	
		vga_hb						: out std_logic;
		vga_vb						: out std_logic;
		
		audio_out			: out std_logic_vector(7 downto 0);
		ms_col				: in std_logic_vector(2 downto 0);
		bs_col				: in std_logic_vector(2 downto 0);
		sh_col				: in std_logic_vector(2 downto 0);
		sc1_col				: in std_logic_vector(2 downto 0);
		sc2_col				: in std_logic_vector(2 downto 0);
		mn_col				: in std_logic_vector(2 downto 0);
		info					: in std_logic;
		bonus					: in std_logic;
		newbonus				: in std_logic;
		bases					: in std_logic_vector(1 downto 0);
		
		btn_coin				: in std_logic;
		btn_one_player		: in std_logic;
		btn_two_player		: in std_logic;
		btn_fire				: in std_logic;
		btn_right			: in std_logic;
		btn_left				: in std_logic

		--

		--
		);
end invaders_top;

architecture rtl of invaders_top is

	signal I_RESET_L       : std_logic;
	signal Rst_n_s         : std_logic;

	signal DIP             : std_logic_vector(8 downto 1);
	signal RWE_n           : std_logic;
	signal Video           : std_logic;
	signal HSync           : std_logic;
	signal VSync           : std_logic;
	
	signal hdmi_RGB        : std_logic_vector(2 downto 0);
	signal vga_RGB     	   : std_logic_vector(2 downto 0);
	signal HSync_X2        : std_logic;
	signal VSync_X2        : std_logic;

	signal cpu_addr        : std_logic_vector(15 downto 0);
	signal ram_addr        : std_logic_vector(12 downto 0);
	signal ram_do          : std_logic_vector(7 downto 0);
	signal ram2_do         : std_logic_vector(7 downto 0);
	signal ram_di          : std_logic_vector(7 downto 0);
	signal rom_do          : std_logic_vector(7 downto 0);
	signal SoundCtrl3      : std_logic_vector(5 downto 0);
	signal SoundCtrl5      : std_logic_vector(5 downto 0);


--	signal Tick1us         : std_logic;

	signal Reset           : std_logic;
   signal reset_counter   : unsigned(23 downto 0);
	signal rom_data_0      : std_logic_vector(7 downto 0);
	signal rom_data_1      : std_logic_vector(7 downto 0);
	signal rom_data_2      : std_logic_vector(7 downto 0);
	signal rom_data_3      : std_logic_vector(7 downto 0);
	signal ram_we          : std_logic;
	--
	signal HCnt            : std_logic_vector(11 downto 0);
	signal VCnt            : std_logic_vector(11 downto 0);
	signal DWHCnt          : unsigned(9 downto 0);
	signal DWVCnt          : unsigned(9 downto 0);
	signal Shift           : std_logic_vector(7 downto 0);
	signal vid_addr        : std_logic_vector(12 downto 0);
	signal vid_do          : std_logic;
	signal HSync_t1        : std_logic;
	signal hdmi_vblank     : std_logic;
	signal hdmi_hblank     : std_logic;
	signal vga_vblank      : std_logic;
	signal vga_hblank      : std_logic;
	signal dwhsync         : std_logic;
	signal dwvsync         : std_logic;
	signal Overlay_G1      : boolean;
	signal Overlay_G2      : boolean;
	signal Overlay_G3      : boolean;
	signal Overlay_G4      : boolean;
	signal Overlay_G5      : boolean;
	signal Overlay_MS      : boolean;
	signal Overlay_G1_VCnt : boolean;
	
	signal rom_cs			: std_logic;
--	signal bonus			: std_logic := '0';
  --

begin

  I_RESET_L <= not I_RESET;
  
  process (clk_vid,I_RESET_L)
  begin
  		if I_RESET_L = '0' then
			DWHCnt  <= "1111111111"; -- so its zero on first run
			DWVCnt  <= "0000100000"; -- starts at 32 - first part of ram not used for video
			dwhsync <= '0';
			dwvsync <= '0';
			hdmi_hblank  <= '0';
			hdmi_vblank  <= '0';
			vga_hblank  <= '0';
			vga_vblank  <= '0';
		elsif clk_vid'event and clk_vid = '1' then
-- colour overlays
				DWHCnt <= DWHCnt + "1";
				if (DWHCnt = 17) then
					Overlay_G1 <= true;
				end if;
				if (DWHCnt = 25) then
					Overlay_G1 <= false;
				end if;
				if (DWHCnt = 25) then
					Overlay_G2 <= true;
				end if;
				if (DWHCnt = 49) then
					Overlay_G2 <= false;
				end if;
				if (DWHCnt = 56) then
					Overlay_G3 <= true;
				end if;
				if (DWHCnt = 73) then
					Overlay_G3 <= false;
				end if;
				if (DWHCnt = 216) then
					Overlay_MS <= true;
				end if;
				if (DWHCnt = 231) then
					Overlay_MS <= false;
				end if;
				if (DWHCnt = 232) then
					Overlay_G4 <= true;
				end if;
				if (DWHCnt = 240) then
					Overlay_G4 <= false;
				end if;
				if (DWHCnt = 242) then
					Overlay_G5 <= true;
				end if;
				if (DWHCnt = 256) then
					Overlay_G5 <= false;
				end if;
-- horizontal blank and sync
				if (DWHCnt = 258) then -- should be 256 but misses top line when rotated
					hdmi_hblank  <= '1';
				end if;
				if (DWHCnt = 320) then
					vga_hblank  <= '1';
				end if;
				if (DWHCnt = 328) then
					dwhsync <= '1';
				end if;
				if (DWHCnt = 376) then 
					dwhsync <= '0';
				end if;

				if (DWHCnt = 400) then 
					DWVCnt <= DWVCnt + "1";
					hdmi_hblank <= '0';
					vga_hblank <= '0';
					DWHCnt <= "1111111111";
				end if;
-- colour overlay for spare bases	
				if (DWVCnt = 54) then
					Overlay_G1_VCnt <= true;
				end if;
				if (DWVCnt = 144) then
					Overlay_G1_VCnt <= false;
				end if;
-- vertical blank and sync
				if (DWVCnt = 256) then 	
					hdmi_vblank  <= '1';
				end if;	
				if (DWVCnt = 272) then 	
					vga_vblank  <= '1';
				end if;
				if (DWVCnt = 277)then	
					dwvsync <= '1';
				end if;
				if (DWVCnt = 278)then	
					dwvsync <= '0';
				end if;
				if (DWVCnt = 294)then 	
					hdmi_vblank <= '0';
					vga_vblank <= '0';
					DWVCnt <= "0000100000";
				end if;					
			
		end if;
  end process;
  
  process (clk_vid,I_RESET_L)
  begin
		if I_RESET_L = '0' then
			vid_do <= '0';
			Shift <= (others => '0');		
  		elsif clk_vid'event and clk_vid = '1' then
				if (hdmi_vblank ='0'and hdmi_hblank = '0') then
					if (DWHCnt(2 downto 0) = "000") then 			
						vid_addr <= std_logic_vector(DWVCnt(7 downto 0) & DWHCnt(7 downto 3));
						Shift(7 downto 0) <= ram2_do(7 downto 0); 
					else														
						Shift(6 downto 0) <= Shift(7 downto 1);	
						Shift(7) <= '0';									
					end if;													
					vid_do <= Shift(0);									
				end if;
				if (vid_do = '0') then
					hdmi_RGB <= "000";
					vga_RGB <= "000";
				else
					if Overlay_MS then
						hdmi_RGB <= ms_col;
						vga_RGB <= ms_col;
					elsif Overlay_G2 then
						hdmi_RGB <= bs_col;
						vga_RGB <= bs_col;
					elsif Overlay_G1 and Overlay_G1_VCnt then
						hdmi_RGB <= bs_col;
						vga_RGB <= bs_col;
					elsif Overlay_G3 then
						hdmi_RGB <= sh_col;
						vga_RGB <= sh_col;
					elsif Overlay_G4 then
						hdmi_RGB <= sc2_col;
						vga_RGB <= sc2_col;
					elsif Overlay_G5 then
						hdmi_RGB <= sc1_col;
						vga_RGB <= sc1_col;
					else
						hdmi_RGB <= mn_col;
						vga_RGB <= mn_col;
					end if;
				end if;			
		end if;
  end process;

		
  hdmi_r 		<= (hdmi_RGB(2) & hdmi_RGB(2) & hdmi_RGB(2));
  hdmi_g 		<= (hdmi_RGB(1) & hdmi_RGB(1) & hdmi_RGB(1));
  hdmi_b 		<= (hdmi_RGB(0) & hdmi_RGB(0) & hdmi_RGB(0));
  hdmi_hs 		<=  dwhsync;
  hdmi_vs 		<=  dwvsync;
  hdmi_hblnk	<= hdmi_hblank;
  hdmi_vblnk 	<= hdmi_vblank;
  
  vga_r 		<= (vga_RGB(2) & vga_RGB(2) & vga_RGB(2) & vga_RGB(2) & vga_RGB(2) & vga_RGB(2) & vga_RGB(2) & vga_RGB(2));
  vga_g 		<= (vga_RGB(1) & vga_RGB(1) & vga_RGB(1) & vga_RGB(1) & vga_RGB(1) & vga_RGB(1) & vga_RGB(1) & vga_RGB(1));
  vga_b 		<= (vga_RGB(0) & vga_RGB(0) & vga_RGB(0) & vga_RGB(0) & vga_RGB(0) & vga_RGB(0) & vga_RGB(0) & vga_RGB(0));
  vga_hs 		<=  dwhsync;
  vga_vs 		<=  dwvsync;
  vga_hb 		<=  vga_hblank;
  vga_vb		<=  vga_vblank;


  --

	DIP(8 downto 5) <= "1111";
	DIP(1) <= info;
	DIP(2) <= bonus;
	DIP(3) <= bases(1);
	DIP(4) <= bases(0);
	

	core : entity work.invaders
		port map(
			Rst_n      => I_RESET_L,
			Clk        => Clk,
			MoveLeft   => btn_left,
			MoveRight  => btn_right,
			Coin       => btn_coin,
			Sel1Player => btn_one_player,
			Sel2Player => btn_two_player,
			Fire       => btn_fire,
			DIP        => DIP,
			ram_do     => ram_do,
			rom_do     => rom_do,
			ram_di     => ram_di,
			ram_addr   => ram_addr,
			cpu_addr   => cpu_addr,
			SoundCtrl3 => SoundCtrl3,
			SoundCtrl5 => SoundCtrl5,
			Rst_n_s    => Rst_n_s,
			RWE_n      => RWE_n,
			Video      => Video,
			HSync      => HSync,
			VSync      => VSync
			);
	--
	-- ROM
	--
	
rom_cs  <= '1' when dn_addr(15 downto 8) < X"20"     else '0';

cpu_prog_rom : work.dpram generic map (13,8)
port map
(
	clock_a   => Clk_mem,
	wren_a    => dn_wr and rom_cs,
	address_a => dn_addr(12 downto 0),
	data_a    => dn_data,

	clock_b   => Clk,
	address_b => cpu_addr(12 downto 0),
	q_b       => rom_do
);	
	
	--
	-- SRAM
	--

cpu_video_ram : work.dpram generic map (13,8)
port map
(
	clock_a   => Clk,
	wren_a    => ram_we,
	address_a => ram_addr,
	data_a    => ram_di,
	q_a		 => ram_do,

	clock_b   => clk_vid,
	address_b => vid_addr(12 downto 0),
	q_b       => ram2_do
);		
	
	ram_we <= not RWE_n;

  --
  -- Audio
  --
  u_audio : entity work.invaders_audio
	port map (
	  Clk => Clk,
	  P3  => SoundCtrl3,
	  P5  => SoundCtrl5,
	  Aud => audio_out
	  );

end;
