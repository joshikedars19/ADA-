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

with System;                   use System;
with System.Storage_Elements;  use System.Storage_Elements;
with Ada.Unchecked_Conversion;

package body NXT.Audio.Wav is

   subtype Identifier is String (1 .. 4);

   type Basic_Chunk is
      record
         Id   : Identifier;
         Size : Unsigned_32;
         Data : Unsigned_32;
      end record;
   --  Each chunk contains a four-character identifier (eg "data"), the size in
   --  bytes of the remaining data, and data of that size. We don't need to
   --  model the data itself because we just need to get the address of it, so
   --  we only declare a simple component for that purpose. The exception to
   --  that approach is the format chunk, where we need to access some of the
   --  actual components (eg the sample rate).

   type Basic_Chunk_Pointer is access all Basic_Chunk;
   for Basic_Chunk_Pointer'Storage_Size use 0;

   type Format_Chunk is
      record
         Id              : Identifier;
         Size            : Unsigned_32;
         Audio_Format    : Unsigned_16; -- 1 for PCM, others mean compression
         Num_Channels    : Unsigned_16;
         Sample_Rate     : Unsigned_32;
         Byte_Rate       : Unsigned_32;
         Block_Align     : Unsigned_16;
         Bits_Per_Sample : Unsigned_16; -- 8, 16, etc
      end record;

   Linear_PCM : constant := 1;  -- for audio format

   type Format_Chunk_Pointer is access all Format_Chunk;
   for Format_Chunk_Pointer'Storage_Size use 0;

   generic
      type Chunk is private;
      type Required_Chunk_Pointer is access all Chunk;
   function Chunk_Location (Name : Identifier; Within : File)
      return Required_Chunk_Pointer;
   --  Search the chunks in the file in memory, looking for the chunk with an
   --  Id matching Name.

   --------------------
   -- Chunk_Location --
   --------------------

   function Chunk_Location (Name : Identifier;  Within : File)
    return Required_Chunk_Pointer
   is
      Ptr         : Integer_Address;
      Max_Address : Integer_Address;

      Basic_Chunk_Size : constant Integer_Address := Basic_Chunk'Size / 8;
      --  the number of bytes required to represent a complete Basic_Chunk

      Size_of_Size_Field : constant := Unsigned_32'Size / 8;
      --  the number of bytes required to represent the size component within
      --  any kind of chunk

      function As_Chunk_Pointer is
        new Ada.Unchecked_Conversion (Integer_Address, Basic_Chunk_Pointer);

      function As_Required_Chunk_Pointer is
        new Ada.Unchecked_Conversion (Integer_Address, Required_Chunk_Pointer);

      function As_Identifier is
        new Ada.Unchecked_Conversion (Unsigned_32, Identifier);

   begin
      Ptr := To_Integer (Within'Address);

      if As_Chunk_Pointer (Ptr).Id /= "RIFF" then
         raise Invalid_Format;
      end if;
      if As_Identifier (As_Chunk_Pointer (Ptr).Data) /= "WAVE" then
         raise Invalid_Format;
      end if;

      if Name = As_Identifier (As_Chunk_Pointer (Ptr).Data) then
         return As_Required_Chunk_Pointer (Ptr);
      end if;

      Max_Address := To_Integer (Within'Address) +
        Integer_Address (As_Chunk_Pointer (Ptr).Size);
      --  The first chunk's size indicates the entire file size, rather than
      --  the chunk size, so it does not tell us where the next chunk is
      --  located. Instead we use it to bound our search, in case the named
      --  chunk is not found within the region of memory corresponding to the
      --  file.

      Ptr := Ptr + Basic_Chunk_Size;  --  Go to the second chunk

      while As_Chunk_Pointer (Ptr).Id /= Name loop
         declare
            This : Basic_Chunk renames As_Chunk_Pointer (Ptr).all;
         begin
            Ptr := To_Integer (This.Size'Address) +
                   Integer_Address (This.Size)    +
                   Size_of_Size_Field;
            if Ptr > Max_Address then
               return null;
            end if;
         end;
      end loop;

      return As_Required_Chunk_Pointer (Ptr);
   end Chunk_Location;

   -----------------
   -- Chunk_Named --
   -----------------

   function Chunk_Named is
     new Chunk_Location (Basic_Chunk, Basic_Chunk_Pointer);

   -----------------
   -- Chunk_Named --
   -----------------

   function Chunk_Named is
     new Chunk_Location (Format_Chunk, Format_Chunk_Pointer);

   ----------
   -- Play --
   ----------

   procedure Play (This : File;  Volume : Allowed_Volume) is
      Format : constant Format_Chunk_Pointer := Chunk_Named ("fmt ", This);
      Sound  : constant Basic_Chunk_Pointer := Chunk_Named ("data", This);
   begin
      if Format.Audio_Format /= Linear_PCM then
         raise Invalid_Format;
      end if;
      Play_Sample (Sound.Data'Address,
                   Sound.Size,
                   Volume,
                   Format.Sample_Rate);
   end Play;

end NXT.Audio.Wav;
