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
 adtsegarray_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtsegarray.defs
&include adtsegarray_impl.mcp


{$R-}

{ ------------------------------------------------------------------------- }

function SegArrayValid(a : TSegArray) : Boolean;
var
   shouldBe : SizeType;
begin
   Assert(a^.Segments <> nil);
   if a^.LastSegIndex <> a^.FirstSegIndex then
   begin
      shouldBe := (a^.LastSegIndex - a^.FirstSegIndex) * saSegmentCapacity -
         a^.InnerStartIndex + a^.ItemsInLastSeg;
   end else
   begin
      shouldBe := a^.ItemsInLastSeg;
   end;
   Result := shouldBe = a^.Size;
end;

procedure SegArrayAllocate(var a : TSegArray;
                           segments : SizeType;
                           StartIndex1, StartIndex2 : IndexType);
var
   db : TDynamicBuffer;
begin
   if segments <= 0 then
      segments := 1;
   
   New(a);
   ArrayAllocate(a^.Segments, segments, StartIndex1);
   a^.InnerStartIndex := StartIndex2;
   a^.FirstSegIndex := StartIndex1;
   a^.Size := 0;
   a^.ItemsInLastSeg := 0;
   a^.LastSegIndex := a^.FirstSegIndex;
   
   BufferAllocate(db, saSegmentCapacity);
   with a^.Segments^ do
   begin
      Items[a^.FirstSegIndex] := db;
      Size := 1;
   end;
   
   Assert(SegArrayValid(a));
end;

procedure SegArrayDeallocate(var a : TSegArray);
var
   i : IndexType;
begin
   if a <> nil then
   begin
      Assert(SegArrayValid(a));
      
      with a^.Segments^ do
      begin
         for i := StartIndex to StartIndex + Size - 1 do
            BufferDeallocate(TDynamicBuffer(Items[i]));
      end;
      ArrayDeallocate(a^.Segments);
      Dispose(a);
      a := nil;
   end;
end;

procedure SegArrayClear(var a : TSegArray; segments : SizeType);
var
   db : TDynamicBuffer;
   i : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(SegArrayValid(a));
   
   if segments <= 0 then
      segments := 1;
   
   with a^.Segments^ do
   begin
      for i := StartIndex + 1 to StartIndex + Size - 1 do
         BufferDeallocate(TDynamicBuffer(Items[i]));
      db := Items[StartIndex];
   end;
   ArrayClear(a^.Segments, segments, segments div 2);
   
   with a^.Segments^ do
   begin
      Items[StartIndex] := db;
      Size := 1;
   end;
      
   a^.FirstSegIndex := segments div 2;
   with a^ do
   begin
      LastSegIndex := FirstSegIndex;
      Size := 0;
      ItemsInLastSeg := 0;
      InnerStartIndex := saSegmentCapacity div 2;
   end;
end;

procedure SegArrayExpandRight(a : TSegArray; n : SizeType);
var
   newSegs : SizeType;
   segsToAlloc : IndexType; { may be negative }
   i : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(SegArrayValid(a));
   
   with a^.Segments^ do
   begin
      newSegs := n div saSegmentCapacity + 1;
      segsToAlloc := StartIndex + Size + newSegs - Capacity;
   end;
   
   if SegsToAlloc > 0 then
      ArrayExpand(a^.Segments, SegsToAlloc);
   
   with a^.Segments^ do
   begin
      for i := StartIndex + Size to StartIndex + Size + newSegs - 1 do
         BufferAllocate(TDynamicBuffer(Items[i]), saSegmentCapacity);
      Inc(Size, NewSegs);
   end;
end;

procedure SegArrayExpandLeft(a : TSegArray; n : SizeType);
var
   newSegs, SegsToAlloc : SizeType;
   i, diff : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(SegArrayValid(a));
   
   with a^.Segments^ do
   begin
      newSegs := n div saSegmentCapacity + 1;
      SegsToAlloc := newSegs - StartIndex; { (StartIndex - newSegs) - StartIndex }
   end;
   if SegsToAlloc > 0 then
   begin
      with a^ do
      begin
         ArrayExpand(Segments, SegsToAlloc);
         with Segments^ do
         begin
            diff := (Capacity - Size) div 2;
            SafeMove(Items[StartIndex], Items[StartIndex + diff], Size);
            StartIndex := StartIndex + diff;
         end;
         FirstSegIndex := FirstSegIndex + diff;
         LastSegIndex := LastSegIndex + diff;
      end;
   end;
   with a^.Segments^ do
   begin
      for i := StartIndex - 1 downto StartIndex - newSegs do
         BufferAllocate(TDynamicBuffer(Items[i]), saSegmentCapacity);
      Inc(Size, NewSegs);
      Dec(StartIndex, newSegs);
   end;
end;

procedure SegArrayLogicalToSegOff(const a : TSegArray; index : IndexType;
                                  var segment, offset : IndexType);
begin
   Assert(a <> nil, msgNilArray);
   Assert(SegArrayValid(a));
   { no assertion of validity of index due to fairly low-level of this
     proc }
   
   with a^ do
   begin
      segment := index div saSegmentCapacity + FirstSegIndex;
      offset := index mod saSegmentCapacity + InnerStartIndex;

      if offset >= saSegmentCapacity then
      begin
         Inc(segment);
         Dec(offset, saSegmentCapacity);
      end;
   end;
end;

function SegArrayGetItem(const a : TSegArray; index : IndexType) : ItemType;
var
   ind, SegInd : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgReadEmpty);
   Assert(IsValidIndex(index, a^.Size), msgInvalidIndex);
   Assert(SegArrayValid(a));
   
   SegArrayLogicalToSegOff(a, index, SegInd, ind);
   with a^.Segments^ do
      Result := TDynamicBuffer(Items[segInd])^.Items[ind];
end;

function SegArraySetItem(a : TSegArray; index : IndexType;
                         elem : ItemType) : ItemType;
var
   db : TDynamicBuffer;
   ind, SegInd : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgReadEmpty);
   Assert(IsValidIndex(index, a^.Size), msgInvalidIndex);
   Assert(SegArrayValid(a));
   
   SegArrayLogicalToSegOff(a, index, SegInd, ind);
   with a^.Segments^ do
      db := TDynamicBuffer(Items[segInd]);
   
   Result := db^.Items[ind];
   db^.Items[ind] := elem;
end;

procedure SegArrayPushFront(a : TSegArray; elem : ItemType);
var
   db : TDynamicBuffer;
   diff : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(SegArrayValid(a));
   
   db := TDynamicBuffer(a^.Segments^.Items[a^.FirstSegIndex]);
   Dec(a^.InnerStartIndex);
   if (a^.InnerStartIndex < 0) then
   begin
      a^.InnerStartIndex := saSegmentCapacity - 1;
      Dec(a^.FirstSegIndex);
      if a^.FirstSegIndex < a^.Segments^.StartIndex then
      begin
         diff := a^.Segments^.StartIndex - 1;
         BufferAllocate(db, saSegmentCapacity);
         { true - may change StartIndex, i.e. move items to some other
           location - we need to adjust FirstSegIndex and LastSegIndex }
         ArrayPushFront(a^.Segments, db, true); 
         diff := a^.Segments^.StartIndex - diff;
         a^.FirstSegIndex := a^.FirstSegIndex + diff;
         a^.LastsegIndex := a^.LastSegIndex + diff;
      end;
      db := TDynamicBuffer(a^.Segments^.Items[a^.FirstSegIndex]);
      
   end else if a^.LastSegIndex = a^.FirstSegIndex then
   begin
      Inc(a^.ItemsInLastSeg);
   end;   
   db^.Items[a^.InnerStartIndex] := elem;
   Inc(a^.Size);
end;

procedure SegArrayPushBack(a : TSegArray; elem : ItemType);
var
   lastSeg : TDynamicBuffer;
   InnerStart : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(SegArrayValid(a));
   
   with a^ do
   begin
      if LastSegIndex <> FirstSegIndex then
         InnerStart := 0
      else
         InnerStart := InnerStartIndex;
      
      if InnerStart + ItemsInLastSeg = saSegmentCapacity then
      begin
	 Inc(LastSegIndex);
	 if LastSegIndex >= Segments^.StartIndex + Segments^.Size then
	 begin
	    BufferAllocate(lastSeg, saSegmentCapacity);
	    ArrayPushBack(Segments, lastSeg);
	 end;
	 ItemsInLastSeg := 0;
         InnerStart := 0;
      end;
      lastSeg := TDynamicBuffer(Segments^.Items[lastSegIndex]);
      
      Inc(ItemsInLastSeg);
      lastSeg^.Items[InnerStart + ItemsInLastSeg - 1] := elem;
      
      Inc(a^.Size);
   end;
end;

function SegArrayPopFront(a : TSegArray) : ItemType;
var
   db : TDynamicBuffer;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgPopEmpty);
   Assert(SegArrayValid(a));
   
   with a^ do
   begin
      db := TDynamicBuffer(Segments^.Items[FirstSegIndex]);
      Result := db^.Items[InnerStartIndex];
      
      if FirstSegIndex = LastSegIndex then
         Dec(ItemsInLastSeg);
      
      Inc(InnerStartIndex);
      if InnerStartIndex = saSegmentCapacity then
      begin
         if FirstSegIndex <> LastSegIndex then
         begin
            if Segments^.StartIndex < FirstSegIndex then
            begin
               BufferDeallocate(TDynamicBuffer(Segments^.Items[Segments^.StartIndex]));
               Inc(Segments^.StartIndex);
               Dec(Segments^.Size);
            end;
            Inc(FirstSegIndex);
            InnerStartIndex := 0;
         end else
         begin
            { set the InnerStartIndex to some sensible value, we may
              do it becuase the array is now empty }
            InnerStartIndex := saSegmentCapacity div 2; 
         end;
      end;
      Dec(a^.Size);
   end;
end;

function SegArrayPopBack(a : TSegArray) : ItemType;
var
   lastSeg : TDynamicBuffer;
   InnerStart : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(a^.Size <> 0, msgPopEmpty);
   Assert(SegArrayValid(a));
   
   with a^ do
   begin
      if FirstSegIndex <> LastSegIndex then
         InnerStart := 0
      else
         InnerStart := InnerStartIndex;
      
      lastSeg := TDynamicBuffer(Segments^.Items[lastSegIndex]);
      Result := lastSeg^.Items[InnerStart + ItemsInLastSeg - 1];
      
      Dec(ItemsInLastSeg);
      
      if ItemsInLastSeg = 0 then
      begin
         if LastSegIndex <> FirstSegIndex then
         begin
            if lastSegIndex < Segments^.StartIndex + Segments^.Size - 1 then
            begin
               with Segments^ do
                  BufferDeallocate(TDynamicBuffer(Items[StartIndex + Size - 1]));
               Dec(Segments^.Size);
            end;
            Dec(lastSegIndex);
            if LastSegIndex <> FirstSegIndex then
               ItemsInLastSeg := saSegmentCapacity
            else
               ItemsInLastSeg := saSegmentCapacity - InnerStartIndex;
         end else
         begin
            InnerStartIndex := saSegmentCapacity div 2;
         end;
      end;
      
      Dec(a^.Size);
   end;
end;

procedure SegArrayReserveItems(a : TSegArray; index : IndexType; n : SizeType);

   { returns true if there is enough space at the back of a to hold n
     items }
   function IsSpaceAtBack : Boolean;
   begin
      with a^ do
      begin
         Result := (Segments^.Size -
                (FirstSegIndex - Segments^.StartIndex)) * saSegmentCapacity -
               (a^.Size + a^.InnerStartIndex) >= n;
      end;
   end;

var
   destSeg, destOff, srcSeg, srcOff, FirstSrcSeg, FirstSrcOff : IndexType;
   InnerStart : IndexType;
   freeSpaceInLastSeg : SizeType;
   destBuf, srcBuf : TDynamicBuffer;
begin
   Assert(a <> nil, msgNilArray);
   Assert(IsValidIndex(index, a^.Size) or (index = a^.Size), msgInvalidIndex);
   Assert(SegArrayValid(a));
   
   if n = 0 then
      Exit;
      
   if index = 0 then
      { reserving at the front (no need to move items), the array may
        be empty }
   begin
      with a^ do
      begin
         if n > (FirstSegIndex - Segments^.startIndex) * saSegmentCapacity +
               InnerStartIndex then
         begin
            SegArrayExpandLeft(a, n);
         end;
         
         Inc(a^.Size, n);
         
         if FirstSegIndex = LastSegIndex then
            Inc(ItemsInLastSeg, Min(InnerStartIndex, n));
         
         if n > InnerStartIndex then
         begin
            Dec(n, InnerStartIndex);
            Dec(firstSegIndex, n div saSegmentCapacity);
            if (n mod saSegmentCapacity) <> 0 then
            begin
               InnerStartIndex := saSegmentCapacity - (n mod saSegmentCapacity);
               Dec(FirstSegIndex);
            end else
            begin
               InnerStartIndex := 0;
            end;
         end else
         begin
            Dec(InnerStartIndex, n);
         end;
      end;
   end else if index = a^.Size then
      { array is non-empty, reserving at the back (no need to move
        items), index is not the first index in the array }
   begin
      with a^ do
      begin
         if not IsSpaceAtBack then
         begin
            SegArrayExpandRight(a, n);
         end;
         
         Inc(a^.Size, n);
         
         freeSpaceInLastSeg := saSegmentCapacity - ItemsInLastSeg;
         if FirstSegIndex = LastSegIndex then
            Dec(freeSpaceInLastSeg, InnerStartIndex);
         
         if n > freeSpaceInLastSeg then
         begin
            Dec(n, freeSpaceInLastSeg);
            Inc(LastSegIndex, n div saSegmentCapacity);
            ItemsInLastSeg := n mod saSegmentCapacity;
            if ItemsInLastSeg <> 0 then
            begin
               Inc(LastSegIndex);
            end;
         end else
         begin
            Inc(ItemsInLastSeg, n);
         end;
      end;
   end else
   begin
      { array is non-empty, reserving somewhere in the middle }
      with a^ do
      begin
         if not IsSpaceAtBack then
         begin
            SegArrayExpandRight(a, n);
         end;
         
         srcseg := LastSegIndex;
         srcOff := ItemsInLastSeg - 1; { does not work if array is empty !!! }
         if LastSegIndex = FirstSegIndex then
            Inc(srcOff, InnerStartIndex);
         
         SegArrayLogicalToSegOff(a, index - 1, FirstSrcSeg, FirstSrcOff);
         
         destSeg := srcSeg + (n div saSegmentCapacity);
         destOff := srcOff + (n mod saSegmentCapacity);
         if destOff >= saSegmentCapacity then
         begin
            Inc(destSeg);
            Dec(destOff, saSegmentCapacity);
         end;
         
         destBuf := TDynamicBuffer(Segments^.Items[destSeg]);
         srcBuf := TDynamicBuffer(Segments^.Items[srcSeg]);
         
         while (srcSeg <> firstSrcSeg) or (srcOff <> FirstSrcOff) do
         begin
            destBuf^.Items[destOff] := srcBuf^.Items[srcOff];
            
            Dec(destOff);
            if DestOff < 0 then
            begin
               DestOff := saSegmentCapacity - 1;
               Dec(destSeg);
               destBuf := TDynamicBuffer(Segments^.Items[destSeg]);
            end;
            
            Dec(srcOff);
            if srcOff < 0 then
            begin
               srcOff := saSegmentCapacity - 1;
               Dec(srcSeg);
               srcBuf := TDynamicBuffer(Segments^.Items[srcSeg]);
            end;
         end;
         
         { these several lines are always a source of potential bugs -
           check them first if anything's wrong }
         
         if FirstSegIndex <> LastSegIndex then
            InnerStart := 0
         else
            InnerStart := InnerStartIndex;
         
         Inc(ItemsInLastSeg, n); { now ItemsInLastSeg > 0 }
         { this -1 is necessary, because otherwise LastSegIndex would
           be increased 1 too much when ItemsInLastSeg + InnerStart =
           saSegmentCapacity (after increasing ItemsInLastSeg) }
         { ItemsInLastSeg has valid values from 1 to saSegCapacity -
           it denotes the size of the last segnent - the _number_ of
           items, but the mod operation is correct for _indicies_,
           which are 0-based }
         Inc(LastSegIndex, (ItemsInLastSeg + InnerStart - 1) div saSegmentCapacity);
         { we just convert ItemsInLastSeg into "index to last item in
           seg", and then back to the _number_ of items; we refrain
           from doing this if LastSegIndex was not actually increased,
           because it would require taking into account InnerStart
           when converting back }
         if ItemsInLastSeg + InnerStart > saSegmentCapacity then
            ItemsInLastSeg := ((ItemsInLastSeg + InnerStart - 1) mod saSegmentCapacity) + 1;
         // this was an imperfect guard against the situation mentioned above, but it failed
{         if ItemsInLastSeg = 0 then
         begin
            Dec(LastSegIndex);
            ItemsInLastSeg := saSegmentCapacity;
         end;}
      end;
      Inc(a^.Size, n);
   end;
end;

procedure SegArrayRemoveItems(a : TSegArray; index : IndexType; n : SizeType);
var
   destBuf, srcBuf : TDynamicBuffer;
   destSeg, srcSeg, destOff, srcOff, finishOff, finishSeg : IndexType;
   i : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(IsValidIndex(index, a^.Size), msgInvalidIndex);
   Assert(a^.Size - index >= n, msgInvalidIndex);
   Assert(SegArrayValid(a));
   
   if n = 0 then
      Exit;
   
   if index = 0 then
      { removing from the front (no need to move items) }
   begin
      with a^ do
      begin
//         WriteLn(n, ' ', Size, ' ', InnerStartIndex, ' ', ItemsInLastSeg, ' ', FirstSegIndex, ' ', LastSegIndex);
         Dec(a^.Size, n);         
         Inc(innerStartIndex, n);
         
         if InnerStartIndex >= saSegmentCapacity then
         begin
            Inc(FirstSegIndex, InnerStartIndex div saSegmentCapacity);
            InnerStartIndex := InnerStartIndex mod saSegmentCapacity;
            
            { may happen when removing all items }
            if LastSegIndex < FirstSegIndex then
            begin
               Assert(a^.Size = 0, msgInternalError);
               FirstSegIndex := LastSegIndex;
               InnerStartIndex := saSegmentCapacity div 2;
            end;
            
            if LastSegIndex = FirstSegIndex then
            begin
               Assert(Size <= saSegmentCapacity - InnerStartIndex);
               ItemsInLastSeg := Size; // Min(saSegmentCapacity - InnerStartIndex, Size) ???;
            end;
            
            for i := Segments^.StartIndex to FirstSegIndex - 2 do
            begin
               BufferDeallocate(TDynamicBuffer(Segments^.Items[i]));
               Dec(Segments^.Size);
               Inc(Segments^.StartIndex);
            end;
            
{            if Segments^.StartIndex <= FirstSegindex - 2 then
            begin
               Dec(Segments^.Size, FirstSegIndex - 1 - Segments^.StartIndex);
               Segments^.StartIndex := FirstSegIndex - 1;
            end;}
         end else if LastSegIndex = FirstSegIndex then
         begin
            Dec(ItemsInLastSeg, n);
         end;
//         WriteLn(n, ' ', Size, ' ', InnerStartIndex, ' ', ItemsInLastSeg, ' ', FirstSegIndex, ' ', LastSegIndex);
      end;
   end else
      { removing from the middle or from the back }
   begin
      with a^ do
      begin
         SegArrayLogicalToSegOff(a, index + n, srcSeg, srcOff);
         SegArrayLogicalToSegOff(a, index, destSeg, destOff);
         
         finishOff := ItemsInLastSeg;
         if LastSegIndex = FirstSegIndex then
            finishOff := finishOff + InnerStartIndex;
         
         if finishOff = saSegmentCapacity then
         begin
            finishOff := 0;
            finishSeg := lastSegIndex + 1;
         end else
            finishSeg := lastSegIndex;
         
         destBuf := TDynamicBuffer(Segments^.Items[destSeg]);
         srcBuf := TDynamicBuffer(Segments^.Items[srcSeg]);
         
         { if removing from the back items are not moved anyway,
           because index + n points to the finish position at the
           start of this loop }
         while (srcSeg <> finishSeg) or (srcOff <> finishOff) do
         begin
            destBuf^.Items[destOff] := srcBuf^.Items[srcOff];
            
            Inc(destOff);
            if DestOff >= saSegmentCapacity then
            begin
               DestOff := 0;
               Inc(destSeg);
               destBuf := TDynamicBuffer(Segments^.Items[destSeg]);
            end;
            
            Inc(srcOff);
            if srcOff >= saSegmentCapacity then
            begin
               srcOff := 0;
               Inc(srcSeg);
               srcBuf := TDynamicBuffer(Segments^.Items[srcSeg]);
            end;
         end;
         
         Dec(ItemsInLastSeg, n);
         Dec(a^.Size, n);
         
         if a^.Size = 0 then
         begin   
            ItemsInLastSeg := 0;
            LastSegIndex := FirstSegIndex;
            InnerStartIndex := saSegmentCapacity div 2;
         end else if ItemsInLastSeg <= 0 then
         begin
            Dec(LastSegIndex, (-ItemsInLastSeg div saSegmentCapacity) + 1);
            ItemsInLastSeg := saSegmentCapacity -
               (-ItemsinLastSeg mod saSegmentCapacity);
            if LastSegIndex = FirstSegIndex then
               Dec(ItemsInLastSeg, InnerStartIndex);
         end;
         
         for i := LastSegIndex + 2 to Segments^.StartIndex + Segments^.Size - 1 do
         begin
            BufferDeallocate(TDynamicBuffer(Segments^.Items[i]));
            Dec(Segments^.Size);
         end;
         
{         if LastSegIndex + 2 - Segments^.StartIndex <= Segments^.Size then
         begin
            Segments^.Size := LastSegIndex + 2 - Segments^.StartIndex;
         end;}
      end;
   end;
end;

procedure SegArrayCopy(const src : TSegArray; var dest : TSegArray);
var
   i : IndexType;
begin
   Assert(SegArrayValid(src));
   
   SegArrayDeallocate(dest);
   New(dest);
   
   with dest^ do
   begin
      Size := src^.Size;
      FirstSegIndex := src^.FirstSegIndex;
      LastSegIndex := src^.LastSegIndex;
      InnerStartIndex := src^.InnerStartIndex;
      ItemsInLastSeg := src^.ItemsInLastSeg;
      ArrayAllocate(Segments, src^.Segments^.Capacity, src^.Segments^.StartIndex);
   end;
   
   with dest^.Segments^ do
   begin
      StartIndex := src^.Segments^.StartIndex;
      Size := src^.Segments^.Size;
      
      for i := StartIndex to Size + StartIndex - 1 do
      begin
         Items[i] := nil;
         BufferCopy(TDynamicBuffer(src^.Segments^.Items[i]),
                    TDynamicBuffer(Items[i]));
      end;
   end;
end;

procedure SegArrayApplyFunctor(a : TSegArray; const proc : IUnaryFunctor);
var
   db : TDynamicBuffer;
   i, j : IndexType;
begin
   Assert(a <> nil, msgNilArray);
   Assert(SegArrayValid(a));
   
   with a^ do
   begin
      db := TDynamicBuffer(Segments^.Items[FirstSegIndex]);
      for j := InnerStartIndex to Min(InnerStartIndex + a^.Size,
                                      saSegmentCapacity) - 1 do
      begin
         db^.Items[j] := proc.Perform(db^.Items[j]);
      end;
      
      for i := FirstSegIndex + 1 to LastSegIndex - 1 do
      begin
         db := TDynamicBuffer(Segments^.Items[i]);
         for j := 0 to saSegmentCapacity - 1 do
            db^.Items[j] := proc.Perform(db^.Items[j]);
      end;
      
      if FirstSegIndex <> LastSegIndex then
      begin
         db := TDynamicBuffer(Segments^.Items[lastSegIndex]);
         for j := 0 to ItemsInLastSeg - 1 do
            db^.Items[j] := proc.Perform(db^.Items[j]);
      end;
   end;
end;

