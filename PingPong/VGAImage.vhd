library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity VGAImage is
	generic(
		fporch_hor: natural range 0 to 1023 := 16; -- 16 cycles
		sync_hor: natural range 0 to 1023:= 112; -- 96 cycles
		bporch_hor: natural range 0 to 1023:= 160; -- 48 cycles
		fporch_ver: natural range 0 to 1023:= 10; -- 10 cycles
		sync_ver: natural range 0 to 1023:= 12; -- 2 cycles
		bporch_ver: natural range 0 to 1023:= 45 -- 33 cycles
	);
	port(
		SCL: in STD_LOGIC;
		UPA: in STD_LOGIC;
		DOWNA: in STD_LOGIC;
		UPP: in STD_LOGIC;
		DOWNP: in STD_LOGIC;
		RST: in STD_LOGIC;
		SEG1_EN: out STD_LOGIC;
		SEG2_EN: out STD_LOGIC;
		SEG3_EN: out STD_LOGIC;
		SEG1: out STD_LOGIC_VECTOR(7 DOWNTO 0);
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
signal x: natural range 0 to 4096 := 0;
signal y: natural range 0 to 4096 := 0;
signal color: STD_LOGIC_VECTOR(7 DOWNTO 0);

--ball x y
signal xb: natural range 0 to 4096 := 320;
signal yb: natural range 0 to 4096 := 240;
signal myb: integer range -32 to 32 := 0;
signal mxb: integer range -32 to 32 := -10;

--player p x y
signal xp: natural range 0 to 4096 := 0;
signal yp: natural range 0 to 4096 := 0;

--player a x y
signal xa: natural range 0 to 4096 := 0;
signal ya: natural range 0 to 4096 := 0;

--player points
signal RESULT: natural range 0 to 127 := 0;

--counter for time measure
signal COUNTER: natural range 0 to 25000000 := 0;

--add some kind of randomization xd
signal RND: natural range 0 to 25000000 := 0;

--game state
type MODE is(INIT, PLAY);
signal STATE: MODE := INIT;

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
impure function DRAW_FIELD(X : INTEGER; Y: INTEGER) return STD_LOGIC_VECTOR is
	variable color_inside: STD_LOGIC_VECTOR(7 DOWNTO 0) := b"00000010";
begin
	
	--draw ball
	if ((xb-x)*(xb-x)+(yb-y)*(yb-y)) < 120  then
		color_inside := b"00011000";
	end if;
	
	--draw net
	if x > 315 and x < 325 then
		color_inside := b"11111111";
	end if;
	
	--draw a player
	if x > (xa-5) and x < (xa+5) and y > (ya - 80) and y < (ya + 80) then
		color_inside := b"01000000";
	end if;
	
	--draw p player
	if x > (xp-5) and x < (xp+5) and y > (yp - 80) and y < (yp + 80) then
		color_inside := b"01000000";
	end if;
	
	return color_inside;
end DRAW_FIELD;

begin

vga_pll: VGAImagePLL port map(CLKIN_IN => SCL, CLKFX_OUT => SCL_PLL);

process(SCL_PLL)
begin
if rising_edge(SCL_PLL) then
	
COUNTER <= COUNTER + 1;
RND <= RND + 3;

case STATE is

-- init state, set snake in default position
when INIT =>
	xa <= 8;
	ya <= 240;
	xp <= 622;
	yp <= 240;
	xb <= 320;
	yb <= 240;
	mxb <= -10;
	myb <= 0;
	RESULT <= 0;
	STATE <= PLAY;

-- play state
when PLAY =>	
	SEG1 <= INT_TO_VECTOR(RESULT);
	
	-- move
	if COUNTER > 25000*50 then
		COUNTER <= 0;
		
		yb <= yb + myb;
		xb <= xb + mxb;
		
		--when hit top or bottom
		if yb < 10 then
			if myb < 0 then
				myb <= -1 * myb;
			end if;
		end if;
		if yb > 460 then
			if myb > 0 then
				myb <= -1 * myb;
			end if;
		end if;
		
		--check if point a lose or bounce the ball
		if yb < (ya - 91) or yb > (ya + 91) then
			if xb < 8 then
				RESULT <= RESULT + 1;
				xb <= 320;
				yb <= 240;
				mxb <= -10;
				myb <= 0;
			end if;
		else -- bounce the ball
			if xb < (xa + 25) then
				mxb <= 10;
				if yb > ya then
					myb <= 7 - (RND mod 2);
				else
					myb <= - 7 + (RND mod 2);
				end if;
			end if;
		end if;
		
		--check if point p lose or bounce the ball
		if yb < (yp - 91) or yb > (yp + 91) then
			if xb > 622 then
				RESULT <= RESULT + 1;
				xb <= 320;
				yb <= 240;
				mxb <= -10;
				myb <= 0;
			end if;
		else -- bounce the ball
			if xb > (xp - 25) then
				mxb <= -10;
				if yb > yp then
					myb <= 7 - (RND mod 2);
				else
					myb <= -7 + (RND mod 2);
				end if;
			end if;
		end if;
		
		if UPP = '0' then
			if (yp - 80) > 0 then
				yp <= yp - 10;
			end if;
		elsif DOWNP = '0' then
			if (yp + 80) < 480 then
				yp <= yp + 10;
			end if;
		end if;
		
		if UPA = '0' then
			if (ya - 80) > 0 then
				ya <= ya - 10;
			end if;
		elsif DOWNA = '0' then
			if (ya + 80) < 480 then
				ya <= ya + 10;
			end if;
		end if;
	end if;
	
	--row
	if x < 640 then
	hsync <= '1';
	color <= DRAW_FIELD(x, y);
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
	elsif x < (640+sync_hor) then
	hsync <= '0';
	x<=x+1;
	elsif x < (640+bporch_hor) then
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
	elsif y < (480+sync_ver) then
	vsync <= '0';
	elsif y < (480+bporch_ver) then
	vsync <= '1';
	else
	x <= 0;
	y <= 0;
	end if;
	--column end

end case;

if RST = '0' then
	STATE <= INIT;
end if;

end if;

end process;

SEG1_EN<='0';
SEG2_EN<='1';
SEG3_EN<='1';

end Behavioral;