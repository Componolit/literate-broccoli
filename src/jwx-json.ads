--
-- \brief  JSON decoding (RFC 7159)
-- \author Alexander Senier
-- \date   2018-05-12
--
-- Copyright (C) 2018 Componolit GmbH
--
-- This file is part of JWX, which is distributed under the terms of the
-- GNU Affero General Public License version 3.
--

generic

   Input_Data   : String;
   Context_Size : Natural := Input_Data'Length / 3 + 2;

package JWX.JSON
is

   -- This is a workaround for a bug in GNAT prior to Community 2018, where a
   -- generic formal parameter is not considered a legal component of refined
   -- state.
   Data : constant String := Input_Data;

   type Kind_Type is (Kind_Invalid,
                      Kind_Null,
                      Kind_Boolean,
                      Kind_Real,
                      Kind_Integer,
                      Kind_String,
                      Kind_Object,
                      Kind_Array);

   type Match_Type is (Match_OK,
                       Match_None,
                       Match_Invalid,
                       Match_Out_Of_Memory);

   type Index_Type is new Natural range 1 .. Context_Size;
   Null_Index : constant Index_Type := Index_Type'First;
   End_Index  : constant Index_Type := Index_Type'Last;

   -- Parse a JSON file
   procedure Parse (Match : out Match_Type)
   with
      Pre => Data'First >= 0 and
             Data'Last < Natural'Last and
             Data'First <= Data'Last;

   -- Assert that a @Index@ has a certain kind
   function Has_Kind (Index : Index_Type;
                      Kind  : Kind_Type) return Boolean
   with
      Ghost;

   -- Return kind of current element of a context
   function Get_Kind (Index : Index_Type := Null_Index) return Kind_Type
   with
      Post   => Has_Kind (Index, Get_Kind'Result);

   -- Return value of a boolean context element
   function Get_Boolean (Index : Index_Type := Null_Index) return Boolean
   with
      Pre => Get_Kind (Index) = Kind_Boolean;

   -- Return value of real context element
   function Get_Real (Index : Index_Type := Null_Index) return Real_Type
   with
      Pre => Get_Kind (Index) = Kind_Real or
             Get_Kind (Index) = Kind_Integer;

   -- Return value of integer context element
   function Get_Integer (Index : Index_Type := Null_Index) return Integer_Type
   with
      Pre => Get_Kind (Index) = Kind_Integer;

   -- Return value of a string context element
   function Get_String (Index : Index_Type := Null_Index) return String
   with
      Pre => Get_Kind (Index) = Kind_String;

   -- Get range of stringe object inside Data
   function Get_Range (Index : Index_Type := Null_Index) return Range_Type
   with
      Pre => Get_Kind (Index) = Kind_String,
      Post => (if Get_Range'Result /= Empty_Range then
                  Get_Range'Result.First >= Data'First and
                  Get_Range'Result.Last  <= Data'Last and
                  Get_Range'Result.First <= Get_Range'Result.Last and
                  Get_Range'Result.Last < Positive'Last);

   -- Query object
   function Query_Object (Name  : String;
                          Index : Index_Type := Null_Index) return Index_Type
   with
      Pre => Get_Kind (Index) = Kind_Object;

   -- Return number of elements of an object
   function Elements (Index : Index_Type := Null_Index) return Natural
   with
      Pre => Get_Kind (Index) = Kind_Object;

   -- Return length of an array
   function Length (Index : Index_Type := Null_Index) return Natural
   with
      Pre => Get_Kind (Index) = Kind_Array,
      Annotate => (GNATprove, Terminating);


   -- Return object at given position of an array
   function Pos (Position : Natural;
                 Index    : Index_Type := Null_Index) return Index_Type
   with
      Pre => Get_Kind (Index) = Kind_Array;

end JWX.JSON;
