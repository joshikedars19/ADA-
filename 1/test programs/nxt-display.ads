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

--  High-level driver for LCD display.

with Interfaces; use Interfaces;

package NXT.Display is

   subtype Char_Columns is Natural range 0 .. 15;
   subtype Char_Rows    is Natural range 0 .. 7;
   --   0,0 is the upper left; 15,7 is lower right

   --  Note: the _Noupdate (and _Hex) variants do not update the display.

   procedure Clear_Screen_Noupdate;
   procedure Clear_Screen;

   procedure Set_Pos (Column : Char_Columns; Row : Char_Rows);
   --  Set current position.

   procedure Put_Noupdate (C : Character);
   procedure Put_Noupdate (S : String);
   procedure Put_Noupdate (V : Integer);
   procedure Put_Noupdate (V : Long_Long_Integer);
   --  Write a character, a string and an integer.
   --  Only CR and LF control characters are handled.
   --  Note that the min and max values for Long_Long_Integer will wrap around
   --  the display.

   procedure Put (C : Character);
   procedure Put (S : String);
   procedure Put_Line (S : String);
   --  Like in Ada.Text_IO.

   procedure Newline_Noupdate;
   procedure Newline;
   procedure New_Line renames Newline;
   procedure New_Line_Noupdate renames Newline_Noupdate;
   --  Like in Ada.Text_IO.

   procedure Screen_Update;
   --  Synchronize the LCD with the internal buffer.

   procedure Put_Hex (Val : Unsigned_32);
   procedure Put_Hex (Val : Unsigned_16);
   procedure Put_Hex (Val : Unsigned_8);
   --  Write VAL using its hexadecimal representation, without
   --  updating the LCD.

   procedure Put_Exception (Addr : Unsigned_32);
   pragma Export (C, Put_Exception);
   --  Can be called in case of exception.

end NXT.Display;
