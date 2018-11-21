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
with NXT.Sensor_Ports;

package body NXT.Light_Sensors is

   --------
   -- Id --
   --------

   function Id (This : Light_Sensor) return Sensor_Id is
   begin
      return This.Id;
   end Id;

   -----------------------
   -- Enable_Floodlight --
   -----------------------

   procedure Enable_Floodlight
     (This    : in out Light_Sensor;
      Enabled : Boolean)
   is
      use NXT.Sensor_Ports;
   begin
      This.Floodlight := Enabled;
      if Enabled then
         Set_Pin_State (This.Id, Digital_0, High);
      else
         Set_Pin_State (This.Id, Digital_0, Low);
      end if;
   end Enable_Floodlight;

   -----------------
   -- Light_Value --
   -----------------

   function Light_Value (This : Light_Sensor) return Integer is
      Raw : constant Integer := Integer (NXT.AVR.Raw_Input (This.Id));
   begin
      if This.Low = This.High then
         return 0;
      else
         return 100 * (Raw - This.Low) / (This.High - This.Low);
      end if;
   end Light_Value;

   ----------------------------
   -- Normalized_Light_Value --
   ----------------------------

   function Normalized_Light_Value (This : Light_Sensor) return Integer is
   begin
      return Max_Raw - Integer (NXT.AVR.Raw_Input (This.Id));
   end Normalized_Light_Value;

   -------------------
   -- Calibrate_Low --
   -------------------

   procedure Calibrate_Low (This : in out Light_Sensor) is
   begin
      This.Low := Integer (NXT.AVR.Raw_Input (This.Id));
   end Calibrate_Low;

   --------------------
   -- Calibrate_High --
   --------------------

   procedure Calibrate_High (This : in out Light_Sensor) is
   begin
      This.High := Integer (NXT.AVR.Raw_Input (This.Id));
   end Calibrate_High;

   --------------
   -- Set_High --
   --------------

   procedure Set_High (This : in out Light_Sensor;  Value : Integer) is
   begin
      This.High := Value;
   end Set_High;

   -------------
   -- Set_Low --
   -------------

   procedure Set_Low (This : in out Light_Sensor;  Value : Integer) is
   begin
      This.Low := Value;
   end Set_Low;

   --------------
   -- Get_High --
   --------------

   function Get_High (This : Light_Sensor) return Integer is
   begin
      return This.High;
   end Get_High;

   -------------
   -- Get_Low --
   -------------

   function Get_Low (This : Light_Sensor) return Integer is
   begin
      return This.Low;
   end Get_Low;

   ----------------------
   -- Floodlight_Color --
   ----------------------

   function Floodlight_Color (This : Light_Sensor) return Color is
   begin
      if This.Floodlight then
         return Red;
      else
         return No_Color;
      end if;
   end Floodlight_Color;

   -------------------
   -- Floodlight_On --
   -------------------

   function Floodlight_On (This : Light_Sensor) return Boolean is
   begin
      return This.Floodlight;
   end Floodlight_On;

end NXT.Light_Sensors;
