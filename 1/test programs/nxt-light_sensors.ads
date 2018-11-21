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

--  Abstract data type representing the NXT light sensor

pragma Restrictions (No_Streams);

package NXT.Light_Sensors is
   pragma Elaborate_Body;

   type Light_Sensor (<>) is tagged limited private;
   --  An abstract data type representing the Lego light sensor.
   --  By making the type indefinite, we force an initialization when objects
   --  are declared, thereby ensuring a call to a constructor function

   function Id (This : Light_Sensor) return Sensor_Id;
   --  Returns the sensor identifier assigned to this sensor

   function Light_Value (This : Light_Sensor) return Integer;
   --  Returns the calibrated and normalized brightness of the white light
   --  detected. The value is between 0 and 100%, with 0 = absolute darkness
   --  and 100 = intense sunlight

   function Normalized_Light_Value (This : Light_Sensor) return Integer;
   --  Returns the normalized light reading

   procedure Calibrate_Low (This : in out Light_Sensor);
   --  Calibrate for lowest light input value

   procedure Calibrate_High (This : in out Light_Sensor);
   --  Calibrate for highest light input value

   procedure Set_High (This : in out Light_Sensor;  Value : Integer);
   --  Set the normalized value corresponding to reading 100%

   procedure Set_Low (This : in out Light_Sensor;  Value : Integer);
   --  Set the normalized value corresponding to reading 0%

   function Get_High (This : Light_Sensor) return Integer;
   --  The highest raw light value This sensor returns from intense bright
   --  light

   function Get_Low (This : Light_Sensor) return Integer;
   --  The lowest raw light value This sensor returns in total darkness

   function Floodlight_Color (This : Light_Sensor) return Color;
   --  returns Red when the This.Floodlight is enabled, otherwise No_Color

   procedure Enable_Floodlight (This : in out Light_Sensor; Enabled : Boolean);
   --  Controls whether This.Floodlight is on or off

   function Floodlight_On (This : Light_Sensor) return Boolean;
   --  Returns whether or not This.Floodlight is on

private

   Max_Raw : constant := 1023;  -- max reading from A/D converter
   Min_Raw : constant := 0;     -- min reading from A/D converter

   --  the raw input value varies inversely with the brightness of the light

   type Light_Sensor is tagged limited
      record
         Id         : Sensor_Id;
         Low        : Integer := Max_Raw;
         High       : Integer := Min_Raw;
         Floodlight : Boolean := False;
      end record;

end NXT.Light_Sensors;
