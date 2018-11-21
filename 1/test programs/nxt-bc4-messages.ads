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

--  Definitions for the BlueCore4 bluetooth device.

package NXT.BC4.Messages is

   Msg_Begin_Inquiry               : constant Unsigned_8 := 0;
   Msg_Cancel_Inquiry              : constant Unsigned_8 := 1;
   Msg_Connect                     : constant Unsigned_8 := 2;
   Msg_Open_Port                   : constant Unsigned_8 := 3;
   Msg_Lookup_Name                 : constant Unsigned_8 := 4;
   Msg_Add_Device                  : constant Unsigned_8 := 5;
   Msg_Remove_Device               : constant Unsigned_8 := 6;
   Msg_Dump_List                   : constant Unsigned_8 := 7;
   Msg_Close_Connection            : constant Unsigned_8 := 8;
   Msg_Accept_Connection           : constant Unsigned_8 := 9;
   Msg_Pin_Code                    : constant Unsigned_8 := 10;
   Msg_Open_Stream                 : constant Unsigned_8 := 11;
   Msg_Start_Heart                 : constant Unsigned_8 := 12;
   Msg_Heartbeat                   : constant Unsigned_8 := 13;
   Msg_Inquiry_Running             : constant Unsigned_8 := 14;
   Msg_Inquiry_Result              : constant Unsigned_8 := 15;
   Msg_Inquiry_Stopped             : constant Unsigned_8 := 16;
   Msg_Lookup_Name_Result          : constant Unsigned_8 := 17;
   Msg_Lookup_Name_Failure         : constant Unsigned_8 := 18;
   Msg_Connect_Result              : constant Unsigned_8 := 19;
   Msg_Reset_Indication            : constant Unsigned_8 := 20;
   Msg_Request_Pin_Code            : constant Unsigned_8 := 21;
   Msg_Request_Connection          : constant Unsigned_8 := 22;
   Msg_List_Result                 : constant Unsigned_8 := 23;
   Msg_List_Item                   : constant Unsigned_8 := 24;
   Msg_List_Dump_Stopped           : constant Unsigned_8 := 25;
   Msg_Close_Connection_Result     : constant Unsigned_8 := 26;
   Msg_Port_Open_Result            : constant Unsigned_8 := 27;
   Msg_Set_Discoverable            : constant Unsigned_8 := 28;
   Msg_Close_Port                  : constant Unsigned_8 := 29;
   Msg_Close_Port_Result           : constant Unsigned_8 := 30;
   Msg_Pin_Code_Ack                : constant Unsigned_8 := 31;
   Msg_Discoverable_Ack            : constant Unsigned_8 := 32;
   Msg_Set_Friendly_Name           : constant Unsigned_8 := 33;
   Msg_Set_Friendly_Name_Ack       : constant Unsigned_8 := 34;
   Msg_Get_Link_Quality            : constant Unsigned_8 := 35;
   Msg_Link_Quality_Result         : constant Unsigned_8 := 36;
   Msg_Set_Factory_Settings        : constant Unsigned_8 := 37;
   Msg_Set_Factory_Settings_Ack    : constant Unsigned_8 := 38;
   Msg_Get_Local_Addr              : constant Unsigned_8 := 39;
   Msg_Get_Local_Addr_Result       : constant Unsigned_8 := 40;
   Msg_Get_Friendly_Name           : constant Unsigned_8 := 41;
   Msg_Get_Discoverable            : constant Unsigned_8 := 42;
   Msg_Get_Port_Open               : constant Unsigned_8 := 43;
   Msg_Get_Friendly_Name_Result    : constant Unsigned_8 := 44;
   Msg_Get_Discoverable_Result     : constant Unsigned_8 := 45;
   Msg_Get_Port_Open_Result        : constant Unsigned_8 := 46;
   Msg_Get_Version                 : constant Unsigned_8 := 47;
   Msg_Get_Version_Result          : constant Unsigned_8 := 48;
   Msg_Get_Brick_Statusbyte_Result : constant Unsigned_8 := 49;
   Msg_Set_Brick_Statusbyte_Result : constant Unsigned_8 := 50;
   Msg_Get_Brick_Statusbyte        : constant Unsigned_8 := 51;
   Msg_Set_Brick_Statusbyte        : constant Unsigned_8 := 52;
   Msg_Get_Operating_Mode          : constant Unsigned_8 := 53;
   Msg_Set_Operating_Mode          : constant Unsigned_8 := 54;
   Msg_Set_Operating_Mode_Result   : constant Unsigned_8 := 55;
   Msg_Get_Connection_Status       : constant Unsigned_8 := 56;
   Msg_Connection_Status_Result    : constant Unsigned_8 := 57;
   Msg_Goto_DFUmode                : constant Unsigned_8 := 58;

   Stream_Breaking_Mode   : constant Unsigned_8 := 0;
   Dont_Break_Stream_Mode : constant Unsigned_8 := 1;

end NXT.BC4.Messages;
