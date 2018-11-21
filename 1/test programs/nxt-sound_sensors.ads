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

--  Abstract data type representing the NXT sound sensor

pragma Restrictions (No_Streams);

package NXT.Sound_Sensors is
   pragma Elaborate_Body;

   type Sound_Sensor (<>) is tagged limited private;
   --  NB: by making the type indefinite, we force an initialization when
   --  objects are declared, thereby ensuring a call to a constructor function

   function Id (This : Sound_Sensor) return Sensor_Id;
   --  Returns the sensor identifier assigned to this sensor

   function Sound_Level (This : Sound_Sensor) return Integer;
   --  returns the current sensor value as a percentage

   procedure Use_DBA_Mode (This : in out Sound_Sensor);
   --  causes This sensor to use DBA mode

   procedure Use_DB_Mode (This : in out Sound_Sensor);
   --  causes This sensor to use DB mode

   function DBA_Mode (This : Sound_Sensor) return Boolean;
   --  returns whether This sensor is using DBA mode. When it returns False the
   --  sensor is in DB mode.

private

   Max_Raw : constant := 1023;  -- max reading from A/D converter

   --  the raw input value varies inversely with the volume of the sound

   type Sound_Sensor is tagged limited
      record
         Id       : Sensor_Id;
         DBA_Mode : Boolean;
      end record;

end NXT.Sound_Sensors;
