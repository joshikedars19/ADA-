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

--  Low-level LCD commands.

package NXT.LCD is

   --  Viewable pixels.
   subtype Pixel_Columns is Natural range 0 .. 99;
   subtype Pixel_Rows    is Natural range 0 .. 7;
   --  0,0 is upper left; 99,7 is lower right

   type LCD_Line is array (Pixel_Columns range <>) of Unsigned_8;

   --  Raw number of columns and pages.
   subtype Raw_Columns is Natural range 0 .. 255;
   subtype Raw_Pages   is Natural range 0 .. 15;

   procedure Command (Cmd : Unsigned_8);
   --  Send a command to the lcd.

   procedure Write (Page : Raw_Pages; Start : Raw_Columns; Graph : LCD_line);

   procedure Set_All_Pixels_On (On : Boolean);
   procedure Set_Inverse_Display (On : Boolean);
   --  High level commands.

   procedure Power_On;
   --  Power up and initialize LCD.

end NXT.LCD;
