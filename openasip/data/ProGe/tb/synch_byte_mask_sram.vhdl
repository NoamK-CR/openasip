-- Copyright (c) 2002-2022 Tampere University.
--
-- This file is part of TTA-Based Codesign Environment (TCE).
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------
-- Title      : synchronous static RAM
-------------------------------------------------------------------------------
-- File       : synch_byte_mask_sram.vhdl
-- Author     : Kari Hepola  <kari.hepola@tuni.fi>
-- Company    : 
-- Created    : 2022-07-04
-- Last update: 2022-07-04
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-- An SRAM component that follows Alma-IF. Compared to the normal sram component
-- this one has byte mask and active high control signals, as well as a different
-- handshake protocol
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2022-07-04  1.0      hepola Created
-------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity synch_byte_mask_sram is
  generic (
    -- pragma translate_off
    init                : boolean := true;
    INITFILENAME        : string  := "ram_init";
    trace               : boolean := true;
    TRACEFILENAME       : string  := "dpram_trace";
    -- trace_mode 0: hex, trace_mode 1: integer, trace_mode 2: unsigned
    trace_mode          : natural := 0;
    access_trace        : boolean := true;
    ACCESSTRACEFILENAME : string  := "access_trace";
    -- pragma translate_on
    DATAW               : integer := 32;
    ADDRW               : integer := 7);
  port (
    clk          : in  std_logic;
    adata        : in  std_logic_vector(DATAW-1 downto 0);
    aaddr        : in  std_logic_vector(ADDRW-1 downto 0);
    avalid       : in  std_logic;
    awren        : in  std_logic;
    astrb        : in  std_logic_vector((DATAW/8)-1 downto 0);
    aready       : out std_logic;
    rvalid       : out std_logic;
    rready       : in std_logic;
    rdata        : out std_logic_vector(DATAW-1 downto 0));
end synch_byte_mask_sram;

architecture rtl of synch_byte_mask_sram is

  type std_logic_matrix is array (natural range <>) of
    std_logic_vector (DATAW-1 downto 0);
  subtype word_line_index is integer range 0 to 2**ADDRW-1;
  signal mem_r : std_logic_matrix (0 to 2**ADDRW-1);
  signal line  : word_line_index;

  signal q_r : std_logic_vector(DATAW-1 downto 0);

  signal wr_mask : std_logic_vector(DATAW-1 downto 0);
  
begin  -- rtl

  line <= conv_integer (unsigned (aaddr));

  --TODO: Add logic to these handshake signals
  rvalid <= '1';
  aready <= '1';


  -- purpose: read & write memory
  -- type   : sequential
  -- inputs : clk
  regs : process (clk)
  begin  -- process regs
    if clk'event and clk = '1' then     -- rising clock edge
      -- Memory read
      if (avalid = '1' and awren = '1') then
        -- bypass data to output register
        q_r
          <= (adata and (wr_mask)) or (mem_r(line) and (not wr_mask));
        mem_r(line)
          <= (adata and (wr_mask)) or (mem_r(line) and (not wr_mask));
      elsif (avalid = '1') then
        q_r <= mem_r(line);
      end if;
    end if;
  end process regs;

  gen_mask_cp : process(avalid, astrb)
  begin
    wr_mask <= (others => '0');
    for i in 0 to (DATAW/8) - 1 loop
      for j in i*8 to i*8 + 7 loop
        wr_mask(j) <= astrb(i);
      end loop;
    end loop;
  end process gen_mask_cp;

  rdata <= q_r;

end rtl;

-- pragma translate_off
library IEEE, STD;
use std.textio.all;
use IEEE.std_logic_textio.all;

architecture simulation of synch_byte_mask_sram is

  type std_logic_matrix is array (natural range <>) of
    std_logic_vector (DATAW-1 downto 0);
  subtype word_line_index is integer range 0 to 2**ADDRW-1;
  signal word_line : word_line_index;

  signal mem_r : std_logic_matrix (0 to 2**ADDRW-1);
  signal q_r   : std_logic_vector(DATAW-1 downto 0);

  signal initialized : boolean := false;

  signal wr_mask : std_logic_vector(DATAW-1 downto 0);

begin  -- simulate

  gen_mask_cp : process(avalid, astrb)
  begin
    wr_mask <= (others => '0');
    for i in 0 to (DATAW/8) -1 loop
      for j in i*8 to i*8 + 7 loop
        wr_mask(j) <= astrb(i);
      end loop;
    end loop;
  end process gen_mask_cp;

  --TODO: Add logic to these handshake signals
  rvalid <= '1';
  aready <= '1';
  word_line <= conv_integer(unsigned (aaddr));

  -- purpose: read & write + intialize memory from file
  -- type   : sequential
  -- inputs : clk
  regs_init : process (clk)
    -- input file
    file mem_init              : text;
    -- output file
    file mem_trace             : text;
    variable line_in           : line;
    variable line_out          : line;
    variable word_from_file    : std_logic_vector(DATAW-1 downto 0);
    variable word_to_mem       : std_logic_vector(DATAW-1 downto 0);
    variable i                 : natural;
    variable good              : boolean                            := false;
    variable cycle_count       : natural                            := 0;
    file access_trace_file     : text;
    variable access_trace_init : boolean                            := false;
    variable last_addr         : std_logic_vector(ADDRW-1 downto 0) := (others => 'U');
    variable access_trace_line : line;
    constant separator_c       : string  := " | ";

  begin  -- process regs

    if (init = true) then
      if (initialized = false) then
        i := 0;
        if INITFILENAME /= "" then
          file_open(mem_init, INITFILENAME, read_mode);
          while (not endfile(mem_init) and i < mem_r'length) loop
            readline(mem_init, line_in);
            assert line_in'length >= DATAW
              report "Memory initialization file must have word width " &
                     "greater than or equal to the memory width. Set the " &
                     "-w switch for generatebits accordingly."
              severity failure;

            assert line_in'length mod DATAW = 0
              report "Memory initialization file must have word width " &
                     "divisible by the memory width. Set the " &
                     "-w switch for generatebits accordingly."
              severity failure;

            while line_in'length /= 0 loop
              read(line_in, word_from_file, good);
              assert good
                report "Read error in memory initialization file"
                severity failure;
              mem_r(i) <= word_from_file;
              i        := i+1;
            end loop;
          end loop;
          assert (not good)
            report "Memory initialization succesful"
            severity note;
        else
          while (i < mem_r'length) loop
            mem_r(i) <= (others => '0');
            i        := i+1;
          end loop;
          assert (false)
            report "Memory initialized to zeroes!"
            severity note;
        end if;
        initialized <= true;
      end if;
    end if;

    if clk'event and clk = '1' then     -- rising clock edge
      -- Memory write
      if (avalid = '1' and awren = '1') then
        -- bypass data to output register
        word_to_mem
          := (adata and (wr_mask)) or (mem_r(word_line) and (not wr_mask));
        mem_r(word_line) <= word_to_mem;

        -- trace memory to file
        if (trace = true) then
          file_open(mem_trace, TRACEFILENAME, write_mode);
          for i in mem_r'reverse_range loop
            if (i = word_line) then
              if (trace_mode = 0) then
                hwrite(line_out, word_to_mem);
              elsif (trace_mode = 1) then
                write(line_out, conv_integer(signed(word_to_mem)));
              else
                write(line_out, conv_integer(unsigned(word_to_mem)));
              end if;
            else
              if (trace_mode = 0) then
                hwrite(line_out, mem_r(i));
              elsif (trace_mode = 1) then
                write(line_out, conv_integer(signed(mem_r(i))));
              else
                write(line_out, conv_integer(unsigned(mem_r(i))));
              end if;
            end if;
            writeline(mem_trace, line_out);
          end loop;  -- i
          file_close(mem_trace);
        end if;

      -- Memory read
      elsif (avalid = '1') then
        q_r <= mem_r(word_line);
      end if;

      -- Memory access trace to file
      if access_trace then
        if avalid = '1' and last_addr /= aaddr then
          file_open(access_trace_file, ACCESSTRACEFILENAME, append_mode);
          write(access_trace_line, cycle_count, right, 12);
          write(access_trace_line, separator_c);
          hwrite(access_trace_line, aaddr, right, 12);
          write(access_trace_line, separator_c);
          write(access_trace_line, string'("1"), right, 12);
          write(access_trace_line, separator_c);
          write(access_trace_line, string'("1"), right, 12);
          writeline(access_trace_file, access_trace_line);
          file_close(access_trace_file);
          last_addr := aaddr;
        end if;

        cycle_count := cycle_count + 1;
      end if;
      
    end if;  -- rising edge
  end process regs_init;

  rdata <= q_r;
  
end simulation;

-- pragma translate_on
