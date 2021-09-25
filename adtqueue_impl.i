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
 adtqueue_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtqueue.defs
&include adtqueue_impl.mcp


{ **************************************************************************** }
{                               Circular deque                                 }
{ **************************************************************************** }
   


{ ---------------------------- TCircularDeque members --------------------------- }

constructor TCircularDeque.Create;
begin
   inherited;
   ArrayAllocate(FItems, CircularDequeInitialCapacity, 1);
end;

constructor TCircularDeque.CreateCopy(const cont : TCircularDeque;
                                      const itemCopier : IUnaryFunctor);
var
   i : IndexType;
begin
   inherited CreateCopy(cont);
   if itemCopier <> nil then
   begin
      ArrayCopy(cont.FItems, FItems);
      try
         ArrayCircularApplyFunctor(FItems, ItemCopier);
      except
         i := 0;
         while GetItem(i) <> cont.GetItem(i) do
         begin
            DisposeItem(GetItem(i));
            Inc(i);
         end;
         ArrayDeallocate(FItems);
         raise;
      end;
   end else
      ArrayAllocate(FItems, CircularDequeInitialCapacity, 1);
end;

destructor TCircularDeque.Destroy;
begin
   if FItems <> nil then
      Clear;
   ArrayDeallocate(FItems);
   inherited;
end;

function TCircularDeque.GetCapacity : SizeType;
begin
   Result := FItems^.Capacity;
end;

procedure TCircularDeque.SetCapacity(cap : SizeType);
begin
   if cap > Capacity then
      ArrayCircularExpand(FItems, cap);
end;

function TCircularDeque.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TCircularDeque.CreateCopy(self, itemCopier);
end;

procedure TCircularDeque.Swap(cont : TContainerAdt);
begin
   if cont is TCircularDeque then
   begin
      BasicSwap(cont);
      ExchangePtr(FItems, TCircularDeque(cont).FItems);
   end else
      inherited;
end;

function TCircularDeque.RandomAccessStart : TRandomAccessIterator;
begin
   Result := Start;
end;

function TCircularDeque.RandomAccessFinish : TRandomAccessIterator;
begin
   Result := Finish;
end;

function TCircularDeque.Start : TCircularDequeIterator;
begin
   Result := TCircularDequeIterator.Create(0, self);
end;

function TCircularDeque.Finish : TCircularDequeIterator;
begin
   Result := TCircularDequeIterator.Create(FItems^.Size, self);
end;

function TCircularDeque.GetItem(index : IndexType) : ItemType;
begin
   Result := ArrayCircularGetItem(FItems, index);
end;

procedure TCircularDeque.SetItem(index : IndexType; aitem : ItemType);
begin
   aitem := ArrayCircularSetItem(FItems, index, aitem);
   DisposeItem(aitem);
end;

procedure TCircularDeque.Insert(index : IndexType; aitem : ItemType);
begin
   ArrayCircularReserveItems(FItems, index, 1);
   ArrayCircularSetItem(FItems, index, aitem);
end;

procedure TCircularDeque.Delete(index : IndexType);
begin
   // OK below, need not be called when OwnsItems is false
   DisposeItem(ArrayCircularGetItem(FItems, index));
   ArrayCircularRemoveItems(FItems, index, 1);
end;

function TCircularDeque.Delete(starti : IndexType; n : SizeType) : SizeType;
var
   i, mini : IndexType;
begin
   mini := Min(starti + n - 1, FItems^.Size - 1);
   &if (&_mcp_type_needs_destruction(&ItemType))
   if OwnsItems then
   begin
      for i := starti to mini do
         DisposeItem(ArrayCircularGetItem(FItems, i));
   end;
   &endif
   ArrayCircularRemoveItems(FItems, starti, mini + 1 - starti);
   Result := mini + 1 - starti;
end;

function TCircularDeque.Extract(index : IndexType) : ItemType;
begin
   Result := ArrayCircularGetItem(FItems, index);
   ArrayCircularRemoveItems(FItems, index, 1);
end;

function TCircularDeque.Front : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   
   with FItems^ do
      Result := Items[StartIndex];
end;

function TCircularDeque.Back : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   
   with FItems^ do
   begin
      if StartIndex + Size > Capacity then
         Result := Items[StartIndex + Size - 1 - Capacity]
      else
         Result := Items[StartIndex + Size - 1];
   end;
end;

procedure TCircularDeque.PushFront(aitem : ItemType);
begin
   ArrayCircularPushFront(FItems, aitem);
end;

procedure TCircularDeque.PopFront;
var // note: using temp is necessary since _DisposeItem_ is in fact only a macro
   temp : ItemType;
begin
   temp := ArrayCircularPopFront(FItems);
   DisposeItem(temp);
end;

procedure TCircularDeque.PushBack(aitem : ItemType);
begin
   ArrayCircularPushBack(FItems, aitem);
end;

procedure TCircularDeque.PopBack;
var
   temp : ItemType;
begin
   temp := ArrayCircularPopBack(FItems);
   DisposeItem(temp);
end;

procedure TCircularDeque.Clear;
begin
   &if (&_mcp_type_needs_destruction(&ItemType))   
   if OwnsItems then
   begin
      ArrayCircularApplyFunctor(FItems,
         AdaptObject(_mcp_address_of_DisposeItem));
   end;
   &endif
   ArrayClear(FItems, CircularDequeInitialCapacity, 1);

   GrabageCollector.FreeObjects;
end;

function TCircularDeque.Empty : Boolean;
begin
   Result := (FItems^.Size = 0);
end;

function TCircularDeque.Size : SizeType;
begin
   Result := FItems^.Size;
end;

function TCircularDeque.IsDefinedOrder : Boolean;
begin
   Result := false;
end;


{ --------------------- TCircularDequeIterator members ----------------------- }


function TCircularDequeIterator.CopySelf : TIterator;
begin
   Result := TCircularDequeIterator.Create(FIndex, FCont);
end;

procedure TCircularDequeIterator.ExchangeItemsAt(i, j : IndexType);
var
   ind1, ind2 : IndexType;
   items1 : TDynamicArray;
   aitem : ItemType;
begin
   items1 := TCircularDeque(FCont).FItems;
   
   with items1^ do
   begin
      ind1 := StartIndex + Findex + i;
      if ind1 >= Capacity then
         Dec(ind1, Capacity);
      
      ind2 := StartIndex + FIndex + j;
      if ind2 >= Capacity then
         Dec(ind2, Capacity);

      aitem := Items[ind1];
      Items[ind1] := Items[ind2];
      Items[ind2] := aitem;
   end;
end;


{ **************************************************************************** }
{                               Segmented deque                                }
{ **************************************************************************** }


{ ------------------------------ TDeque members ------------------------------ }

constructor TSegDeque.Create;
begin
   inherited;
   SegArrayAllocate(FItems, SegDequeinitialSegments,
                    SegDequeInitialSegments div 2, saSegmentCapacity div 2);
end;

constructor TSegDeque.CreateCopy(const cont : TSegDeque;
                                 const itemCopier : IUnaryFunctor);
var
   i : IndexType;
begin
   inherited CreateCopy(cont);
   
   if itemCopier <> nil then
   begin
      SegArrayCopy(cont.FItems, FItems);
      try
         SegArrayApplyFunctor(FItems, ItemCopier);
      except
         &if (&_mcp_type_needs_destruction(&ItemType))
         if OwnsItems then
         begin
            i := 0;
            while (i < FItems^.Size) and (GetItem(i) <> cont.GetItem(i)) do
            begin
               DisposeItem(GetItem(i));
               Inc(i);
            end;
            SegArrayDeallocate(FItems);
         end;
         &endif
         raise;
      end;
   end else
   begin
      SegArrayAllocate(FItems, SegDequeinitialSegments,
                       SegDequeInitialSegments div 2,
                       saSegmentCapacity div 2);
   end;
end;

destructor TSegDeque.Destroy;
begin
   if FItems <> nil then
      Clear;
   SegArrayDeallocate(FItems);
   inherited;
end;

function TSegDeque.GetCapacity : SizeType;
begin
   Result := FItems^.Segments^.Size*saSegmentCapacity;
end;

procedure TSegDeque.SetCapacity(cap : SizeType);
var
   totalCap : SizeType;
begin
   totalCap := saSegmentCapacity*FItems^.Segments^.Size -
      FItems^.InnerStartIndex;
   if cap >  totalCap then
      SegArrayExpandRight(FItems, cap - totalCap);
end;

function TSegDeque.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TSegDeque.CreateCopy(self, itemCopier);
end;

procedure TSegDeque.Swap(cont : TContainerAdt);
begin
   if cont is TSegDeque then
   begin
      BasicSwap(cont);
      ExchangePtr(FItems, TSegDeque(cont).FItems);
   end else
      inherited;
end;

function TSegDeque.RandomAccessStart : TRandomAccessIterator;
begin
   Result := Start;
end;

function TSegDeque.RandomAccessFinish : TRandomAccessIterator;
begin
   Result := Finish;
end;

function TSegDeque.Start : TSegDequeIterator;
begin
   Result := TSegDequeIterator.Create(0, self);
end;

function TSegDeque.Finish : TSegDequeIterator;
begin
   Result := TSegDequeIterator.Create(FItems^.Size, self);
end;

function TSegDeque.GetItem(index : IndexType) : ItemType;
begin
   Result := SegArrayGetItem(FItems, index);
end;

procedure TSegDeque.SetItem(index : IndexType; aitem : ItemType);
begin
   aitem := SegArraySetItem(FItems, index, aitem);
   DisposeItem(aitem);
end;

procedure TSegDeque.Insert(index : IndexType; aitem : ItemType);
begin
   Assert(IsValidIndex(index, FItems^.Size) or (index = FItems^.Size),
          msgInvalidIndex);
   
   SegArrayReserveItems(FItems, index, 1);
   SegArraySetItem(FItems, index, aitem);
end;

procedure TSegDeque.Delete(index : IndexType);
begin
   // OK below
   DisposeItem(SegArrayGetItem(FItems, index));
   SegArrayRemoveItems(FItems, index, 1);
end;

function TSegDeque.Delete(starti : IndexType; n : SizeType) : SizeType;
var
   i, mini : IndexType;
begin
   mini := Min(starti + n - 1, FItems^.Size - 1);
   &if (&_mcp_type_needs_destruction(&ItemType))
   if OwnsItems then
   begin
      for i := starti to mini do
         DisposeItem(SegArrayGetItem(FItems, i));
   end;
   &endif
   SegArrayRemoveItems(FItems, starti, mini + 1 - starti);
   Result := mini + 1 - starti;
end;

function TSegDeque.Extract(index : IndexType) : ItemType;
begin
   Result := SegArrayGetItem(FItems, index);
   SegArrayRemoveItems(FItems, index, 1);
end;

function TSegDeque.Front : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   
   with FItems^ do
   begin
      Result :=
         TDynamicBuffer(
            Segments^.Items[FirstSegIndex])^.Items[InnerStartIndex];
   end;
end;

function TSegDeque.Back : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   
   with FItems^ do
   begin
      if FirstSegIndex <> LastSegIndex then
      begin
         Result :=
            TDynamicBuffer(
               Segments^.Items[LastSegIndex]
                          )^.Items[ItemsInLastSeg - 1];
      end else
      begin
         Result :=
            TDynamicBuffer(
               Segments^.Items[LastSegIndex]
                          )^.Items[InnerStartIndex + ItemsInLastSeg - 1];
      end;
   end;
end;

procedure TSegDeque.PushFront(aitem : ItemType);
begin
   SegArrayPushFront(FItems, aitem);
end;

procedure TSegDeque.PopFront;
var
   temp : ItemType;
begin
   temp := SegArrayPopFront(FItems);
   DisposeItem(temp);
end;

procedure TSegDeque.PushBack(aitem : ItemType);
begin
   SegArrayPushBack(FItems, aitem);
end;

procedure TSegDeque.PopBack;
var
   temp : ItemType;
begin
   temp := SegArrayPopBack(FItems);
   DisposeItem(temp);
end;

procedure TSegDeque.Clear;
begin
   &if (&_mcp_type_needs_destruction(&ItemType))
   if OwnsItems then
   begin
      SegArrayApplyFunctor(FItems, AdaptObject(_mcp_address_of_DisposeItem));
   end;
   &endif
   SegArrayClear(FItems, SegDequeInitialSegments);

   GrabageCollector.FreeObjects;
end;

function TSegDeque.Empty : Boolean;
begin
   Result := FItems^.Size = 0;
end;

function TSegDeque.Size : SizeType;
begin
   Result := FItems^.Size;
end;

function TSegDeque.IsDefinedOrder : Boolean;
begin
   Result := false;
end;

{ --------------------- TSegDequeIterator members ----------------------- }

function TSegDequeIterator.CopySelf : TIterator;
begin
   Result := TSegDequeIterator.Create(FIndex, FCont);
end;

procedure TSegDequeIterator.ExchangeItemsAt(i, j : IndexType);
var
   seg1, seg2, off1, off2 : IndexType;
   items1 : TSegArray;
   buff1, buff2 : TDynamicBuffer;
   aitem : ItemType;
begin
   items1 := TSegDeque(FCont).FItems;
         
   SegArrayLogicalToSegOff(items1, FIndex + i, seg1, off1);
   SegArrayLogicalToSegOff(items1, FIndex + j, seg2, off2);
      
   buff1 := TDynamicBuffer(items1^.Segments^.Items[seg1]);
   buff2 := TDynamicBuffer(items1^.Segments^.Items[seg2]);
      
   aitem := buff1^.Items[off1];
   buff1^.Items[off1] := buff2^.Items[off2];
   buff2^.Items[off2] := aitem;
end;

