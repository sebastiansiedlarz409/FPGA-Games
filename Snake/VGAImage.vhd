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
		UP: in STD_LOGIC;
		LEFT: in STD_LOGIC;
		RIGHT: in STD_LOGIC;
		DOWN: in STD_LOGIC;
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
signal x: natural range 0 to 1023 := 0;
signal y: natural range 0 to 1023 := 0;
signal color: STD_LOGIC_VECTOR(7 DOWNTO 0);

--movement direction 0 left, 1 top, 2 right, 4 down
signal DIR: natural range 0 to 4 := 0;

--how many add or sub
signal MD: integer range -16 to 16 := -16;

--x or y should be modified
signal OS: natural range 0 to 1 := 0;

--snake
type MEMORY is array (0 to 25) of INTEGER range 0 to 620;
signal BUFFOR : MEMORY := (others=>0);

--how long snake is (2x)
signal SL : integer range 0 to 127 := 2;

--apple x y
signal xa: natural range 0 to 1023 := 0;
signal ya: natural range 0 to 1023 := 0;

--player points
signal RESULT: natural range 0 to 127 := 0;

--counter for time measure
signal COUNTER: natural range 0 to 25000000 := 0;

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

--random int
impure function RND_NUMBER(MIN, MAX : integer) return INTEGER is
	variable temp: natural range 0 to 1023 := 0;
begin
	temp := (BUFFOR(0) + MIN) mod 512;
	if MAX = 480 then
		temp := temp - 40;
		if temp > 450 then
			temp := 450;
		end if;
		if temp < 20 then
			temp := 20;
		end if;
	else
		temp := temp + 100;
		if temp > 620 then
			temp := 620;
		end if;
		if temp < 20 then
			temp := 20;
		end if;
	end if;
	return temp;
end RND_NUMBER;

--this function draw field and player
impure function DRAW_FIELD(X : INTEGER; Y: INTEGER) return STD_LOGIC_VECTOR is
	variable color_inside: STD_LOGIC_VECTOR(7 DOWNTO 0) := b"00000010";
begin
	
	--draw snake
	for i in 0 to 24 loop
		if (i mod 2) = 0 and x < BUFFOR(i) + 8 and x > BUFFOR(i) - 8 and y < BUFFOR(i+1) + 8 and y > BUFFOR(i+1) - 8 and BUFFOR(i) /= 0 then
			color_inside := b"00011100";
		end if;
	end loop;
	
	--draw apple
	if x < xa + 8 and x > xa - 8 and y < ya + 8 and y > ya - 8 then
		color_inside := b"11100011";
	end if;
	
	return color_inside;
end DRAW_FIELD;

begin

vga_pll: VGAImagePLL port map(CLKIN_IN => SCL, CLKFX_OUT => SCL_PLL);

process(SCL_PLL)
begin
if rising_edge(SCL_PLL) then
	
COUNTER <= COUNTER + 1;

case STATE is

-- init state, set snake in default position
when INIT =>
	BUFFOR <= (others=>0);
	
	BUFFOR(0) <= 320;
	BUFFOR(1) <= 220;
	
--	BUFFOR(2) <= 340;
--	BUFFOR(3) <= 220;
--	
--	BUFFOR(4) <= 360;
--	BUFFOR(5) <= 220;
	STATE <= PLAY;

-- play state
when PLAY =>	
	SEG1 <= INT_TO_VECTOR(RESULT);
	
	-- set direction when button is pressed
	if LEFT = '0' and DIR /= 2 then
		DIR <= 0;
	elsif UP = '0' and DIR /= 3 then
		DIR <= 1;
	elsif RIGHT = '0' and DIR /= 0 then
		DIR <= 2;
	elsif DOWN = '0' and DIR /= 1 then
		DIR <= 3;
	end if;
	
	-- move snake once per N millis
	if COUNTER > 25000*200 then
		COUNTER <= 0;
		
		if DIR = 0 then
			OS <= 0;
			MD <= -16;
		elsif DIR = 1 then
			OS <= 1;
			MD <= -16;
		elsif DIR = 2 then
			OS <= 0;
			MD <= 16;
		elsif DIR = 3 then
			OS <= 1;
			MD <= 16;
		end if;
		
		for i in 0 to 22 loop
			BUFFOR(i+2) <= BUFFOR(i);
			BUFFOR(i+3) <= BUFFOR(i+1);
		end loop;
		BUFFOR(SL) <= 0;
		BUFFOR(SL+1) <= 0;
		BUFFOR(OS) <= BUFFOR(OS) + MD;		
		
		--check if screen boreder are riched
		if BUFFOR(0) < 10 or BUFFOR(0) > 620 or BUFFOR(1) < 20 or BUFFOR(1) > 460 then
			DIR <= 0;
			STATE <= INIT;
			xa <= 0;
			ya <= 0;
			SL <= 2;
			RESULT <= 0;
		end if;
	end if;
	
	--check if apple hit
	if BUFFOR(0) < (xa + 16) and BUFFOR(0) > (xa - 16) and BUFFOR(1) < (ya + 16) and BUFFOR(1) > (ya - 16) then
		xa <= 0;
		ya <= 0;
		SL <= SL + 2;
		RESULT <= RESULT + 1;
	end if;
	
	--random apple position
	if xa = 0 and ya = 0 then
		xa <= RND_NUMBER(10, 640);
		ya <= RND_NUMBER(10, 480);
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
	DIR <= 0;
	STATE <= INIT;
	xa <= 0;
	ya <= 0;
	SL <= 2;
	RESULT <= 0;
end if;

end if;

end process;

SEG1_EN<='0';
SEG2_EN<='1';
SEG3_EN<='1';

end Behavioral;