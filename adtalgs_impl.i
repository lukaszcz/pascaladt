{@discard
 
  This file is a part of the PascalAdt library, which provides
  commonly used algorithms and data structures for the FPC and Delphi
  compilers.
  
  Copyright (C) 2004, 2005 by Lukasz Czajka
  
  This library is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of the
  License, or (at your option) any later version.
  
  This library is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
  
  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
  USA }

{@discard
 adtalgs_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtalgs.defs
&include adtalgs_impl.mcp

&define TForwardIteratorPair T&_mcp_prefix&ForwardIteratorPair
&define Projection &_mcp_prefix&Projection


{ ---------------------- helper functions --------------------------- }

procedure InsertionSortAux(start : TRandomAccessIterator; si, fi : IndexType;
                           comparer : IBinaryComparer); overload;
var
   i, j : IndexType;
begin
   i := si + 1;
   
   while i < fi do
   begin
      j := i;
      while (j > si) and (_mcp_gt(start[j - 1], start[j], comparer)) do
      begin
         start.ExchangeItemsAt(j - 1, j);
         Dec(j);
      end;
      Inc(i);
   end;   
end;

function PartitionAux(start : TRandomAccessIterator; si, fi : IndexType;
                      pred : IUnaryPredicate) : IndexType; overload;
begin
   Dec(fi);   
   while si <> fi do
   begin
      while (si <> fi) and pred.Test(start[si]) do
         Inc(si);
      
      while (si <> fi) and (not pred.Test(start[fi])) do
         Dec(fi);
      
      if (si <> fi) then
         start.ExchangeItemsAt(si, fi);
   end;
   
   if pred.Test(start[fi]) then
      Inc(fi);

   Result := fi;
end;


{ =========================== iterators ================================ }

{ ----------------------- TInserterBase --------------------------- }

function TInserterBase.GetItem : ItemType; 
begin
   Result := DefaultItem; { for the compiler not to complain }
   raise EAssertionFailed.Create(msgInvalidIterator);
end;

procedure TInserterBase.SetItem(aitem : ItemType); 
begin
   raise EAssertionFailed.Create(msgInvalidIterator);
end;

procedure TInserterBase.ExchangeItem(iter : TIterator); 
begin
   raise EAssertionFailed.Create(msgInvalidIterator);
end;

{ ------------------------- TInserter ----------------------------------- }

constructor TInserter.Create(apos : TForwardIterator);
begin
   inherited Create(apos.Owner);
   FPos := apos;
   FOwner := FPos.Owner;
end;

function TInserter.CopySelf : TIterator; 
begin
   Result := TInserter.Create(FPos);
end;

function TInserter.Equal(const Pos : TIterator) : Boolean; 
begin
   if pos is TInserter then
      Result := TInserter(pos).FPos.Equal(FPos)
   else
      Result:= FPos.Equal(pos);
end;

procedure TInserter.Write(aitem : ItemType); 
begin
   FPos.Insert(aitem);
   FPos.Advance;
end;

function TInserter.GetItem : ItemType; 
begin
   Result := FPos.GetItem;
end;

procedure TInserter.SetItem(aitem : ItemType);
begin
   FPos.SetItem(aitem);
end;

procedure TInserter.ExchangeItem(iter : TIterator); 
begin
   if iter is TInserter then
      FPos.ExchangeItem(TInserter(iter).FPos)
   else
      FPos.ExchangeItem(iter);
end;

function TInserter.Owner : TContainerAdt; 
begin
   { Note: We cannot simply return FPos.Owner because this method may
     be called from the destructor to obtain the grabage collector.
     This means that, if the destructor was called from the grabage
     collector, FPos might have been destroyed earlier! We therefore
     have to store the owner separately in a field.  }
   Result := FOwner;
end;
      
{ ------------------------ TBasicInserter -------------------------------- }

constructor TBasicInserter.Create(cont : TContainerAdt);
begin
   inherited Create(cont);
   FCont := cont;
end;

function TBasicInserter.CopySelf : TIterator; 
begin
   Result := TBasicInserter.Create(FCont);
end;

function TBasicInserter.Equal(const Pos : TIterator) : Boolean; 
begin
   Result := (pos is TBasicInserter) and (TBasicInserter(pos).FCont = FCont);
end;

procedure TBasicInserter.Write(aitem : ItemType); 
begin
   if not FCont.InsertItem(aitem) then
      raise EPascalAdt.Create('TBasicInserter: Cannot insert');
end;

function TBasicInserter.Owner : TContainerAdt; 
begin
   Result := FCont;
end;

{ ----------------------- TBackInserter ---------------------------- }

constructor TBackInserter.Create(cont : TQueueAdt);
begin
   inherited Create(cont);
   FCont := cont;
end;

function TBackInserter.CopySelf : TIterator; 
begin
   Result := TBackInserter.Create(FCont);
end;

function TBackInserter.Equal(const Pos : TIterator) : Boolean; 
begin
   Result := (pos is TBackInserter) and (TBackInserter(pos).FCont = FCont);
end;

procedure TBackInserter.Write(aitem : ItemType); 
begin
   FCont.PushBack(aitem);
end;

function TBackInserter.Owner : TContainerAdt; 
begin
   Result := FCont;
end;

{ ---------------------- TFrontInserter ------------------------------ }

constructor TFrontInserter.Create(cont : TDequeAdt);
begin
   inherited Create(cont);
   FCont := cont;
end;

function TFrontInserter.CopySelf : TIterator; 
begin
   Result := TFrontInserter.Create(FCont);
end;

function TFrontInserter.Equal(const Pos : TIterator) : Boolean; 
begin
   Result := (pos is TFrontInserter) and (TFrontInserter(pos).FCont = FCont);
end;

procedure TFrontInserter.Write(aitem : ItemType); 
begin
   FCont.PushFront(aitem);
end;

function TFrontInserter.Owner : TContainerAdt; 
begin
   Result := FCont;
end;


{ ======================= non-modifying algorithms ============================ }

{ ------------------------- searching ------------------------------------ }

function Find(const start, finish : TForwardIterator;
              aitem : ItemType; const comparer : IBinaryComparer) : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   Result := CopyOf(start);
   while (not Result.Equal(finish)) and
            (not _mcp_equal(Result.Item, aitem, comparer)) do
   begin
      Result.Advance;
   end;
end;

function Find(const start, finish : TForwardIterator;
              const pred : IUnaryPredicate) : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   Result := CopyOf(start);
   while not (Result.Equal(finish) or pred.Test(Result.Item)) do
   begin
      Result.Advance;
   end;
end;

{ ----------------------- other ------------------------------------- }

function Count(const start, finish : TForwardIterator;
               const pred : IUnaryPredicate) : SizeType;
var
   iter : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   Result := 0;
   iter := CopyOf(start);
   while not iter.Equal(finish) do
   begin
      if pred.Test(iter.Item) then
         Inc(Result);
      iter.Advance;
   end;
   iter.Destroy;
end;

function Minimal(const start, finish : TForwardIterator;
                 const comparer : IBinaryComparer) : TForwardIterator;
var
   iter : TForwardIterator;
   minptr, aitem : ItemType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   if start.Equal(finish) then
   begin
      Result := CopyOf(finish);
      Exit;
   end;
   
   Result := CopyOf(start);
   minptr := Result.Item;
   iter := Next(start);
   while not iter.Equal(finish) do
   begin
      aitem := iter.Item;
      if _mcp_lt(aitem, minptr, comparer) then
      begin
         minptr := aitem;
         Result.Destroy;
         Result := CopyOf(iter);
      end;
      iter.Advance;
   end;
end;

function Maximal(const start, finish : TForwardIterator;
                 const comparer : IBinaryComparer) : TForwardIterator;
var
   iter : TForwardIterator;
   maxptr, aitem : ItemType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   if start.Equal(finish) then
   begin
      Result := CopyOf(finish);
      Exit;
   end;
   
   Result := CopyOf(start);
   maxptr := Result.Item;
   iter := Next(start);
   while not iter.Equal(finish) do
   begin
      aitem := iter.Item;
      if _mcp_gt(aitem, maxptr, comparer) then
      begin
         maxptr := aitem;
         Result.Destroy;
         Result := CopyOf(iter);
      end;
      iter.Advance;
   end;
end;

function Equal(const start1, finish1, start2 : TForwardIterator;
               const pred : IBinaryPredicate) : Boolean;
var
   iter1, iter2 : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
{$endif }

   REsult := false;
   iter1 := CopyOf(start1);
   iter2 := CopyOf(start2);
   while not iter1.Equal(finish1) do
   begin
      if not pred.Test(iter1.Item, iter2.Item) then
      begin
         iter1.Destroy;
         iter2.Destroy;
         Exit;
      end;
      iter1.Advance;
      iter2.Advance;
   end;
   iter1.Destroy;
   iter2.Destroy;
   Result := true;
end;

function Mismatch(const start1, finish1, start2 : TForwardIterator;
                  const pred : IBinaryPredicate) : TForwardIteratorPair;
var
   iter1, iter2 : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
{$endif }

   iter1 := CopyOf(start1);
   iter2 := CopyOf(start2);
   while not iter1.Equal(finish1) do
   begin
      if not pred.Test(iter1.Item, iter2.Item) then
         break;
      iter1.Advance;
      iter2.Advance;
   end;
   Result := TForwardIteratorPair.Create(iter1, iter2);
end;

function LexicographicalCompare(const start1, finish1,
                                start2, finish2 : TForwardIterator;
                                const comparer : IBinaryComparer) : Integer;
var
   iter1, iter2 : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
   CheckIteratorRange(start2, finish2);
{$endif }

   Result := 0;
   iter1 := CopyOf(start1);
   iter2 := CopyOf(start2);
   while (not iter1.Equal(finish1)) and (not iter2.Equal(finish2)) and
            (Result = 0) do
   begin
      _mcp_compare_assign(iter1.Item, iter2.Item, Result, comparer);
      iter1.Advance;
      iter2.Advance;
   end;
   if Result = 0 then
   begin
      if iter1.Equal(finish1) then
      begin
         if not iter2.Equal(finish2) then
            Result := -1;
      end else
      begin
         Result := +1;
      end;
   end;
   iter1.Destroy;
   iter2.Destroy;
end;


{ ======================= modifying algorithms ============================ }

procedure ForEach(start, finish : TForwardIterator;
                  const funct : IUnaryFunctor);
var
   owner : TContainerAdt;
   owns : Boolean;
   iter : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   iter := CopyOf(start);
   owner := start.Owner; 
   owns := owner.OwnsItems;
   owner.OwnsItems := false;
   try
      while not iter.Equal(finish) do
      begin
         iter.SetItem(funct.Perform(iter.GetItem));
         iter.Advance;
      end;
   finally
      owner.OwnsItems := owns;
      start.Destroy;
   end;
end;

procedure Generate(start, finish : TForwardIterator;
                   const funct : IUnaryFunctor);
var
   iter : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   iter := CopyOf(start);
   while not iter.Equal(finish) do
   begin
      iter.SetItem(funct.Perform(iter.GetItem));
      iter.Advance;
   end;
end;

procedure Copy(const start1, finish1 : TForwardIterator;
               start2 : TOutputIterator;
               const itemCopier : IUnaryFunctor);
var
   iter : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
{$endif }

   iter := CopyOf(start1);
   while not iter.Equal(finish1) do
   begin
      start2.Write(itemCopier.Perform(iter.Item));
      iter.Advance;
   end;
   iter.Destroy;
end;

procedure Move(start1, finish1, start2 : TForwardIterator);
var
   owns : Boolean;
   owner : TContainerAdt;
   iter, fstart2 : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
{$endif }
   
   if start1.Owner <> start2.Owner then
   begin
      iter := CopyOf(start1);
      while not iter.Equal(finish1) do
      begin
         start2.Insert(iter.Item);
         start2.Advance;
         iter.Advance;
      end;
      iter.Destroy;

      owner := start1.Owner;
      owns := owner.OwnsItems;
      owner.OwnsItems := false;
      try
         start1.Delete(finish1);
      finally
         owner.OwnsItems := owns;
      end;
   end else { not start1.Owner <> start2.Owner }
   begin
      Assert(start2 is TForwardIterator);
      
      fstart2 := TForwardIterator(start2);
      if Less(start1, fstart2) then
      begin
         if finish1.Equal(fstart2) then
            Exit;
         Assert(Less(finish1, fstart2), msgMovingBadRange);
         
         if start1 is TBidirectionalIterator then
         begin
            Assert((fstart2 is TBidirectionalIterator) and
                      (finish1 is TBidirectionalIterator));
            iter := CopyOf(fstart2);
            Retreat(TBidirectionalIterator(iter), Distance(start1, finish1));
         end else
         begin
            iter := CopyOf(start1);
            Advance(iter, Distance(finish1, fstart2));
         end;
         
         Rotate(start1, iter, fstart2);
         
      end else { not Less(start1, fstart2) }
      begin
         if start1.Equal(fstart2) then
            Exit;
         
         if start1 is TBidirectionalIterator then
         begin
            Assert((fstart2 is TBidirectionalIterator) and
                      (finish1 is TBidirectionalIterator));
            iter := CopyOf(finish1);
            Retreat(TBidirectionalIterator(iter), Distance(fstart2, start1));
         end else
         begin
            iter := CopyOf(fstart2);
            Advance(iter, Distance(start1, finish1));
         end;
         
         Rotate(fstart2, iter, finish1);
      end;
   end; { end not start1.Owner <> start2.Owner }
end;

procedure Combine(const start1, finish1, start2 : TForwardIterator;
                  start3 : TOutputIterator; const itemJoiner : IBinaryFunctor);
var
   iter1, iter2 : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
{$endif }

   iter1 := CopyOf(start1);
   iter2 := CopyOf(start2);
   while not iter1.Equal(finish1) do
   begin
      start3.Write(itemJoiner.Perform(iter1.Item, iter2.Item));
      iter1.Advance;
      iter2.Advance;
   end;
   iter1.Destroy;
   iter2.Destroy;
end;

{ ===================== mutating algorithms ======================== }

{ ---------------------- sorting -------------------------- }

procedure Sort(start, finish : TRandomAccessIterator;
               const comparer : IBinaryComparer);
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   if finish.Index - start.Index <= qsMinItems then
      InsertionSort(start, finish, comparer)
   else
      QuickSort(start, finish, comparer);
end;

procedure StableSort(start, finish : TRandomAccessIterator;
                     const comparer : IBinaryComparer);
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   if finish.Index - start.Index <= msMinItems then
      InsertionSort(start, finish, comparer)
   else
      MergeSort(start, finish, comparer);
end;

procedure QuickSort(start, finish : TRandomAccessIterator;
                    const comparer : IBinaryComparer);
var
   pi, si, fi, starti, finishi : IndexType;
   stack : TDynamicArray;
   predi : IUnaryPredicate;
   pred : TLessBinder;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   starti := start.Index;
   finishi := finish.Index;
   si := 0;
   fi := finishi - starti;
   
   ArrayAllocate(stack, CeilLog2(fi - si), 0); { may raise }
   
   try
      pred := nil;
      pred := TLessBinder.Create(comparer, DefaultItem); { may raise }
      predi := pred;
      
      ArrayPushBack(stack, ItemType(si)); { may raise }
      ArrayPushBack(stack, ItemType(fi));
      
      while stack^.Size <> 0 do
      begin
         fi := IndexType(ArrayPopBack(stack));
         si := IndexType(ArrayPopBack(stack));
         
         while fi - si >= qsMinItems do
         begin
            pi := Random(fi - si) + si;
            pred.Item := start[pi];
            { save the pivot }
            start.ExchangeItemsAt(si, pi);
            pi := PartitionAux(start, si + 1, fi, predi);
            { move the saved pivot to its proper position }
            start.ExchangeItemsAt(si, pi - 1);
            { this if-statement is essential to have an O(log(n))
              memory complexity }
            if pi - 1 - si < fi - pi then
            begin
               ArrayPushBack(stack, ItemType(pi)); { may raise }
               ArrayPushBack(stack, ItemType(fi));
               { we should not consider the position pi - 1 any more
                 since the item at that position is at its proper
                 position }
               fi := pi - 1;
            end else
            begin
               ArrayPushBack(stack, ItemType(si));
               ArrayPushBack(stack, ItemType(pi - 1));
               si := pi;
            end;
         end; { end while fi - si }
         
         { insertion-sort is performed at the very end for the whole
           range }
         
      end; { end while stack }
      
   finally
      ArrayDeallocate(stack);
   end;
   
   { now use InsertionSort to sort small groups that have remained
     unsorted; InsertionSort will work very fast because it has only
     groups with maximally qsMinItems to sort; }
   InsertionSort(start, finish, comparer);
end;

procedure MergeSort(start, finish : TRandomAccessIterator;
                    const comparer : IBinaryComparer);
var
   buffer : array of ItemType;
   fi, i, j, k, m : IndexType;
   n : SizeType;
   owner : TContainerAdt;
   invalidContainer, owns : boolean;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   owner := start.Owner;
   owns := owner.OwnsItems;
   owner.OwnsItems := false;

   invalidContainer := false;
   fi := finish.Index - start.Index;
   try
      SetLength(buffer, fi);
      n := 1; { the length of each of the sequences already sorted }
      while n < fi do
      begin
         i := 0;
         while i + n < fi do
         begin
            j := i;
            k := i + n;
            m := i;
            while (j < i + n) and (k < fi) and (k < i + 2*n) do
            begin
               if _mcp_lte(start[j], start[k], comparer) then
               begin
                  buffer[m] := start[j];
                  Inc(j);
               end else
               begin
                  buffer[m] := start[k];
                  Inc(k);
               end;
               Inc(m);
            end; { end while end of sequence not reached }
            
            while j < i + n do
            begin
               buffer[m] := start[j];
               Inc(j);
               Inc(m);
            end;

            while (k < i + 2*n) and (k < fi) do
            begin
               buffer[m] := start[k];
               Inc(k);
               Inc(m);
            end;
            
            i := i + 2*n;
         end; { end while i + n < fi }
         { copy the tail }
         while i < fi do
         begin
            buffer[i] := start[i];
            Inc(i);
         end;
         n := 2*n;
         
         invalidContainer := true; { exception handling }
         if n < fi then
         begin
            { now merge the sequences in the buffer and put them into
              the proper array }
            i := 0;
            while i + n < fi do
            begin
               j := i;
               k := i + n;
               m := i;
               while (j < i + n) and (k < fi) and (k < i + 2*n) do
               begin
                  if _mcp_lte(buffer[j], buffer[k], comparer) then
                  begin
                     start[m] := buffer[j];
                     Inc(j);
                  end else
                  begin
                     start[m] := buffer[k];
                     Inc(k);
                  end;
                  Inc(m);
               end; { end while end of sequence not reached }
               
               while j < i + n do
               begin
                  start[m] := buffer[j];
                  Inc(j);
                  Inc(m);
               end;

               while (k < i + 2*n) and (k < fi) do
               begin
                  start[m] := buffer[k];
                  Inc(k);
                  Inc(m);
               end;
               
               i := i + 2*n;
            end; { end while i + n < fi }
            { copy the tail }
            while i < fi do
            begin
               start[i] := buffer[i];
               Inc(i);
            end;
            n := 2*n;
            
         end else
         begin
            { copy items from the buffer to the container }
            for i := 0 to fi - 1 do
               start[i] := buffer[i];
         end; { end not if n < fi }
         invalidContainer := false;
      end; { end while n < fi }
      
   finally
      if invalidContainer then
      begin
         { the exception was raised in the second part of the loop
           when items are copied from the buffer to the container;
           just copy all of them back into the container not to leak
           anything }
         for i := 0 to fi - 1 do
            start[i] := buffer[i];
      end;
      owner.OwnsItems := owns;
   end;
end;

procedure ShellSort(start, finish : TRandomAccessIterator;
                    const comparer : IBinaryComparer);
var
   n, k, i, j : IndexType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   n := finish.Index - start.Index;
   k := n div 2;
   while k <> 0 do
   begin
      for i := k to n - 1 do
      begin
         j := i;
         while j - k >= 0 do
         begin
            if _mcp_gt(start[j - k], start[j], comparer) then
            begin
               start.ExchangeItemsAt(j - k, j);
               j := j - k;
            end else
               break;
         end;
      end;
      k := k div 2;
   end;
end;

procedure InsertionSort(start, finish : TBidirectionalIterator;
                        const comparer : IBinaryComparer);
var
   iter, iter2, iter3 : TBidirectionalIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   if start is TRandomAccessIterator then
   begin
      Assert(finish is TRandomAccessIterator);
      InsertionSort(TRandomAccessIterator(start), TRandomAccessIterator(finish),
                    comparer);
   end;
   
   iter := CopyOf(start);
   
   iter2 := CopyOf(iter);
   iter.Advance;
   iter3 := CopyOf(iter);
   
   while not iter.Equal(finish) do
   begin
      while _mcp_gt(iter2.Item, iter3.Item, comparer) do
      begin
         iter2.ExchangeItem(iter3);
         iter3.Retreat;
         if iter3.Equal(start) then
            break;
         iter2.Retreat;
      end;
      
      iter2.Destroy;
      iter3.Destroy;
      
      iter2 := CopyOf(iter);
      iter.Advance;
      iter3 := CopyOf(iter);
   end;
   iter.Destroy;
end;

procedure InsertionSort(start, finish : TRandomAccessIterator;
                        const comparer : IBinaryComparer);
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   InsertionSortAux(start, 0, finish.Index - start.Index, comparer);
end;

{ ------------------- other mutating algorithms -------------------------- }

procedure Rotate(start, newstart, finish : TForwardIterator);
var
   src, dest, finsrc, findest : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
   CheckIteratorRange(start, newstart);
   CheckIteratorRange(newstart, finish);
{$endif }
   
   if start.Equal(newstart) or newstart.Equal(finish) then
      Exit;

   src := nil; { will be set in the loop }
   dest := CopyOf(newstart);  
//   newstart := CopyOf(newstart);
//   finish := CopyOf(finish);
   findest := CopyOf(finish);
   finsrc := CopyOf(newstart);
   start := CopyOf(start); { start of source }
   
   repeat
      { First, we swap the source as many times as possible with
        subsequent destination blocks. We shall call a block any
        physically continuous group of items. For clarity, we assume
        that the number of the situation is like in the picture below,
        but the algorithm may be easily generalised.  }
      {   +--------+                    }
      {(5)| size m | <- remaining dest block (size m < n) }
      {   |--------| ]                  }
      {(4)| size n | ]                  }
      {   |--------| ]                  }
      {(3)| size n | ]-> destinations blocks (all size n)  }
      {   |--------| ]                  }
      {(2)| size n | ]                  }
      {   |--------| <- newstart        }
      {(1)|*size*n*| <- the first source block (size n) }
      {   +--------+                    }
      { We first swap (1) with (2). Then, (2) is where (1) used to be,
        and we swap it with (3), and so on. Having swapped block (4),
        the remaining dest block contains less items than the source
        block (m < n), and the blocks (1) to (3) are now at their
        proper positions (i.e. one block up) and (4) is at the very
        bottom of the table. So, we swap m items from (4) with the
        block (5). Now, only the items in [start, newstart) are in
        wrong order. We have the following: }
      {    |   ...   |                }
      {    | ordered |                }
      {    +---------+ <- old newstart; logical array end }
      {    |         | ]              }
      {    | size n-m| ]-> source     }
      {    |---------| <- start       }
      { (5)| size m  | -> dest        }
      {    +---------+                }
      { We simply apply the algorithm recursively by setting the
        variables as shown above. The only peculiarity is that we have
        to make the array wrap around, since the destination is
        logically above the source. Logically, the range we operate on
        should be treated as circular, but we set several additional
        variables to avoid the necessity of checking the end of the
        physical range and make iterators go 'wrapping around'. }
      repeat
         src.Free;
         src := CopyOf(start);
         while not (dest.Equal(findest) or src.Equal(finsrc)) do
         begin
            src.ExchangeItem(dest);
            src.Advance;
            dest.Advance;
{            if src.Equal(finish) then
            begin
               src.Destroy;
               src := CopyOf(start);
            end;
            if dest.Equal(finish) then
            begin
               dest.Destroy;
               dest := CopyOf(start);
            end;}
         end;
      until dest.Equal(findest);

      if src.Equal(finsrc) then
         break;

//      finish.Destroy;
//      finish := CopyOf(finsrc);
      { finsrc remains the same }
      { src remains the same }
      findest.Destroy;
      findest := CopyOf(src);
      dest.Destroy;
      dest := CopyOf(start);
      start.Destroy;
      start := CopyOf(src);
   until src.Equal(dest);
   src.Destroy;
   dest.Destroy;  
//   newstart.Destroy;
//   finish.Destroy;
   findest.Destroy;
   finsrc.Destroy;
end;

procedure Reverse(start, finish : TBidirectionalIterator);
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   while not start.Equal(finish) do
   begin
      finish.Retreat;
      if start.Equal(finish) then
         break
      else begin
         start.ExchangeItem(finish);
         start.Advance;
      end;
   end;
end;

procedure RandomShuffle(start, finish : TRandomAccessIterator);
var
   i, fi : IndexType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   fi := finish.Index - start.Index;
   for i := 0 to fi - 1 do
   begin
      start.ExchangeItemsAt(i, Random(i) + 1);
   end;
end;

function Partition(start, finish : TBidirectionalIterator;
                   const pred : IUnaryPredicate) : TBidirectionalIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   if start is TRandomAccessIterator then
   begin
      Result := TBidirectionalIterator(Partition(TRandomAccessIterator(start),
                                                 TRandomAccessIterator(finish),
                                                 pred));
      Exit;
   end;
   
   start := CopyOf(start);
   Result := CopyOf(finish);
   Result.Retreat;
   
   while not start.Equal(Result) do
   begin
      while (not start.Equal(Result)) and pred.Test(start.Item) do
      begin
         start.Advance;
      end;
      
      while not (start.Equal(Result) or pred.Test(Result.Item)) do
      begin
         Result.Retreat;
      end;
      
      start.ExchangeItem(Result);
   end;
   
   start.Destroy;
   
   if pred.Test(Result.Item) then
      Result.Advance;
end;

function Partition(start, finish : TRandomAccessIterator; 
                   const pred : IUnaryPredicate) : TRandomAccessIterator;
var
   i : IndexType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   i := PartitionAux(start, 0, finish.Index - start.Index, pred);
   
   Result := CopyOf(start);
   Result.Advance(i);
end;

function StablePartition(start, finish : TForwardIterator;
                         const pred : IUnaryPredicate) : TForwardIterator;
var
   a1, a2 : TDynamicArray;
   owns : Boolean;
   iter : TForwardIterator;
   aitem : ItemType;
   i : IndexType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }

   a1 := nil;
   a2 := nil;
   
   owns := start.Owner.OwnsItems;
   start.Owner.OwnsItems := false;
   
   iter := nil; a1 := nil; a2 := nil;
   try
      ArrayAllocate(a1, 100, 0);
      ArrayAllocate(a2, 100, 0);
      iter := CopyOf(start);

      while not iter.Equal(finish) do
      begin
         aitem := iter.Item;
//         WriteLn(TTestObject(aitem).Value);
         if pred.Test(aitem) then
            ArrayPushBack(a1, aitem) { may raise }
         else
            ArrayPushBack(a2, aitem); { may raise }
         iter.Advance;
      end;
      iter.Free;
      iter := CopyOf(start);
      
//      WriteLn;
      for i := 0 to a1^.Size - 1 do
      begin
//         WriteLn(TTestObject(a1^.Items[i]).Value);
         iter.SetItem(a1^.Items[i]);
         iter.Advance;
      end;
//      WriteLn;
      
      Result := CopyOf(iter);
      
      for i := 0 to a2^.Size - 1 do
      begin
//         WriteLn(TTestObject(a2^.Items[i]).Value);
         iter.SetItem(a2^.Items[i]);
         iter.Advance;
      end;

   finally
      ArrayDeallocate(a1);
      ArrayDeallocate(a2);
      iter.Free;
      start.Owner.OwnsItems := owns;
   end;
end;

function MemoryEfficientStablePartition(
   start, finish : TForwardIterator;
   const pred : IUnaryPredicate) : TForwardIterator;
var
   prev, iter, iter2, iter3, iter4 : TForwardIterator;
   size, n : SizeType;
   i : IndexType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   if start.Equal(finish) then
   begin
      Result := CopyOf(finish);
      Exit;
   end;

   { make a preliminary pass 'sorting' 2-element sequences; when we
     'sort' we consider the items for which pred is true to come
     before those for which pred is false }
   prev := CopyOf(start);
   iter := Next(start);
   size := 1; { the size of the range }
   while not iter.Equal(finish) do
   begin
      if (not pred.Test(prev.Item)) and (pred.Test(iter.Item)) then
      begin
         prev.ExchangeItem(iter);
      end;
      prev.Advance;
      iter.Advance;
      Inc(size);
      if not iter.Equal(finish) then
      begin
         prev.Advance;
         iter.Advance;
         Inc(size);
      end;
   end;
   iter.Destroy;
   prev.Destroy;
   
   { in each pass merge two adjacent already 'sorted' sequences of
     size n into a sequence of size 2*n }
   n := 2; { the length of already 'sorted' sequences }
   while n < size do
   begin
      iter := CopyOf(start);
      while not iter.Equal(finish) do
      begin
         { Now, set the following iterators accordingly: }
         { iter - the first item for which pred does not hold }
         { iter2 - the first item after iter for which pred holds }
         { iter3 - the first item after iter2 for which pred does not
           hold }
         { iter4 - the new position of iter }
         i := n;
         while (i > 0) and (not iter.Equal(finish)) and pred.Test(iter.Item) do
         begin
            Dec(i);
            iter.Advance;
         end;
         iter2 := CopyOf(iter);
         i := i + n;
         while (i > 0) and (not iter2.Equal(finish)) and
                  (not pred.Test(iter2.Item)) do
         begin
            Dec(i);
            iter2.Advance;
         end;
         iter3 := CopyOf(iter2);
         iter4 := CopyOf(iter);
         while (i > 0) and (not iter3.Equal(finish)) and pred.Test(iter3.Item) do
         begin
            Dec(i);
            iter3.Advance;
            iter4.Advance;
         end;
         { move the group of items in sequence 2 for which pred holds
           before the group of items in sequence 1 for which pred does
           not hold }
         Rotate(iter, iter4, iter3);
         
         iter.Destroy;
         iter := iter3;
         while (i > 0) and (not iter.Equal(finish)) do
         begin
            Dec(i);
            iter.Advance;
         end;
         
         if 2*n >= size then
         begin
            Result := CopyOf(iter4);
         end;
         iter2.Destroy;
         iter4.Destroy;
      end; { end while not iter.Equal(finish) }
      n := n*2;
   end; { end while n <> size }
   
   if size <= 2 then
   begin
      Result := CopyOf(start);
      while (not Result.Equal(finish)) and pred.Test(Result.Item) do
         Result.Advance;
   end;
end; { end MemoryEfficientStablePartition }

function FindKthItem(start, finish : TRandomAccessIterator; k : SizeType;
                     const comparer : IBinaryComparer) : ItemType;
var
   predi : IUnaryPredicate;
   pred : TLessBinder;

   { kk is the relative index from si (i.e. starting from 0, not 1) of the
     item to find if the sequence were sorted }
   function FindAux(si, fi : IndexType; kk : SizeType) : ItemType;
   var
      i, j, pi : IndexType;
   begin
      while fi - si >= BfptrMinSize do
      begin
         { divide the range into 5-element sequences and sort these
           sequences separately; create a sequence of medians of these
           5-element sequences }
         i := si; j := si;
         while i + 5 <= fi do
         begin
            InsertionSortAux(start, i, i + 5, comparer);
            start.ExchangeItemsAt(j, i + 2);
            j := j + 1;
            i := i + 5;
         end;
         if i <> fi then
         begin
            InsertionSortAux(start, i, fi, comparer);
            start.ExchangeItemsAt(j, (fi + i) div 2);
            j := j + 1;
         end;
         { now, find the (j div 2)-th element in the sequence of
           medians; i.e. the median of medians }
         pred.Item := FindAux(si, j, (j - si) div 2);
         { at least 1/4 of all items are < m and at least 1/4 items
           are >= m }
         pi := PartitionAux(start, si, fi, predi);
         { we have to create three sequences: items < pred.Item; items
           = pred.Item; items > pred.Item; this is essential if we want
           to achieve O(n) worst-case time with repeated items }
         { pi - the first item >= pred.Item }
         j := pi; { j - will be the first item > pred.Item }
         i := pi;
         while i <> fi do
         begin
            if _mcp_equal(start[i], pred.Item, comparer) then
            begin
               start.ExchangeItemsAt(i, j);
               Inc(j);
            end;
            Inc(i);
         end;
         
         if si + kk < pi then
            fi := pi
         else if (si + kk >= pi) and (si + kk < j) then
         begin
            Result := pred.Item;
            Exit;
         end else { if si + kk >= j then }
         begin
            kk := kk + si - j;
            si := j;
         end;
      end; { end while fi - si >= ... }
      
      Result := FindKthItemHoare(Next(start, si),
                                 Next(start, fi), kk + 1, comparer)
   end; { end FindAux }
   
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   Assert((k <= finish.Index - start.Index) and (k > 0));
   
   pred := TLessBinder.Create(comparer, DefaultItem);
   predi := pred;
   Result := FindAux(0, finish.Index - start.Index, k - 1);
end;

function FindKthItemHoare(start, finish : TRandomAccessIterator; k : SizeType;
                          const comparer : IBinaryComparer) : ItemType;
var
   si, fi, pi : IndexType; { start, finish and pivot relative indices }
   pred : TLessBinder;
   predi : IUnaryPredicate;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   Result := DefaultItem;
   
   si := 0;
   fi := finish.Index - start.Index;
   
   Assert((k <= finish.Index - start.Index) and (k > 0));
   
   pred := TLessBinder.Create(comparer, DefaultItem); { may raise }
   predi := pred;
   
   while si < fi do
   begin
      pi := Random(fi - si);
      pred.Item := start[si + pi];
      pi := PartitionAux(start, si, fi, pred); { may raise }
      { now pi is the index of the first item equal to
        pred.Item; bear in mind that k is index + 1 }
      if k < pi + 1 then
         fi := pi
      else if k > pi + 1 then
         si := pi
      else begin
        { k = pi + 1 (there are exactly pi items < pred.Item, so
          pi.Item is the k-th item) }
        Result := pred.Item;
        break;
      end;
   end;
end;


{ ======================== deleting algorithms =========================== }

function Delete(start : TForwardIterator; n : SizeType) : SizeType;
begin
   if start is TRandomAccessIterator then
   begin
      Result := TRandomAccessIterator(start).Delete(n);
   end else
   begin
      Result := n;
      while (n > 0) and not start.IsFinish do
      begin
         start.Delete;
         Dec(n);
      end;
      Result := Result - n;
   end;
end;

function DeleteIf(start : TForwardIterator; n : SizeType;
                  const pred : IUnaryPredicate) : SizeType;
var
   iter : TRandomAccessIterator;
   aitem : ItemType;
begin
   Result := 0;
   if start is TRandomAccessIterator then
   begin
      { for most random-access containers it is more efficient to
        delete items at once than to delete them one-by-one; hence,
        move first all the items to be deleted to the front and than
        delete them all at once }
      iter := TRandomAccessIterator(CopyOf(start));
      while (n > 0) and (not iter.IsFinish) do
      begin
         aitem := iter.Item;
         if pred.Test(aitem) then
         begin
            iter.Item := DefaultItem;
            Inc(Result);
         end else if Result <> 0 then
            iter.ExchangeItemsAt(0, -Result);
         iter.Advance(1);
         Dec(n);
      end;
      if Result <> 0 then
      begin
         iter.Advance(-Result);
         iter.Delete(Result);
      end;
      iter.Destroy;
   end else { not start is TRandomAccessIterator }
   begin
      while (n > 0) and (not start.IsFinish) do
      begin
         if pred.Test(start.Item) then
         begin
            start.Delete;
            Inc(Result);
         end else
            start.Advance;
         Dec(n);
      end;
   end;
end;

{ ======================= sorted range algorithms ============================ }

{ ---------------------- non-modifying sorted range -------------------------- }

function BinaryFind(const start, finish : TRandomAccessIterator; aitem : ItemType;
                    const comparer : IBinaryComparer) : TRandomAccessIterator;
var
   si, fi, i : IndexType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   si := 0;
   fi := finish.Index - start.Index;
   while fi - si > 2 do
   begin
      i := (fi + si) div 2;
      if _mcp_lte(aitem, start[i], comparer) then
         fi := i + 1
      else
         si := i + 1;
   end;
   
   if _mcp_equal(aitem, start[si], comparer) then
   begin
      Result := CopyOf(start);
      Result.Advance(si);
   end else if (fi - si > 1) and (_mcp_equal(aitem, start[si + 1], comparer)) then
   begin
      Result := CopyOf(start);
      Result.Advance(si + 1);
   end else
      Result := CopyOf(finish);
end;

function InterpolationFind(const start, finish : TRandomAccessIterator;
                           aitem : ItemType;
                           const diff : ISubtractor) : TRandomAccessIterator;
var
   si, fi, i, d : IndexType;
begin
&if (&ItemType != Real && &ItemType != Integer && &ItemType != Cardinal)
   Assert(diff <> nil);
&endif
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start, finish);
{$endif }
   
   si := 0;
   fi := finish.Index - start.Index;
   while fi - si > 1 do
   begin
&if (&_mcp_substractable)
      if diff <> nil then
      begin
&else
      Assert(diff <> nil, msgInvalidArgument);
&endif
         i := si + ( diff.Compare(aitem, start[si]) div
                        diff.Compare(start[fi - 1], start[si]) ) * (fi - 1 - si);
         d := diff.Compare(aitem, start[i]);
&if (&_mcp_substractable)
      end else
      begin
         i := si + (_mcp_diff(aitem, start[si]) div
                       _mcp_diff(start[fi - 1], start[si])) * (fi - 1 - si);
         d := _mcp_diff(aitem, start[si]);
      end;
&endif
      if (d = 0) and ((i = si) or not _mcp_equal(aitem, start[i - 1], diff)) then
      begin
         Result := CopyOf(start);
         Result.Advance(i);
         Exit;
      end else if d <= 0 then
         fi := i
      else
         si := i + 1;
   end;
   
   if _mcp_equal(aitem, start[si], diff) then
   begin
      Result := CopyOf(start);
      Result.Advance(si);
   end else
      Result := CopyOf(finish);
end;

{ ------------------------ modifying sorted range ---------------------------- }

function Unique(start : TForwardIterator; n : SizeType;
                const comparer : IBinaryComparer) : SizeType;
var
   aitem, aitem2 : ItemType;
   iter : TRandomAccessIterator;
begin
   Result := 0;
   if not start.IsFinish then
   begin
      if start is TRandomAccessIterator then
      begin
         iter := TRandomAccessIterator(CopyOf(start));
         aitem := iter.Item;
         iter.Advance(1);
         while (n > 0) and not iter.IsFinish do
         begin
            aitem2 := iter.Item;
            if not _mcp_equal(aitem2, aitem, comparer) then
            begin
               aitem := aitem2;
               if Result <> 0 then
                  iter.ExchangeItemsAt(0, -Result);
            end else
            begin
               iter.Item := DefaultItem;
               Inc(Result);
            end;
            iter.Advance(1);
            Dec(n);
         end;
         if Result <> 0 then
         begin
            iter.Advance(-Result);
            iter.Delete(Result);
         end;
         iter.Destroy;
      end else { not if start is TRandomAccessIterator }
      begin
         aitem := start.Item;
         start.Advance;
         while (n > 0) and not start.IsFinish do
         begin
            aitem2 := start.Item;
            if not _mcp_equal(aitem, aitem2, comparer) then
            begin
               aitem := aitem2;
               start.Advance;
            end else
            begin
               start.Delete;
               Inc(Result);
            end;
            Dec(n);
         end; { end while }
      end;
   end; { end if not start.IsFinish }
end;

{ ------------------------ mutating sorted range ----------------------------- }

procedure Merge(start1, finish1, start2, finish2 : TForwardIterator;
                output : TOutputIterator;
                const comparer : IBinaryComparer);
var
   aitem1, aitem2 : ItemType;
   owns1, owns2 : Boolean;
   s1, s2 : TForwardIterator;
   range1, range2 : SizeType;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
   CheckIteratorRange(start2, finish2);
{$endif }

   { numbers of items in the first and the second range, respectively }
   range1 := 0; 
   range2 := 0;
   
   s1 := CopyOf(start1);
   s2 := CopyOf(start2);
      
   while not (s1.Equal(finish1) or s2.Equal(finish2)) do
   begin
      aitem1 := s1.Item;
      aitem2 := s2.Item;
      if _mcp_lte(aitem1, aitem2, comparer) then
      begin
         output.Write(aitem1);
         s1.Advance;
         Inc(range1)
      end else
      begin
         output.Write(aitem2);
         s2.Advance;
         Inc(range2);
      end;
   end;
   
   while not s1.Equal(finish1) do
   begin
      output.Write(s1.Item);
      s1.Advance;
      Inc(range1);
   end;
   
   while not s2.Equal(finish2) do
   begin
      output.Write(s2.Item);
      s2.Advance;
      Inc(range2);
   end;
   s1.Free;
   s2.Free;
      
   owns1 := start1.Owner.OwnsItems;
   owns2 := start2.Owner.OwnsItems;
   start1.Owner.OwnsItems := false;
   start2.Owner.OwnsItems := false;
   
   try
      Delete(start1, range1);
      Delete(start2, range2);
      
   finally
      start1.Owner.OwnsItems := owns1;
      start2.Owner.OwnsItems := owns2;
   end;
end;

procedure MergeCopy(const start1, finish1, start2, finish2 : TForwardIterator;
                    output : TOutputIterator; const comparer : IBinaryComparer;
                    const itemCopier : IUnaryFunctor);
var
   aitem1, aitem2 : ItemType;
   s1, s2 : TForwardIterator;
begin
{$ifdef DEBUG_PASCAL_ADT }
   CheckIteratorRange(start1, finish1);
   CheckIteratorRange(start2, finish2);
{$endif }

   s1 := CopyOf(start1);
   s2 := CopyOf(start2);
   
   while not (s1.Equal(finish1) or s2.Equal(finish2)) do
   begin
      aitem1 := s1.Item;
      aitem2 := s2.Item;
      if _mcp_lte(aitem1, aitem2, comparer) then
      begin
         output.Write(itemCopier.Perform(aitem1));
         s1.Advance;
      end else
      begin
         output.Write(itemCopier.Perform(aitem2));
         s2.Advance;
      end;
   end;
   
   while not s1.Equal(finish1) do
   begin
      output.Write(itemCopier.Perform(s1.Item));
      s1.Advance;
   end;
   
   while not s2.Equal(finish2) do
   begin
      output.Write(itemCopier.Perform(s2.Item));
      s2.Advance;
   end;
   s1.Free;
   s2.Free;
end;

{ ----------------------------- set algorithms ------------------------------ }

function SetUnion(set1, set2 : TSetAdt) : TSetAdt;
var
   iter : TSetIterator;
   owns : Boolean;
begin
   Result := TSetAdt(set1.CopySelf(nil));
   Result.RepeatedItems := true;
   try
      owns := set2.OwnsItems;
      set2.OwnsItems := false;
      try
         Result.Swap(set1); { may raise }
   
         iter := set2.Start; { may raise }
         while not iter.IsFinish do { may raise }
         begin
            Result.Insert(iter.Item);
            iter.Delete;
         end;
      finally
         set2.OwnsItems := owns;
      end;
   except
      Result.Destroy;
      raise;
   end;
end;

function SetUnionCopy(const set1, set2 : TSetAdt;
                      const itemCopier : IUnaryFunctor) : TSetAdt;
begin
   Result := TSetAdt(set1.CopySelf(itemCopier));
   Result.RepeatedItems := true;
   SetUnionCopyToArg(Result, set2, itemCopier);
end;

function SetUnionCopyToArg(set1 : TSetAdt; const set2 : TSetAdt;
                           const itemCopier : IUnaryFunctor) : IUnaryFunctor;
var
   iter : TSetIterator;
   aitem : ItemType;
begin
// &<_mcp_set_zero> is due to a bug in fpc 2.0.1 which I am
// unfortunately not able to reproduce in a smaller program
   _mcp_set_zero(Result, SizeOf(Pointer));
   Result := itemCopier;
   iter := set2.Start;
   while not iter.IsFinish do
   begin
      aitem := itemCopier.Perform(iter.Item);
      try
         if not set1.Insert(aitem) then { may raise }
            with set1 do
               DisposeItem(aitem);
      except
         with set1 do
            DisposeItem(aitem);
         raise;
      end;
      iter.Advance;
   end;
end;

function SetIntersection(set1, set2 : TSetAdt) : TSetAdt;
var
   owns1, owns2 : Boolean;
   iter1 : TSetIterator;
   range2 : TSetIteratorRange;
   aitem : ItemType;
begin
   owns1 := set1.OwnsItems;
   owns2 := set2.OwnsItems;
   Result := TSetAdt(set1.CopySelf(nil));
   Assert(Result.OwnsItems = owns1);
   Result.RepeatedItems := true;
   iter1 := nil;
   try
      try
         set1.OwnsItems := false;
         set2.OwnsItems := false;

         iter1 := set1.Start;
         while not iter1.IsFinish do
         begin
            range2 := set2.EqualRange(iter1.Item);
            if range2.Start.Equal(range2.Finish) then
            begin
               { there is no such item in set2 }
               iter1.Advance;
            end else
            begin
               { insert the items without removing them from the range }
               Copy(range2.Start, range2.Finish, TBasicInserter.Create(Result),
                    Projection);
               range2.Start.Delete(range2.Finish);
               Assert(not set2.Has(iter1.Item));
               aitem := iter1.Item;
               with set1 do
               begin
                  repeat
                     Result.Insert(iter1.Item);
                     iter1.Delete;
                  until iter1.IsFinish or (not _mcp_equal(aitem, iter1.Item));
               end;
            end;
            range2.Destroy;
         end;
      finally
         set1.OwnsItems := owns1;
         set2.OwnsItems := owns2;
         iter1.Free;
      end;
   except
      Result.Destroy;
      raise;
   end;
end;

function SetIntersectionCopy(const set1, set2 : TSetAdt;
                             const itemCopier : IUnaryFunctor) : TSetAdt;
var
   iter1 : TSetIterator;
   range2 : TSetIteratorRange;
   aitem : ItemType;
begin
   Result := TSetAdt(set1.CopySelf(nil));
   Result.RepeatedItems := true;

   iter1 := set1.Start;
   while not iter1.IsFinish do
   begin
      aitem := iter1.Item;
      range2 := set2.EqualRange(aitem);
      if not range2.Start.Equal(range2.Finish) then
      begin
         { copy the range into Result }
         Copy(range2.Start, range2.Finish,
              TBasicInserter.Create(Result), itemCopier);
         with set1 do
         begin
            repeat
               Result.Insert(itemCopier.Perform(iter1.Item));
               iter1.Advance;
            until iter1.IsFinish or (not _mcp_equal(aitem, iter1.Item));
         end;
      end else
         iter1.Advance;
      range2.Destroy;
   end;
   iter1.Destroy;
end;

function SetDifferenceCopy(const set1, set2 : TSetAdt;
                           const itemCopier : IUnaryFunctor) : TSetAdt;
var
   iter1 : TSetIterator;
   aitem : ItemType;
begin
   Result := TSetAdt(set1.CopySelf(nil));
   Result.RepeatedItems := true;

   iter1 := set1.Start;
   while not iter1.IsFinish do
   begin
      aitem := iter1.Item;
      if not set2.Has(aitem) then
      begin
         Result.Insert(itemCopier.Perform(aitem));
      end;
      iter1.Advance;
   end;
   iter1.DESTROY;
end;

function SetSymmetricDifferenceCopy(const set1, set2 : TSetAdt;
                                    const itemCopier : IUnaryFunctor) : TSetAdt;
var
   iter1, iter2 : TSetIterator;
   aitem : ItemType;
begin
   Result := TSetAdt(set1.CopySelf(nil));
   Result.RepeatedItems:= true;

   iter1 := set1.Start;
   while not iter1.IsFinish do
   begin
      aitem := iter1.Item;
      if not set2.Has(aitem) then
      begin
         Result.Insert(itemCopier.Perform(aitem));
      end;
      iter1.Advance;
   end;
   iter1.DESTROY;

   iter2 := set2.Start;
   while not iter2.IsFinish do
   begin
      aitem := iter2.Item;
      if not set1.Has(aitem) then
      begin
         Result.Insert(itemCopier.Perform(aitem));
      end;
      iter2.Advance;
   end;
   iter2.DESTROY;
end;
