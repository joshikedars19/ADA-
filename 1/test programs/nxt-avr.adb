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

with Ada.Real_Time;  use Ada.Real_Time;
with NXT.Filtering;
with NXT.Buffers;
with NXT.Priorities;

with Memory_Compare;  -- needed for linking

package body NXT.AVR is

   package Outgoing_Messages is new NXT.Buffers (Outgoing_AVR_Message);
   --  Note the buffer abstraction provided by this package is not thread safe.
   --  Neither mutual exclusion nor condition synchronization are provided.
   --  Messages may be lost or corrupted.  Message corruption is detected
   --  via checksum computation.
   --  This approach is a cleanup of the original design that had the same
   --  behavior but was more likely to lose messages.  To be addressed in a
   --  future release.
   use Outgoing_Messages;

   Outgoing_Buffer_Size : constant := 5;
   --  This capacity choice is arbitrary.  Note that values are overwritten
   --  when inserting into a full buffer, i.e., no blocking occurs.

   Outgoing : Outgoing_Messages.Buffer (Capacity => Outgoing_Buffer_Size);

   IO_Interval       : constant Time_Span := Milliseconds (10);
   AVR_Init_Interval : constant Time_Span := Milliseconds (20);

   package Button_Inputs is new NXT.Filtering (Button_Id, No_Button);
   --  Provides noise filtering for button presses

   Max_Samples_Required : constant := 4;
   --  The number of successive detected (sampled) button presses required
   --  before we believe a real button press has occurred. Requires tuning,
   --  since too large a number results in sluggish response, and too low a
   --  number might allow noise through.

   Button_Noise : Button_Inputs.Filter (Max_Samples_Required);
   --  a noise filter for all incoming buttons

   Max_Samples_Power_Forced : constant := 150;
   --  The number of successive sampled presses of the power button required
   --  for a forced power off to be recognized

   Forced_Off : Button_Inputs.Filter (Max_Samples_Power_Forced);
   --  a filter for detecting a forced power down request (ie the user holds
   --  down the power button for a certain amount of time)

   Data_Available : Boolean := False;
   --  A flag for detecting when to signal that data is initially available.
   --  Once true, it stays true.
   pragma Atomic (Data_Available);

   procedure Update_Outputs (This_Msg : Incoming_AVR_Message);
   --  Assign the global variables exported in the package spec based on the
   --  data in This_Msg

   ----------
   -- Pump --
   ----------

   task Pump is
      pragma Storage_Size (4096);
      pragma Priority (NXT.Priorities.AVR_IO_Pump_Priority);
   end Pump;

   ----------
   -- Pump --
   ----------

   task body Pump is
      Next_Outgoing_Msg : Outgoing_AVR_Message := Null_Outgoing_Msg;
      Next_Incoming_Msg : Incoming_AVR_Message;
      Checksum_Valid    : Boolean := False;
   begin
      Send_Initialization;
      delay until Clock + AVR_Init_Interval;

      loop
         if not Empty (Outgoing) then
            Remove (Next_Outgoing_Msg, From => Outgoing);
         end if;

         Send_To_AVR (Next_Outgoing_Msg); -- we always send something
         delay until Clock + IO_Interval;

         Receive_From_AVR (Next_Incoming_Msg, Checksum_Valid);
         delay until Clock + IO_Interval;

         if Checksum_Valid then
            Update_Outputs (Next_Incoming_Msg);
         end if;
      end loop;
   end Pump;

   --------------------
   -- Update_Outputs --
   --------------------

   procedure Update_Outputs (This_Msg : Incoming_AVR_Message) is
      Sampled_Button : Button_Id;
      use Button_Inputs;
   begin
      if not Data_Available then
         Data_Available := True;
      end if;
      Sampled_Button := Decoded_Button (From => This_Msg);
      Button := Filtered (Button_Noise, Sampled_Button);
      Raw_Input := Raw_Inputs (From => This_Msg);
      Raw_Battery := Battery_Reading (From => This_Msg);
      --  Check for forced power off
      if Filtered (Forced_Off, Button) = Power_Button then
         Power_Down;
      end if;
   end Update_Outputs;

   ----------------
   -- Power_Down --
   ----------------

   procedure Power_Down is
   begin
      Insert (Power_Down_Message, Into => Outgoing);
   end Power_Down;

   ---------------
   -- Set_Power --
   ---------------

   procedure Set_Power
     (Motor : Motor_Id;
      Power : PWM_Value;
      Brake : Boolean)
   is
   begin
      Insert (Set_Motor_Message (Motor, Power, Brake), Into => Outgoing);
   end Set_Power;

   ---------------------
   -- Set_Input_power --
   ---------------------

   procedure Set_Input_Power (Port : Sensor_Id; Power_Type : Sensor_Power) is
   begin
      Insert (Set_Sensor_Power_Message (Port, Power_Type), Into => Outgoing);
   end Set_Input_Power;

   --------------------------
   -- Await_Data_Available --
   --------------------------

   procedure Await_Data_Available is
      Interval : constant Time_Span := AVR_Init_Interval + (2 * IO_Interval);
      --  Before data are available from the AVR we must both initialize it
      --  and perform at least one send and receive operation
   begin
      while not Data_Available loop
         delay until Clock + Interval;
      end loop;
   end Await_Data_Available;

end NXT.AVR;
