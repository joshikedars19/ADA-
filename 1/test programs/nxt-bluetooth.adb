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

with Ada.Real_Time;     use Ada.Real_Time;
with NXT.BC4.IO;        use NXT.BC4.IO;
with NXT.BC4.Messages;  use NXT.BC4.Messages;

package body NXT.Bluetooth is

   Handle : Unsigned_8;

   subtype Device_Packet_Representation is Packet (0 .. 26);
   --  represents a device as a packet

   procedure Convert_To_Device
     (This   : Device_Packet_Representation;
      Result : out Device);
   --  Converts the packet into a device representation

   procedure Convert_To_Packet
     (This   : Device;
      Result : out Device_Packet_Representation);
   --  Converts the device into a packet representation

   procedure Pause;
   --  waits 10 milliseconds

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use NXT;
      Ignored : BC4.Reset_Status;
   begin
      BC4.Initialize_Device;
      BC4.Reset_Device (Result => Ignored);
   end Initialize;

   ------------------------------
   -- Convert_To_Friendly_Name --
   ------------------------------

   procedure Convert_To_Friendly_Name
     (Input : String;
      Name  : out Friendly_Name)
   is
   begin
      if Input'Length > Name'Length then
         for I in 0 .. Name'Length - 1 loop
            Name (Name'First + I) := Character'Pos (Input (Input'First + I));
         end loop;
      else
         for I in 0 .. Input'Length - 1 loop
            Name (Name'First + I) := Character'Pos (Input (Input'First + I));
         end loop;
         for I in 0 .. Name'Length - Input'Length - 1 loop
            Name (Name'First + Input'Length + I) := 0;
         end loop;
      end if;
   end Convert_To_Friendly_Name;

   -----------------------
   -- Set_Friendly_Name --
   -----------------------

   procedure Set_Friendly_Name (Name : Friendly_Name) is
      Cmd   : Packet (0 .. 16);
      Reply : Packet (0 .. 16);
      subtype Name_Packet is Packet (0 .. 15);
   begin
      Cmd (0) := MSG_SET_FRIENDLY_NAME;
      Cmd (1 .. 16) := Name_Packet (Name);
      Send_Packet (Cmd);

      loop
         Receive_Packet (Reply);
         if Reply (0) /= 0
           and then Reply (1) = MSG_SET_FRIENDLY_NAME_ACK
         then
            return;
         else
            Pause;
         end if;
      end loop;
   end Set_Friendly_Name;

   -----------------------
   -- Convert_To_Device --
   -----------------------

   procedure Convert_To_Device
     (This   : Device_Packet_Representation;
      Result : out Device)
   is
   begin
      Result := (Addr  => BT_Address (This (0 .. 6)),
                 Name  => Friendly_Name (This (7 .. 22)),
                 Class => Class_Service (This (23 .. 26)));
   end Convert_To_Device;

   -----------------------
   -- Convert_To_Packet --
   -----------------------

   procedure Convert_To_Packet
     (This   : Device;
      Result : out Device_Packet_Representation)
   is
   begin
      Result (0 .. 6)   := Packet (This.Addr);
      Result (7 .. 22)  := Packet (This.Name);
      Result (23 .. 26) := Packet (This.Class);
   end Convert_To_Packet;

   ---------------------
   -- Get_Known_Peers --
   ---------------------

   procedure Get_Known_Peers
     (Peers  : out Device_List;
      Length : out Natural)
   is
      Cmd   : Packet (0 .. 0);
      Reply : Packet (0 .. 31);
   begin
      Length := 0;
      Cmd (0) := MSG_DUMP_LIST;
      Send_Packet (Cmd);

      loop
         Receive_Packet (Reply);
         if Reply (0) /= 0 then
            if Reply (1) = MSG_LIST_ITEM then
               if Length < Peers'Length then
                  Convert_To_Device (Reply (2 .. 28),
                                 Peers (Peers'First + Length));
                  Length := Length + 1;
               end if;
            elsif Reply (1) = MSG_LIST_DUMP_STOPPED then
               return;
            end if;
         else
            Pause;
         end if;
      end loop;
   end Get_Known_Peers;

   -------------------------------
   -- Find_Discoverable_Devices --
   -------------------------------

   procedure Find_Discoverable_Devices
     (Timeout_Sec : Natural;
      Discovered  : out Device_List;
      Length      : out Natural)
   is
      Cmd   : Packet (0 .. 7);
      Reply : Packet (0 .. 32);
   begin
      Length := 0;

      Cmd (0) := MSG_BEGIN_INQUIRY;
      if Discovered'Length > 255 then
         Cmd (1) := 255;
      else
         Cmd (1) := Discovered'Length;        --  Max dev
      end if;
      Cmd (2) := Unsigned_8 (Timeout_Sec / 256);        --  Timeout HI
      Cmd (3) := Unsigned_8 (Timeout_Sec mod 256);      --  Timeout LO
      Cmd (4) := 0;
      Cmd (5) := 0;
      Cmd (6) := 0;
      Cmd (7) := 0;
      Send_Packet (Cmd);

      loop
         Receive_Packet (Reply);
         if Reply (0) /= 0 then
            if Reply (1) = MSG_INQUIRY_RUNNING then
               null;
            elsif Reply (1) = MSG_INQUIRY_STOPPED then
               return;
            elsif Reply (1) = MSG_INQUIRY_RESULT then
               if Length < Discovered'Length then
                  Convert_To_Device (Reply (2 .. 28),
                                 Discovered (Discovered'First + Length));
                  Length := Length + 1;
               end if;
            end if;
         else
            Pause;
         end if;
      end loop;
   end Find_Discoverable_Devices;

   ----------------------
   -- Set_Discoverable --
   ----------------------

   procedure Set_Discoverable (On : Boolean) is
      Cmd   : Packet (0 .. 1);
      Reply : Packet (0 .. 3);
   begin
      Cmd (0) := MSG_SET_DISCOVERABLE;
      Cmd (1) := Boolean'Pos (On);
      Send_Packet (Cmd);

      loop
         Receive_Packet (Reply);
         if Reply (0) /= 0 then
            if Reply (1) = MSG_DISCOVERABLE_ACK then
               return;
            end if;
         else
            Pause;
         end if;
      end loop;
   end Set_Discoverable;

   ----------------------
   -- Add_Known_Device --
   ----------------------

   procedure Add_Known_Device (Dev : Device; Success : out Boolean) is
      Cmd   : Packet (0 .. 27);
      Reply : Packet (0 .. 3);
   begin
      Cmd (0) := MSG_ADD_DEVICE;
      Convert_To_Packet (Dev, Cmd (1 .. 27));
      Send_Packet (Cmd);

      loop
         Receive_Packet (Reply);
         if Reply (0) = 0 then
            Pause;
         elsif Reply (1) = MSG_LIST_RESULT then
            Success := Reply (2) = 16#50#;
            return;
         end if;
      end loop;
   end Add_Known_Device;

   ----------------
   -- Start_Data --
   ----------------

   procedure Start_Data is
      Cmd : Packet (0 .. 1);
   begin
      Cmd (0) := MSG_OPEN_STREAM;
      Cmd (1) := Handle;
      Send_Packet (Cmd (0 .. 1));
      delay until Clock + Milliseconds (50);
      NXT.BC4.Enter_Data_Mode;
   end Start_Data;

   -----------------------
   -- Accept_Connection --
   -----------------------

   procedure Accept_Connection
     (Pin     : Pin_Code;
      Addr    : out BT_Address;
      Success : out Boolean)
   is
      Cmd       : Packet (0 .. 0);
      Pin_Cmd   : Packet (0 .. 23);
      Accpt_Cmd : Packet (0 .. 1);
      Reply     : Packet (0 .. 32);
   begin
      Cmd (0) := MSG_OPEN_PORT;
      Send_Packet (Cmd);

      loop
         Receive_Packet (Reply);
         if Reply (0) = 0 then
            Pause;
         else
            if Reply (1) = MSG_PORT_OPEN_RESULT then
               null;
            elsif Reply (1) = MSG_REQUEST_PIN_CODE then
               Pin_Cmd (0) := MSG_PIN_CODE;
               Pin_Cmd (1 .. 7) := Reply (2 .. 8);
               Pin_Cmd (8 .. 23) := Packet (Pin);
               Send_Packet (Pin_Cmd);
            elsif Reply (1) = MSG_PIN_CODE_ACK then
               null;
            elsif Reply (1) = MSG_REQUEST_CONNECTION then
               Addr := BT_Address (Reply (2 .. 8));
               Accpt_Cmd (0) := MSG_ACCEPT_CONNECTION;
               Accpt_Cmd (1) := 1;
               Send_Packet (Accpt_Cmd);
            elsif Reply (1) = MSG_CONNECT_RESULT then
               if Reply (2) = 1 then
                  Handle := Reply (3);
                  Success := True;
                  Start_Data;
               else
                  Success := False;
               end if;
               return;
            end if;
         end if;
      end loop;
   end Accept_Connection;

   -------------
   -- Connect --
   -------------

   procedure Connect (Target : BT_Address; Success : out Boolean) is
      Cmd   : Packet (0 .. 7);
      Reply : Packet (0 .. 3);
   begin
      Cmd (0) := MSG_CONNECT;
      Cmd (1 .. 7) := Packet (Target);
      Send_Packet (Cmd);

      loop
         Receive_Packet (Reply);
         if Reply (0) = 0 then
            Pause;
         elsif Reply (1) = MSG_CONNECT_RESULT then
            if Reply (2) = 1 then
               Handle := Reply (3);
               Success := True;
               Start_Data;
            else
               Success := False;
            end if;
            return;
         elsif Reply (1) = MSG_CLOSE_CONNECTION_RESULT then
            Success := False;
            return;
         end if;
      end loop;
   end Connect;

   -----------
   -- Pause --
   -----------

   procedure Pause is
   begin
      delay until Clock + Milliseconds (10);
   end Pause;

   --------
   -- IO --
   --------

   package body IO is
      use NXT;

      procedure Send (This : access Message) is
      begin
         BC4.Send (This.all'Address, Length => Message'Object_Size / 8);
      end Send;

      procedure Receive (This : access Message) is
      begin
         BC4.Receive (This.all'Address);
      end Receive;

   end IO;

end NXT.Bluetooth;
