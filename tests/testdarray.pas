program testdarray;

{$C+}

uses
   testutils, SysUtils, adtdarray, adtfunct;

procedure DestroyObjectProc(elem : TObject);
begin
   TObject(elem).Destroy;
end;

procedure TestDynamicArray;
var
   da, da2 : TDynamicArray;
   lastSize, lastStart, lastCapacity : SizeType;
   i : IndexType;
   obj : TTestObject;
begin
   StartTest('TDynamicArray (linear)');
   
   { ---------------- Test: ArrayAllocate -------------------- }
   da := nil;
   ArrayAllocate(da, 100, 10);
   Test((da <> nil) and (da^.Capacity = 100) and (da^.StartIndex = 10) and
           (da^.Size = 0), 'proper allocation & initialization');
   
   
   { ---------------- Test: ArrayReserveItems -------------------- }
   ArrayReserveItems(da, 0, 200);
   Test((da <> nil) and (da^.Size = 200) and (da^.StartIndex = 10),
        'ArrayReserveItems (with expansion)');
   
   WriteLn('Array capacity = ', da^.capacity);
     
   for i := da^.StartIndex to da^.StartIndex + da^.Size - 1 do
      da^.Items[i] := TTestObject.Create(i - da^.StartIndex);
   
   
   { ---------------- Test: ArrayGetItem -------------------- }   
   Test(TTestObject(ArrayGetItem(da, 0)).Value = 0, 'ArrayGetItem');
   
   { ---------------- Test: ArraySetItem -------------------- }   
   obj := TTestObject(ArraySetItem(da, 55, TTestObject.Create(500)));
   Test(obj.Value = 55, 'ArraySetItem', 'returns wrong element');
   Test(TTestObject(da^.Items[da^.StartIndex + 55]).Value = 500, 'ArraySetItem',
        'sets wrong item');
   obj.Free;
   
   { ---------------- Test: ArrayPushFront (no move) -------------------- }   
   ArrayPushFront(da, TTestObject.Create(-1), false);
   Test((da^.StartIndex = 9) and (da^.Size = 201) and
           (TTestObject(da^.Items[da^.StartIndex]).Value = -1),
        'ArrayPushFront (no move)');
   
   StartDestruction(49, 'by hand destruction');
   for i := da^.StartIndex + 51 to da^.StartIndex + 99 do
   begin
      TTestObject(da^.Items[i]).Destroy;
      da^.Items[i] := nil;
   end;
   FinishDestruction;
   WriteLn('49 items removed');
   
   { ---------------- Test: ArrayRemoveItems -------------------- }
   ArrayRemoveItems(da, 51, 49);
   Test((da^.Size = 152) and (da^.StartIndex = 9),'ArrayRemoveItems',
        'wrong StartIndex or Count');
   Test((TTestObject(da^.Items[da^.StartIndex + 51]).Value = 99),
        'ArrayRemoveItems', 'wrong order of items');
   StartSilentMode;
   for i := da^.StartIndex + 52 to da^.StartIndex + da^.Size - 1 do
   begin
      if i = da^.StartIndex + da^.Size - 1 then
         StopSilentMode;
      Test(TTestObject(da^.items[i]).Value = TTestObject(da^.items[i-1]).Value + 1,
           'ArrayRemoveItems', 'wrong order of elements');
   end;
   
   { ---------------- Test: ArrayPushBack -------------------- }
   StartSilentMode;
   for i := 200 to 300 do
   begin
      lastSize := da^.Size;
      if i = 300 then
         StopSilentMode;
      ArrayPushBack(da, TTestObject.Create(i));
      Test((da^.Size = lastSize + 1) and
              (TTestObject(da^.Items[da^.StartIndex + da^.Size - 1]).Value = i),
           'ArrayPushBack', 'failed in ' + IntToStr(i - 199) + 'th try');
   end;
   Test((da^.Size = 253) and (da^.StartIndex = 9), 'ArrayPushBack');
   
   WriteLn('Array capacity = ', da^.capacity);
   
   { ---------------- Test: ArrayPopFront (no move) -------------------- }      
   StartSilentMode;
   for i := 1 to 51 do
   begin
      lastSize := da^.Size;
      obj := TTestObject(ArrayPopFront(da, false));
      Test(obj.Value = i - 2, 'ArrayPopFront (no move)',
           'returns wrong element; failed in ' + IntToStr(i) + 'th try');
      Test(da^.Size = lastSize - 1, 'ArrayPopFront (no move)',
           'wrong Count; failed in ' + IntToStr(i) + 'th try');
      obj.Free;
   end;
   StopSilentMode;
   Test(da^.Size = 202, 'ArrayPopFront (no move)', 'wrong Count');
   Test(da^.StartIndex = 60, 'ArrayPopFront (no move)', 'wrong StartIndex');
   
   for i := da^.StartIndex to da^.StartIndex + da^.Size - 1 do
   begin
      TTestObject(da^.items[i]).Destroy;
      da^.Items[i] := TTestObject.Create(i - da^.StartIndex);
   end;
   
   { ---------------- Test: ArrayPopFront (move) -------------------- }      
   StartSilentMode;
   for i := 1 to 102 do
   begin
      lastStart := da^.StartIndex;
      lastSize := da^.Size;
      obj := TTestObject(ArrayPopFront(da, true));
      Test(obj.Value = i - 1, 'ArrayPopFront (move)',
           'returns wrong element; failed in ' + IntToStr(i) + 'th try');
      Test(da^.StartIndex = lastStart, 'ArrayPopFront (move)',
           'StartIndex not preserved; failed in ' + IntToStr(i) + 'th try'); 
      Test(da^.Size = lastSize - 1, 'ArrayPopFront (move)',
           'wrong Count; failed in ' + IntToStr(i) + 'th try');
      obj.Destroy;
   end;
   StopSilentMode;
   Test((da^.StartIndex = 60) and (da^.Size = 100), 'ArrayPopFront (move)');
   
   { ---------------- Test: ArrayCopy -------------------- }
   da2 := nil;
   ArrayCopy(da, da2);
   Test(da^.Capacity = da2^.Capacity, 'ArrayCopy', 'wrong Capacity');
   Test(da^.Size = da2^.Size, 'ArrayCopy', 'wrong Size');
   Test(da^.StartIndex = da2^.StartIndex, 'ArrayCopy', 'wrong StartIndex');
   Test(CompareByte(da^.Items[0], da2^.Items[0], da^.Capacity * SizeOf(TObject)) = 0,
        'ArrayCopy', 'source and destination arrays not byte-to-byte identical');
   
   { ---------------- Test: ArrayDeallocate -------------------- }   
   ArrayDeallocate(da2);
   Test(da2 = nil, 'ArrayDeallocate', 'nil not assigned after deallocation');
   da2 := nil;
   ArrayDeallocate(da2);
   Test(true, 'ArrayDeallocate - handles nil arguments correctly',
        'otherwise we have a segmentation fault and never get here');
   
   { ---------------- Test: ArrayExpand -------------------- }
   lastCapacity := da^.Capacity;
   ArrayExpand(da, 1);
   Test(da^.Capacity = lastCapacity * daGrowRate, 'ArrayExpand (n < capacity)',
        'wrong capacity: ' + InttoStr(da^.Capacity));
   Test((da^.Size = 100) and (da^.StartIndex = 60), 'ArrayExpand',
        'wrong Size or StartIndex');
   
   lastCapacity := da^.Capacity;
   ArrayExpand(da, lastCapacity * daGrowRate + 1000);
   Test(da^.Capacity = lastCapacity * daGrowRate + lastCapacity + 1000,
        'ArrayExpand (n > capacity * daGrowRate)', 'wrong capacity: ' +
                                                      InttoStr(da^.Capacity));
   Test((da^.Size = 100) and (da^.StartIndex = 60), 'ArrayExpand',
        'wrong Size or StartIndex');
   
   
   { now elements are in ascending order starting with 102 (100 items left) }
   
   { ---------------- Test: ArrayPopBack -------------------- }
   StartSilentMode;
   for i := 1 to 50 do
   begin
      lastSize := da^.Size;
      obj := TTestObject(ArrayPopBack(da));
      Test(obj.Value = 202 - i, 'ArrayPopBack',
           'returns wrong item; failed in ' + InttoStr(i) + 'th try');
      Test(da^.Size = lastSize - 1, 'ArrayPopBack',
           'wrong Size; failed in ' + InttoStr(i) + 'th try');
      obj.Destroy;
   end;
   StopSilentMode;
   Test((da^.Size = 50) and (da^.StartIndex = 60), 'ArrayPopBack', 'wrong Size');
   
   { ---------------- Test: ArrayPushFront (move) -------------------- }
   StartSilentMode;
   for i := 1 to 61 do
   begin
      lastSize := da^.Size;
      ArrayPushFront(da, TTestObject.Create(61 - i), true);
      Test(da^.Size = lastSize + 1, 'ArrayPushFront (move)',
           'wrong Size; failed in ' + IntToStr(i) + 'th try');
   end;
   StopSilentMode;
   Test(da^.Size = 111, 'ArrayPushFront (move)', 'wrong Size');
   
   StartSilentMode;
   for i := da^.StartIndex to da^.StartIndex + 60 do
   begin
      Test(TTestObject(da^.Items[i]).Value = i - da^.StartIndex,
           'ArrayPushFront (move)', 'wrong order of items');
   end;
   StopSilentMode;
   
   WriteLn('StartIndex = ', da^.StartIndex);
   
   { ---------------- Test: ArrayApplyFunctor -------------------- }
   StartDestruction(da^.Size, 'ArrayApplyFunctor');
   ArrayApplyFunctor(da, Adapt(@DestroyObjectProc));
   FinishDestruction;
   
   { ---------------- Test: ArrayClear -------------------- }
   ArrayClear(da, 100, 50);
   Test((da^.Capacity = 100) and (da^.StartIndex = 50), 'ArrayClear');
   
   ArrayDeallocate(da);
   Test(da = nil, 'ArrayDeallocate', 'nil not assigned to argument');
   
   FinishTest;
end;

procedure TestCircularArray;
var
   da : TDynamicArray;
   lastCapacity, lastSize : SizeType;
   obj : TTestObject;
   i, lastStart, start : IndexType;
   
   procedure TestCircularPushFront;
   var
      ii : IndexType;
   begin
      StartSilentMode;
      i := -1;
      repeat
         lastStart := da^.StartIndex;
	 lastSize := da^.Size;
	 ArrayCircularPushFront(da, TTestObject.Create(i));
	 Test(da^.Size = lastSize + 1, 'ArrayCircularPushFront',
	      'wrong Size; failed in ' + IntToStr(-i) + 'th step');
	 Test(TTestObject(ArrayCircularGetItem(da, 0)).Value = i,
	      'ArrayCircularPushFront', 'sets wrong item; failed in ' +
					   IntToStr(-i) + 'th step');
	 Dec(i);
      until da^.StartIndex > lastStart; { to force inserting from the back (circ) }
      StopSilentMode;
      Test(true, 'ArrayCircularPushFront (passed (?) ' +
		    IntToStr(-i - 1) + ' steps)');
      start := i + 1;

      StartSilentMode;
      for ii := 0 to da^.Size - 1 do
      begin
	 if ii = da^.Size - 1 then
	    StopSilentMode;
         
	 Test(TTestObject(ArrayCircularGetItem(da, ii)).Value = ii + start,
	      'ArrayCircularPushFront', 'messed sth up with items in array');
      end;
   end;
   
begin
   StartTest('TDynamicArray (circular)');
   
   { ---------------- Test: ArrayAllocate -------------------- }
   da := nil;
   ArrayAllocate(da, 100, 50);
   Test((da <> nil) and (da^.Capacity = 100) and (da^.StartIndex = 50) and
           (da^.Size = 0), 'proper allocation & initialization');
   
   { ----------------- Test: ArrayCircularReserveItems -------------------- }
   ArrayCircularReserveItems(da, 0, 70);
   Test((da^.Size = 70) and (da^.Capacity = 100), 'ArrayCircularReserveItems');
   
   for i := 0 to 69 do
      ArrayCircularSetItem(da, i, TTestObject.Create(i));
   
   { ----------------- Test: ArrayCircularGetItem -------------------- }
   StartSilentMode;
   for i := 0 to 69 do
   begin
      if i = 69 then
         StopSilentMode;
      Test(TTestObject(ArrayCircularGetItem(da, i)).Value = i,
           'ArrayCircularGetItem',
           'returns wrong item; failed in ' + IntToStr(i + 1) + 'th try');
   end;
   
   { ----------------- Test: ArrayCircularSetItem -------------------- }
   StartSilentMode;
   for i := 0 to 69 do
   begin
      if i = 69 then
         StopSilentMode;
      obj := TTestObject(ArrayCircularSetItem(da, i, TTestObject.Create(9000)));
      Test(obj.Value = i, 'ArrayCircularSetItem',
           'returns wrong item; failed in ' + IntToStr(i + 1) + 'th try');
      Test(TTestObject(ArrayCircularGetItem(da, i)).Value = 9000,
           'ArrayCircularSetItem', 'sets wrong item; failed in ' +
                                      IntToStr(i + 1) + 'th try');
      TTestObject(ArrayCircularSetItem(da, i, obj)).Destroy;
   end;
   
   { ----------------- Test: ArrayCircularReserveItems -------------------- }
   ArrayCircularReserveItems(da, 60, 100);
   Test((da^.Size = 170), 'ArrayCircularReserveItems');
   WriteLn('Capacity = ', da^.Capacity);
   WriteLn('StartIndex = ', da^.StartIndex);
   Test(TTestObject(ArrayCircularGetItem(da, 59)).Value = 59,
        'ArrayCircularReserveItems', 'wrong item');
   
   for i := 60 to 159 do
      ArrayCircularSetItem(da, i, TTestObject.Create(i));
   StartSilentMode;
   for i := 160 to 169 do
   begin
      obj := TTestObject(ArrayCircularGetItem(da, i));
      Test(obj.Value = i - 100, 'ArrayCircularReserveItems',
           'messed up sth with objects in array');
      obj.Value := i;
   end;
   StopSilentMode;
   
   { ----------------- Test: ArrayCircularPushFront -------------------- }
   TestCircularPushFront;
   
   { ----------------- Test: ArrayCircularPopFront -------------------- }
   i := start;
   StartSilentMode;
   while da^.Size <> 0 do
   begin
      if da^.Size = 1 then
         StopSilentMode;
      lastSize := da^.Size;
      obj := TTestObject(ArrayCircularPopFront(da));
      Test(obj.Value = i, 'ArrayCircularPopFront',
           'returns wrong item; failed in ' +
              IntToStr(i - start + 1) + 'th step');
      Test(da^.Size = lastSize - 1, 'ArrayCircularPopFront', 
           'wrong Size; failed in ' + IntToStr(i - start + 1) + 'th step');
      obj.Destroy;
      Inc(i);
   end;
   
   { ---------------- Test: ArrayClear -------------------- }
   ArrayClear(da, 100, 50);
   Test((da^.Capacity = 100) and (da^.StartIndex = 50), 'ArrayClear');
   
   
   { ----------------- Test: ArrayCircularPushBack -------------------- }
   for i := 0 to 200 do
   begin
      ArrayCircularPushBack(da, TTestObject.Create(i));
   end;
   Test(da^.Size = 201, 'ArrayCircularPushBack', 'wrong Size');
   
   StartSilentMode;
   for i := 0 to 200 do
   begin
      if i = 200 then
         StopSilentMode;
      Test(TTestObject(ArrayCircularGetItem(da, i)).Value = i,
           'ArrayCircularPushBack', 'wrong order of items');
   end;
   
   { ----------------- Test: ArrayCircularPushFront -------------------- }
   { push sth at front to ensure 'circularity' }
   TestCircularPushFront;
   
   { ----------------- Test: ArrayCircularPopBack -------------------- }
   i := 200;
   StartSilentMode;
   while da^.Size <> 0 do
   begin
      if da^.Size = 1 then
         StopSilentMode;
      
      lastSize := da^.Size;
      obj := TTestObject(ArrayCircularPopBack(da));
      Test(obj.Value = i, 'ArrayCircularPopBack', 'retruns wrong item');
      Test(da^.Size = lastSize - 1, 'ArrayCircularPopBack', 'wrong Size');
      Dec(i);
      obj.Destroy;
   end;
   
   { ---------------- Test: ArrayClear -------------------- }
   ArrayClear(da, 100, 50);
   Test((da^.Capacity = 100) and (da^.StartIndex = 50), 'ArrayClear');
   
   { ----------------- Test: ArrayCircularPushFront -------------------- }
   { push sth at front to ensure 'circularity' }
   TestCircularPushFront;
   
   { ----------------- Test: ArrayCircularRemoveItems -------------------- }
   lastSize := da^.Size;
   WriteLn('Size = ', da^.Size);
   
   for i := 10 to 29 do
   begin
      TTestObject(ArrayCircularSetItem(da, i, nil)).Destroy;
   end;

   ArrayCircularRemoveItems(da, 10, 20);
   Test(da^.Size = lastSize - 20, 'ArrayCircularRemoveItems', 'wrong Size');
   
   StartSilentMode;
   for i := 0 to 9 do
   begin
      Test(TTestObject(ArrayCircularGetItem(da, i)).Value = i + start,
           'ArrayCircularRemoveItems', 'messed up sth with items');
   end;
   for i := 10 to da^.Size - 1 do
   begin
      Test(TTestObject(ArrayCircularGetItem(da, i)).Value = i + start + 20,
           'ArrayCircularRemoveItems', 'messed up sth with items');
   end;
   StopSilentMode;
   
   
   { ---------------- Test: ArrayCircularExpand -------------------- }
   lastSize := da^.Size;
   lastCapacity := da^.Capacity;
   ArrayCircularExpand(da, 1);
   Test(da^.Capacity = lastCapacity * daGrowRate,
        'ArrayCircularExpand (n < capacity)',
        'wrong capacity: ' + InttoStr(da^.Capacity));
   Test((da^.Size = lastSize), 'ArrayCircularExpand', 'wrong Size');
   
   lastCapacity := da^.Capacity;
   ArrayCircularExpand(da, lastCapacity * daGrowRate + 1000);
   Test(da^.Capacity = lastCapacity * daGrowRate + lastCapacity + 1000,
        'ArrayCircularExpand (n > capacity * daGrowRate)',
        'wrong capacity: ' + InttoStr(da^.Capacity) +
           ' (should be ' +
           IntToStr(lastCapacity * daGrowRate + lastcapacity + 1000)  + ')');
   Test((da^.Size = lastSize), 'ArrayCircularExpand', 'wrong Size');
   
   
   { ---------------- Test: ArrayCircularApplyFunctor -------------------- }
   StartDestruction(da^.Size, 'ArrayCircularApplyFunctor');
   ArrayCircularApplyFunctor(da, Adapt(@DestroyObjectProc));
   FinishDestruction;
   
   { ---------------- Test: ArrayClear -------------------- }
   ArrayClear(da, 100, 50);
   Test((da^.Capacity = 100) and (da^.StartIndex = 50), 'ArrayClear');
   
   ArrayDeallocate(da);
   Test(da = nil, 'ArrayDeallocate', 'nil not assigned to argument');
   
   FinishTest;
end;

procedure TestDynamicBuffer;
var
   db, db2 : TDynamicBuffer;
   lastCapacity : SizeType;
begin
   StartTest('TDynamicBuffer');
   
   BufferAllocate(db, 100);
   Test(db^.Capacity = 100, 'BufferAllocate', 'wrong capacity');
   
   { ---------------- Test: BufferExpand -------------------- }
   lastCapacity := db^.Capacity;
   BufferExpand(db, 1);
   Test(db^.Capacity = lastCapacity * bufGrowRate,
        'BufferExpand (n < capacity)',
        'wrong capacity: ' + InttoStr(db^.Capacity));
   
   lastCapacity := db^.Capacity;
   BufferExpand(db, lastCapacity * bufGrowRate + 1000);
   Test(db^.Capacity = lastCapacity * bufGrowRate + lastCapacity + 1000,
        'BufferExpand (n > capacity * bufGrowRate)',
        'wrong capacity: ' + InttoStr(db^.Capacity) +
           ' (should be ' +
           IntToStr(lastCapacity * bufGrowRate + lastcapacity + 1000)  + ')');
   
   { ---------------- Test: BufferCopy -------------------- }
   db2 := nil;
   BufferCopy(db, db2);
   Test(db^.Capacity = db2^.Capacity, 'BufferCopy', 'wrong Capacity');
   Test(CompareByte(db^.Items[0], db2^.Items[0], db^.Capacity * SizeOf(TObject)) = 0,
        'BufferCopy', 'source and destination arrays not byte-to-byte identical');
   
   { ---------------- Test: BufferDeallocate -------------------- }   
   BufferDeallocate(db2);
   Test(db2 = nil, 'BufferDeallocate', 'nil not assigned after deallocation');
   db2 := nil;
   BufferDeallocate(db2);
   Test(true, 'BufferDeallocate - handles nil arguments correctly',
        'otherwise we have a segmentation fault and never get here');
   
   BufferDeallocate(db);
   
   FinishTest;
end;

begin
   TestDynamicArray;
   TestCircularArray;
   TestDynamicBuffer;
end.
