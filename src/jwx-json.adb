--
--  @summary JSON decoding (RFC 7159)
--  @author  Alexander Senier
--  @date    2018-05-12
--
--  Copyright (C) 2018 Componolit GmbH
--
--  This file is part of JWX, which is distributed under the terms of the
--  GNU Affero General Public License version 3.
--

package body JWX.JSON
is

   type Context_Element_Type (Kind : Kind_Type := Kind_Invalid) is
   record
      Offset      : Natural    := 0;
      Next_Member : Index_Type := Null_Index;
      Next_Value  : Index_Type := Null_Index;
      case Kind is
         when Kind_Null
            | Kind_Invalid
            | Kind_Object
            | Kind_Array => null;
         when Kind_Boolean =>
            Boolean_Value  : Boolean      := False;
         when Kind_Real =>
            Real_Value     : Real_Type    := 0.0;
         when Kind_Integer =>
            Integer_Value  : Integer_Type := 0;
         when Kind_String =>
            String_Start   : Integer      := 0;
            String_End     : Integer      := 0;
      end case;
   end record;

   type Context_Type is array (Index_Type) of Context_Element_Type;

   procedure Parse_Internal (Match : out Match_Type;
                             Depth : Natural)
   with
      Pre => Data'First >= 0 and
             Data'Last < Natural'Last;

   ---------------------
   -- Invalid_Element --
   ---------------------

   function Invalid_Element (Off : Natural := 0) return Context_Element_Type is
   --  Construct invalid element
      (Kind        => Kind_Invalid,
       Offset      => Off,
       Next_Member => Null_Index,
       Next_Value  => Null_Index);

   Context       : Context_Type := (others => Invalid_Element);
   Context_Index : Index_Type := Index_Type'First;
   Offset        : Natural    := 0;

   ------------------
   -- Null_Element --
   ------------------

   function Null_Element (Off : Natural) return Context_Element_Type is
   --  Construct null element
      (Kind        => Kind_Null,
       Offset      => Off,
       Next_Member => Null_Index,
       Next_Value  => Null_Index);

   ---------------------
   -- Boolean_Element --
   ---------------------

   function Boolean_Element (Value : Boolean; Off : Natural) return Context_Element_Type is
   --  Construct boolean element
      (Kind          => Kind_Boolean,
       Offset        => Off,
       Boolean_Value => Value,
       Next_Member   => Null_Index,
       Next_Value    => Null_Index);

   -------------------
   -- Real_Element --
   -------------------

   function Real_Element (Value : Real_Type; Off : Natural) return Context_Element_Type is
   --  Construct real element
      (Kind        => Kind_Real,
       Offset      => Off,
       Real_Value  => Value,
       Next_Member => Null_Index,
       Next_Value  => Null_Index);

   ---------------------
   -- Integer_Element --
   ---------------------

   function Integer_Element (Value : Integer_Type; Off : Natural) return Context_Element_Type is
   --  Construct integer element
      (Kind          => Kind_Integer,
       Offset        => Off,
       Integer_Value => Value,
       Next_Member   => Null_Index,
       Next_Value    => Null_Index);

   --------------------
   -- String_Element --
   --------------------

   function String_Element (String_Start : Integer;
                            String_End   : Integer;
                            Off          : Natural) return Context_Element_Type is
   --  Construct string element
      (Kind         => Kind_String,
       Offset       => Off,
       String_Start => String_Start,
       String_End   => String_End,
       Next_Member  => Null_Index,
       Next_Value   => Null_Index);

   --------------------
   -- Object_Element --
   --------------------

   function Object_Element (Off : Natural) return Context_Element_Type is
   --  Construct object element
      (Kind        => Kind_Object,
       Offset      => Off,
       Next_Member => Null_Index,
       Next_Value  => Null_Index);

   -------------------
   -- Array_Element --
   -------------------

   function Array_Element (Off : Natural) return Context_Element_Type is
   --  Construct array element
      (Kind        => Kind_Array,
       Offset      => Off,
       Next_Member => Null_Index,
       Next_Value  => Null_Index);

   pragma Warnings (Off, "postcondition does not check the outcome of calling");

   procedure Prf_Mult_Protect (Arg1  : Integer_Type;
                               Arg2  : Integer_Type;
                               Upper : Integer_Type)
   with
      Ghost,
      Pre    => (Arg1 >= 0 and Arg2 > 0 and Upper >= 0 and Arg1 < Upper)
                 and then Arg1 <= Upper / Arg2,
      Post   => Arg1 * Arg2 >= 0 and Arg1 * Arg2 <= Upper;

   pragma Warnings (On, "postcondition does not check the outcome of calling");

   procedure Prf_Mult_Protect (Arg1  : Integer_Type;
                               Arg2  : Integer_Type;
                               Upper : Integer_Type) is null;

   ---------
   -- Get --
   ---------

   function Get (Index : Index_Type := Null_Index) return Context_Element_Type;
   --  Return current element of a context

   function Get (Index : Index_Type := Null_Index) return Context_Element_Type
   is
   begin
      if Index = Null_Index
      then
         return Context (Context_Index);
      elsif Index = End_Index
      then
         return Invalid_Element;
      else
         return Context (Index);
      end if;
   end Get;

   --------------
   -- Has_Kind --
   --------------

   function Has_Kind (Index : Index_Type;
                      Kind  : Kind_Type) return Boolean
   is
      (Get (Index).Kind = Kind);

   ---------
   -- Set --
   ---------

   procedure Set (Value : Context_Element_Type;
                  Index : Index_Type := Null_Index);
   --  Return current element of a context

   procedure Set (Value : Context_Element_Type;

                  Index : Index_Type := Null_Index)
   is
   begin
      if Index = Null_Index
      then
         Context (Context_Index) := Value;
      else
         Context (Index) := Value;
      end if;
   end Set;

   -----------
   -- Reset --
   -----------

   procedure Reset;
   --  Initialize context state

   procedure Reset
   is
   begin
      Context_Index := Context'First;
      Offset := 0;
   end Reset;

   --------------
   -- Get_Kind --
   --------------

   function Get_Kind (Index : Index_Type := Null_Index) return Kind_Type
   is
   begin
      return Get (Index).Kind;
   end Get_Kind;

   -----------------
   -- Get_Boolean --
   -----------------

   function Get_Boolean (Index : Index_Type := Null_Index) return Boolean
   is
   begin
      return Get (Index).Boolean_Value;
   end Get_Boolean;

   --------------
   -- Get_Real --
   --------------

   function Get_Real (Index : Index_Type := Null_Index) return Real_Type
   is
   begin
      if Get_Kind (Index) = Kind_Integer
      then
         return Real_Type (Get (Index).Integer_Value);
      end if;
      return Get (Index).Real_Value;
   end Get_Real;

   -----------------
   -- Get_Integer --
   -----------------

   function Get_Integer (Index : Index_Type := Null_Index) return Integer_Type
   is
   begin
      return Get (Index).Integer_Value;
   end Get_Integer;

   ---------------
   -- Get_Range --
   ---------------

   function Get_Range (Index : Index_Type := Null_Index) return Range_Type
   is
      Element : constant Context_Element_Type := Get (Index);
   begin
      if Element.String_Start in Data'Range and
         Element.String_End in Data'Range and
         Element.String_End < Positive'Last and
         Element.String_Start <= Element.String_End
      then
         return Range_Type'(First => Element.String_Start,
                            Last  => Element.String_End);
      else
         return Empty_Range;
      end if;
   end Get_Range;

   ----------------
   -- Get_String --
   ----------------

   function Get_String (Index : Index_Type := Null_Index) return String
   is
      Element : constant Context_Element_Type := Get (Index);
   begin
      if Element.String_Start in Data'Range and
         Element.String_End in Data'Range
      then
         return Data (Element.String_Start .. Element.String_End);
      else
         return "";
      end if;
   end Get_String;

   ----------------------
   -- Skip_Whitespace --
   ----------------------

   procedure Skip_Whitespace;
   --  Skip all whitespace from current position

   procedure Skip_Whitespace
   is
   begin
      loop
         if Offset >= Data'Length
         then
            return;
         end if;

         if Data (Data'First + Offset) = ASCII.HT or
            Data (Data'First + Offset) = ASCII.LF or
            Data (Data'First + Offset) = ASCII.CR or
            Data (Data'First + Offset) = ASCII.FF or
            Data (Data'First + Offset) = ' '
         then
            Offset := Offset + 1;
         else
            return;
         end if;
      end loop;
   end Skip_Whitespace;

   ----------------
   -- Parse_Null --
   ----------------

   procedure Parse_Null (Match : out Match_Type);
   --  Parse JSON "null" element

   procedure Parse_Null (Match : out Match_Type)
   is
      Base : Natural;
   begin
      Match := Match_None;

      if Context_Index >= Context'Last
      then
         Match := Match_Out_Of_Memory;
         return;
      end if;

      if Offset > Data'Length - 4
      then
         Match := Match_None;
         return;
      end if;

      Base := Data'First + Offset;
      if Data (Base .. Base + 3) = "null"
      then
         Set (Null_Element (Offset));
         Context_Index := Context_Index + 1;
         Offset := Offset + 4;
         Match := Match_OK;
      end if;

   end Parse_Null;

   ----------------
   -- Parse_Bool --
   ----------------

   procedure Parse_Bool (Match : out Match_Type);
   --  Parse JSON boolean

   procedure Parse_Bool (Match : out Match_Type)
   is
      Base : Natural;
   begin
      Match := Match_None;

      if Context_Index >= Context'Last
      then
         Match := Match_Out_Of_Memory;
         return;
      end if;

      if Offset > Data'Length - 4
      then
         Match := Match_None;
         return;
      end if;

      Base := Data'First + Offset;
      if Data (Base .. Base + 3) = "true"
      then
         Set (Boolean_Element (True, Offset));
         Context_Index := Context_Index + 1;
         Offset := Offset + 4;
         Match := Match_OK;
         return;
      end if;

      if Offset > Data'Length - 5
      then
         Match := Match_None;
         return;
      end if;

      if Data (Base .. Base + 4) = "false"
      then
         Set (Boolean_Element (False, Offset));
         Context_Index := Context_Index + 1;
         Offset := Offset + 5;
         Match := Match_OK;
      end if;

   end Parse_Bool;

   ---------------
   -- Match_Set --
   ---------------

   function Match_Set (S : String) return Boolean
   with
      Pre    => Data'First >= 0 and Data'Last < Natural'Last,
      Post   => (if Match_Set'Result then
                    (for some E of S => E = Data (Data'First + Offset)));

   function Match_Set (S : String) return Boolean
   is
   begin
      for Value of S
      loop
         if Offset < Data'Length and then
            Data (Data'First + Offset) = Value
         then
            return True;
         end if;
      end loop;
      return False;
   end Match_Set;

   ---------------
   -- To_Number --
   ---------------

   function To_Number (Value : Character) return Integer_Type
      is (Character'Pos (Value) - Character'Pos ('0'))
   with
      Pre  => Value >= '0' and Value <= '9',
      Post => To_Number'Result >=  0 and
              To_Number'Result <  10;

   ---------------------------
   -- Parse_Fractional_Part --
   ---------------------------

   procedure Parse_Fractional_Part
     (Match   : out Match_Type;
      Result  : out Real_Type)
   with
      Pre =>
         Data'First >= 0 and
         Data'Last < Natural'Last and
         Data'First < Integer'Last - Offset and
         Offset < Data'Length,
      Post =>
         (case Match is
            when Match_OK => Result >= 0.0 and Result < 1.0,
            when others   => Result = 0.0 and Offset = Offset'Old);

   procedure Parse_Fractional_Part
     (Match   :    out Match_Type;
      Result  :    out Real_Type)
   is
      Divisor     : Integer_Type := 1;
      Tmp         : Integer_Type := 0;
      Old_Offset  : constant Natural := Offset;

   begin
      Result := 0.0;
      Match  := Match_None;

      if not Match_Set (".") then
         return;
      end if;

      Match := Match_Invalid;
      if Offset >= Natural'Last
      then
         return;
      end if;

      Offset := Offset + 1;

      loop
         pragma Loop_Invariant (Divisor > Tmp);
         pragma Loop_Invariant (Tmp >= 0);

         if Data'First > Integer'Last - Offset or
            Offset > Data'Length - 1
         then
            if Match /= Match_OK then
               Offset := Old_Offset;
               return;
            end if;
            exit;
         end if;

         if Data (Data'First + Offset) < '0' or
            Data (Data'First + Offset) > '9'
         then
            if Match /= Match_OK then
               Offset := Old_Offset;
               return;
            end if;
            exit;
         end if;

         if Tmp >= Integer_Type'Last / 10
         then
            Match := Match_Invalid;
            Offset := Old_Offset;
            return;
         end if;

         Prf_Mult_Protect (Arg1  => Tmp,
                           Arg2  => 10,
                           Upper => Integer_Type'Last);

         Tmp := 10 * Tmp + To_Number (Data (Data'First + Offset));
         Offset := Offset + 1;

         if Divisor >= Integer_Type'Last / 10
         then
            Match := Match_Invalid;
            Offset := Old_Offset;
            return;
         end if;

         Divisor := Divisor * 10;

         --  At least one decimal place matched.
         Match := Match_OK;
      end loop;

      Result := Real_Type (Tmp) / Real_Type (Divisor);
      if Result >= 1.0 then
         Result := 0.0;
         Match  := Match_Invalid;
         Offset := Old_Offset;
      end if;

   end Parse_Fractional_Part;

   -------------------
   -- Parse_Integer --
   -------------------

   procedure Parse_Integer
     (Check_Leading :        Boolean;
      Match         :    out Match_Type;
      Result        :    out Integer_Type;
      Negative      :    out Boolean)
   with
      Pre  => Data'First >= 0 and
              Data'Last < Natural'Last,
      Post => Result >= 0;

   procedure Parse_Integer
     (Check_Leading :        Boolean;
      Match         :    out Match_Type;
      Result        :    out Integer_Type;
      Negative      :    out Boolean)
   is
      Leading_Zero : Boolean := False;
      Num_Matches  : Natural := 0;
      Old_Offset   : constant Natural := Offset;
   begin
      Match    := Match_Invalid;
      Negative := False;
      Result   := 0;

      if Offset > Data'Length - 1
      then
         Match := Match_Invalid;
         return;
      end if;

      Negative := Match_Set ("-");
      if Negative
      then
         Offset := Offset + 1;
      end if;

      loop

         if Offset >= Data'Length
         then
            exit;
         end if;

         if Num_Matches >= Natural'Last
         then
            Match := Match_Invalid;
            Offset := Old_Offset;
            return;
         end if;

         --  Valid digit?
         exit when
            Data (Data'First + Offset) < '0' or
            Data (Data'First + Offset) > '9' or
            Data'First >= Integer'Last - Offset or
            Data'First > Data'Last - Offset or
            Offset > Data'Length - 1 or
            Num_Matches >= Natural'Last;

         --  Check for leading '0'
         if Num_Matches = 0 and
            Data (Data'First + Offset) = '0'
         then
            Leading_Zero := True;
         end if;

         pragma Loop_Invariant (Result >= 0);
         pragma Loop_Invariant (Data'First + Offset in Data'Range);
         pragma Loop_Invariant (Data (Data'First + Offset) >= '0');
         pragma Loop_Invariant (Data (Data'First + Offset) <= '9');

         --  Check for overflow
         if Num_Matches >= Natural'Last or
            Result >= Integer_Type'Last / 10
         then
            Match := Match_Invalid;
            Offset := Old_Offset;
            return;
         end if;

         Result := Result * 10;
         Result := Result + To_Number (Data (Data'First + Offset));
         Offset      := Offset + 1;
         Num_Matches := Num_Matches + 1;
      end loop;

      --  No
      if Num_Matches = 0
      then
         Match  := Match_None;
         Offset := Old_Offset;
         return;
      end if;

      --  Leading zeros found
      if Check_Leading and
         ((Result > 0 and Leading_Zero) or
          (Result = 0 and Num_Matches > 1))
      then
         Offset := Old_Offset;
         return;
      end if;

      Match := Match_OK;
   end Parse_Integer;

   -------------------------
   -- Parse_Exponent_Part --
   -------------------------

   procedure Parse_Exponent_Part
     (Match    :    out Match_Type;
      Result   :    out Integer_Type;
      Negative :    out Boolean)
   with
      Pre  => Data'First >= 0 and
              Data'Last < Natural'Last,
      Post => (case Match is
                  when Match_OK   => Result > 0,
                  when Match_None => Result = 1 and Negative = False,
                  when others     => True);

   procedure Parse_Exponent_Part
     (Match    :    out Match_Type;
      Result   :    out Integer_Type;
      Negative :    out Boolean)
   is
      Scale            : Integer_Type;
      Match_Exponent   : Match_Type;
      Integer_Negative : Boolean;
      Old_Offset       : constant Natural := Offset;
   begin
      Result   := 1;
      Negative := False;
      Match    := Match_None;

      if not Match_Set ("Ee")
      then
         return;
      end if;

      Match  := Match_Invalid;
      if Offset >= Natural'Last
      then
         return;
      end if;

      Offset := Offset + 1;

      if Offset > Data'Length or else
         Data'First > Data'Last - Offset
      then
         Match := Match_None;
         Offset := Old_Offset;
         return;
      end if;

      if Match_Set ("+-")
      then
         if Data (Data'First + Offset) = '-'
         then
            Negative := True;
         end if;
         Offset := Offset + 1;
      end if;

      Parse_Integer (False, Match_Exponent, Scale, Integer_Negative);
      if Match_Exponent /= Match_OK or Integer_Negative
      then
         Offset := Old_Offset;
         return;
      end if;

      for I in 1 .. Scale
      loop
         pragma Loop_Invariant (Result > 0);

         if Result > Integer_Type'Last / 10
         then
            Offset := Old_Offset;
            return;
         end if;

         Prf_Mult_Protect (Arg1  => Result,
                           Arg2  => 10,
                           Upper => Integer_Type'Last);
         Result := Result * 10;
      end loop;

      Match := Match_OK;

   end Parse_Exponent_Part;

   ------------------
   -- Parse_Number --
   ------------------

   procedure Parse_Number (Match : out Match_Type)
   with
      Pre => Data'First >= 0 and
             Data'Last < Natural'Last;

   procedure Parse_Number (Match : out Match_Type)
   is
      Fractional_Component : Real_Type := 0.0;
      Integer_Component    : Integer_Type;
      Scale                : Integer_Type;

      Match_Int      : Match_Type;
      Match_Frac     : Match_Type := Match_None;
      Match_Exponent : Match_Type;
      Negative       : Boolean;
      Scale_Negative : Boolean;
   begin
      Parse_Integer (True, Match_Int, Integer_Component, Negative);
      if Match_Int /= Match_OK
      then
         Match := Match_Int;
         return;
      end if;

      if Data'First < Integer'Last - Offset and
         Offset < Data'Length
      then
         Parse_Fractional_Part (Match_Frac, Fractional_Component);
      end if;

      if Context_Index >= Context'Last
      then
         Match := Match_Out_Of_Memory;
         return;
      end if;

      Match := Match_Invalid;
      if Match_Frac = Match_Invalid
      then
         return;
      end if;

      Parse_Exponent_Part (Match_Exponent, Scale, Scale_Negative);
      if Match_Exponent = Match_Invalid
      then
         return;
      end if;

      --  Convert to float if either we have fractional part or dividing by the
      --  scale would yield a non-integer number.
      if Match_Frac = Match_OK or
         (Match_Exponent = Match_OK and then
          (Scale_Negative and Integer_Component mod Scale > 0))
      then
         if Real_Type (Integer_Component) >= Real_Type'Last
         then
            return;
         end if;

         declare
            Tmp : Real_Type := Real_Type (Integer_Component) + Fractional_Component;
         begin
            if Match_Exponent = Match_OK and Tmp >= 1.0
            then
               if Scale_Negative
               then
                  Tmp := Tmp / Real_Type (Scale);
               else
                  if Real_Type (Scale) >= Real_Type'Last / Tmp
                  then
                     return;
                  end if;
                  Tmp := Tmp * Real_Type (Scale);
               end if;
            end if;
            if Negative then
               if Tmp >= Real_Type'Last then
                  return;
               end if;
               Tmp := -Tmp;
            end if;
            Set (Real_Element (Tmp, Offset));
         end;
      else
         if Match_Exponent = Match_OK
         then
            if Scale_Negative
            then
               Integer_Component := Integer_Component / Scale;
            else
               if Integer_Component >= Integer_Type'Last / Scale
               then
                  return;
               end if;
               Prf_Mult_Protect (Arg1  => Integer_Component,
                                 Arg2  => Scale,
                                 Upper => Integer_Type'Last);
               Integer_Component := Integer_Component * Scale;
            end if;
         end if;
         if Negative then
            Integer_Component := -Integer_Component;
         end if;
         Set (Integer_Element (Integer_Component, Offset));
      end if;

      Context_Index := Context_Index + 1;
      Match := Match_OK;

   end Parse_Number;

   ------------------
   -- Parse_String --
   ------------------

   procedure Parse_String (Match : out Match_Type)
   with
      Pre => Data'First >= 0 and
             Data'Last < Natural'Last;

   procedure Parse_String (Match : out Match_Type)
   is
      String_Start : Natural;
      String_End   : Natural;
      Escaped      : Boolean := False;
      Old_Offset   : constant Natural := Offset;
   begin
      --  Check for starting "
      if not Match_Set ("""") then
         Match := Match_None;
         return;
      end if;

      Match := Match_Invalid;
      if Offset >= Natural'Last or
         Offset >= Data'Length
      then
         return;
      end if;

      Offset := Offset + 1;

      if Offset >= Data'Length
      then
         Offset := Old_Offset;
         return;
      end if;

      String_Start := Data'First + Offset;

      loop
         if Data'First > Integer'Last - Offset or
            Offset > Data'Length - 1
         then
            Offset := Old_Offset;
            return;
         end if;

         exit when not Escaped and Match_Set ("""");
         Escaped := (if not Escaped and Match_Set ("\") then True else False);
         Offset := Offset + 1;
      end loop;

      if Data'First > Integer'Last - Offset or
         Offset > Data'Length - 1
      then
         Offset := Old_Offset;
         return;
      end if;

      if Context_Index >= Context'Last
      then
         Offset := Old_Offset;
         Match  := Match_Out_Of_Memory;
         return;
      end if;

      if not Match_Set ("""")
      then
         Offset := Old_Offset;
         return;
      end if;
      Offset := Offset + 1;

      if Offset > Data'Length
      then
         Offset := Old_Offset;
         return;
      end if;

      String_End := Data'First + (Offset - 2);

      Set (String_Element (String_Start, String_End, Old_Offset));
      Context_Index := Context_Index + 1;
      Match := Match_OK;

   end Parse_String;

   ------------------
   -- Parse_Object --
   ------------------

   procedure Parse_Object (Match : out Match_Type;
                           Depth : Natural := 0)
   with
      Pre => Data'First >= 0 and
             Data'Last < Natural'Last and
             Depth < Natural'Last;

   procedure Parse_Object (Match : out Match_Type;
                           Depth : Natural := 0)
   is
      Object_Index    : Index_Type;
      Previous_Member : Index_Type;
      Result          : Match_Type;
      Match_Member    : Match_Type;
      Old_Offset      : constant Natural := Offset;
   begin

      if Context_Index >= Context'Last
      then
         Match := Match_Out_Of_Memory;
         return;
      end if;

      --  Check for starting {
      if not Match_Set ("{") then
         Match := Match_None;
         return;
      end if;

      Object_Index := Context_Index;
      Set (Object_Element (Old_Offset));
      Context_Index := Context_Index + 1;
      Previous_Member := Object_Index;

      Match := Match_Invalid;
      if Offset >= Natural'Last
      then
         return;
      end if;

      Offset := Offset + 1;

      loop
         Skip_Whitespace;

         if Offset >= Natural'Last or
            Data'First > Integer'Last - Offset or
            Offset > Data'Length - 1
         then
            Offset := Old_Offset;
            return;
         end if;

         --  Check for ending '}'
         if Match_Set ("}")
         then
            Offset := Offset + 1;
            exit;
         end if;

         --  Link previous element to this element
         Context (Previous_Member).Next_Member := Context_Index;
         Previous_Member := Context_Index;

         --  Parse member name
         Skip_Whitespace;
         Parse_String (Result);
         if Result /= Match_OK
         then
            Offset := Old_Offset;
            return;
         end if;

         --  Check for name separator (:)
         Skip_Whitespace;
         if Offset >= Natural'Last or
            not Match_Set (":")
         then
            Offset := Old_Offset;
            return;
         end if;
         Offset := Offset + 1;

         --  Parse member
         Parse_Internal (Match_Member, Depth + 1);
         if Match_Member /= Match_OK then
            Offset := Old_Offset;
            return;
         end if;

         Skip_Whitespace;

         if Offset >= Natural'Last
         then
            Offset := Old_Offset;
            return;
         end if;

         --  Check for value separator ','
         if Match_Set (",") then
            Offset := Offset + 1;
         end if;

      end loop;

      Context (Previous_Member).Next_Member := End_Index;
      Match := Match_OK;

   end Parse_Object;

   ------------------
   -- Parse_Array --
   ------------------
   procedure Parse_Array (Match : out Match_Type;
                          Depth : Natural := 0)
   with
      Pre => Data'First >= 0 and
             Data'Last < Natural'Last and
             Depth < Natural'Last;

   procedure Parse_Array (Match : out Match_Type;
                          Depth : Natural := 0)
   is
      AI               : Index_Type;
      Previous_Element : Index_Type;
      Match_Element    : Match_Type;
      Old_Offset       : constant Natural := Offset;
   begin

      if Context_Index >= Context'Last
      then
         Match := Match_Out_Of_Memory;
         return;
      end if;

      --  Check for starting [
      if not Match_Set ("[") then
         Match := Match_None;
         return;
      end if;

      AI := Context_Index;
      Set (Array_Element (Old_Offset));
      Context_Index := Context_Index + 1;
      Previous_Element := AI;

      Match := Match_Invalid;
      if Offset >= Natural'Last
      then
         return;
      end if;

      Offset := Offset + 1;

      loop
         Skip_Whitespace;

         if Offset >= Natural'Last or
            Data'First >= Integer'Last - Offset or
            Offset > Data'Length - 1
         then
            Offset := Old_Offset;
            return;
         end if;

         --  Check for ending ']'
         if Match_Set ("]")
         then
            Offset := Offset + 1;
            exit;
         end if;

         --  Link previous object to this element
         Context (Previous_Element).Next_Value := Context_Index;
         Previous_Element := Context_Index;

         --  Parse element
         Parse_Internal (Match_Element, Depth + 1);
         if Match_Element /= Match_OK then
            Offset := Old_Offset;
            return;
         end if;

         Skip_Whitespace;

         if Offset >= Natural'Last
         then
            Offset := Old_Offset;
            return;
         end if;

         --  Check for value separator ','
         if Match_Set (",") then
            Offset := Offset + 1;
         end if;

      end loop;

      Context (Previous_Element).Next_Value := End_Index;
      Match := Match_OK;

   end Parse_Array;

   --------------------
   -- Parse_Internal --
   --------------------

   procedure Parse_Internal (Match : out Match_Type;
                             Depth : Natural)
   is
   begin
      --  Check recursion depth
      if Depth > Depth_Max
      then
         Match := Match_Depth_Limit;
         return;
      end if;

      Skip_Whitespace;

      Parse_Null (Match);
      if Match = Match_None
      then
         Parse_Bool (Match);
         if Match = Match_None
         then
            Parse_Number (Match);
            if Match = Match_None
            then
               Parse_String (Match);
               if Match = Match_None
               then
                  Parse_Object (Match);
                  if Match = Match_None
                  then
                     Parse_Array (Match);
                  end if;
               end if;
            end if;
         end if;
      end if;
   end Parse_Internal;

   -----------
   -- Parse --
   -----------

   procedure Parse (Match : out Match_Type)
   is
   begin
      Parse_Internal (Match => Match,
                      Depth => 0);
      if Context_Index > Context'First
      then
         Reset;
      end if;
   end Parse;

   ------------------
   -- Query_Object --
   ------------------

   function Query_Object (Name  : String;
                          Index : Index_Type := Null_Index) return Index_Type
   is
      I : Index_Type := Index;
   begin
      loop
         I := Get (I).Next_Member;
         exit when I = End_Index;

         if Get_Kind (I) = Kind_String and then
            Get_String (I) = Name
         then
            --  Value object are stored next to member names
            return I + 1;
         end if;
      end loop;
      return End_Index;
   end Query_Object;

   -------------
   -- Iterate --
   -------------

   procedure Iterate (Index : Index_Type := Null_Index)
   is
      I : Index_Type := Index;
   begin
      loop
         I := Get (I).Next_Member;
         exit when I = End_Index;

         if Get_Kind (I) = Kind_String
         then
            Process (Get_String (I), I + 1);
         end if;
      end loop;
   end Iterate;

   --------------
   -- Elements --
   --------------

   function Elements (Index : Index_Type := Null_Index) return Natural
   is
      I     : Index_Type := Index;
      Count : Natural := 0;
   begin
      loop
         I := Get (I).Next_Member;
         exit when
            Count >= Natural'Last or
            I = End_Index;
         Count := Count + 1;
      end loop;
      return Count;
   end Elements;

   ------------
   -- Length --
   ------------

   function Length (Index : Index_Type := Null_Index) return Natural
   is
      Element : Context_Element_Type := Get (Index);
      Count   : Natural := 0;
   begin
      loop
         pragma Loop_Variant (Decreases => Natural'Last - Count);
         exit when
            Count >= Natural'Last or
            Element.Next_Value = End_Index;

         Element := Context (Element.Next_Value);
         Count := Count + 1;
      end loop;
      return Count;
   end Length;

   ---------
   -- Pos --
   ---------

   function Pos (Position : Natural;
                 Index    : Index_Type := Null_Index) return Index_Type
   is
      Count      : Natural := 0;
      Last_Index : Index_Type := Index;
      Element    : Context_Element_Type := Get (Last_Index);
   begin
      loop
         exit when Count = Position;

         if Element.Next_Value = End_Index
         then
            return End_Index;
         end if;

         if Count >= Natural'Last
         then
            return End_Index;
         end if;

         Last_Index := Element.Next_Value;
         Element    := Get (Element.Next_Value);
         Count      := Count + 1;
      end loop;
      return Last_Index;
   end Pos;

   ----------------
   -- Get_Offset --
   ----------------

   function Get_Offset (Index : Index_Type := Null_Index) return Natural is (Get (Index).Offset);

end JWX.JSON;
