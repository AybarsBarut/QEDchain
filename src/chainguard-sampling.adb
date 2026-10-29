with Interfaces; use Interfaces;
package body ChainGuard.Sampling with SPARK_Mode => On is
   function Next_State (State : Word64) return Word64 is
      X : Word64 := (if State = 0 then 16#9e3779b97f4a7c15# else State);
   begin
      X := X xor Shift_Right (X, 12);
      X := X xor Shift_Left (X, 25);
      X := X xor Shift_Right (X, 27);
      return X;
   end Next_State;

   procedure Pick_Segment
     (State : in out Word64; Chain_Length, Segment_Len : Block_Count;
      Start : out Block_Count)
   is
      Windows : constant Positive := Chain_Length - Segment_Len + 1;
   begin
      State := Next_State (State);
      Start := Block_Count (Output (State) mod Word64 (Windows));
   end Pick_Segment;
end ChainGuard.Sampling;
