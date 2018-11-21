with Tasks;
with System;

procedure Main is

   pragma Priority (System.Priority'First);

begin
   --  Insert code here.
   Tasks.Background;

end Main;
