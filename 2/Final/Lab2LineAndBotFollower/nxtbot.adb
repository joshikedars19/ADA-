with System ;
with tasks ;


procedure nxtbot is
	pragma Priority(System.Priority'First);
begin
	Tasks.backgroundProcedure ;
end nxtbot ;
