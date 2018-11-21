------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with NXT.SPI;

package body NXT.LCD is

   procedure Command (Cmd : Unsigned_8) is
      C : Unsigned_8 := Cmd;
   begin
      NXT.SPI.Send (False, C'Address, 1);
   end Command;

   procedure Set_All_Pixels_On (On : Boolean) is
      C : Unsigned_8 := 16#A4#;
   begin
      if On then
         C := C or 1;
      end if;
      Command (C);
   end Set_All_Pixels_On;

   procedure Set_Inverse_Display (On : Boolean) is
      C : Unsigned_8 := 16#A6#;
   begin
      if On then
         C := C or 1;
      end if;
      Command (C);
   end Set_Inverse_Display;

   procedure Set_Display_Enable (On : Boolean) is
      C : Unsigned_8 := 16#AE#;
   begin
      if On then
         C := C or 1;
      end if;
      Command (C);
   end Set_Display_Enable;

   procedure Set_Bias_Ratio (Br : Unsigned_8) is
   begin
      Command (16#E8# or Br);
   end Set_Bias_Ratio;

   procedure Set_Pot (Pm : Unsigned_8) is
   begin
      Command (16#81#);
      Command (Pm);
   end Set_Pot;

   procedure Set_Ram_Address_Control (Ac : Unsigned_8) is
   begin
      Command (16#84# or Ac);
   end Set_Ram_Address_Control;

   procedure Set_Map_Control (M : Unsigned_8) is
   begin
      Command (16#C0# or M * 2);
   end Set_Map_Control;

   procedure Reset is
   begin
      Command (16#E2#);
   end Reset;

   procedure Set_Col (Ca : Raw_Columns) is
   begin
      Command (16#00# or Unsigned_8 (Ca mod 16));
      Command (16#10# or Unsigned_8 (Ca / 16));
   end Set_Col;

   procedure Set_Page_Address (Pa : Raw_Pages) is
   begin
      Command (16#b0# or Unsigned_8 (Pa));
   end Set_Page_Address;

   procedure Set_Scroll (N : Unsigned_8) is
   begin
      Command (16#40# or (N and 63));
   end Set_Scroll;

   procedure Write (Page : Raw_Pages; Start : Raw_Columns; Graph : LCD_line) is
   begin
      Set_Col (Start);
      Set_Page_Address (Page);

      --  ??? Check the length.
      NXT.SPI.Send (True, Graph'Address, Graph'Length);
   end Write;

   procedure Power_On is
   begin
      --  Let the LCD power-up.
      delay until Clock + Milliseconds (20);
      Reset;
      Set_Bias_Ratio (3);
      Set_Pot (16#60#);
      Set_Ram_Address_Control (0);
      Set_Map_Control (2);
      Set_Scroll (0);
      Set_Display_Enable (True);
   end Power_On;

end NXT.LCD;
