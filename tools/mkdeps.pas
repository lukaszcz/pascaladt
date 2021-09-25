program mkdeps;

uses
   SysUtils;

var
   f : file of char;
   leftChar : Char;
   wasLeftChar : Boolean;

type
   TCharType = (ctWhitespace, ctAlnum, ctOther);

const
   TAB = #9;

function CharType(c : Char) : TCharType;
begin
   if c in [' ', #13, #10, TAB] then
      Result := ctWhitespace
   else if (c in ['a'..'z']) or (c in ['A'..'Z']) or (c in ['0'..'9']) then
   begin
      Result := ctAlnum;
   end else
      Result := ctOther;
end;

function IsWhitespace(c : Char) : Boolean;
begin
   Result := CharType(c) = ctWhitespace;
end;

function ReadToken : String;
var
   c : Char;
   ct : TCharType;
begin
   Result := '';

   if wasLeftChar then
      c := leftChar
   else
      Read(f, c);

   while IsWhitespace(c) and not Eof(f) do
   begin
      Read(f, c);
   end;

   ct := CharType(c);
   while (CharType(c) = ct) and not Eof(F) do
   begin
      Result := Result + c;
      Read(f, c);
   end;

   if (Result <> '') and (Result[1] = '{') then
   begin
      while (c <> '}') and not Eof(f) do
      begin
         Read(f, c);
      end;
      wasLeftChar := false;
      Result := ReadToken();
   end else if Result = '(*' then
   begin
      while not Eof(f) do
      begin
         Read(f, c);
         if (c = '*') and not Eof(f) then
         begin
            Read(f, c);
            if c = ')' then
               break;
         end;
      end;
      wasLeftChar := false;
      Result := ReadToken();
   end else
   begin
      wasLeftChar := true;
      leftChar := c;
   end;
   Result := LowerCase(Result);
end;

function CutExt(str : String) : String;
var
   i : Integer;
begin
   Result := str;
   for i := Length(Result) downto 1 do
   begin
      if Result[i] = '.' then
         break;
   end;
   SetLength(Result, i - 1);
end;

procedure OpenFile(str : String);
begin
   wasLeftChar := false;
   Assign(f, str);
   Reset(f);
end;

procedure CloseFile;
begin
   Close(f);
end;

var
   token, str : String;
   i, j, k, kk : Integer;
   deps : array[1..1000] of String;
   testunits_deps : array[1..100] of String;
   is_mcp, is_program : Boolean;
   dependsOnCpuTimer : Boolean;

   procedure AddTestutilsDeps;
   begin
      deps[k] := 'adtiters';
      Inc(k);
      deps[k] := 'adtfunct';
      Inc(k);
      deps[k] := 'adthashfunct';
      Inc(k);
   end;

   procedure ReadDeps;
   begin
      k := 1;
      kk := 1;

      dependsOnCpuTimer := false;
      for i := 0 to 1 do
      begin
         while not Eof(f) and (ReadToken <> 'uses') do
            ;

         while not Eof(f) do
         begin
            token := ReadToken;
            if FileExists(token + '.pas.mcp') then
            begin
               deps[k] := token;
               Inc(k);
            end else if Copy(token, 1, 4) = 'test' then
            begin
               testunits_deps[kk] := token;
               Inc(kk);
{               if token = 'testutils' then
               begin
                  AddTestutilsDeps;
               end;}
            end else if token = 'cpu_timer.pas' then
            begin
               dependsOnCpuTimer := true;
            end;

            if not Eof(f) then
            begin
               if ReadToken = ';' then
                  break;
            end;
         end;
      end; { end for }
   end; { end procedure ReadDeps }

begin
   { this is needed because of circular dependencies between adtiters
     and adtcont - adding dependencies of adtcont to adtiters at the
     very beginning seems to alleviate the problem (at least with GNU
     make) }
   for j := 1 to ParamCount do
   begin
      if ParamStr(j) = 'adtcont.pas.mcp' then
      begin
         OpenFile(ParamStr(j));
         ReadDeps;

         Write('adtiters$(obj_suffix) : ');
         for i := 1 to k - 1 do
         begin
            Write(deps[i], '$(obj_suffix) ');
         end;
         CloseFile;
      end;
   end;

   for j := 1 to ParamCount do
   begin
      OpenFile(ParamStr(j));
      if ReadToken = 'program' then
         is_program := true
      else
         is_program := false;

      ReadDeps;

      if ExtractFileExt(ParamStr(j)) = '.mcp' then
         is_mcp := true
      else
         is_mcp := false;
      if is_mcp then
         str := CutExt(CutExt(ParamStr(j)))
      else
         str := CutExt(ParamStr(j));
      WriteLn;
      Write(str);
      if is_program then
         Write('$(prog_suffix) : ')
      else
         Write('$(obj_suffix) : ');
      Write(str, '.pas ');
      for i := 1 to k - 1 do
      begin
         Write(deps[i], '$(obj_suffix) ');
      end;
      for i := 1 to kk - 1 do
      begin
         Write('tests/units/', testunits_deps[i], '$(obj_suffix) ');
      end;
      if dependsOnCpuTimer then
         Write('tests/units/cpu/cpu_timer$(obj_suffix)');
      WriteLn;

      if is_mcp then
      begin
         { dependencies for the *.pas file  }
         Write(str, '.pas : ', str, '.pas.mcp adtdefs.inc ');
         if FileExists(str + '.i') or FileExists(str + '_impl.i') then
         begin
            Write(str, '.defs ');
         end;
         if FileExists(str + '.i') then
         begin
            Write(str, '.mcp ');
         end;
         if FileExists(str + '_impl.i') then
         begin
            Write(str, '_impl.mcp ');
         end;
         if FileExists(str + '.mac') then
         begin
            Write(str, '.mac ');
         end;
         if FileExists(str + '_impl.mac') then
         begin
            Write(str, '_impl.mac ');
         end;
         WriteLn;

         if FileExists(str + '.i') or FileExists(str + '_impl.i') then
         begin
            { dependencies for the *.defs file  }
            WriteLn;
            Write(str, '.defs : ');
            if FileExists(str + '.mac') then
            begin
               Write(str, '.mac ');
            end;
            if FileExists(str + '_impl.mac') then
            begin
               Write(str, '_impl.mac ');
            end;
            for i := 1 to k - 1 do
            begin
               if FileExists(deps[i] + '.i') then
               begin
                  Write(deps[i], '.mcp ');
               end;
               if FileExists(deps[i] + '.mac') then
               begin
                  Write(deps[i], '.mac ');
               end;
            end;
            WriteLn;
            Write(TAB, 'echo "&include ', str, '.mcp\n');
            for i := 1 to k - 1 do
            begin
               if FileExists(deps[i] + '.i') then
               begin
                  Write('&include ', deps[i], '.mcp\n');
               end;
               if FileExists(deps[i] + '.mac') then
               begin
                  Write('&include ', deps[i], '.mac\n');
               end;
            end;
            WriteLn('" > ', str, '.defs');
         end; { end if should generate the *.defs file }
      end; { end if is_mcp }

      CloseFile;
   end;
end.
