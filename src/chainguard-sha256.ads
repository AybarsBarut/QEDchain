with ChainGuard.Types; use ChainGuard.Types;
package ChainGuard.SHA256 with SPARK_Mode => On is
   use type Word64;
   Max_Message_Bytes : constant Word64 := 2 ** 61 - 1;
   type Context is private;
   function Bytes_Processed (C : Context) return Word64;
   procedure Initialize (C : out Context)
     with Post => Bytes_Processed (C) = 0;
   procedure Update (C : in out Context; Data : Byte_Array)
     with Pre => Word64 (Data'Length) <= Max_Message_Bytes - Bytes_Processed (C),
          Post => Bytes_Processed (C) = Bytes_Processed (C)'Old + Word64 (Data'Length);
   function Finish (C : Context) return Hash;
   function Digest (Data : Byte_Array) return Hash;
private
   type State_Words is array (Natural range 0 .. 7) of Word32;
   Initial : constant State_Words :=
     (16#6a09e667#, 16#bb67ae85#, 16#3c6ef372#, 16#a54ff53a#,
      16#510e527f#, 16#9b05688c#, 16#1f83d9ab#, 16#5be0cd19#);
   subtype Buffer_Type is Byte_Array (0 .. 63);
   type Context is record
      H : State_Words := Initial;
      Buffer_Data : Buffer_Type := (others => 0);
      Used : Natural range 0 .. 63 := 0;
      Total : Word64 range 0 .. Max_Message_Bytes := 0;
   end record;
   function Bytes_Processed (C : Context) return Word64 is (C.Total);
end ChainGuard.SHA256;
