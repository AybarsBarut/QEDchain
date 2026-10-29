with Interfaces; use Interfaces;
package body ChainGuard.SHA256 with SPARK_Mode => On is
   -- FIPS 180-4 sections 4.2.2, 5.1.1, 5.3.3 and 6.2.2.
   type Schedule is array (Natural range 0 .. 63) of Word32;
   K : constant Schedule :=
     (16#428a2f98#, 16#71374491#, 16#b5c0fbcf#, 16#e9b5dba5#,
      16#3956c25b#, 16#59f111f1#, 16#923f82a4#, 16#ab1c5ed5#,
      16#d807aa98#, 16#12835b01#, 16#243185be#, 16#550c7dc3#,
      16#72be5d74#, 16#80deb1fe#, 16#9bdc06a7#, 16#c19bf174#,
      16#e49b69c1#, 16#efbe4786#, 16#0fc19dc6#, 16#240ca1cc#,
      16#2de92c6f#, 16#4a7484aa#, 16#5cb0a9dc#, 16#76f988da#,
      16#983e5152#, 16#a831c66d#, 16#b00327c8#, 16#bf597fc7#,
      16#c6e00bf3#, 16#d5a79147#, 16#06ca6351#, 16#14292967#,
      16#27b70a85#, 16#2e1b2138#, 16#4d2c6dfc#, 16#53380d13#,
      16#650a7354#, 16#766a0abb#, 16#81c2c92e#, 16#92722c85#,
      16#a2bfe8a1#, 16#a81a664b#, 16#c24b8b70#, 16#c76c51a3#,
      16#d192e819#, 16#d6990624#, 16#f40e3585#, 16#106aa070#,
      16#19a4c116#, 16#1e376c08#, 16#2748774c#, 16#34b0bcb5#,
      16#391c0cb3#, 16#4ed8aa4a#, 16#5b9cca4f#, 16#682e6ff3#,
      16#748f82ee#, 16#78a5636f#, 16#84c87814#, 16#8cc70208#,
      16#90befffa#, 16#a4506ceb#, 16#bef9a3f7#, 16#c67178f2#);

   procedure Compress (H : in out State_Words; Data : Buffer_Type) is
      W : Schedule := (others => 0);
      A : Word32 := H (0); B : Word32 := H (1);
      C : Word32 := H (2); D : Word32 := H (3);
      E : Word32 := H (4); F : Word32 := H (5);
      G : Word32 := H (6); V : Word32 := H (7);
      S0, S1, T1, T2 : Word32;
   begin
      for I in 0 .. 15 loop
         W (I) := Shift_Left (Word32 (Data (4 * I)), 24)
           or Shift_Left (Word32 (Data (4 * I + 1)), 16)
           or Shift_Left (Word32 (Data (4 * I + 2)), 8)
           or Word32 (Data (4 * I + 3));
      end loop;
      for I in 16 .. 63 loop
         S0 := Rotate_Right (W (I - 15), 7) xor Rotate_Right (W (I - 15), 18)
           xor Shift_Right (W (I - 15), 3);
         S1 := Rotate_Right (W (I - 2), 17) xor Rotate_Right (W (I - 2), 19)
           xor Shift_Right (W (I - 2), 10);
         W (I) := W (I - 16) + S0 + W (I - 7) + S1;
      end loop;
      for I in W'Range loop
         S1 := Rotate_Right (E, 6) xor Rotate_Right (E, 11) xor Rotate_Right (E, 25);
         T1 := V + S1 + ((E and F) xor ((not E) and G)) + K (I) + W (I);
         S0 := Rotate_Right (A, 2) xor Rotate_Right (A, 13) xor Rotate_Right (A, 22);
         T2 := S0 + ((A and B) xor (A and C) xor (B and C));
         V := G; G := F; F := E; E := D + T1;
         D := C; C := B; B := A; A := T1 + T2;
      end loop;
      H := (H (0) + A, H (1) + B, H (2) + C, H (3) + D,
            H (4) + E, H (5) + F, H (6) + G, H (7) + V);
   end Compress;

   procedure Feed (C : in out Context; Value : Byte)
     with Post => C.Used = (C.Used'Old + 1) mod 64
       and then C.Total = C.Total'Old
   is
   begin
      C.Buffer_Data (C.Used) := Value;
      if C.Used = 63 then
         Compress (C.H, C.Buffer_Data);
         C.Used := 0;
      else
         C.Used := C.Used + 1;
      end if;
   end Feed;

   procedure Initialize (C : out Context) is
   begin
      C := (H => Initial, Buffer_Data => (others => 0), Used => 0, Total => 0);
   end Initialize;

   procedure Update (C : in out Context; Data : Byte_Array) is
   begin
      for I in Data'Range loop
         pragma Loop_Invariant (C.Total = C.Total'Loop_Entry);
         Feed (C, Data (I));
      end loop;
      C.Total := C.Total + Word64 (Data'Length);
   end Update;

   function Finish (C : Context) return Hash is
      Work : Context := C;
      Bits : constant Word64 := C.Total * 8;
      Result : Hash := (others => 0);
   begin
      Feed (Work, 16#80#);
      if Work.Used > 56 then
         while Work.Used /= 0 loop
            pragma Loop_Invariant (Work.Used = 0 or Work.Used > 56);
            pragma Loop_Variant (Increases => Work.Used);
            Feed (Work, 0);
         end loop;
      end if;
      while Work.Used < 56 loop
         pragma Loop_Invariant (Work.Used <= 56);
         pragma Loop_Variant (Increases => Work.Used);
         Feed (Work, 0);
      end loop;
      for I in 0 .. 7 loop
         Feed (Work, Byte (Shift_Right (Bits, 8 * (7 - I)) and 16#ff#));
      end loop;
      for I in 0 .. 7 loop
         for J in 0 .. 3 loop
            Result (4 * I + J) :=
              Byte (Shift_Right (Work.H (I), 8 * (3 - J)) and 16#ff#);
         end loop;
      end loop;
      return Result;
   end Finish;

   function Digest (Data : Byte_Array) return Hash is
      C : Context;
   begin
      Initialize (C);
      Update (C, Data);
      return Finish (C);
   end Digest;
end ChainGuard.SHA256;
