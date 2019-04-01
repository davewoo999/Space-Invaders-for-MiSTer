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
		
		r				: out std_logic_vector(3 downto 0);
		g				: out std_logic_vector(3 downto 0);
		b				: out std_logic_vector(3 downto 0);
		hblnk		: out std_logic;
		vblnk		: out std_logic;
		hs				: out std_logic;
		vs				: out std_logic;
		
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
	
	signal RGB        : std_logic_vector(2 downto 0);
	signal hblank           : std_logic;
	signal vblank           : std_logic;

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

	signal DWHCnt          : unsigned(8 downto 0);
	signal DWVCnt          : unsigned(8 downto 0);
	signal Shift           : std_logic_vector(7 downto 0);
	signal vid_addr        : std_logic_vector(12 downto 0);
	signal vid_do          : std_logic;

	signal Overlay_G1      : boolean;
	signal Overlay_G2      : boolean;
	signal Overlay_G3      : boolean;
	signal Overlay_G4      : boolean;
	signal Overlay_G5      : boolean;
	signal Overlay_MS      : boolean;
	signal Overlay_G1_VCnt : boolean;
	
	signal rom_cs			: std_logic;
	signal spare			: std_logic := '0';
  --

begin

  I_RESET_L <= not I_RESET;
  
  process (clk_vid,I_RESET_L)
  begin
  		if I_RESET_L = '0' then
			DWHCnt  <= "111111111"; -- so its zero on first run
			DWVCnt  <= "000000000"; -- starts at 32 - first part of ram not used for video so vblank = 1
			hs <= '0';
			vs <= '1';
			hblank  <= '0';
			vblank  <= '1';

		elsif rising_edge(clk_vid) then
-- colour overlays
				DWHCnt <= DWHCnt + "1";
				if (DWHCnt = 17) then
					Overlay_G1 <= true;
				end if;
				if (DWHCnt = 25) then
					Overlay_G1 <= false;
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
				if (DWHCnt = 257) then -- should be 256 but misses top line when rotated
					hblank  <= '1';
				end if;
				if (DWHCnt = 328) then
					hs <= '1';
				end if;
				if (DWHCnt = 376) then 
					hs <= '0';
				end if;

				if (DWHCnt = 384) then -- 399
					DWVCnt <= DWVCnt + "1";
					hblank <= '0';
					DWHCnt <= "111111111";
				end if;
-- vertical
				if (DWVCnt = 15) then
					vs <= '1';
				end if;				
				if (DWVCnt = 17) then
					vs <= '0';
				end if;
				if (DWVCnt = 32) then
					vblank  <= '0';
				end if;				
				-- colour overlay for spare bases	
				if (DWVCnt = 54) then
					Overlay_G1_VCnt <= true;
				end if;
				if (DWVCnt = 144) then
					Overlay_G1_VCnt <= false;
				end if;
-- vertical blank and sync
				if (DWVCnt = 255) then 	
					vblank  <= '1';
				end if;	
--				if (DWVCnt = 256)then	
--					vs <= '1';
--				end if;
--				if (DWVCnt = 257)then	
--					vs <= '0';
--				end if;
				if (DWVCnt = 261)then 	
					DWVCnt <= "000000000";
				end if;	
		end if;
  end process;
  
  process (clk_vid,I_RESET_L)
  begin
		if I_RESET_L = '0' then
			vid_do <= '0';
			Shift <= (others => '0');		
  		elsif rising_edge(clk_vid) then
				if (vblank ='0'and hblank = '0') then
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
					RGB <= "000";
				else
					if Overlay_MS then
						RGB <= ms_col;
					elsif Overlay_G2 then
						RGB <= bs_col;
					elsif Overlay_G1 and Overlay_G1_VCnt then
						RGB <= bs_col;
					elsif Overlay_G3 then
						RGB <= sh_col;
					elsif Overlay_G4 then
						RGB <= sc2_col;
					elsif Overlay_G5 then
						RGB <= sc1_col;
					else
						RGB <= mn_col;
					end if;
				end if;			
		end if;
  end process;

		
  r 		<= (RGB(2) & RGB(2) & RGB(2) & RGB(2));
  g 		<= (RGB(1) & RGB(1) & RGB(1) & RGB(1));
  b 		<= (RGB(0) & RGB(0) & RGB(0) & RGB(0));
  hblnk	<= hblank;
  vblnk	<= vblank;

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
