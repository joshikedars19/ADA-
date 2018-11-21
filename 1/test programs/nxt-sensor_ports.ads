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

--  Low level controls for sensor port hardware

with Interfaces;     use Interfaces;
with NXT.Registers;  use NXT.Registers;

package NXT.Sensor_Ports is
   pragma Elaborate_Body;

   procedure Reset (Port : Sensor_Id);

   procedure Reset_All_Ports;

   type Pin_Id is (Digital_0, Digital_1);
   pragma Discard_Names (Pin_Id);

   type Modes is (Off, Input, Output, ADC);
   pragma Discard_Names (Modes);

   procedure Set_Pin_Mode (Port : Sensor_Id;  Pin : Pin_Id;  Mode : Modes);

   type Pin_States is (Low, High);
   pragma Discard_Names (Pin_States);

   function Current_State (Port : Sensor_Id; Pin : Pin_Id) return Pin_States;

   procedure Set_Pin_State
     (Port  : Sensor_Id;
      Pin   : Pin_Id;
      Value : Pin_States);

   procedure Set_Input_Power (Port : Sensor_Id;  Kind : Sensor_Power);

   type Digital_Pins is array (Pin_Id) of Unsigned_32;

   type Port_Pins is
      record
         Pins                : Digital_Pins;
         ADC_Channel_Number  : Unsigned_32;
         ADC_Data_Reg_Number : Unsigned_32;
      end record;

   Sensor_Pins : constant array (Sensor_Id) of Port_Pins :=
     (((PIO_PA23, PIO_PA18), ADC_CH1, ADC_CDR1),
      ((PIO_PA28, PIO_PA19), ADC_CH2, ADC_CDR2),
      ((PIO_PA29, PIO_PA20), ADC_CH3, ADC_CDR3),
      ((PIO_PA30, PIO_PA2),  ADC_CH7, ADC_CDR7));

end NXT.Sensor_Ports;
