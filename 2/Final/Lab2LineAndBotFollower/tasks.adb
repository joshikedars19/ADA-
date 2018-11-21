with Ada.Real_Time ;			use Ada.Real_Time ;
with NXT.Motor_Controls ;		use NXT.Motor_Controls ;
with NXT.Touch_Sensors ;		use NXT.Touch_Sensors ;
with NXT ;
with System ;			--use System ;
with NXT.AVR;			--use NXT.AVR ;
with NXT.Display ;		use NXT.Display ;
with NXT.Light_Sensors;		use NXT.Light_Sensors;
with NXT.Light_Sensors.Ctors;	use NXT.Light_Sensors.Ctors;
with NXT.Ultrasonic_Sensors ;	use NXT.Ultrasonic_Sensors ;
with NXT.Ultrasonic_Sensors.Ctors ; use NXT.Ultrasonic_Sensors.Ctors ;

package body tasks is

	-- Periods for different tasks. --
	getLightSensorDataTaskPeriod   : constant Time_Span := milliseconds(30) ;		
	calculatePIDValuesTaskPeriod   : constant Time_Span := milliseconds(60) ;
	findDistanceTaskPeriod	       : constant Time_Span := milliseconds(100) ;

	-- Priorities for different tasks. --
	getLightSensorDataTaskPriority : constant System.Priority := System.Priority'First + 1 ;
	calculatePIDValuesTaskPriority : constant System.Priority := System.Priority'First + 2 ;
	findDistanceTaskPriority       : constant System.Priority := System.Priority'First + 3 ;
	
	-- Storage Size for different tasks. --
	calculatePIDValuesTaskStorage  : constant Integer := 8192 ;
	getLightSensorDataTaskStorage  : constant Integer := 4096 ;
	findDistanceTaskStorage        : constant Integer := 2048 ;

	procedure backgroundProcedure is
	begin
		loop
			null ;
		end loop ;
	end backgroundProcedure ;

	
	-- Protected object to store data from Distance Sensor.
	-- Procedures :
	--				putDistanceData(DistanceData: Integer) procedure to store most recently captured Distance Sensor Value.
	-- Functions :
	--				getDistanceData return Integer function to return the most recently stored Distance Sensor Value.
	-- Private Members :
	--			DistanceValue : Integer variable to store distance sensor value. Initiliazed to maximum of Distance Sensor Value.
	protected distanceSensorObject is
		procedure putDistanceData(DistanceData : Integer ) ;
		function getDistanceData return Integer ;
		private
			DistanceValue : Integer := 255 ;
	end distanceSensorObject ;

	protected body distanceSensorObject is
		procedure putDistanceData(DistanceData : Integer) is
		begin
			DistanceValue := DistanceData ;
		end putDistanceData ;
		function getDistanceData return Integer is
		begin
			return DistanceValue ;
		end getDistanceData ;
	end distanceSensorObject ;





	-- Protected object to store data from Light Sensor.
	-- Procedures :
	--				putightData(LightSensorValue: Integer) procedure to store most recently captured Light Sensor Value.
	--				putLightDataMinimum(lightSensorMinimumValue : Integer) procedure to store minimum value of
	--																		Light Sensor Value.
	--				putLightDataMaximum(lightSensorMaximumValue : Integer) procedure to store maximum value of
	--																		Light Sensor Value.
	--				putLightDataSetPoint(lightSensorSetPointValue : Integer) procedure to store set-point value of
	--																		Light Sensor Value.
	-- Functions :
	--				getLightData return Integer function to return the most recently stored Light Sensor Value.
	--				getLightDataMinimum return Integer function to return minimum value stored from Light Sensor Values.
	--				getLightDataMaximum return Integer function to return the maximum value stored from Light Sensor Values.
	--				getLightDataSetPoint return Integer function to return the set-point stored from Light Sensor Values.
	-- Private Members :
	--			sensorValue : Integer variable to store light sensor value. Initiliazed to a random value of distance sensor.
	--			minSensorValue : Integer variable to store light sensor value. Initiliazed to a maximum value of distance sensor.
	--			maxSensorValue : Integer variable to store light sensor value. Initiliazed to a minimum value of distance sensor.
	--			sensorSetPointValue : Integer variable to store light sensor value. Initiliazed to a 0.
	protected lightSensorObject is
		function getLightData return Integer ;
		function getLightDataMinimum return Integer ;
		function getLightDataMaximum return Integer ;
		function getLightDataSetPoint return Integer ;
		procedure putLightData(lightSensorValue : Integer) ;
		procedure putLightDataMinimum(lightSensorMinimumValue : Integer) ;
		procedure putLightDataMaximum(lightSensorMaximumValue : Integer) ;
		procedure putLightDataSetPoint(lightSensorSetPointValue : Integer) ;
		private
			sensorValue : Integer := 575;
			minSensorValue : Integer := 1023 ;
			maxSensorValue : Integer := 0 ;
			sensorSetPointValue : Integer := 0 ;
	end lightSensorObject ;

	protected body lightSensorObject is
		
		procedure putLightData(lightSensorValue : Integer) is
		begin
			sensorValue := lightSensorValue ;
		end putLightData ;
		procedure putLightDataMinimum(lightSensorMinimumValue : Integer) is
		begin
			minSensorValue := lightSensorMinimumValue ;
		end putLightDataMinimum ;
		procedure putLightDataMaximum(lightSensorMaximumValue : Integer) is
		begin
			maxSensorValue := lightSensorMaximumValue ;
		end putLightDataMaximum ;
		procedure putLightDataSetPoint(lightSensorSetPointValue : Integer) is
		begin
			sensorSetPointValue := lightSensorSetPointValue ;
		end putLightDataSetPoint ;
		function getLightData return Integer is
		begin 
			return sensorValue ;
		end getLightData ;
		function getLightDataMinimum return Integer is
		begin
			return minSensorValue ;
		end getLightDataMinimum ;
		function getLightDataMaximum return Integer is
		begin
			return maxSensorValue ;
		end getLightDataMaximum ;
		function getLightDataSetPoint return Integer is
		begin
			return sensorSetPointValue ;
		end getLightDataSetPoint ;
	end lightSensorObject ;


	-- Task to find the distance from the Distance sensor and put it in 
	-- distanceSensorObject Periodically at rate defined by findDistanceTaskPeriod.
	task findDistanceTask is
		pragma Priority(findDistanceTaskPriority);
		pragma Storage_Size(findDistanceTaskStorage);
	end findDistanceTask ;

	task body findDistanceTask is
		use NXT ;
		putDistValue : Integer := 255 ;
		DistSensor : Ultrasonic_Sensor := Make(Sensor_3) ;	-- Distance Sensor Intialization.
		Next_Time : Time := Clock ;
	begin
		Set_Mode(DistSensor, Reset);						-- Resets the Distance Sensor.
		Set_Mode(DistSensor, Continuous);					-- Set the mode to Continuous for constant streaming.
		loop
			Next_Time := Next_Time + findDistanceTaskPeriod ;
			Get_Distance(DistSensor, putDistValue);
			DistanceSensorObject.putDistanceData(putDistValue);
			delay until Next_Time ;
		end loop ;
	end findDistanceTask ;

	-- Task to find the light sensor value and put it in
	-- LightSensorObject Periodically at a rate defined by getLightSensorDataTaskPeriod.
	-- We put the raw sensor values and use it as it is. This provides a higher range of variation 
	-- between complete black and complete white, makng PID tuning easier.
	task getLightSensorDataTask is
		pragma Priority(getLightSensorDataTaskPriority);
		pragma Storage_Size(getLightSensorDataTaskStorage);
	end getLightSensorDataTask ;
	task body getLightSensorDataTask is

		use NXT ;
		Next_Time : Time := Clock ;		
		LSensor : Light_Sensor := Make (Sensor_1, Floodlight_On => True); -- Light Sensor Initialization.
	begin
		NXT.AVR.Await_Data_Available;	-- Wait Till Data is available.
		loop
			Next_Time := Next_Time + getLightSensorDataTaskPeriod ;
			lightSensorObject.putLightData(Integer (NXT.AVR.Raw_Input (Sensor_1))); -- Put the raw value from the 
																					-- Sensor into the LightSensorObject.
			delay until Next_Time ;
		end loop ;
	end getLightSensorDataTask ;

	-- Task to calculate PID Compensation values for distance compensation and line compensation.
	task calculatePIDValuesTask is
		pragma Priority(calculatePIDValuesTaskPriority) ;
		pragma Storage_Size(calculatePIDValuesTaskStorage) ;
	end calculatePIDValuesTask ;
	
	task body calculatePIDValuesTask is
		use NXT ;
		Next_Time : Time := Clock ;
		MotorNoObjectSpeed : constant Integer := 29 ;	-- Base speed of motors in case of no object in front of the robot.
		MotorMaxSpeed : constant Integer := MotorNoObjectSpeed * 2 ;	-- Maximum allowed base speed.

		MotorbaseSpeed : Integer := MotorNoObjectSpeed ;	-- Speed to be compensated based on distance from object in front of the robot.
		
		botForward : constant Motion_Modes := Backward ;	-- Due to orientation of the brick and overall structure,
		botBackward : constant Motion_Modes := Forward ;	-- We switched front and back directions for the bot. 


		
		DivFactorPID : constant Integer := 1000 ;			-- Constant factor for adjusting PID Values.

		KpDist : constant Integer := 1800 ;					-- Distance Error Adjustment constant 
		KdDist : constant Integer := 0 ;					-- Distance Differential Adjustment constant
		KiDist : constant Integer := 10 ;					-- Distance Integral Adjustment constant.
		DistSetPoint : constant Integer := 27 ;				-- Distance Set Point.
		presentDist : Integer := 0 ;						-- value read from DistanceSensorObject as present distance.
		DistError : Integer := 0 ;							-- Variable to store difference between present value and set point
															-- of distance sensor values.
		DistErrorDiff : Integer := 0 ;						-- Variable to stor difference between present error and last error in
															-- distance sensor values.
		DistErrorIntegral : Integer := 0 ;					-- Variable to store sum of errors in distance sensor values from set point.
		DistLastError : Integer := 0 ;						-- Variable to store last error in distance sensor values from set-point.
		DistComp : Integer := 0 ;							-- Compensation to be applied to motor base speed.
		maxDistCheck : constant Integer := 45 ;				-- Variable to store Distance Sensor Value within which Compensation to the
															-- motor base speed is to be provided. 

		KpLine : constant Integer := 52 ;					-- Line Error Adjustment Constant
		KdLine : constant Integer := 151 ;					-- Line Differential Adjustment Constant
		KiLine : constant Integer := 5 ;					-- Line Integral Adjustment Constant
		LinePresentPoint : Integer := 0 ;					-- Line Set Point.
		LineSetPointError : Integer := 0 ;					-- Variable to store difference between line present position and set point.
		LineSetPointErrorIntegral : Integer := 0;			-- Variable to store sum of errors in line position.
		LineSetPointMaximumIntegral : constant Integer := motorbaseSpeed* DivFactorPID *65 / 
									 (KiLine * 100 ) ;		-- Variable to store maximum allowed Integral Wind Up.
									 						-- Set to 65% of motorbaseSpeed.
		LineInitDiff : Boolean := True ;					-- Variable to store and clear initial Differentail Factor.
															-- If true, Differential gain is not taken into account, otherwise it is.
		LineSetPointErrorDiff : Integer := 0;				-- Variable to store error difference between present and last error from set point.
		LineSetPointErrorLast : Integer := LineSetPointError ; -- Variable to store last error from set point.
		LineSetPoint : Integer := 0 ;						-- Variable to store set point of the line.
		LineCompensation : Integer := 0 ;					-- Compensation to be applied to motor base speed.
		LeftMotorSpeed : Integer := MotorBaseSpeed;			-- Speed for Left Motor.
		RightMotorSpeed : Integer := MotorBaseSpeed ;		-- Speed for Right Motor.
		LeftMotorDirection : Motion_Modes := botForward ;	-- Direction for Left Motor.
		RightMotorDirection : Motion_Modes := botForward ;	-- Direction for Right Motor.

		motorLeft : Motor_ID := Motor_B ;					-- Left Motor's Motor_ID.
		motorRight : Motor_ID := Motor_A ;					-- Right Motor's Motor_ID.
		buttonLeft : Touch_Sensor(Sensor_4) ;				-- Left Touch Sensor on the robot.
		buttonRight : Touch_Sensor(Sensor_2);				-- Right Touch Sensor on the robot.

		-- Procedure to write actual motor speeds.
		procedure writeMotorSpeedValues( leftMotorSpeedValue : Power_Percentage ; 
						leftMotorDirection : Motion_Modes ;
					     rightMotorSpeedValue : Power_Percentage ; 
						rightMotorDirection : Motion_Modes ) is
		begin	
			Control_Motor(motorLeft,leftMotorSpeedValue , leftMotorDirection);
			Control_Motor(motorRight, rightMotorSpeedValue, rightMotorDirection);
			null ;
		end writeMotorSpeedValues ;

		-- Procedure to stop both motors simultaneously.  
		procedure stopMotors is
		begin
			Control_Motor(motorLeft, 0, Brake);
			Control_Motor(motorRight, 0, Brake);
		end stopMotors;

		-- Procedure to read the light sensor values from LightSensorObject 
		-- and store its minimum and maximum values.
		procedure readData is
			Next_Time : Time := Clock ;
			SampleSize : Integer := 50 ;
			repeatPeriod : Time_Span := 2*getLightSensorDataTaskPeriod;
			presentLightValue : Integer := 0 ;
		begin 
			for X in 1.. SampleSize loop
				Next_Time := Next_Time + repeatPeriod ;
				presentLightValue := LightSensorObject.getLightData ;
				if presentLightValue < LightSensorObject.getLightDataMinimum then
					LightSensorObject.putLightDataMinimum(presentLightValue);
				end if ;
				if presentLightValue > LightSensorObject.getLightDataMaximum then
					LightSensorObject.putLightDataMaximum(presentLightValue);
				end if ;
				delay until Next_Time ;
			end loop ;
		end readData ;
		
		-- Procedure to find and set the set point for the line using procedure readData
		procedure fixLineSetPoint is
			
		begin
			Put_line("Set on Black");
			readData ;
			Put_line("Set on White");
			readData ;
			LineSetPoint := (LightSensorObject.getLightDataMinimum +  LightSensorObject.getLightDataMaximum) / 2 ;
			LightSensorObject.putLightDataSetPoint(LineSetPoint);
		end fixLineSetPoint ;

	begin	
		NXT.AVR.Await_Data_Available;
		Clear_Screen ;
		-- Calibration Process.
		Put_Line("Press RB 2 Start");
		while not Pressed(buttonRight) loop
			delay until Clock + milliseconds(50) ;
		end loop ;
		Put_Line("Calibrating");
		stopMotors ;	
		fixLineSetPoint ;
		Put_Line("Calib Done!");
		-- Waiting for putting th bot on line.
		Put_Line("Press LB 2 Start");
		while not Pressed(buttonLeft) loop
			delay until Clock + milliseconds(50) ;
		end loop ;

		Next_Time := Clock ;
		loop
			Next_Time := Next_Time + calculatePIDValuesTaskPeriod ;

			presentDist := DistanceSensorObject.getDistanceData ;
			if presentDist <= maxDistCheck then -- If present distance is less than a particluar distance of 45 cm.
				-- Act on PID control to set motor base speed.
				DistError := presentDist - DistSetPoint ;
				DistErrorIntegral := DistErrorIntegral + DistError ;
				DistErrorDiff := DistError - DistLastError ;
				DistComp := (DistError*KpDist + DistErrorIntegral* KiDist +
						DistErrorDiff* KdDist) / DivFactorPID ;
				motorBaseSpeed := motorNoObjectSpeed + DistComp ;
				DistLastError := DistError ;
			else
				-- Else set motor base speed to normal speed.
				motorBaseSpeed := motorNoObjectSpeed ;
			end if ;
			-- Put the received data on Display.
			Clear_Screen ;
			Put_noupdate("Dist ");
			Put_noupdate(presentDist);
			newline ;
			Put_noupdate("Speed ");
			Put_noupdate(motorBaseSpeed);
			newline ;

			-- Perform Line Compensation PID.
			LineSetPointError := LightSensorObject.getLightData - LineSetPoint ;
			LineSetPointErrorIntegral := lineSetPointErrorIntegral + LineSetPointError ;
			if not LineInitDiff then
				LineSetPointErrorDiff := lineSetPointError - LineSetPointErrorLast ;
			else
				LineInitDiff := False ;
				LineSetPointErrorDiff := 0 ;
			end if ;
			
			-- Check for Integral Wind Up.
			if LineSetPointErrorIntegral > LineSetPointMaximumIntegral or 
			LineSetPointErrorIntegral < -LineSetPointMaximumIntegral  				then
				LineSetPointErrorIntegral := 0 ;
			end if ;
			LineCompensation := 	(KpLine*LineSetPointError +
						KdLine*LineSetPointErrorDiff +
						KiLine*LineSetPointErrorIntegral)/DivFactorPID ;
			LeftMotorSpeed := MotorbaseSpeed + LineCompensation ;
			RightMotorSpeed := MotorbaseSpeed - LineCompensation ;

			-- Check for negative values on the speed of the motors.
			if(LeftMotorSpeed < 0 ) then
				LeftMotorSpeed := - LeftMotorSpeed ;
				LeftMotorDirection := botBackward ;
			else 				
				LeftMotorDirection := botForward ;
			end if ;
			if(RightMotorSpeed < 0 ) then
				RightMotorSpeed := - RightMotorSpeed ;
				RightMotorDirection := botBackward ;
			else 				
				RightMotorDirection := botForward ;
			end if ;

			-- Check for maximum allowed speed of the motors.
			if(LeftMotorSpeed > MotorMaxSpeed ) then
				LeftMotorSpeed := MotorMaxSpeed ;
			end if;
			if(RightMotorSpeed > MotorMaxSpeed ) then
				RightMotorSpeed := MotorMaxSpeed ;
			end if;

			writeMotorSpeedValues(Power_Percentage(LeftMotorSpeed), LeftMotorDirection ,
							  Power_Percentage(RightMotorSpeed),  RightMotorDirection );
			
			LineSetPointErrorLast := LineSetPointError ;

			
			while Pressed(buttonRight) loop 		-- If Right Button is pressed in middle of the run,
				LineSetPointErrorIntegral := 0 ;	-- set integral wind up to 0, 
				LineInitDiff := True ;				-- set initial contidition to true for differential gain,
				stopMotors ;						-- stop the motors
				delay until Clock +seconds(2) ;
				Next_Time := Clock ;
				while not Pressed(buttonLeft) loop 	-- and wait till Left Button is pressed to resume the task.
					delay until Clock + milliseconds(50) ;
				end loop ;
				Next_Time := Clock + calculatePIDValuesTaskPeriod ;
			end loop ;
			delay until Next_Time ;	
			
		end loop ;
	end calculatePIDValuesTask ;
end tasks ;
