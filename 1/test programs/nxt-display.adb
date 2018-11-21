------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                     Copyright (C) 2010-2011, AdaCore                     --
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

with NXT.LCD; use NXT.LCD;
with NXT.Fonts;
with Memory_Copy;  -- why??

package body NXT.Display is

   Font_Width : constant := 6;

   Max_X : constant Natural := 100 / Font_Width;

   Current_Column : Char_Columns;
   Current_Row    : Char_Rows;

   Screen : array (Char_Columns, Char_Rows) of Character;

   -------------------
   -- Screen_Update --
   -------------------

   procedure Screen_Update is
      use NXT.Fonts;
      Line : LCD_Line (Pixel_Columns);
   begin
      for I in Char_Rows loop
         for J in Screen'Range (1) loop
            Line (J * Font_Width .. J * Font_Width + Font_Width - 2) :=
              Font5x8 (Screen (J, I));
            Line (J * Font_Width + Font_Width - 1) := 0;
         end loop;
         Line (Max_X * Font_Width .. Line'Last) := (others => 0);
         Write (I, 0, Line);
      end loop;
   end Screen_Update;

   ---------------------------
   -- Clear_Screen_Noupdate --
   ---------------------------

   procedure Clear_Screen_Noupdate is
   begin
      Screen := (others => (others => ' '));
      Current_Column := 0;
      Current_Row := 0;
   end Clear_Screen_Noupdate;

   ------------------
   -- Clear_Screen --
   ------------------

   procedure Clear_Screen is
   begin
      Clear_Screen_Noupdate;
      Screen_Update;
   end Clear_Screen;

   -------------
   -- Set_Pos --
   -------------

   procedure Set_Pos (Column : Char_Columns; Row : Char_Rows) is
   begin
      Current_Column := Column;
      Current_Row := Row;
   end Set_Pos;

   ----------------------
   -- Newline_Noupdate --
   ----------------------

   procedure Newline_Noupdate is
   begin
      Current_Column := 0;
      if Current_Row = Pixel_Rows'Last then
         for I in 0 .. Pixel_Rows'Last - 1 loop
            for J in Char_Columns loop
               Screen (J, I) := Screen (J, I + 1);
            end loop;
         end loop;
         for J in Char_Columns loop
            Screen (J, Pixel_Rows'Last) := ' ';
         end loop;
      else
         Current_Row := Current_Row + 1;
      end if;
   end Newline_Noupdate;

   ------------------
   -- Put_Noupdate --
   ------------------

   procedure Put_Noupdate (C : Character) is
      use NXT.Fonts;
      X : Pixel_Columns := Current_Column * Font_Width;
   begin
      if C in Font5x8'Range then
         Screen (Current_Column, Current_Row) := C;
         if Current_Column = Char_Columns'Last then
            Newline_Noupdate;
         else
            Current_Column := Current_Column + 1;
         end if;
      else
         case C is
            when ASCII.CR =>
               Current_Column := 0;
            when ASCII.LF =>
               Newline_Noupdate;
            when others =>
               null;
         end case;
      end if;
   end Put_Noupdate;

   ---------
   -- Put --
   ---------

   procedure Put (C : Character) is
   begin
      Put_Noupdate (C);
      Screen_Update;
   end Put;

   ------------------
   -- Put_Noupdate --
   ------------------

   procedure Put_Noupdate (S : String) is
   begin
      for I in S'Range loop
         Put_Noupdate (S (I));
      end loop;
   end Put_Noupdate;

   ---------
   -- Put --
   ---------

   procedure Put (S : String) is
   begin
      Put_Noupdate (S);
      Screen_Update;
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (S : String) is
   begin
      Put_Noupdate (S);
      Newline_Noupdate;
      Screen_Update;
   end Put_Line;

   -------------
   -- Newline --
   -------------

   procedure Newline is
   begin
      Newline_Noupdate;
      Screen_Update;
   end Newline;

   Hexdigits : constant array (0 .. 15) of Character := "0123456789ABCDEF";

   -------------
   -- Put_Hex --
   -------------

   procedure Put_Hex (Val : Unsigned_32) is
   begin
      for I in reverse 0 .. 7 loop
         Put_Noupdate (Hexdigits (Natural (Shift_Right (Val, 4 * I) and 15)));
      end loop;
   end Put_Hex;

   -------------
   -- Put_Hex --
   -------------

   procedure Put_Hex (Val : Unsigned_16) is
   begin
      for I in reverse 0 .. 3 loop
         Put_Noupdate (Hexdigits (Natural (Shift_Right (Val, 4 * I) and 15)));
      end loop;
   end Put_Hex;

   -------------
   -- Put_Hex --
   -------------

   procedure Put_Hex (Val : Unsigned_8) is
   begin
      for I in reverse Integer range 0 .. 1 loop
         Put_Noupdate (Hexdigits (Natural (Shift_Right (Val, 4 * I) and 15)));
      end loop;
   end Put_Hex;

   ------------------
   -- Put_Noupdate --
   ------------------

   procedure Put_Noupdate (V : Integer) is
      Val : Integer := V;
      Res : String (1 .. 9);
      Pos : Natural := Res'Last;
   begin
      if Val < 0 then
         Put_Noupdate ('-');
      else
         Val := -Val;
      end if;
      loop
         Res (Pos) := Character'Val (Character'Pos ('0') - (Val mod (-10)));
         Val := Val / 10;
         exit when Val = 0;
         Pos := Pos - 1;
      end loop;
      for I in Pos .. Res'Last loop
         Put_Noupdate (Res (I));
      end loop;
   end Put_Noupdate;

   ------------------
   -- Put_Noupdate --
   ------------------

   procedure Put_Noupdate (V : Long_Long_Integer) is
      Val : Long_Long_Integer := V;
      Res : String (1 .. 20);
      Pos : Natural := Res'Last;
   begin
      if Val < 0 then
         Put_Noupdate ('-');
      else
         Val := -Val;
      end if;
      loop
         Res (Pos) := Character'Val (Character'Pos ('0') - (Val mod (-10)));
         Val := Val / 10;
         exit when Val = 0;
         Pos := Pos - 1;
      end loop;
      for I in Pos .. Res'Last loop
         Put_Noupdate (Res (I));
      end loop;
   end Put_Noupdate;

   -------------------
   -- Put_Exception --
   -------------------

   procedure Put_Exception (Addr : Unsigned_32) is
   begin
      Set_Pos (0, 0);
      Put_Noupdate ("ERR@");
      Put_Hex (Addr);
   end Put_Exception;

begin
   NXT.LCD.Power_On;
   Clear_Screen;
end NXT.Display;
