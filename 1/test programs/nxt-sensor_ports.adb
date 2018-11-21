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

package body NXT.Sensor_Ports is

   -----------
   -- Reset --
   -----------

   procedure Reset (Port : Sensor_Id) is
      RS485_Port : constant Sensor_Id := Sensor_4;
   begin
      --  reset the port to be normal digital I/O
      Set_Pin_Mode (Port, Digital_0, Output);
      Set_Pin_Mode (Port, Digital_1, Output);
      --  and set the output to be zero
      Set_Pin_State (Port, Digital_0, Low);
      Set_Pin_State (Port, Digital_1, Low);
      --  if this is the port with the RS485 on it, reset those pins as well
      if Port = RS485_Port then
         PIOA_PER   := PIO_PA5 or PIO_PA6 or PIO_PA7;
         PIOA_PUDR  := PIO_PA5 or PIO_PA6 or PIO_PA7;
         PIOA_OER   := PIO_PA5 or PIO_PA6 or PIO_PA7;
         PIOA_CODR  := PIO_PA5 or PIO_PA6 or PIO_PA7;
      end if;
      --  reset the power being supplied to the port
      Set_Input_Power (Port, Standard_Power);
   end Reset;

   ---------------------
   -- Reset_All_Ports --
   ---------------------

   procedure Reset_All_Ports is
   begin
      for Port in Sensor_Id loop
         Reset (Port);
      end loop;
   end Reset_All_Ports;

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Pin_Mode (Port : Sensor_Id; Pin : Pin_Id; Mode : Modes) is
      At_Pin : constant Unsigned_32 := Sensor_Pins (Port).Pins (Pin);
   begin
      PIOA_PUDR := At_Pin;
      case Mode is
         when Off =>
            PIOA_ODR := At_Pin;
            PIOA_PDR := At_Pin;
         when Input =>
            PIOA_PER := At_Pin;
            PIOA_ODR := At_Pin;
         when Output =>
            PIOA_PER := At_Pin;
            PIOA_OER := At_Pin;
         when ADC =>
            PIOA_ODR := At_Pin;
            PIOA_PER := At_Pin;
      end case;
      if Pin = Digital_1 then
         if Mode = ADC then
            ADC_CHER := Sensor_Pins (Port).ADC_Channel_Number;
         else
            ADC_CHDR := Sensor_Pins (Port).ADC_Channel_Number;
         end if;
      end if;
   end Set_Pin_Mode;

   -------------------
   -- Current_State --
   -------------------

   function Current_State (Port : Sensor_Id; Pin : Pin_Id) return Pin_States is
   begin
      if (Sensor_Pins (Port).Pins (Pin) and PIOA_PDSR) /= 0 then
         return High;
      else
         return Low;
      end if;
   end Current_State;

   ---------------
   -- Set_State --
   ---------------

   procedure Set_Pin_State
     (Port : Sensor_Id;
      Pin   : Pin_Id;
      Value : Pin_States)
   is
      At_Pin : constant Unsigned_32 := Sensor_Pins (Port).Pins (Pin);
   begin
      if Value = High then
         PIOA_SODR := At_Pin;
      else
         PIOA_CODR := At_Pin;
      end if;
   end Set_Pin_State;

   ---------------------
   -- Set_Input_Power --
   ---------------------

   procedure Set_Input_Power (Port : Sensor_Id;  Kind : Sensor_Power) is
   begin
      NXT.AVR.Set_Input_Power (Port, Kind);
   end Set_Input_Power;

end NXT.Sensor_Ports;
