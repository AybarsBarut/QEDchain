with ChainGuard.Types; use ChainGuard.Types;
package ChainGuard.Sampling with SPARK_Mode => On is
   use type Word64;
   -- Deterministic xorshift64*. Zero is normalized to a fixed nonzero seed.
   -- This generator is not suitable for adversary-unpredictable challenges.
   function Next_State (State : Word64) return Word64;
   function Output (State : Word64) return Word64 is (State * 16#2545f4914f6cdd1d#);
   procedure Pick_Segment
     (State : in out Word64; Chain_Length, Segment_Len : Block_Count;
      Start : out Block_Count)
     with Pre => Segment_Len > 0 and then Segment_Len <= Chain_Length,
          Post => Start <= Chain_Length - Segment_Len
            and then State = Next_State (State'Old)
            and then Word64 (Start) =
              Output (State) mod Word64 (Chain_Length - Segment_Len + 1);
end ChainGuard.Sampling;
