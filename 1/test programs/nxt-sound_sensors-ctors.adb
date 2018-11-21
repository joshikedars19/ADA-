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

pragma Warnings (Off, "unit ""MALLOC"" is not referenced");
with NXT.Malloc;
--  NXT.Malloc is required because the compiler references __gnat_malloc in the
--  implementation of build-in-place functions, although it will not use it at
--  run-time (if it did our NXT implementation would raise P_E)
pragma Warnings (On);

with NXT.Sensor_Ports;  use NXT.Sensor_Ports;

package body NXT.Sound_Sensors.Ctors is

   ----------
   -- Make --
   ----------

   function Make (Port : Sensor_Id;  DBA_Mode : Boolean)
      return Sound_Sensor
   is
   begin
      return Result : Sound_Sensor do
         Result.Id := Port;

         Set_Input_Power (Port, Standard_Power);

         Set_Pin_Mode (Port, Digital_0, Output);
         Set_Pin_Mode (Port, Digital_1, Output);

         --  set pin states
         if DBA_Mode then
            Use_DBA_Mode (Result);
         else
            Use_DB_Mode (Result);
         end if;
      end return;
   end Make;

end NXT.Sound_Sensors.Ctors;
