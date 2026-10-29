with ChainGuard.Types; use ChainGuard.Types;
package ChainGuard.Chain with SPARK_Mode => On is
   use type Word64;
   type Block is record
      Index : Word64 := 0;
      Prev_Hash : Hash := Zero_Hash;
      Payload_Hash : Hash := Zero_Hash;
      Block_Hash : Hash := Zero_Hash;
   end record;
   type Block_Array is array (Positive range <>) of Block;
   -- Storage is one-based; protocol positions and block indices are zero-based.
   type Chain (Capacity : Capacity_Type := Max_Capacity) is record
      Blocks : Block_Array (1 .. Capacity);
      Length : Block_Count := 0;
   end record;

   function Compute_Block_Hash
     (Index : Word64; Prev_Hash, Payload_Hash : Hash) return Hash
     with Global => null;
   function Block_Valid (B : Block) return Boolean is
     (B.Block_Hash = Compute_Block_Hash (B.Index, B.Prev_Hash, B.Payload_Hash));
   function Link_Valid (Prev, Cur : Block) return Boolean is
     (Prev.Index < Word64'Last and then Cur.Index = Prev.Index + 1
      and then Cur.Prev_Hash = Prev.Block_Hash and then Block_Valid (Cur));
   function Genesis_Valid (B : Block) return Boolean is
     (B.Index = 0 and then B.Prev_Hash = Zero_Hash and then Block_Valid (B));
   function Chain_Valid (C : Chain) return Boolean is
     (C.Length <= C.Capacity and then (C.Length = 0 or else
        (Genesis_Valid (C.Blocks (1)) and then
         (for all J in 2 .. C.Length => Link_Valid (C.Blocks (J - 1), C.Blocks (J))))))
     with Ghost;

   procedure Append (C : in out Chain; Payload : Hash)
     with Pre => C.Length < C.Capacity and then Chain_Valid (C),
          Post => C.Length = C.Length'Old + 1 and then Chain_Valid (C)
            and then (for all J in 1 .. C.Length'Old => C.Blocks (J) = C.Blocks'Old (J));

   -- Conditional theorem: the distinct computed hashes premise is the exact
   -- per-message cryptographic assumption. It is never introduced as an axiom.
   procedure Payload_Tamper_Lemma (Original, Changed : Block)
     with Ghost,
       Pre => Block_Valid (Original)
         and then Changed.Index = Original.Index
         and then Changed.Prev_Hash = Original.Prev_Hash
         and then Changed.Block_Hash = Original.Block_Hash
         and then Changed.Payload_Hash /= Original.Payload_Hash
         and then Compute_Block_Hash (Changed.Index, Changed.Prev_Hash, Changed.Payload_Hash)
           /= Compute_Block_Hash (Original.Index, Original.Prev_Hash, Original.Payload_Hash),
       Post => not Block_Valid (Changed);
end ChainGuard.Chain;
