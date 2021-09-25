unit testcont;

interface

uses
   adtmap, adtcontbase, adtcont, tester;

type
   TPriorityQueueTester = class (TTester)
   protected
      function CreateContainer : TContainerAdt; override;
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   TSetTester = class (TTester)
   protected
      function CreateContainer : TContainerAdt; override;
      procedure TestContainer(cont : TContainerAdt); override;
   public
      procedure Test; override;
   end;
   
   TSortedSetTester = class (TSetTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   TConcatenableSortedSetTester = class (TSortedSetTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   THashSetTester = class (TSetTester)
   protected
      function CreateContainer : TContainerAdt; override;
   end;
   
   TMapTester = class (TTester)
   protected
      function CreateContainer : TContainerAdt; override;
      function ObjectsInOneItem : SizeType; override;
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   TBasicTreeTester = class (TTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   TQueueTester = class (TTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;

   TDequeTester = class (TQueueTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   TSingleListTester = class (TDequeTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   TDoubleListTester = class (TSingleListTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   
   TRandomAccessContainerTester = class (TDoubleListTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;
   

const
   testAlgorithms : Boolean = true; { set this to false to make the
                                      tests a bit quicker }
   { items to insert must be >= 2000 }
   ITEMS_TO_INSERT = 2000;

implementation

uses
   testutils, testiters, testalgs, SysUtils, adtutils,
   adtiters, adtlog, adtfunct;

function TPriorityQueueTester.CreateContainer : TContainerAdt;
begin
   Result := inherited;
   (Result as TPriorityQueueAdt).ItemComparer := TestObjectComparer;
end;

procedure TPriorityQueueTester.TestContainer(cont : TContainerAdt);
var
   pqueue : TPriorityQueueAdt;
               
   procedure DeleteAll;
   var
      num, ii : IndexType;
   begin
      StartSilentMode;
      for ii := 0 to ITEMS_TO_INSERT do
      begin
         if ii = ITEMS_TO_INSERT then
            StopSilentMode;
         num := TTestObject(pqueue.First).Value;
         testutils.Test(num = ii, 'First', 'Returns wrong item: ' + IntToStr(num) +
                                    ' instead of ' + IntToStr(ii));
         StartDestruction(1, 'DeleteFirst');
         pqueue.DeleteFirst;
         FinishDestruction;
      end;
      testutils.Test(pqueue.Empty, 'DeleteFirst', 'not empty after deleting all items');
   end;

var
   i, j : IndexType;
   inserted : array[0..ITEMS_TO_INSERT] of Boolean;
   pqueue2 : TPriorityQueueAdt;
begin
   Assert(cont is TPriorityQueueAdt);
   pqueue := TPriorityQueueAdt(cont);

   StartDestruction(pqueue.Size, 'Clear');
   pqueue.Clear;
   FinishDestruction;
   testutils.Test(pqueue.Empty and (pqueue.Size = 0), 'Clear', 'container not empty');
   
   for i := 0 to ITEMS_TO_INSERT do
      inserted[i] := false;
   for i := 0 to ITEMS_TO_INSERT do
   begin
      repeat
         j := Random(ITEMS_TO_INSERT + 1);
      until not inserted[j];
      pqueue.Insert(TTestObject.Create(j));
      inserted[j] := true;
   end;
   testutils.Test(pqueue.Size = ITEMS_TO_INSERT + 1, 'Size & Insert',
        'wrong size after insertion');
   
   DeleteAll;
   
   pqueue2 := TPriorityQueueAdt(pqueue.CopySelf(nil));
   testutils.Test(pqueue2.Empty, 'CopySelf (with nil)', 'the copy is not empty');
   
   for i := 0 to ITEMS_TO_INSERT do
      inserted[i] := false;
   
   for i := 0 to ITEMS_TO_INSERT do
   begin
      repeat
         j := Random(ITEMS_TO_INSERT + 1);
      until not inserted[j];
      if Random(2) = 0 then
         pqueue.Insert(TTestObject.Create(j))
      else
         pqueue2.Insert(TTestObject.Create(j));
      inserted[j] := true;
   end;
   
   pqueue.Merge(pqueue2);
   testutils.Test(pqueue.Size = ITEMS_TO_INSERT + 1, 'Merge', 'wrong size after merging');
   
   pqueue2 := TPriorityQueueAdt(pqueue.CopySelf(TestObjectCopier));
   testutils.Test((pqueue2.Size = pqueue.Size) and (pqueue2.Size = ITEMS_TO_INSERT + 1),
        'CopySelf (non-nil)', 'wrong size');
   
   DeleteAll;
   
   StartDestruction(pqueue2.Size, 'Clear');
   pqueue2.Clear;
   FinishDestruction;
   testutils.Test(pqueue2.Empty and (pqueue2.Size = 0), 'Clear', 'container not empty');
   
   pqueue2.Insert(TTestObject.Create(10));
   StartDestruction(1, 'destructor');
   pqueue2.Destroy;
   FinishDestruction;
end;



{ =========================== TestSet ================================ }


{ pre-condition: aset must be empty; post-condition: aset is filled
  with some items from the range <0,aset.Size) }
procedure TestInsertSet(aset : TSetAdt);
const
   MAX_ITEMS = ITEMS_TO_INSERT;
var
   finserted : array[0..MAX_ITEMS] of Boolean;
   i, rand : IndexType;
   obj : TTestObject;
   lastSize : SizeType;
   prevRepeatedItems : Boolean;
   
   procedure TestInsAux;
   begin
      obj := TTestObject.Create(rand);
      lastSize := aset.Size;
      if aset.Insert(obj) then
      begin
         testutils.Test(aset.Size = lastSize + 1, 'Insert',
              'wrong size (item really inserted)');
         testutils.Test(not aset.Empty, 'Empty',
              'returns true for non-empty set (item inserted)');
         testutils.Test(aset.Find(obj) <> nil, 'Insert',
              'item not in the set (item inserted), size: ' +
                 IntToStr(aset.Size));
         testutils.Test(aset.Find(obj) = (obj), 'Find',
              'returns wrong item (item inserted, size: ' +
                 IntToStr(aset.Size));
         testutils.Test(aset.Count(obj) = 1, 'Insert',
              'Count returns ' + IntToStr(aset.Count(obj)) +
                 ' (item inserted), Size is ' + IntToStr(aset.Size));
         testutils.Test(finserted[rand] = false, 'Insert',
              'item inserted despite the fact that it had already' +
                 ' been in the set and RepeatedItems = false');
         finserted[rand] := true;
      end else
      begin
         testutils.Test(finserted[rand] = true, 'Insert',
              'item not inserted although not already in the set');
         testutils.Test(aset.Size = lastSize, 'Insert', 'wrong size (item not inserted)');
         testutils.Test(aset.Find(obj) <> (obj), 'Insert',
                                        'item inserted but false returned');
         testutils.Test(aset.Count(obj) = 1, 'Insert', 'Count returns ' +
                                                IntToStr(aset.Count(obj)) +
                                                ' (item not inserted)');
         obj.Free;
      end;
   end;
   
begin
   Randomize;
   for i := 0 to MAX_ITEMS do
      finserted[i] := false;
   
   { ------------------------- Insert --------------------------- }
   aset.RepeatedItems := false;
   StartSilentMode;
   while aset.Size < (MAX_ITEMS div 2) do
   begin
      rand := Random(MAX_ITEMS) + 1;
      TestInsAux;
   end;
   
   for rand := 0 to MAX_ITEMS do
   begin
      TestInsAux;
   end;
   
   StopSilentMode;
   
   testutils.Test(aset.Size = MAX_ITEMS + 1, 'Insert', 'wrong size');
end;

function TSetTester.CreateContainer : TContainerAdt;
begin
   Result := inherited;
   (Result as TSetAdt).ItemComparer := TestObjectComparer;
end;

procedure TSetTester.TestContainer(cont : TContainerAdt);
var
   aset : TSetAdt;
   i, j, firstI : IndexType;
   obj, obj2 : TTestObject;
   lastSize, rand, lastCount, count, s, asetsize, maxItem, firstS : SizeType;
   lb, ub, iter, start, finish : TSetIterator;
   range : TSetIteratorRange;
   set2 : TSetAdt;
   copier : IUnaryFunctor;
begin
   Assert(cont is TSetAdt);
   aset := TSetAdt(cont);
   
   { ------------------------ IsDefinedOrder ---------------------------- }
   testutils.Test(aset.IsDefinedOrder, 'IsDefinedOrder');
   
   { ------------------------ Clear ---------------------------- }
   StartDestruction(aset.Size, 'Clear');
   aset.Clear;
   FinishDestruction;
   
   aset.RepeatedItems := true;
   
   { ------------------------ Size ---------------------------- }
   testutils.Test(aset.Size = 0, 'Size', 'returns non-zero for empty set');
   
   { ------------------------ Empty ---------------------------- }
   testutils.Test(aset.Empty, 'Empty', 'returns false for empty set');
   
   obj := TTestObject.Create(0);
   
   { ------------------------- Has ------------------------------ }
   testutils.Test(not aset.Has(obj), 'Has', 'does not work for an empty set');
   
   { ------------------------- Find ----------------------------- }
   testutils.Test(aset.Find(obj) = nil, 'Find', 'does not work for empty set');
   
   { ------------------------- Count ----------------------------- }
   testutils.Test(aset.Count(obj) = 0, 'Count', 'does not work for empty set');
   
   obj.Free;  
   
   { ------------------------- Insert ----------------------------- }
   TestInsertSet(aset);
   
   { ----------------------- Find + Count + Has -------------------------- }
   StartSilentMode;
   for i := 0 to aset.Size - 1 do
   begin
      if i = aset.Size - 2 then
         StopSilentMode;
      
      obj := TTestObject.Create(i);
      obj2 := TTestObject(aset.Find(obj));
      testutils.Test(obj2 <> nil, 'Find', 'does not return object from the set');
      if obj2 <> nil then
         testutils.Test(obj2.Value = i, 'Find', 'returns wrong item');
      testutils.Test(aset.Has(obj), 'Has', 'returns false for an object present');
      testutils.Test(aset.Count(obj) = 1, 'Count', 'returns ' + InttoStr(aset.Count(obj)) +
                                            ' instead of 1');
      obj.Free;
   end;
   
   { ------------------------ Set iterator ---------------------------- }
   start := aset.Start;
   finish := aset.Finish;
   TestSetIterator(start, finish);
   
   { ------------------------ Clear --------------------------------- }
   StartDestruction(aset.Size, 'Clear');
   aset.Clear;
   FinishDestruction;
   testutils.Test(aset.Size = 0, 'Clear', 'size <> 0');
   
   { -------------------------- Insert ----------------------------- }
   TestInsertSet(aset); 
   
   { ------------------------ Clear --------------------------------- }
   StartDestruction(aset.Size, 'Clear');
   aset.Clear;
   FinishDestruction;
   testutils.Test(aset.Size = 0, 'Clear', 'size <> 0');
   
   aset.RepeatedItems := true;
   
   // insert some items
   for i := 0 to ITEMS_TO_INSERT do
   begin
      aset.Insert(TTestObject.Create(i));
   end;
   
   maxItem := aset.Size - 1;
   
   { ------------------- Insert (repeated items) -------------------- }
   s := aset.Size;
   
   StartSilentMode;
   for i := 0 to 10 do
   begin
      rand := Random(s);
      for j := 1 to 100 do
      begin         
         lastSize := aset.Size;
         obj := TTestObject.Create(rand);
         lastcount := aset.Count(obj);
         testutils.Test(aset.Insert(obj), 'Insert (repeated)',
              'returns false although RepeatedItems = true');
         testutils.Test(aset.Size = lastsize + 1, 'Insert (repeated)', 'wrong size');
         testutils.Test(aset.Find(obj) <> nil, 'Insert (repeated)',
              'inserted item not returned by Find');
         if aset.Find(obj) <> nil then
         begin
            testutils.Test(TTestObject(aset.Find(obj)).Value = rand, 'Find',
                 'returns wrong item');
         end;
         testutils.Test(aset.Count(obj) = lastcount + 1, 'Insert (repeated)',
              'Count(obj) returns wrong amount');
      end;
   end;
   StopSilentMode;
   obj := TTestObject.Create(rand);
   testutils.Test(aset.Count(obj) = 101, 'Insert (repeated items)',
        'did not insert all 101 equal objects');
   
   { ------------------ LowerBound + UpperBound --------------------------- }
   lb := aset.LowerBound(obj);
   ub := aset.UpperBound(obj);
   i := 0;
   StartSilentMode;
   while not lb.Equal(ub) do
   begin
      Inc(i);
      testutils.Test(TTestObject(lb.Item).Value = obj.Value, 'LowerBound & UpperBound',
           'item not equal to searched object at LowerBound + ' + IntToStr(i));
      lb.Advance;
   end;
   StopSilentMode;
   testutils.Test(TTestObject(ub.Item).Value <> obj.Value, 'UpperBound',
        'item at UpperBound equal to searched object');
   testutils.Test(aset.Count(obj) = i, 'UpperBound & LowerBound',
        'not all items in range <LowerBound,UpperBound)');
   
   { ---------------------- EqualRange ------------------------------- }
   range := aset.EqualRange(obj);
   testutils.Test(range.Start.Equal(aset.LowerBound(obj)), 'EqualRange',
        'the start of the range not equal to LowerBound');
   testutils.Test(range.Finish.Equal(aset.UpperBound(obj)), 'EqualRange',
        'the finish of the range not equal to UpperBound');
     
   obj.Free;
   
   { ----------------------- CopySelf ------------------------------- }
   asetSize := aset.Size;
   copier := TTestObjectCopier.Create;
   set2 := TSetAdt(aset.CopySelf(copier));
   testutils.Test(set2.Size = aset.Size, 'CopySelf', 'wrong size');
   testutils.Test(set2.RepeatedItems = aset.RepeatedItems, 'CopySelf',
        'RepeatedItems not copied');
   testutils.Test(set2.ItemDisposer = aset.ItemDisposer, 'CopySelf', 'Disposer not copied');
   
   StartSilentMode;
   for i := 0 to aset.Size - 1 do
   begin
      obj := TTestObject.Create(i);
      testutils.Test(set2.Count(obj) = aset.Count(obj), 'CopySelf', 'not all items copied');
      obj.Free;
   end;
   StopSilentMode;
   
   { ------------------------ Delete --------------------------------- }
   obj := TTestObject.Create(set2.Size);
   testutils.Test(set2.Delete(obj) = 0, 'Delete',
        'returns non-zero for item not in the set');
   obj.Free;
   
   firstS := set2.Size div 2;
   firstI := set2.Size div 10;
   i := firstI;
   s := firstS;
   StartSilentMode;
   while set2.Size > s do
   begin      
      obj := TTestObject.Create(i);
      count := set2.Count(obj);
      if set2.Size - count <= s then
         StopSilentMode;
      lastSize := set2.Size;
      
      StartDestruction(count, 'Delete');
      testutils.Test(set2.Delete(obj) = count, 'Delete', 'does not delete all items');
      FinishDestruction;
      testutils.Test(set2.Size = lastSize - count, 'Delete', 'wrong size');
      
      obj.Free;
      Inc(i);
   end;
   
   { -------------------------- Destroy ------------------------------------ }
   StartDestruction(set2.Size, 'destructor');
   set2.Destroy;
   FinishDestruction;
   
   { check if aset is not changed by operations on set2 }
   testutils.Test(aset.Size = asetSize, 'CopySelf',
        'Size of source set changed by operations on its copy');
   Write('CopySelf: testing if items in source set were not changed ' +
            'by operations on its copy...');
   for i := 0 to maxItem do
   begin
      obj := TTestObject.Create(i);
      if TTestObject(aset.Find(obj)).Value <> i then
      begin
         { we'll probably never get here as there will be protection
           fault earlier }
         WriteLn(' - FAILED !!!');
         break;
      end;
      obj.Free;
   end;
   WriteLn(' - passed');
   
   { --------------------------- Insert ----------------------------------- }
   iter := aset.Start;
   obj := TTestObject.Create(aset.Size);
   lastSize := aset.Size;
   testutils.Test(aset.Insert(iter, obj), 'Insert (with hint)',
        'returns false although inserting item not present in the set');
   testutils.Test(aset.Count(obj) = 1, 'Insert', 'Count(obj) does not return 1');
   testutils.Test(aset.Size = lastSize + 1, 'Insert', 'wrong size');
   
   testutils.Test(aset.Insert(TTestObject.Create(obj.Value)), 'Insert',
        'returns false although RepeatedItems = true');
   testutils.Test(aset.Count(obj) = 2, 'Count', 'does not return 2');
   
   { --------------------------- Delete ------------------------------------ }
   obj := TTestObject.Create(obj.Value);
   iter := aset.LowerBound(obj);
   lastSize := aset.Size;
   
   StartDestruction(1, 'Delete (with given position)');
   iter.Delete;
   FinishDestruction;
   
   testutils.Test(aset.Size = lastSize - 1, 'Delete (with given position)', 'wrong size');
   testutils.Test(aset.Count(obj) = 1, 'Delete (with given position)',
        'Count(obj) failed');
   TestIter(not iter.IsFinish and (TTestObject(iter.Item).Value = obj.Value),
            'Delete', 'does not advance to next item');
   
   lastSize := aset.Size;
   StartDestruction(1, 'Delete (with given position)');
   iter.Delete;
   FinishDestruction;
   
   testutils.Test(aset.Size = lastSize - 1, 'Delete (with given position)', 'wrong size');
   testutils.Test(aset.Find(obj) = nil, 'Delete (with given position)',
        'Find(obj) does not return nil');
   obj.Free;
   
   { --------------------------- Clear -------------------------------------- }
   StartDestruction(aset.Size, 'Clear');
   aset.Clear;
   FinishDestruction;
   testutils.Test(aset.Empty, 'Clear', 'still not empty');
   
   { -------------------------- Insert ---------------------------------- }
   TestInsertSet(aset);
   
   { ---------------------- test algorithms ---------------------- }
   if testAlgorithms then
   begin
      set2 := TSetAdt(aset.CopySelf(TTestObjectCopier.Create));
      TestSetAlgs(aset, set2);
      
      StartDestruction(set2.Size, 'Destructor');
      set2.Destroy;
      FinishDestruction;
   end;
end;

procedure TSetTester.Test;
var
   mt : TMapTester;
begin
   Assert(TestedCont is TSetAdt);
   inherited;
   mt := TMapTester.Create('(map) ' + contName, '(map) ' + iterName,
                           TObjectObjectMap.Create(TSetAdt(TestedCont.CopySelf(nil))));
   mt.Test;
   mt.Destroy;
end;



{ =========================== TestSortedSet ================================ }



procedure TSortedSetTester.TestContainer(cont : TContainerAdt);
var
   sortedset : TSortedSetAdt;
   start, finish : TSetIterator;
begin
   inherited;
   Assert(cont is TSortedSetAdt);
   sortedset := TSortedSetAdt(cont);
   
   start := sortedset.Start;
   finish := sortedset.Finish;
   TestSortedSetIterator(start, finish);
   
   { ---------------------- Clear ----------------------------- }
   StartDestruction(sortedset.Size, 'Clear');
   sortedset.Clear;
   FinishDestruction;
   testutils.Test(sortedset.Size = 0, 'Clear', 'wrong size');
   
   { ---------------------- Insert ---------------------------- }
   TestInsertSet(sortedset);
   
   CheckRange(sortedset.Start, sortedset.Finish, true, 0, sortedset.Size,
              'Insert');
end;






{ ================== TestConcatenableSortedSet ======================== }


procedure TConcatenableSortedSetTester.TestContainer(cont : TContainerAdt);
var
   aset : TConcatenableSortedSetAdt;
   copier : IUnaryFunctor;
   i : IndexType;
   lb, ub : TSetIterator;
   aset2 : TConcatenableSortedSetAdt;
   obj : TTestObject;
begin
   inherited;
   Assert(cont is TConcatenableSortedSetAdt);
   aset := TConcatenableSortedSetAdt(cont);
   
   StartDestruction(aset.Size, 'Clear');
   aset.Clear;
   FinishDestruction;
   
   aset.RepeatedItems := true;
   
   copier := TTestObjectCopier.Create;
   aset2 := TConcatenableSortedSetAdt(aset.CopySelf(copier));
   
   for i := 1 to 10000 do
      aset.Insert(TTestObject.Create(i));
   aset.Insert(TTestObject.Create(10000));
   
   for i := 10000 to 50000 do
      aset2.Insert(TTestObject.Create(i));
   
   aset.Concatenate(aset2);
   
   testutils.Test(aset.Size = 50002, 'Concatenate', 'wrong size');
   
   obj := TTestObject.Create(10000);
   testutils.Test(aset.Count(obj) = 3, 'Concatenate');
   
   lb := aset.LowerBound(obj);
   ub := aset.UpperBound(obj);
   
   CheckRange(aset.Start, lb, true, 1, 9999, 'Concatenate (1)');
   CheckRange(ub, aset.Finish, true, 10001, 40000, 'Concatenate (2)');
   testutils.Test(Distance(lb, ub) = 3, 'Concatenate', 'distance wrong');
   
   aset2 := aset.Split(obj);
   testutils.Test(aset.Size = 10002, 'Split', 'wrong size of the first container');
   testutils.Test(aset2.Size = 40000, 'Split', 'wrong size of the second container');
   testutils.Test(aset.Count(obj) = 3, 'Split (1)');
   testutils.Test(aset2.Count(obj) = 0, 'split (2)');
   lb := aset.LowerBound(obj);
   CheckRange(aset.Start, lb, true, 1, 9999, 'Split (1)');
   CheckRange(aset2.Start, aset2.Finish, true, 10001, 40000, 'Split (2)');
   
   
   aset.Concatenate(aset2);
   testutils.Test(aset.Count(obj) = 3, 'Concatenate');
   
   lb := aset.LowerBound(obj);
   ub := aset.UpperBound(obj);
   
   CheckRange(aset.Start, lb, true, 1, 9999, 'Concatenate (1)');
   CheckRange(ub, aset.Finish, true, 10001, 40000, 'Concatenate (2)');
   testutils.Test(Distance(lb, ub) = 3, 'Concatenate', 'distance wrong');
   
   obj.Destroy;
   
   StartDestruction(aset.Size, 'Clear');
   aset.Clear;
   FinishDestruction;
end;



{ ========================== THashSetTester ========================= }

function THashSetTester.CreateContainer : TContainerAdt;
begin
   result := inherited;
   (Result as THashSetAdt).Hasher := TTestObjectHasher.Create;
end;



{ =========================== TestMap ================================ }



{ map must be empty; on exit map is filled with random items
  associated with all keys from range <0,map.Size) }
procedure TestInsertFindMap(map : TObjectObjectMapAdt);
const
   MAX_ITEMS = ITEMS_TO_INSERT;
var
   tab : array[0..MAX_ITEMS] of TPair;
   i : IndexType;
   key, item : TObject;
   rand1, rand2 : SizeType;
   lastSize : SizeType;
begin
   Randomize;
      
   for i := 0 to MAX_ITEMS do
   begin
      tab[i].First := nil;
      tab[i].Second := nil;
   end;
   
   map.RepeatedItems := false;
   
   { ------------------ Insert ---------------------- }
   StartSilentMode;
   while map.Size < MAX_ITEMS div 2 do
   begin
      rand1 := Random(MAX_ITEMS);
      rand2 := Random(MAX_ITEMS);
      key := TTestObject.Create(rand1);
      item := TTestObject.Create(rand2);
      lastSize := map.Size;
      
      if map.Insert(key, item) then
      begin
         testutils.Test(map.Size = lastSize + 1, 'Insert', 'wrong size (item inserted)');
         testutils.Test(map.Count(key) = 1, 'Insert',
              'item inserted and Count returns ' +
                 IntToStr(map.Count((key))));
         testutils.Test(map.Find(key) = item, 'Find', 'returns wrong item (item inserted)');
         testutils.Test(tab[rand1].First = nil, 'Insert',
              'inserted although RepeatedItems is false' +
                 ' and key already in the map');
         tab[rand1].First := key;
         tab[rand1].Second := item;
      end else
      begin
         testutils.Test(map.Size = lastSize, 'Insert', 'wrong size (not inserted);' +
                                                ' Size = ' + intToStr(map.Size));
         testutils.Test(map.Count(key) = 1, 'Insert',
              '(not inserted) Count returns ' + IntToStr(map.Count(key)));
         testutils.Test(map.Find(key) <> nil, 'Insert',
              'item not inserted although it could be');
         testutils.Test(tab[rand1].First <> nil, 'Insert',
              'item not inserted although not already in the map');
         TTestObject(key).Destroy;
         TTestObject(item).Destroy;
      end;
   end;
   StopSilentMode;
   testutils.Test(map.Size = MAX_ITEMS div 2, 'Insert', 'wrong size');
   
   StartSilentMode;
   for i := 0 to MAX_ITEMS do
   begin
      key := TTestObject.Create(i);
      if tab[i].First = nil then
      begin
         item := TTestObject.Create(Random(MAX_ITEMS));
         lastSize := map.Size;
         testutils.Test(map.Insert((key), (item)), 'Insert',
              'returns false although key not in the map');
         testutils.Test(map[key] = item, 'Find', 'returns wrong item');
         testutils.Test(map.Size = lastSize + 1, 'Insert', 'wrong size');
         tab[i].First := key;
         tab[i].Second := item;
      end else
      begin
         item := map[key];
         testutils.Test(item <> nil, 'Find', 'item not found although inserted');
         if item <> nil then
         begin
            testutils.Test(TTestObject(item).Value = TTestObject(tab[i].Second).Value,
                 'Find', 'wrong item returned');
         end;
         TTestObject(key).Free;
      end;
   end;
   StopSilentMode;
   
   StartSilentMode;
   for i := 0 to MAX_ITEMS do
   begin
      if i = MAX_ITEMS then
         StopSilentMode;
      
      key := tab[i].First;
      item := map[key];
      testutils.Test(item <> nil, 'Find', 'item not found although inserted');
      if item <> nil then
      begin
         testutils.Test(item = tab[i].Second, 'Find',
              'wrong item returned');
      end;
   end;
   
end;


function TMapTester.CreateContainer : TContainerAdt;
begin
   result := inherited;
   (Result as TObjectObjectMapAdt).KeyComparer := TestObjectComparer;
   (Result as TObjectObjectMapAdt).SetKeyHasher(TTestObjectHasher.Create);
end;

function TMapTester.ObjectsInOneItem : SizeType;
begin
   Result := 2;
end;

procedure TMapTester.TestContainer(cont : TContainerAdt);
var
   map : TObjectObjectMapAdt;
   item, key : TObject;
   count, s, lastSize : SizeType;
   i : IndexType;
   iter, iter2, iter3 : TObjectObjectMapIterator;
   range : TObjectObjectMapIteratorRange;
   copier : IUnaryFunctor;
   map2 : TObjectObjectMapAdt;
begin
   Assert(cont is TObjectObjectMapAdt);
   map := TObjectObjectMapAdt(cont);
   
   { ------------------ Clear ---------------------- }
   StartDestruction(map.Size * 2, 'Clear');
   map.Clear;
   FinishDestruction;
   testutils.Test(map.Size = 0, 'Clear', 'wrong size');
   
   { ------------------ Empty ---------------------- }
   testutils.Test(map.Empty, 'Empty', 'returns false for empty map');
   
   { ------------------ Insert & Find ---------------------- }
   TestInsertFindMap(map);
   
   { ------------------ Empty ---------------------- }
   testutils.Test(not map.Empty, 'Empty', 'returns true for non-empty map');
   
   { ------------------- Associate ------------------------- }
   map.RepeatedItems := false;
   StartSilentMode;
   for i := 0 to map.Size - 1 do
   begin
      key := TTestObject.Create(i);
      item := TTestObject.Create(i);
      lastSize := map.Size;
      StartDestruction(2, 'Associate');
      map[key] := item;
      FinishDestruction;
      testutils.Test(map.Size = lastSize, 'Associate', 'wrong size (1)');
      testutils.Test(map.Find(item) = item, 'Associate', 'Find failed (1)');
   end;
   StopSilentMode;
   
   s := map.Size + 100;
   StartSilentMode;
   for i := map.Size to s do
   begin
      key := TTestObject.Create(i);
      item := TTestObject.Create(i);
      lastSize := map.Size;
      map[key] := item;
      testutils.Test(map.Size = lastSize + 1, 'Associate', 'wrong size (2)');
      testutils.Test(map.Find(item) = item, 'Associate', 'Find failed (2)');
   end;
   StopSilentMode;
   
   map.RepeatedItems := true;
   s := map.Size - 1;
   StartSilentMode;
   for i := 0 to s do
   begin
      if i = s then
         StopSilentMode;
      
      key := TTestObject.Create(i);
      item := TTestObject.Create(i);
      lastSize := map.Size;
      map[key] := item;
      testutils.Test(map.Size = lastSize + 1, 'Associate', 'wrong size (3)');
      item := map.Find(item);
      testutils.Test(item <> nil, 'Associate', 'Find failed (2)');
      if item <> nil then
      begin
         testutils.Test(TTestObject(item).Value = i, 'Associate',
              'Find returns wrong item (3)');
      end;
   end;
      
   { ------------------ Clear ---------------------- }
   StartDestruction(map.Size * 2, 'Clear');
   map.Clear;
   FinishDestruction;
   testutils.Test(map.Size = 0, 'Clear', 'wrong size');
   
   TestInsertFindMap(map);
   
   { ------------------ Insert ---------------------- }
   map.RepeatedItems := true;
   s := map.Size - 1;
   StartSilentMode;
   for i := 0 to s do
   begin
      if i = s then
         StopSilentMode;
      
      testutils.Test(map.Insert(TTestObject.Create(i), TTestObject.Create(i)),
           'Insert', 'item not inserted although RepeatedItems is true');
   end;
   
   
   { ------------------ Delete ---------------------- }
   key := TTestObject.Create(map.Size);
   testutils.Test(map.Delete(key) = 0, 'Delete',
        'returns non-zero although key not in the map');
   TTestObject(key).Free;
   
   StartSilentMode;
   for i := 0 to s do
   begin
      key := TTestObject.Create(i);
      lastSize := map.Size;
      count := map.Count(key);
      testutils.Test(count = 2, 'Count', 'does not return 2; returns ' + IntToStr(count));
      StartDestruction(count * 2, 'Delete');
      testutils.Test(map.Delete(key) = count, 'Delete',
           'does not delete all items (wrong return value)');
      FinishDestruction;
      testutils.Test(map.Count(key) = 0, 'Delete', 'Count still returns non-zero');
      testutils.Test(map.Size = lastsize - count, 'Delete',
           'did not delete all items with the given key');
      TTestObject(key).Free;
   end;
   StopSilentMode;
   testutils.Test(map.Size = 0, 'Delete', 'did not delete all items');
   
   TestInsertFindMap(map);
   
   map.RepeatedItems := false;
   s := map.Size - 1;
   for i := 0 to s do
   begin
      key := TTestObject.Create(i);
      item := TTestObject.Create(i);
      StartDestruction(2, 'Associate');
      map[key] := item;
      FinishDestruction;
   end;
   
   if map.IsSorted then
      CheckRange(map.Start, map.Finish, true, 0, map.Size, 'Insert');
   
   { ------------------ LowerBound ---------------------- }
   key := TTestObject.Create(10);
   iter := map.LowerBound(key);
   testutils.Test(TTestObject(iter.Key).Value = 10, 'LowerBound', 'iter.Key failed');
   
   { ------------------ UpperBound ---------------------- }
   iter2 := map.UpperBound(key);
   if not iter2.IsFinish then
   begin 
      testutils.Test(TTestObject(iter2.Key).Value <> 10, 'UpperBound',
           'iter.Key returns 10');
   end;
   
   iter3 := CopyOf(iter);
   iter3.Advance;
   testutils.Test(iter3.Equal(iter2), 'UpperBound & LowerBound',
        'wrong number of items in the range');
   
   { ------------------ EqualRange ---------------------- }
   range := map.EqualRange(key);
   TTestObject(key).Free;
   testutils.Test(iter.Equal(range.Start) and iter2.Equal(range.Finish), 'EqualRange');
   
   { ------------------ CopySelf ---------------------- }
   lastSize := map.Size;
   copier := map.CreateCopier(TTestObjectCopier.Create,
                              TTestObjectCopier.Create);
   map2 := TObjectObjectMapAdt(map.CopySelf(copier));
   
   testutils.Test(map2.Size = map.Size, 'CopySelf', 'size not copied');
   
   StartSilentMode;
   for i := 0 to map2.Size - 1 do
   begin
      key := TTestObject.Create(i);
      testutils.Test(TTestObject(map.Find(key)).Value = TTestObject(map2.Find(key)).Value,
           'CopySelf', 'copied items not equal');
      TTestObject(key).Destroy;
   end;
   StopSilentMode;
   
   StartDestruction(map2.Size * 2, 'destructor (map2)');
   map2.Destroy;
   FinishDestruction;
   
   testutils.Test(map.Size = lastSize, 'CopySelf',
        'source container changed by operations on dest (1)');
   
   StartSilentMode;
   for i := 0 to map.Size - 1 do
   begin
      key := TTestObject.Create(i);
      testutils.Test(map.Count(key) = 1, 'CopySelf',
           'source container changed by operations on dest (2)');
      TTestObject(key).Destroy;
   end;
   StopSilentMode;
   
   TestMapIterator(map.Start, map.Finish, map.IsSorted);
   
end;




{ ========================= TestBasicTree ============================= }



procedure TBasicTreeTester.TestContainer(cont : TContainerAdt);
var
   tree : TBasicTreeAdt;
   tree2 : TBasicTreeAdt;
   iter : TBasicTreeIterator;
   fiter, fiter2 : TForwardIterator;
   i : IndexType;
   copier : IUnaryFunctor;
   
   procedure TestInsertAsRoot(first, last : IndexType);
   var
      ii, lSize : IndexType;
   begin
      StartSilentMode;
      
      if first <= last then
      begin
         for ii := first to last do
         begin
            lSize := tree.Size;
            tree.InsertAsRoot(TTestObject.Create(ii));
            testutils.Test(TTestObject(tree.BasicRoot.Item).Value = ii, 'InsertAsRoot',
                 'inserts wrong item; failed in ' +
                    IntToStr(ii - first + 1) + 'th try');
            testutils.Test(tree.Size = lSize + 1, 'InsertAsRoot',
                 'wrong Size; failed in ' + IntToStr(ii - first + 1) + 'th try');
         end;
      end else
      begin
         for ii := first downto last do
         begin
            lSize := tree.Size;
            tree.InsertAsRoot(TTestObject.Create(ii));
            testutils.Test(TTestObject(tree.BasicRoot.Item).Value = ii, 'InsertAsRoot',
                 'inserts wrong item; failed in ' +
                    IntToStr(first - ii + 1) + 'th try');
            testutils.Test(tree.Size = lSize + 1, 'InsertAsRoot',
                 'wrong Size; failed in ' + IntToStr(first - ii + 1) + 'th try');
         end;
      end;
      
      StopSilentMode;   
   end;
   
begin
   Assert(cont is TBasicTreeAdt);
   tree := TBasicTreeAdt(cont);
   
   { ------------------------------ Clear ----------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong Size');
   
   { -------------------------- Empty ------------------------ }
   testutils.Test(tree.Empty, 'Empty', 'returns false on empty container');
   
   { -------------------------- Size ------------------------ }
   testutils.Test(tree.Size = 0, 'Size');
   
   { -------------------------- InsertAsRoot ------------------------ }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(tree.Size = 1, 'InsertAsRoot', 'wrong Size');
   
   { -------------------------- iterator.IsRoot ------------------------ }
   TestIter(tree.BasicRoot.IsRoot, 'IsRoot', 'returns false for the root');
   
   { -------------------------- iterator.IsLeaf ------------------------ }
   TestIter(tree.BasicRoot.IsLeaf, 'IsLeaf', 'returns false for a leaf');
   
   { -------------------------- iterator.Item  ------------------------ }
   iter := tree.BasicRoot;
   TestIter(TTestObject(iter.Item).Value = 0, 'Item');
   
   { -------------------------- InsertAsRoot ------------------------ }
   TestInsertAsRoot(1, 40000);
   testutils.Test(tree.Size = 40001, 'InsertAsRoot', 'wrong Size');
   
   { -------------------------- iterator.IsLeaf ------------------------ }
   TestIter(not tree.BasicRoot.IsLeaf, 'IsLeaf', 'returns true for internal node');
   
   { -------------------------- Empty ------------------------ }
   testutils.Test(not tree.Empty, 'Empty', 'returns true on non-empty container');
   
   { ------------------------------ Clear ----------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong Size');
   
   { -------------------------- InsertAsRoot ------------------------ }
   TestInsertAsRoot(50000, 0);
   testutils.Test(tree.Size = 50001, 'InsertAsRoot', 'wrong Size');
   
   { -------------------------- DeleteSubTree ------------------------ }
   StartDestruction(50001, 'DeleteSubTree');
   tree.DeleteSubTree(tree.BasicRoot);
   FinishDestruction;
   testutils.Test(tree.Empty, 'DeleteSubTree', 'not empty');
   
   { -------------------------- InsertAsRoot ------------------------ }
   TestInsertAsRoot(50000, 0);
   testutils.Test(tree.Size = 50001, 'InsertAsRoot', 'wrong Size');
   
   { -------------------------- PreOrderIterator ------------------------ }
   TestTraversalIterator(tree.PreOrderIterator, 'TPreOrderIterator');
   
   { ------------------------------ Clear ----------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong Size');
   
   { -------------------------- InsertAsRoot ------------------------ }
   TestInsertAsRoot(0, 50000);
   testutils.Test(tree.Size = 50001, 'InsertAsRoot', 'wrong Size');
   
   { -------------------------- PostOrderIterator ------------------------ }
   TestTraversalIterator(tree.PostOrderIterator, 'TPostOrderIterator');
   
   { ------------------------------ Clear ----------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong Size');
   
   { -------------------------- InsertAsRoot ------------------------ }
   TestInsertAsRoot(0, 50000);
   testutils.Test(tree.Size = 50001, 'InsertAsRoot', 'wrong Size');
   
   { -------------------------- InOrderIterator ------------------------ }
   TestTraversalIterator(tree.InOrderIterator, 'TInOrderIterator');
   
   { ------------------------------ Clear ----------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong Size');
   
   { -------------------------- InsertAsRoot ------------------------ }
   TestInsertAsRoot(5000, 0);
   testutils.Test(tree.Size = 5001, 'InsertAsRoot', 'wrong Size');
   
   { ----------------------- LevelOrderIterator ------------------------ }
   TestTraversalIterator(tree.LevelOrderIterator, 'TLevelOrderIterator');
   
   { ------------------------------ Clear ----------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong Size');
   
   { -------------------------- InsertAsRoot ------------------------ }
   TestInsertAsRoot(20000, 0);
   testutils.Test(tree.Size = 20001, 'InsertAsRoot', 'wrong Size');
   
   { -------------------------- CopySelf ------------------------------- }
   copier := TTestObjectCopier.Create;
   tree2 := TBasicTreeAdt(tree.CopySelf(copier));
   testutils.Test(tree2 <> nil, 'CopySelf', 'returns nil');
   testutils.Test(tree2.Size = 20001, 'CopySelf', 'wrong Size');
   
   fiter := tree2.PreOrderIterator;
   fiter2 := tree.PreOrderIterator;
   i := 0;
   StartSilentMode;
   while not fiter.Equal(tree2.Finish) do
   begin
      testutils.Test(TTestObject(fiter.GetItem).Value = i, 'CopySelf',
           'wrong order of items; failed in ' + IntToStr(i + 1) + 'th try');
      testutils.Test(fiter.Item <> fiter2.Item, 'CopySelf',
           'does not copy items but just pointers to objects!!!' +
              '; failed in ' + IntToStr(i + 1) + 'th try');
      fiter.Advance;
      fiter2.Advance;
      Inc(i);
   end;
   StopSilentMode;
   
   { -------------------------- Destroy -------------------- }
   StartDestruction(tree2.Size, 'destructor');
   tree2.Destroy;
   FinishDestruction;
end;




{ =========================== TestQueue ================================ }

procedure TQueueTester.TestContainer(cont : TContainerAdt);
var
   queue : TQueueAdt;
   i : IndexType;
   lastSize : SizeType;
   queue2 : TQueueAdt;
   copier : IUnaryFunctor;
begin
   Assert(cont is TQueueAdt);
   queue := TQueueAdt(cont);
   
   { -------------------------- Clear ----------------------- }
   StartDestruction(queue.Size, 'Clear');
   queue.Clear;
   FinishDestruction;
   testutils.Test(queue.Size = 0, 'Clear', 'does not update Size');
   
   { -------------------------- Empty ----------------------- }
   testutils.Test(queue.Empty, 'Empty', 'returns false for empty container');
   
   { -------------------------- Front ----------------------- }
   queue.PushBack(TTestObject.Create(0));
   testutils.Test(TTestObject(queue.Front).Value = 0, 'Front',
        'returns wrong item (or PushBack failed)');
   
   { -------------------------- PushBack ----------------------- }
   StartSilentMode;
   for i := 1 to ITEMS_TO_INSERT do
   begin
      lastSize := queue.Size;
      queue.PushBack(TTestObject.Create(i));
      testutils.Test(queue.Size = lastSize + 1, 'PushBack',
           'wrong Size; failed in ' + IntToStr(i) + 'th try');
   end;
   StopSilentMode;
   testutils.Test(queue.Size = ITEMS_TO_INSERT + 1, 'PushBack', 'wrong Size');
   
   { -------------------------- Empty ----------------------- }
   testutils.Test(not queue.Empty, 'Empty', 'returns true for non-empty container');
   
   { -------------------------- Front + PopFront ----------------------- }
   StartSilentMode;
   for i := 0 to ITEMS_TO_INSERT do
   begin
      if i = ITEMS_TO_INSERT then
         StopSilentMode;
      
      testutils.Test(TTestObject(queue.Front).Value = i, 'Front',
           'returns wrong item (or PushBack failed); failed in ' +
              IntToStr(i + 1) + 'th try');
      
      lastSize := queue.Size;
      StartDestruction(1, 'PopFront');
      queue.PopFront;
      FinishDestruction;
      if i <> ITEMS_TO_INSERT then
      begin
         testutils.Test(TTestObject(queue.Front).Value = i + 1, 'PopFront',
              'does not move the next item to the front; failed in ' +
                 IntToStr(i + 1) + 'th try');
      end;
      testutils.Test(queue.Size = lastSize - 1, 'PopFront',
           'wrong Size; failed in ' + IntToStr(i + 1) + 'th try');
   end;
   
   { -------------------------- PushBack ----------------------- }
   StartSilentMode;
   for i := 0 to ITEMS_TO_INSERT do
   begin
      if i = ITEMS_TO_INSERT then
         StopSilentMode;
      
      lastSize := queue.Size;
      queue.PushBack(TTestObject.Create(i));
      testutils.Test(queue.Size = lastSize + 1, 'PushBack',
           'wrong Size; failed in ' + IntToStr(i + 1) + 'th try');
   end;
   
   { -------------------------- Clear ----------------------- }
   StartDestruction(ITEMS_TO_INSERT + 1, 'Clear');
   queue.Clear;
   FinishDestruction;
   testutils.Test(queue.Size = 0, 'Size',
        'or maybe Clear failed to update the internal Size ?');
   
   { -------------------------- PushBack ----------------------- }
   StartSilentMode;
   for i := 0 to ITEMS_TO_INSERT do
   begin
      if i = ITEMS_TO_INSERT then
         StopSilentMode;
      
      lastSize := queue.Size;
      queue.PushBack(TTestObject.Create(i));
      testutils.Test(queue.Size = lastSize + 1, 'PushBack',
           'wrong Size; failed in ' + IntToStr(i + 1) + 'th try');
   end;
   
   { -------------------------- CopySelf ----------------------- }
   copier := TTestObjectCopier.Create;
   queue2 := TQueueAdt(queue.CopySelf(copier));
   testutils.Test(queue2.ItemDisposer = queue.ItemDisposer, 'CopySelf',
        'disposer not copied');
   testutils.Test(queue2.Size = queue.Size, 'CopySelf', 'Size not copied');
   
   StartSilentMode;
   for i := 0 to ITEMS_TO_INSERT do
   begin
      if i = ITEMS_TO_INSERT then
         StopSilentMode;
      
      testutils.Test(not queue2.Empty, 'CopySelf', 'not enough items copied');
      testutils.Test(TTestObject(queue2.Front).Value = i, 'CopySelf',
           'wrong order of copied items');
      
      StartDestruction(1, 'PopFront');
      queue2.PopFront;
      FinishDestruction;
   end;
   testutils.Test(queue2.Empty, 'CopySelf', 'wrong Size');
   
   { --------------------------- Destroy ------------------------------- }
   for i := 0 to ITEMS_TO_INSERT do
   begin
      queue2.PushBack(TTestObject.Create(i));
   end;
   
   StartDestruction(ITEMS_TO_INSERT + 1, 'destructor');
   queue2.Destroy;
   FinishDestruction;
   
   { -------------------------- Clear ----------------------- }
   copier := TTestObjectCopier.Create;
   queue2 := TQueueAdt(queue.CopySelf(copier));
   
   StartDestruction(ITEMS_TO_INSERT + 1, 'Clear');
   queue2.Clear;
   FinishDestruction;
   testutils.Test(queue2.Size = 0, 'Clear', 'wrong Size');
   
   { ------------------ destruction of empty container --------------------- }
   Write('Destroying empty container...');
   queue2.Destroy;
   WriteLn(' - passed');
end;




{ =========================== TestDeque ================================ }

procedure TDequeTester.TestContainer(cont : TContainerAdt);
var
   deque : TDequeAdt;
   i : Indextype;
   first, lastSize : SizeType;
begin
   inherited;
   Assert(cont is TDequeAdt);
   deque := TDequeAdt(cont);
   
   { -------------------------- Back ----------------------- }
   testutils.Test(TTestObject(deque.Back).Value = deque.Size - 1, 'Back',
        'returns wrong item');
   
   
   { -------------------------- PopBack ----------------------- }
   { for singly linked list it takes O(n) time, so it may take a while }
   i := deque.Size - 2;
   first := i;
   StartSilentMode;
   while not deque.Empty do
   begin
      if deque.Size = 1 then
         StopSilentMode;
      
      lastSize := deque.Size;
      
      StartDestruction(1, 'PopBack');
      deque.PopBack;
      FinishDestruction;
      
      if not deque.Empty then
      begin
         testutils.Test(TTestObject(deque.Back).Value = i, 'PopBack',
              'pops wrong item; failed in ' + IntToStr(first + 1 - i) + 'th try');
      end;
      testutils.Test(deque.Size = lastSize - 1, 'PopBack',
           'wrong Size; failed in ' + IntToStr(first + 1 - i) + 'th try');
      Dec(i);
   end;
   
   { -------------------------- Size ----------------------- }
   testutils.Test(deque.Size = 0, 'Size');
   
   { -------------------------- PushFront ----------------------- }
   StartSilentMode;
   for i := ITEMS_TO_INSERT downto 0 do
   begin
      if i = 0 then
         StopSilentMode;
      
      lastSize := deque.Size;
      deque.PushFront(TTestObject.Create(i));
      testutils.Test(TTestObject(deque.Front).Value = i, 'PushFront',
           'sets wrong item; failed in ' + IntToStr(ITEMS_TO_INSERT - i) +
              'th try');
      testutils.Test(deque.Size = lastSize + 1, 'PushFront',
           'wrong Size; failed in ' + IntToStr(ITEMS_TO_INSERT - i) + 'th try');
   end;
   
   { -------------------------- Back + PushBack ----------------------- }
   StartSilentMode;
   for i := ITEMS_TO_INSERT + 1 to ITEMS_TO_INSERT*2 do
   begin
      if i = ITEMS_TO_INSERT*2 then
         StopSilentMode;
      
      lastSize := deque.Size;
      deque.PushBack(TTestObject.Create(i));
      testutils.Test(deque.Size = lastSize + 1, 'PushBack',
           'wrong Size; failed in ' + IntToStr(i - ITEMS_TO_INSERT) + 'th try');
      testutils.Test(TTestObject(deque.Back).Value = i, 'Back',
           'returns wrong item (or PushBack failed); failed in ' +
              IntToStr(i - ITEMS_TO_INSERT) + 'th try');
   end;
end;




{ =========================== TestList ================================ }

procedure TSingleListTester.TestContainer(cont : TContainerAdt);
var
   list : TListAdt;
   i : IndexType;
   lastSize : SizeType;
   iter, iter2, iter3 : TForwardIterator;
   list2 : TListAdt;
   obj : TTestObject;
   copier : IUnaryFunctor;
begin
   inherited;
   Assert(cont is TListAdt);
   list := TListAdt(cont);
   
   iter := list.ForwardStart;
   iter2 := list.ForwardFinish;
   TestForwardIterator(iter, iter2);
   
   { -------------------------- Delete ----------------------- }
   i := 1;
   StartSilentMode;
   while not list.Empty do
   begin
      lastSize := list.Size;
      
      StartDestruction(1, 'Delete');
      list.Delete(list.ForwardStart);
      FinishDestruction;
      
      testutils.Test(list.Size = lastSize - 1, 'Delete',
           'wrong Size; failed in ' + IntToStr(i) + 'th try');
      if not list.Empty then
      begin
         testutils.Test(TTestObject(list.Front).Value = i, 'Delete',
              'deletes wrong item; failed in ' + IntToStr(i) + 'th try');
      end;
      Inc(i);
   end;
   StopSilentMode;
   testutils.Test(list.Size = 0, 'Delete', 'wrong Size');
   
   { -------------------------- Insert ----------------------- }
   StartSilentMode;
   for i := 0 to ITEMS_TO_INSERT do
   begin
      if i = ITEMS_TO_INSERT then
         StopSilentMode;
      
      lastSize := list.Size;
      list.Insert(list.ForwardFinish, TTestObject.Create(i));
      testutils.Test(list.Size = lastSize + 1, 'Insert',
           'wrong Size; failed in ' + IntToStr(i + 1) + 'th try');
      testutils.Test(TTestObject(list.Back).Value = i, 'Insert',
           'inserts at wrong position; failed in ' + IntToStr(i + 1) + 'th try');
   end;
   CheckRange(list.ForwardStart, list.ForwardFinish, true, 0,
              list.Size, 'Insert');
   
   { -------------------------- Delete ----------------------- }
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 2) + 1);
   i := 1;
   StartSilentMode;
   while i <> (ITEMS_TO_INSERT div 4) + 1 do { delete ITEMS_TO_INSERT div 4 items }
   begin
      if i = ITEMS_TO_INSERT div 4 then
         StopSilentMode;
      
      lastSize := list.Size;
      
      StartDestruction(1, 'Delete');
      iter.Delete;
      FinishDestruction;
      
      testutils.Test(list.Size = lastSize - 1, 'Delete',
           'wrong Size; failed in ' + IntToStr(i) + 'th try');
      Inc(i);
   end;
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 2) + 1);
   CheckRange(list.ForwardStart, iter, true, 0, (ITEMS_TO_INSERT div 2) + 1,
              'Delete');
   CheckRange(iter, list.ForwardFinish, true, (ITEMS_TO_INSERT div 4)*3 + 1,
              ITEMS_TO_INSERT div 4, 'Delete');
   testutils.Test(list.Size = 3*(ITEMS_TO_INSERT div 4) + 1, 'Delete', 'wrong Size');
   
   { ---------------------- Delete (range) ------------------------ }
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 2) + 1);
   StartDestruction((ITEMS_TO_INSERT div 2) + 1, 'Delete (range)');
   list.Delete(list.ForwardStart, iter);
   FinishDestruction;
   testutils.Test(list.Size = (ITEMS_TO_INSERT div 4), 'Delete (range)', 'wrong Size');
   CheckRange(list.ForwardStart, list.ForwardFinish, true,
              (ITEMS_TO_INSERT div 4)*3 + 1, (ITEMS_TO_INSERT div 4),
              'Delete (range)');
   
   { ----------------------- PushFront ----------------------- }
   StartSilentMode;
   for i := (ITEMS_TO_INSERT div 2) downto 0 do
   begin
      lastSize := list.Size;
      list.PushFront(TTestObject.Create(i));
      testutils.Test(list.Size = lastSize + 1, 'PushFront',
           'wrong Size; failed in ' +
              IntToStr((ITEMS_TO_INSERT div 2) + 1 - i) + 'th try');
   end;
   StopSilentMode;
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 2) + 1);
   CheckRange(list.ForwardStart, iter, true, 0, (ITEMS_TO_INSERT div 2) + 1,
              'PushFront');
   CheckRange(iter, list.ForwardFinish, true, (ITEMS_TO_INSERT div 4)*3 + 1,
              (ITEMS_TO_INSERT div 4), 'PushFront');
   testutils.Test(list.Size = (ITEMS_TO_INSERT div 4)*3 + 1, 'PushFront', 'wrong Size');

   { -------------------------- Insert ----------------------- }
   StartSilentMode;
   for i := (ITEMS_TO_INSERT div 4)*3 downto (ITEMS_TO_INSERT div 2) + 1 do
   begin
      lastSize := list.Size;
      iter.Insert(TTestObject.Create(i));
      testutils.Test(list.Size = lastSize + 1, 'Insert',
           'wrong Size; failed in ' +
              IntToStr((ITEMS_TO_INSERT div 4)*3 + 1 - i) + 'th try');
   end;
   StopSilentMode;
   testutils.Test(list.Size = ITEMS_TO_INSERT + 1, 'Insert', 'wrong Size');
   CheckRange(list.ForwardStart, list.ForwardFinish, true, 0,
              list.Size, 'Insert');
   
   { ------------------------ Move (same container)  ----------------------- }
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 4));
   iter2 := CopyOf(iter);
   Advance(iter2, 10);
   iter3 := CopyOf(iter);
   
   list.Move(iter, iter2);
   {$ifdef TEST_PASCAL_ADT }
   list.SizeCanRecalc := false;
   {$endif }
   testutils.Test(list.Size = ITEMS_TO_INSERT + 1, 'Move (same container)', 'wrong Size');
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 4));
   testutils.Test(TTestObject(iter.Item).Value = (ITEMS_TO_INSERT div 4) + 1, 'Move',
        'wrong order of items');
   Advance(iter, 9);
   testutils.Test(TTestObject(iter.Item).Value = (ITEMS_TO_INSERT div 4), 'Move',
        'wrong order of items');
   iter.Advance;
   testutils.Test(TTestObject(iter.Item).Value = (ITEMS_TO_INSERT div 4) + 10, 'Move',
        'wrong order of items');
   
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 4));
   iter2 := CopyOf(iter);
   Advance(iter2, 9);
   list.Move(iter2, iter);
   
   {$ifdef TEST_PASCAL_ADT }
   list.SizeCanRecalc := false;
   {$endif }
   testutils.Test(list.Size = ITEMS_TO_INSERT + 1, 'Move', 'wrong Size');
   CheckRange(list.ForwardStart, list.ForwardFinish, true, 0,
              list.Size, 'Move');
   
   { ------------------------ Move (same container, range)  -------------------- }
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 2));
   iter2 := CopyOf(iter);
   Advance(iter2, 10);
   iter3 := CopyOf(iter2);
   Advance(iter3, (ITEMS_TO_INSERT div 4)); 
   
   { move [20000, 20010) to 30010 }
   list.Move(iter, iter2, iter3);
   
   {$ifdef TEST_PASCAL_ADT }
   list.SizeCanRecalc := false;
   {$endif }
   testutils.Test(list.Size = ITEMS_TO_INSERT + 1, 'Move (same container, range)',
        'wrong Size');
   
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 2));
   CheckRange(list.forwardStart, iter, true, 0, (ITEMS_TO_INSERT div 2), 'Move');
   iter2 := CopyOf(iter);
   Advance(iter2, (ITEMS_TO_INSERT div 4));
   CheckRange(iter, iter2, true, (ITEMS_TO_INSERT div 2) + 10,
              (ITEMS_TO_INSERT div 4), 'Move');
   Advance(iter, (ITEMS_TO_INSERT div 4) + 10);
   CheckRange(iter2, iter, true, (ITEMS_TO_INSERT div 2), 10, 'Move');
   CheckRange(iter, list.ForwardFinish, true, (ITEMS_TO_INSERT div 4)*3 + 10,
              (ITEMS_TO_INSERT div 4) - 10, 'Move');
   
   iter := list.ForwardStart;
   Advance(iter, (ITEMS_TO_INSERT div 4)*3);
   iter2 := list.ForwardStart;
   Advance(iter2, (ITEMS_TO_INSERT div 4)*3 + 10);
   iter3 := list.ForwardStart;
   Advance(iter3, (ITEMS_TO_INSERT div 2));
   list.Move(iter, iter2, iter3);
   {$ifdef TEST_PASCAL_ADT }
   list.SizeCanRecalc := false;
   {$endif }
   testutils.Test(list.Size = ITEMS_TO_INSERT + 1, 'Move (same container, range)',
        'wrong Size');
   CheckRange(list.ForwardStart, list.ForwardFinish, true, 0, list.Size, 'Move');
   
   
   { ----------------------- Move (different containers)  ----------------------- }
   copier := TTestObjectCopier.Create;
   list2 := TListAdt(list.CopySelf(copier));
   
   iter := list.ForwardStart;
   Advance(iter, 10);
   list2.Move(iter, list2.ForwardStart);
   {$ifdef TEST_PASCAL_ADT }
   list2.SizeCanRecalc := false;
   list.SizeCanRecalc := false;
   {$endif }
   testutils.Test(list.Size = ITEMS_TO_INSERT, 'Move (different containers)',
        'wrong Size in first container (source)');
   testutils.Test(list2.Size = ITEMS_TO_INSERT + 2, 'Move',
        'wrong Size in second container (destination)');
   
   iter := list.ForwardStart;
   Advance(iter, 10);
   CheckRange(list.ForwardStart, iter, true, 0, 10,
              'Move (checking source container)');
   CheckRange(iter, list.ForwardFinish, true, 11, ITEMS_TO_INSERT - 10,
              'Move (checking source container)');
   iter := list2.ForwardStart;
   testutils.Test(TTestObject(iter.Item).Value = 10, 'Move', 'moves to wrong position');
   iter.Advance;
   CheckRange(iter, list2.ForwardFinish, true, 0, ITEMS_TO_INSERT + 1,
              'Move (checking destination container)');
   iter := list.ForwardStart;
   Advance(iter, 10);
   list.Move(list2.ForwardStart, iter);
   CheckRange(list.ForwardStart, list.ForwardFinish, true, 0, ITEMS_TO_INSERT + 1,
              'Move (checking destination container)');
   CheckRange(list2.ForwardStart, list2.ForwardFinish, true, 0,
              ITEMS_TO_INSERT + 1, 'Move (checking source container)');
   
   { ------------------- Move (different containers, range)  -------------------- }
   list.Move(list2.ForwardStart, list2.ForwardFinish, list.ForwardFinish);
   testutils.Test(list2.Size = 0, 'Move (different containers, range)',
        'Size failed in source container (recalculation)');
   testutils.Test(list.Size = 2*ITEMS_TO_INSERT + 2, 'Move',
        'Size failed in destination container (recalculation)');
   iter := list.ForwardStart;
   Advance(iter, ITEMS_TO_INSERT + 1);
   CheckRange(list.ForwardStart, iter, true, 0, ITEMS_TO_INSERT + 1,
              'Move (checking destination container)');
   CheckRange(iter, list.ForwardFinish, true, 0, ITEMS_TO_INSERT + 1,
              'Move (checking destination container)');
   
   list2.Move(iter, list.ForwardFinish, list2.ForwardStart);
   testutils.Test(list.Size = ITEMS_TO_INSERT + 1, 'Move',
        'Size failed in source container (recalculation)');
   testutils.Test(list2.Size = ITEMS_TO_INSERT + 1, 'Move',
        'Size failed in destination container (recalculation)');
   CheckRange(list.ForwardStart, list.ForwardFinish, true, 0, list.Size,
              'Move (checking source container)');
   CheckRange(list2.ForwardStart, list2.ForwardFinish, true, 0, list2.Size,
              'Move (checking destination container)');
   
   { -------------------------- Extract --------------------------- }
   iter := list2.ForwardStart;
   Advance(iter, 100);
   obj := TTestObject(list2.Extract(iter));
   testutils.Test(obj.Value = 100, 'Extract', 'returns wrong object');
   testutils.Test(list2.Size = ITEMS_TO_INSERT, 'Extract', 'wrong Size');
   obj.Free;
   
   { -------------------------- Destroy --------------------------- }
   StartDestruction(list2.Size, 'destructor');
   list2.Destroy;
   FinishDestruction;
   
   { ---------------------- test algorithms ---------------------- }
   if testAlgorithms then
   begin
      TestAllAlgs(list);
   end;
   
   StartDestruction(list.Size, 'Clear');
   list.Clear;
   FinishDestruction;
   
   for i := 0 to ITEMS_TO_INSERT do
      list.PushBack(TTestObject.Create(i));
end;



{ =========================== TestDoubleList ================================ }

procedure TDoubleListTester.TestContainer(cont : TContainerAdt);
var
   dlist : TDoubleListAdt;
   start, finish : TBidirectionalIterator;
   i : IndexType;
begin
   inherited;
   Assert(cont is TDoubleListAdt);
   dlist := TDoubleListAdt(cont);
   
   start := dlist.BidirectionalStart;
   finish := dlist.BidirectionalFinish;
   TestBidirectionalIterator(start, finish);
   
   { ---------------------- test algorithms ---------------------- }
   if testAlgorithms then
   begin
      TestAllAlgs(dlist);
   end;
   
   StartDestruction(dlist.Size, 'Clear');
   dlist.Clear;
   FinishDestruction;
   
   for i := 0 to ITEMS_TO_INSERT do
      dlist.PushBack(TTestObject.Create(i));
end;




{ =========================== TestRandomAccess ================================ }

procedure TRandomAccessContainerTester.TestContainer(cont : TContainerAdt);
var
   ra : TRandomAccessContainerAdt;
   i, cs : IndexType;
   lastSize, newSize, lastcapacity : SizeType;
   iter, iter2 : TRandomAccessIterator;
   obj : TTestObject;
begin
   inherited;
   Assert(cont is TRandomAccessContainerAdt);
   ra := TRandomAccessContainerAdt(cont);
   
   iter := ra.RandomAccessStart;
   iter2 := ra.RandomAccessFinish;
   TestRandomAccessIterator(iter, iter2);
   
   { -------------------- HighIndex + LowIndex ------------------- }
   testutils.Test(ra.HighIndex >= ra.LowIndex, 'HighIndex & LowIndex',
        'HighIndex >= LowIndex is false');
   testutils.Test(ra.HighIndex - ra.LowIndex + 1 = ra.Size, 'HighIndex & LowIndex',
        'incorrect relationship with Size');
   
   { ------------------------ Delete ----------------------------- }
   i := (ra.Size div 2) + ra.LowIndex;
   cs := i;
   StartSilentMode;
   while i <= ra.HighIndex do
   begin
      lastSize := ra.Size;
      StartDestruction(1, 'Delete');
      ra.Delete(i);
      FinishDestruction;
      testutils.Test(ra.Size = lastSize - 1, 'Delete',
           'wrong Size; failed in ' + IntToStr(cs - i) + 'th step');
      iter := ra.RandomAccessStart;
      iter.Advance(i - ra.LowIndex);
      CheckRange(iter, ra.RandomAccessFinish, true, cs + 1,
                 ra.HighIndex - i + 1, 'Delete');
      Inc(cs);
   end;
   StopSilentMode;
   CheckRange(ra.RandomAccessStart, ra.RandomAccessFinish, true, 0, ra.Size,
              'Delete');
      
   { ------------------------ Insert ----------------------------- }
   i := (ra.Size div 2) + ra.LowIndex;
   newSize := ra.Size * 2;
   StartSilentMode;
   cs := 1;
   while ra.Size <> newSize do
   begin
      lastSize := ra.Size;
      ra.Insert(i, TTestObject.Create(cs));
      testutils.Test(ra.Size = lastSize + 1, 'Insert',
           'wrong Size; failed in ' + IntToStr(cs) + 'th step');
      Inc(cs);
   end;
   StopSilentMode;
   iter := ra.RandomAccessStart;
   iter.Advance(i - ra.LowIndex);
   CheckRange(ra.RandomAccessStart, iter, true, 0, iter.Index - ra.LowIndex,
              'Insert');
   iter2 := CopyOf(iter);
   iter2.Advance(cs - 1);
   CheckRange(iter, iter2, false, cs - 1, cs - 1, 'Insert');
   CheckRange(iter2, ra.RandomAccessFinish, true, i - ra.LowIndex,
              ra.HighIndex - iter2.Index + 1, 'Insert');
   
   { -------------------------- Items ------------------------------ }
   for i := ra.LowIndex to ra.HighIndex do
   begin
      obj := TTestObject.Create(i - ra.LowIndex);
      StartDestruction(1, 'SetItem');
      ra.SetItem(i, obj);
      FinishDestruction;
   end;
   CheckRange(ra.RandomAccessStart, ra.RandomAccessFinish, true, 0,
              ra.Size, 'Items property - writing (SetItem)');
   
   StartSilentMode;
   for i := ra.LowIndex to ra.HighIndex do
   begin
      if i = ra.HighIndex then
         StopSilentMode;
      
      testutils.Test(TTestObject(ra.GetItem(i)).Value = i - ra.LowIndex,
           'Items property - reading (GetItem)',
           'returns wrong item; failed in ' +
              IntToStr(i - ra.LowIndex + 1) + 'th step');
   end;
   
   { ------------------ Delete (n items) --------------------------- }
   newSize := ra.Size - (ra.Size div 2);
   StartDestruction(ra.Size div 2, 'Delete (n items)');
   ra.Delete(ra.LowIndex, ra.Size div 2);
   FinishDestruction;
   testutils.Test(ra.Size = newSize, 'Delete (n items)', 'wrong size');

   { -------------------------- Clear ------------------------------ }
   ra.Clear;
   testutils.Test(ra.Size = 0, 'Clear', 'wrong Size');
   
   { -------------------------- Capacity ------------------------------ }
   ra.Capacity := 5000;
   lastCapacity := ra.Capacity;
   for i := 0 to 4999 do
   begin
      ra.PushBack(TTestObject.Create(i));
   end;
   testutils.Test(ra.Capacity = lastCapacity, 'Capacity property (expansion)',
        'does not preallocate enough memory');
   
   { ---------------------- test algorithms ---------------------- }
   if testAlgorithms then
   begin
      TestAllAlgs(ra);
   end;
   
   StartDestruction(ra.Size, 'Clear');
   ra.Clear;
   FinishDestruction;
   
   for i := 0 to 1000 do
      ra.PushBack(TTestObject.Create(i));
end;


end.
