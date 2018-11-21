-------------------------------------------------------------------------
----------------------  Line Follower Without PID  ----------------------
-------------------------------------------------------------------------

with Ada.Real_Time;             use Ada.Real_Time;
with System;
with NXT;			use NXT;
with NXT.AVR;		        use NXT.AVR;
with Nxt.Display;               use Nxt.Display;
with ADA.Real_time;		use ADA.Real_time;
with NXT.Light_Sensors;		use NXT.Light_Sensors;
with NXT.Light_Sensors.Ctors;	use NXT.Light_Sensors.Ctors;
with NXT.Motor_Controls ;	use NXT.Motor_Controls ;

package body Tasks is

   ----------------------------
   --  Background procedure  --
   ----------------------------

   procedure Background is
   begin
      loop
         null;
      end loop;
   end Background;

   -------------
   --  Tasks  --
   -------------

   move_delay : constant Time_Span := milliseconds(30);
   right_delay : constant Time_Span := milliseconds(60);

   displayTaskPriority : constant System.Priority := System.Priority'First + 2 ;

   displayTaskStorage : constant Integer := 4096 ;


   task ReadAndMove is
      pragma Priority(System.Priority'First + 1);
      pragma Storage_Size (4096);
   end ReadAndMove;

   task body ReadAndMove is

      Next_Time : Time := Clock;
      Period : Time_Span := milliseconds(50);
      LS : Light_Sensor := make(Sensor_3, True);

   begin

      loop
         put_noupdate("Light level is: ");
	 put_noupdate(LS.Light_Value);
         Newline;
         if LS.Light_Value>575 then				----Follow the black line
            Control_Motor(Motor_A, 31, Forward);		----Move the right motor forward
            Control_Motor(Motor_B, 31, Forward);		----Move the left motor forward
            delay move_delay;
         else							----TURN LEFT
            Control_Motor(Motor_A, 31, Forward);		----Move the right motor forward
            Control_Motor(Motor_B, 31, Backward);		----Move the left motor backward
            delay move_delay;
            if LS.Light_Value<575 then				----TURN RIGHT
               Control_Motor(Motor_A, 31, Backward);		----Move the right motor backward
               Control_Motor(Motor_B, 31, Forward);		----Move the left motor forward
               delay right_delay;
         end if;

         if NXT.AVR.Button = Power_Button then
	    Power_Down;
	 end if;
	 Next_Time := Next_Time + Period;
	 delay until Next_Time;
      end loop;

   end ReadAndMove;

end Tasks;
