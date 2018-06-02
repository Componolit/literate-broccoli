with JWX.JWK;
with JWX.Base64;
with JWX.LSC;
with JWX.Util;

with LSC.Types;
with LSC.SHA256;
with LSC.HMAC_SHA256;

with Interfaces;
use type LSC.SHA256.Message_Index;

package body JWX.Crypto
   with
      Refined_State => (State => (K.State))
is
   package K is new JWX.JWK (Key);

   -----------------------
   -- Valid_HMAC_SHA256 --
   -----------------------

   procedure Valid_HMAC_SHA256 (Valid : out Boolean)
   is
      Payload_Raw : JWX.Byte_Array (1 .. Payload'Length);
      Key_Raw     : JWX.Byte_Array (1 .. (Key'Length/4 + 1) * 3);
      Auth_Raw    : JWX.Byte_Array (1 .. 32);

      Payload_LSC : Standard.LSC.SHA256.Message_Type (1 .. (Payload_Raw'Length - 1) / 64 + 1);
      Auth_Input  : Standard.LSC.SHA256.SHA256_Hash_Type;
      Auth_Calc   : Standard.LSC.SHA256.SHA256_Hash_Type;
      Key_LSC     : Standard.LSC.SHA256.Block_Type;

      Auth_Length    : Natural;
      Key_Length     : Natural;

      use JWX.LSC;
      use SC.Types;
      use Interfaces;
   begin
      Valid := False;
      K.Select_Key;

      if not K.Loaded or else
         not K.Valid
      then
         return;
      end if;
   
      if K.Algorithm /= Alg_Invalid and then
         K.Algorithm /= Alg_HS256
      then
         return;
      end if;

      K.K (Key_Raw, Key_Length);
      if Key_Length = 0
      then
         return;
      end if;

      --  Convert key into LSC compatible format
      LSC.JWX_Byte_Array_To_LSC_Word32_Array
         (Input  => Key_Raw (Key_Raw'First .. Key_Raw'First + Key_Length),
          Output => Key_LSC);

      --  Convert string to JWX byte array
      JWX.Util.To_Byte_Array (Payload, Payload_Raw);

      --  Convert payload into LSC compatible format
      LSC.JWX_Byte_Array_To_LSC_SHA256_Message
         (Input  => Payload_Raw,
          Output => Payload_LSC);

      --  Decode authenticator
      Base64.Decode_Url (Encoded => Auth,
                         Length  => Auth_Length,
                         Result  => Auth_Raw);
      if Auth_Length /= 32
      then
         return;
      end if;

      --  Convert authenticator LSC compatible format
      LSC.JWX_Byte_Array_To_LSC_Word32_Array
         (Input  => Auth_Raw,
          Output => Auth_Input);

      Auth_Calc := SC.HMAC_SHA256.Pseudorandom
         (Key     => Key_LSC,
          Message => Payload_LSC,
          Length  => SC.SHA256.Message_Index (Payload'Length) * 8);

      --  Validate
      if Auth_Input /= Auth_Calc
      then
         return;
      end if;

      Valid := True;
   end Valid_HMAC_SHA256;

   -----------
   -- Valid --
   -----------

   procedure Valid (Alg   : Alg_Type;
                    Valid : out Boolean)
   is
   begin
      Valid := False;
      case Alg is
         when Alg_HS256 => Valid_HMAC_SHA256 (Valid);
         when others    => null;
      end case;
   end Valid;

end JWX.Crypto;
