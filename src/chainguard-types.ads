with Interfaces;
package ChainGuard.Types with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   subtype Word32 is Interfaces.Unsigned_32;
   subtype Word64 is Interfaces.Unsigned_64;
   type Byte_Array is array (Natural range <>) of Byte;
   subtype Hash is Byte_Array (0 .. 31);
   Zero_Hash : constant Hash := (others => 0);
   Max_Capacity : constant := 65_536;
   subtype Capacity_Type is Positive range 1 .. Max_Capacity;
   subtype Block_Count is Natural range 0 .. Max_Capacity;
   subtype Block_Position is Natural range 0 .. Max_Capacity - 1;
end ChainGuard.Types;
