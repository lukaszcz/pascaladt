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
 array_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtarray.defs
&include adtarray_impl.mcp

{ --------------------------- TArray ----------------------------- }

constructor TArray.Create(afirstIndex : IndexType);
begin
   inherited Create;
   firstIndex := afirstIndex;
   ArrayAllocate(FItems, arrInitialCapacity, 0);
end;

constructor TArray.Create;
begin
   inherited Create;
   ArrayAllocate(FItems, arrInitialCapacity, 0);
end;

constructor TArray.CreateCopy(const cont : TArray;
                              const itemCopier : IUnaryFunctor);
var
   i : IndexType;
begin
   inherited CreateCopy(cont);
   firstIndex := cont.Firstindex;

   if itemCopier <> nil then
   begin
      ArrayAllocate(FItems, cont.FItems^.Size + arrInitialCapacity, 0);
      
      for i := 0 to cont.FItems^.Size - 1 do
      begin
         { may raise (the statement below) }
         FItems^.Items[i] := itemCopier.Perform(cont.FItems^.Items[i]);
         Inc(FItems^.Size); { increasing gradually (not at once after
                              the loop) in case of an exception }
      end;
   end else
      ArrayAllocate(FItems, arrInitialCapacity, 0);
end;

destructor TArray.Destroy;
begin
   if FItems <> nil then
      Clear;
   ArrayDeallocate(FItems);
   inherited;
end;

function TArray.GetCapacity : SizeType;
begin
   Result := FItems^.Capacity;
end;

procedure TArray.SetCapacity(cap : SizeType);
begin
   if cap > FItems^.Size then
      ArrayReallocate(FItems, cap);
end;

function TArray.RandomAccessStart : TRandomAccessIterator;
begin
   Result := Start;
end;

function TArray.RandomAccessFinish : TRandomAccessIterator;
begin
   Result := Finish;
end;

function TArray.Start : TArrayIterator;
begin
   Result := TArrayIterator.Create(firstIndex, self);
end;

function TArray.Finish : TArrayIterator;
begin
   Result := TArrayIterator.Create(firstIndex + FItems^.Size, self);
end;

function TArray.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TArray.CreateCopy(self, itemCopier);
end;

procedure TArray.Swap(cont : TContainerAdt);
begin
   if cont is TArray then
   begin
      BasicSwap(cont);
      ExchangePtr(FItems, TArray(cont).FItems);
      ExchangeData(firstIndex, TArray(cont).firstIndex, SizeOf(IndexType));
   end else
      inherited;
end;

function TArray.GetItem(index : IndexType) : ItemType;
begin
   Result := FItems^.Items[index - firstIndex];
end;

procedure TArray.SetItem(index : IndexType; elem : ItemType);
begin
   DisposeItem(FItems^.Items[index - firstIndex]);
   FItems^.Items[index - firstIndex] := elem;
end;

procedure TArray.Insert(index : IndexType; aitem : ItemType);
begin
   Assert((index >= LowIndex) and (index <= HighIndex + 1), msgInvalidIndex);
   ArrayReserveItems(FItems, index - firstIndex, 1);
   FItems^.Items[index - firstIndex] := aitem;
end;

procedure TArray.Delete(index : IndexType);
var
   aitem : ItemType;
begin
   Dec(index, firstIndex);
   aitem := FItems^.Items[index];
   ArrayRemoveItems(FItems, index, 1); { may raise }
   DisposeItem(aitem);
end;

function TArray.Delete(astart : IndexType; n : SizeType) : SizeType;
var
   fin, i : IndexType;
begin
   fin := astart - firstIndex + n;
   if fin > FItems^.Size then
      fin := FItems^.Size;
   
   &if (&_mcp_type_needs_destruction(&ItemType))
   if OwnsItems then
   begin
      for i := astart - firstIndex to fin - 1 do
      begin
         DisposeItem(FItems^.Items[i]);
      end;
   end;
   &endif
   
   Result := fin - astart + firstIndex;
   ArrayRemoveItems(FItems, astart - firstIndex, Result);
end;

function TArray.Extract(index : IndexType) : ItemType;
begin
   Dec(index, firstIndex);
   Result := FItems^.Items[index];
   ArrayRemoveItems(FItems, index, 1); { may raise }
end;

procedure TArray.PushBack(aitem : ItemType);
begin
  ArrayPushBack(FItems, aitem); 
end;

procedure TArray.PushFront(aitem : ItemType);
begin
   ArrayPushFront(FItems, aitem, false);
end;

procedure TArray.PopBack;
var
   aitem : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   aitem := ArrayPopBack(FItems);
   DisposeItem(aitem);
end;

procedure TArray.PopFront;
var
   aitem : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   aitem := ArrayPopFront(FItems, true);
   DisposeItem(aitem);
end;

function TArray.Back : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   Result := FItems^.Items[FItems^.Size - 1];
end;

function TArray.Front : ItemType;
begin
   Assert(FItems^.Size <> 0, msgReadEmpty);
   Result := FItems^.Items[0];
end;

procedure TArray.Clear;
begin
   &if (&_mcp_type_needs_destruction(&ItemType))
   if OwnsItems then
   begin
      ArrayApplyFunctor(FItems,
                        AdaptObject(_mcp_address_of_DisposeItem));
   end;
   &endif
   ArrayClear(FItems, arrInitialCapacity, 0);
   GrabageCollector.FreeObjects;
end;

function TArray.Empty : Boolean;
begin
   Result := FItems^.Size = 0;
end;

function TArray.Size : SizeType;
begin
   Result := FItems^.Size;
end;

function TArray.LowIndex : IndexType;
begin
   Result := firstIndex;
end;

function TArray.HighIndex : IndexType;
begin
   Result := firstIndex + FItems^.Size - 1;
end;

function TArray.SetLowIndex(ind : IndexType) : IndexType;
begin
   Result := firstIndex;
   firstIndex := ind;
end;

{ -------------------------- TArrayIterator ----------------------------- }

function TArrayIterator.CopySelf : TIterator;
begin
   Result := TArrayIterator.Create(FIndex, FCont);
end;

procedure TArrayIterator.ExchangeItemsAt(i, j : IndexType);
var
   i1, i2 : IndexType;
begin
   with TArray(FCont) do
   begin
      i1 := FIndex - TArray(FCont).firstIndex + i;
      i2 := FIndex - TArray(FCont).firstIndex + j;
      Assert((i1 >= 0) and (i1 < FItems^.Size), msgInvalidIndex);
      Assert((i2 >= 0) and (i2 < FItems^.Size), msgInvalidIndex);
      adtutils.ExchangeItem(FItems^.Items[i1], FItems^.Items[i2]);
   end;
end;



{ ====================================================================== }

{ --------------------- TPascalArray --------------------------- }

constructor TPascalArray.Create(pascalArray : TPascalArrayType); 
begin
   inherited Create;
   FPascalArray := pascalArray;
end;

constructor TPascalArray.CreateCopy(const cont : TPascalArray;
                                    const itemCopier : IUnaryFunctor);
var
   i : IndexType;
begin
   inherited CreateCopy(cont);
   if itemCopier <> nil then
   begin
      SetLength(FPascalArray, Length(cont.FPascalArray));
      try
         for i := 0 to Length(FPascalArray) - 1 do
            FPascalArray[i] := itemCopier.Perform(cont.FPascalArray[i]);
         i := Length(FPascalArray);
         { may raise above }
      except
         SetLength(FPascalArray, i);
         raise;
      end;      
      
   end else
      SetLength(FPascalArray, 0);      
end;

destructor TPascalArray.Destroy; 
begin
   Clear;
   inherited;
end;

function TPascalArray.GetCapacity : SizeType;
begin
   Result := Length(FPascalArray);
end;

procedure TPascalArray.SetCapacity(cap : SizeType); 
begin
   { ignore }
end;

function TPascalArray.RandomAccessStart : TRandomAccessIterator; 
begin
   Result := Start;
end;

function TPascalArray.RandomAccessFinish : TRandomAccessIterator; 
begin
   Result := Finish;
end;

function TPascalArray.Start : TPascalArrayIterator;
begin
   Result := TPascalArrayIterator.Create(0, self);
end;

function TPascalArray.Finish : TPascalArrayIterator;
begin
   Result := TPascalArrayIterator.Create(Length(FPascalArray), self);
end;

function TPascalArray.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt; 
begin
   Result := TPascalArray.CreateCopy(self, itemcopier);
end;

procedure TPascalArray.Swap(cont : TContainerAdt); 
begin
   if cont is TPascalArray then
   begin
      BasicSwap(cont);
      ExchangePtr(FPascalArray, TPascalArray(cont).FPascalArray);
   end else
      inherited;
end;

function TPascalArray.GetItem(index : IndexType) : ItemType; 
begin
   Assert((index >= 0) and (index < Length(FPascalArray)), msgInvalidIndex);
   Result := FPascalArray[index];
end;

procedure TPascalArray.SetItem(index : IndexType; elem : ItemType); 
begin
   Assert((index >= 0) and (index < Length(FPascalArray)), msgInvalidIndex);
   DisposeItem(FPascalArray[index]);
   FPascalArray[index] := elem;
end;

procedure TPascalArray.Insert(index : IndexType; aitem : ItemType);  
begin
   Assert((index >= 0) and (index <= Length(FPascalArray)), msgInvalidIndex);
   SetLength(FPascalArray, Length(FPascalArray) + 1);
   SafeMove(FPascalArray[index], FPascalArray[index + 1],
            (Length(FPascalArray) - 1 - index));
   FPascalArray[index] := aitem;
end;

procedure TPascalArray.Delete(index : IndexType);
var
   aitem : ItemType;
begin
   Assert((index >= 0) and (index < Length(FPascalArray)), msgInvalidIndex);
   aitem := Extract(index);
   DisposeItem(aitem);
end;

function TPascalArray.Delete(astart : IndexType; n : SizeType) : SizeType;
var
   i : IndexType;
begin
   Assert((astart >= 0) and (astart < Length(FPascalArray)), msgInvalidIndex);
   if astart + n > Length(FPascalArray) then
      n := Length(FPascalArray) - astart;
   &if (&_mcp_type_needs_destruction(&ItemType))   
   if OwnsItems then
   begin
      for i := astart to astart + n - 1 do
         DisposeItem(FPascalArray[i]);
   end;
   &endif
   if astart + n <> Length(FPascalArray) then
   begin
      SafeMove(FPascalArray[astart + n], FPascalArray[astart],
               (Length(FPascalArray) - astart - n));
   end;
   SetLength(FPascalArray, Length(FPascalArray) - n);
   Result := n;
end;

function TPascalArray.Extract(index : IndexType) : ItemType;   
begin
   Assert((index >= 0) and (index < Length(FPascalArray)), msgInvalidIndex);
   Result := FPascalArray[index];
   SafeMove(FPascalArray[index + 1], FPascalArray[index],
            (Length(FPascalArray) - index - 1));
   SetLength(FPascalArray, Length(FPascalArray) - 1);
end;

procedure TPascalArray.PushBack(aitem : ItemType); 
begin
   SetLength(FPascalArray, Length(FPascalArray) + 1);
   FPascalArray[Length(FPascalArray) - 1] := aitem;
end;

procedure TPascalArray.PushFront(aitem : ItemType); 
begin
   SetLength(FPascalArray, Length(FPascalArray) + 1);
   SafeMove(FPascalArray[0], FPascalArray[1],
            (Length(FPascalArray) - 1));
   FPascalArray[0] := aitem;
end;

procedure TPascalArray.PopBack; 
begin
   Assert(Length(FPascalArray) <> 0, msgReadEmpty);
   DisposeItem(FPascalArray[Length(FPascalArray) - 1]);
   SetLength(FPascalArray, Length(FPascalArray) - 1);
end;

procedure TPascalArray.PopFront; 
begin
   Assert(Length(FPascalArray) <> 0, msgReadEmpty);
   DisposeItem(FPascalArray[0]);
   SafeMove(FPascalArray[1], FPascalArray[0],
            (Length(FPascalArray) - 1));
   SetLength(FPascalArray, Length(FPascalArray) - 1);
end;

function TPascalArray.Back : ItemType; 
begin
   Assert(Length(FPascalArray) <> 0, msgReadEmpty);
   Result := FPascalArray[Length(FPascalArray) - 1];
end;

function TPascalArray.Front : ItemType; 
begin
   Assert(Length(FPascalArray) <> 0, msgReadEmpty);
   Result := FPascalArray[0];
end;

procedure TPascalArray.Clear;
var
   i : IndexType;
begin
   &if (&_mcp_type_needs_destruction(&ItemType))
   if OwnsItems then
   begin
      for i := 0 to Length(FPascalArray) - 1 do
         DisposeItem(FPascalArray[i]);
      SetLength(FPascalArray, 0);
   end;
   &endif
   GrabageCollector.FreeObjects;
end;

function TPascalArray.Empty : Boolean; 
begin
   Result := Length(FPascalArray) = 0;
end;

function TPascalArray.Size : SizeType; 
begin
   Result := Length(FPascalArray);
end;

{ -------------------------- TPascalArrayIterator --------------------------- }

function TPascalArrayIterator.CopySelf : TIterator;
begin
   Result := TPascalArrayIterator.Create(FIndex, FCont);
end;

procedure TPascalArrayIterator.ExchangeItemsAt(i, j : IndexType);
begin
   Assert((i >= 0) and (i < Length(TPascalArray(FCont).FPascalArray)),
          msgInvalidIndex);
   Assert((j >= 0) and (j < Length(TPascalArray(FCont).FPascalArray)),
          msgInvalidIndex);
   adtutils.ExchangeItem(TPascalArray(FCont).FPascalArray[i],
                         TPascalArray(FCont).FPascalArray[j]);
end;

