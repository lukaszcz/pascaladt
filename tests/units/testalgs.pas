unit testalgs;

interface

uses
   adtcont;

{ the containers passed to any of these routines should already
  contain some TestObject's, except for TestAllAlgs }
procedure TestAllAlgs(list : TListAdt); overload;
procedure TestAllAlgs(list : TDoubleListAdt); overload;
procedure TestAllAlgs(cont : TRandomAccessContainerAdt); overload;
procedure TestNonModifyingAlgs(list : TListAdt); overload;
procedure TestNonModifyingAlgs(list : TDoubleListAdt); overload;
procedure TestNonModifyingAlgs(cont : TRandomAccessContainerAdt); overload;
procedure TestModifyingAlgs(list : TListAdt); overload;
procedure TestModifyingAlgs(list : TDoubleListAdt); overload;
procedure TestModifyingAlgs(cont : TRandomAccessContainerAdt); overload;
procedure TestMutatingAlgs(list : TListAdt); overload;
procedure TestMutatingAlgs(list : TDoubleListAdt); overload;
procedure TestMutatingAlgs(cont : TRandomAccessContainerAdt); overload;
procedure TestDeletingAlgs(list : TListAdt); overload;
procedure TestDeletingAlgs(list : TDoubleListAdt); overload;
procedure TestDeletingAlgs(cont : TRandomAccessContainerAdt); overload;
procedure TestSortedRangeAlgs(list : TListAdt); overload;
procedure TestSortedRangeAlgs(list : TDoubleListAdt); overload;
procedure TestSortedRangeAlgs(cont : TRandomAccessContainerAdt); overload;
procedure TestSetAlgs(set1, set2 : TSetAdt); overload;


implementation

uses
   adtalgs, testutils, adtfunct, adtcontbase, adtiters, adtmsg,
   SysUtils, adtlist;

type
   TChanger = class (TFunctor, IUnaryFunctor)
   private
      counter : IndexType;
   public
      function Perform(obj : TObject) : TObject;
   end;
   
   TTestSum = class (TFunctor, IBinaryFunctor)
   public
      function Perform(obj1, obj2 : TObject) : TObject;
   end;
   
   TPartitionFunctor = class
   public
      function Partition(start, finish : TForwardIterator;
                         const pred : IUnaryPredicate) : TForwardIterator;
      virtual; abstract;
   end;
   
   TNormalPartition = class (TPartitionFunctor)
   public
      function Partition(start, finish : TForwardIterator;
                         const pred : IUnaryPredicate) : TForwardIterator;
      override;
   end;
   
   TStablePartition = class (TPartitionFunctor)
   public
      function Partition(start, finish : TForwardIterator;
                         const pred : IUnaryPredicate) : TForwardIterator;
      override;
   end;
   
   TMemoryEfficientStablePartition = class (TPartitionFunctor)
   public
      function Partition(start, finish : TForwardIterator;
                         const pred : IUnaryPredicate) : TForwardIterator;
      override;
   end;
   
   TFindFunctor = class
   private
      cmp : ISubtractor;
   public
      constructor Create;
      function Find(obj : TTestObject) : TIterator; virtual; abstract;
      procedure PushBack(obj : TObject); virtual; abstract;
      function Finish : TIterator; virtual; abstract;
   end;
   
   TNormalFind = class (TFindFunctor)
   private
      list : TListAdt;
   public
      constructor Create(l : TListAdt);
      function Find(obj : TTestObject) : TIterator; override;
      procedure PushBack(obj : TObject); override;
      function Finish : TIterator; override;
   end;
   
   TBinaryFind = class (TFindFunctor)
   private
      cont : TRandomAccessContainerAdt;
   public
      constructor Create(c : TRandomAccessContainerAdt);
      function Find(obj : TTestObject) : TIterator; override;
      procedure PushBack(obj : TObject); override;
      function Finish : TIterator; override;
   end;
   
   TInterpolationFind = class (TFindFunctor)
   private
      cont : TRandomAccessContainerAdt;
   public
      constructor Create(c : TRandomAccessContainerAdt);
      function Find(obj : TTestObject) : TIterator; override;
      procedure PushBack(obj : TObject); override;
      function Finish : TIterator; override;
   end;
   
function TChanger.Perform(obj : TObject) : TObject; 
begin
   // counter inited to 0 at the creation of the object
   Inc(counter);
   TTestObject(obj).Value := counter;
   Result := obj;
end;

function TTestSum.Perform(obj1, obj2 : TObject) : TObject;
begin
   Result := TTestObject.Create(TTestObject(obj1).Value +
                                   TTestObject(obj2).Value);
end;

function TNormalPartition.Partition(start, finish : TForwardIterator;
                                    const pred : IUnaryPredicate) : TForwardIterator;
begin
   Assert((start is TBidirectionalIterator) and
             (finish is TBidirectionalIterator), msgInvalidIterator);
   
   Result := adtalgs.Partition(TBidirectionalIterator(start),
                               TBidirectionalIterator(finish), pred);
end;
   
function TStablePartition.Partition(start, finish : TForwardIterator;
                                    const pred : IUnaryPredicate) : TForwardIterator;
begin
   Result := StablePartition(start, finish, pred);
end;

function TMemoryEfficientStablePartition.
   Partition(start, finish : TForwardIterator;
             const pred : IUnaryPredicate) : TForwardIterator;
begin
   Result := MemoryEfficientStablePartition(start, finish, pred);
end;

constructor TFindFunctor.Create;
begin
   cmp := TestObjectComparer;
end;

constructor TNormalFind.Create(l : TListAdt);
begin
   inherited Create;
   list := l;
end;

function TNormalFind.Find(obj : TTestObject) : TIterator; 
begin
   Result := adtalgs.Find(list.ForwardStart, list.ForwardFinish, obj, cmp);
end;

procedure TNormalFind.PushBack(obj : TObject); 
begin
   list.PushBack(obj);
end;

function TNormalFind.Finish : TIterator; 
begin
   Result := list.ForwardFinish;
end;

constructor TBinaryFind.Create(c : TRandomAccessContainerAdt);
begin
   inherited Create;
   cont := c;
end;

function TBinaryFind.Find(obj : TTestObject) : TIterator; 
begin
   Result := BinaryFind(cont.RandomAccessStart, cont.RandomAccessFinish, obj, cmp);
end;

procedure TBinaryFind.PushBack(obj : TObject); 
begin
   cont.PushBack(obj);
end;

function TBinaryFind.Finish : TIterator; 
begin
   Result := cont.RandomAccessFinish;
end;

constructor TInterpolationFind.Create(c : TRandomAccessContainerAdt);
begin
   inherited Create;
   cont := c;
end;

function TInterpolationFind.Find(obj : TTestObject) : TIterator; 
begin
   Result := InterpolationFind(cont.RandomAccessStart, cont.RandomAccessFinish,
                               obj, cmp);
end;

procedure TInterpolationFind.PushBack(obj : TObject); 
begin
   cont.PushBack(obj);
end;

function TInterpolationFind.Finish : TIterator; 
begin
   Result := cont.RandomAccessFinish;
end;

procedure AddRandomItems(cont : TContainerAdt);
var
   flag : array[1..1000] of boolean;
   i, j : IndexType;
begin
   for i := 1 to 1000 do
      flag[i] := false;
   
   for i := 1 to 1000 do
   begin
      repeat
         j := Random(1000) + 1;
      until not flag[j];
      flag[j] := true;
      cont.InsertItem(TTestObject.Create(j));
   end;
end;

procedure InsertRandomItems(cont : TContainerAdt);
begin
   cont.Clear;
   AddRandomItems(cont);
end;

{ 'sinks' part }
procedure TestPartition(list : TListAdt; part : TPartitionFunctor;
                        nameMsg : String);
var
   pred : IUnaryPredicate;
   cmp : IBinaryComparer;
   obj : TTestObject;
   iter, pivot : TForwardIterator;
   i : IndexType;
begin
   cmp := TestObjectComparer;
   pred := TLessBinder.Create(cmp, nil);
   
   try
      InsertRandomItems(list);
      WriteLn('Testing ' + nameMsg + '...');
      StartSilentMode;
      for i := 1 to 100 do
      begin
         if i = 100 then
            obj := TTestObject.Create(0)
         else if i = 99 then
            obj := TTestObject.Create(9000)
         else
            obj := TTestObject.Create(Random(1000) + 1);
         
         TLessBinder(pred.GetObject).Item := obj;
         pivot := part.Partition(list.ForwardStart, list.ForwardFinish, pred);
//         WriteLn(TRandomAccessIterator(pivot).Index);
         
         iter := list.ForwardStart;
         while not iter.Equal(pivot) do
         begin
            Test(TTestObject(iter.Item).Value < obj.Value, nameMsg,
                 'wrong item in the first range (' +
                    IntToStr(TTestObject(iter.Item).Value) + '), ' +
                    'pivot: ' + IntToStr(obj.Value));
            iter.Advance;
         end;
         
         while not iter.IsFinish do
         begin
            Test(TTestObject(iter.Item).Value >= obj.Value, nameMsg,
                 'wrong item in the second range (' +
                    IntToStr(TTestObject(iter.Item).Value) + '), ' +
                    'pivot: ' + IntToStr(obj.Value));
            iter.Advance;
         end;
         
         obj.Destroy;
         if i = 100 then
            StopSilentMode;
      end;
      WriteLn('Finished testing ' + nameMsg);
   finally
      part.Destroy;
   end;
end;

{ 'sinks' ff }
procedure TestFind(cont : TContainerAdt; ff : TFindFunctor; nameMsg : String);
var
   n, i, j : IndexType;
   obj : TTestObject;
   iter : TForwardIterator;
begin
   n := 1000;
   cont.Clear;
   for i := 1 to n do
   begin
      ff.PushBack(TTestObject.Create(i));
   end;
   
   try
      StartSilentMode;
      for j := 1 to n do
      begin
         if j = n then
            StopSilentMode;
         
         i := Random(n) + 1;
         
         obj := TTestObject.Create(i);
         iter := TForwardIterator(ff.Find(obj));
         obj.Destroy;
         
         Test(not iter.Equal(ff.Finish), nameMsg,
              'did not find an object ' +
                 'existing in the container; object value: ' + IntToStr(i));
         Test(TTestObject(iter.Item).Value = i, nameMsg,
              'found wrong object; searched: ' + IntToStr(i) +
                 '; found: ' + IntToStr(TTestObject(iter.Item).Value));
//         iter.Destroy;
      end;
   finally
      ff.Destroy;
   end;
end;


{ ---------------------------------------------------------------- }

procedure TestAllAlgs(list : TListAdt);
begin
   WriteLn('** Testing algorithms...');
   InsertRandomItems(list);
   TestNonModifyingAlgs(list);
   TestModifyingAlgs(list);
   TestMutatingAlgs(list);
   TestDeletingAlgs(list);
   TestSortedRangeAlgs(list);
   WriteLn('** Finished testing algorithms');
end;

procedure TestAllAlgs(list : TDoubleListAdt); 
begin
   WriteLn('** Testing algorithms...');
   InsertRandomItems(list);
   TestNonModifyingAlgs(list);
   TestModifyingAlgs(list);
   TestMutatingAlgs(list);
   TestDeletingAlgs(list);
   TestSortedRangeAlgs(list);
   WriteLn('** Finished testing algorithms');
end;

procedure TestAllAlgs(cont : TRandomAccessContainerAdt); 
begin
   WriteLn('** Testing algorithms...');
   InsertRandomItems(cont);
   TestNonModifyingAlgs(cont);
   TestModifyingAlgs(cont);
   TestMutatingAlgs(cont);
   TestDeletingAlgs(cont);
   TestSortedRangeAlgs(cont);
   WriteLn('** Finished testing algorithms');
end;

procedure TestNonModifyingAlgs(list : TListAdt);
var
   i : IndexType;
   flag : Boolean;
   iter, iter1, iter2, fin1 : TForwardIterator;
   iterpair : TForwardIteratorPair;
   obj : TTestObject;
begin
   { ---------------------- Find -------------------------- }
   { the object created here is 'sunk' by the function }
   TestFind(list, TNormalFind.Create(list), 'Find');
   
   { -------------------- Count --------------------------- }
   InsertRandomItems(list);
   for i := 1 to 100 do
      list.PushBack(TTestObject.Create(-1));
   AddRandomItems(list);
   list.PushBack(TTestObject.Create(-1));
   
   obj := TTestObject.Create(-1);
   i := Count(list.ForwardStart, list.ForwardFinish,
              EqualTo(TestObjectComparer, obj));
   Test(i = 101, 'Count', 'wrong result: ' + IntToStr(i) + ' instead of 101');
   obj.Destroy;
   
   { ------------------ Minimal --------------------------- }
   iter := Minimal(list.ForwardStart, list.ForwardFinish,
                   TestObjectComparer);
   i := TTestObject(iter.Item).Value;
   Test(i = -1, 'Minimal', 'wrong minimal value: ' +
                              IntToStr(i) + ' instead of -1');
   list.PushFront(TTestObject.Create(-1));
   iter := Minimal(list.ForwardStart, list.ForwardFinish,
                   TestObjectComparer);
   Test(iter.IsStart, 'Minimal', 'not the first minimal item');
   
   { ------------------ Maximal ---------------------------- }
   AddRandomItems(list);
   list.PushBack(TTestObject.Create(1234567));
   AddRandomItems(list);
   
   iter := Maximal(list.ForwardStart, list.ForwardFinish,
                   TestObjectComparer);
   i := TTestObject(iter.Item).Value;
   Test(i = 1234567, 'Maximal', 'wrong max value: ' +
                                   IntToStr(i) + ' instead of -1');
   list.PushFront(TTestObject.Create(1234567));
   iter := Maximal(list.ForwardStart, list.ForwardFinish,
                   TestObjectComparer);
   Test(iter.IsStart, 'Maximal', 'not the first maximal item');
   
   { ------------------ Equal ----------------------------- }
   for i := 1 to 10000 do
      list.PushBack(TTestObject.Create(-i));
   flag := Equal(list.ForwardStart, Advance(list.ForwardStart, 10000),
                 Advance(list.ForwardStart, list.Size - 10000),
                 TEqual.Create(TestObjectComparer));
   Test(not flag, 'Equal', 'returns true for two different ranges');
   
   list.Clear;
   for i := 1 to 5000 do
      list.PushBack(TTestObject.Create(i));
   for i := 1 to 5000 do
      list.PushBack(TTestObject.Create(i));
   for i := 1 to 5000 do
      list.PushBack(TTestObject.Create(i));
   flag := Equal(list.ForwardStart, Advance(list.ForwardStart, 10000),
                 Advance(list.ForwardStart, 5000),
                 TEqual.Create(TestObjectComparer));
   Test(flag, 'Equal', 'returns false for two equal overlapping ranges');
   
   { ---------------------- Mismatch ---------------------- }
   fin1 := Advance(list.ForwardStart, 10000);
   iterpair := Mismatch(list.ForwardStart, fin1,
                        Advance(list.ForwardStart, 5000),
                        TEqual.Create(TestObjectComparer));
   Test(iterpair.First.Equal(fin1), 'Mismatch',
        'returns a mismatch for equal ranges');
   
   iter := list.ForwardStart;
   Advance(iter, 4000);
   iter.Item := TTestObject.Create(-1);
   fin1 := Advance(list.ForwardStart, 5000);
   iterpair := Mismatch(list.ForwardStart, fin1, fin1,
                        TEqual.Create(TestObjectComparer));
   Test(not iterpair.First.Equal(fin1), 'Mismatch',
        'does not find a mismatch for non-equal ranges');
   Test(TTestObject(iterpair.First.Item).Value = -1, 'Mismatch');
   Test(TTestObject(iterpair.Second.Item).Value = 4001, 'Mismatch');
   Test(Distance(list.ForwardStart, iterpair.First) = 4000, 'Mismatch');
   
   { ------------------ LexicographicalCompare ------------------- }
   list.Clear;
   for i := 1 to 6000 do
      list.PushBack(TTestObject.Create(i));
   for i := 1 to 5000 do
      list.PushBack(TTestObject.Create(i));
   iter1 := list.ForwardStart;
   Advance(iter1, 5000);
   iter2 := Advance(CopyOf(iter1), 1000);
   i := LexicographicalCompare(list.ForwardStart, iter1, iter2,
                               list.ForwardFinish, TestObjectComparer);
   Test(i = 0, 'LexicographicalCompare', 'returns non-zero for equal ranges');
   i := LexicographicalCompare(list.ForwardStart, iter2, iter2,
                               list.ForwardFinish, TestObjectComparer);
   Test(i > 0, 'LexicographicalCompare', 'wrong return for r1 > r2');
   i := LexicographicalCompare(Advance(list.ForwardStart, 5000), iter2,
                               iter2, list.ForwardFinish,
                               TestObjectComparer);
   Test(i > 0, 'LexicographicalCompare', 'wrong return for r1 > r2');
   
   iter := list.ForwardStart;
   iter.Advance;
   iter.Item := TTestObject.Create(0);
   i := LexicographicalCompare(list.ForwardStart, iter1, iter2,
                               list.ForwardFinish, TestObjectComparer);
   Test(i < 0, 'LexicographicalCompare', 'wrong return for r1 < r2');
end;

procedure TestNonModifyingAlgs(list : TDoubleListAdt); 
begin
   TestNonModifyingAlgs(TListAdt(list));
end;

procedure TestNonModifyingAlgs(cont : TRandomAccessContainerAdt); 
begin
   TestNonModifyingAlgs(TDoubleListAdt(cont));
end;

procedure TestModifyingAlgs(list : TListAdt);
var
   i, n : Indextype;
   funct : IUnaryFunctor;
   iter, iter2 : TForwardIterator;
   list2 : TListAdt;
begin
   { ---------------------- ForEach --------------------------- }
   n := list.Size + 1000;
   for i := 1 to 1000 do
   begin
      list.PushBack(TTestObject.Create(Random(2*n)));
   end;
   funct := TChanger.Create;
   ForEach(list.ForwardStart, list.ForwardFinish, funct);
   CheckRange(list.ForwardStart, list.ForwardFinish,
              true, 1, list.Size, 'ForEach');
   
   { ---------------------- Generate --------------------------- }
   n := list.Size + 1000;
   for i := 1 to 1000 do
   begin
      list.PushBack(TTestObject.Create(Random(2*n)));
   end;
   funct := TChanger.Create;
   Generate(list.ForwardStart, list.ForwardFinish,
            Compose_F_Gx(TTestObjectCopier.Create, funct));
   CheckRange(list.ForwardStart, list.ForwardFinish,
              true, 1, list.Size, 'Generate');
   
   { ---------------------- Copy ---------------------------- }
   list.Clear;
   list2 := TDoubleListAdt(list.CopySelf(nil));
   for i := 1 to 1000 do
      list.PushBack(TTestObject.Create(i));
   Copy(list.ForwardStart, list.ForwardFinish, TBackInserter.Create(list2),
        TTestObjectCopier.Create);
   CheckRange(list.ForwardStart, list.ForwardFinish,
              true, 1, 1000, 'Copy (source)');
   CheckRange(list2.ForwardStart, list2.ForwardFinish,
              true, 1, 1000, 'Copy (dest)');
   
   Copy(list2.ForwardStart, list2.ForwardFinish, TBackInserter.Create(list),
        TTestObjectCopier.Create);
   CheckRange(list2.ForwardStart, list2.ForwardFinish,
              true, 1, 1000, 'Copy (source)');
   iter := Advance(list.ForwardStart, 1000);
   CheckRange(list.ForwardStart, iter, true, 1, 1000, 'Copy (dest 1)');
   CheckRange(iter, list.ForwardFinish, true, 1, 1000, 'Copy (dest 2)');
   list2.Destroy;   
   
   { -------------------- Move ---------------------------- }
   iter2 := list.ForwardStart;
   iter2.Advance;
   Move(iter, list.ForwardFinish, iter2);
   Test(TTestObject(list.Front).Value = 1, 'Move');
   iter := list.ForwardStart;
   iter.Advance;
   iter2 := Advance(CopyOf(iter), 1000);
   CheckRange(iter, iter2, true, 1, 1000, 'Move');
   CheckRange(iter2, list.ForwardFinish, true, 2, 999, 'Move');
   
   { ---------------------- Combine ---------------------- }
   list.Clear;
   for i := 1 to 1000 do
      list.PushBack(TTestObject.Create(2*i));
   for i := 1 to 1000 do
      list.PushBack(TTestObject.Create(-i));
   iter := Advance(list.ForwardStart, 1000);
   Combine(list.ForwardStart, iter, iter, list.ForwardStart, TTestSum.Create);
   CheckRange(list.ForwardStart, iter, true, 1, 1000, 'Combine');
   CheckRange(iter, list.ForwardFinish, false, -1, 1000, 'Combine');
end;

procedure TestModifyingAlgs(list : TDoubleListAdt); 
begin
   TestModifyingAlgs(TListAdt(list));
end;

procedure TestModifyingAlgs(cont : TRandomAccessContainerAdt); 
begin
   TestModifyingAlgs(TDoubleListAdt(cont));
end;

procedure TestMutatingAlgs(list : TListAdt);
var
   i, j, n : IndexType;
begin
   { ----------------------- StablePartition -------------------- }
   { the object created here is 'sunk' by the function }
   InsertRandomItems(list);
   TestPartition(list, TStablePartition.Create, 'StablePartition');
   
   { --------------- MemoryEfficientStablePartition ------------- }
   { the object is 'sunk' by the function (ditto) }
   InsertRandomItems(list);
   TestPartition(list, TMemoryEfficientStablePartition.Create,
                 'MemoryEfficientStablePartition');
   
   { -------------------- Rotate ------------------------------- }
   StartSilentMode;
   for j := 1 to 100 do
   begin
      if j = 100 then
         StopSilentMode;
      
      list.Clear;
      for i := 1 to 10000 do
         list.PushBack(TTestObject.Create(i));
      n := Random(10000);
      
      Rotate(list.ForwardStart, Advance(list.ForwardStart, n),
             list.ForwardFinish);
      
      CheckRange(Advance(list.ForwardStart, n), list.ForwardFinish,
                 true, 1, 10000 - n, 'Rotate (' + IntToStr(n) + ')');
      CheckRange(list.ForwardStart, Advance(list.ForwardStart, n),
                 true, 10001 - n, n, 'Rotate (' + IntToStr(n) + ')');
   end;
end;

procedure TestMutatingAlgs(list : TDoubleListAdt);
var
   cmp : IBinaryComparer;
   i : IndexType;
begin
   TestMutatingAlgs(TListAdt(list));
   
   { ------------------- InsertionSort ------------------------ }
   InsertRandomItems(list);
   cmp := TestObjectComparer;
   InsertionSort(list.BidirectionalStart, list.BidirectionalFinish, cmp);
   CheckRange(list.BidirectionalStart, list.BidirectionalFinish,
              true, 1, list.Size, 'InsertionSort');
   
   { -------------------- Partition --------------------------- }
   { the object created here is 'sunk' by the function }
   TestPartition(list, TNormalPartition.Create, 'Partition');   
   
   { ------------------------ Reverse --------------------------------- }
   list.Clear;
   for i := 1 to 10000 do
      list.PushBack(TTestObject.Create(i));
   Reverse(list.BidirectionalStart, list.BidirectionalFinish);
   CheckRange(list.BidirectionalStart, list.BidirectionalFinish,
              false, 10000, 10000, 'Reverse');
end;

procedure TestMutatingAlgs(cont : TRandomAccessContainerAdt); 
var
   cmp : IBinaryComparer;
   i, j, k : Indextype;
   obj : TObject;
   m, n, count : SizeType;
   perc : Double;
begin
   TestMutatingAlgs(TDoubleListAdt(cont));
   
   { ----------------------- RandomShuffle ------------------------ }
   { note: if the distribution is random then the probability that one
     item i out of n items lands at the position i should be 1/n;
     thus, in m tries, the average number of times we find a given
     item i at the index i should be close to m/n (Bernoulli tries);
     hence, the overall number of times we find any item i at the
     position i is n*(m/n) = m }
   WriteLn('Testing RandomShuffle (may take a while) ...');
   m := 10000;
   n := 100;
   count := 0;
   cont.Clear;
   for j := 0 to n - 1 do
      cont.PushBack(TTestObject.Create(j));
   for i := 1 to m do
   begin
      RandomShuffle(cont.RandomAccessStart, cont.RandomAccessFinish);
      for j := 0 to n - 1 do
      begin
         if TTestObject(cont.GetItem(j)).Value = j then
            Inc(count);
      end;
   end;
   perc := count*100/m;
   WriteLn('Randomness of RandomShuffle: ', perc, '%');
   WriteLn('(100% is ideal; several percent divergence is acceptable)');
   
   cmp := TestObjectComparer;
   
   InsertRandomItems(cont);
   InsertionSort(cont.RandomAccessStart, cont.RandomAccessFinish, cmp);
   CheckRange(cont.RandomAccessStart, cont.RandomAccessFinish,
              true, 1, cont.Size, 'InsertionSort');
   
   InsertRandomItems(cont);
   ShellSort(cont.RandomAccessStart, cont.RandomAccessFinish, cmp);
   CheckRange(cont.RandomAccessStart, cont.RandomAccessFinish,
              true, 1, cont.Size, 'ShellSort');
   
   InsertRandomItems(cont);
   MergeSort(cont.RandomAccessStart, cont.RandomAccessFinish, cmp);
   CheckRange(cont.RandomAccessStart,cont.RandomAccessFinish,
              true, 1, cont.Size, 'MergeSort');
   
   InsertRandomItems(cont);
   QuickSort(cont.RandomAccessStart, cont.RandomAccessFinish, cmp);
   CheckRange(cont.RandomAccessStart, cont.RandomAccessFinish,
              true, 1, cont.Size, 'QuickSort');
   
   InsertRandomItems(cont);
   Sort(cont.RandomAccessStart, cont.RandomAccessFinish, cmp);
   CheckRange(cont.RandomAccessStart, cont.RandomAccessFinish,
              true, 1, cont.Size, 'Sort');
   
   { ------------------------- FindKthItemHoare ----------------------- }
   InsertRandomItems(cont);
   StartSilentMode;
   for i := 1 to 100 do
   begin
      if i = 100 then
         StopSilentMode;
      k := Random(1000) + 1;
      obj := FindKthItemHoare(cont.RandomAccessStart,
                              cont.RandomAccessFinish, k, cmp);
      Test(TTestObject(obj).Value = k, 'FindKthItemHoare',
           'returns wrong item: ' + IntToStr(TTestObject(obj).Value) +
              'instead of ' + IntToStr(k));
   end;
   
   { ----------------------- FindKthItem ---------------------- }
   InsertRandomItems(cont);
   StartSilentMode;
   for i := 1 to 100 do
   begin
      if i = 100 then
         StopSilentMode;
      k := Random(1000) + 1;
      obj := FindKthItem(cont.RandomAccessStart, cont.RandomAccessFinish, k, cmp);
      Test(TTestObject(obj).Value = k, 'FindKthItem',
           'returns wrong item: ' + IntToStr(TTestObject(obj).Value) +
              ' instead of ' + IntToStr(k));
   end;
   
end;

procedure TestDeletingAlgs(list : TListAdt);
var
   s : SizeType;
   i : Indextype;
   obj : TTestObject;
begin
   InsertRandomItems(list);

   { ----------------------- Delete -------------------------- }
   s := list.Size;
   StartDestruction(s, 'Delete');
   Test(Delete(list.ForwardStart, s + 3) = s, 'Delete',
        'wrong number returned');
   FinishDestruction;
   
   { ---------------------- DeleteIf -------------------------- }
   list.Clear;
   for i := 1 to 10000 do
   begin
      list.PushBack(TTestObject.Create(i));
      list.PushBack(TTestObject.Create(-i));
   end;
   obj := TTestObject.Create(0);
   StartDestruction(10000, 'DeleteIf');
   DeleteIf(list.ForwardStart, 20000,
            LessThan(TestObjectComparer, obj));
   FinishDestruction;
   obj.Destroy;
   CheckRange(list.ForwardStart, list.ForwardFinish,
              true, 1, 10000, 'DeleteIf');
end;

procedure TestDeletingAlgs(list : TDoubleListAdt);
begin
   TestDeletingAlgs(TListAdt(list));
end;

procedure TestDeletingAlgs(cont : TRandomAccessContainerAdt);
begin
   TestDeletingAlgs(TDoubleListAdt(cont));
end;

procedure TestSortedRangeAlgs(list : TListAdt);
var
   list2, list3 : TSingleList;
   cmp : IBinaryComparer;
   i, j : Indextype;
   s : SizeType;
begin
   list2 := nil;
   list3 := nil;
   
   try
      cmp := TestObjectComparer;
      list.Clear;
      list2 := TSingleList.Create;
      list3 := TSingleList.Create;
      
      for i := 1 to 100 do
      begin
         if (i and $01) <> 0 then
            list.PushBack(TTestObject.Create(i))
         else
            list2.PushBack(TTestObject.Create(i));
      end;
      s := list.Size + list2.Size;
      
      { ------------------ MergeCopy ---------------------- }
      
      MergeCopy(list2.ForwardStart, list2.ForwardFinish,
                list.ForwardStart, list.ForwardFinish,
                list3.ForwardStart, cmp, TTestObjectCopier.Create);
      
      Test(list3.Size = s, 'MergeCopy', 'wrong size');
      CheckRange(list3.ForwardStart, list3.ForwardFinish,
                 true, 1, list3.Size, 'MergeCopy');
      
      StartDestruction(list3.Size, 'Clear');
      list3.Clear;
      FinishDestruction;
      
      { ------------------------ Merge ---------------------- }
      
      Merge(list2.ForwardStart, list2.ForwardFinish,
            list.ForwardStart, list.ForwardFinish,
            list3.ForwardStart, cmp);
      
      Test(list3.Size = s, 'Merge', 'wrong size');
      CheckRange(list3.ForwardStart, list3.ForwardFinish,
                 true, 1, list3.Size, 'MergeCopy');
      Test(list.Empty, 'Merge', 'the second list not cleared');
      Test(list2.Empty, 'Merge', 'the first list not cleared');
      
      { ----------------- Unique -------------------------- }
      list.Clear;
      for i := 1 to 10000 do
      begin
         list.PushBack(TTestObject.Create(i));
         if (i and $01) <> 0 then
            for j := 1 to 100 do
               list.PushBack(TTestObject.Create(i));
      end;
      StartDestruction(100*5000, 'Unique');
      i := Unique(list.ForwardStart, list.Size, TestObjectComparer);
      FinishDestruction;
      Test(i = 100*5000, 'Unique', 'wrong return');
      CheckRange(list.ForwardStart, list.ForwardFinish,
                 true, 1, 10000, 'Unique');

   finally
      list2.Free;
      list3.Free;
   end;
end;

procedure TestSortedRangeAlgs(list : TDoubleListAdt); 
begin
   TestSortedRangeAlgs(TListAdt(list));
end;

procedure TestSortedRangeAlgs(cont : TRandomAccessContainerAdt); 
begin
   TestSortedRangeAlgs(TDoubleListAdt(cont));
   { the object created here is 'sunk' by the function }
   TestFind(cont, TBinaryFind.Create(cont), 'BinaryFind');
   { the object created here is 'sunk' by the function }
   TestFind(cont, TInterpolationFind.Create(cont), 'InterpolationFind');
end;

procedure TestSetAlgs(set1, set2 : TSetAdt);
const
   { ITEMS_NUM must be >= 10 and be divisible by 10 }
   ITEMS_NUM = 1000; 
var
   set3, set4 : TSetAdt;
   i : Indextype;
   obj : TTestObject;
begin
   WriteLn('** Testing general set algorithms...');
   
   set3 := nil;
   set4 := nil;
   set1.Clear;
   set2.Clear;
   set1.Repeateditems := true;
   set2.Repeateditems := true;
   try
      { --------------------- SetUnion ------------------------ }
      for i := 1 to ITEMS_NUM do
      begin
         set1.Insert(TTestObject.Create(i));
         set2.Insert(TTestObject.Create(ITEMS_NUM + i));
      end;
      set3 := SetUnion(set1, set2);
      Test(set3.Size = 2*ITEMS_NUM, 'SetUnion', 'wrong size');
      Test(set1.Empty, 'SetUnion', 'set1 not empty');
      Test(set2.Empty, 'SetUnion', 'set2 not empty');
      StartSilentMode;
      for i := 1 to 2*ITEMS_NUM do
      begin
         obj := TTestObject.Create(i);
         Test(set3.Find(obj) <> nil, 'SetUnion', 'union not present');
         Test(set2.Find(obj) = nil, 'SetUnion', 'set2 present');
         Test(set1.Find(obj) = nil, 'SetUnion', 'set1 present');
         obj.Destroy;
      end;
      StopSilentMode;
      
      { --------------------- SetUnionCopy ------------------------ }
      set1.Clear;
      set2.Clear;
      for i := 1 to ITEMS_NUM do
      begin
         set1.Insert(TTestObject.Create(i));
         set2.Insert(TTestObject.Create(ITEMS_NUM + i));
      end;
      set4 := SetUnionCopy(set1, set2, Ttestobjectcopier.Create);
      Test(set4.Size = 2*ITEMS_NUM, 'SetUnionCopy', 'wrong size of the result');
      Test(set1.Size = ITEMS_NUM, 'SetUnionCopy', 'wrong size of set1');
      Test(set2.Size = ITEMS_NUM, 'SetUnionCopy', 'wrong size of set2');
      
      StartSilentMode;
      for i := 1 to 2*ITEMS_NUM do
      begin
         obj := TTestObject.Create(i);
         Test(set4.Find(obj) <> nil, 'SetUnionCopy (result)');
         obj.Destroy;
      end;
      for i := 1 to ITEMS_NUM do
      begin
         obj := TTestObject.Create(i);
         Test(set1.Find(obj) <> nil, 'SetUnionCopy (set1)');
         obj.Destroy;
      end;
      for i := ITEMS_NUM + 1 to 2*ITEMS_NUM do
      begin
         obj := TTestObject.Create(i);
         Test(set2.Find(obj) <> nil, 'SetUnionCopy (set2)');
         obj.Destroy;
      end;
      StopSilentMode;
      
      { ---------------------- SetIntersection ----------------------- }
      set1.Clear;
      set2.Clear;
      for i := 1 to ITEMS_NUM div 10 do
      begin
         set1.Insert(TTestObject.Create(-i));
         set2.Insert(TTestObject.Create(-i));
      end;
      for i := 1 to ITEMS_NUM do
      begin
         set1.Insert(TTestObject.Create(i));
         set2.Insert(TTestObject.Create(ITEMS_NUM + i));
      end;
      
      StartDestruction(set3.Size, 'destructor');
      set3.Free;
      FinishDestruction;
      
      set3 := nil;
      set3 := SetIntersection(set1, set2);
      Test(set3.Size = 2*(ITEMS_NUM div 10), 'SetIntersection', 'wrong size of intersection');
      
      StartDestruction(ITEMS_NUM div 10, 'Unique');
      Unique(set3.Start, set3.Size, Ttestobjectcomparer.Create);
      FinishDestruction;
      
      Test(set3.Size = ITEMS_NUM div 10, 'SetIntersection', 'wrong size of intersection');
      StartSilentMode;
      WriteLn('(1)');
      for i := 1 to ITEMS_NUM div 10 do
      begin
         obj := TTestObject.Create(-i);
         Test(set3.Find(obj) <> nil, 'SetIntersection',
              'intersection not present');
         Test(set2.Find(obj) = nil, 'SetIntersection', 'set2 present');
         Test(set1.Find(obj) = nil, 'SetIntersection', 'set1 present');
         obj.Destroy;
      end;
      WriteLn('(2)');
      for i := 1 to ITEMS_NUM do
      begin
         obj := TTestObject.Create(i);
         Test(set3.Find(obj) = nil, 'SetIntersection',
              'intersection present');
         Test(set2.Find(obj) = nil, 'SetIntersection', 'set2 present');
         Test(set1.Find(obj) <> nil, 'SetIntersection', 'set1 not present');
         obj.Destroy;
      end;
      WriteLn('(3)');
      for i := ITEMS_NUM + 1 to 2*ITEMS_NUM do
      begin
         obj := TTestObject.Create(i);
         Test(set3.Find(obj) = nil, 'SetIntersection',
              'intersection present');
         Test(set2.Find(obj) <> nil, 'SetIntersection', 'set2 not present');
         Test(set1.Find(obj) = nil, 'SetIntersection', 'set1 present');
         obj.Destroy;
      end;
      StopSilentMode;

   finally
      if set4 <> nil then
      begin
         StartDestruction(set4.Size, 'set4.Destroy');
         set4.Destroy;
         FinishDestruction;
      end;
      if set3 <> nil then
      begin
         StartDestruction(set3.Size, 'set3.Destroy');
         set3.Destroy;
         FinishDestruction;
      end;
   end;

   WriteLn('** Finished testing general set algorithms.');
end;

end.
