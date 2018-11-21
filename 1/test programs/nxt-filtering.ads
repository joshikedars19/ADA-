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

--  A facility for removing noisy inputs, such as button pseudo-presses.

generic
   type Sample_Value is private;
   No_Value : Sample_Value;
package NXT.Filtering is

   type Filter (Max_Samples_Required : Positive) is limited private;
   --  A filter for removing noisy inputs that are detected by the
   --  hardware but are not real inputs by a user. The discriminant is the
   --  number of successive samples required for a detected input to be
   --  considered a real input.

   function Filtered (The_Filter : Filter; Latest_Sample : Sample_Value)
      return Sample_value;
   --  Returns the value that the user has actually input.
   --  Returns No_Value if no input has been detected.
   --  Updates the filter state accordingly.

private

   type Filter (Max_Samples_Required : Positive) is limited
      record
         Detected        : Sample_Value := No_Value;
         Previous_Sample : Sample_Value := No_Value;
         Detected_Count  : Natural := 0;
      end record;

end NXT.Filtering;
