unit testsetspeed;

{ this unit provides utilities to benchmark sets; it inserts words
  from /usr/share/dict/words and measures running times of functions;
  writes output to to the log stream }

interface

uses
   SysUtils, Classes, adtcont, adtlog, adtfunct, adthashfunct, adtdarray;

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
   dict    : TFileStream;
   ln      : String;
   tm, timeSearchFound, timeSearchNotFound, timeInsert, timeDelete : Comp;
   words   : TStringDynamicArray;
   i, maxi : IndexType;

begin
   WriteLn('Benchmarking ', className, '...');
   dict := TFileStream.Create('/usr/share/dict/words', fmOpenRead);
   lastByteLeft := false;

   WriteLogStream('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
   WriteLogStream('Benchmark for ' + className);

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

      timeInsert := TimeStampToMSecs(DateTimeToTimeStamp(Time));
      for i := 0 to maxi do
      begin
         aset.Insert(words^.Items[i]);
      end;
      timeInsert := TimeStampToMSecs(DateTimeToTimeStamp(Time)) - timeInsert;

      timeSearchFound := TimeStampToMSecs(DateTimeToTimeStamp(Time));
      for i := 0 to maxi do
      begin
         aset.Has(words^.Items[i]);
      end;
      timeSearchFound := TimeStampToMSecs(DateTimeToTimeStamp(Time)) - timeSearchFound;

      ln := 'AAAAAAAAAAXXXXXXXXXX';
      timeSearchNotFound := TimeStampToMSecs(DateTimeToTimeStamp(Time));
      for i := 0 to maxi do
      begin
         aset.Has(ln);

         Inc(ln[(i mod 20) + 1]);
      end;
      timeSearchNotFound := TimeStampToMSecs(DateTimeToTimeStamp(Time)) - timeSearchNotFound;

      timeDelete := TimeStampToMSecs(DateTimeToTimeStamp(Time));
      for i := 0 to maxi div 2 do
      begin
         aset.Delete(words^.Items[i]);
      end;
      timeDelete := TimeStampToMSecs(DateTimeToTimeStamp(Time)) - timeDelete;

      tm := TimeStampToMSecs(DateTimeToTimeStamp(Time));
      for i := maxi div 2 + 1 to maxi do
      begin
         aset.Has(words^.Items[i]);
      end;
      tm := TimeStampToMSecs(DateTimeToTimeStamp(Time)) - tm;
      timeSearchFound := timeSearchFound + tm;

      tm := TimeStampToMSecs(DateTimeToTimeStamp(Time));
      for i := maxi div 2 + 1 to maxi do
      begin
         aset.Delete(words^.Items[i]);
      end;
      tm := TimeStampToMSecs(DateTimeToTimeStamp(Time)) - tm;
      timeDelete := timeDelete + tm;

      ln := 'AAAAAAAAAAXXXXXXXXXX';
      tm := TimeStampToMSecs(DateTimeToTimeStamp(Time));
      for i := maxi div 2 + 1 to maxi do
      begin
         aset.Has(ln);

         Inc(ln[(i mod 20) + 1]);
      end;
      tm := TimeStampToMSecs(DateTimeToTimeStamp(Time)) - tm;
      timeSearchNotFound := timeSearchNotFound + tm;

      WriteLogStream('');
      WriteLogStream('*******************************************');
      WriteLogStream('Benchmark for ' + className + ' results:');
      WriteLogStream('Total number of words inserted: ' +
                        IntToStr(words^.Size));
      WriteLogStream('Total time for Insert (ms): ' + FloatToStr(timeInsert));
      WriteLogStream('Total time for Has (searching existing item, *1.5, ms): ' +
                        FloatToStr(timeSearchFound));
      WriteLogStream('Total time for Has (searching non-existing item, *1.5, ms): '
                     + FloatToStr(timeSearchNotFound));
      WriteLogStream('Total time for Delete (ms): ' + FloatToStr(timeDelete));
      WriteLogStream('Time per item for Insert (ms): ' +
                        FloatToStr(Double(timeInsert) / words^.Size));
      WriteLogStream('Time per item for Has (existing, ms): ' +
                        FloatToStr(Double(timeSearchFound) / (words^.Size * 1.5)));
      WriteLogStream('Time per item for Has (non-existing, ms): ' +
                        FloatToStr(Double(timeSearchNotFound) /
                                      (words^.Size * 1.5)));
      WriteLogStream('Time per item for Delete (ms): ' +
                        FloatToStr(Double(timeDelete) / words^.Size));
      WriteLogStream('');
      WriteLogStream('End Of Benchmark');
      WriteLogStream('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

   finally
      ArrayDeallocate(words);
      dict.Free;
   end;
end;

end.
