with NXT.AVR;
--with NXT.Buttons;              use NXT.Buttons;
with NXT.Display;              use NXT.Display;
with Ada.Real_Time;            use Ada.Real_Time;
with NXT.Light_Sensors;        use NXT.Light_Sensors;
with NXT.Light_Sensors.Ctors;  use NXT.Light_Sensors.Ctors;
--with Menu_Tests;
with NXT.Last_Chance;

generic
   type Item is private;
   Maximum_Buffer_Size : in Positive;
package Bounded_Buffer_Package is

   subtype Buffer_Index is Positive range 1..Maximum_Buffer_Size;
   subtype Buffer_Count is Natural  range 0..Maximum_Buffer_Size;
   type    Buffer_Array is array (Buffer_Index) of Item;

   protected type Bounded_Buffer is
      entry Get (X : out Item);
      entry Put (X : in Item);
   private
      Get_Index : Buffer_Index := 1;
      Put_Index : Buffer_Index := 1;
      Count     : Buffer_Count := 0;
      Data      : Buffer_Array;
   end Bounded_Buffer;

procedure input_light is
use NXT;
PhotoDetector : Light_Sensor := Make (Sensor_1, Floodlight_On => False);

begin
    NXT.AVR.Await_Data_Available;
   Put_Line ("Ready for the light values");

   loop
      Put_Noupdate (PhotoDetector.Light_Value);
      Put_Noupdate ("%,  0x");
      Put_Hex (NXT.AVR.Raw_Input (Sensor_1));
      New_Line;
      exit when NXT.AVR.Button /= No_Button;
      delay until Clock + Milliseconds (100);
   end loop;

Put_Line ("Powering off");
   loop
      NXT.AVR.Power_Down;
      delay until Clock + Seconds (1);
   end loop;
end input_light;

end Bounded_Buffer_Package;




