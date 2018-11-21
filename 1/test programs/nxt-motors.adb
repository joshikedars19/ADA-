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

with NXT.AVR;

package body NXT.Motors is

   --------
   -- Id --
   --------

   function Id (This : Abstract_Motor) return Motor_Id is
   begin
      return This.Id;
   end Id;

   ---------------
   -- Set_Power --
   ---------------

   procedure Set_Power
     (This : in out Abstract_Motor;
      Power : Power_Percentage)
   is
   begin
      This.Power := Power;
      Control_Motor (This.Id, This.Power, This.Motion);
   end Set_Power;

   -------------------
   -- Current_Power --
   -------------------

   function Current_Power (This : Abstract_Motor) return Power_Percentage is
   begin
      return This.Power;
   end Current_Power;

   -------------
   -- Forward --
   -------------

   procedure Forward (This : in out Abstract_Motor) is
   begin
      Update_State (Abstract_Motor'Class (This), Forward);
   end Forward;

   --------------
   -- Backward --
   --------------

   procedure Backward (This : in out Abstract_Motor) is
   begin
      Update_State (Abstract_Motor'Class (This), Backward);
   end Backward;

   -----------------------
   -- Reverse_Direction --
   -----------------------

   procedure Reverse_Direction (This : in out Abstract_Motor) is
   begin
      if This.Motion = Forward then
         Update_State (Abstract_Motor'Class (This), Backward);
      elsif This.Motion = Backward then
         Update_State (Abstract_Motor'Class (This), Forward);
      end if;
   end Reverse_Direction;

   ------------
   -- Moving --
   ------------

   function Moving (This : Abstract_Motor) return Boolean is
      Now : constant Motion_Modes := This.Motion;
   begin
      return Now = Forward or Now = Backward;
   end Moving;

   ----------
   -- Stop --
   ----------

   procedure Stop
     (This        : in out Abstract_Motor;
      Apply_Brake : Boolean := False)
   is
   begin
      This.Power := 0;
      if Apply_Brake then
         Update_State (Abstract_Motor'Class (This), Brake);
      else
         Update_State (Abstract_Motor'Class (This), Coast);
      end if;
   end Stop;

   ------------------
   -- Update_State --
   ------------------

   procedure Update_State
     (This : in out Abstract_Motor;
      Mode : Motion_Modes)
   is
   begin
      if This.Motion /= Mode then
         This.Motion := Mode;
         Control_Motor (This.Id, This.Power, This.Motion);
      end if;
   end Update_State;

end NXT.Motors;
