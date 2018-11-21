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

with NXT.TWI;
with Memory_Set;

package body NXT.AVR_IO is

   type Outgoing_Message_As_Bytes is array (0 .. 8) of Unsigned_8;
   --  represents an Outgoing_AVR_Message as a sequence of bytes for the sake
   --  of computing the checksum

   type Incoming_Message_As_Bytes is array (0 .. 12) of Unsigned_8;
   --  represents an Incoming_AVR_Message as a sequence of bytes for the sake
   --  of computing the checksum

   AVR_String : constant String :=
     Character'Val (16#CC#) & "Let's samba nxt arm in arm, (c)LEGO System A/S";
   --  mandatory initial string

   AVR_Address : constant NXT.TWI.Device_Id := 1;
   --  TWI address for the AVR itself

   Current_Power_Settings : PWM_Output_Values := (others => 0);
   --  All power settings are sent each time a message is sent to the AVR and
   --  it will react accordingly, setting the power levels for all motors, not
   --  just the one specified to Set_Motor_Message for example. Thus we have to
   --  retain the values from previous calls so that we can send them each
   --  time.

   Current_Output_Modes  : Motor_Braking_Modes := (others => No_Braking);
   --  All braking modes are sent each time a message is sent to the AVR so we
   --  have to retain the values from previous calls so that we can send them
   --  each time.

   Current_Input_Power : Sensor_Power_Control :=
      (Pulsed_9V   => (others => False),
       Constant_9V => (others => False));
   --  All sensor power settings are sent each time a message is sent to the
   --  AVR so we have to retain the values from previous calls so that we can
   --  send them each time.

   -------------------------
   -- Send_Initialization --
   -------------------------

   procedure Send_Initialization is
   begin
      NXT.TWI.Send (AVR_Address, 0, AVR_String'Address, AVR_String'Length);
   end Send_Initialization;

   ----------------
   -- Send_Frame --
   ----------------

   procedure Send_To_AVR (This : Outgoing_AVR_Message) is
      Outgoing : Outgoing_AVR_Message;
      Checksum : Unsigned_8;
      Bytes    : Outgoing_Message_As_Bytes;
      for Bytes'Address use Outgoing'Address;
   begin
      Outgoing := This;
      Checksum := 0;
      --  skip last byte since that will hold the checksum we compute here
      for I in Bytes'First .. Bytes'Last - 1 loop
         Checksum := Checksum + Bytes (I);
      end loop;
      Outgoing.Checksum := not Checksum;

      NXT.TWI.Send (AVR_Address, 0, Outgoing'Address, Outgoing'Size / 8);
   end Send_To_AVR;

   ----------------------
   -- Receive_From_AVR --
   ----------------------

   procedure Receive_From_AVR
     (This  : out Incoming_AVR_Message;
      Valid : out Boolean)
   is
      Checksum : Unsigned_8;
      Incoming : Incoming_AVR_Message;
      Bytes    : Incoming_Message_As_Bytes;
      for Bytes'Address use Incoming'Address;
   begin
      NXT.TWI.Recv (AVR_Address, 0, Incoming'Address, Incoming'Size / 8);
      Checksum := 0;
      for I in Bytes'Range loop
         Checksum := Checksum + Bytes (I);
      end loop;
      if Checksum /= 16#FF# then
         Valid := False;
      else
         Valid := True;
         This := Incoming;
      end if;
   end Receive_From_AVR;

   ------------------------
   -- Power_Down_Message --
   ------------------------

   function Power_Down_Message return Outgoing_AVR_Message is
      Result : Outgoing_AVR_Message;
   begin
      Result.Power_Command := 16#5A#;
      return Result;
   end Power_Down_Message;

   ------------------------------
   -- Set_Sensor_Power_Message --
   ------------------------------

   function Set_Sensor_Power_Message
     (Port       : Sensor_Id;
      Power_Type : Sensor_Power)
      return Outgoing_AVR_Message
   is
      Result : Outgoing_AVR_Message;
   begin
      Result.Power_Command := 0;
      Result.PWM_Frequency := 8;
      Result.PWM_Values := Current_Power_Settings;
      Result.Output_Mode := Current_Output_Modes;
      --  The power to the sensor is controlled by a bit in each of the two
      --  nibbles of the byte. There is one bit for each of the four sensors.
      --  If the low nibble bit is set then the sensor is "ACTIVE" and 9v is
      --  supplied to it but it will be pulsed off to allow the sensor to be
      --  read. A 1 in the high nibble indicates that it is a 9v "always on"
      --  sensor and 9v will be supplied constantly. If both bits are clear
      --  then 9v is not supplied to the sensor. Having both bits set is
      --  currently not supported.
      case Power_Type is
         when Standard_Power =>
            Current_Input_Power.Constant_9V (Port) := False;
            Current_Input_Power.Pulsed_9V (Port)   := False;
         when RCX_9V =>
            Current_Input_Power.Constant_9V (Port) := True;
         when NXT_9V =>
            Current_Input_Power.Pulsed_9V (Port) := True;
      end case;
      Result.Input_Power := Current_Input_Power;
      return Result;
   end Set_Sensor_Power_Message;

   -----------------------
   -- Set_Motor_Message --
   -----------------------

   function Set_Motor_Message
     (Motor : Motor_Id;
      Power : PWM_Value;
      Brake : Boolean)
      return Outgoing_AVR_Message
   is
      This_Motor : constant Integer := Motor_Id'Pos (Motor);
      Result     : Outgoing_AVR_Message;
   begin
      Result.Power_Command := 0;
      Result.PWM_Frequency := 8;
      Current_Power_Settings (This_Motor) := Power;
      Result.PWM_Values := Current_Power_Settings;
      if Power /= 0 then
         Current_Output_Modes (This_Motor) := Braking;
         --  This is very strange, but true. We must set the bit high,
         --  otherwise the motor acts as if the brake is indeed applied. If we
         --  don't do so, specifying a low power setting can result in the
         --  motor not rotating, presumably because the motor has to have
         --  enough power to overcome the brake. So in other words setting the
         --  bit high disables the brake when power is non-zero!
      else --  power will be going to zero
         --  The strange thing here, relative to the above use, is that these
         --  are indeed the proper values required for controlling the brake
         --  *when stopping the motor*. This means, however, that one cannot
         --  apply non-zero power to the brake, which may be useful when one
         --  must overcome some external torque on the wheel when stopped
         --  (e.g., when stopped on an incline and the default braking power is
         --  insufficient).
         if Brake then
            Current_Output_Modes (This_Motor) := Braking;
         else
            Current_Output_Modes (This_Motor) := No_Braking;
         end if;
      end if;
      Result.Output_Mode := Current_Output_Modes;
      Result.Input_Power := Current_Input_Power;
      return Result;
   end Set_Motor_Message;

   ----------------
   -- Raw_Inputs --
   ----------------

   function Raw_Inputs (From : Incoming_AVR_Message) return Raw_ADC_Inputs is
   begin
      return From.Inputs;
   end Raw_Inputs;

   --------------------
   -- Decoded_Button --
   --------------------

   function Decoded_Button (From : Incoming_AVR_Message) return Button_Id is
   begin
      if From.Buttons >= 16#7FF# then
         return Power_Button;
      end if;
      if From.Buttons > 16#300# then
         return Middle_Button;
      elsif From.Buttons > 16#100# then
         return Right_Button;
      elsif From.Buttons > 16#60# then
         return Left_Button;
      end if;
      return No_Button;
   end Decoded_Button;

   ---------------------
   -- Battery_Reading --
   ---------------------

   function Battery_Reading (From : Incoming_AVR_Message) return Unsigned_16 is
   begin
      return From.Battery;
   end Battery_Reading;

end NXT.AVR_IO;
