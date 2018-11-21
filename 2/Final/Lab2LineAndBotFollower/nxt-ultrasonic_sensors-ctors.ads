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

--  Constructors for the abstract data type representing the NXT light sensor

package NXT.Ultrasonic_Sensors.Ctors is

   function Make
     (Port : Sensor_Id)
      return Ultrasonic_Sensor;
   --  Constructs a Lego ultrasonic sensor object using the port specified.
   --  Selects "lego mode" for the port, as this is always necessary.
   --  Selects "continuous" mode.
   --  Sets the device address to 2.

   function Make
     (Port           : Sensor_Id;
      Device_Address : Unsigned_32;
      Mode           : Commanded_Operating_Mode)
      return Ultrasonic_Sensor;
   --  Constructs a Lego ultrasonic sensor object using the port specified.
   --  Sets the device address for the chip within the ultrasonic sensor to the
   --  value specified. Note that the value 2 is likely always required.
   --  Selects "lego mode" for the port, as this is always necessary.
   --  Sets the operating mode to the value specified.

end NXT.Ultrasonic_Sensors.Ctors;
