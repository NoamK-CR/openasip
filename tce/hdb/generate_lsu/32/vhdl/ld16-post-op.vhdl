load_data_32b <= rdata_out_1;
case addr_low_out_1(1 downto 1) is
  when "0" => op2 <= (16-1 downto 0 => load_data_32b(15)) & load_data_32b(15 downto 0);
  when others => op2 <= (16-1 downto 0 => load_data_32b(31)) & load_data_32b(31 downto 16);
end case;