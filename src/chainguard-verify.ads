with ChainGuard.Types; use ChainGuard.Types;
with ChainGuard.Chain; use ChainGuard.Chain;
package ChainGuard.Verify with SPARK_Mode => On is
   function Verify_Link (Prev, Cur : Block) return Boolean is (Link_Valid (Prev, Cur))
     with Post => Verify_Link'Result = Link_Valid (Prev, Cur);
   -- A segment authenticates its first block's own hash, all internal links,
   -- and the genesis rule at position zero. No external anchor is implied.
   function Segment_Valid (C : ChainGuard.Chain.Chain; Start, Count : Block_Count)
     return Boolean is
       (Count = 0 or else
          ((if Start = 0 then Genesis_Valid (C.Blocks (1))
            else Block_Valid (C.Blocks (Start + 1))) and then
           (for all K in 1 .. Count - 1 =>
              Link_Valid (C.Blocks (Start + K), C.Blocks (Start + K + 1)))))
     with Ghost,
       Pre => C.Length <= C.Capacity and then Start <= C.Length
         and then Count <= C.Length - Start;
   function Verify_Segment (C : ChainGuard.Chain.Chain; Start, Count : Block_Count)
     return Boolean
     with Pre => C.Length <= C.Capacity and then Start <= C.Length
       and then Count <= C.Length - Start,
       Post => Verify_Segment'Result = Segment_Valid (C, Start, Count);
   function Verify_Chain (C : ChainGuard.Chain.Chain) return Boolean
     with Post => Verify_Chain'Result = Chain_Valid (C);
end ChainGuard.Verify;
