------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                     Copyright (C) 2010-2011, AdaCore                     --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
------------------------------------------------------------------------------

with System;
with NXT.Registers; use NXT.Registers;
with Interfaces;    use Interfaces;

pragma Warnings (Off);
with System.BB.Interrupts; use System.BB.Interrupts;
pragma Warnings (On);

package body NXT.Motor_Encoders is

   --  Pin used for tachometers.
   Motor_A_Tach_Pin : constant := 15;
   Motor_A_Dir_Pin  : constant := 1;

   Motor_B_Tach_Pin : constant := 26;
   Motor_B_Dir_Pin  : constant := 9;

   Motor_C_Tach_Pin : constant := 0;
   Motor_C_Dir_Pin  : constant := 8;

   Motor_A_Tach : constant := 2 ** Motor_A_Tach_Pin;
   Motor_A_Dir  : constant := 2 ** Motor_A_Dir_Pin;

   Motor_B_Tach : constant := 2 ** Motor_B_Tach_Pin;
   Motor_B_Dir  : constant := 2 ** Motor_B_Dir_Pin;

   Motor_C_Tach : constant := 2 ** Motor_C_Tach_Pin;
   Motor_C_Dir  : constant := 2 ** Motor_C_Dir_Pin;

   type Pin_Array is array (Motor_Id) of Unsigned_32;
   Dir_Pin  : constant Pin_Array := (Motor_A_Dir, Motor_B_Dir, Motor_C_Dir);
   Tach_Pin : constant Pin_Array := (Motor_A_Tach, Motor_B_Tach, Motor_C_Tach);

   Motors_Tach : constant := Motor_A_Tach + Motor_B_Tach + Motor_C_Tach;
   Motors_Dir  : constant := Motor_A_Dir + Motor_B_Dir + Motor_C_Dir;

   protected PIO is
      procedure Init;
      --  Initialize the PIO.
   private
      pragma Interrupt_Priority (System.Max_Interrupt_Priority);

      procedure ISR;
      pragma Attach_Handler (ISR, AT91C_ID_PIOA);
      --  Interrupt handler.
   end PIO;

   ---------
   -- PIO --
   ---------

   protected body PIO is

      ---------
      -- ISR --
      ---------

      procedure ISR is
         Value  : constant Unsigned_32 := PIOA_PDSR;
         Change : constant Unsigned_32 := PIOA_ISR;
         Dir    : Boolean;
         Tach   : Boolean;
      begin
         for I in Motor_Id'Range loop
            if (Change and Tach_Pin (I)) /= 0 then
               Dir := (Value and Dir_Pin (I)) /= 0;
               Tach := (Value and Tach_Pin (I)) /= 0;
               --  ??? Overflow.
               if Dir xor Tach then
                  Encoder_Count (I) := Encoder_Count (I) + 1;
               else
                  Encoder_Count (I) := Encoder_Count (I) - 1;
               end if;
            end if;
         end loop;
      end ISR;

      ----------
      -- Init --
      ----------

      procedure Init is
      begin
         --  Power on PIOA.
         PMC_PCER := 2 ** AT91C_ID_PIOA;

         --  Disable PIO interrupts.
         PIOA_IDR := Motors_Tach or Motors_Dir;

         --  Enable glitch filtering
         --  Disable pull-up
         --  Set pins as inputs.
         --  Assign pins to PIO
         PIOA_IFER := Motors_Tach or Motors_Dir;
         PIOA_PUDR := Motors_Tach or Motors_Dir;
         PIOA_ODR := Motors_Tach or Motors_Dir;
         PIOA_PER := Motors_Tach or Motors_Dir;

         Enable_Interrupt (AT91C_Id_PIOA);
         PIOA_IER := Motors_Tach;
      end Init;

   end PIO;

begin
   PIO.Init;
end NXT.Motor_Encoders;
