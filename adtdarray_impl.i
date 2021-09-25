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
 adtdarray_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtdarray.defs
&include adtdarray_impl.mcp

{$R-}

function ConsistentArray(a : TDynamicArray) : Boolean;
begin
   with a^ do
   begin
      Assert(Length(Items) = Capacity);
      Assert(Size <= Capacity);
      Assert(Size >= 0);
      Result := (StartIndex < Capacity) and (StartIndex >= 0);
   end;
end;

{ calculates new Size for TDynamicArray }
function CalculateNewSize(const a : TDynamicArray; n : SizeType;
                          circular : Boolean) : SizeType;
var
   neededCapacity : SizeType;
begin
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      neededCapacity := Size + n + SizeType(StartIndex);
      
      if capacity < daMaxMemChunk then
      begin
         if neededCapacity <= capacity * daGrowRate then
         begin
            Result := capacity * daGrowRate;
         end else
            Result := capacity + n;
      end else
      begin
         if neededCapacity <= capacity + daMaxMemChunk then
            Result := capacity + daMaxMemChunk
         else
            Result := capacity + n;
      end;
   end;
end;

{ calculates new Size for TDynamicBuffer. }
function CalculateNewBufferSize(b : TDynamicBuffer; n : SizeType) : SizeType;
begin
   if b^.capacity < bufMaxMemChunk then
   begin
      if n <= b^.capacity * bufGrowRate - b^.capacity then
         Result := b^.capacity * bufGrowRate
      else
         Result := b^.capacity + n;
   end else if bufMaxMemChunk <= n then
   begin
      Result := b^.capacity + bufMaxMemChunk;
   end else
      Result := b^.capacity + n;
end;

{ ========================================================================= }

procedure ArrayAllocate(var a : TDynamicArray; capacity : SizeType;
                        StartIndex : IndexType);
var
   a2 : TDynamicArray;
begin
   New(a2); { may raise, but harmless }
   try
      SetLength(a2^.Items, capacity); { may raise }
   except
      Dispose(a2);
   end;
   a := a2;
   a^.Size := 0;
   a^.Capacity := capacity;
   a^.StartIndex := StartIndex;
   Assert(ConsistentArray(a));
end;

procedure ArrayReallocate(var a : TDynamicArray; newcap : SizeType);
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   if a^.capacity <> newcap then
   begin
      SetLength(a^.Items, newcap);
      a^.Capacity := newcap;
   end;
end;

procedure ArrayDeallocate(var a : TDynamicArray);
begin
   if a <> nil then
   begin
      a^.Items := nil;
      Dispose(a);
      a := nil;
   end;
end;

procedure ArrayClear(var a : TDynamicArray; capacity : SizeType;
                     StartIndex : IndexType);
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));

   a^.Size := 0;
   a^.StartIndex := StartIndex;
   ArrayReallocate(a, capacity);
end;

procedure ArrayExpand(var a : TDynamicArray; n : SizeType);
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   if n <> 0 then
      ArrayReAllocate(a, CalculateNewSize(a, n, false));
end;

function ArrayGetItem(const a : TDynamicArray; index : IndexType) : ItemType;
begin
   Assert(IsValidIndex(index, a^.Size), msgInvalidIndex);
   Assert(ConsistentArray(a));
   
   Result := a^.Items[a^.StartIndex + index];
end;

function ArraySetItem(a : TDynamicArray; index : IndexType;
                      elem : ItemType) : ItemType;
begin
   with a^ do
   begin
      Assert(IsvalidIndex(index, a^.Size), msgInvalidIndex);
      Assert(ConsistentArray(a));
      
      Result := Items[StartIndex + index];
      Items[StartIndex + index] := elem;
   end;
end;

procedure ArrayReserveItems(var a : TDynamicArray; index : IndexType;
                            n : SizeType);
var
   i : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   if n <> 0 then
   begin
      with a^ do
      begin
         if SizeType(StartIndex) + Size + n > Capacity then
            ArrayExpand(a, n);
      end;
      with a^ do
      begin
         for i := StartIndex + Size + n - 1 downto StartIndex + index + n do
            Items[i] := Items[i - n];
         Inc(Size, n);
      end;
   end;
end;

procedure ArrayRemoveItems(a : TDynamicArray; index : IndexType; n : SizeType);
var
   i : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   if n <> 0 then
   begin
      with a^ do
      begin
         for i := StartIndex + index to StartIndex + Size - n do
            Items[i] := Items[i + n];
         Dec(Size, n);
      end;
   end;
end;

procedure ArrayPushFront(var a : TDynamicArray; elem : ItemType;
                         leaveSpaceAtFront : Boolean);
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      if Size = Capacity then
	 ArrayExpand(a, 1);
   end;
   
   with a^ do
   begin
      if Size <> 0 then
      begin
         if StartIndex = 0 then
         begin
            if leaveSpaceAtFront then
            begin
               StartIndex := (Capacity - Size) div 2;
            end;
            SafeMove(Items[0], Items[StartIndex + 1], Size);
         end else
         begin
            Dec(StartIndex);
         end;
      end;
      Items[StartIndex] := elem;
      Inc(Size);
   end;
end;

procedure ArrayPushBack(var a : TDynamicArray; elem : ItemType);
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));

   with a^ do
   begin
      if StartIndex + Size + 1 > Capacity then
	 ArrayExpand(a, 1);
   end;
   with a^ do
   begin
      Items[StartIndex + Size] := elem;
      Inc(Size);
   end;
end;

function ArrayPopFront(a : TDynamicArray; iftomove : Boolean) : ItemType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgPopEmpty);
   
   with a^ do
   begin
      Result := Items[StartIndex];
      Dec(Size);
      if Size <> 0 then
      begin
	 if iftomove then
	 begin
	    SafeMove(Items[StartIndex + 1], Items[StartIndex], Size);
	 end else 
	    Inc(StartIndex);
      end;
   end;
end;

function ArrayPopBack(a : TDynamicArray) : ItemType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgPopEmpty);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      Result := Items[StartIndex + Size - 1];
      Dec(Size);
   end;
end;

procedure ArrayCopy(const src : TDynamicArray; var dest : TDynamicArray);
var
   i : IndexType;
begin
   Assert(src <> nil, msgNilArray);
   
   ArrayDeallocate(dest);
   ArrayAllocate(dest, src^.Capacity, src^.StartIndex);
   dest^.Size := src^.Size;
   SetLength(dest^.Items, dest^.Capacity);
   for i := 0 to src^.Capacity - 1 do
      dest^.Items[i] := src^.Items[i];
end;

procedure ArrayApplyFunctor(a : TDynamicArray; const proc : IUnaryFunctor);
var
   i : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      for i := StartIndex to StartIndex + Size - 1 do
	 Items[i] := proc.Perform(Items[i]);
   end;
end;


{ --------------------------- Circular procedures ------------------------------- }


{ A description of the algorithm used in ArrayCircularMove: }

{ To understand the following algorithm let's look at three possible
  cases. }
{  (1) the distance from source to destination downwards is larger than the
   distance from destination to source downwards }
{  (2) the distance from destination and source is larger }
{  (3) these distances are equal }
{ When we speak of distances we mean the 'circular' distance, i.e. not
  the one computed by substracting appropriate indicies, but the true
  distance between two places with regard to the fact that the array
  does not have an end (it's circular). To clarify this a bit I
  present a picture showing possibility (2) with distances marked. }
{
                         +-------+ -+
                         |   7   |  |
                         |-------|  |
last element to move --> |   6   |  +-> distance from source to dest (= 3)
                         |-------|  |          (sddist)
         destination --> |   5   |  |
                         |-------| -+
                         |   4   |  |
                         |-------|  |
                         |   3   |  |
                         |-------|  |
                         |   2   |  +-> distance from dest to source (= 5)
                         |-------|  |          (dsdist)
                         |   1   |  |
                         |-------|  |
              source --> |   0   |  |
                         +-------+ -+

 For this picture:
 - the number of elements to move: n = 7;
 - capacity = 8;

 Note:
 - these two distances make up the whole capacity;
 - source is placed at the beginning of the array, but it doesn't
   matter because the array is circular, i.e. even if source is
   elsewhere we can treat its position as if it was at the beginning;
}
{ The algorithm works in the following way: it swaps subsequent
  elements with their proper destinations (after each swap, both the
  current source position and the currect destination position are
  incremented, circularly of course). When the current source position
  reaches the first (not current) destination position it is
  decremented by (capacity) mod (the distance from source to
  destination). Each swap, the number of elements to move is
  decremented. The algorithm stops when this number reaches 0. }
{ For brevity, let's call the distance from source to dest sddist,
  and the distance from dest to source dsdist;
}
{ Possibility (1): sddist > dsdist }
{ After the first dsdist swaps, first dsdist elements (at most) from
  the beginning have been moved to their proper places. If those
  places contained elements which should also have been moved, then
  those elements are now at the beginning, in the proper order. The
  current source position is decremented by capacity mod sddist =
  dsdist (because dsdist < sddist and dsdist + sddist =
  capacity). However, the destination position is not changed, so the
  subsequent elements are being moved after the first dsdist
  elements. And this is their proper position, because the elements
  currently at the beginning are the elements which were at positions
  after the first dsdist elems to dsdist*2, i.e. from the range
  <dsdist,2*dsdist). And the elements which are swapped in the second
  step (by one step I shall call the move of dsdist elements from the
  beginning and the subsequent decrementation of the current source
  position) are those from the range <dsdist*2, dsdist*3). Generally,
  if after the step k, the elements at the first dsdist positions are
  from the range <dsdist*k,dsdist*(k+1)) and the current destination
  position is the position of the source element number dsdist*(k+1),
  then in the step k+1 those elements (i.e. from the beginning) will
  go after the elements moved in the step k, and the first dsdist
  positions (or less if there are not so many elements to move) will
  contain the elements from <dsdist*(k+1),dsdist*(k+2)). So, by
  induction, the algorithm moves in each step at most dsdist elements
  to their proper places. Therefore, it does its job properly. }
{ Possibility (2): sddist < dsdist }
{ Let's call the act of swapping sddist elements a step. After the
  first step the first sddist positions contain at most sddist
  elements from the end of source sequence (or nothing if sequences do
  not overlap - in such a case the algorithm ends with proper result),
  and the sddist positions starting at destination position contain
  first elements from source. Current source and destination positions
  retain their values, so in the next step elements from source range
  <sddist,sddist*2) are swapped with elements from the end of source
  sequence (which are now at the beginning) and both current source
  and destination positions are incremented by sddist. This happens in
  each step, so after (capacity div sddist) - 1 steps only sddist +
  capacity mod sddist elements at positions immediately down to
  original destination position are not in proper places. First sddist
  of them (Sizeing from down upwards) are the elements from our end
  of sequence, and the remaining capacity mod sddist are the elements
  which should be placed where those aforementioned are. In the next
  step they are placed there and source reaches original
  destination. It is decremented by capacity mod sddist. Now elements
  to move in a step are the capacity mod sddist elements from the
  beginning of the chunk from the end of source sequence. And they
  will be moved to proper positions - after the elements which were
  originally just before dest. Again, the first capacity mod sddist
  elements from range <dest+sddist,n) will be just below original dest
  position. In next step they will be moved to proper places and next
  first ... and so on till all elements are placed where they should
  be. }
{ Possibility (3): sddist = dsdist }
{ If n (number of elems to move) is less than or equal sddist, then
  those elements will be just moved to proper positions. If n is
  greater (i.e. source and dest sequs overlap) the first sddist elems
  will be placed at positions starting at dest, and the remaining
  elems will be placed starting from the beginning, which is the
  behaviour expected, because the beginnig is the continuation of the
  sequence from the last positon. }
procedure ArrayCircularMove(a : TDynamicArray;
                            srcIndex, destIndex : IndexType; n : SizeType);
var
   source, dest, finish, destptr : PItemType;
   decr : SizeType;
   temp : ItemType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   if srcIndex = destIndex then
      Exit;

   finish := @a^.Items[a^.capacity];
   source := @a^.Items[srcIndex];
   dest := @a^.Items[destIndex];
   
   if srcIndex > destIndex then
      decr := srcIndex - destIndex
   else
      decr := a^.capacity - destIndex + srcIndex;
   decr := a^.capacity mod decr;
   destptr := dest; { a pointer to the beginning of the destination }
   
   while n <> 0 do
   begin
      temp := dest^;
      dest^ := source^;
      source^ := temp;
      
      Inc(dest);
      if dest = finish then
         Dec(dest, a^.capacity);
      
      Inc(source);
      if source = finish then
         Dec(source, a^.capacity);
      
      if source = destptr then
      begin
         Dec(source, decr);
      end;

      Dec(n);
   end;
end;

procedure ArrayCircularExpand(var a : TDynamicArray; n : SizeType);
var
   newcap, tomove : SizeType;
   buf : TDynamicArray;
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));

   newcap := CalculateNewSize(a, n, true);
   
   with a^ do
   begin
      New(buf);
      SetLength(buf^.Items, newcap);

      if StartIndex + Size > capacity then
	 tomove := capacity - StartIndex
      else
	 tomove := Size;
      { is this ok? does it work with Strings? are the references
        automatically adjusted or not? }
      SafeMove(Items[StartIndex], buf^.Items[0], tomove);
      if StartIndex + Size > capacity then
      begin
	 SafeMove(Items[0], buf^.Items[tomove], (StartIndex + Size - capacity));
      end;
      buf^.Size := Size;
      buf^.Capacity := newcap;
      a^.Items := nil;
      Dispose(a);
   end;
   a := buf;
   a^.StartIndex := 0;
end;

function ArrayCircularLogicalToAbs(const a : TDynamicArray;
                                   logindex : IndexType) : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(logindex < a^.capacity, msgInvalidIndex);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      Result := StartIndex + logIndex;
      if Result >= capacity then
	 Dec(Result, capacity);
   end;
end;

function ArrayCircularGetItem(const a : TDynamicArray;
                              index : IndexType) : ItemType;
var
   ind : SizeType;
begin
   Assert(a <> nil, msgNilArray);
   Assert((a^.StartIndex >= 0) and (index >= 0), msgInvalidIndex);
   Assert(index < a^.Capacity, msgInvalidIndex);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      ind := StartIndex + index;
      if ind >= capacity then
	 Dec(ind, capacity);

      Result := Items[ind];
   end;
end;

function ArrayCircularSetItem(a : TDynamicArray; index : IndexType;
                              elem : ItemType) : ItemType;
var
   ind : SizeType;
begin
   Assert(a <> nil, msgNilArray);
   Assert((a^.StartIndex >= 0) and (index >= 0), msgInvalidIndex);
   Assert(index < a^.Capacity, msgInvalidIndex);
   Assert(ConsistentArray(a));

   with a^ do
   begin
      ind := StartIndex + index;
      if ind >= capacity then
	 Dec(ind, capacity);

      Result := Items[ind];
      Items[ind] := elem;
   end;
end;

procedure ArrayCircularReserveItems(var a : TDynamicArray;
                                    index : IndexType; n : SizeType);
begin
   Assert(a <> nil, msgNilArray);
   
   with a^ do
   begin
      if Size + n > Capacity then
	 ArrayCircularExpand(a, n);
   end;
   with a^ do
   begin
      ArrayCircularMove(a, (StartIndex + index) mod Capacity,
                        (StartIndex + index + n) mod Capacity,
                        Size - index);
      Inc(Size, n);
   end;
end;

procedure ArrayCircularRemoveItems(a : TDynamicArray;
                                   index : IndexType; n : SizeType);
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      ArrayCircularMove(a, (StartIndex + index + n) mod Capacity,
                        (StartIndex + index) mod Capacity,
			Size - (index + n));
      Dec(Size, n);
   end;
end;

procedure ArrayCircularPushFront(var a : TDynamicArray;
                                 elem : ItemType);
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      if Size + 1 > capacity then
	 ArrayCircularExpand(a, 1);
   end;
   with a^ do
   begin
      Dec(StartIndex);
      if StartIndex < 0 then
	 Inc(StartIndex, capacity);
      Items[StartIndex] := elem;
      Inc(Size);
   end;
end;

procedure ArrayCircularPushBack(var a : TDynamicArray;
                                elem : ItemType);
var
   ind : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   
   with a^ do
   begin
      if Size + 1 > Capacity then
	 ArrayCircularExpand(a, 1);
   end;
   with a^ do
   begin
      ind := StartIndex + Size;
      if ind >= capacity then
	 Dec(ind, capacity);
      Items[ind] := elem;
      Inc(Size);
   end;
end;

function ArrayCircularPopFront(a : TDynamicArray) : ItemType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgPopEmpty);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      Result := Items[StartIndex];
      Inc(StartIndex);
      if StartIndex >= Capacity then
	 Dec(StartIndex, capacity);

      Dec(Size);
   end;
end;

function ArrayCircularPopBack(a : TDynamicArray) : ItemType;
var
   ind : indexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgPopEmpty);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      ind := StartIndex + Size - 1;
      if ind >= Capacity then
         Dec(ind, capacity);
      
      Result := Items[ind];
      
      Dec(Size);
   end;
end;

procedure ArrayCircularApplyFunctor(a : TDynamicArray;
                                    const proc : IUnaryFunctor);
var
   i : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(ConsistentArray(a));
   
   with a^ do
   begin
      if StartIndex + Size > Capacity then
      begin
         for i := StartIndex to Capacity - 1 do
            Items[i] := proc.Perform(Items[i]);
         for i := 0 to StartIndex + Size - Capacity - 1 do
            Items[i] := proc.Perform(Items[i]);
      end else
      begin
         for i := StartIndex to StartIndex + Size - 1 do
            Items[i] := proc.Perform(Items[i]);
      end;
   end;
end;


{ TDynamicBuffer routines }

procedure BufferAllocate(var b : TDynamicBuffer; capacity : SizeType);
var
   b2 : TDynamicBuffer;
begin
   New(b2);
   try
      SetLength(b2^.Items, capacity);
   except
      Dispose(b2);
   end;
   b := b2;
   b^.capacity := capacity;
end;

procedure BufferReallocate(var b : TDynamicBuffer; newcap : SizeType);
begin
   SetLength(b^.Items, newcap);
   b^.capacity := newcap;
end;

procedure BufferDeallocate(var b : TDynamicBuffer);
begin
   if b <> nil then
   begin
      b^.Items := nil;
      Dispose(b);
      b := nil;
   end;
end;

procedure BufferExpand(var b : TDynamicBuffer; n : SizeType);
begin
   BufferReallocate(b, CalculateNewBufferSize(b, n));
end;

procedure BufferCopy(const src : TDynamicBuffer; var dest : TDynamicBuffer);
var
   i : IndexType;
begin
   if dest <> nil then
   begin
      BufferReallocate(dest, src^.capacity);
   end else
   begin
      BufferAllocate(dest, src^.Capacity);
   end;
   
   for i := 0 to dest^.Capacity - 1 do
      dest^.Items[i] := src^.Items[i];
end;

