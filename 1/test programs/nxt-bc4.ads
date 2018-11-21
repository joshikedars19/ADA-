------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                    Copyright (C) 2010-2011, AdaCore                      --
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

--  Low-level driver for BlueCore4 bluetooth device.

with System;
with Interfaces;  use Interfaces;

package NXT.BC4 is

   procedure Initialize_Device;

   type Reset_Status is (Success, Failed, Unpowered);
   pragma Discard_Names (Reset_Status);

   procedure Reset_Device (Result : out Reset_Status);

   procedure Enter_Command_Mode;

   procedure Enter_Data_Mode;

   function Current_Mode return Unsigned_32;

   procedure Send (Msg : System.Address; Length : Natural);

   procedure Receive (Msg : System.Address);

private

   subtype Buffer_Index is Integer range 0 .. 127;

   type Buffer is array (Buffer_Index) of Unsigned_8;

   pragma Volatile (Buffer);

   subtype Buffer_Selector is Unsigned_8 range 0 .. 1;

   type Double_Buffer is array (Buffer_Selector) of aliased Buffer;

   Incoming       : Double_Buffer;
   Index          : Integer;
   Current_Buffer : Buffer_Selector;

   type Buffer_Reference is access all Buffer;
   for Buffer_Reference'Storage_Size use 0;
   pragma No_Strict_Aliasing (Buffer_Reference);

   Buf_Ptr : Buffer_Reference;

end NXT.BC4;
