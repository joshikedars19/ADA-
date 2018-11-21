------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                       Copyright (C) 2011, AdaCore                        --
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

package body NXT.Filtering is

   --------------
   -- Filtered --
   --------------

   function Filtered (The_Filter : Filter; Latest_Sample : Sample_Value)
      return Sample_Value
   is
      This : Filter renames The_Filter'Unrestricted_Access.all;
      --  Using 'Unrestricted_Access is simpler than the full Rosen Trick (with
      --  apologies to J.P.) and we don't necessarily want to force people to
      --  use Ada 2012 for the sake of mode "in out" on functions
   begin
      if Latest_Sample = No_Value then -- start over
         This.Detected_Count := 0;
         This.Detected := No_Value;
      elsif Latest_Sample = This.Previous_Sample then
         --  starting to look like a real input
         This.Detected_Count := This.Detected_Count + 1;
         if This.Detected_Count >= This.Max_Samples_Required then
            --  detected a real sample value to be returned to caller
            This.Detected := Latest_Sample;
            --  and then start over
            This.Previous_Sample := No_Value;
            This.Detected_Count := 0;
         end if;
      else -- a different value encountered
         --  start counting this new sample
         This.Previous_Sample := Latest_Sample;
         This.Detected_Count := 1;
      end if;
      return This.Detected;
   end Filtered;

end NXT.Filtering;
