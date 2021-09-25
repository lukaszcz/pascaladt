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
 adtiters_impl.inc::prefix=&_mcp_prefix&::ItemType=&ItemType&
 }

&include adtiters.defs
&include adtiters_impl.mcp

{ ------------------------------ &TIterator& --------------------------------- }

constructor TIterator.Create(ownerObject : TContainerAdt);
begin
{$ifdef DEBUG_PASCAL_ADT }
   Inc(existingIters);
{$endif DEBUG_PASCAL_ADT }
   handle := OwnerObject.GrabageCollector.RegisterObject(self);
end;

destructor TIterator.Destroy;
begin
{$ifdef DEBUG_PASCAL_ADT }
   Dec(existingIters);
{$endif DEBUG_PASCAL_ADT }
   Owner.GrabageCollector.UnregisterObject(handle);
end;

procedure TIterator.DoExchangeItem(iter : TIterator);
var
   aitem : ItemType;
   own : TContainerAdt;
   owns : Boolean;
begin
   aitem := iter.Item;
   own := iter.Owner;
   owns := own.OwnsItems;
   own.OwnsItems := false;
   iter.SetItem(Item);
   own.OwnsItems := owns;
   SetItem(aitem);
end;

{ ------------------------- TForwardIterator ------------------------------ }

procedure TForwardIterator.Write(aitem : ItemType);
begin
   if IsFinish then
      Insert(aitem)
   else
      SetItem(aitem);
   Advance;
end;

procedure TForwardIterator.Delete;
{$ifdef INLINE_DIRECTIVE_REPEAT }
inline;
{$endif }
var
   aitem : ItemType;
begin
   aitem := Extract;
   with Owner do
      DisposeItem(aitem);
end;

function TForwardIterator.Delete(finish : TForwardIterator) : SizeType;
var
   dist : IndexType;
   cont : TContainerAdt;
   aitem : ItemType;
begin
   Assert(finish.Owner = Owner, msgWrongOwner);
   
   cont := Owner;
   Result := 0;
   if finish.IsFinish then
   begin
      while not IsFinish do
      begin
         with cont do
         begin
            aitem := Extract;
            DisposeItem(aitem);
         end;
         Inc(Result);
      end;
   end else
   begin
      dist := Distance(self, finish);
      while (Result <> dist) do
      begin
         with cont do
         begin
            aitem := Extract;
            DisposeItem(aitem);
         end;
         Inc(Result);
      end;
   end;
end;

{ ------------------------- TRandomAccessIterator --------------------------- }
{ @ignore-declarations 1 }
{$ifdef OVERLOAD_DIRECTIVE }
procedure TRandomAccessIterator.Advance;
{$else }
procedure TRandomAccessIterator.AdvanceOnePosition;
{$endif OVERLOAD_DIRECTIVE }
begin
   Advance(1);
end;

procedure TRandomAccessIterator.Retreat;
begin
   Advance(-1);
end;

function TRandomAccessIterator.Delete(finish : TForwardIterator) : SizeType;
begin
   Assert(finish is TRandomAccessIterator, msgInvalidIterator);
   Result := Delete(TRandomAccessIterator(finish).Index - Index);
end;

{ ------------------------ TTreeTraversalIterator ----------------------------- }

function TTreeTraversalIterator.Equal(const Pos : TIterator) : Boolean;
var
   titer1, titer2 : TBasicTreeIterator;
begin
   titer1 := TreeIterator;
   if pos is TTreeTraversalIterator then
   begin
      titer2 := TTreeTraversalIterator(pos).TreeIterator;
      Result := titer1.Equal(titer2);
      titer2.Destroy;
   end else
      Result := titer1.Equal(pos);
   titer1.Destroy;
end;

function TTreeTraversalIterator.GetItem : ItemType;
var
   titer : TBasicTreeIterator;
begin
   titer := TreeIterator;
   Result := titer.Item;
   titer.Destroy;
end;

procedure TTreeTraversalIterator.SetItem(aitem : ItemType);
var
   titer : TBasicTreeIterator;
begin
   titer := TreeIterator;
   titer.SetItem(aitem);
   titer.Destroy;
end;

procedure TTreeTraversalIterator.ExchangeItem(iter : TIterator);
var
   titer1, titer2 : TBasicTreeIterator;
begin
   titer1 := TreeIterator;
   if iter is TTreeTraversalIterator then
   begin
      titer2 := TTreeTraversalIterator(iter).TreeIterator;
      titer1.ExchangeItem(titer2);
      titer2.Destroy;
   end else
      titer1.ExchangeItem(iter);
   titer1.Destroy;
end;

function TTreeTraversalIterator.Owner : TContainerAdt;
var
   titer : TBasicTreeIterator;
begin
   titer := TreeIterator;
   Result := titer.Owner;
   titer.Destroy;
end;

function TTreeTraversalIterator.IsFinish : Boolean;
var
   titer : TBasicTreeIterator;
begin
   titer := TreeIterator;
   Result := TBasicTreeAdt(Owner).Finish.Equal(titer);
   titer.Destroy;
end;
(*
{ --------------------------- TStringIterator  ------------------------------- }

function TStringIterator.GetItem : ItemType;
begin
   Result := ItemType(Integer(GetChar));
end;

procedure TStringIterator.SetItem(aitem : ItemType);
begin
   {$warnings off }
   SetChar(CharType(aitem));
   {$warnings on }
end;
*)
{ ----------------------------- TSetIterator --------------------------------- }

procedure TDefinedOrderIterator.ExchangeItem(iter : TIterator);
begin
   raise EDefinedOrder.Create('TSetIterator.ExchangeItem');
end;

{ --------------------------- TReverseIterator ------------------------------- }

constructor TReverseIterator.Create(const iter : TBidirectionalIterator);
begin
   inherited Create(iter.Owner);
   FIter := CopyOf(iter);
end;

function TReverseIterator.CopySelf : TIterator;
begin
   Result := TReverseIterator.Create(FIter);
end;

function TReverseIterator.Equal(const Pos : TIterator) : Boolean;
var
   iter : TBidirectionalIterator;
begin
   if pos is TReverseIterator then
   begin
      Result := FIter.Equal(TReverseIterator(pos).FIter);
   end else
   begin
      iter := CopyOf(FIter);
      iter.Retreat;
      Result := iter.Equal(pos);
   end;
end;

function TReverseIterator.GetItem : ItemType;
var
   iter : TBidirectionalIterator;
begin
   iter := CopyOf(FIter);
   iter.Retreat;
   Result := iter.Item;
end;

procedure TReverseIterator.SetItem(aitem : ItemType);
var
   iter : TBidirectionalIterator;
begin
   iter := CopyOf(FIter);
   iter.Retreat;
   iter.SetItem(aitem); 
end;

{ @ignore-declarations 1 }
{$ifdef OVERLOAD_DIRECTIVE }
procedure TReverseIterator.Advance;
{$else }
procedure TReverseIterator.AdvanceOnePosition;
{$endif OVERLOAD_DIRECTIVE }
begin
   FIter.Retreat;
end;

procedure TReverseIterator.Retreat; 
begin
   FIter.Advance;
end;

procedure TReverseIterator.ExchangeItem(iter : TIterator);
var
   iter2, iter3 : TBidirectionalIterator;
begin
   iter2 := CopyOf(FIter);
   iter2.Retreat;
   if iter is TReverseIterator then
   begin
      iter3 := CopyOf(TReverseIterator(iter).FIter);
      iter3.Retreat;
      iter2.ExchangeItem(iter3);
   end else
   begin
      iter2.ExchangeItem(iter);
   end;
end;

procedure TReverseIterator.Insert(aitem : ItemType);
begin
   FIter.Insert(aitem);
   FIter.Retreat;
end;

function TReverseIterator.Extract : ItemType;
begin
   FIter.Retreat;
   Result := FIter.Extract;
end;

function TReverseIterator.Delete(finish : TForwardIterator) : SizeType;
var
   iter : TBidirectionalIterator;
begin
   Assert(finish is TReverseIterator, msgInvalidIterator);
   
   iter := TReverseIterator(finish).FIter;
   Result := iter.Delete(FIter);
   FIter := iter;
end;

function TReverseIterator.Owner : TContainerAdt;
begin
   Result := FIter.Owner;
end;

function TReverseIterator.GetIterator : TBidirectionalIterator;
begin
   Result := CopyOf(FIter);
end;

function TReverseIterator.IsStart : Boolean;
begin
   Result := FIter.IsFinish;
end;

function TReverseIterator.IsFinish : Boolean;
begin
   Result := FIter.IsStart;
end;

{ -------------------- TForwardIteratorRange ---------------------------- }

constructor TForwardIteratorRange.Create(starti, finishi : TForwardIterator);
begin
   inherited Create;
   FStart := starti;
   FFinish := finishi;
   owner := FStart.Owner;
   handle := owner.GrabageCollector.RegisterObject(self);
end;

destructor TForwardIteratorRange.Destroy;
begin
   owner.GrabageCollector.UnregisterObject(handle);
   inherited;
end;

{ -------------------- TSetIteratorRange ---------------------------- }

constructor TSetIteratorRange.Create(starti, finishi : TSetIterator);
begin
   inherited Create;
   FStart := starti;
   FFinish := finishi;
   owner := FStart.Owner;
   handle := owner.GrabageCollector.RegisterObject(self);
end;

destructor TSetIteratorRange.Destroy;
begin
   owner.GrabageCollector.UnregisterObject(handle);
   inherited;
end;

{ --------------------------- general functions ------------------------------- }

function Less(const pos1, pos2 : TRandomAccessIterator) : Boolean;
begin
   Assert(pos1.Owner = pos2.Owner, msgWrongOwner);
   Result := pos1.Less(pos2);
end;

function Less(const pos1, pos2 : TForwardIterator) : Boolean;
var
   iter : TForwardIterator;
begin
   Assert(pos1.Owner = pos2.Owner, msgWrongOwner);
   
   if pos1.Equal(pos2) then
      Result := false
   else if pos1.IsStart or pos2.IsFinish then
      Result := true
   else begin
      iter := CopyOf(pos1);
      while not (iter.IsFinish or iter.Equal(pos2)) do
         iter.Advance;
      if iter.Equal(pos2) then
         Result := true
      else
         Result := false;
   end;
end;

function Advance(iter : TForwardIterator; step : IndexType) : TForwardIterator;
begin
   Result := iter;
   if iter is TRandomAccessIterator then
   begin
      TRandomAccessIterator(iter).Advance(step);
   end else
   begin
      while step <> 0 do
      begin
         iter.Advance;
         Dec(step);
      end;
   end;
end;

{$ifdef OVERLOAD_DIRECTIVE }
function Advance(iter : TRandomAccessIterator;
                 step : IndexType) : TRandomAccessIterator;
begin
   iter.Advance(step);
   Result := iter;
end;
{$endif OVERLOAD_DIRECTIVE }

function Retreat(iter : TBidirectionalIterator;
                 step : IndexType) : TBidirectionalIterator;
begin
   Result := iter;
   if iter is TRandomAccessIterator then
   begin
      TRandomAccessIterator(iter).Advance(-step);
   end else
   begin
      while step <> 0 do
      begin
         iter.Retreat;
         Dec(step);
      end;
   end;
end;

{$ifdef OVERLOAD_DIRECTIVE }
function Retreat(iter : TRandomAccessIterator;
                 step : IndexType) : TRandomAccessIterator;
begin
   iter.Advance(-step);
   Result := iter;
end;


function CopyOf(const iter : TIterator) : TIterator;
begin
   Result := TIterator(iter.CopySelf);
end;

function CopyOf(const iter : TForwardIterator) : TForwardIterator;
begin
   Result := TForwardIterator(iter.CopySelf);
end;

function CopyOf(const iter : TBidirectionalIterator) : TBidirectionalIterator;
begin
   Result := TBidirectionalIterator(iter.CopySelf);
end;

function CopyOf(const iter : TRandomAccessIterator) : TRandomAccessIterator;
begin
   Result := TRandomAccessIterator(iter.CopySelf);
end;

function CopyOf(const iter : TBasicTreeIterator) : TBasicTreeIterator;
begin
   Result := TBasicTreeIterator(iter.CopySelf);
end;

function CopyOf(const iter : TTreeTraversalIterator) : TTreeTraversalIterator;
begin
   Result := TTreeTraversalIterator(iter.CopySelf);
end;

function CopyOf(const iter : TPreOrderIterator) : TPreOrderIterator;
begin
   Result := TPreOrderIterator(iter.CopySelf);
end;

function CopyOf(const iter : TPostOrderIterator) : TPostOrderIterator;
begin
   Result := TPostOrderIterator(iter.CopySelf);
end;

function CopyOf(const iter : TInOrderIterator) : TInOrderIterator;
begin
   Result := TInOrderIterator(iter.CopySelf);
end;

function CopyOf(const iter : TLevelOrderIterator) : TLevelOrderIterator;
begin
   Result := TLevelOrderIterator(iter.CopySelf);
end;

function CopyOf(const iter : TDefinedOrderIterator) : TDefinedOrderIterator;
begin
   Result := TDefinedOrderIterator(iter.CopySelf);
end;

function CopyOf(const iter : TSetIterator) : TSetIterator;
begin
   Result := TSetIterator(iter.CopySelf);
end;

function CopyOf(const iter : TReverseIterator) : TReverseIterator;
begin
   Result := TReverseIterator(iter.CopySelf);
end;


function Next(const iter : TForwardIterator) : TForwardIterator;
begin
   Result := TForwardIterator(iter.CopySelf);
   Result.Advance;
end;

function Next(const iter : TBidirectionalIterator)
   : TBidirectionalIterator;
begin
   Result := TBidirectionalIterator(iter.CopySelf);
   Result.Advance;
end;

function Next(const iter : TRandomAccessIterator)
   : TRandomAccessIterator;
begin
   Result := TRandomAccessIterator(iter.CopySelf);
   Result.Advance;
end;

function Next(const iter : TRandomAccessIterator; i : IndexType)
   : TRandomAccessIterator;
begin
   Result := TRandomAccessIterator(iter.CopySelf);
   Result.Advance(i);
end;

function Prev(const iter : TBidirectionalIterator)
   : TBidirectionalIterator;
begin
   Result := TBidirectionalIterator(iter.CopySelf);
   Result.Retreat;
end;

function Prev(const iter : TRandomAccessIterator)
   : TRandomAccessIterator;
begin
   Result := TRandomAccessIterator(iter.CopySelf);
   Result.Retreat;
end;
{$endif OVERLOAD_DIRECTIVE }

function Distance(const iter1, iter2 : TForwardIterator) : IndexType;
var
   temp : TForwardIterator;
begin
   if (iter1 is TRandomAccessIterator)
      and (iter2 is TRandomAccessIterator) then
   begin
      Result := Distance(TRandomAccessIterator(iter1),
                         TRandomAccessIterator(iter2));
   end else
   begin
      Assert(Less(iter1, iter2));
      
      Result := 0;
      temp := TForwardIterator(iter1.CopySelf);
      while not temp.Equal(iter2) do
      begin
         temp.Advance;
         Inc(Result);
      end;
   end;
end;

{$ifdef OVERLOAD_DIRECTIVE }
function Distance(const iter1, iter2 : TRandomAccessIterator) : IndexType;
begin
   Result := iter1.Distance(iter2);
end;
{$endif OVERLOAD_DIRECTIVE }

function PreOrder(const node : TPreOrderIterator) : TPreOrderIterator;
begin
   Result := TPreOrderIterator(node.CopySelf);
   Result.Advance;
end;

function PostOrder(const node : TPostOrderIterator) : TPostOrderIterator;
begin
   Result := TPostOrderIterator(node.CopySelf);
   Result.Advance;
end;

function InOrder(const node : TInOrderIterator) : TInOrderIterator;
begin
   Result := TInOrderIterator(node.CopySelf);
   Result.Advance;
end;

function LevelOrder(const node : TLevelOrderIterator) : TLevelOrderIterator;
begin
   Result := TLevelOrderIterator(node.CopySelf);
   Result.Advance;
end;

{ ---------------------------- debugging routines -------------------------- }

procedure CheckIteratorRange(start, finish : TForwardIterator);
{$ifdef TEST_PASCAL_ADT }
var
   iter : TForwardIterator;
{$endif }
begin
   Assert(start.Owner = finish.Owner, msgWrongRangeOwner);
   if start is TRandomAccessIterator then
   begin
      Assert(finish is TRandomAccessIterator, msgInvalidRange);
      Assert(TRandomAccessIterator(start).Less(TRandomAccessIterator(finish)) or
                start.Equal(finish));
   end else
   begin
{$ifdef TEST_PASCAL_ADT }   
      iter := CopyOf(start);
      while not iter.Equal(finish) do
      begin
         iter.Advance;
      end;
      Assert(iter.Equal(finish), msgInvalidRange);
{$endif }
   end;
end;

