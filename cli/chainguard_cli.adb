with Ada.Command_Line; use Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Streams; use Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Interfaces;
with ChainGuard.Types; use ChainGuard.Types;
with ChainGuard.SHA256;
with ChainGuard.Chain;
with ChainGuard.Verify;
with ChainGuard.Sampling;
procedure ChainGuard_CLI with SPARK_Mode => Off is
   use type Word64;
   use type Byte;
   use type Ada.Streams.Stream_IO.Count;
   package SIO renames Ada.Streams.Stream_IO;
   C : ChainGuard.Chain.Chain;
   Magic : constant String := "CGUARD01";
   Usage_Error : exception;

   procedure Usage is
   begin
      Ada.Text_IO.Put_Line ("chainguard build <manifest.txt> -o <chain.bin>");
      Ada.Text_IO.Put_Line ("chainguard verify <chain.bin>");
      Ada.Text_IO.Put_Line ("chainguard sample <chain.bin> --count <n> --seed <n> [--length <n>]");
      Ada.Text_IO.Put_Line ("chainguard tamper <chain.bin> --block <n> -o <bad.bin>");
   end Usage;

   function Number (Text : String) return Word64 is
      Value : Word64 := 0;
      Digit : Word64;
   begin
      if Text'Length = 0 then
         raise Usage_Error with "empty number";
      end if;
      for Ch of Text loop
         if Ch not in '0' .. '9' then
            raise Usage_Error with "expected an unsigned decimal integer";
         end if;
         Digit := Word64 (Character'Pos (Ch) - Character'Pos ('0'));
         if Value > (Word64'Last - Digit) / 10 then
            raise Usage_Error with "integer too large";
         end if;
         Value := Value * 10 + Digit;
      end loop;
      return Value;
   end Number;

   function Image (Value : Natural) return String is
     (Ada.Strings.Fixed.Trim (Natural'Image (Value), Both));

   procedure Put_Number
     (Data : in out Stream_Element_Array; First : Stream_Element_Offset;
      Width : Positive; Value : Word64)
   is
   begin
      for I in 0 .. Width - 1 loop
         Data (First + Stream_Element_Offset (I)) := Stream_Element
           (Interfaces.Shift_Right (Value, 8 * (Width - I - 1)) and 16#ff#);
      end loop;
   end Put_Number;

   function Get_Number
     (Data : Stream_Element_Array; First : Stream_Element_Offset;
      Width : Positive) return Word64
   is
      Value : Word64 := 0;
   begin
      for I in 0 .. Width - 1 loop
         Value := Interfaces.Shift_Left (Value, 8)
           or Word64 (Data (First + Stream_Element_Offset (I)));
      end loop;
      return Value;
   end Get_Number;

   procedure Read_Exact (F : SIO.File_Type; Data : out Stream_Element_Array) is
      Last : Stream_Element_Offset;
   begin
      SIO.Read (F, Data, Last);
      if Last /= Data'Last then
         raise Ada.Text_IO.Data_Error with "truncated chain";
      end if;
   end Read_Exact;

   procedure Load (Path : String; Result : out ChainGuard.Chain.Chain) is
      F : SIO.File_Type;
      Header : Stream_Element_Array (1 .. 12);
      Record_Data : Stream_Element_Array (1 .. 104);
      Length : Word64;
   begin
      Result.Length := 0;
      SIO.Open (F, SIO.In_File, Path);
      Read_Exact (F, Header);
      for I in Magic'Range loop
         if Header (Stream_Element_Offset (I)) /= Character'Pos (Magic (I)) then
            raise Ada.Text_IO.Data_Error with "bad chain magic";
         end if;
      end loop;
      Length := Get_Number (Header, 9, 4);
      if Length > Word64 (Result.Capacity) then
         raise Ada.Text_IO.Data_Error with "chain exceeds capacity";
      end if;
      if SIO.Size (F) /= SIO.Count (12 + Length * 104) then
         raise Ada.Text_IO.Data_Error with "incorrect chain file size";
      end if;
      Result.Length := Block_Count (Length);
      for I in 1 .. Result.Length loop
         Read_Exact (F, Record_Data);
         Result.Blocks (I).Index := Get_Number (Record_Data, 1, 8);
         for J in 0 .. 31 loop
            Result.Blocks (I).Prev_Hash (J) := Byte (Record_Data (9 + Stream_Element_Offset (J)));
            Result.Blocks (I).Payload_Hash (J) := Byte (Record_Data (41 + Stream_Element_Offset (J)));
            Result.Blocks (I).Block_Hash (J) := Byte (Record_Data (73 + Stream_Element_Offset (J)));
         end loop;
      end loop;
      SIO.Close (F);
   exception
      when others =>
         if SIO.Is_Open (F) then SIO.Close (F); end if;
         raise;
   end Load;

   procedure Save (Path : String; Value : ChainGuard.Chain.Chain) is
      F : SIO.File_Type;
      Header : Stream_Element_Array (1 .. 12);
      Record_Data : Stream_Element_Array (1 .. 104);
   begin
      for I in Magic'Range loop
         Header (Stream_Element_Offset (I)) := Character'Pos (Magic (I));
      end loop;
      Put_Number (Header, 9, 4, Word64 (Value.Length));
      SIO.Create (F, SIO.Out_File, Path);
      SIO.Write (F, Header);
      for I in 1 .. Value.Length loop
         Put_Number (Record_Data, 1, 8, Value.Blocks (I).Index);
         for J in 0 .. 31 loop
            Record_Data (9 + Stream_Element_Offset (J)) := Stream_Element (Value.Blocks (I).Prev_Hash (J));
            Record_Data (41 + Stream_Element_Offset (J)) := Stream_Element (Value.Blocks (I).Payload_Hash (J));
            Record_Data (73 + Stream_Element_Offset (J)) := Stream_Element (Value.Blocks (I).Block_Hash (J));
         end loop;
         SIO.Write (F, Record_Data);
      end loop;
      SIO.Close (F);
   exception
      when others =>
         if SIO.Is_Open (F) then SIO.Close (F); end if;
         raise;
   end Save;

   function Hash_File (Path : String) return Hash is
      F : SIO.File_Type;
      Data : Stream_Element_Array (1 .. 8192);
      Bytes : Byte_Array (1 .. 8192);
      Last : Stream_Element_Offset;
      Context : ChainGuard.SHA256.Context;
   begin
      ChainGuard.SHA256.Initialize (Context);
      SIO.Open (F, SIO.In_File, Path);
      while not SIO.End_Of_File (F) loop
         SIO.Read (F, Data, Last);
         if Word64 (Last) > ChainGuard.SHA256.Max_Message_Bytes -
           ChainGuard.SHA256.Bytes_Processed (Context)
         then
            raise Ada.Text_IO.Data_Error with "file too large for SHA-256";
         end if;
         for I in 1 .. Natural (Last) loop
            Bytes (I) := Byte (Data (Stream_Element_Offset (I)));
         end loop;
         ChainGuard.SHA256.Update (Context, Bytes (1 .. Natural (Last)));
      end loop;
      SIO.Close (F);
      return ChainGuard.SHA256.Finish (Context);
   exception
      when others =>
         if SIO.Is_Open (F) then SIO.Close (F); end if;
         raise;
   end Hash_File;

   procedure Build (Manifest : String) is
      F : Ada.Text_IO.File_Type;
      Line : Ada.Strings.Unbounded.Unbounded_String;
      Base : constant String := Ada.Directories.Containing_Directory
        (Ada.Directories.Full_Name (Manifest));
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Manifest);
      loop
         begin
            Line := Ada.Strings.Unbounded.To_Unbounded_String (Ada.Text_IO.Get_Line (F));
         exception
            when Ada.Text_IO.End_Error => exit;
         end;
         declare
            Path : constant String := Ada.Strings.Fixed.Trim
              (Ada.Strings.Unbounded.To_String (Line), Both);
         begin
            if Path'Length = 0 then
               raise Ada.Text_IO.Data_Error with "empty manifest line";
            end if;
            if C.Length = C.Capacity then
               raise Ada.Text_IO.Data_Error with "manifest exceeds capacity";
            end if;
            if Path (Path'First) = '\' or else Path (Path'First) = '/'
              or else (Path'Length >= 2 and then Path (Path'First + 1) = ':')
            then
               ChainGuard.Chain.Append (C, Hash_File (Path));
            else
               ChainGuard.Chain.Append (C, Hash_File (Base & "\" & Path));
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (F);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then Ada.Text_IO.Close (F); end if;
         raise;
   end Build;

   procedure Sample is
      Count : constant Word64 := Number (Argument (4));
      State : Word64 := Number (Argument (6));
      Size : Block_Count := Natural'Min (8, C.Length);
      Start : Block_Count;
      Valid : Boolean;
   begin
      if Count = 0 or Count > 1_000_000 or C.Length = 0 then
         raise Usage_Error with "sampling needs a nonempty chain and count 1..1000000";
      end if;
      if Argument_Count = 8 then
         if Argument (7) /= "--length" then raise Usage_Error; end if;
         declare
            Value : constant Word64 := Number (Argument (8));
         begin
            if Value = 0 or Value > Word64 (C.Length) then
               raise Usage_Error with "segment length outside chain";
            end if;
            Size := Block_Count (Value);
         end;
      end if;
      for I in 1 .. Natural (Count) loop
         ChainGuard.Sampling.Pick_Segment (State, C.Length, Size, Start);
         Valid := ChainGuard.Verify.Verify_Segment (C, Start, Size);
         Ada.Text_IO.Put_Line ("sample start=" & Image (Start) & " count=" & Image (Size)
           & (if Valid then " valid" else " invalid"));
         if not Valid then Set_Exit_Status (1); end if;
      end loop;
   end Sample;
begin
   if Argument_Count = 4 and then Argument (1) = "build" and then Argument (3) = "-o" then
      Build (Argument (2));
      Save (Argument (4), C);
      Ada.Text_IO.Put_Line ("built " & Image (C.Length) & " blocks");
   elsif Argument_Count = 2 and then Argument (1) = "verify" then
      Load (Argument (2), C);
      if ChainGuard.Verify.Verify_Chain (C) then
         Ada.Text_IO.Put_Line ("valid");
      else
         Ada.Text_IO.Put_Line ("invalid");
         Set_Exit_Status (1);
      end if;
   elsif (Argument_Count = 6 or Argument_Count = 8) and then Argument (1) = "sample"
     and then Argument (3) = "--count" and then Argument (5) = "--seed"
   then
      Load (Argument (2), C);
      Sample;
   elsif Argument_Count = 6 and then Argument (1) = "tamper"
     and then Argument (3) = "--block" and then Argument (5) = "-o"
   then
      Load (Argument (2), C);
      declare
         Position : constant Word64 := Number (Argument (4));
      begin
         if Position >= Word64 (C.Length) then
            raise Usage_Error with "block outside chain";
         end if;
         C.Blocks (Natural (Position) + 1).Payload_Hash (0) :=
           C.Blocks (Natural (Position) + 1).Payload_Hash (0) xor 1;
      end;
      Save (Argument (6), C);
      Ada.Text_IO.Put_Line ("tampered");
   else
      Usage;
      raise Usage_Error with "invalid arguments";
   end if;
exception
   when Error : others =>
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Ada.Exceptions.Exception_Message (Error));
      Set_Exit_Status (2);
end ChainGuard_CLI;
