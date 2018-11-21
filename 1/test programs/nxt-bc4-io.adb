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

with NXT.Display;    use NXT.Display;
with NXT.Registers;  use NXT.Registers;
with System;         use System;
with Ada.Unchecked_Conversion;

package body NXT.BC4.IO is

   Flag_Trace : constant Boolean := False;

   Tx_Packet : Packet (Allowed_Packet_Length);
   Rx_Packet : Packet (Allowed_Packet_Length);

   -----------------
   -- Send_Packet --
   -----------------

   procedure Send_Packet (Outgoing : Packet) is
      Checksum : Unsigned_32;
      B        : Unsigned_8;
   begin
      Checksum := 0;
      Tx_Packet (0) := Outgoing'Length + 2;
      for I in 0 .. Outgoing'Length - 1 loop
         B := Outgoing (Outgoing'First + I);
         Tx_Packet (I + 1) := B;
         Checksum := Checksum - Unsigned_32 (B);
      end loop;
      Tx_Packet (Outgoing'Length + 1) :=
        Unsigned_8 (Shift_Right (Checksum, 8) and 16#FF#);
      Tx_Packet (Outgoing'Length + 2) :=
        Unsigned_8 (Shift_Right (Checksum, 0) and 16#FF#);

      if Flag_Trace then
         Put ("Snd:");
         for I in 0 .. Outgoing'Length + 2 loop
            Put (' ');
            Put_Hex (Tx_Packet (I));
         end loop;
         Newline;
      end if;

      Send (Tx_Packet'Address, Outgoing'Length + 3);
   end Send_Packet;

   --------------------
   -- Receive_Packet --
   --------------------

   procedure Receive_Packet (Incoming : out Packet) is
      Len      : Natural;
      Checksum : Unsigned_32;
      B        : Unsigned_8;
   begin
      pragma Assert (Incoming'Length >= 2);

      Rx_Packet (0) := 0;
      Receive (Rx_Packet'Address);
      Len := Natural (Rx_Packet (0));
      Incoming (Incoming'First) := 0;
      if Len = 0 then
         return;
      end if;

      if Len < 3 then
         if Flag_Trace then
            Put_Line ("bad len");
         end if;
         return;
      end if;

      if Flag_Trace then
         Put ("Rcv:");
         for I in 0 .. len loop
            Put (' ');
            Put_Hex (Rx_Packet (I));
         end loop;
         Newline;
      end if;

      --  Copy data and compute the checksum.
      Checksum := 0;
      for I in 0 .. Len - 2 loop
         B := Rx_Packet (I);
         if I < Incoming'Length then
            Incoming (Incoming'First + I) := B;
         end if;
         Checksum := Checksum + Unsigned_32 (B);
      end loop;
      Checksum := Checksum
        + Shift_Left (Unsigned_32 (Rx_Packet (Len - 1)), 8)
        + Shift_Left (Unsigned_32 (Rx_Packet (Len)), 0);

      if (Checksum and 16#FFFF#) /= 0 then
         if Flag_Trace then
            Put_Line ("bad cksum");
         end if;
         --  Discard the packet.
         Incoming (Incoming'First) := 0;
      end if;
   end Receive_Packet;

end NXT.BC4.IO;
