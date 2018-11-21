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

--  High-level bluetooth driver.  The package is a state machine representing
--  the onboard Bluetooth hardware, in other words, that of the local NXT.

with System;
with Interfaces; use Interfaces;

package NXT.Bluetooth is

   type BT_Address    is array (0 .. 6)  of Unsigned_8;

   type Friendly_Name is array (0 .. 15) of Unsigned_8;

   type Class_Service is array (0 .. 3)  of Unsigned_8;

   type Pin_Code      is array (0 .. 15) of Unsigned_8;

   type Device is
      record
         Addr  : BT_Address;
         Name  : Friendly_Name;
         Class : Class_Service;
      end record;

   type Device_List is array (Natural range <>) of Device;

   --  Note: all procedures are blocking (ie they use delay).

   procedure Initialize;
   --  Must be done before any other operation.

   procedure Convert_To_Friendly_Name
     (Input : String;
      Name  : out Friendly_Name);
   --  Appends necessary NUL byte.    (always ???)
   --  Input may be truncated if too long.

   procedure Set_Friendly_Name (Name : Friendly_Name);

   procedure Get_Known_Peers (Peers : out Device_List; Length : out Natural);

   procedure Find_Discoverable_Devices
     (Timeout_Sec : Natural;
      Discovered  : out Device_List;
      Length      : out Natural);

   procedure Set_Discoverable (On : Boolean);

   procedure Add_Known_Device (Dev : Device; Success : out Boolean);
   --  Add a device to the known peer list.

   procedure Accept_Connection
     (Pin     : Pin_Code;
      Addr    : out BT_Address;
      Success : out Boolean);

   procedure Connect (Target : BT_Address; Success : out Boolean);

   --  a generic communication package for application-specific messages
   generic
      type Message (<>) is limited private;
   package IO is
      procedure Send (This : access Message);
      procedure Receive (This : access Message);
   end IO;

end NXT.Bluetooth;
