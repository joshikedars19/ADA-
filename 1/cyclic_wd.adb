with Ada.Calendar ;
with Ada.Text_IO ;
use Ada.Calendar ;
use Ada.Text_IO ;
with Ada.Numerics.Float_Random ;
use Ada.Numerics.Float_Random ;

procedure cyclic_wd is
    Message: constant String := "Cyclic scheduler";
        -- change/add your declarations here
	Start_Time: Time := Clock;			-- Epoch.
	F1_Scheduler_Time : Time := Clock ;	-- Variable to Set time to Schedule F1 at 1 second Interval
	F1_Period : constant Duration := 1.0 ;		-- 1 sec period of F1
	F3_After_F1_Time: constant Duration := 0.5 ;	-- Duration after scheduling F1 after which we schedule F3
										-- (Alternatively.)
	AlternateSecond : Boolean := True ; -- Variable to execute F3 Alternatively.
	
	X : Generator ;	-- Random Number Generator.
	IncreaseExecutionTimeF2 : Boolean := False ; -- Variable to store if execution time needs to be
												-- Increased.
	addedDelayDuration : Duration := 0.0 ;			-- Add Extra Delay to Execution of F3
	F3StartTime, F3EndTime : Time := Clock ;	-- Time Stamp Variables to store Start and finish
												-- time of F3.
	stillExecutingF3 : Boolean := False;		-- Flag to know if F3 execution has not completed.

	F1RescheduleNeeded : Boolean := False ;		-- Flag to know if F1 needs re-sync.






	

        

	procedure f1 is 
		Message: constant String := "F1 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time) ) ; 
	end f1;

	procedure f2 is 
		Message: constant String := "F2 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time)  );
	end f2;

	procedure f3 is 
		Message: constant String := "F3 executing, time is now";
	begin
		Put(Message);
		Put_Line(Duration'Image(Clock - Start_Time));
		
		-- add a random delay here
		IncreaseExecutionTimeF2 := (Integer(Random(X) * 100.0) rem 2) = 0 ;
		if IncreaseExecutionTimeF2 then
			-- Put_Line("Added Delay to F3");
			addedDelayDuration := 0.6;
		else
			addedDelayDuration := 0.0 ;
		end if;
		delay addedDelayDuration ;
	
	end f3;


	task Watchdog is
	       -- add your task entries for communication 	
	       entry F3_Started ;		-- Entry into Watchdog Task to note start time of F3.
	       entry F3_Ended ;			-- Entry into Watchdog Task to note end time of F3.
	end Watchdog;

	task body Watchdog is
		begin
		loop
			select 
					accept F3_Started do  -- Note the Start time of F3 here and mark f3 as executing.
						F3StartTime := Clock ;
						stillExecutingF3 := True ;
					end F3_Started ;
				or 
					accept F3_Ended do   -- Note the End Time of F3.
						F3EndTime := Clock ;
					end F3_Ended ;
				or 
					-- delay 0.5 ;								-- Timeout Watchdog Task if after 0.5 seconds,
					delay until Clock + 0.5 ;					-- Timeout Watchdog Task if after 0.5 seconds, Better than relative delay.
																-- As it has less local drift.
					if stillExecutingF3 and not F1RescheduleNeeded then		-- F3 is still executing and F1 needs a reschedule. 
																			-- The second part of the condition *not F1RescheduleNeeded*
																			-- Prevents multiple warnings to be printed in case of 
																			-- F3 missing deadline by more than 2 times it's period of 0.5 seconds.
						Put_Line("Warning !!") ; 	-- Put Out a Warning.
						F1RescheduleNeeded := True ;-- Note down that F1 needs re-sync from here.
					end if;
			end select ;


		end loop;
	end Watchdog;

	begin
        loop
        	F1_Scheduler_Time := Clock + F1_Period ;  -- Absolute Time For Next F1 Schedule
        	f1 ;									  -- Scheduled F1.
            f2 ;									  -- Schedule F2 after F1 execution finishes.
            delay until F1_Scheduler_Time - F1_Period + F3_After_F1_Time ; -- Delay 0.5 sec from
            															   -- schedule of F1 to 
            															   -- schedule F3 alternatively.
            if AlternateSecond then	-- If Time to schedule F3, do it.
            	Watchdog.F3_Started ;		-- Let Watchdog know it has to get ready for looking out for F3 Start.
            	f3 ;						-- Start F3.
            	stillExecutingF3 := False ; -- Set still Executing flag to false for F3 to let Watchdog know if extra delay occured or not.          	
            	Watchdog.F3_Ended ;			-- Tell Watchdog that F3 Ended.
            	AlternateSecond := False ; -- Change status for alternate second.
            else
            	AlternateSecond := True ;	-- Revert status to execute F3 next time.
            end if;
            if F1RescheduleNeeded then   	-- If F1 Needs re-sync.
				F1RescheduleNeeded := False ;	-- Set Flag to false to prevent spurious entry in if blocks.
            	EndTimeCheckerLoop :			
				loop 												-- Loop 
					if(F1_Scheduler_Time > F3EndTime) then 			-- Over F1's Schedule time till it is greater than last F3's deadline miss time.
						exit EndTimeCheckerLoop ;					-- If so, exit the loop.
					else
						F1_Scheduler_Time := F1_Scheduler_Time + F1_Period ; -- Else Add F1's Period to it, making it whole Number for next scheduling.
					end if ;
				end loop EndTimeCheckerLoop;
            end if;
            delay until F1_Scheduler_Time ;		-- Delay execution until the next F1 Reschedule.
        end loop;
end cyclic_wd;
