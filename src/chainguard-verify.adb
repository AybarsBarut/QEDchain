package body ChainGuard.Verify with SPARK_Mode => On is
   function Verify_Segment (C : ChainGuard.Chain.Chain; Start, Count : Block_Count)
     return Boolean
   is
   begin
      if Count = 0 then
         return True;
      end if;
      if Start = 0 then
         if not Genesis_Valid (C.Blocks (1)) then
            return False;
         end if;
      elsif not Block_Valid (C.Blocks (Start + 1)) then
         return False;
      end if;
      for K in 1 .. Count - 1 loop
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 =>
              Link_Valid (C.Blocks (Start + J), C.Blocks (Start + J + 1)));
         if not Verify_Link (C.Blocks (Start + K), C.Blocks (Start + K + 1)) then
            return False;
         end if;
      end loop;
      return True;
   end Verify_Segment;

   function Verify_Chain (C : ChainGuard.Chain.Chain) return Boolean is
   begin
      if C.Length > C.Capacity then
         return False;
      end if;
      return Verify_Segment (C, 0, C.Length);
   end Verify_Chain;
end ChainGuard.Verify;
