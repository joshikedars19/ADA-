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

with NXT.Sensor_Ports;
with NXT.I2C_Ports;

package body NXT.Ultrasonic_Sensors is

   ---------------------
   -- Initialize_Port --
   ---------------------

   procedure Initialize_Port
     (This : in out Ultrasonic_Sensor;
      Port : Sensor_Id)
   is
      pragma Unreferenced (This);
      use NXT.Sensor_Ports, NXT.I2C_Ports;
   begin
      Set_Input_Power (Port, NXT_9V);
      Set_Pin_Mode (Port, Digital_0, Output);
      Set_Pin_Mode (Port, Digital_1, Output);
      Set_Pin_State (Port, Digital_0, Low);
      Set_Pin_State (Port, Digital_1, Low);
      --  It is essential, when driving the Lego ultrasonic sensor, that we
      --  operate in "Lego" mode. Otherwise the sensor will not interact
      --  properly at the I2C level.
      Configure_I2C_Port (Port, Lego_Mode);
   end Initialize_Port;

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode
     (This : in out Ultrasonic_Sensor;
      Mode : Commanded_Operating_Mode)
   is
      New_Mode    : Commanded_Operating_Mode := Mode;
      Delay_Value : Time_Span := Time_Span_Zero;
      Outgoing    : aliased Unsigned_8;
      Result      : Integer;
   begin
      case Mode is
         when Reset =>
            New_Mode := Off;
         when Ping =>
            Delay_Value := Delay_Data_Ping;
         when Off | Capture | Continuous =>
            Delay_Value := Delay_Data_Other;
      end case;
      Outgoing := Operating_Mode'Pos (Mode);
      Send_Data
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Mode_Register,
         Outgoing'Address,
         Length => 1,
         Result => Result);
      if Result = 0 then
         This.Data_Available_Time := Clock + Delay_Value;
         This.Mode := New_Mode;
      else
         raise Operating_Error;
      end if;
   end Set_Mode;

   --------------------
   -- Commanded_Mode --
   --------------------

   function Commanded_Mode (This : Ultrasonic_Sensor) return Operating_Mode is
   begin
      return This.Mode;
   end Commanded_Mode;

   ------------------------
   -- Query_Current_Mode --
   ------------------------

   procedure Query_Current_Mode
     (This : in out Ultrasonic_Sensor;
      Mode : out Operating_Mode)
   is
      Incoming : aliased Unsigned_8;
      Result   : Integer;
   begin
      Get_Data
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Mode_Register,
         Incoming'Address,
         Length => 1,
         Result => Result);
      if Result /= 0 then
         Mode := Error;
      else
         Mode := Operating_Mode'Val (Incoming);
      end if;
   end Query_Current_Mode;

   -----------
   -- Reset --
   -----------

   procedure Reset (This : in out Ultrasonic_Sensor) is
   begin
      Set_Mode (Ultrasonic_Sensor'Class (This), Reset);
   end Reset;

   ----------
   -- Ping --
   ----------

   procedure Ping (This : in out Ultrasonic_Sensor) is
   begin
      Set_Mode (Ultrasonic_Sensor'Class (This), Ping);
      --  note this also makes the sensor issue a ping and sample the results
   end Ping;

   ---------
   -- Off --
   ---------

   procedure Off (This : in out Ultrasonic_Sensor) is
   begin
      Set_Mode (Ultrasonic_Sensor'Class (This), Off);
   end Off;

   ------------------
   -- Get_Distance --
   ------------------

   procedure Get_Distance
     (This    : in out Ultrasonic_Sensor;
      Reading : out Natural)
   is
      Delay_Value : Time_Span;
      Incoming    : aliased Unsigned_8;
      Result      : Integer;
   begin
      case This.Mode is
         when Off | Error =>
            raise Operating_Error;
         when Ping =>
            Delay_Value := Delay_Data_Ping;
         when others =>
            Delay_Value := Delay_Data_Other;
      end case;
      delay until This.Data_Available_Time;
      Get_Data
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Distance_Register,
         Incoming'Address,
         Length => 1,
         Result => Result);
      if Result /= 0 then
         Reading := Default_Distance;
      else
         This.Data_Available_Time := Clock + Delay_Value;
         Reading := Natural (Incoming);
      end if;
   end Get_Distance;

   -------------------
   -- Get_Distances --
   -------------------

   procedure Get_Distances
     (This      : in out Ultrasonic_Sensor;
      Readings  : out Distances;
      Actual    : out Natural)
   is
   begin
      Get_Distances (This, Readings'Length, 0, Readings, Actual);
   end Get_Distances;

   -------------------
   -- Get_Distances --
   -------------------

   procedure Get_Distances
     (This      : in out Ultrasonic_Sensor;
      Requested : Distances_Index;
      Offset    : Natural;
      Readings  : out Distances;
      Actual    : out Natural)
   is
      Delay_Value : Time_Span := Delay_Data_Other;
      Incoming    : aliased array (Distances_Index) of Unsigned_8;
      Result      : Integer;
      Max_Length  : Distances_Index := Requested;

      Readings_Offset : constant Natural := Readings'First - Incoming'First;
      --  we don't know that the actual for Readings uses a 1-based index
   begin
      case This.Mode is
         when Off | Error =>
            raise Operating_Error;
         when Ping =>
            Delay_Value := Delay_Data_Ping;
         when Continuous =>
            Max_Length := 1;
         when others =>
            null;
      end case;
      delay until This.Data_Available_Time;
      Get_Data
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Distance_Register,
         Incoming'Address,
         Length => Max_Length,
         Result => Result);
      Actual := 0;
      if Result = 0 then
         for K in 1 .. Max_Length loop
            exit when Incoming (K) = Default_Distance;
            Readings (K + Offset + Readings_Offset) := Incoming (K);
            Actual := Actual + 1;
         end loop;
         This.Data_Available_Time := Clock + Delay_Value;
      end if;
   end Get_Distances;

   ---------------
   -- Get_Units --
   ---------------

   procedure Get_Units
     (This    : in out Ultrasonic_Sensor;
      Units   : out Units_String;
      Success : out Boolean)
   is
      use NXT.I2C_Sensors;
   begin
      Fetch_String
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Register => Units_Register,
         Length   => 8,
         Fetched  => Units,
         Success  => Success);
   end Get_Units;

   ----------------------
   -- Get_Factory_Data --
   ----------------------

   procedure Get_Factory_Data
     (This    : in out Ultrasonic_Sensor;
      Info    : out Data;
      Success : out Boolean)
   is
   begin
      Fetch_Multiple_Bytes
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Factory_Data_Register,
         Info,
         Success);
   end Get_Factory_Data;

   --------------------------
   -- Get_Calibration_Data --
   --------------------------

   procedure Get_Calibration_Data
     (This    : in out Ultrasonic_Sensor;
      Info    : out Data;
      Success : out Boolean)
   is
   begin
      Fetch_Multiple_Bytes
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Calibration_Register,
         Info,
         Success);
   end Get_Calibration_Data;

   --------------------------
   -- Set_Calibration_Data --
   --------------------------

   procedure Set_Calibration_Data
     (This    : in out Ultrasonic_Sensor;
      Info    : Data;
      Success : out Boolean)
   is
   begin
      Set_Multiple_Bytes
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Calibration_Register,
         Info,
         Success);
   end Set_Calibration_Data;

   -----------------------------
   -- Get_Continuous_Interval --
   -----------------------------

   procedure Get_Continuous_Interval
     (This    : in out Ultrasonic_Sensor;
      Info    : out Unsigned_8;
      Success : out Boolean)
   is
      Incoming : aliased Unsigned_8;
      Result   : Integer;
   begin
      Get_Data
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Continuous_Interval_Register,
         Incoming'Address,
         Length => 1,
         Result => Result);
      if Result = 0 then
         Info := Incoming;
         Success := True;
      else
         Success := False;
      end if;
   end Get_Continuous_Interval;

   -----------------------------
   -- Set_Continuous_Interval --
   -----------------------------

   procedure Set_Continuous_Interval
     (This    : in out Ultrasonic_Sensor;
      Info    : Unsigned_8;
      Success : out Boolean)
   is
      Outgoing : aliased Unsigned_8;
      Result   : Integer;
   begin
      Outgoing := Info;
      Send_Data
        (Ultrasonic_Sensor'Class (This), -- redispatch if necessary
         Continuous_Interval_Register,
         Outgoing'Address,
         Length => 1,
         Result => Result);
      Success := Result = 0;
   end Set_Continuous_Interval;

   ---------------
   -- Send_Data --
   ---------------

   overriding
   procedure Send_Data
     (This     : in out Ultrasonic_Sensor;
      Register : Unsigned_32;
      Buffer   : System.Address;
      Length   : Positive;
      Result   : out Integer)
   is
   begin
      delay until This.Next_Command_Time;
      --  call the parent version, ie the one without the delay
      Send_Data (I2C_Sensor (This), Register, Buffer, Length, Result);
      This.Next_Command_Time := Clock + Command_Delay;
   end Send_Data;

   --------------
   -- Get_Data --
   --------------

   overriding
   procedure Get_Data
     (This     : in out Ultrasonic_Sensor;
      Register : Unsigned_32;
      Buffer   : System.Address;
      Length   : Positive;
      Result   : out Integer)
   is
   begin
      delay until This.Next_Command_Time;
      --  call the parent version, ie the one without the delay
      Get_Data (I2C_Sensor (This), Register, Buffer, Length, Result);
      This.Next_Command_Time := Clock + Command_Delay;
   end Get_Data;

end NXT.Ultrasonic_Sensors;
