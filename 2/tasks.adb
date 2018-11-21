with Ada.Real_Time ;			use Ada.Real_Time ;
with NXT.Motor_Controls ;		use NXT.Motor_Controls ;
with NXT.Touch_Sensors ;		use NXT.Touch_Sensors ;
with NXT ;
with System ;			--use System ;
with NXT.Display;		use NXT.Display;
with NXT.AVR;			--use NXT.AVR ;
with NXT.Light_Sensors;		use NXT.Light_Sensors;
with NXT.Light_Sensors.Ctors;	use NXT.Light_Sensors.Ctors;

package body tasks is

	procedure backgroundProcedure is
	begin
		loop
			null ;
		end loop ;
	end backgroundProcedure ;

	use NXT ;
	getLightSensorDataTaskPeriod : constant Time_Span := milliseconds(30) ;
	calculatePIDValuesTaskPeriod : constant Time_Span := milliseconds(60) ;
	displayTaskPeriod : constant Time_Span := milliseconds(500) ;

	getLightSensorDataTaskPriority : constant System.Priority := System.Priority'First + 1 ;
	calculatePIDValuesTaskPriority : constant System.Priority := System.Priority'First + 2 ;
	displayTaskPriority :	constant System.Priority := System.Priority'First + 3 ;
	
	calculatePIDValuesTaskStorage : constant Integer := 8192 ;
	getLightSensorDataTaskStorage : constant Integer := 4096 ;
	displayTaskStorage : constant Integer := 4096 ;	


	
	type myMotors is record 
		motorID : Motor_ID ;
		currentSpeed : Power_Percentage ;
	end record ;
	botForward : constant Motion_Modes := Backward ;
	botBackward : constant Motion_Modes := Forward ;


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

	protected MotorObject is
		procedure writeMotorSpeedValues( leftMotorSpeedValue : Power_Percentage ; 
						leftMotorDirection : Motion_Modes ;
					     rightMotorSpeedValue : Power_Percentage ; 
						rightMotorDirection : Motion_Modes ) ;
		procedure stopMotors ;
		function getLeftMotorSpeed return Integer ;
		function getRightMotorSpeed return Integer ;
	
		private
			motorLeft : myMotors := (motorID => Motor_B , currentSpeed => 0);
			motorRight : myMotors := (motorID => Motor_A , currentSpeed => 0);
	end MotorObject ;
	protected ButtonObject is
		function isLeftButtonPressed return Boolean ;
		function isRightButtonPressed return Boolean ;
		private 
		buttonLeft : Touch_Sensor(Sensor_4) ;
		buttonRight : Touch_Sensor(Sensor_2);
	end ButtonObject ;

	task getLightSensorDataTask is
		pragma Priority(getLightSensorDataTaskPriority);
		pragma Storage_Size(getLightSensorDataTaskStorage);
	end getLightSensorDataTask ;
	task displayTask is
		pragma Priority(displayTaskPriority);
		pragma Storage_Size(displayTaskStorage);
	end displayTask ;



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


	protected body MotorObject is
		procedure writeMotorSpeedValues( leftMotorSpeedValue : Power_Percentage ; 
						leftMotorDirection : Motion_Modes ;
					     rightMotorSpeedValue : Power_Percentage ; 
						rightMotorDirection : Motion_Modes ) is
		begin	
			motorLeft.currentSpeed :=  leftMotorSpeedValue ;
			motorRight.currentSpeed :=  rightMotorSpeedValue ;
			Control_Motor(motorLeft.motorID, motorLeft.currentSpeed, leftMotorDirection);
			Control_Motor(motorRight.motorID, motorRight.currentSpeed, rightMotorDirection);
		end writeMotorSpeedValues ;

		procedure stopMotors is
		begin
			Control_Motor(motorLeft.motorID, 0, Brake);
			Control_Motor(motorRight.motorID, 0, Brake);
			motorRight.currentSpeed := 0;
			motorLeft.currentSpeed := 0 ;
		end stopMotors;
		
		function getLeftMotorSpeed return Integer is
		begin
			return Integer(motorLeft.currentSpeed) ;
		end getLeftMotorSpeed ;
		function getRightMotorSpeed return Integer is
		begin
			return Integer(motorRight.currentSpeed) ;
		end getRightMotorSpeed ;


	end MotorObject ;
	protected body ButtonObject is

		function isLeftButtonPressed return Boolean is
		begin
			return Pressed(buttonLeft) ;
		end isLeftButtonPressed ;
		function isRightButtonPressed return Boolean is
		begin
			return Pressed(buttonRight) ;
		end isRightButtonPressed ;
	end ButtonObject ;

	task body getLightSensorDataTask is
		Next_Time : Time := Clock ;		
		LSensor : Light_Sensor := Make (Sensor_1, Floodlight_On => True);
	begin
		NXT.AVR.Await_Data_Available;	
		loop
			Next_Time := Next_Time + getLightSensorDataTaskPeriod ;
			--lightSensorObject.putLightData(LSensor.Light_Value);
			lightSensorObject.putLightData(Integer (NXT.AVR.Raw_Input (Sensor_1)));
			delay until Next_Time ;
		end loop ;
	end getLightSensorDataTask ;
	
	protected globalStartCommand is
		procedure giveStartCommand ;
		function doIStartNow return Boolean ;
		private 
			startCommand : Boolean := False ;
	end globalStartCommand ;

	protected body globalStartCommand is
		procedure giveStartCommand is
		begin
			startCommand := True ;
		end giveStartCommand ;
		function doIStartNow return Boolean is
		begin
			return startCommand ;
		end doIStartNow ;
	end globalStartCommand ;

	

	protected PIDValuesObject is
		procedure putPIDLineValues(Error : Integer;
					   LastError : Integer ;
					   Integral: Integer ; 
					   Diff: Integer; 
					   Comp: Integer);
		procedure getPIDLineValues(Error :out Integer;
					   LastError : out Integer ;
					   Integral:out Integer ; 
					   Diff: out Integer; 
					   Comp: out Integer) ;
		private
			LineError : Integer := 0;
			LineLastError : Integer := 0 ;
			LineIntegral : Integer := 0;
			LineDiff : Integer := 0;
			LineComp : Integer := 0;
	end PIDValuesObject ;


	protected body PIDValuesObject is
		procedure putPIDLineValues(Error : Integer;
					   LastError : Integer ;
					   Integral: Integer ; 
					   Diff: Integer; 
					   Comp: Integer) is
		begin
			LineError := Error ;
			LineLastError := LastError ;
			LineIntegral := Integral ;
			LineDiff := Diff ;
			LineComp := Comp ;
		end putPIDLineValues ;
		procedure getPIDLineValues(Error :out Integer;
					   LastError :out  Integer ;
					   Integral:out Integer ; 
					   Diff: out Integer; 
					   Comp: out Integer) is
		begin
			Error := LineError ;
			LastError := LineLastError ;
			Integral := LineIntegral ;
			Diff := LineDiff ;
			Comp := LineComp ;
		end getPIDLineValues ;

	end PIDValuesObject ;
	
	task calculatePIDValuesTask is
		pragma Priority(calculatePIDValuesTaskPriority) ;
		pragma Storage_Size(calculatePIDValuesTaskStorage) ;
	end calculatePIDValuesTask ;
	
	task body calculatePIDValuesTask is
		Next_Time : Time := Clock ;
		MotorbaseSpeed : Integer := 31 ;
		
		MotorMaxSpeed : Integer := MotorBaseSpeed * 2 ;

		
		DivFactorPID : constant Integer := 1000 ;

		KpDist : constant Integer := 500 ;
		KdDist : constant Integer := 200 ;
		KiDist : constant Integer := 10 ;


		KpLine : constant Integer := 48 ;
		KdLine : constant Integer := 0 ;
		KiLine : constant Integer := 3 ;
		LinePresentPoint : Integer := 0 ;
		LineSetPointError : Integer := 0 ;
		LineSetPointErrorIntegral : Integer := 0;
		LineSetPointMaximumIntegral : Integer := motorbaseSpeed* DivFactorPID *60 /
									 (KiLine * 100 ) ;
		LineSetPointErrorDiff : Integer := 0;
		LineSetPointErrorLast : Integer := LineSetPointError ;
		LineSetPoint : Integer := 0 ;
		LineCompensation : Integer := 0 ;
		LeftMotorSpeed : Integer := Integer(MotorBaseSpeed);
		RightMotorSpeed : Integer := Integer(MotorBaseSpeed) ;
		LeftMotorDirection : Motion_Modes := botForward ;
		RightMotorDirection : Motion_Modes := botForward ;

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
		
		procedure fixLineSetPoint is
			
		begin
			Put_line("Set on Black");
			delay until Clock + seconds(1) ;
			readData ;
			Put_line("Set on White");
			delay until Clock + seconds(1) ;
			readData ;
			LineSetPoint := (LightSensorObject.getLightDataMinimum + 						 LightSensorObject.getLightDataMaximum) / 2 ;
			--LineSetPoint := LightSensorObject.getLightDataMaximum ;
			LightSensorObject.putLightDataSetPoint(LineSetPoint);
		end fixLineSetPoint ;

	begin	
		NXT.AVR.Await_Data_Available;
		Clear_Screen ;
		Put_Line("Press RB 2 Start");
		while not buttonObject.isRightButtonPressed loop
			delay until Clock + milliseconds(50) ;
		end loop ;
		Put_Line("Calibrating");
		--MotorObject.stopMotors ;	
		fixLineSetPoint ;
		Put_Line("Calib Done!");
		Put_Line("Press LB 2 Start");
		while not buttonObject.isLeftButtonPressed loop
			delay until Clock + milliseconds(50) ;
		end loop ;
		globalStartCommand.giveStartCommand ;
		
		Next_Time := Clock ;
		loop
			Next_Time := Next_Time + calculatePIDValuesTaskPeriod ;
			LineSetPointError := LightSensorObject.getLightData - LineSetPoint ;
			LineSetPointErrorIntegral := lineSetPointErrorIntegral + LineSetPointError ;
			LineSetPointErrorDiff := lineSetPointError - LineSetPointErrorLast ;
			
			if LineSetPointErrorIntegral > LineSetPointMaximumIntegral or 
			LineSetPointErrorIntegral < -LineSetPointMaximumIntegral  				then
				LineSetPointErrorIntegral := 0 ;
			end if ;
			LineCompensation := 	(KpLine*LineSetPointError +
						KdLine*LineSetPointErrorDiff +
						KiLine*LineSetPointErrorIntegral)/DivFactorPID ;
			LeftMotorSpeed := MotorbaseSpeed + LineCompensation ;
			RightMotorSpeed := MotorbaseSpeed - LineCompensation ;
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
			if(LeftMotorSpeed > MotorMaxSpeed ) then
				LeftMotorSpeed := MotorMaxSpeed ;
			end if;
			if(RightMotorSpeed > MotorMaxSpeed ) then
				RightMotorSpeed := MotorMaxSpeed ;
			end if;

			MotorObject.writeMotorSpeedValues(Power_Percentage(LeftMotorSpeed), 								  LeftMotorDirection ,
							  Power_Percentage(RightMotorSpeed), 								  RightMotorDirection );
			
			PIDValuesObject.putPIDLineValues(LineSetPointError, LineSetPointErrorLast, 								 LineSetPointErrorIntegral,
							 LineSetPointErrorDiff, LineCompensation);
			LineSetPointErrorLast := LineSetPointError ;
			while ButtonObject.isRightButtonPressed loop
				MotorObject.stopMotors ;
				delay until Next_Time ;
				delay until Clock +seconds(2) ;
				Next_Time := Clock ;
				while not ButtonObject.isLeftButtonPressed loop
					if ButtonObject.isRightButtonPressed then
						LineSetPointErrorIntegral := 0 ;
					end if ;
					Next_Time := Next_Time + calculatePIDValuesTaskPeriod ;
					delay until Next_Time ;
				end loop ;
				Next_Time := Clock + calculatePIDValuesTaskPeriod ;
			end loop ;
			delay until Next_Time ;	
			
		end loop ;
	end calculatePIDValuesTask ;


	
	task body displayTask is
		buttonLeftStatus : Integer := 0;
		buttonRightStatus : Integer := 0;
		LineError : Integer := 0;
		LineLastError : Integer := 0 ;
		LineIntegral : Integer := 0;
		LineDiff : Integer := 0;
		LineComp : Integer := 0;
		Next_Time : Time := Clock ;
	begin
		NXT.AVR.Await_Data_Available;
		while not globalStartCommand.doIStartNow loop
			Next_Time := Next_Time + displayTaskPeriod ;
			delay until Next_Time ;
		end loop ;
		loop
			Next_Time := Next_Time + displayTaskPeriod ;
			if ButtonObject.isRightButtonPressed then
				buttonRightStatus := 1;
			else
				buttonRightStatus := 0 ;
			end if ;
			if ButtonObject.isLeftButtonPressed then
				buttonLeftStatus := 1;
			else
				buttonLeftStatus := 0 ;
			end if ;
			PIDValuesObject.getPIDLineValues(LineError,LineLastError ,
							 LineIntegral, LineDiff, LineComp);
			Clear_Screen ;

			put("LS: ");
			put_noupdate(MotorObject.getLeftMotorSpeed);
			put("  RS: ");
			put_noupdate(MotorObject.getRightMotorSpeed);
			NewLine ;

			put("LB: ");
			put_noupdate(buttonLeftStatus);
			put("  RB: ");
			put_noupdate(buttonRightStatus);
			NewLine ;
			put("C: ");
			put_noupdate(LightSensorObject.getLightData);
			put("  CS: ");
			put_noupdate(LightSensorObject.getLightDataSetPoint);

			newline ;
			put("Cm: ");
			put_noupdate(LightSensorObject.getLightDataMinimum);
			put("  CM: ");
			put_noupdate(LightSensorObject.getLightDataMaximum);
			newline ;
		
			put("E: ");
			put_noupdate(LineError);
			put(" LE: ");
			put_noupdate(LineLastError) ;
			newline ;
			put(" I: ");
			put_noupdate(LineIntegral);
			newline ;
			put("D: ");
			put_noupdate(LineDiff);
			put("  T: ");
			put_noupdate(LineComp);
			newLine ;
			while ButtonObject.isRightButtonPressed loop
				while not ButtonObject.isLeftButtonPressed loop
					Next_Time := Next_Time + displayTaskPeriod ;
					delay until Next_Time ;
				end loop ;
				Next_Time := Clock + displayTaskPeriod ;
			end loop ;


			delay until Next_Time ;
		end loop ;
	end displayTask ;

	



end tasks ;
