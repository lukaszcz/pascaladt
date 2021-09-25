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
 adthash_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adthash.defs
&include adthash_impl.mcp

{ turn range checking off }
{$R-}
   
{ **************************************************************************** }
{   Notes on the implementation of THashTable: }
{ THashTable is implemented as a closed hash table. FBuckets is an
  array of buckets, containing elements of type THashNode. If
  FBuckets^.Bucket[i].Next = @FBuckets.Bucket[i] then it means that
  bucket number i is empty. Items that hash to the same bucket number
  are placed in a singly linked list; FBuckets^.Bucket[i] is the head
  of the list, next node can be reached through Next field of
  THashNode, the last node in the list has Next field set to nil. All
  nodes except for the first one are dynamically allocated. Items that
  have the same keys (according to comparison functor, not only that
  they hash to the same value) are stored in consequtive
  nodes. FCapacity is the number of buckets allocated. FSize is the
  number of items stored in the table. FTableSize is
  log2(FCapacity). When the ratio FSize/FCapacity exceeds
  MaxFiillRatio then the table is Rehash'ed to be two times
  bigger. AutoShrink can be set to true to make the table shrink
  automatically when it contains less than
  (MinFillRatio*FCapacity)/100 items. FCanShrink is used to keep track
  whether it is resonable to shrink the table automatically (only if
  AutoShrink is true). It is considered unreasonable to shrink the
  table automatically if it has just been Rehash'ed by the user,
  i.e. the user called Rehash and there were no subsequent automatic
  calls to this method. In such a situation the user probably intends
  to insert a large number of items and set the capacity large enough
  to insert all those items without intervening automatic
  Rehash'es. It would be pointless to ruin his endeavours by shrinking
  the table automatically. A position within a hash table is
  represented by a (bucket,node) pair, where bucket is the index of
  the bucket and node is the node in this bucket just before the one
  that contains the item at the position. I.e. node^.Next points to
  the item. The first position in a bucket is represented by
  (bucket,nil) pair, where bucket is the index of that bucket. The
  one-beyond-last position is represented by (FCapacity,nil) pair. Any
  other pairs are not valid positions. }
{ Calling CheckMaxFillRatio, CheckMinFillRatio. }
{ Caution must be taken when calling one of these methods. It should
  be remembered that any of them may potentially call Rehash and
  invalidate all pointers into the table.  }   
{  Graphical representation of THashTable: }
{
Bucket       
index   
     +-----+    +-----+    +-----+
  0  | 2n  |--->|  n  |--->|  0  |
     +-----+    +-----+    +-----+
  1  |  1  |--+   +-----+    +-----+    +-----+
     +-----+  +-->|  1  |--->| n+1 |--->| n+1 |
  2  | nil |      +-----+    +-----+    +-----+
     +-----+
       ... 
     |     |
     +-----+    +-----+
 n-3 |2n-3 |--->| n-3 |
     +-----+    +-----+
 n-2 | nil |
     +-----+
 n-1 | n-1 |
     +-----+
}
{ This sample hash table stores items represented by integers and uses
  a simple hashing function that returns the number itself to be used
  as an index into the Fbuckets array. It is then mod'ed by n (the
  capacity) and an appropriate node in the list is
  located. RepeatedItems is true for this table.  }
{ **************************************************************************** }   


{ ------------------------ non-member routines ------------------------------- }


{ ------------------------------- THashTable --------------------------------- }

constructor THashTable.Create;
begin
   inherited;
   InitFields;
end;

constructor THashTable.CreateCopy(const ht : THashTable;
                                  const itemCopier : IUnaryFunctor);
var
   i : IndexType;
   dest, src : PHashNode;
begin
   inherited CreateCopy(ht);
   
   FSize := 0;
   
   if itemCopier <> nil then
   begin
      FTableSize := ht.FTableSize;
      FCapacity := ht.FCapacity;
      GetMem(Pointer(FBuckets), FCapacity * SizeOf(THashNode));
      i := 0;
      try
         for i := 0 to FCapacity - 1 do
         begin
            dest := @FBuckets^.Bucket[i];
            _mcp_set_zero(dest^.Item);
            src := @ht.FBuckets^.Bucket[i];
            if src^.Next <> src then
            begin
               dest^.Next := nil;
               dest^.Item := itemCopier.Perform(src^.Item);
               Inc(FSize);
               
               src := src^.Next;
               while src <> nil do
               begin
                  NewNode(dest^.Next);
                  dest := dest^.Next;
                  dest^.Next := nil;
                  dest^.Item := itemCopier.Perform(src^.Item);
                  Inc(FSize);
                  src := src^.Next;
               end;
            end else
            begin
               dest^.Next := dest;
            end;
         end; { end for }
         i := FCapacity;         
      except
         Inc(i);
         while i < FCapacity do
         begin
            with FBuckets^.Bucket[i] do
            begin
               _mcp_set_zero(Item);
               Next := @FBuckets^.Bucket[i];
            end;
            Inc(i);
         end;
         raise;
      end;
   end else { not itemCopier <> nil }
   begin
      InitBuckets;
   end;
end;

destructor THashTable.Destroy;
begin
   if FBuckets <> nil then
   begin
      ClearBuckets;
      FreeMem(FBuckets);
   end;
   inherited;
end;

function THashTable.GetBucketIndex(value : UnsignedType) : IndexType;
{$ifdef INLINE_DIRECTIVE_REPEAT }
inline;
{$endif }
begin
   Result := value and (FCapacity - 1);
end;

procedure THashTable.CheckMinFillRatio;
{$ifdef INLINE_DIRECTIVE_REPEAT }
inline;
{$endif }
begin
   if AutoShrink and FCanShrink and
         ((FSize shl htRatioFactor) shr FTableSize < FMinFillRatio) and
         (FTableSize - 1 >= htMinTableSize) then
   begin
      Rehash(-1);
      FCanShrink := true;
   end;
end;

procedure THashTable.CheckMaxFillRatio;
begin
   if (FSize shl htRatioFactor) shr FTableSize > FMaxFillRatio then
   begin
      Rehash(1);
      FCanShrink := true;
   end;
end;

procedure THashTable.InitFields;
begin
   FMaxFillRatio := (htDefaultMaxFillRatio shl htRatioFactor) div 100;
   FMinFillRatio := (htDefaultMaxFillRatio shl htRatioFactor) div 100;
   InitBuckets;
end;

procedure THashTable.InitBuckets;
var
   i : IndexType;
begin
   FFirstUsedBucket := -1;
   FCanShrink := false;
   FSize := 0;
   FTableSize := htInitialTableSize;
   FCapacity := CalculateCapacity(FTableSize);
   GetMem(Pointer(FBuckets), FCapacity * SizeOf(THashNode));
   
   for i := 0 to FCapacity - 1 do
   begin
      _mcp_set_zero(FBuckets^.Bucket[i].Item);
      FBuckets^.Bucket[i].Next := @FBuckets^.Bucket[i];
   end;
end;

procedure THashTable.AdvanceToNearestItem(var bucket : IndexType;
                                          var node : PHashNode);
begin
   if (node <> nil) and (node^.Next = nil) then
   begin
      node := nil;
      Inc(bucket);
   end;
   
   if node = nil then
   begin
      while (bucket < FCapacity) and
               (FBuckets^.Bucket[bucket].Next = @FBuckets^.Bucket[bucket]) do
      begin
         Inc(bucket);
      end;
   end;   
end;

procedure THashTable.RetreatToNearestItem(var bucket : IndexType;
                                          var node : PHashNode);
begin
   Assert(bucket <= FCapacity, msgInvalidIterator);
   
   if node = nil then
   begin
      while (bucket >= 0) and
               ((bucket >= FCapacity) or
                   (FBuckets^.Bucket[bucket].Next = @FBuckets^.Bucket[bucket]))  do
      begin
         Dec(bucket);
      end;
      Assert(bucket >= 0, msgRetreatingStartIterator);
   end;
end;

function THashTable.EqualItemsAhead(var bucket : IndexType;
                                    var node : PHashNode;
                                    aitem : ItemType) : SizeType;
begin
   { assert that the chain is not empty }
   Assert(FBuckets^.Bucket[bucket].Next <> @FBuckets^.Bucket[bucket]);

   Result := 1;
   if node = nil then
   begin
      node := @FBuckets^.Bucket[bucket];
   end else
   begin
      Assert(node^.Next <> nil, msgInternalError);
      node := node^.Next;
   end;
   
   Assert(_mcp_equal(node^.Item, aitem), msgInternalError);
   
   while (node^.Next <> nil) and
            (_mcp_equal(node^.Next^.Item, aitem)) do
   begin
      Inc(Result);
      node := node^.Next;
   end;
   
   if node^.Next = nil then
   begin
      node := nil;
      Inc(bucket);
   end;  
end;


function THashTable.FindNode(aitem : ItemType; var bucket : IndexType;
                             var node : PHashNode) : Boolean;
begin
   bucket := GetBucketIndex(Hasher.Hash(aitem));
   if FBuckets^.Bucket[bucket].Next <> @FBuckets^.Bucket[bucket] then
   begin
      if _mcp_equal(FBuckets^.Bucket[bucket].Item, aitem) then
      begin
         node := nil;
         Result := true;
      end else
      begin
         node := @FBuckets^.Bucket[bucket];
         while (node^.Next <> nil) and
                  (not _mcp_equal(node^.Next^.Item, aitem)) do
         begin
            node := node^.Next;
         end;
         
         if node^.Next <> nil then
         begin
            Result := true;
         end else
            Result := false;
      end;
      
   end else begin
      node := nil;
      Result := false;
   end;
end;

procedure THashTable.InsertNode(var bucket : IndexType; var node : PHashNode;
                                aitem : ItemType);
var
   temp : PHashNode;
begin
   if node <> nil then
   begin
      temp := node^.Next;
      NewNode(node^.Next);
      with node^.Next^ do
      begin
         Item := aitem;
         Next := temp;
      end;
   end else
   begin
      if FBuckets^.Bucket[bucket].Next = @FBuckets^.Bucket[bucket] then
      begin
         FBuckets^.Bucket[bucket].Next := nil;
         FBuckets^.Bucket[bucket].Item := aitem
      end else
      begin
         with FBuckets^.Bucket[bucket] do
         begin
            temp := Next;
            NewNode(Next);
            Next^.Next := temp;
            Next^.Item := aitem;
         end;
         node := @FBuckets^.Bucket[bucket];
      end;
   end;
   
   Inc(FSize);
   FFirstUsedBucket := -1;
end;

function THashTable.ExtractNode(bucket : IndexType; node : PHashNode) : ItemType;
var
   nnode : PHashNode;
begin
   Assert(FBuckets^.Bucket[bucket].Next <> @FBuckets^.Bucket[bucket]);
   if (node = nil) then
   begin
      node := @FBuckets^.Bucket[bucket];
      Result := node^.Item;
      
      nnode := node^.Next;
      if nnode <> nil then
      begin
         node^.Item := nnode^.Item;
         node^.Next := nnode^.Next;
         DisposeNode(nnode);
      end else begin
         node^.Next := node;
         node^.Item := DefaultItem;
      end;
   end else 
   begin
      Assert(node^.Next <> nil, msgDeletingInvalidIterator);
      
      nnode := node^.Next;
      Result := nnode^.Item;
      
      node^.Next := nnode^.Next;
      DisposeNode(nnode);
   end;
   
   Dec(FSize);
   FFirstUsedBucket := -1;
end;

procedure THashTable.ClearBuckets;
var
   i : IndexType;
   node, nnode : PHashNode;
begin
   for i := 0 to FCapacity - 1 do
   begin
      if FBuckets^.Bucket[i].Next <> @FBuckets^.Bucket[i] then
      begin
         node := @FBuckets^.Bucket[i];
         DisposeItem(node^.Item);
         
         node := node^.Next;
         while node <> nil do
         begin
            DisposeItem(node^.Item);
            nnode := node^.Next;
            DisposeNode(node);
            node := nnode;
         end;
         { after ClearBuckets the buckets are usually freed, so the
           values of Next and Item do not matter; if it is necessary
           have these field valid, then it is the responsibility of
           the caler to validate them; thisd is not done here because
           of the (small) performance penalty (as it is not needed
           most of the time, anyway) }
      end;
   end;
   FFirstUsedBucket := -1;
end;


procedure THashTable.NewNode(var node : PHashNode);
begin
   New(node);
end;

procedure THashTable.DisposeNode(node : PHashNode);
begin
   Dispose(node);
end;

function THashTable.GetCapacity : SizeType;
begin
   Result := FCapacity;
end;

function THashTable.CalculateCapacity(ex : SizeType) : SizeType;
begin
   Result := 1 shl ex;
end;

function THashTable.GetMaxFillRatio : SizeType;
begin
   Result := (FMaxFillRatio*100) shr htRatioFactor;
end;

procedure THashTable.SetMaxFillRatio(fr : SizeType);
begin
   FMaxFillRatio := (fr shl htRatioFactor) div 100;
end;

function THashTable.GetMinFillRatio : SizeType;
begin
   Result := (FMinFillRatio*100) shr htRatioFactor;
end;

procedure THashTable.SetMinFillRatio(fr : SizeType);
begin
   FMinFillRatio := (fr shl htRatioFactor) div 100;
end;

{$ifdef TEST_PASCAL_ADT }
procedure THashTable.LogStatus(mname : String);
var
   maxItemsInBucket, m2ItemsInBucket : SizeType;  
   BucketsEmpty, BucketsUsed, itemsInBucket : SizeType;
   avgItemsInBucket, varItemsInBucket, avgAll, varAll : Double;
   i : IndexType;
   node : PHashNode;
begin
   inherited;
   
   m2ItemsInBucket := 0;
   BucketsEmpty := 0;
   maxItemsInBucket := 0;
   
   for i := 0 to FCapacity - 1 do
   begin
      node := @FBuckets^.Bucket[i];
      if node^.Next = node then
      begin
         Inc(BucketsEmpty);
      end else
      begin
         itemsInBucket := 0;
         while node <> nil do
         begin
            Inc(itemsInBucket);
            node := node^.Next;
         end;
         
         Inc(m2ItemsInBucket, itemsInBucket * itemsInBucket);
         if itemsInBucket > maxItemsInBucket then
            maxItemsInBucket := itemsInBucket;
      end;
   end;
   
   BucketsUsed := FCapacity - BucketsEmpty;
   avgItemsInBucket := FSize / BucketsUsed;
   varItemsInBucket :=
      m2ItemsInBucket / BucketsUsed - Sqr(avgItemsInBucket);
   avgAll := FSize / FCapacity;
   varAll := m2ItemsInBucket / FCapacity - Sqr(avgAll);
   
   WriteLog('Total buckets: ' + IntToStr(FCapacity));
   WriteLog('Empty buckets: ' + IntToStr(BucketsEmpty));
   WriteLog('Used buckets: ' + IntToStr(BucketsUsed));
   WriteLog('Max items in bucket: ' + IntToStr(maxItemsInBucket));
   WriteLog('Average items in bucket (all): ' + FloatToStr(avgAll));
   WriteLog('Variance of items in bucket (all): ' + FloatToStr(varAll));
   WriteLog('Deviation of items in bucket (all): ' +
               FloatToStr(Sqrt(varAll)));
   WriteLog('Average items in bucket (used): ' +
               FloatToStr(avgItemsInBucket));
   WriteLog('Variance of items in bucket (used): ' +
               FloatToStr(varItemsInBucket));
   WriteLog('Deviation of items in bucket (used): ' +
               FloatToStr(Sqrt(varItemsInBucket)));
   WriteLog('Average steps searching for an existing item: ' +
               FloatToStr(((m2ItemsInBucket / FSize) + 1) / 2));
   WriteLog;
end;
{$endif TEST_PASCAL_ADT }

function THashTable.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt; 
begin
   Result := THashTable.CreateCopy(self, itemCopier);
end;

procedure THashTable.Swap(cont : TContainerAdt);
var
   table : THashTable;
begin
   if cont is THashTable then
   begin
      BasicSwap(cont);
      table := THashTable(cont);
      ExchangePtr(FBuckets, table.FBuckets);
      ExchangeData(FCapacity, table.FCapacity, SizeOf(SizeType));
      ExchangeData(FSize, table.FSize, SizeOf(SizeType));
      ExchangeData(FTableSize, table.FTableSize, SizeOf(SizeType));
      ExchangeData(FMinFillRatio, table.FMinFillRatio, SizeOf(SizeType));
      ExchangeData(FMaxFillRatio, table.FMaxFillRatio, SizeOf(SizeType));
      ExchangeData(FCanShrink, table.FCanShrink, SizeOf(Boolean));
      ExchangeData(FFirstUsedBucket, table.FFirstUsedBucket, SizeOf(IndexType));
   end else
      inherited;
end;

function THashTable.Start : TSetIterator;
begin
   Result := THashTableIterator.Create(0, nil, self);
   AdvanceToNearestItem(THashTableIterator(Result).FBucket,
                        THashTableIterator(Result).FNode);
end;

function THashTable.Finish : TSetIterator; 
begin
   Result := THashTableIterator.Create(FCapacity, nil, self);
end;

&if (&_mcp_accepts_nil)
function THashTable.FindOrInsert(aitem : ItemType) : ItemType;
var
   bucket : IndexType;
   node : PHashNode;
begin
   if RepeatedItems then
   begin
      Insert(aitem);
      Result := nil;
   end else
   begin
      if FindNode(aitem, bucket, node) then
      begin
         if node <> nil then
            Result := node^.Next^.Item
         else
            Result := FBuckets^.Bucket[bucket].Item;
      end else begin
         InsertNode(bucket, node, aitem);
         Result := nil;
      end;
      CheckMaxFillRatio;
   end;
end;

function THashTable.Find(aitem : ItemType) : ItemType;
var
   bucket : IndexType;
   node : PHashNode;
begin
   if FindNode(aitem, bucket, node) then
   begin
      if node = nil then
         Result := FBuckets^.Bucket[bucket].Item
      else
         Result := node^.Next^.Item
   end else
      Result := nil;
end;
&endif &# end &_mcp_accepts_nil

function THashTable.Has(aitem : ItemType) : Boolean;
var
   bucket : IndexType;
   node : PHashNode;
begin
   Result := FindNode(aitem, bucket, node);
end;

function THashTable.Count(aitem : ItemType) : SizeType;
var
   node : PHashNode;
   bucket : IndexType;
begin
   if FindNode(aitem, bucket, node) then
   begin
      Result := EqualItemsAhead(bucket, node, aitem);
   end else
      Result := 0;
end;

function THashTable.Insert(pos : TSetIterator; aitem : ItemType) : Boolean;
begin
   Result := Insert(aitem);
end;

function THashTable.Insert(aitem : ItemType) : Boolean;
var
   bucket : IndexType;
   node : PHashNode;
begin
   if FindNode(aitem, bucket, node) then
   begin
      if RepeatedItems then
      begin
         InsertNode(bucket, node, aitem);
         Result := true;
      end else
         Result := false;
   end else
   begin
      InsertNode(bucket, node, aitem);
      Result := true;
   end;
   CheckMaxFillRatio;
end;

procedure THashTable.Delete(pos : TSetIterator);
var
   aitem : ItemType;
begin
   Assert(pos is THashTableIterator, msgInvalidIterator);
   
   aitem := ExtractNode(THashTableIterator(pos).FBucket,
                        THashTableIterator(pos).FNode);
   DisposeItem(aitem);
end;

function THashTable.Delete(aitem : ItemType) : SizeType; 
var
   bucket : IndexType;
   node, nnode, fnode : PHashNode;
begin
   CheckMinFillRatio;

   Result := 0;
   if FindNode(aitem, bucket, node) then
   begin
      if node = nil then
      begin
         DisposeItem(FBuckets^.Bucket[bucket].Item);
         Inc(Result);
         
         node := FBuckets^.Bucket[bucket].Next;
         while (node <> nil) and
                  (_mcp_equal(node^.Item, aitem)) do
         begin
            nnode := node^.Next;
            DisposeItem(node^.Item);
            DisposeNode(node);
            node := nnode;
            Inc(Result);
         end;
         
         if node = nil then
         begin
            with FBuckets^.Bucket[bucket] do
            begin
               Item := DefaultItem;
               Next := @FBuckets^.Bucket[bucket];
            end;
         end else
         begin
            with FBuckets^.Bucket[bucket] do
            begin
               Item := node^.Item;
               Next := node^.Next;
            end;
            DisposeNode(node);
         end;

      end else
      begin
         fnode := node;
         node := node^.Next;
         repeat
            nnode := node^.Next;
            DisposeItem(node^.Item);
            DisposeNode(node);
            Inc(Result);
            node := nnode;
         until (node = nil) or (not _mcp_equal(node^.Item, aitem));
         
         fnode^.Next := node;
      end;
      
      FFirstUsedBucket := -1;
   end;
   
   Dec(FSize, Result);
end;

function THashTable.LowerBound(aitem : ItemType) : TSetIterator;
var
   bucket : IndexType;
   node : PHashNode;
begin
   FindNode(aitem, bucket, node);
   Result := THashTableIterator.Create(bucket, node, self);
end;

function THashTable.UpperBound(aitem : ItemType) : TSetIterator; 
var
   bucket : IndexType;
   node : PHashNode;
begin
   if FindNode(aitem, bucket, node) then
   begin
      EqualItemsAhead(bucket, node, aitem);
   end;
   Result := THashTableIterator.Create(bucket, node, self);
end;

function THashTable.EqualRange(aitem : ItemType) : TSetIteratorRange;
var
   bucket1, bucket2 : IndexType;
   node1, node2 : PHashNode;
begin
   if FindNode(aitem, bucket1, node1) then
   begin
      bucket2 := bucket1;
      node2 := node1;
      EqualItemsAhead(bucket2, node2, aitem);
   end else
   begin
      bucket2 := bucket1;
      node2 := node1;
   end;
   Result := TSetIteratorRange.Create(
      THashTableIterator.Create(bucket1, node1, self),
      THashTableIterator.Create(bucket2, node2, self)
                                     );
end;

procedure THashTable.Rehash(ex : SizeType);
var
   buckets : PHashBuckets;
   oldCap, NewCapacity, NewTableSize : SizeType;
   nnode, node, lnode, temp : PHashNode;
   i, lbucket : IndexType;
   lastItem : ItemType;
   lastItemValid : Boolean;
   blist : PHashNode; { list of buckets that can be reused }
   
   procedure GetNewNode(var node : PHashNode);
   begin
      if blist <> nil then
      begin
         node := blist;
         blist := blist^.Next;
      end else
         NewNode(node); { may raise }
   end;
   
   procedure ReInsert(aitem : ItemType);
   begin
      if (lastItemValid) and (_mcp_equal(aitem, lastItem)) then
      begin
         temp := lnode^.Next;
         GetNewNode(lnode^.Next); { may raise }
         lnode := lnode^.Next;
         with lnode^ do
         begin
            Item := aitem;
            Next := temp;
         end;
      end else
      begin
         lbucket := GetBucketIndex(Hasher.Hash(aitem));
         lnode := @FBuckets^.Bucket[lbucket];
         if lnode^.Next = lnode then
         begin
            lnode^.Item := aitem;
            lnode^.Next := nil;
         end else
         begin
            GetNewNode(temp); { may raise }
            temp^.Item := lnode^.Item;
            temp^.Next := lnode^.Next;
            lnode^.Next := temp;
            lnode^.Item := aitem;
         end;
      end;
      lastItem := aitem;
      lastItemValid := true;
   end; { end ReInsert }
   
   procedure ReInsertItems;
   var
      i : IndexType;
   begin
      lnode := nil;
      blist := nil;
      lastItem := DefaultItem;
      lastItemValid := false;
   
      for i := 0 to oldCap - 1 do
      begin
         if buckets^.Bucket[i].Next <> @buckets^.Bucket[i] then
         begin
            node := @buckets^.Bucket[i];
            { may raise here (and only here) if there are no more
              nodes left in blist and there is not enough memory to
              allocate a new node; this is possible only if ex < 0 }
            ReInsert(node^.Item); 
            
            node := node^.Next;
            while node <> nil do
            begin
               nnode := node^.Next;
               { add node to the list of unused bucket nodes }
               node^.Next := blist;
               blist := node;
               
               { cannot raise here because there is now at least one
                 node in blist }
               ReInsert(node^.Item);
               node := nnode;
            end;
            { in case of an exception the fields at the current
              position to defaults (to avoid doing it when an
              exception occurs) }
            with buckets^.Bucket[i] do
            begin
               { this should not be &<_mcp_set_zero>'ed; &<_mcp_set_zero>
                 should (and must!) be used only for newly allocated
                 items }
               Item := DefaultItem; 
               Next := @buckets^.Bucket[i];
            end;
         end;
      end; { end for }
   end; { end ReInsertItems }
   
   procedure DeallocateOldBuckets;
   begin
      while blist <> nil do
      begin
         nnode := blist^.Next;
         DisposeNode(blist);
         blist := nnode;
      end;
      FreeMem(buckets);
   end;
   
begin
   Assert(FTableSize + ex >= htMinTableSize, msgContainerTooSmall);
   
{$ifdef TEST_PASCAL_ADT }
{   LogStatus('Rehash'); }
{$endif }

   oldCap := FCapacity;
   NewTableSize := FTableSize + ex;
   NewCapacity := CalculateCapacity(NewTableSize);
   
   GetMem(Pointer(buckets), NewCapacity * SizeOf(THashNode)); { may raise }
   
   ExchangePtr(buckets, FBuckets);
   FCapacity := NewCapacity;
   FTableSize := NewTableSize;
   FFirstUsedBucket := -1;
   
   for i := 0 to FCapacity - 1 do
   begin
      with FBuckets^.Bucket[i] do
      begin
         _mcp_set_zero(Item);
         Next := @FBuckets^.Bucket[i];
      end;
   end;
     
   try
      ReInsertItems;
   except
      { no nodes were deleted up to now, so we may be sure that no
        memory will be attempted to be allocated while calling
        ReInsert; note that additional memory for nodes may be needed
        only we we make the table smaller, so if there is an exception
        raised while trying to allocate a node then we may be sure
        that the old table needs less memory for nodes than the new
        one; hence, while re-inserting back to the old table we won't
        need any more additional memory; therefore, we just exchange
        the table and use the procedure ReInsertItems to insert items
        back to the old table }
      ExchangePtr(FBuckets, buckets);
      FCapacity := oldCap;
      oldCap := NewCapacity;
      FTableSize := FTableSize - ex;
      ReInsertItems;
      DeallocateOldBuckets;
      raise;
   end;
   DeallocateOldBuckets;
   
   FCanShrink := false;
   { it is desirable not to shrink the table if it were rehashed by a
     user to make place for data that is going to be inserted, so we
     set FCanShrink to false; if Rehash is called internally then
     FCanShrink is reset to true after the call. }
end; { end Rehash }

procedure THashTable.Clear;
begin
   ClearBuckets;
   FreeMem(FBuckets);
   InitBuckets;
   GrabageCollector.FreeObjects;
end;

function THashTable.Empty : Boolean; 
begin
   Result := FSize = 0;
end;

function THashTable.Size : SizeType;
begin
   Result := FSize;
end;

function THashTable.MinCapacity : SizeType;
begin
   Result := CalculateCapacity(htMinTableSize);
end;


{ -------------------------- THashTableIterator ----------------------------- }


constructor THashTableIterator.Create(abucket : IndexType; anode : PHashNode;
                                      tab : THashTable);
begin
   inherited Create(tab);
   FBucket := abucket;
   FNode := anode;
   FTable := tab;
   FTable.AdvanceToNearestItem(FBucket, FNode);
end;

function THashTableIterator.CopySelf : TIterator;
begin
   Result := THashTableIterator.Create(FBucket, FNode, FTable);
end;

function THashTableIterator.Equal(const Pos : TIterator) : Boolean;
begin
   Assert(pos is THashTableIterator, msgInvalidIterator);
   Result := (THashTableIterator(pos).FNode = FNode) and
      (THashTableIterator(pos).FBucket = FBucket);
end;

function THashTableIterator.GetItem : ItemType;
begin
   Assert(not IsFinish, msgReadingInvalidIterator);
   
   if FNode <> nil then
      Result := FNode^.Next^.Item
   else
      Result := FTable.FBuckets^.Bucket[FBucket].Item;
end;

procedure THashTableIterator.SetItem(aitem : ItemType);
var
   pi : PItemType;
   oldItem : ItemType;
begin
   Assert(not IsFinish, msgInvalidIterator);
   
   if FNode <> nil then
      pi := @FNode^.Next^.Item
   else
      pi := @FTable.FBuckets^.Bucket[FBucket].Item;
   
   oldItem := pi^;
   pi^ := aitem;
   with FTable do
   begin
      if not _mcp_equal(oldItem, aitem) then
      begin
         try
            self.Insert(self.Extract);
         finally
            DisposeItem(oldItem);
         end;
      end else
         DisposeItem(oldItem);
   end;
end;

procedure THashTableIterator.ResetItem;

   procedure DoResetItem;
   begin
      Insert(Extract);
   end;

begin
   if FNode <> nil then
   begin
      { we have to perform the reset operation here, because we cannot
        check whether the previous item is equal or not to our item
        (in order to determine whether a chain of equal items is
        broken) }
      DoResetItem;
   end else
   begin
      if FTable.GetBucketIndex(
         FTable.Hasher.Hash(FTable.FBuckets^.Bucket[FBucket].Item)
                              ) <> FBucket then
      begin
         DoResetItem;
      end;
   end;
end;

procedure THashTableIterator.Advance;
begin
   Assert(FBucket < FTAble.FCapacity, msgAdvancingInvalidIterator);
   
   if (FNode <> nil) and (FNode^.Next <> nil) then
   begin
      FNode := FNode^.Next;
   end else if (FNode = nil) then
   begin
      FNode := @FTable.FBuckets^.Bucket[FBucket];
   end;
   
   if (FNode^.Next = nil) then
   begin
      FTable.AdvanceToNearestItem(FBucket, FNode);
   end;
end;

procedure THashTableIterator.Retreat;
var
   node : PHashNode;
begin
   with FTable.FBuckets^, FTable do
   begin
      if FBucket < FCapacity then
      begin
         if Bucket[FBucket].Next <> @Bucket[FBucket] then
         begin
            if FNode = nil then
            begin
               Dec(FBucket);
               FTable.RetreatToNearestItem(FBucket, FNode);
            end else
            begin
               node := @Bucket[FBucket];
               while node^.Next <> FNode do
                  node := node^.Next;
               FNode := node;
            end;
         end else
         begin
            FNode := nil;
            FTable.RetreatToNearestItem(FBucket, FNode);
         end;
      end else
      begin
         FTable.RetreatToNearestItem(FBucket, FNode);
      end;
   end;
end;

procedure THashTableIterator.Insert(aitem : ItemType);
begin
   with FTable do
   begin
      { Note: We have to call CheckMaxFillRatio here and not after
        doing the job not to invalidate FBucket and FNode by a
        possible re-hash }
      CheckMaxFillRatio;
      if FindNode(aitem, FBucket, FNode) then
      begin
         if RepeatedItems then
         begin
            InsertNode(FBucket, FNode, aitem);
         end else
         begin
            FBucket := FCapacity;
            FNode := nil;
         end;
      end else
      begin
         InsertNode(FBucket, FNode, aitem);
      end;
   end;
end;

function THashTableIterator.Extract : ItemType;
begin
   Assert(FBucket < FTable.FCapacity, msgDeletingInvalidIterator);
   with FTable do
   begin
      Result := ExtractNode(FBucket, FNode);
      AdvanceToNearestItem(FBucket, FNode);
   end;
end;

function THashTableIterator.Owner : TContainerAdt;
begin
   Result := FTable;
end;

function THashTableIterator.IsStart : Boolean;
var
   node : PHashNode;
begin
   with FTable do
   begin
      if FNode <> nil then
         Result := false
      else if FBucket = FTable.FCapacity then
      begin
         if FTable.FSize = 0 then
            Result := true
         else
            Result := false;
      end else if (FBucket > 1) and
                     ((FBuckets^.Bucket[FBucket-1].Next <>
                          @FBuckets^.Bucket[FBucket-1]) or
                         (FBuckets^.Bucket[FBucket-2].Next <>
                             @FBuckets^.Bucket[FBucket-2])) then
      begin
         Result := false;
      end else if FFirstUsedBucket <> -1 then
      begin
         Result := FBucket = FFirstUsedBucket;
      end else
      begin
         FTable.FFirstUsedBucket := 0;
         node := nil;
         FTable.AdvanceToNearestItem(FTable.FFirstUsedBucket, node);
         Result := FBucket = FTable.FFirstUsedBucket;
      end;
   end;
end;

function THashTableIterator.IsFinish : Boolean;
begin
   Result := (FBucket = FTable.FCapacity);
end;


&if (&_mcp_are_two_special_values)

{ ============================================================================ }
{ Notes on the implementation of TScatterTable: }
{ TScatterTable is a closed hash table. It uses one array (FArray) to
  store its elements. The collision solving strategy used is a
  semi-random probing. When a collision occurs, i.e. some item hashes
  to a position that is already used, the item being inserted is
  placed at the first free place (containing nil or marked stDeleted)
  in the collision chain starting from the place to which the item
  hashes. We shall call 'the collision chain of i' the sequence of
  places with items that hash to index i. This way every index in the
  array has a chain associated with it. The positions from the
  sequence of probes that start from some index h do not necessarily
  belong to the collision chain of h; they may belong to different
  collision chains and just happen to be on the way, or may be marked
  as stDeleted. The end of the sequence of probes starting from a
  given position is designated by nil. The collision chain of this
  position is entirely contained in this sequence. Therefore, when we
  delete an item we cannot just simply remove it and put nil in its
  place, because it would break our collision chain into two pieces,
  and possibly also some other chains we don't know anything
  about. So, we just mark the place as 'deleted' (with a special value
  stDeleted). Equal items are placed next to each other in their
  collision chain (the Insert routine is a bit tricky because of
  this). When traversing the table, the collision chains of all
  indices are visited one after another. That is, at first all items
  that hash to index 0 are visited, then all that hash to index 1, and
  so on.  }
{ Calling Rehash. }
{ While in THashTable there may be virtually any number of items
  inserted without the need of rehashing it, albeit losing efficiency,
  in TScatterTable the number of items can never exceed the current
  capacity. It is, therefore, necessary to check sufficiently often
  whether Rehash should be called not to let this situation
  develop. It should be pointed out that the Delete method of the
  iterator may cause a situation in which all fields are marked
  stDeleted. To remedy this the CheckDeletedFields chould be called
  even before non-modifying operations. }
{ TScatterTable graphically: }
{
 Index   Items  Chain  Probe Seqs.
        +-----+  
   0    |  0  |   0    (0)
        +-----+
   1    |  1  |   1    (1, 0)
        +-----+
   2    |  1  |   1    (1, 2)
        +-----+
   3    |  d  |   -    (2, 3)
        +-----+
   4    | nil |   -    (end of 3)
        +-----+
        |     |
          ...          (probably end of 0 somewhere here)
        |     |
        +-----+
  n-5   |  1  |   1    (1, n-5)
        +-----+
  n-4   |  2  |   2    (2, n-4, n-5)
        +-----+
  n-3   | nil |   -    (end of n-4)
        +-----+
  n-2   |  d  |   -    (1, n-2)
        +-----+
  n-1   | nil |   -    (end of 2, end of n-2)
        +-----+
}
{ Numbers in the boxes show the indicies to which given items hash; d
  means a deleted position, nil means an empty one. Numbers to the
  right of the picture show to which collision chain the given
  position belongs; the numbers in brackets show all sequences of
  probes the given position belongs to (all sequences starting from
  positions not shown in the picture are omitted). }
  
{ ============================================================================ }


{ --------------------------- TScatterTable ---------------------------------- }

constructor TScatterTable.Create;
begin
   inherited;
   InitFields;
end;

constructor TScatterTable.CreateCopy(const st : TScatterTable;
                                     const itemCopier : IUnaryFunctor);
var
   i : IndexType;
begin
   inherited CreateCopy(st);
   
   if itemCopier <> nil then
   begin
      InitBasicFields;
      FTableSize := st.FTableSize;
      
      ArrayAllocate(FArray, st.FArray^.Capacity, 0);
      ZeroOutFArray;
      
      for i := 0 to st.FArray^.Capacity - 1 do
      begin
         if (st.FArray^.Items[i] <> stFree) and
               (st.FArray^.Items[i] <> stDeleted) then
         begin
            Insert(itemCopier.Perform(st.FArray^.Items[i]));
         end;
      end;
   end else { not itemCopier <> nil }
   begin
      InitFields;
   end;
end;

destructor TScatterTable.Destroy;
begin
   if FArray <> nil then
   begin
      Clear;
      ArrayDeallocate(FArray);
   end;
   inherited;
end;

function TScatterTable.FirstProbe : SizeType;
{$ifdef INLINE_DIRECTIVE_REPEAT }      
inline;
{$endif }
begin
   Result := 1;
end;

function TScatterTable.NextProbe(off : UnsignedType) : SizeType;
{$ifdef INLINE_DIRECTIVE_REPEAT }      
inline;
{$endif }
begin
   if (off and (1 shl (FTableSize - 1))) <> 0 then
      Result := (off shl 1) xor stMagicTable[FTableSize]
   else
      Result := off shl 1;
end;

function TScatterTable.GetIndex(val : UnsignedType) : IndexType;
{$ifdef INLINE_DIRECTIVE_REPEAT }      
inline;
{$endif }
begin
   Result := val and ((1 shl FTableSize) - 1);
end;

procedure TScatterTable.CheckDeletedFields;
{$ifdef INLINE_DIRECTIVE_REPEAT }      
inline;
{$endif }
var
   canShrinkSave : Boolean;
begin
   canShrinkSave := FCanShrink;
   if (FDeletedFields >= FArray^.Size) and
         (((FArray^.Size + FDeletedFields) shl stRatioFactor) shr
             FTableSize >= FMinFillRatio) then
   begin
      Rehash(0);
      FCanShrink := canShrinkSave;
   end;
end;

procedure TScatterTable.CheckMinFillRatio;
{$ifdef INLINE_DIRECTIVE_REPEAT }      
inline;
{$endif }
var
   fillRatio : SizeType;
begin
   fillRatio := (FArray^.Size shl stRatioFactor) shr FTableSize;
   if AutoShrink and FCanShrink and (fillRatio < FMinFillRatio) and
         (FTableSize - 1 >= stMinTableSize) then
   begin
      Rehash(-1);
      FCanShrink := true;
   end;
   CheckDeletedFields;
end;

procedure TScatterTable.CheckMaxFillRatio;
{$ifdef INLINE_DIRECTIVE_REPEAT }      
inline;
{$endif }
var
   fillRatio : SizeType;
begin
   fillRatio := (FArray^.Size shl stRatioFactor) shr FTableSize;
   if fillRatio > FMaxFillRatio then
   begin
      Rehash(1);
      FCanShrink := true;
   end;
   CheckDeletedFields;
end;

procedure TScatterTable.InitFields;
begin
   InitBasicFields;
   FTableSize := stInitialTableSize;
   ArrayAllocate(FArray, CalculateCapacity(FTableSize), 0);
   ZeroOutFArray;
end;

procedure TScatterTable.InitBasicFields;
begin
   FDeletedFields := 0;
   FCanShrink := false;
   SetMinFillRatio(stDefaultMinFillRatio);
   SetMaxFillRatio(stDefaultMaxFillRatio);
end;

procedure TScatterTable.ZeroOutFArray;
var
   i : IndexType;
begin
   for i := 0 to FArray^.Capacity - 1 do
   begin
      FArray^.Items[i] := stFree;
   end;
end;

procedure TScatterTable.AdvanceToNearestItem(var h : IndexType;
                                             var p : SizeType);
var
   i : IndexType;
   bug : SizeType;
begin
   with FArray^ do
   begin
      i := GetIndex(h + p);
      while (h < FArray^.Capacity) and
               ((Items[i] = stFree) or (Items[i] = stDeleted) or
               (GetIndex(Hasher.Hash(Items[i])) <> h)) do
      begin
         while (Items[i] <> stFree) and
                  ((Items[i] = stDeleted) or
                      (GetIndex(Hasher.Hash(Items[i])) <> h)) do
         begin
            if p <> 0 then
            begin
               bug := NextProbe(p);
            end else
               bug := FirstProbe;
            i := GetIndex(h + bug);
            p := bug;
         end;
         
         while (h < FArray^.Capacity) and (Items[i] = stFree) do
         begin
            Inc(h);
            p := 0;
            i := h;
         end;
      end;
   end;
end;

function TScatterTable.DoInsert(aitem : ItemType; var h : IndexType) : SizeType;
var
   i, ii, ii2 : IndexType;
   p : SizeType;
   orgPtr : ItemType;
   wasMoreThanOne : Boolean;
begin
   { Note: We have to call this before doing the job. Otherwise the
     returned offset and base may be invalid! The re-hashing of the
     table could possibly invalidate them. }
   CheckMaxFillRatio;
   
   h := GetIndex(Hasher.Hash(aitem));
   { find the first item equal to aitem, if not found insert at the back
     of the collision chain; if found find the nearest item not equal
     to aitem, exchange aitem with it and continue with inserting this
     exchanged item (this is because equal items must be kept in a
     sequence, adjacent to each other); it should be noted that
     collision chains may coalesce and items from different collision
     chains should be skipped; special care must be taken with
     exceptions, because if we exchange aitem with some item already in
     the container this item cannot be leaked! }
   
   orgPtr := aitem; { original aitem }
   wasMoreThanOne := false;

   i := 0; { only to shut the compiler up }
   try
      
      if (FArray^.Items[h] = stFree) then
      begin
         FArray^.Items[h] := aitem;
         p := 0;
      end else if (FArray^.Items[h] = stDeleted) then
      begin
         Dec(FDeletedFields);
         FArray^.Items[h] := aitem;
         p := 0;
      end else
      begin
         p := FirstProbe;
         i := GetIndex(h + p);
               
         if _mcp_equal(FArray^.Items[h], aitem) then
         begin
            if not RepeatedItems then
            begin
               Result := -1; { set result to some rubbish }
               Exit;
            end else
            begin
               while (FArray^.Items[i] <> stFree) and
                        (FArray^.Items[i] <> stDeleted) and
                        (_mcp_equal(FArray^.Items[i], aitem) or
                            (GetIndex(Hasher.Hash(FArray^.Items[i])) <> h)) do
               begin
                  p := NextProbe(p);
                  i := GetIndex(h + p);
               end;
               if (FArray^.Items[i] <> stFree) and
                     (FArray^.Items[i] <> stDeleted) then
               begin
                  ExchangePtr(FArray^.Items[i], aitem);
                  p := NextProbe(p);
                  i := GetIndex(h + p);
               end;
            end;
         end;
         
         while (FArray^.Items[i] <> stFree) and (FArray^.Items[i] <> stDeleted) do
         begin
            if not _mcp_equal(FArray^.Items[i], aitem) then { may raise }
            begin
               p := NextProbe(p);
               i := GetIndex(h + p);
               wasMoreThanOne := false; { for exception handling }
            end else
            begin
               if not RepeatedItems then
               begin
                  Result := -1; { could be anything instead of -1 }
                  Exit;
               end else
               begin
                  p := NextProbe(p);
                  i := GetIndex(h + p);
                  while (FArray^.Items[i] <> stFree) and
                           (FArray^.Items[i] <> stDeleted) and
                           (_mcp_equal(FArray^.Items[i], aitem) or
                               (GetIndex(Hasher.Hash(FArray^.Items[i])) <> h)) do
                  begin
                     p := NextProbe(p);
                     i := GetIndex(h + p);
                  end;
                  
                  if (FArray^.Items[i] <> stFree) and
                        (FArray^.Items[i] <> stDeleted) then
                  begin
                     ExchangePtr(FArray^.Items[i], aitem);
                     p := NextProbe(p);
                     i := GetIndex(h + p);
                     wasMoreThanOne := true; { exception handling }
                  end;
               end;
            end; { end not aitem <> FArray[i] }
         end; { end while an empty place not found }
         if FArray^.Items[i] = stDeleted then
            Dec(FDeletedFields);
         FArray^.Items[i] := aitem;
      end; { end main if }
      
   except
      { The exception could have been raised in three circumstances: }
      { 1. The original aitem passed by the user has not yet been placed
        into FArray -> we are lucky, just do nothing. }
      { 2. The original pointer passed by the user (orgPtr) was placed
        in FArray and aitem is now an item that had previously been
        stored somewhere in the container. }
      { 2.a) There is more than one item equal to aitem in the
        container, or the exception was raised in the comparison just
        after aitem had been withdrawn from the structure -> this means
        that i points to a valid position where aitem can be safely put
        back, because if there are more items equal to aitem, they are
        placed just after where aitem had originally been; so aitem is
        compared only with items from this sequence and exchanged
        immediately after its end is found; therefore, when exception
        is raised i points either somewhere inside the sequence or to
        just after its end; we have to remove orgPtr from the chain,
        so we should move all items between orgPtr and i (not
        including i) to previous positions, and put aitem at the
        position just before i }
      { 2.b) There is only one item equal to aitem in the whole
        container -> just remove orgPtr and place aitem at the very end
        of the collision chain; }
      
      { orgPtr can't be at the first pos }
      p := FirstProbe;
      ii2 := GetIndex(h + p);
      
      while (ii2 <> i) and (FArray^.Items[ii2] <> orgPtr) do
      begin
         p := NextProbe(p);
         ii2 := GetIndex(h + p);
      end;
      
      if i <> ii2 then
         { aitem is not the pointer passed by the user  }
      begin
         ii := ii2;
         p := NextProbe(p);
         ii2 := GetIndex(h + p);
        
         if wasMoreThanOne then
            { 2.a }
         begin
            while (ii2 <> i) do
            begin
               { Hasher.Hash may raise and cause big problems, but it's
                 not very likely }
               if (FArray^.Items[ii2] = stDeleted) or
                     (GetIndex(Hasher.Hash(FArray^.Items[ii2])) = h) then
               begin
                  FArray^.Items[ii] := FArray^.Items[ii2];
                  ii := ii2;
               end;
               p := NextProbe(p);
               ii2 := GetIndex(h + p);
            end;
         end else
            { 2.b }
         begin
            while FArray^.Items[ii2] <> stFree do
            begin
               if (FArray^.Items[i] = stDeleted) or
                     (GetIndex(Hasher.Hash(FArray^.Items[ii2])) = h) then
               begin
                  FArray^.Items[ii] := FArray^.Items[ii2];
                  ii := ii2;
               end;
               p := NextProbe(p);
               ii2 := GetIndex(h + p);
            end;
         end;
         
         FArray^.Items[ii] := aitem;
      end;
      
      raise;
   end;
   
   Result := p;
   Inc(FArray^.Size);
   FFirstUsedIndex := -1;
end; { end DoInsert }

function TScatterTable.DoInsert(aitem : ItemType) : Boolean;
var
   dummy : IndexType;
   prevSize : SizeType;
begin
   prevSize := FArray^.Size;
   DoInsert(aitem, dummy);
   if prevSize <> FArray^.Size then
      Result := true
   else
      Result := false;
end;

function TScatterTable.GetCapacity : SizeType; 
begin
   Result := FArray^.Capacity;
end;

function TScatterTable.CalculateCapacity(ex : SizeType) : SizeType; 
begin
   Result := 1 shl ex;
end;

function TScatterTable.GetMaxFillRatio : SizeType; 
begin
   Result := (FMaxFillRatio*100) shr stRatioFactor;
end;

procedure TScatterTable.SetMaxFillRatio(fr : SizeType); 
begin
   FMaxFillRatio := (fr shl stRatioFactor) div 100;
end;

function TScatterTable.GetMinFillRatio : SizeType; 
begin
   Result := (FMinFillRatio * 100) shr stRatioFactor;
end;

procedure TScatterTable.SetMinFillRatio(fr : SizeType); 
begin
   FMinFillRatio := (fr shl stRatioFactor) div 100;
end;

{$ifdef TEST_PASCAL_ADT }
procedure TScatterTable.LogStatus(mname : String);
var
   m2ItemsInChain, itemsInChain, deletedPlaces, totalItemsInChains : SizeType;
   totalStepsSearchEx, stepsSearchEx, maxStepsSearchEx,
   m2StepsSearchEx : SizeType;
   avgStepsSearchUnex, avgStepsSearchEx : Double;
   varStepsSearchEx, varStepsSearchUnex : Double;
   h, h2, i : IndexType;
   p : SizeType;

begin
   inherited;
   
   deletedPlaces := 0;
   totalItemsInChains := 0;
   totalStepsSearchEx := 0;
   m2ItemsInChain := 0;
   m2stepsSearchEx := 0;
   maxStepsSearchEx := 0;
   
   with FArray^ do
   begin
      for h := 0 to FArray^.Capacity - 1 do
      begin
         if Items[h] <> stFree then
         begin
            itemsInChain := 0;
            if Items[h] = stDeleted then
               Inc(deletedPlaces)
            else begin
               Inc(itemsInChain);
               stepsSearchEx := 1;
               h2 := GetIndex(Hasher.Hash(Items[h]));
               if h2 <> h then
               begin
                  Inc(stepsSearchEx);
                  p := FirstProbe;
                  i := GetIndex(h2 + p);
                  while i <> h do
                  begin
                     Inc(stepsSearchEx);
                     p := NextProbe(p);
                     i := GetIndex(h2 + p);
                  end;
               end;
               Inc(totalStepsSearchEx, stepsSearchEx);
               if stepsSearchEx > maxStepsSearchEx then
                  maxStepsSearchEx := stepsSearchEx;
               Inc(m2StepsSearchEx, stepsSearchEx * stepsSearchEx);
            end;
            
            p := FirstProbe;
            i := GetIndex(h + p);
            while Items[i] <> stFree do
            begin
               if Items[h] <> stDeleted then
                  Inc(itemsInChain);
               p := NextProbe(p);
               i := GetIndex(h + p);
            end;
            Inc(totalItemsInChains, itemsInChain);
            Inc(m2ItemsInChain, itemsInChain * itemsInChain);
         end;
      end;
   end;
   Inc(m2ItemsInChain, FArray^.Capacity - FArray^.Size);
   
   Assert(deletedPlaces = FDeletedFields);
   
   avgStepsSearchUnex :=
      (FArray^.Capacity - FArray^.Size + totalItemsInChains) / FArray^.Capacity;
   varStepsSearchUnex := (m2ItemsInChain / FArray^.Capacity) -
      Sqr(avgStepsSearchUnex);
   avgStepsSearchEx := totalStepsSearchEx / FArray^.Size;
   varStepsSearchEx := m2StepsSearchEx / FArray^.Size -
      Sqr(avgStepsSearchEx);

   WriteLog('Number of cells marked ''deleted'':' + IntToStr(deletedPlaces));
   WriteLog('Maximum steps searching for an existing item: ' +
               IntToStr(maxStepsSearchEx));
   WriteLog('Average steps searching for an existing item: ' +
               FloatToStr(avgStepsSearchEx));
   WriteLog('Variance of steps searching for an existing item: ' +
               FloatToStr(varStepsSearchEx));
   WriteLog('Deviation of steps searching for an existing item: ' +
               FloatToStr(Sqrt(varStepsSearchEx)));
   WriteLog('Average steps searching for an unexisting item: ' +
               FloatToStr(avgStepsSearchUnex));
   WriteLog('Variance of steps searching for an unexisting item: ' +
               FloatToStr(varStepsSearchUnex));
   WriteLog('Deviation of steps searching for an unexisting item: ' +
               FloatToStr(Sqrt(varStepsSearchUnex)));
end;
{$endif TEST_PASCAL_ADT }

function TScatterTable.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt; 
begin
   Result := TScatterTable.CreateCopy(self, itemcopier);
end;

procedure TScatterTable.Swap(cont : TContainerAdt);
var
   table : TScatterTable;
begin
   if cont is TScatterTable then
   begin
      BasicSwap(cont);
      table := TScatterTable(cont);
      ExchangePtr(FArray, table.FArray);
      ExchangeData(FTableSize, table.FTableSize, SizeOf(SizeType));
      ExchangeData(FMinFillRatio, table.FMinFillRatio, SizeOf(SizeType));
      ExchangeData(FMaxFillRatio, table.FMaxFillRatio, SizeOf(SizeType));
      ExchangeData(FCanShrink, table.FCanShrink, SizeOf(Boolean));
      ExchangeData(FFirstUsedIndex, table.FFirstUsedIndex, SizeOf(IndexType));
      ExchangeData(FFirstUsedOffset, table.FFirstUsedOffset, SizeOf(SizeType));
      ExchangeData(FDeletedFields, table.FDeletedFields, SizeOf(SizeType));
   end else
      inherited;
end;

function TScatterTable.Start : TSetIterator; 
begin
   Result := TScatterTableIterator.Create(0, 0, self);
end;

function TScatterTable.Finish : TSetIterator; 
begin
   Result := TScatterTableIterator.Create(FArray^.Capacity, 0, self);
end;

&if (&_mcp_accepts_nil)
function TScatterTable.FindOrInsert(aitem : ItemType) : ItemType;
var
   h, i : IndexType;
   p : SizeType;
begin
   if RepeatedItems then
   begin
      Insert(aitem);
      Result := nil;
   end else
   begin
      CheckDeletedFields;
      
      h := GetIndex(Hasher.Hash(aitem));
      
      if (FArray^.Items[h] = stFree) then
      begin
         FArray^.Items[h] := aitem;
         Inc(FArray^.Size);
         FFirstUsedIndex := -1;
         Result := nil;
      end else if (FArray^.Items[h] <> stDeleted) and
                     _mcp_equal(FArray^.Items[h], aitem) then
      begin
         Result := FArray^.Items[h];
      end else
      begin
         p := FirstProbe;
         i := GetIndex(h + p);
         while (FArray^.Items[i] <> stFree) and
                  ((FArray^.Items[i] = stDeleted) or
                      (not _mcp_equal(FArray^.Items[i], aitem))) do
         begin
            p := NextProbe(p);
            i := GetIndex(h + p);
         end;
         
         if FArray^.Items[i] <> stFree then
         begin
            Result := FArray^.Items[i];
         end else
         begin
            FArray^.Items[i] := aitem;
            Inc(FArray^.Size);
            FFirstUsedIndex := -1;
            Result := nil;
         end;
      end;
   end;
end;

function TScatterTable.Find(aitem : ItemType) : ItemType;
var
   h, i : IndexType;
   p : SizeType;
begin
   CheckDeletedFields;
   
   h := GetIndex(Hasher.Hash(aitem));
   
   if (FArray^.Items[h] = stFree) then
   begin
      Result := nil;
   end else if (FArray^.Items[h] <> stDeleted) and
                  (_mcp_equal(FArray^.Items[h], aitem)) then
   begin
      Result := FArray^.Items[h];
   end else
   begin
      p := FirstProbe;
      i := GetIndex(h + p);
      while (FArray^.Items[i] <> stFree) and
               ((FArray^.Items[i] = stDeleted) or
                   (not _mcp_equal(FArray^.Items[i], aitem))) do
      begin
         p := NextProbe(p);
         i := GetIndex(h + p);
      end;
      Result := FArray^.Items[i];
   end;
end;
&endif &# end &_mcp_accepts_nil

function TScatterTable.Has(aitem : ItemType) : Boolean;
var
   h, i : IndexType;
   p : SizeType;
begin
   CheckDeletedFields;
   h := GetIndex(Hasher.Hash(aitem));
   
   if (FArray^.Items[h] = stFree) then
   begin
      Result := false;
   end else if (FArray^.Items[h] <> stDeleted) and
                  _mcp_equal(FArray^.Items[h], aitem) then
   begin
      Result := true;
   end else
   begin
      p := FirstProbe;
      i := GetIndex(h + p);
      while (FArray^.Items[i] <> stFree) and
               ((FArray^.Items[i] = stDeleted) or
                   (not _mcp_equal(FArray^.Items[i], aitem))) do
      begin
         p := NextProbe(p);
         i := GetIndex(h + p);
      end;
      Result := (FArray^.Items[i] <> stFree) and (FArray^.Items[i] <> stDeleted);
   end;
end;

function TScatterTable.Count(aitem : ItemType) : SizeType;
var
   h, i : IndexType;
   p : SizeType;
begin
   CheckDeletedFields;
   Result := 0;
   h := GetIndex(Hasher.Hash(aitem));
   
   if (FArray^.Items[h] = stFree) then
   begin
      Exit;
   end else if (FArray^.Items[h] = stDeleted) or
                  (not _mcp_equal(FArray^.Items[h], aitem)) then
   begin
      p := FirstProbe;
      i := GetIndex(h + p);
      while (FArray^.Items[i] <> stFree) and
               ((FArray^.Items[i] = stDeleted) or
                   (not _mcp_equal(FArray^.Items[i], aitem))) do
      begin
         p := NextProbe(p);
         i := GetIndex(h + p);
      end;
      
      if FArray^.Items[i] <> stFree then
      begin
         Inc(Result);
         p := NextProbe(p);
      end;
      
   end else
   begin
      Inc(Result);
      p := FirstProbe;
   end;
   
   i := GetIndex(h + p);
   while (FArray^.Items[i] <> stFree) do
   begin
      if FArray^.Items[i] <> stDeleted then
      begin
         if (_mcp_equal(FArray^.Items[i], aitem)) then
            Inc(Result)
         else if GetIndex(Hasher.Hash(FArray^.Items[i])) = h then
            break;
      end;
      
      p := NextProbe(p);
      i := GetIndex(h + p);
   end;
end;

function TScatterTable.Insert(pos : TSetIterator; aitem : ItemType) : Boolean;
begin
   Result := DoInsert(aitem);
end;

function TScatterTable.Insert(aitem : ItemType) : Boolean;
begin
   Result := DoInsert(aitem);
end;

procedure TScatterTable.Delete(pos : TSetIterator);
var
   i : IndexType;
begin
   Assert(pos is TScatterTableIterator, msgInvalidIterator);
   Assert(not pos.IsFinish, msgInvalidIterator);
   
   i := GetIndex(TScatterTableIterator(pos).FBase +
                    TScatterTableIterator(pos).FOffset);
   FFirstUsedIndex := -1;
   
   DisposeItem(FArray^.Items[i]);
   FArray^.Items[i] := stDeleted;
   Inc(FDeletedFields);
   Dec(FArray^.Size);
end;

function TScatterTable.Delete(aitem : ItemType) : SizeType;
var
   h, i : IndexType;
   p : SizeType;
begin
   CheckDeletedFields;
   Result := 0;
   h := GetIndex(Hasher.Hash(aitem));
   
   if h = FFirstUsedIndex then
   begin
      FFirstUsedIndex := -1;
      FFirstUsedOffset := -1;
   end; { otherwise the first used bucket is before h and our deleting
          cannot affect its position }
   
   if (FArray^.Items[h] <> stFree) then
   begin
      p := FirstProbe;
      i := GetIndex(h + p);
      
      if (FArray^.Items[h] <> stDeleted) and
            (_mcp_equal(FArray^.Items[h], aitem)) then
      begin
         DisposeItem(FArray^.Items[h]);
         FArray^.Items[h] := stDeleted;
         Inc(FDeletedFields);
         Inc(Result);
         Dec(FArray^.Size);
      end else
      begin
         while (FArray^.Items[i] <> stFree) and
                  ((FArray^.Items[i] = stDeleted) or
                      (not _mcp_equal(FArray^.Items[i], aitem))) do
         begin
            p := NextProbe(p);
            i := GetIndex(h + p);
         end;
      end;
      
      if FArray^.Items[i] <> stFree then
      begin
         repeat
            if (FArray^.Items[i] <> stDeleted) then
            begin
               if (_mcp_equal(FArray^.Items[i], aitem)) then
               begin
                  DisposeItem(FArray^.Items[i]);
                  FArray^.Items[i] := stDeleted;
                  Inc(FDeletedFields);
                  Inc(Result);
                  Dec(FArray^.Size);
               end else
               begin
                  if GetIndex(Hasher.Hash(Farray^.Items[i])) = h then
                     break;
               end;
            end;
            p := NextProbe(p);
            i := GetIndex(h + p);
         until (FArray^.Items[i] = stFree);
      end;
   end;
   CheckMinFillRatio;
end;

function TScatterTable.LowerBound(aitem : ItemType) : TSetIterator;
var
   i, h : IndexType;
   p : SizeType;
begin
   CheckDeletedFields;
   h := GetIndex(Hasher.Hash(aitem));
   
   if (FArray^.Items[h] = stFree) or ((FArray^.Items[h] <> stDeleted) and
            (_mcp_equal(FArray^.Items[h], aitem))) then
   begin
      Result := TScatterTableIterator.Create(h, 0, self);
   end else
   begin
      p := FirstProbe;
      i := GetIndex(h + p);
      while (FArray^.Items[i] <> stFree) and
               ((FArray^.Items[i] = stDeleted) or
                   (not _mcp_equal(FArray^.Items[i], aitem))) do
      begin
         p := NextProbe(p);
         i := GetIndex(h + p);
      end;
      Result := TScatterTableIterator.Create(h, p, self);
   end;
   
   AdvanceToNearestItem(TScatterTableIterator(Result).FBase,
                        TScatterTableIterator(Result).FOffset);
end;

function TScatterTable.UpperBound(aitem : ItemType) : TSetIterator; 
var
   i, h : IndexType;
   p : SizeType;
begin
   CheckDeletedFields;
   h := GetIndex(Hasher.Hash(aitem));
   
   p := FirstProbe;
   i := GetIndex(h + p);
   
   if (FArray^.Items[h] <> stFree) and ((FArray^.Items[h] = stDeleted) or
            (not _mcp_equal(FArray^.Items[h], aitem))) then
   begin
      while (FArray^.Items[i] <> stFree) and
               ((FArray^.Items[i] = stDeleted) or
                   (not _mcp_equal(FArray^.Items[i], aitem))) do
      begin
         p := NextProbe(p);
         i := GetIndex(h + p);
      end;
   end;
   
   while (FArray^.Items[i] <> stFree) and
            ((FArray^.Items[i] = stDeleted) or
                (_mcp_equal(FArray^.Items[i], aitem)) or
                (GetIndex(Hasher.Hash(FArray^.Items[i])) <> h)) do
   begin
      p := NextProbe(p);
      i := GetIndex(h + p);
   end;
   
   Result := TScatterTableIterator.Create(h, p, self);
   
   AdvanceToNearestItem(TScatterTableIterator(Result).FBase,
                        TScatterTableIterator(Result).FOffset);
end;

function TScatterTable.EqualRange(aitem : ItemType) : TSetIteratorRange; 
var
   i, h : IndexType;
   p : SizeType;
   iter1, iter2 : TScatterTableIterator;
begin
   CheckDeletedFields;
   h := GetIndex(Hasher.Hash(aitem));
   
   if (FArray^.Items[h] = stFree) or ((FArray^.Items[h] <> stDeleted) and
            (_mcp_equal(FArray^.Items[h], aitem))) then
   begin
      iter1 := TScatterTableIterator.Create(h, 0, self);
      p := FirstProbe;
   end else
   begin
      p := FirstProbe;
      i := GetIndex(h + p);
      while (FArray^.Items[i] <> stFree) and
               ((FArray^.Items[i] = stDeleted) or
                   (not _mcp_equal(FArray^.Items[i], aitem))) do
      begin
         p := NextProbe(p);
         i := GetIndex(h + p);
      end;
      iter1 := TScatterTableIterator.Create(h, p, self);
      p := NextProbe(p);
   end;
   
   i := GetIndex(h + p);
   
   while (FArray^.Items[i] <> stFree) and
            ((FArray^.Items[i] = stDeleted) or
                (_mcp_equal(FArray^.Items[i], aitem)) or
                (GetIndex(Hasher.Hash(FArray^.Items[i])) <> h)) do
   begin
      p := NextProbe(p);
      i := GetIndex(h + p);
   end;
   
   iter2 := TScatterTableIterator.Create(h, p, self);
   
   AdvanceToNearestItem(iter1.FBase, iter1.FOffset);
   AdvanceToNearestItem(iter2.FBase, iter2.FOffset);
   
   Result := TSetIteratorRange.Create(iter1, iter2);
end;

procedure TScatterTable.Rehash(ex : SizeType);
var
   oldtab : TDynamicArray;
   ii, dummy : IndexType;
   oldDelFields : SizeType;
begin
   Assert(FTableSize + ex >= stMinTableSize, msgWrongRehashArg);
   
{$ifdef TEST_PASCAL_ADT }
{   LogStatus('Rehash'); }
{$endif }
   
   oldtab := FArray;
   ArrayAllocate(FArray, CalculateCapacity(FTableSize + ex), 0); { may raise }
   FTableSize := FTableSize + ex;
   oldDelFields := FDeletedFields;
   FDeletedFields := 0;
   
   ZeroOutFArray;
   
   try
      for ii := 0 to oldtab^.Capacity - 1 do
      begin
         if (oldtab^.Items[ii] <> stFree) and (oldtab^.Items[ii] <> stDeleted) then
         begin
            DoInsert(oldtab^.Items[ii], dummy); { may raise }
         end;
      end;
      
   except
      ArrayDeallocate(FArray);
      FArray := oldtab;
      FTableSize := FTableSize - ex;
      FDeletedFields := oldDelFields;
   end;
   
   ArrayDeallocate(oldtab);
   
   FCanShrink := false;
end;

procedure TScatterTable.Clear;
var
   i : IndexType;
begin
   for i := 0 to FArray^.Capacity - 1 do
   begin
      if (FArray^.Items[i] <> stFree) and (FArray^.Items[i] <> stDeleted) then
      begin
         DisposeItem(FArray^.Items[i]);
      end;
      FArray^.Items[i] := stFree;
   end;
   FArray^.Size := 0;
   FDeletedFields := 0;
   
   GrabageCollector.FreeObjects;
end;

function TScatterTable.Empty : Boolean;
begin
   Result := FArray^.Size = 0;
end;

function TScatterTable.Size : SizeType; 
begin
   Result := FArray^.Size;
end;

function TScatterTable.MinCapacity : SizeType; 
begin
   Result := 1 shl stMinTableSize;
end;


{ -------------------------- TScatterTableIterator -------------------------- }

constructor TScatterTableIterator.Create(abase : IndexType; aoff : SizeType;
                                         tab : TScatterTable);
begin
   inherited Create(tab);
   FBase := abase;
   FOffset := aoff;
   FTable := tab;
   FTable.AdvanceToNearestItem(FBase, FOffset);
end;

function TScatterTableIterator.CopySelf : TIterator; 
begin
   Result := TScatterTableIterator.Create(FBase, FOffset, FTable);
end;

function TScatterTableIterator.Equal(const Pos : TIterator) : Boolean; 
begin
   Assert(pos is TScatterTableIterator, msgInvalidIterator);
   Result := (TScatterTableIterator(pos).FBase = FBase) and
      (TScatterTableIterator(pos).FOffset = FOffset);
end;

function TScatterTableIterator.GetItem : ItemType;
var
   ind : IndexType; { we have to use this variable because of a bug in
                      FPC 1.0.1 }
begin
   with FTable, FTable.FArray^ do
   begin
      ind := GetIndex(FBase + FOffset);
      
      Assert((Items[ind] <> stFree) and (Items[ind] <> stDeleted),
             msgReadingInvalidIterator);
      
      Result := Items[ind];
   end;
end;

procedure TScatterTableIterator.SetItem(aitem : ItemType);
var
   i : IndexType;
begin
   with FTable, FTable.FArray^ do
   begin
      Assert((Items[GetIndex(FBase + FOffset)] <> stFree) and
                (Items[GetIndex(FBase + FOffset)] <> stDeleted),
             msgReadingInvalidIterator);
//      Assert(GetIndex(Hasher.Hash(aitem)) = FBase, msgWrongHash);
      
      i := GetIndex(FBase + FOffset);
      if not _mcp_equal(Items[i], aitem) then
      begin
         DisposeItem(Items[i]);
         Items[i] := stDeleted;
         Dec(FArray^.Size);
         self.Insert(aitem);
      end else
      begin
         DisposeItem(Items[i]);
         Items[i] := aitem;
      end;
   end;   
end;

procedure TScatterTableIterator.ResetItem;
var
   i : IndexType;
   aitem : ItemType;
begin
   i := FTable.GetIndex(FBase + FOffset);
   with FTable.FArray^ do
   begin
      aitem := Items[i];
      Items[i] := stDeleted;
   end;
   Dec(FTable.FArray^.Size);
   Insert(aitem);
end;

procedure TScatterTableIterator.Advance;
begin
   Assert(FBase < FTable.FArray^.Capacity, msgAdvancingInvalidIterator);
   
   with FTable do
   begin
      if FOffset = 0 then
      begin
         FOffset := FirstProbe;
      end else
      begin
         FOffset := NextProbe(FOffset);
      end;
      AdvanceToNearestItem(FBase, FOffset);
   end;
end;

procedure TScatterTableIterator.Retreat;
var
   i, maxi : IndexType; 
   lastoff : SizeType;
begin
   with FTable.FArray^, FTable do
   begin
      { maxi is the index from which we are retreating }
      if FOffset = 0 then
      begin
         maxi := 0;
      end else
      begin
         maxi := GetIndex(FBase + FOffset);
      end;
      
      repeat
         if maxi = 0 then
         begin
            Dec(FBase);
            maxi := -1; { have to find the last index in the previous
                          sequence; the value of -1 won't make the
                          search stop prematurely }
            Assert(FBase >= 0, msgRetreatingStartIterator);
         end;
         
         { find the first non-empty collision chain }
         while Items[FBase] = stFree do
            Dec(FBase);
         
         lastoff := 0; { we have to keep lastoff, because we in fact
                         know we've reached an appropriate index only
                         just after this index itself }
         FOffset := FirstProbe;
         i := GetIndex(FBase + FOffset);
         { find the index just before maxi (or the penultimate index
           if we've moved to the previous collision chain) }
         while (Items[i] <> stFree) and (i <> maxi) do
         begin
            if (Items[i] <> stDeleted) and
                  (GetIndex(Hasher.Hash(Items[i])) = FBase) then
            begin
               lastoff := FOffset;
            end;
            FOffset := NextProbe(FOffset);
            i := GetIndex(FBase + FOffset);
         end;
         FOffset := lastoff;
         i := GetIndex(FBase + FOffset);
         if FOffset = 0 then
            maxi := 0
         else
            maxi := i;
      until (Items[i] <> stFree) and (Items[i] <> stDeleted) and
         (GetIndex(Hasher.Hash(Items[i])) = FBase);
      { the condition here is false if there are no items in the
        current collision chain } { ugly proc !!! rewrite later on !!}
   end;
end;

procedure TScatterTableIterator.Insert(aitem : ItemType);
var
   sizeBefore : SizeType;
begin
   with FTable do
   begin
      sizeBefore := FArray^.Size;
      FBase := GetIndex(Hasher.Hash(aitem));
      FOffset := DoInsert(aitem, FBase);
      if FArray^.Size = sizeBefore then
      begin
         FOffset := 0;
         FBase := FArray^.Capacity;
      end;
   end;
end;

function TScatterTableIterator.Extract : ItemType;
var
   i : IndexType;
begin
   with FTable.FArray^, FTable do
   begin
      if FFirstUsedIndex = FBase then
      begin
         FFirstUsedIndex := -1;
         FFirstUsedOffset := -1;
      end;
   
      i := GetIndex(FBase + FOffset);
      Assert((Items[i] <> stFree) and (Items[i] <> stDeleted),
             msgDeletingInvalidIterator);
      
      Result := Items[i];
      Items[i] := stDeleted;
      Inc(FDeletedFields);
      Dec(FArray^.Size);
      
      if FDeletedFields + FArray^.Size = FArray^.Capacity then
      begin
         FBase := FArray^.Capacity;
         FOffset := 0;
      end else
         Advance;
   end;
end;

function TScatterTableIterator.Owner : TContainerAdt; 
begin
   Result := Ftable;
end;

function TScatterTableIterator.IsStart : Boolean;
var
   isGood : Boolean;
   i : IndexType;
begin
   with Ftable.Farray^, Ftable do
   begin
      i := GetIndex(FBase + FOffset);
      isGood := (FBase < FArray^.Capacity) and (Items[i] <> stFree) and
         (Items[i] <> stDeleted) and (GetIndex(Hasher.Hash(Items[i])) = FBase);
      
      if (FBase = FARRAY^.Capacity) then
      begin
         Result := Size = 0;
      end else if (not isGood) or ((FOffset <> 0) and
                                      (Items[FBase] <> stDeleted) and
                                      (Hasher.Hash(Items[FBase]) =
                                          UnsignedType(FBase))) then
      begin
         Result := false;
      end else
      begin
         if FFirstUsedIndex = -1 then
         begin
            FFirstUsedIndex := 0;
            FFirstUsedOffset := 0;
            AdvanceToNearestItem(FFirstUsedIndex, FFirstUsedOffset);
         end;
         Result := (FBase = FFirstUsedIndex) and (FOffset = FFirstUsedOffset);
      end;
   end;
end;

function TScatterTableIterator.IsFinish : Boolean; 
begin
   Result := FBase = Ftable.FArray^.Capacity;
end;

&endif
