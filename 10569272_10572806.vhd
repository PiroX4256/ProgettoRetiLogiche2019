----------------------------------------------------------------------------------
-- Company: PoliMi 
-- Engineer: Alice Piemonti & Luca Pirovano
-- 
-- Create Date: 17.02.2020 12:25:14
-- Design Name: 
-- Module Name: 10569272_10572806 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    port(
        i_clk: in std_logic;
        i_start: in std_logic;
        i_rst: in std_logic;
        i_data: in std_logic_vector(7 downto 0);
        o_address: out std_logic_vector(15 downto 0);
        o_done: out std_logic;
        o_en: out std_logic;
        o_we: out std_logic;
        o_data: out std_logic_vector(7 downto 0)
        );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    --Stati della macchina
    type state_type is (IDLE, READ_ADDR, SET_WZ, READ_WZ, ENCODE_WRITE, WAIT_SIGNAL, STOP);
    
    signal current_state: state_type;
    signal to_code_address: unsigned(7 downto 0);
    signal address_counter: std_logic_vector(15 downto 0);
    signal wz_found: std_logic;
    --signal converted_address: unsigned(7 downto 0);
    --signal wz_starting_address: unsigned(7 downto 0);
    signal wz_found_address: std_logic_vector(2 downto 0);
    signal onehot_offset: std_logic_vector(3 downto 0);
    
    --Costanti
    constant VALUE_ZERO: std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(0,8));
    constant END_OF_WZ: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(8,16));
    constant ADDRESS_ZERO: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(0,16));
    constant INPUT_ADDRESS: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(8,16));
    constant OUTPUT_ADDRESS: std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(9, 16));
    
begin

--Descrizione FSM

    --Funzione stato prossimo
    next_state_function: process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            current_state <= IDLE;
        elsif falling_edge(i_clk) then
            case current_state is
                when IDLE =>
                    if(i_start = '1') then
                        current_state <= READ_ADDR;
                    else
                        current_state <= IDLE;
                    end if;
                when READ_ADDR =>
                    current_state <= SET_WZ;
                when SET_WZ =>
                    if(address_counter = END_OF_WZ) then
                        current_state <= ENCODE_WRITE;
                    elsif(wz_found = '1') then
                        current_state <= ENCODE_WRITE;
                    else
                        current_state <= READ_WZ;
                    end if;
                when READ_WZ =>
                    current_state <= SET_WZ;
                when ENCODE_WRITE =>
                    current_state <= WAIT_SIGNAL;
                when WAIT_SIGNAL =>
                    if (i_start = '0') then
                        current_state <= STOP;
                    else
                        current_state <= WAIT_SIGNAL;
                    end if;
                when STOP =>
                    if (i_start = '1') then
                        current_state <= READ_ADDR;
                    else
                        current_state <= STOP;
                    end if;
            end case;
        end if;
    end process next_state_function;
    
    output_function: process(current_state)
    begin
        case current_state is
            when IDLE =>
                if (i_start = '1') then
                    o_en <= '1';
                else
                    o_en <= '0';
                end if;
                o_done <= '0';
                o_we <= '0';
                o_data <= VALUE_ZERO;              
            when READ_ADDR =>
                o_en <= '1';
                o_done <= '0';
                o_we <= '0';
                o_data <= VALUE_ZERO;
            when SET_WZ =>
                o_en <= '1';
                o_done <= '0';
                o_we <= '0';
                o_data <= VALUE_ZERO;
            when READ_WZ =>
                o_en <= '1';
                o_done <= '0';
                o_we <= '0';
                o_data <= VALUE_ZERO;
            when ENCODE_WRITE =>
                o_en <= '1';
                o_done <= '0';
                o_we <= '1';
                if(wz_found = '0') then
                    o_data <= std_logic_vector(to_code_address);
                    o_data(7) <= '0';
                else
                    o_data(7) <= '1';
                    o_data(6 downto 4) <= std_logic_vector(wz_found_address);
                    o_data(3 downto 0) <= std_logic_vector(onehot_offset(3 downto 0));
                end if;
--            o_data <= std_logic_vector(converted_address);
            when WAIT_SIGNAL =>
                o_en <= '0';
                o_done <= '1';
                o_we <= '0';
                o_data <= VALUE_ZERO;
            when STOP =>
                o_en <= '0';
                o_done <= '0';
                o_we <= '0';
                o_data <= VALUE_ZERO;
        end case;
    end process output_function;
-- Fine descrizione FSM

-- Generatore di indirizzi
    address_generator: process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            address_counter <= ADDRESS_ZERO;
        elsif(falling_edge(i_clk)) then
            case current_state is
                when IDLE =>
                    address_counter <= INPUT_ADDRESS;
                when READ_ADDR =>
                    address_counter <= ADDRESS_ZERO;
                when SET_WZ =>
                    if(wz_found = '1') then
                        address_counter <= OUTPUT_ADDRESS;
                    elsif(address_counter = END_OF_WZ) then
                        address_counter <= OUTPUT_ADDRESS;
                    end if;

                when READ_WZ =>
                    address_counter <= address_counter + 1;                

                when ENCODE_WRITE =>
                    address_counter <= ADDRESS_ZERO;
                when WAIT_SIGNAL =>
                when STOP =>
                    if (i_start = '1')then
                        address_counter <= INPUT_ADDRESS;
                    end if;
            end case;
        end if;
    end process address_generator;

o_address <= address_counter;
    
 -- Fine generatore di ingirizzi
 
 -- Registro inidirzzo da codificare
    to_code_register: process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            to_code_address <= unsigned(VALUE_ZERO);
        elsif(falling_edge(i_clk)) then
            case current_state is
                when READ_ADDR =>
                    to_code_address <= unsigned(i_data);
                when others =>
            end case;
        end if;
    end process to_code_register;
    
    -- Registro ricerca WZ
    wz_found_register: process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            wz_found <= '0';
            onehot_offset <= std_logic_vector(to_unsigned(0,4));
        elsif(falling_edge(i_clk)) then
            case current_state is
                when READ_WZ =>
                    if((to_code_address - unsigned(i_data)) = 0) then
                        wz_found <= '1';
                        onehot_offset <= std_logic_vector(to_unsigned(1,4));
                        wz_found_address <= address_counter(2 downto 0);
                    elsif((to_code_address - unsigned(i_data)) = 1) then
                        wz_found <= '1';
                        onehot_offset <= std_logic_vector(to_unsigned(2,4));
                        wz_found_address <= address_counter(2 downto 0);
                    elsif((to_code_address - unsigned(i_data)) = 2) then
                        wz_found <= '1';
                        onehot_offset <= std_logic_vector(to_unsigned(4,4));
                        wz_found_address <= address_counter(2 downto 0);                    
                    elsif((to_code_address - unsigned(i_data)) = 3) then
                        wz_found <= '1';
                        onehot_offset <= std_logic_vector(to_unsigned(8,4));
                        wz_found_address <= address_counter(2 downto 0);
                    else
                        wz_found <= '0';
                    end if;
                  when ENCODE_WRITE =>
                    wz_found <= '0';

                when others =>
            end case;
        end if;
    end process wz_found_register;
    
    -- Fine registro ricerca WZ
    
end Behavioral;