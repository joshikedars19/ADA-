------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
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

with NXT.Registers;     use NXT.Registers;
with NXT.BC4.Messages;  use NXT.BC4.Messages;
with Ada.Real_Time;     use Ada.Real_Time;
with Ada.Unchecked_Conversion;

package body NXT.BC4 is

   BT_RX_PIN  : constant := 2 ** 21;  -- AT91C_PIO_PA21
   BT_TX_PIN  : constant := 2 ** 22;  -- AT91C_PIO_PA22
   BT_SCK_PIN : constant := 2 ** 23;  -- AT91C_PIO_PA23
   BT_RTS_PIN : constant := 2 ** 24;  -- AT91C_PIO_PA24
   BT_CTS_PIN : constant := 2 ** 25;  -- AT91C_PIO_PA25
   BT_CS_PIN  : constant := 2 ** 31;  -- AT91C_PIO_PA31
   BT_RST_PIN : constant := 2 ** 11;  -- AT91C_PIO_PA11

   PIO_Pins : constant Register_32 :=
      BT_RX_PIN or BT_TX_PIN or BT_SCK_PIN or BT_RTS_PIN or BT_CTS_PIN;

   BT_ARM7_CMD_PIN : constant := 2 ** 27;  -- AT91C_PIO_PA27

   function As_Register_32 is new Ada.Unchecked_Conversion
     (Source => System.Address, Target => Register_32);

   function As_Register_32 is new Ada.Unchecked_Conversion
     (Source => Buffer_Reference, Target => Register_32);

   function As_Buffer_Reference is new Ada.Unchecked_Conversion
     (Source => System.Address, Target => Buffer_Reference);

   procedure Set_Reset_Low;
   procedure Set_Reset_High;

   -----------------------
   -- Initialize_Device --
   -----------------------

   procedure Initialize_Device is
      Baud_Rate : constant := 460_800;
      Unused    : Unsigned_32;
      pragma Unreferenced (Unused);
   begin
      Index := 0;
      Current_Buffer := 0;

      PMC_PCER := 2 ** AT91C_ID_US1;

      PIOA_PDR := PIO_Pins;
      PIOA_ASR := PIO_Pins;

      US1_CR := US_RSTSTA;
      US1_CR := US_STTTO;
      US1_RTOR := 10_000;

      US1_IDR := US_TIMEOUT;
      US1_MR := (US_USMODE_HWHSH and (not US_SYNC)) or US_CLKS_CLOCK
                or US_CHRL_8_BITS or US_PAR_NONE or US_NBSTOP_1_BIT
                or US_OVER;

      declare
         Temp1 : Unsigned_32;
         Temp2 : Unsigned_32;
      begin
         Temp1 := (Clock_Frequency / 8 / Baud_Rate);
         Temp2 := ((Clock_Frequency / 8) - ((Clock_Frequency / 8 / Baud_Rate)
                     * Baud_Rate)) / ((Baud_Rate + 4) / 8);
         US1_BRGR := Temp1 or Shift_Left (Temp2, 16);
      end;

      US1_PTCR := PDC_RXTDIS or PDC_TXTDIS;
      US1_RCR  := 0;
      US1_TCR  := 0;
      US1_RNPR := 0;
      US1_TNPR := 0;

      AIC_IDCR := 2 ** AT91C_ID_US1;
      AIC_ICCR := 2 ** AT91C_ID_US1;

      pragma Warnings (Off);
      Unused := US1_RHR;
      Unused := US1_CSR;
      pragma Warnings (On);

      US1_RPR  := As_Register_32 (Incoming (0)'Address);
      US1_RCR  := 128;
      US1_RNPR := As_Register_32 (Incoming (1)'Address);
      US1_RNCR := 128;
      US1_CR   := US_RXEN or US_TXEN;
      US1_PTCR := PDC_RXTEN or PDC_TXTEN;

      PIOA_PDR := PIO_Pins;
      PIOA_ASR := PIO_Pins;
      PIOA_PER  := BT_CS_PIN or BT_RST_PIN;
      PIOA_OER  := BT_CS_PIN or BT_RST_PIN;
      PIOA_SODR := BT_CS_PIN or BT_RST_PIN;
      PIOA_PUDR := BT_ARM7_CMD_PIN;
      PIOA_PER  := BT_ARM7_CMD_PIN;
      PIOA_CODR := BT_ARM7_CMD_PIN;
      PIOA_OER  := BT_ARM7_CMD_PIN;
      --  Configure timer 01 as trigger for ADC, sample every 0.5ms
      PMC_PCER := 2 ** AT91C_ID_TC1;
      TC1_CCR := TC_CLKDIS;
      TC1_IDR := not 0;
      pragma Warnings (Off);
      Unused := TC1_SR;
      pragma Warnings (On);
      TC1_CMR := TC_WAVE or TC_WAVESEL_UP_AUTO or TC_ACPA_SET or
                 TC_ACPC_CLEAR or TC_ASWTRG_SET;
      TC1_RC := (Clock_Frequency / 2) / 2000;
      TC1_RA := (Clock_Frequency / 2) / 4000;
      TC1_CCR := TC_CLKEN;
      TC1_CCR := TC_SWTRG;

      PMC_PCER := 2 ** AT91C_ID_ADC;
      ADC_MR := 0;
      ADC_MR := ADC_MR or ADC_TRGEN_EN or ADC_TRGSEL_TIOA1;
      ADC_MR := ADC_MR or 16#0000_3F00#;
      ADC_MR := ADC_MR or 16#0002_0000#;
      ADC_MR := ADC_MR or 16#0900_0000#;
      ADC_CHER := ADC_CH6 or ADC_CH4;

      Buf_Ptr := Incoming (0)'Access;
   end Initialize_Device;

   --  we declare this here just to avoid evaluating it repeatedly
   One_Ms : constant Time_Span := Milliseconds (1);

   ---------------
   -- Delay_1ms --
   ---------------

   procedure Delay_1ms is
   begin
      delay until Clock + One_Ms;
   end Delay_1ms;

   ------------------
   -- Reset_Device --
   ------------------

   procedure Reset_Device (Result : out Reset_Status) is
      Temp : Buffer;
   begin
      Result := Failed;

      if (PIOA_ODSR and BT_RST_PIN) = 0 then
         Result := Unpowered;
         return;
      end if;

      Enter_Command_Mode;
      --  BC4 reset sequence. First take the reset line low for 100ms
      --  and discard any packets that may be around.
      Set_Reset_Low;
      for K in reverse 0 .. 99 loop  -- better code gen when counting to zero
         Receive (Temp'Address);
         Delay_1ms;
      end loop;
      Set_Reset_High;

      --  Now wait either for 5000ms or for the BC4 chip to signal reset
      --  complete.
      for K in reverse 0 .. 4999 loop
         Receive (Temp'Address);
         if (Temp (0) = 3) and (Temp (1) = MSG_RESET_INDICATION) and
           (Temp (2) = 16#FF#) and (Temp (3) = 16#E9#)
         then
            Result := Success;
            exit;
         end if;
         Delay_1ms;
      end loop;

      Enter_Command_Mode;
   end Reset_Device;

   ----------
   -- Send --
   ----------

   procedure Send (Msg : System.Address; Length : Natural) is
   begin
      if US1_TNCR = 0 then
         US1_TNPR := As_Register_32 (Msg);
         US1_TNCR := Unsigned_32 (Length);
      end if;
   end Send;

   -------------
   -- Receive --
   -------------

   procedure Receive (Msg : System.Address) is
      use type System.Address;

      Message : constant Buffer_Reference := As_Buffer_Reference (Msg);

      Bytes_Ready       : Integer;
      Total_Bytes_Ready : Integer;
      Cmd_Length        : Integer;
      Tmp_Ptr           : Buffer_Reference;
      K                 : Integer;
   begin
      --  initially indicate no content
      Message (0) := 0;
      Message (1) := 0;

      if US1_RNCR = 0 then  --  incoming buffer has been filled.
         Bytes_Ready := 128;
         Total_Bytes_Ready := Integer (256 - US1_RCR);
      else
         Bytes_Ready := Integer (128 - US1_RCR);
         Total_Bytes_Ready := Bytes_Ready;
      end if;

      if Total_Bytes_Ready > Index + 1 then
         Cmd_Length := Integer (Buf_Ptr (Index));

         if Index < 127 then
            if Buf_Ptr (Index + 1) = 0 then
               Cmd_Length := Cmd_Length + 1;
            end if;
         else
            Tmp_Ptr := Incoming (Current_Buffer xor 1)'Access;
            if Tmp_Ptr (0) = 0 then
               Cmd_Length := Cmd_Length + 1;
            end if;
         end if;

         --  Is whole command in the buffer?

         if Bytes_Ready >= Index + Cmd_Length + 1 then
            K := 0;
            while K < Cmd_Length + 1 loop
               Message (K) := Buf_Ptr (Index);
               Index := Index + 1;
               K := K + 1;
            end loop;
         else
            if Total_Bytes_Ready >= Index + Cmd_Length + 1 then
               K := 0;
               while (K < Cmd_Length + 1) and (Index < 128) loop
                  Message (K) := Buf_Ptr (Index);
                  Index := Index + 1;
                  K := K + 1;
               end loop;
               Index := 0;
               Tmp_Ptr := Incoming (Current_Buffer xor 1)'Access;
               while K < Cmd_Length + 1 loop
                  Message (K) := Tmp_Ptr (Index);
                  Index := Index + 1;
                  K := K + 1;
               end loop;
               Index := Index + 128;
            else
               return;  --  wait for all bytes to be ready
            end if;
         end if;
      end if;

      if (Index >= 128) and (US1_RNCR = 0) then
         Index := Index - 128;
         US1_RNPR := As_Register_32 (Buf_Ptr);
         US1_RNCR := 128;
         Current_Buffer := Current_Buffer xor 1;
         Buf_Ptr := Incoming (Current_Buffer)'Access;
      end if;
   end Receive;

   ------------------------
   -- Enter_Command_Mode --
   ------------------------

   procedure Enter_Command_Mode is
   begin
      PIOA_CODR := BT_ARM7_CMD_PIN;
   end Enter_Command_Mode;

   ---------------------
   -- Enter_Data_Mode --
   ---------------------

   procedure Enter_Data_Mode is
   begin
      PIOA_SODR := BT_ARM7_CMD_PIN;
   end Enter_Data_Mode;

   ------------------
   -- Current_Mode --
   ------------------

   function Current_Mode return Unsigned_32 is
   begin
      return ADC_CDR6;
   end Current_Mode;

   -------------------
   -- Set_Reset_Low --
   -------------------

   procedure Set_Reset_Low is
   begin
      PIOA_CODR := BT_RST_PIN;
   end Set_Reset_Low;

   --------------------
   -- Set_Reset_High --
   --------------------

   procedure Set_Reset_High is
   begin
      PIOA_SODR := BT_RST_PIN;
   end Set_Reset_High;

end NXT.BC4;
