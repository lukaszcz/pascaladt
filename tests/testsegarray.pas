program testsegarray;

{$C+}

uses
   testutils, SysUtils, adtsegarray, adtdarray, adtfunct;


procedure DestroyObjectProc(ptr : TObject);
begin
   TTestObject(ptr).Free;
end;

procedure TestTSegArray;
var
   sa : TSegArray;
   i : IndexType;
   lastSize, lastSegsSize : SizeType;
   obj : TTestObject;

   procedure TestGetSetItem(low, high, start : IndexType);
   var
      ii : IndexType;
   begin
      StartSilentMode;
      for ii := low to high do
      begin
         if ii = high then
            StopSilentMode;

         obj := TTestObject(SegArrayGetItem(sa, ii));
         Test(obj.Value = ii + start, 'SegArrayGetItem',
              'returns wrong item; failed in ' + IntToStr(ii - low+1) + 'th try');
         obj := TTestObject(SegArraySetItem(sa, ii, TTestObject.Create(777)));
         Test(obj.Value = ii + start, 'SegArraySetItem',
              'returns wrong item; failed in ' + IntToStr(ii - low+1) + 'th try');
         Test(TTestObject(SegArrayGetItem(sa, ii)).Value = 777, 'SegArrayGetItem',
              'sets wrong item; failed in ' + IntToStr(ii - low + 1) + 'th try');
         TTestObject(SegArraySetItem(sa, ii, obj)).Destroy;
         Inc(i);
      end;
   end;

begin
   StartTest('TSegArray');

   { ------------------- SegArrayAllocate ---------------------- }
   SegArrayAllocate(sa, 128, 64, saSegmentCapacity div 2);
   Test((sa^.Size = 0) and (sa^.Segments^.Capacity = 128) and
           (sa^.Segments^.Size = 1) and (sa^.FirstSegIndex = 64) and
           (sa^.InnerStartIndex = saSegmentCapacity div 2), 'SegArrayAllocate');

   { ------------------- SegArrayPushFront --------------------- }
   StartSilentMode;
   for i := 500 downto 0 do
   begin
      lastSize := sa^.Size;
      SegArrayPushFront(sa, TTestObject.Create(i));
      Test(sa^.Size = lastSize + 1, 'SegArrayPushFront',
           'wrong Size; failed in ' + IntToStr(501 - i) + 'th try');
      Test(TTestObject(TDynamicBuffer(
                          sa^.Segments^.Items[sa^.FirstSegIndex]
                                     )^.Items[sa^.InnerStartIndex]).Value = i,
           'SegArrayPushFront',
           'sets wrong item; failed in ' + IntToStr(501 - i) + 'th try');
   end;
   StopSilentMode;
   Test(sa^.Size = 501, 'SegArrayPushFront', 'wrong Size');

   { ------------- SegArrayGetItem + SegArraySetItem --------------------- }
   TestGetSetItem(0, 500, 0);

   { ------------------- SegArrayPopFront --------------------- }
   StartSilentMode;
   i := 0;
   while sa^.Size <> 0 do
   begin
      if sa^.Size = 1 then
         StopSilentMode;

      lastSize := sa^.Size;
      obj := TTestObject(SegArrayPopFront(sa));
      Test(obj.Value = i, 'SegArrayPopFront',
           'returns wrong item; failed in ' + IntToStr(i + 1) + 'th try');
      Test(sa^.Size = lastSize - 1, 'SegArrayPopFront',
           'wrong Size in ' + IntToStr(i + 1) + 'th try');
      obj.Destroy;
      Inc(i);
   end;

   { ------------------- SegArrayPushBack --------------------- }
   StartSilentMode;
   for i := 0 to 400 do
   begin
      lastSize := sa^.Size;
      SegArrayPushBack(sa, TTestObject.Create(i));
      Test(sa^.Size = lastSize + 1, 'SegArrayPushBack',
           'wrong Size; failed in ' + IntToStr(i + 1) + 'th try');
      Test(TTestObject(SegArrayGetItem(sa, i)).Value = i, 'SegArrayPushBack',
           'sets wrong item; failed in ' + IntToStr(i + 1) + 'th try');
   end;
   StopSilentMode;
   Test(sa^.Size = 401, 'SegArrayPushBack', 'wrong Size');

   { ------------- SegArrayGetItem + SegArraySetItem --------------------- }
   TestGetSetItem(0, 400, 0);

   { ------------------- SegArrayPopBack --------------------- }
   StartSilentMode;
   i := 400;
   while sa^.Size <> 200 do
   begin
      if sa^.Size = 201 then
         StopSilentMode;

      lastSize := sa^.Size;
      obj := TTestObject(SegArrayPopBack(sa));
      Test(obj.Value = i, 'SegArrayPopBack',
           'returns wrong item; failed in ' + IntToStr(401 - i) + 'th try');
      Test(sa^.Size = lastSize - 1, 'SegArrayPopBack',
           'wrong Size; failed in ' + IntToStr(401 - i) + 'th try');
      obj.Destroy;
      Dec(i);
   end;

   { ------------------- SegArrayReserveItems --------------------- }
   SegArrayReserveItems(sa, 100, 500);
   Test(sa^.Size = 700, 'SegArrayReserveItems', 'wrong Size');

   for i := 100 to 599 do
   begin
      SegArraySetItem(sa, i, TTestObject.Create(i));
   end;

   { ------------- SegArrayGetItem + SegArraySetItem --------------------- }
   TestGetSetItem(0, 599, 0);
   TestGetSetItem(600, 699, -500);

   for i := 100 to 599 do
   begin
      TTestObject(SegArraySetItem(sa, i, nil)).Destroy;
   end;

   { ------------------- SegArrayRemoveItems --------------------- }
   SegArrayRemoveItems(sa, 100, 500);
   Test(sa^.Size = 200, 'SegArrayRemoveItems', 'wrong Size');

   { ------------- SegArrayGetItem + SegArraySetItem --------------------- }
   TestGetSetItem(0, 199, 0);

   { ---------------------- SegArrayExpandRight -------------------------- }
   SegArrayExpandRight(sa, 1000);
   Test(sa^.Size = 200, 'SegArrayExpandRight', 'wrong Size');
   lastSegsSize := sa^.Segments^.Size;

   TestGetSetItem(0, 199, 0);

   for i := 1 to 1000 do
   begin
      SegArrayPushBack(sa, TTestObject.Create(i));
   end;

   Test(sa^.Segments^.Size = lastSegsSize, 'SegArrayExpandRight',
        'not enough space preallocated');

   { ---------------------- SegArrayExpandLeft -------------------------- }
   SegArrayExpandLeft(sa, 1000);
   Test(sa^.Size = 1200, 'SegArrayExpandLeft', 'wrong Size');
   lastSegsSize := sa^.Segments^.Size;

   TestGetSetItem(0, 199, 0);

   for i := 1 to 1000 do
   begin
      SegArrayPushFront(sa, TTestObject.Create(i));
   end;

   Test(sa^.Segments^.Size = lastSegsSize, 'SegArrayExpandLeft',
        'not enough space preallocated');

   StartSilentMode;
   Test(sa^.Size = 2200, 'Sth''s wrong with SegArrayPushFront !');
   StopSilentMode;

   { ---------------------- SegArrayApplyFunctor ---------------------- }
   StartDestruction(sa^.Size, 'SegArrayApplyFunctor');
   SegArrayApplyFunctor(sa, Adapt(@DestroyObjectProc));
   FinishDestruction;

   { ---------------------- SegArrayClear ---------------------- }
   SegArrayClear(sa, 10);
   Test((sa^.Segments^.Capacity = 10) and (sa^.Size = 0), 'SegArrayClear');

   { ---------------------- SegArrayDeallocate ---------------------- }
   SegArrayDeallocate(sa);
   Test(sa = nil, 'SegArrayDeallocate', 'nil not assigned to argument');
   sa := nil;
   SegArrayDeallocate(sa);
   Test(true, 'SegArrayDeallocate - correct handling of nil arguments',
        'this message is never displayed, as we get access violation earlier');

   FinishTest;
end;

begin
   TestTSegArray;
end.
