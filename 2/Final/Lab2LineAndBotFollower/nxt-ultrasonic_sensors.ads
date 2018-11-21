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

--  Abstract data type representing the Lego ultrasonic sensor

pragma Restrictions (No_Streams);

with NXT.I2C_Sensors;  use NXT.I2C_Sensors;
with Interfaces;       use Interfaces;
with Ada.Real_Time;    use Ada.Real_Time;
with System;

package NXT.Ultrasonic_Sensors is
   pragma Elaborate_Body;

   type Ultrasonic_Sensor (<>) is new I2C_Sensor with private;
   --  An abstract data type representing the Lego ultrasonic sensor.
   --  By making the type indefinite, we force an initialization when objects
   --  are declared, thereby ensuring a call to a constructor function

   type Operating_Mode is (Off, Ping, Continuous, Capture, Reset, Error);
   for Operating_Mode use
     (Off        => 0,
      Ping       => 1,
      Continuous => 2,
      Capture    => 3,
      Reset      => 4,
      Error      => 5);
   --  Confirming (matches hardware codes).  NB: order is critical!
   pragma Discard_Names (Operating_Mode);


   subtype Commanded_Operating_Mode is Operating_Mode range Off .. Reset;

   procedure Set_Mode
     (This : in out Ultrasonic_Sensor;
      Mode : Commanded_Operating_Mode);
   --  Set This sensor into the specified mode. The physical device is directly
   --  affected. For example,  a value of Reset will physically reset the
   --  sensor, after which the sensor will be in the "off" mode. A mode value
   --  of Ping puts the device into that mode and issues a single ping, and so
   --  on.



   procedure Get_Distance
     (This    : in out Ultrasonic_Sensor;
      Reading : out Natural);
   --  Gets the current computed distance into Reading. If no object is in
   --  range or if an error occurred, the value is 255.

   subtype Distances_Index is Integer range 1 .. 8;
   type Distances is array (Distances_Index range <>) of Unsigned_8;


   Operating_Error : exception;
   --  Raised when trying something impossible, like getting a distance when
   --  the device is off

   subtype Units_String is String (1 .. 8);

   subtype Data is Multiple_Bytes (1 .. 3);

 
 

private

   --  The Lego ultrasonic sensor uses a "bit-banged" I2C interface and seems
   --  to require a minimum delay between commands, otherwise the commands
   --  fail.
   Command_Delay : constant Time_Span := Milliseconds (5);

   type Ultrasonic_Sensor is new I2C_Sensor with
      record
         Next_Command_Time   : Time := Clock + Command_Delay;
         Data_Available_Time : Time;
         Mode                : Operating_Mode;
      end record;

   overriding
   procedure Send_Data
     (This     : in out Ultrasonic_Sensor;
      Register : Unsigned_32;
      Buffer   : System.Address;
      Length   : Positive;
      Result   : out Integer);
   --  Override the standard version to ensure correct timing when using the
   --  ultrasonic sensor. The Lego ultrasonic sensor uses a "bit-banged" I2C
   --  interface and seems to require a minimum delay between commands.

   overriding
   procedure Get_Data
     (This     : in out Ultrasonic_Sensor;
      Register : Unsigned_32;
      Buffer   : System.Address;
      Length   : Positive;
      Result   : out Integer);
   --  Override the standard version to ensure correct timing when using the
   --  ultrasonic sensor. The Lego ultrasonic sensor uses a "bit-banged" I2C
   --  interface and seems to require a minimum delay between commands.

   --  The following are the addresses for the registers within the Lego
   --  ultrasonic sensor chip
   Factory_Data_Register        : constant := 16#11#;
   Units_Register               : constant := 16#14#;
   Continuous_Interval_Register : constant := 16#40#;
   Mode_Register                : constant := 16#41#;
   Distance_Register            : constant := 16#42#;
   Calibration_Register         : constant := 16#4A#;

   --  The delay values corresponding to when the data become available in the
   --  given mode.
   Delay_Data_Ping  : constant Time_Span := Milliseconds (50);
   Delay_Data_Other : constant Time_Span := Milliseconds (30);

   Default_Distance : constant := 255;
   --  The value returned when no actual value is available. Also represents
   --  "out of range".

   procedure Initialize_Port
     (This : in out Ultrasonic_Sensor;
      Port : Sensor_Id);
   --  Sets Port Id for This sensor. Sets power and pins appropriately. Enables
   --  "Lego Mode".
   --  Intended to be called by constructors.

end NXT.Ultrasonic_Sensors;
