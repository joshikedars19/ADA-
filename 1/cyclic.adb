with Ada.Calendar;
with Ada.Text_IO;
use Ada.Calendar;
use Ada.Text_IO;

procedure cyclic is
    Message: constant String := "Cyclic scheduler";
        -- change/add your declarations here
	Start_Time: Time := Clock;					-- Epoch.
	F1_Scheduler_Time : Time := Start_Time ;	-- Variable to Set time to Schedule F1 at 1 second Interval
	F1_Period : Duration := 1.0 ;				-- 1 sec period of F1
	F3_After_F1_Time: Duration := 0.5 ;			-- Duration after scheduling F1 after which we schedule F3
												-- (Alternatively.)
	alternateSecond : Boolean := True ; 		-- Variable to execute F3 Alternatively.
        

	procedure f1 is 
		Message: constant String := "F1 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
	end f1;

	procedure f2 is 
		Message: constant String := "F2 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
	end f2;

	procedure f3 is 
		Message: constant String := "F3 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
	end f3;

	begin
        loop
        	F1_Scheduler_Time := F1_Scheduler_Time + F1_Period ;	-- Absolute Time For Next F1 Schedule
            f1 ;													-- Scheduled F1.
            f2 ;													-- Schedule F2 after F1 execution finishes.
            delay until F1_Scheduler_Time - F1_Period + F3_After_F1_Time ; -- Schedule F3 after 0.5 seconds
            															   -- From F1.
            if alternateSecond then	-- If Time to schedule F3, do it.
            	f3 ;
            	alternateSecond := False ; -- Change status for alternate second.
            else
            	alternateSecond := True ;	-- Revert status to execute F3 next time.
            end if;
            delay until F1_Scheduler_Time ;
        end loop;
end cyclic;
