------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                        Copyright (C) 2011, AdaCore                       --
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

with NXT.AVR;
with NXT.Sensor_Ports;  use NXT.Sensor_Ports;

package body NXT.Sound_Sensors is

   --------
   -- Id --
   --------

   function Id (This : Sound_Sensor) return Sensor_Id is
   begin
      return This.Id;
   end Id;

   -----------------
   -- Sound_Level --
   -----------------

   function Sound_Level (This : Sound_Sensor) return Integer is
      Raw : constant Integer := Integer (NXT.AVR.Raw_Input (This.Id));
   begin
      return ((Max_Raw - Raw) * 100 / Max_Raw);
   end Sound_Level;

   ------------------
   -- Use_DBA_Mode --
   ------------------

   procedure Use_DBA_Mode (This : in out Sound_Sensor) is
   begin
      This.DBA_Mode := True;
      Set_Pin_State (This.Id, Digital_0, Low);
      Set_Pin_State (This.Id, Digital_1, High);
   end Use_DBA_Mode;

   -----------------
   -- Use_DB_Mode --
   -----------------

   procedure Use_DB_Mode (This : in out Sound_Sensor) is
   begin
      This.DBA_Mode := False;
      Set_Pin_State (This.Id, Digital_0, High);
      Set_Pin_State (This.Id, Digital_1, Low);
   end Use_DB_Mode;

   --------------
   -- DBA_Mode --
   --------------

   function DBA_Mode (This : Sound_Sensor) return Boolean is
   begin
      return This.DBA_Mode;
   end DBA_Mode;

end NXT.Sound_Sensors;
