library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity VGAImage is
	port(
		SCL: in STD_LOGIC;
		SEG1_EN: out STD_LOGIC;
		SEG2_EN: out STD_LOGIC;
		SEG3_EN: out STD_LOGIC;
		SEG1: out STD_LOGIC_VECTOR(7 DOWNTO 0);
		LED: out STD_LOGIC_VECTOR(7 DOWNTO 0);
		ROWS: out STD_LOGIC_VECTOR(3 DOWNTO 0);
		COLS: in STD_LOGIC_VECTOR(3 DOWNTO 0);
		hsync: out std_logic;
		vsync: out std_logic;
		red: out std_logic_vector(2 downto 0);
		green: out std_logic_vector(2 downto 0);
		blue: out std_logic_vector(2 downto 1)
	);
end VGAImage;

architecture Behavioral of VGAImage is

component VGAImagePLL is
  port ( CLKIN_IN: in STD_LOGIC;
         CLKFX_OUT: out STD_LOGIC;
			CLKIN_IBUFG_OUT: out STD_LOGIC;
			CLK0_OUT: out STD_LOGIC;
			LOCKED_OUT: out STD_LOGIC);
end component;

--new boosted clock
signal SCL_PLL: STD_LOGIC;

--vga variables
signal fporch_hor: integer := 16; -- 16 cycles
signal sync_hor: integer := 96; -- 96 cycles
signal bporch_hor: integer := 48; -- 48 cycles
signal fporch_ver: integer := 10; -- 10 cycles
signal sync_ver: integer := 2; -- 2 cycles
signal bporch_ver: integer := 33; -- 33 cycles
signal x: integer := 0;
signal y: integer := 0;
signal color: STD_LOGIC_VECTOR(7 DOWNTO 0);

--segment screen data
signal S1: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"FF";

--leds
signal L: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";

--keys
signal R: STD_LOGIC_VECTOR(3 DOWNTO 0) := x"F";
signal C: STD_LOGIC_VECTOR(3 DOWNTO 0) := x"F";
signal KEY: integer := 0;
signal KEYP: integer := 0;
signal COUNTER: integer := 0;

--player
signal PLAYER: STD_LOGIC := '0';

--fieldmap
signal FIELD_MAP_PLUS: STD_LOGIC_VECTOR(8 DOWNTO 0) := b"000000000";
signal FIELD_MAP_MINUS: STD_LOGIC_VECTOR(8 DOWNTO 0) := b"000000000";

--dot, c, b, a, g, f, e, d
--this function convert int to vector for segment screen
function INT_TO_VECTOR(X : INTEGER) return STD_LOGIC_VECTOR is
begin
  if X = 0 then
    return b"10001000";
  elsif X = 1 then
    return b"10011111";
  elsif X = 2 then
    return b"11000100";
  elsif X = 3 then
    return b"10000110";
  elsif X = 4 then
    return b"10010011";
  elsif X = 5 then
    return b"10100010";
  elsif X = 6 then
    return b"10100000";
  elsif X = 7 then
    return b"10001111";
  elsif X = 9 then
    return b"10000010";
  elsif X = 8 then
	 return b"10000000";
  elsif X = 10 then
	 return b"10000001";
  elsif X = 11 then
	 return b"10110000";
  elsif X = 12 then
	 return b"11101000";
  elsif X = 13 then
	 return b"10010100";
  else
    return b"11111111";
  end if;
end INT_TO_VECTOR;

--this function draw field and player
function DRAW_FIELD(X : INTEGER; Y: INTEGER) return STD_LOGIC_VECTOR is

	variable color_inside: STD_LOGIC_VECTOR(7 DOWNTO 0) := b"00000010";

begin
	
	--draw vertical line
	if (x > 200 and x < 220) or (x > 420 and x < 440) then
		color_inside := b"00011111";
	end if;
	
	--draw horizontal line
	if (y > 140 and y < 160) or (y > 300 and y < 320) then
		color_inside := b"00011111";
	end if;
	
	--plus for 1
	if FIELD_MAP_PLUS(0) = '1' then
		
		if(x > 90 and x < 110) and (y > 20 and y < 120) then
			color_inside := b"11100000";
		end if;
		if(y > 60 and y < 80) and (x > 40 and x < 160) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 2
	if FIELD_MAP_PLUS(1) = '1' then
		
		if(x > 310 and x < 330) and (y > 20 and y < 120) then
			color_inside := b"11100000";
		end if;
		if(y > 60 and y < 80) and (x < 380 and x > 260) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 3
	if FIELD_MAP_PLUS(2) = '1' then
		
		if(x > 530 and x < 550) and (y > 20 and y < 120) then
			color_inside := b"11100000";
		end if;
		if(y > 60 and y < 80) and (x < 600 and x > 480) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 4
	if FIELD_MAP_PLUS(3) = '1' then
		
		if(x > 90 and x < 110) and (y < 280 and y > 180) then
			color_inside := b"11100000";
		end if;
		if(y > 220 and y < 240) and (x < 160 and x > 40) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 5
	if FIELD_MAP_PLUS(4) = '1' then
		
		if(x > 310 and x < 330) and (y < 280 and y > 180) then
			color_inside := b"11100000";
		end if;
		if(y > 220 and y < 240) and (x < 380 and x > 260) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 6
	if FIELD_MAP_PLUS(5) = '1' then
		
		if(x > 530 and x < 550) and (y < 280 and y > 180) then
			color_inside := b"11100000";
		end if;
		if(y > 220 and y < 240) and (x < 600 and x > 480) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 7
	if FIELD_MAP_PLUS(6) = '1' then
		
		if(x > 90 and x < 110) and (y < 460 and y > 340) then
			color_inside := b"11100000";
		end if;
		if(y > 390 and y < 410) and (x < 160 and x > 40) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 8
	if FIELD_MAP_PLUS(7) = '1' then
		
		if(x > 310 and x < 330) and (y < 460 and y > 340) then
			color_inside := b"11100000";
		end if;
		if(y > 390 and y < 410) and (x < 380 and x > 260) then
			color_inside := b"11100000";
		end if;
		
	end if;
	--plus for 9
	if FIELD_MAP_PLUS(8) = '1' then
		
		if(x > 530 and x < 550) and (y < 460 and y > 340) then
			color_inside := b"11100000";
		end if;
		if(y > 390 and y < 410) and (x < 600 and x > 480) then
			color_inside := b"11100000";
		end if;
		
	end if;
	
	--minus for 1
	if FIELD_MAP_MINUS(0) = '1' then
		
		if(y > 60 and y < 80) and (x > 40 and x < 160) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 2
	if FIELD_MAP_MINUS(1) = '1' then
		
		if(y > 60 and y < 80) and (x < 380 and x > 260) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 3
	if FIELD_MAP_MINUS(2) = '1' then
		
		if(y > 60 and y < 80) and (x < 600 and x > 480) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 4
	if FIELD_MAP_MINUS(3) = '1' then
		
		if(y > 220 and y < 240) and (x < 160 and x > 40) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 5
	if FIELD_MAP_MINUS(4) = '1' then
		
		if(y > 220 and y < 240) and (x < 380 and x > 260) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 6
	if FIELD_MAP_MINUS(5) = '1' then
		
		if(y > 220 and y < 240) and (x < 600 and x > 480) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 7
	if FIELD_MAP_MINUS(6) = '1' then
		
		if(y > 390 and y < 410) and (x < 160 and x > 40) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 8
	if FIELD_MAP_MINUS(7) = '1' then
		
		if(y > 390 and y < 410) and (x < 380 and x > 260) then
			color_inside := b"00011100";
		end if;
		
	end if;
	--minus for 9
	if FIELD_MAP_MINUS(8) = '1' then
		
		if(y > 390 and y < 410) and (x < 600 and x > 480) then
			color_inside := b"00011100";
		end if;
		
	end if;
	
	return color_inside;
end DRAW_FIELD;

begin

vga_pll: VGAImagePLL port map(CLKIN_IN => SCL, CLKFX_OUT => SCL_PLL);

--keyboard proccess
process(SCL_PLL)
begin
if rising_edge(SCL_PLL) then

	COUNTER <= COUNTER + 1;

	--CATCH KEY
	--set LOW first row
	if COUNTER < 12000*10 then
		R <= b"1111";
		R <= b"1110";
		if C(0) = '0' and R(0) = '0' then
		KEY <= 1;
		elsif C(1) = '0' and R(0) = '0' then
		KEY <= 2;
		elsif C(2) = '0' and R(0) = '0' then
		KEY <= 3;
		elsif C(3) = '0' and R(0) = '0' then
		KEY <= 10;
		end if;

	--set LOW second row
	elsif COUNTER < 12000*20 then
		R <= b"1111";
		R <= b"1101";
		if C(0) = '0' and R(1) = '0' then
		KEY <= 4;
		elsif C(1) = '0' and R(1) = '0' then
		KEY <= 5;
		elsif C(2) = '0' and R(1) = '0' then
		KEY <= 6;
		elsif C(3) = '0' and R(1) = '0' then
		KEY <= 11;
		end if;

	--set LOW third row
	elsif COUNTER < 12000*30 then
		R <= b"1111";
		R <= b"1011";
		if C(0) = '0' and R(2) = '0' then
		KEY <= 7;
		elsif C(1) = '0' and R(2) = '0' then
		KEY <= 8;
		elsif C(2) = '0' and R(2) = '0' then
		KEY <= 9;
		elsif C(3) = '0' and R(2) = '0' then
		KEY <= 12;
		end if;

	--set LOW fourth row
	elsif COUNTER < 12000*40 then
		R <= b"1111";
		R <= b"0111";
		if C(0) = '0' and R(3) = '0' then
		KEY <= 0;
		elsif C(1) = '0' and R(3) = '0' then
		KEY <= 0;
		elsif C(2) = '0' and R(3) = '0' then
		KEY <= 0;
		elsif C(3) = '0' and R(3) = '0' then
		KEY <= 13;
		end if;

	elsif COUNTER <= 12000*50 then
		COUNTER <= 0;

	end if;
	
	KEYP <= KEY;
	S1 <= INT_TO_VECTOR(KEY);
	
	--MARK FIELD
	if KEYP > 0 then
		L<=FIELD_MAP_PLUS(7 DOWNTO 0);
		if PLAYER = '0' then --when plus click
			if FIELD_MAP_MINUS(KEYP-1) = '0' then
				FIELD_MAP_PLUS(KEYP-1) <= '1';
				PLAYER <= '1';
			end if;
		else --when minus click
			if FIELD_MAP_PLUS(KEYP-1) = '0' then
				FIELD_MAP_MINUS(KEYP-1) <= '1';
				PLAYER <= '0';
			end if;
		end if;
	end if;
	
	--row
	if x < 640 then
	hsync <= '1';
	color <= DRAW_FIELD(x, y);
	--red <= b"000";
	--green <= b"100";
	--blue <= b"00";
	red <= color(7 DOWNTO 5);
	green <= color(4 DOWNTO 2);
	blue <= color(1 DOWNTO 0);
	x<=x+1;
	elsif x < (640+fporch_hor) then
	hsync <= '1';
	red <= b"000";
	green <= b"000";
	blue <= b"00";
	x<=x+1;
	elsif x < (640+fporch_hor+sync_hor) then
	hsync <= '0';
	x<=x+1;
	elsif x < (640+fporch_hor+sync_hor+bporch_hor) then
	hsync <= '1';
	x<=x+1;
	else
	x <= 0;
	y <= y + 1;
	end if;
	--row end

	--column
	if (y < 480) then
	vsync <= '1';
	elsif y < (480+fporch_ver) then
	vsync <= '1';
	elsif y < (480+fporch_ver+sync_ver) then
	vsync <= '0';
	elsif y < (480+fporch_ver+sync_ver+bporch_ver) then
	vsync <= '1';
	else
	x <= 0;
	y <= 0;
	end if;
	--column end

end if;

end process;
--keyboard process end

--width: 640px
--height: 480px
--signal fporch_hor: integer := 16; -- 16 cycles
--signal sync_hor: integer := 96; -- 96 cycles
--signal bporch_hor: integer := 48; -- 48 cycles
--signal fporch_ver: integer := 10; -- 10 cycles
--signal sync_ver: integer := 2; -- 2 cycles
--signal bporch_ver: integer := 33; -- 33 cycles

LED<=L;
SEG1<=S1;
SEG1_EN<='0';
SEG2_EN<='1';
SEG3_EN<='1';
ROWS<=R;
C<=COLS;

end Behavioral;