task body getDistanceSensorDataTask is
		Next_Time : Time := Clock ;
		LSensor : Distance_Sensor := Make (Sensor_3, Floodlight_On => True);
	begin
		NXT.AVR.Await_Data_Available;
		loop
			Next_Time := Next_Time + getDistanceSensorDataTaskPeriod ;
			--lightSensorObject.putLightData(LSensor.Light_Value);
			lightSensorObject.putLightData(Integer (NXT.AVR.Raw_Input (Sensor_1)));
			delay until Next_Time ;
		end loop ;
end getLightSensorDataTask ;


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
