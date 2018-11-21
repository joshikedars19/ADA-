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

--  This package provides the low-level interface to the AVR. Higher-level
--  abstractions used by application code will access this package, although
--  application code may access this package directly when necessary (e.g., to
--  call the Power_Down routine). All access to the current button and raw
--  inputs are through this package.

--  Note that this package initializes the AVR automatically.

with NXT.AVR_IO;  use NXT.AVR_IO;
with Interfaces;  use Interfaces;

package NXT.AVR is
   pragma Elaborate_Body;

   procedure Power_Down;
   --  Send a power-down message to the AVR

   procedure Set_Power
     (Motor : Motor_Id;
      Power : PWM_Value;
      Brake : Boolean);
   --  Send motor control message to the AVR

   procedure Await_Data_Available;
   --  Wait until at least one set of messages has been sent and received
   --  from the AVR, such that the data below are now available to be accessed.
   --  To be called once, prior to accessing the sampled values declared below.

   --  The following are the sole means of acquiring the values. In other
   --  words, abstractions and application code should not interact with the
   --  AVR to get them. These objects are to be treated as strictly read-only.
   --  They are updated periodically by an task internal to this package. Any
   --  other updates will be overwritten by that task. Access to the individual
   --  values is thread-safe.

   Button : Button_Id;
   pragma Atomic (Button);
   --  The most recent single button actively pressed, if any, received from
   --  the AVR. The value will be No_Button when no button press is detected.

   Raw_Input : Raw_ADC_Inputs;
   --  The most recent A/D input readings received from the AVR for the four
   --  sensors.  The type Raw_ADC_Inputs has Atomic_Components applied.

   Raw_Battery : Unsigned_16;
   pragma Atomic (Raw_Battery);
   --  The most recent battery voltage reading received from the AVR. Units are
   --  millivolts. The bit indicating use of rechargeable batteries is
   --  included in the value.

   procedure Set_Input_Power (Port : Sensor_Id; Power_Type : Sensor_Power);
   --  Control the power supplied to an input sensor

end NXT.AVR;
