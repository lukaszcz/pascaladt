unit testiters;

interface

uses
   testutils, SysUtils, adtmap, adtcont, adtiters;

{ in the following procedures start should be the Start iterator in
  the container and finish the finish one. The range should contain at
  least 100 items and should contain TTestObjects with values starting
  from zero and increasing by one. Guarantees that the same conditions
  will be true on exit.  }

procedure TestForwardIterator(var start, finish : TForwardIterator);
procedure TestBidirectionalIterator(var start, finish : TBidirectionalIterator);
procedure TestRandomAccessIterator(var start, finish : TRandomAccessIterator);
procedure TestTraversalIterator(start : TTreeTraversalIterator; iname : String);
procedure TestDefinedOrderIterator(var start, finish : TDefinedOrderIterator);
procedure TestSetIterator(var start, finish : TSetIterator);
procedure TestSortedSetIterator(var start, finish : TSetIterator);
procedure TestMapIterator(start, finish : TObjectObjectMapIterator; isSorted : Boolean);


implementation

procedure TestGetItem(start, finish : TForwardIterator; starti : IndexType);
var
   iter : TForwardIterator;
   i : IndexType;
begin
   iter := CopyOf(start);
   i := starti;
   StartSilentMode;
   while not iter.Equal(finish) do
   begin
      TestIter(not iter.IsFinish, 'IsFinish; failed in ' +
                                 IntToStr(i + 1 - starti) + 'th try');
      
      TestIter(TTestObject(iter.Item).Value = i, 'Item',
           'returns wrong item; failed in ' +
              IntToStr(i + 1 - starti) + 'th try');
      
      iter.Advance;
      Inc(i);
   end;
   StopSilentMode;
   
   Write('Destroying iterator... (in TestGetItem)');
   iter.Destroy;
   WriteLn(' - passed');
end;

procedure TestForwardIterator(var start, finish : TForwardIterator);
var
   iter, iter2 : TForwardIterator;
   Size, lastSize : SizeType;
   i : IndexType;
   old1, old2, obj : TTestObject;
begin
   { -------------------------- Owner ----------------------- }
   TestIter(start.Owner = finish.Owner, 'Owner');
   
   { --------------------- IsStart + IsFinish -------------------- }
   TestIter(start.IsStart, 'IsStart');
   TestIter(finish.IsFinish, 'IsFinish');
   TestIter(not finish.IsStart, 'IsStart');
   TestIter(not start.IsFinish, 'IsFinish');
   
   { -------------------------- Equal ----------------------- }
   iter := CopyOf(start);
   TestIter(iter.Equal(start), 'Equal');
   
   { -------------------------- Advance ----------------------- }
   i := 0;
   while not iter.Equal(finish) do
   begin
      iter.Advance;
      Inc(i);
   end;
   TestIter(i = start.Owner.Size, 'Advance',
        'incorrect number of items in range' +
           '(did not move far enough - or maybe Equal failed ?)');
   
   
   { -------------------------- GetItem ----------------------- }
   TestGetItem(start, finish, 0);
   
   
   { -------------------------- Advance (generic) ----------------------- }
   iter := CopyOf(start);
   i := start.Owner.Size div 2;
   Advance(iter, i);
   TestIter(TTestObject(iter.Item).Value = i, 'Advance (generic)');
   
   if not iter.Owner.IsDefinedOrder then
   begin            
      { -------------------------- SetItem ----------------------- }
      iter := CopyOf(start);
      i := 0;
      StartSilentMode;
      while not iter.Equal(finish) do
      begin
         TestIter(not iter.IsFinish, 'IsFinish; failed in ' +
                                    IntToStr(i + 1) + 'th try');
         
         obj := TTestObject.Create(i);
         StartDestruction(1, IterName + '.' + 'SetItem');
         iter.SetItem(obj);
         FinishDestruction;
         
         TestIter(TTestObject(iter.Item).Value = i, 'SetItem',
              'sets wrong item; failed in ' + IntToStr(i + 1) + 'th try');
         
         iter.Advance;
         Inc(i);
      end;
      StopSilentMode;
      
      { -------------------------- IsFinish ----------------------- }
      TestIter(iter.IsFinish, 'IsFinish');
      
      { -------------------------- SetItem ----------------------- }
      CheckRange(start, finish, true, 0, start.Owner.Size,
                 IterName + '.' + 'SetItem');
      
      { -------------------------- Delete ----------------------- }
      Size := finish.Owner.Size;
      i := 0;
      StartSilentMode;
      { note that iterators may be invalidated by the call to Delete,
        so we cannot simply test start against finish }
      while not start.IsFinish do
      begin
         lastSize := start.Owner.Size;
         StartDestruction(1, 'Delete');
         start.Delete;
         FinishDestruction;
         TestIter(start.Owner.Size = lastSize - 1, 'Delete', 'wrong Size');
         if not start.IsFinish then
         begin
            TestIter(TTestObject(start.Item).Value = i + 1, 'Delete',
                     'does not advance iter to next position; failed in ' +
                        IntToStr(i + 1) + 'th try');
         end;
         Inc(i);
      end;
      StopSilentMode;
      TestIter(start.Owner.Size = 0, 'Delete', 'did not delete all items');
      TestIter(start.IsStart, 'IsStart',
               'does not work with empty container, i.e. when start = finish');
      
      { -------------------------- Insert ----------------------- }
      i := Size - 1;
      StartSilentMode;
      while start.Owner.Size <> Size do
      begin
         start.Insert(TTestObject.Create(i));
         TestIter(TTestObject(start.Item).Value = i, 'Insert',
                  'does not move to newly inserted item; failed in ' +
                     IntToStr(Size - i) + 'th try');
         Dec(i);
      end;
      StopSilentMode;
      
      Test(start.IsStart, 'IsStart');
      { get a valid finish iterator }
      finish := CopyOf(start);
      Advance(finish, start.Owner.Size);
      
      StartSilentMode;
      TestIter(finish.IsFinish, 'IsFinish');
      StopSilentMode;
      
      CheckRange(start, finish, true, 0, Size, IterName + '.' + 'Insert');
            
      { ----------------------- ExchangeItem ----------------------- }
      iter := CopyOf(start);
      iter2 := CopyOf(iter);
      iter2.Advance;
      StartSilentMode;
      while not iter2.Equal(finish) do
      begin
         old1 := TTestObject(iter.Item);
         old2 := TTestObject(iter2.Item);
         iter.ExchangeItem(iter2);
         TestIter(TTestObject(iter.Item) = old2, 'ExchangeItem');
         TestIter(TTestObject(iter2.Item) = old1, 'ExchangeItem');
         
         iter.Advance;
         iter2.Advance;
      end;
      StopSilentMode;
      CheckRange(start, iter, true, 1, iter.Owner.Size - 1,
                 IterName + '.' + 'ExchangeItem');
      TestIter(TTestObject(iter.Item).Value = 0, 'ExchangeItem');
      
      obj := TTestObject.Create(iter.Owner.Size);
      StartDestruction(1, IterName + '.' + 'SetItem');
      iter.SetItem(obj);
      FinishDestruction;
      
      start.Insert(TTestObject.Create(0)); // (1)
      
      finish := CopyOf(start);
      Advance(finish, finish.Owner.Size);
      
      StartSilentMode;
      TestIter(finish.IsFinish, 'IsFinish');
      StopSilentMode;
      
      { -------------------------- Extract ---------------------- }
      Size := start.Owner.Size;
      obj := TTestObject(start.Extract); // check (1)
      TestIter(obj.Value = 0, 'Extract', 'returns wrong item');
      TestIter(start.Owner.Size = Size - 1, 'Extract', 'wrong size');
      
      start.Insert(obj);
      finish := CopyOf(start);
      Advance(finish, start.Owner.Size);
      
      { ---------------------- Delete (range) --------------------- }
      start.Delete(finish);
      TestIter(start.IsFinish, 'Delete (range)', 'does not move the iterator');
      TestIter(start.Owner.Size = 0, 'Delete (range)', 'wrong size');
      
      { insert some items }
      for i := 100 downto 0 do
         start.Insert(TTestObject.Create(i));
      finish := CopyOf(start);
      Advance(finish, start.Owner.Size);
   end;
end;

procedure TestBidirectionalIterator(var start, finish : TBidirectionalIterator);
var
   iter : TBidirectionalIterator;
   i, ii : IndexType;
   lastSize, Size : SizeType;
begin
   TestForwardIterator(start, finish);
         
   { -------------------------- Retreat ----------------------- }
   iter := CopyOf(finish);
   iter.Retreat;
   TestIter(not iter.IsFinish, 'Retreat',
        'retreating finish iterator failed - still finish');
   
   { -------------------------- Retreat ----------------------- }
   i := start.Owner.Size - 1;
   StartSilentMode;
   while not iter.Equal(start) do
   begin
      TestIter(TTestObject(iter.Item).value = i, 'Retreat', 'moves to wrong item');
      iter.Retreat;
      Dec(i);
   end;
   StopSilentMode;
   TestIter(TTestObject(iter.Item).Value = i, 'Retreat', 'moves to wrong item');
   
   { -------------------------- Retreat (generic) ----------------------- }
   iter := CopyOf(finish);
   i := finish.Owner.Size;
   Retreat(iter, i div 2);
   TestIter(TTestObject(iter.Item).Value = i - i div 2, 'Retreat (generic)');
   
   if not start.Owner.IsDefinedOrder then
   begin
      iter := CopyOf(start);
      i := start.Owner.Size div 2;
      Advance(iter, i);
      Size := iter.Owner.Size;

      { -------------------------- Delete ----------------------- }
      ii := 1;
      StartsilentMode;
      while not iter.IsFinish do
      begin
         lastSize := iter.Owner.Size;
         StartDestruction(1, 'Delete');
         iter.Delete;
         FinishDestruction;
         if iter.IsFinish then
            StopSilentMode;
         
         TestIter(iter.Owner.Size = lastSize - 1, 'Delete',
                  'wrong Size; failed in ' + IntToStr(ii) + 'th try');
         if not iter.IsFinish then
         begin
            TestIter(TTestObject(iter.Item).Value = i + 1, 'Delete',
                     'does not advance iter to next item; failed in ' +
                        IntToStr(ii) + 'th try');
         end;
         Inc(i);
         Inc(ii);
      end;
      
      { -------------------------- Insert ----------------------- }
      StartSilentMode;
      while iter.Owner.Size <> Size do
      begin
         if iter.Owner.Size = Size - 1 then
            StopSilentMode;
         Dec(i);
         iter.Insert(TTestObject.Create(i));
         TestIter(TTestObject(iter.Item).Value = i, 'Insert',
                  'does not move to newly inserted item');
      end;
      
      { the start and finish iterators might be invalidated by Insert
        or Delete, so we have to re-obtain them }
      start := iter;
      Retreat(start, i);
      finish := CopyOf(start);
      Advance(finish, start.Owner.Size);
      
      CheckRange(start, finish, true, 0, start.Owner.Size,
                 IterName + '.' + 'Insert');
      
      { ------------------------ Insert ---------------------------- }
      { test inserting just before finish }
      i := Size;
      StartSilentMode;
      while finish.Owner.Size <> Size + 1000 do
      begin
         if finish.Owner.Size = Size + 999 then
            StopSilentMode;
         
         finish.Insert(TTestObject.Create(i));
         TestIter(TTestObject(finish.Item).Value = i, 'Insert',
                  'does not move to newly inserted item; failed in ' +
                     IntToStr(i - Size + 1) + 'th try');
         finish.Advance;
         TestIter(finish.IsFinish, 'Insert',
                  'does not insert at proper place - just before finish');
         Inc(i);
      end;
      
      { ------------------------ Retreat ------------------------------ }
      start := CopyOf(finish);
      Retreat(start, start.Owner.Size);
      TestIter(start.IsStart, 'Retreat',
               'retreating finish iterator failed ' +
                  '- result is not the start iterator');
      
      CheckRange(start, finish, true, 0, start.Owner.Size, 'Insert');
   end;
end;

procedure TestRandomAccessIterator(var start, finish : TRandomAccessIterator);
var
   iter : TRandomAccessIterator;
   Size : SizeType;
begin
   TestBidirectionalIterator(start, finish);
   
   size := start.Owner.Size;
   
   { -------------------------- Index ----------------------- }
   TestIter(finish.Index - start.Index = size, 'Index');
   
   { -------------------------- Distance ----------------------- }
   TestIter(start.Distance(finish) = size, 'Distance');
   TestIter(finish.Distance(start) = -size, 'Distance',
        'fails for negative distance');
   TestIter(start.Distance(start) = 0, 'Distance', 'fails for 0 distance');
   
   { -------------------------- Advance (random access) ----------------------- }
   iter := CopyOf(start);
   iter.Advance(size div 2);
   TestIter(TTestObject(iter.Item).Value = size div 2, 'Advance (random access)',
        'advances to wrong position');
   
   iter.Advance(-(size div 2));
   TestIter(iter.Equal(start), 'Advance (random access)',
        'does not handle negative distance properly');
   
   { -------------------------- Less ----------------------- }
   iter.Advance(size div 2);
   StartSilentMode;
   TestIter(iter.Less(finish), 'Less', 'iter < finish returns false');
   TestIter(not iter.Less(start), 'Less', 'iter < start returns true');
   TestIter(start.Less(iter), 'Less', 'start < iter returns false');
   TestIter(not finish.Less(iter), 'Less', 'finish < iter returns true');
   TestIter(start.Less(finish), 'Less', 'start < finish returns false');
   TestIter(not start.Less(start), 'Less', 'start < start returns true');
   TestIter(not finish.Less(finish), 'Less', 'finish < finish returns true');
   StopSilentMode;
   TestIter(not finish.Less(start), 'Less', 'finish < start returns true');   
end;

procedure TestTraversalIterator(start : TTreeTraversalIterator; iname : String);
var
   oldIterName : String;
   iter, finish : TTreeTraversalIterator;
   lastsize, Size : SizeType;
   i : IndexType;
begin
   oldIterName := iterName;
   iterName := iname;
   
   TestIter(start.Owner is TBasicTreeAdt, 'Owner',
        'owner is not a descendant of TBasicTreeAdt');
   
   finish := CopyOf(start);
   Advance(finish, finish.Owner.Size);
   TestBidirectionalIterator(start, finish);
   
   { ---------------------------- StartTraversal ------------------------------- }
   start.StartTraversal;
   TestIter(TTestObject(start.Item).Value = 0, 'StartTraversal',
            'resets to wrong item');
   
   TestGetItem(start, finish, 0);
   
   if not start.Owner.IsDefinedOrder then
   begin
      iter := copyOf(start);
      i := start.Owner.Size div 2;
      Advance(iter, i);
      Size := iter.Owner.Size;
      
      { -------------------------- Delete ----------------------- }
      StartSilentMode;
      while not iter.IsFinish do
      begin
         lastSize := iter.Owner.Size;
         StartDestruction(1, 'Delete');
         iter.Delete;
         FinishDestruction;
         
         if iter.IsFinish then
            StopSilentMode;
         
         TestIter(iter.Owner.Size = lastSize - 1, 'Delete', 'wrong Size');
         if not iter.IsFinish then
         begin
            TestIter(TTestObject(iter.Item).Value = i + 1, 'Delete',
                     'does not advance iter to next item');
         end;
         Inc(i);
      end;
      
      { -------------------------- Insert ----------------------- }
      StartSilentMode;
      while iter.Owner.Size <> Size do
      begin
         if iter.Owner.Size = Size - 1 then
            StopSilentMode;
         Dec(i);
         iter.Insert(TTestObject.Create(i));
         TestIter(TTestObject(iter.Item).Value = i, 'Insert',
                  'does not move to newly inserted item');
      end;
      
      { 're-obtain' the start iterator }
      start.StartTraversal;
      
      finish := CopyOf(start);
      Advance(finish, finish.Owner.Size);
      TestGetItem(start, finish, 0);
   end;
   
   IterName := oldIterName;
end;

procedure TestDelete(var start : TDefinedOrderIterator);
var
   lastSize : SizeType;
begin
   { ------------------------ Delete ------------------------------ }
   StartSilentMode;
   while not start.IsFinish do
   begin
      lastSize := start.Owner.Size;
      StartDestruction(1, iterName + '.Delete');
      start.Delete;
      FinishDestruction;
      TestIter(start.Owner.Size = lastSize - 1, 'Delete', 'wrong size');
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 0, 'Delete',
            'wrong size - did not delete all items');
end;

procedure TestDefinedOrderIterator(var start, finish : TDefinedOrderIterator);
var
   i, j : IndexType;
   lastSize : SizeType;
   iter : TDefinedOrderIterator;
   obj : TTestObject;
begin
   { ----------------------- Equal ------------------------------- }
   iter := CopyOf(start);
   TestIter(iter.Equal(start), 'Equal',
            'iter not equal with its copy (or maybe CopySelf failed?)');
   
   { ---------------------- Delete ------------------------------- }
   TestDelete(start);
   
   { ------------------------ Insert ------------------------------ }
   start.Insert(TTestObject.Create(0));
   TestIter(not start.IsFinish, 'Insert', 'iter still pointing at finish');
   if not start.IsFinish then
   begin
      TestIter(TTestObject(start.Item).Value = 0, 'Insert',
               'does not advance to the newly inserted item');
   end;
   
   StartDestruction(1, iterName + '.Delete');
   start.Delete;
   FinishDestruction;
   
   start.Insert(TTestObject.Create(1));
   TestIter(not start.IsFinish, 'Insert',
            'moves to finish instead of to the new item');
   if not start.IsFinish then
   begin
      TestIter(TTestObject(start.Item).Value = 1, 'Insert',
               'does not advance to newly inserted item');
   end;
   
   start.Advance;
   TestIter(start.IsFinish, 'Advance', 'does not advance to Finish');
   
   finish := CopyOf(start);
   
   { ---------------------------- Retreat ------------------------------ }
   i := 0;
   while not start.IsStart do
   begin
      start.Retreat;
      Inc(i);
   end;
   TestIter(i = 1, 'Retreat', 'performed ' +
                                 IntToStr(i) + ' steps instead of 1');
   
   { --------------------------- Advance ------------------------------- }
   i := TTestObject(start.Item).Value;
   iter := CopyOf(start);
   iter.Advance;
   TestIter(iter.IsFinish, 'Advance', 'moves to wrong item');
   
   { -------------------------- Equal ---------------------------------- }
   TestIter(finish.Equal(iter), 'Equal', 'fails for finish iterators');
   
   TestDelete(start);
   
   { -------------------------- Insert --------------------------------- }
   StartSilentMode;
   for i := 0 to 10000 do
   begin
      lastSize := start.Owner.Size;
      start.Insert(TTestObject.Create(i));
      TestIter(start.Owner.Size = lastSize + 1, 'Insert', 'wrong size');
      TestIter(TTestObject(start.Item).Value = i, 'Insert',
               'does not advance to newly inserted item');
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 10001, 'Insert', 'wrong size');
   
   finish := CopyOf(start);
   while not finish.IsFinish do
      finish.Advance;
   
   while not start.IsStart do
      start.Retreat;
   
   { -------------------------- Distance ------------------------------- }
   TestIter(Distance(start, finish) = 10001, 'Distance (generic)');
   
   TestDelete(start);
   
   
   { -------------------------- Insert --------------------------------- }
   StartSilentMode;
   for i := 0 to 100 do
   begin
      lastSize := start.Owner.Size;
      start.Insert(TTestObject.Create(i));
      TestIter(start.Owner.Size = lastSize + 1, 'Insert', 'wrong size');
      TestIter(TTestObject(start.Item).Value = i, 'Insert',
               'does not advance to newly inserted item');
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 101, 'Insert', 'wrong size');
   
   finish := CopyOf(start);
   while not finish.IsFinish do
      finish.Advance;
   
   while not start.IsStart do
      start.Retreat;
   
   { -------------------------- Distance ------------------------------- }
   TestIter(Distance(start, finish) = 101, 'Distance (generic)');
   
   { -------------------------- SetItem -------------------------------- }
   StartSilentMode;
   for i := 100 downto 0 do
   begin
      for j := 100 downto i + 1 do
         start.Advance;
      obj := TTestObject.Create(i + 101);
      StartDestruction(1, iterName + 'SetItem');
      start.SetItem(obj);
      FinishDestruction;
      TestIter(TTestObject(start.Item) = obj, 'SetItem',
               'does not move to the new item');
      while not start.IsStart do
         start.Retreat;
   end;
   StopSilentMode;
   TestIter(start.IsStart, 'SetItem');
   
   TestDelete(start);
   
   { -------------------------- Insert --------------------------------- }
   StartSilentMode;
   for i := 0 to 100 do
   begin
      lastSize := start.Owner.Size;
      start.Insert(TTestObject.Create(i));
      TestIter(start.Owner.Size = lastSize + 1, 'Insert', 'wrong size');
      TestIter(TTestObject(start.Item).Value = i, 'Insert',
               'does not advance to newly inserted item');
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 101, 'Insert', 'wrong size');
   
   while not start.IsStart do
      start.Retreat;
   
   { ------------------------ ResetItem ------------------------------ }
   
   StartSilentMode;
   for i := 0 to 100 do
   begin
      while TTestObject(start.Item).Value <> i do
         start.Advance;
      obj := TTestObject(start.Item);
      obj.Value := -i;
      start.ResetItem;
      TestIter(TTestObject(start.Item).Value = -i, 'ResetItem',
               'failed in step ' + IntToStr(i));
      while not start.IsStart do
         start.Retreat;
   end;
   StopSilentMode;
   TestIter(start.IsStart, 'ResetItem');
   
   finish := CopyOf(start);
   while not finish.IsFinish do
      finish.Advance;
end;

procedure TestSetIterator(var start, finish : TSetIterator);
var
   obj : TTestObject;
   lastSize : SizeType;
begin
   TestDefinedOrderIterator(start, finish);
   
   Test(start.Owner is TSetAdt, 'Owner', 'the owner is not a set (TSetAdt)');
   
   { ------------------------ Delete ------------------------------ }
   StartSilentMode;
   while not start.IsFinish do
   begin
      lastSize := start.Owner.Size;
      StartDestruction(1, iterName + '.Delete');
      start.Delete;
      FinishDestruction;
      TestIter(start.Owner.Size = lastSize - 1, 'Delete', 'wrong size');
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 0, 'Delete',
            'wrong size - did not delete all items');
   
   TSetAdt(start.Owner).RepeatedItems := false;
   
   { ------------------------ Insert ------------------------------ }
   start.Insert(TTestObject.Create(0));
   TestIter(not start.IsFinish, 'Insert', 'iter still pointing at finish');
   if not start.IsFinish then
   begin
      TestIter(TTestObject(start.Item).Value = 0, 'Insert',
               'does not advance to the newly inserted item');
   end;

   start.Insert(TTestObject.Create(1));
   TestIter(not start.IsFinish, 'Insert',
            'moves to finish instead of to the new item');
   if not start.IsFinish then
   begin
      TestIter(TTestObject(start.Item).Value = 1, 'Insert',
               'does not advance to newly inserted item');
   end;
   
   obj := TTestObject.Create(1);
   start.Insert(obj);
   TestIter(start.IsFinish, 'Insert',
            'does not move to finish when insertion cannot be preformed');
   obj.Free;
   
   finish := CopyOf(start);
   while not start.IsStart do
      start.Retreat;
end;


Procedure TestSortedSetIterator(var start, finish : TSetIterator);
var
   lastSize, i : SizeType;
begin
   TestSetIterator(start, finish);
   
   { --------------------------- Delete ------------------------------ }
   StartSilentMode;
   while not start.IsFinish do
   begin
      lastSize := start.Owner.Size;
      StartDestruction(1, iterName + '.Delete');
      start.Delete;
      FinishDestruction;
      TestIter(start.Owner.Size = lastSize - 1, 'Delete', 'wrong size');
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 0, 'Delete',
            'wrong size - did not delete all items');
   
   { -------------------------- Insert --------------------------------- }
   i := 0;
   StartSilentMode;
   while start.Owner.Size <> 10000 do
   begin
      lastSize := start.Owner.Size;
      start.Insert(TTestObject.Create(start.Owner.Size));
      TestIter(not start.IsFinish, 'Insert',
               'moves to finish instead of to new item');
      if not start.IsFinish then
      begin
         TestIter(TTestObject(start.Item).Value = start.Owner.Size - 1, 'Insert',
                  'does not advance to newly inserted item');
      end else
      begin
         TestIter(start.Owner.Size = 10000, 'Insert',
                  'item not inserted although it could be');;
      end;
      Inc(i);
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = i, 'Insert', 'wrong size');
   
   { -------------------------- Retreat --------------------------------- }
   while not start.IsFinish do
      start.Advance;
   finish := CopyOf(start);
   
   Retreat(start, start.Owner.Size);
   TestIter(start.IsStart, 'Retreat');
   
   { -------------------------- Insert --------------------------------- }
   CheckRange(start, finish, true, 0, 10000, iterName + '.Insert');
   
   { ------------------------ Bidirectional ------------------------------ }
   TestBidirectionalIterator(start, finish);
end;

procedure TestMapIterator(start, finish : TObjectObjectMapIterator; isSorted : Boolean);
var
   lastSize : SizeType;
   i : IndexType;
   key, item : TTestObject;
begin
   { ------------------ Delete ---------------------- }
   StartSilentMode;
   while not start.IsFinish do
   begin
      lastSize := start.Owner.Size;
      StartDestruction(2, 'Delete');
      start.Delete;
      FinishDestruction;
      TestIter(start.Owner.Size = lastSize - 1, 'Delete', 'wrong size');
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 0, 'Delete', 'did not delete all items');
   
   { ------------------ Insert ---------------------- }
   i := 0;
   StartSilentMode;
   while start.Owner.Size <> 10000 do
   begin
      lastSize := start.Owner.Size;
      key := TTestObject.Create(i);
      item := TTestObject.Create(i);
      start.Insert(key, item);
      TestIter(start.Owner.Size = lastSize + 1, 'Insert', 'wrong size');
      TestIter(not start.IsFinish, 'Insert', 'goes to finish');
      TestIter((start.Item = item) and (start.Key = key),
               'Insert', 'moves to wrong item');
      Inc(i);
   end;
   StopSilentMode;
   TestIter(start.Owner.Size = 10000, 'Insert', 'wrong size');
   
   while not start.IsFinish do
      start.Advance;  
   finish := CopyOf(start);
   
   Retreat(start, start.Owner.Size);
   Test(start.IsStart, 'Retreat', 'did not retreat to start');
   
   if isSorted then
   begin
      CheckRange(start, finish, true, 0, start.Owner.Size,
                 iterName + '.Insert');
      TestBidirectionalIterator(start, finish);
   end;
end;

end.
