with Interfaces; use Interfaces;
with ChainGuard.SHA256;
package body ChainGuard.Chain with SPARK_Mode => On is
   function Compute_Block_Hash
     (Index : Word64; Prev_Hash, Payload_Hash : Hash) return Hash
   is
      Data : Byte_Array (0 .. 71) := (others => 0);
   begin
      for I in 0 .. 7 loop
         Data (I) := Byte (Shift_Right (Index, 8 * (7 - I)) and 16#ff#);
      end loop;
      Data (8 .. 39) := Prev_Hash;
      Data (40 .. 71) := Payload_Hash;
      return SHA256.Digest (Data);
   end Compute_Block_Hash;

   procedure Index_Lemma (C : Chain)
     with Ghost,
       Pre => Chain_Valid (C),
       Post => (for all J in 1 .. C.Length => C.Blocks (J).Index = Word64 (J - 1))
   is
   begin
      for J in 1 .. C.Length loop
         pragma Loop_Invariant
           (for all K in 1 .. J - 1 => C.Blocks (K).Index = Word64 (K - 1));
         if J > 1 then
            pragma Assert (Link_Valid (C.Blocks (J - 1), C.Blocks (J)));
         end if;
         pragma Assert (C.Blocks (J).Index = Word64 (J - 1));
      end loop;
   end Index_Lemma;

   procedure Append (C : in out Chain; Payload : Hash) is
      B : Block;
   begin
      Index_Lemma (C);
      B.Index := Word64 (C.Length);
      if C.Length > 0 then
         B.Prev_Hash := C.Blocks (C.Length).Block_Hash;
      end if;
      B.Payload_Hash := Payload;
      B.Block_Hash := Compute_Block_Hash (B.Index, B.Prev_Hash, Payload);
      C.Blocks (C.Length + 1) := B;
      C.Length := C.Length + 1;
   end Append;

   procedure Payload_Tamper_Lemma (Original, Changed : Block) is
   begin
      null;
   end Payload_Tamper_Lemma;
end ChainGuard.Chain;
