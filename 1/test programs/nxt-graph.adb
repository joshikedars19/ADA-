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

with Interfaces; use Interfaces;
with Memory_Copy;

package body NXT.Graph is

   Screen : array (Pixel_Rows) of LCD_Line (Pixel_Columns);

   procedure Clear is
   begin
      Screen := (others => (others => 0));

      for I in Screen'Range loop
         Write (I, 0, Screen (I));
      end loop;
   end Clear;

   procedure Draw_Glyph (X     : Graph_Columns;
                         Y     : Graph_Rows;
                         Glyph : LCD_Line)
   is
      Shift : constant Natural := Y mod Glyph_Height;
      LCD_Y : constant Natural := Y / Glyph_Height;
      Last : Natural := Glyph'Last;
   begin
      if X + Last > Pixel_Columns'Last then
         Last := Pixel_Columns'Last - X;
      end if;
      for I in Glyph'First .. Last loop
         Screen (LCD_Y)(X + I) := Screen (LCD_Y)(X + I)
           xor Shift_Left (Glyph (I), Shift);
         if Shift /= 0 and then LCD_Y < Pixel_Rows'Last then
            Screen (LCD_Y + 1)(X + I) := Screen (LCD_Y + 1)(X + I)
              xor Shift_Right (Glyph (I), 8 - Shift);
         end if;
      end loop;
      Write (LCD_Y, X, Screen (LCD_Y)(X .. X + Last));
      if Shift /= 0 and then LCD_Y < Pixel_Rows'Last then
         Write (LCD_Y + 1, X, Screen (LCD_Y + 1)(X .. X + Last));
      end if;
   end Draw_Glyph;

begin
   NXT.LCD.Power_On;
   Clear;
end NXT.Graph;
