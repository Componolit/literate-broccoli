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

   Data_Length  : Natural;
   Context_Size : Natural := Data_Length/3 + 2;

package JWX.JSON
   with
      SPARK_Mode,
      Abstract_State => State,
      Initializes    => State
is

   type Kind_Type is (Kind_Invalid,
                      Kind_Null,
                      Kind_Boolean,
                      Kind_Float,
                      Kind_Integer,
                      Kind_String,
                      Kind_Object,
                      Kind_Array);

   type Match_Type is (Match_OK,
                       Match_None,
                       Match_Invalid,
                       Match_Out_Of_Memory);

   type Index_Type is new Natural range 1 .. Context_Size;
   Null_Index : constant Index_Type;
   End_Index  : constant Index_Type;

   -- Parse a JSON file
   procedure Parse (Input : String;
                    Match : out Match_Type);

   -- Return kind of current element of a context
   function Get_Kind (Index : Index_Type := Null_Index) return Kind_Type;

   -- Return value of a boolean context element
   function Get_Boolean (Index : Index_Type := Null_Index) return Boolean
   with
      Pre => Get_Kind (Index) = Kind_Boolean;

   -- Return value of float context element
   function Get_Float (Index : Index_Type := Null_Index) return Float
   with
      Pre => Get_Kind (Index) = Kind_Float or
             Get_Kind (Index) = Kind_Integer;

   -- Return value of integer context element
   function Get_Integer (Index : Index_Type := Null_Index) return Long_Integer
   with
      Pre => Get_Kind (Index) = Kind_Integer;

   -- Return value of a string context element
   function Get_String (Index : Index_Type := Null_Index) return String
   with
      Pre => Get_Kind (Index) = Kind_String;

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
      Pre => Get_Kind (Index) = Kind_Array;

   -- Return object at given position of an array
   function Pos (Position : Natural;
                 Index    : Index_Type := Null_Index) return Index_Type
   with
      Pre => Get_Kind (Index) = Kind_Array;

private

   Null_Index : constant Index_Type := Index_Type'First;
   End_Index  : constant Index_Type := Index_Type'Last;

end JWX.JSON;