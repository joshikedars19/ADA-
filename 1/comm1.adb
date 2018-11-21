--Process commnication: Ada lab part 3

with Ada.Calendar;
with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
use Ada.Calendar;
use Ada.Text_IO;

procedure comm1 is
    Message: constant String := "Process communication";

    -- N : Integer := 0;
	task buffer is
            -- add your task entries for communication 
        entry PutIntegerInFIFOAtLast(InputInteger : in Integer) ;		-- Entry for Putting a number into the Buffer End.
        entry GetIntegerFromFIFOFromFront(OutputInteger : out Integer);	-- Entry for Getting a number from the Buffer Front.
        entry FinishBufferTask ;			-- Entry to indicate Buffer task should be ended now.
	end buffer;

	task producer is
            -- add your task entries for communication  
            entry FinishProducerTask ;	-- Entry to indicate producer task should end now.
	end producer;

	task consumer is
            -- add your task entries for communication 
	end consumer;

	task body buffer is 
		Message: constant String := "buffer executing";
		BufferSize : constant Integer := 13 ;							-- Size of Buffer Queue.
		
		type FIFOBufferArrayType is array(Integer range<>) of Integer ;	-- Array type for creating actual buffer of size BufferSize
		type FIFOPositionsMod is mod BufferSize ; 						-- Type for Using Buffer as Circular Queue.


		FIFOBuffer : FIFOBufferArrayType(0 .. BufferSize-1) ; 			-- Actual Buffer Queue.
		FIFOBufferPutPosition : FIFOPositionsMod := 
								FIFOPositionsMod( FIFOBuffer'First ) ;  -- Variable which holds next position 
																		-- in Buffer to Put Data. 
																		-- Mod Value prevents going out of 
																		-- Buffer range to put data
		FIFOBufferGetPosition : FIFOPositionsMod := 
								FIFOPositionsMod( FIFOBuffer'First ) ;  -- Variable which holds next position 
																		-- in Buffer to Get Data. 
																		-- Mod Value prevents going out of 
																		-- Buffer range to get data
		FIFOAvailableGetCount : Integer := 0 ;							-- Available Number of Values to be removed from Queue.
																		-- Zero at start due to buffer being empty.
		FIFOAvailablePutCount : Integer := BufferSize ;					-- Available Number of Values to be added into Queue.
																		-- BufferSize at start due to buffer being empty.


		function FIFOBufferNotOverFlow return Boolean is 				-- Function to check if Buffer Overflow Situation is avoidable for now.
			
		begin -- FIFOBufferNotOverFlow
			if FIFOAvailablePutCount > 0  then -- Still have space in Buffer.
				return True ;
			else 								-- No More Space to Put More Data.
				-- Put_Line("Buffer Overflow!");
				return False ;
			end if;
		end FIFOBufferNotOverFlow;

		function FIFOBufferNotUnderFlow return Boolean is 				-- Function to check if Buffer Underflow Situation is avoidable for now.
			
		begin -- FIFOBufferNotUnderFlow
			if FIFOAvailableGetCount > 0  then	-- Still have values in Buffer.
				return True ;
			else 
				-- Put_Line("Buffer Underflow!");
				return False ; -- No More Values in Buffer.
			end if;
		end FIFOBufferNotUnderFlow;		

                -- change/add your local declarations here   
	begin
		Put_Line(Message);
		loop
                -- add your task code inside this loop 

            select 
            	when FIFOBufferNotOverFlow =>								-- Put Data at End of FIFO
                	accept PutIntegerInFIFOAtLast(InputInteger : in Integer ) do
                		FIFOBuffer(Integer(FIFOBufferPutPosition) ) := InputInteger ;  -- Add One Value to Queue End. 
                		FIFOAvailablePutCount := FIFOAvailablePutCount - 1 ; -- One Integer Added to Queue
                															 -- This Reduces Buffer Size for Putting by 1.
                		FIFOBufferPutPosition := FIFOBufferPutPosition + 1 ; -- Integer Added to Tail.
                															 -- Make Putting Position Ready for next Put.
                		FIFOAvailableGetCount := FIFOAvailableGetCount + 1 ; -- One new Integer in Queue, so Getting Count
                															 -- Increases by 1.
                	end PutIntegerInFIFOAtLast ;
            or
            	when FIFOBufferNotUnderFlow => 	-- Get Data from Start of FIFO 
            		accept GetIntegerFromFIFOFromFront(OutputInteger : out Integer) do
            			OutputInteger := FIFOBuffer(Integer(FIFOBufferGetPosition) ) ; -- Get On Value from Queue Start ;
            			FIFOAvailableGetCount := FIFOAvailableGetCount - 1 ; -- One Integer Removed from Queue
            																 -- This Reduces Buffer Size for Getting by 1.
            			FIFOBufferGetPosition := FIFOBufferGetPosition + 1 ; -- Integer Removed from Head.
            																 -- Make Getting Position Ready for next Get.
            			FIFOAvailablePutCount := FIFOAvailablePutCount + 1 ; -- One Less Integer in Queue, so Putting Count
            																 -- Increases by 1.
            		end GetIntegerFromFIFOFromFront ;
            or
            	accept FinishBufferTask ;	-- Summarization Exceeds 100 now. So Exit Buffer.
            	exit ;
            end select ;
            null ;   
		end loop;
		
		-- Put_Line("Exiting Buffer");
	end buffer;

	task body producer is 
		Message: constant String := "producer executing";
                -- change/add your local declarations here
    	
    	-- Creating Random Number Generator from Ada.Numerics.Discrete_Random
    	subtype Num is Integer range 0 .. 25 ;					
    	package Random_Data is new Ada.Numerics.Discrete_Random(Num) ; 
    	use Random_Data ;
    	RandomIntGen : Generator ;
 
        function randomDataToPut return Integer is -- Function to generate Random Data to Put from 0 to 25
        begin -- randomDataToPut
        	return Integer(Random(RandomIntGen)) ;
        end randomDataToPut;

 
        function randomTimeToPut return Boolean is --Function to generate boolean value if it is time to Put random Data.
        begin -- randomTimeToPut
        	return Integer(Random(RandomIntGen)) rem 7 = 0 ;
        end randomTimeToPut;
        
        DataToPut : Integer := 0 ;	-- Actual Value to be Put in Buffer Queue.


	begin
		Reset(RandomIntGen) ;	-- Seed the Random Generator.
		Put_Line(Message);
		loop
                -- add your task code inside this loop  
            select
            	accept FinishProducerTask ;	-- If summarization is done, exit the endless loop and end the task.
            	exit ;
            else
            	if randomTimeToPut then	-- If time to put random data
	            	DataToPut := randomDataToPut ;	-- Get a random data from 0 .. 25
	            	Put_Line("Put Data: " & Integer'Image(DataToPut) ) ; -- Print Value to be Put in Buffer.
	            	Buffer.PutIntegerInFIFOAtLast(DataToPut);     	-- Request Data Put, and put it else get blocked here.
	            	Put_Line("Put Sucess for " & Integer'Image(DataToPut));  -- Put Data and Print Success for Putting this value.
            	end if ;

            end select ;
		end loop;


	end producer;

	task body consumer is 
		Message: constant String := "consumer executing";
                -- change/add your local declarations here


    	-- Creating Random Number Generator from Ada.Numerics.Discrete_Random
    	subtype Num is Integer range 0 .. 25 ;
    	package Random_Data is new Ada.Numerics.Discrete_Random(Num) ;
    	use Random_Data ;
    	RandomIntGen : Generator ;
 

 
        function randomTimeToGet return Boolean is --Function to generate boolean value if it is time to Get Data.
        begin -- randomTimeToGet
        	return Integer(Random(RandomIntGen)) rem 2 = 0 ;
        end randomTimeToGet;

        SumValue : Integer := 0 ; -- Variable to Store Sum from Get Operation.
        DataToGet : Integer := 0; -- Actual Value Received from get Operation store in this variable.
	begin
		Reset(RandomIntGen) ; -- Seed the Generator.
		Put_Line(Message);
		Main_Cycle:
		loop 
                -- add your task code inside this loop 
			if randomTimeToGet then	-- If it is time to get Data.
				Put_Line("Get Data" );	-- Print the Request to Get Data
				Buffer.GetIntegerFromFIFOFromFront(DataToGet) ; -- Get Data from Buffer or be blocked here.
				Put_Line("Get Success got Data: " & Integer'Image(DataToGet)); -- Print data if Successfully received.
				SumValue := SumValue + DataToGet ;	-- Sum the Data.
				if SumValue > 100 then	-- If Sum is greater than 100.
					exit Main_Cycle;	-- Exit the Loop.
				end if ;
			end if;
			null ;
		end loop Main_Cycle; 


		Put_Line("Summation is Complete, Sum: " & Integer'Image(SumValue)); -- Print that summation is complete.
		producer.FinishProducerTask ; -- Ask Producer to exit.
		Buffer.FinishBufferTask ;	-- Ask Buffer to exit.

		exception
			  when TASKING_ERROR =>
				  Put_Line("Buffer finished before producer");
		Put_Line("Ending the consumer");
	end consumer;
begin
	Put_Line(Message);
end comm1;