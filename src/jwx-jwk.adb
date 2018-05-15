--
-- \brief  JWK decoding (RFC 7517)
-- \author Alexander Senier
-- \date   2018-05-13
--
-- Copyright (C) 2018 Componolit GmbH
--
-- This file is part of JWX, which is distributed under the terms of the
-- GNU Affero General Public License version 3.
--

with JWX.JSON;
with JWX.Base64;

package body JWX.JWK
   with
      SPARK_Mode,
      Refined_State => (State => (Key_Data.State,
                                  Key_Valid,
                                  Key_Kind,
                                  Key_ID,
                                  Key_Curve,
                                  Key_X,
                                  Key_Y))
is

   package Key_Data is new JSON (4096);
   Key_Valid : Boolean := False;
   Key_Kind  : Kind_Type := Kind_Invalid;
   Key_Curve : EC_Curve_Type := Curve_Invalid;
   Key_ID    : Key_Data.Index_Type := Key_Data.End_Index;
   Key_X     : Key_Data.Index_Type := Key_Data.End_Index;
   Key_Y     : Key_Data.Index_Type := Key_Data.End_Index;

   -----------------
   -- Validate_EC --
   -----------------

   function Valid_EC return Boolean
   with
      Pre => Key_Kind = Kind_EC;

   function Valid_EC return Boolean
   is
      use Key_Data;
      Crv, Y : Index_Type;
   begin
      --  EC key has 5 elements
      if Elements /= 5
      then
         return False;
      end if;

      --  Retrieve curve type 'crv'
      Crv := Query_Object ("crv");
      if Get_String (Crv) = "P-256"
      then
         Key_Curve := Curve_P256;
      elsif Get_String (Crv) = "P-384"
      then
         Key_Curve := Curve_P384;
      elsif Get_String (Crv) = "P-521"
      then
         Key_Curve := Curve_P521;
      else
         return False;
      end if;

      --  Check for 'x'
      Key_X := Query_Object ("x");
      if Key_X = End_Index then
         return False;
      end if;

      --  Check for 'y'
      Key_Y := Query_Object ("y");
      if Key_Y = End_Index then
         return False;
      end if;

      case Key_Curve is
         when Curve_P256 =>
            if Get_String (Key_X)'Length /= 43 or
               Get_String (Key_Y)'Length /= 43
            then
               return False;
            end if;
         when Curve_P384 =>
            if Get_String (Key_X)'Length /= 64 or
               Get_String (Key_Y)'Length /= 64
            then
               return False;
            end if;
         when Curve_P521 =>
            if Get_String (Key_X)'Length /= 88 or
               Get_String (Key_Y)'Length /= 88
            then
               return False;
            end if;
         when Curve_Invalid =>
            return False;
      end case;

      return True;
   end Valid_EC;

   -----------
   -- Parse --
   -----------

   procedure Parse (Input : String)
   is
      use Key_Data;
      Match : Match_Type;
      Kty   : Index_Type;
   begin
      Key_Valid := False;
      Parse (Input, Match);
      if Match /= Match_OK
      then
         return;
      end if;

      --  Key must be an object
      if Get_Kind /= Kind_Object
      then
         return;
      end if; 

      --  Retrieve key id 'kid'
      Key_ID := Query_Object ("kid");
      if Key_ID = End_Index or else
         Get_Kind (Key_ID) /= Kind_String
      then
         return;
      end if;

      --  Retrieve key type 'kty'
      Kty := Query_Object ("kty");
      if Get_String (Kty) = "EC"
      then
         Key_Kind := Kind_EC;
      else
         return;
      end if;

      -- Revieve curve
      case Key_Kind is
         when Kind_EC =>
            if not Valid_EC
            then
               return;
            end if;
         when Kind_Invalid =>
            return;
      end case;
      Key_Valid := True;
         
   end Parse;

   -----------
   -- Valid --
   -----------

   function Valid return Boolean is (Key_Valid);

   ----------
   -- Kind --
   ----------

   function Kind return Kind_Type is (Key_Kind);

   ------------
   -- Key_ID --
   ------------

   function ID return String
   is
      use Key_Data;
   begin
      return Get_String (Key_ID);
   end ID;

   -------
   -- X --
   -------

   procedure X (Value  : out Byte_Array;
                Length : out Natural)
   is
      use JWX;
      use Key_Data;
   begin
      Base64.Decode_Url (Encoded => Get_String (Key_X),
                         Length  => Length,
                         Result  => Value,
                         Padding => Base64.Padding_Implicit);
   end X;

   -------
   -- Y --
   -------

   procedure Y (Value  : out Byte_Array;
                Length : out Natural)
   is
      use JWX;
      use Key_Data;
   begin
      Base64.Decode_Url (Encoded => Get_String (Key_Y),
                         Length  => Length,
                         Result  => Value,
                         Padding => Base64.Padding_Implicit);
   end Y;

end JWX.JWK;