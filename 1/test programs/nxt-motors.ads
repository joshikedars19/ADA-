------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                        Copyright (C) 2011, AdaCore                       --
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

--  Abstract data type for basic motors without speed regulation or
--  acceleration smoothing.  Simple NXT motors will be derived from this type,
--  as will RCX motors.

pragma Restrictions (No_Streams);

with NXT.Motor_Controls; use NXT.Motor_Controls;

package NXT.Motors is
   pragma Elaborate_Body;

   type Abstract_Motor is abstract tagged limited private;

   function Id (This : Abstract_Motor) return Motor_Id;

   procedure Set_Power (This  : in out Abstract_Motor;
                        Power : Power_Percentage);

   function Current_Power (This : Abstract_Motor) return Power_Percentage;

   procedure Forward (This : in out Abstract_Motor);

   procedure Backward (This : in out Abstract_Motor);

   procedure Reverse_Direction (This : in out Abstract_Motor);

   function Moving (This : Abstract_Motor) return Boolean;

   procedure Stop (This        : in out Abstract_Motor;
                   Apply_Brake : Boolean := False);

private

   type Abstract_Motor is abstract tagged limited
      record
         Id     : Motor_Id;
         Motion : Motion_Modes;
         Power  : Power_Percentage;
      end record;

   procedure Update_State (This : in out Abstract_Motor;  Mode : Motion_Modes);

end NXT.Motors;
