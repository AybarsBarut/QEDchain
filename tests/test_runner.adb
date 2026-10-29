with Ada.Text_IO;
with Ada.Command_Line;
with ChainGuard.Types; use ChainGuard.Types;
with ChainGuard.SHA256;
with ChainGuard.Chain;
with ChainGuard.Verify;
with ChainGuard.Sampling;
procedure Test_Runner is
   use type Byte;
   Failures : Natural := 0;
   procedure Check (Condition : Boolean; Name : String) is
   begin
      if not Condition then
         Ada.Text_IO.Put_Line ("FAIL: " & Name);
         Failures := Failures + 1;
      end if;
   end Check;
   function Hex (H : Hash) return String is
      Hex_Chars : constant String := "0123456789abcdef";
      R : String (1 .. 64);
   begin
      for I in H'Range loop
         R (I * 2 + 1) := Hex_Chars (Integer (H (I) / 16) + 1);
         R (I * 2 + 2) := Hex_Chars (Integer (H (I) mod 16) + 1);
      end loop;
      return R;
   end Hex;
   procedure Vector (Message, Expected, Name : String) is
      Data : Byte_Array (1 .. Message'Length);
      C : ChainGuard.SHA256.Context;
   begin
      for I in Message'Range loop
         Data (I - Message'First + 1) := Byte (Character'Pos (Message (I)));
      end loop;
      Check (Hex (ChainGuard.SHA256.Digest (Data)) = Expected, Name & " one-shot");
      ChainGuard.SHA256.Initialize (C);
      for I in Data'Range loop
         ChainGuard.SHA256.Update (C, Data (I .. I));
      end loop;
      Check (Hex (ChainGuard.SHA256.Finish (C)) = Expected, Name & " incremental");
   end Vector;
   procedure Chain_Tests (Capacity : Capacity_Type) is
      C : ChainGuard.Chain.Chain (Capacity);
   begin
      Check (ChainGuard.Verify.Verify_Chain (C), "empty chain");
      for I in 1 .. Capacity loop
         ChainGuard.Chain.Append (C, Zero_Hash);
      end loop;
      Check (C.Length = Capacity, "capacity length");
      Check (ChainGuard.Verify.Verify_Chain (C), "capacity valid");
   end Chain_Tests;
   procedure Tamper_Tests is
      use ChainGuard.Chain;
      C : ChainGuard.Chain.Chain (7);
   begin
      for I in 1 .. 7 loop
         Append (C, Zero_Hash);
      end loop;
      for Position in 0 .. 6 loop
         for Kind in 0 .. 3 loop
            declare
               Bad : ChainGuard.Chain.Chain (7) := C;
            begin
               case Kind is
                  when 0 => Bad.Blocks (Position + 1).Payload_Hash (0) := 1;
                  when 1 => Bad.Blocks (Position + 1).Prev_Hash (0) :=
                      Bad.Blocks (Position + 1).Prev_Hash (0) xor 1;
                  when 2 => Bad.Blocks (Position + 1).Index := Word64 (Position + 9);
                  when 3 => Bad.Blocks (Position + 1).Block_Hash (0) :=
                      Bad.Blocks (Position + 1).Block_Hash (0) xor 1;
               end case;
               Check (not ChainGuard.Verify.Verify_Chain (Bad), "tamper full chain");
               for Start in 0 .. 7 loop
                  for Count in 0 .. 7 - Start loop
                     Check (ChainGuard.Verify.Verify_Segment (Bad, Start, Count) =
                       (not (Position >= Start and Position < Start + Count)),
                       "tamper window membership");
                  end loop;
               end loop;
            end;
         end loop;
      end loop;
      -- An index increment must never wrap at the modular type boundary.
      declare
         A, B : Block;
      begin
         A.Index := Word64'Last;
         B.Block_Hash := Compute_Block_Hash (0, Zero_Hash, Zero_Hash);
         Check (not ChainGuard.Verify.Verify_Link (A, B), "no index wrap");
      end;
      C.Length := 8;
      Check (not ChainGuard.Verify.Verify_Chain (C), "invalid public length");
   end Tamper_Tests;
   procedure Sampling_Tests is
      use type Word64;
      A, B : Word64 := 42;
      Start_A, Start_B : Block_Count;
   begin
      for L in 1 .. 100 loop
         for Size in 1 .. L loop
            ChainGuard.Sampling.Pick_Segment (A, L, Size, Start_A);
            ChainGuard.Sampling.Pick_Segment (B, L, Size, Start_B);
            Check (A = B and Start_A = Start_B, "sampling deterministic");
            Check (Start_A + Size <= L, "sampling in range");
         end loop;
      end loop;
      A := 0;
      ChainGuard.Sampling.Pick_Segment (A, Max_Capacity, Max_Capacity, Start_A);
      Check (Start_A = 0 and A /= 0, "zero seed and whole-chain segment");
      A := Word64'Last;
      ChainGuard.Sampling.Pick_Segment (A, Max_Capacity, 1, Start_A);
      Check (Start_A < Max_Capacity, "maximum seed and length");
      A := 42;
      ChainGuard.Sampling.Pick_Segment (A, 100, 1, Start_A);
      Check (A = 16#54000020# and Start_A = 0, "xorshift known answer");
   end Sampling_Tests;
begin
   Vector ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "empty");
   Vector ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "abc");
   Vector ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
           "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1", "448-bit");
   declare
      Chunk : constant Byte_Array (0 .. 999) := (others => Character'Pos ('a'));
      C : ChainGuard.SHA256.Context;
      Million : constant Byte_Array (1 .. 1_000_000) := (others => Character'Pos ('a'));
   begin
      ChainGuard.SHA256.Initialize (C);
      for I in 1 .. 1_000 loop
         ChainGuard.SHA256.Update (C, Chunk);
      end loop;
      Check (Hex (ChainGuard.SHA256.Finish (C)) =
             "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0", "million a");
      Check (Hex (ChainGuard.SHA256.Digest (Million)) =
             "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0", "million a one-shot");
   end;
   Chain_Tests (1);
   Chain_Tests (2);
   Chain_Tests (100);
   Chain_Tests (Max_Capacity);
   Tamper_Tests;
   Sampling_Tests;
   if Failures = 0 then
      Ada.Text_IO.Put_Line ("PASS: all tests");
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Test_Runner;
