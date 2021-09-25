unit testsetspeed;

{ this unit provides utilities to benchmark sets; it inserts words
  from /usr/share/dict/words and measures running times of functions;
  writes output to to the log stream }

interface

uses
   SysUtils, Classes, adtcont, adtlog, adtfunct, adthashfunct, adtdarray, cpu_timer;

procedure BenchmarkSet(aset : TStringSetAdt; className : String);
   
implementation

var
   lastByte : Byte;
   lastByteLeft : Boolean;

function ReadToken(strm : TStream) : String;
begin
   Result := '';
   if not lastByteLeft then
      lastByte := strm.ReadByte;
   while Char(lastByte) in [' ', #13, #10] do
      lastByte := strm.ReadByte;
   while not (Char(lastByte) in [' ', #13, #10]) do
   begin
      Result := Result + Char(lastByte);
      lastByte := strm.ReadByte;
   end;
   while (Char(lastByte) in [' ', #13, #10]) and not (strm.Position >= strm.Size) do
      lastByte := strm.ReadByte;
   lastByteLeft := true;
end;

procedure BenchmarkSet(aset : TStringSetAdt; className : String);
var
   dict : TFileStream;
   ln : String;
   timeInsert, timeSearchFound, timeSearchNotFound, timeDelete : TZenTimer;
   words : TStringDynamicArray;
   i, maxi : IndexType;
   
begin
   WriteLn('Benchmarking ', className, '...');
   dict := TFileStream.Create('/usr/share/dict/words', fmOpenRead);
   lastByteLeft := false;
   
   WriteLogStream('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
   WriteLogStream('Benchmark for ' + className);

   timeInsert := TZenTimer.Create;
   timeSearchFound := TZenTimer.Create;
   timeSearchNotFound := TZenTimer.Create;
   timeDelete := TZenTimer.Create;
   
   ArrayAllocate(words, 100000, 0);
   
   try
      aset.Clear;
      aset.RepeatedItems := true;
   
      repeat
         ln := ReadToken(dict);
         for i := 1 to 2 do
            ArrayPushBack(words, ln);
      until dict.Position >= dict.Size;
      
      maxi := words^.Size - 1;
      
      timeInsert.Start;
      for i := 0 to maxi do
      begin
         aset.Insert(words^.Items[i]);
      end;
      timeInsert.Stop;
      
{$ifdef TEST_PASCAL_ADT }      
      if className <> 'TString23Tree' then
         aset.LogStatus('BenchmarkSet (after inserting all items)');
{$endif }
      
      timeSearchFound.Start;
      for i := 0 to maxi do
      begin
         aset.Has(words^.Items[i]);
      end;
      timeSearchFound.Stop; 
      
      ln := 'AAAAAAAAAAXXXXXXXXXX';
      timeSearchNotFound.Start;
      for i := 0 to maxi do
      begin
         aset.Has(ln);
         
         Inc(ln[(i mod 20) + 1]);
      end;
      timeSearchNotFound.Stop; 
      
      timeDelete.Start;
      for i := 0 to maxi div 2 do
      begin
         aset.Delete(words^.Items[i]);
      end;
      timeDelete.Stop; 
      
{$ifdef TEST_PASCAL_ADT }      
      if className <> 'TString23Tree' then
         aset.LogStatus('BenchmarkSet (after deleting half of the items)');
{$endif }      
      
      timeSearchFound.Start;
      for i := maxi div 2 + 1 to maxi do
      begin
         aset.Has(words^.Items[i]);
      end;
      timeSearchFound.Stop; 
      
      timeDelete.Start;
      for i := maxi div 2 + 1 to maxi do
      begin
         aset.Delete(words^.Items[i]);
      end;
      timeDelete.Stop; 
            
      ln := 'AAAAAAAAAAXXXXXXXXXX';
      timeSearchNotFound.Start;
      for i := maxi div 2 + 1 to maxi do
      begin
         aset.Has(ln);
         
         Inc(ln[(i mod 20) + 1]);
      end;
      timeSearchNotFound.Stop; 
      
      WriteLogStream('');
      WriteLogStream('*******************************************');
      WriteLogStream('Benchmark for ' + className + ' results:');
      WriteLogStream('Total number of words inserted: ' +
                        IntToStr(words^.Size));
      WriteLogStream('Total time for Insert (microsecs): ' + IntToStr(timeInsert.Time));
      WriteLogStream('Total time for Has (searching existing item, *1.5, microsecs): ' +
                        IntToStr(timeSearchFound.Time));
      WriteLogStream('Total time for Has (searching non-existing item, *1.5, microsecs): '
                     + IntToStr(timeSearchNotFound.Time));
      WriteLogStream('Total time for Delete (microsecs): ' + IntToStr(timeDelete.Time));
      WriteLogStream('Time per item for Insert (microsecs): ' +
                        FloatToStr(Double(timeInsert.Time) / words^.Size));
      WriteLogStream('Time per item for Has (existing, microsecs): ' +
                        FloatToStr(Double(timeSearchFound.Time) / (words^.Size * 1.5)));
      WriteLogStream('Time per item for Has (non-existing, microsecs): ' +
                        FloatToStr(Double(timeSearchNotFound.Time) /
                                      (words^.Size * 1.5)));
      WriteLogStream('Time per item for Delete (microsecs): ' +
                        FloatToStr(Double(timeDelete.Time) / words^.Size));
      WriteLogStream('');
      WriteLogStream('End Of Benchmark');
      WriteLogStream('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
      
   finally
      ArrayDeallocate(words);
      timeInsert.Free;
      timeDelete.Free;
      timeSearchFound.Free;
      timeSearchNotFound.Free;
      dict.Free;
   end;
end;

end.
