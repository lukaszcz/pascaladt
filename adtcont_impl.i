{@discard
 
 This file is a part of the PascalAdt library, which provides commonly
 used algorithms and data structures for the FPC and Delphi compilers.
 
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
 adtcont_impl.inc::prefix=&_mcp_prefix&::item_type=&ItemType&
}

&include adtcont.defs
&include adtcont_impl.mcp

type
   TSortedSetPriorityQueueInterface = class (TPriorityQueueAdt)
   private
      FSet : TSortedSetAdt;
      owns : Boolean;
   public
      { aowns indicates whether aset is owned by the object or not }
      constructor Create(aset : TSortedSetAdt; aowns : Boolean);
      destructor Destroy; override;
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      procedure Insert(aitem : ItemType); override;
      function First : ItemType; override;
      function ExtractFirst : ItemType; override;
      procedure Merge(aqueue : TPriorityQueueAdt); override;
      { clears the container - removes all items; @complexity O(n). }
      procedure Clear; override;
      { returns true if container is empty; equivalent to Size = 0,
        but may be faster; @complexity guaranteed worst-case O(1). }
      function Empty : Boolean; override;
      { returns the number of items; @complexity guaranteed average,
        amortized or worst-case O(1) and never more than worst-case
        O(n). }
      function Size : SizeType; override;
   end;
   
   
{ ----------------------- TDefinedOrderContainerAdt --------------------------- }

function TDefinedOrderContainerAdt.IsDefinedOrder : Boolean;
begin
   Result := true;
end;

{ -------------------------- TPriorityQueueAdt -------------------------------- }

constructor TPriorityQueueAdt.Create;
begin
   inherited Create;
   FComparer := &_mcp_comparer(&ItemType);
end;

constructor TPriorityQueueAdt.CreateCopy(const cont : TPriorityQueueAdt);
begin
   inherited CreateCopy(TContainerAdt(cont));
   Fcomparer := cont.ItemComparer;
end;
      
procedure TPriorityQueueAdt.DeleteFirst;
var
   aitem : ItemType;
begin
   aitem := ExtractFirst;
   DisposeItem(aitem);
end;
      
function TPriorityQueueAdt.InsertItem(aitem : ItemType) : Boolean;
begin
   Insert(aitem);
   Result := true;
end;

function TPriorityQueueAdt.ExtractItem : ItemType;
begin
   Assert(CanExtract);
   Result := ExtractFirst;
end;

function TPriorityQueueAdt.CanExtract : Boolean;
begin
   Result := not Empty;
end;

function TPriorityQueueAdt.IsDefinedOrder : Boolean;
begin
   Result := true;
end;

{ -------------------------- TBasicTreeAdt -------------------------------- }

function TBasicTreeAdt.InsertItem(aitem : ItemType) : Boolean;
begin
   InsertAsRoot(aitem);
   Result := true;
end;

function TBasicTreeAdt.ExtractItem : ItemType;
var
   iter : TPostOrderIterator;
begin
   Assert(CanExtract);
   iter := PostOrderIterator;
   Result := iter.Item;
   DeleteSubTree(iter.TreeIterator);
   iter.Destroy;
end;

function TBasicTreeAdt.CanExtract : Boolean;
begin
   Result := not Empty;
end;

{ -------------------------- TQueueAdt -------------------------------- }

function TQueueAdt.InsertItem(aitem : ItemType) : Boolean;
begin
   PushBack(aitem);
   Result := true;
end;

function TQueueAdt.ExtractItem : ItemType;
begin
   Assert(CanExtract);
   Result := Front;
   PopFront;
end;

function TQueueAdt.CanExtract : Boolean;
begin
   Result := not Empty;
end;

function TQueueAdt.IsDefinedOrder : Boolean;
begin
   Result := false;
end;

{ ------------------------------- TSetAdt ------------------------------------- }

class function TSetAdt.NeedsHasher : Boolean;
begin
   Result := false;
end;

procedure TSetAdt.SetRepeatedItems(b : Boolean);
begin
   Assert(b or not RepeatedItems or Empty, msgChangingRepeatedItemsInNonEmptyContainer);
   FRepeatedItems := b;
end;

procedure TSetAdt.SetComparer(comp : IBinaryComparer);
begin
   Assert(Empty);
   Fcomparer := comp;
end;

constructor TSetAdt.Create;
begin
   inherited Create;
   FComparer := &_mcp_comparer(&ItemType);
   FRepeatedItems := false;
end;

constructor TSetAdt.CreateCopy(const cont : TSetAdt);
begin
   inherited CreateCopy(TContainerAdt(cont));
   FComparer := cont.FComparer;
   FRepeatedItems := cont.FRepeatedItems;
end;

procedure TSetAdt.BasicSwap(cont : TContainerAdt);
begin
   inherited;
   if cont is TSetAdt then
   begin
      ExchangePtr(FComparer, TSetAdt(cont).FComparer);
      ExchangeData(FRepeatedItems, TSetAdt(cont).FRepeatedItems,
                   SizeOf(Boolean));
   end;
end;

function TSetAdt.Extract(aitem : ItemType) : SizeType;
var
   owns : Boolean;
begin
   owns := OwnsItems;
   try
      OwnsItems := false;
      Result := Delete(aitem);
   finally
      OwnsItems := owns;
   end;
end;

function TSetAdt.InsertItem(aitem : ItemType) : Boolean;
begin
   Result := Insert(aitem);
end;

function TSetAdt.ExtractItem : ItemType;
var
   iter : TSetIterator;
begin
   Assert(CanExtract);
   iter := Start;
   Assert(not iter.IsFinish);
   Result := iter.Item;
   iter.Delete;
   iter.Destroy;
end;

function TSetAdt.CanExtract : Boolean;
begin
   Result := not Empty;
end;

{ ------------------------- TSortedSetAdt ------------------------------ }

function TSortedSetAdt.First : ItemType;
var
   iter : TBidirectionalIterator;
begin
   iter := Start;
   Result := iter.Item;
   iter.Destroy;
end;

function TSortedSetAdt.ExtractFirst : ItemType;
var
   iter : TBidirectionalIterator;   
begin
   iter := Start;
   Result := iter.Extract;
   iter.Destroy;
end;

procedure TSortedSetAdt.DeleteFirst;
var
   aitem : ItemType;
begin
   aitem := ExtractFirst;
   DisposeItem(aitem);
end;

function TSortedSetAdt.PriorityQueueInterface : TPriorityQueueAdt;
begin
   Result := TSortedSetPriorityQueueInterface.Create(self, false);
end;

{ -------------------------- THashSetAdt ------------------------------- }

class function THashSetAdt.NeedsHasher : Boolean;
begin
   Result := true;
end;

constructor THashSetAdt.Create;
begin
   inherited Create;
   FHasher := &_mcp_hasher(&ItemType);
   FAutoShrink := false;
end;

constructor THashSetAdt.CreateCopy(const cont : THashSetAdt);
begin
   inherited CreateCopy(TSetAdt(cont));
   FHasher := cont.FHasher;
end;

procedure THashSetAdt.BasicSwap(cont : TContainerAdt);
begin
   inherited;
   if cont is THashSetAdt then
   begin
      ExchangePtr(FHasher, THashSetAdt(cont).FHasher);
      ExchangeData(FAutoShrink, THashSetAdt(cont).FAutoShrink,
                   SizeOf(Boolean));
   end;
end;

procedure THashSetAdt.SetCapacity(cap : SizeType);
begin
   if cap > GetCapacity then
   begin
      if GetCapacity <> 0 then
         Rehash(FloorLog2(cap) - FloorLog2(GetCapacity))
      else
         Rehash(FLoorLog2(cap));
   end;
end;

{$ifdef TEST_PASCAL_ADT }
procedure THashSetAdt.LogStatus(mname : String);
begin
   inherited;
   WriteLog('Max fill ratio: ' + IntToStr(MaxFillRatio) + '%');
   WriteLog('Current fill ratio: ' + IntToStr((Size * 100) div Capacity) + '%');
end;
{$endif TEST_PASCAL_ADT }

{ ---------------------------- TListAdt ---------------------------------- }

{$ifdef DEBUG_PASCAL_ADT }
constructor TListAdt.Create;
begin
   inherited Create;
   FSizeCanRecalc := true;
end;
{$endif DEBUG_PASCAL_ADT }

procedure TListAdt.Move(SourceStart, SourceFinish, Dest : TForwardIterator);
begin
   adtalgs.Move(SourceStart, SourceFinish, Dest)
end;

procedure TListAdt.Move(Source, Dest : TForwardIterator);
begin
   adtalgs.Move(Source, Next(Source), Dest);
end;

{ ---------------------------- TDoubleListAdt ---------------------------------- }

function TDoubleListAdt.BidirectionalStart : TBidirectionalIterator;
begin
   Result := TBidirectionalIterator(ForwardStart);
end;

function TDoubleListAdt.BidirectionalFinish : TBidirectionalIterator;
begin
   Result := TBidirectionalIterator(ForwardFinish);
end;

{ ------------------------- TRandomAccessContainerAdt -------------------------- }

function TRandomAccessContainerAdt.ForwardStart : TForwardIterator; 
begin
   Result := RandomAccessStart;
end;

function TRandomAccessContainerAdt.ForwardFinish : TForwardIterator;
begin
   Result := RandomAccessFinish;
end;
      
procedure TRandomAccessContainerAdt.Insert(iter : TForwardIterator;
                                           aitem : ItemType);
begin
   Assert(iter is TRandomAccessIterator, msgInvalidIterator);
   Insert(TRandomAccessIterator(iter).Index, aitem);
end;

procedure TRandomAccessContainerAdt.Delete(iter : TForwardIterator);
begin
   Assert(iter is TRandomAccessIterator, msgInvalidIterator);
   Delete(TRandomAccessIterator(iter).Index);
end;

function TRandomAccessContainerAdt.Delete(start,
                                          finish : TForwardIterator) : SizeType;
var
   ind1 : IndexType;
begin
   Assert(start is TRandomAccessIterator, msgInvalidIterator);
   Assert(finish is TRandomAccessIterator, msgInvalidIterator);
   ind1 := TRandomAccessIterator(start).Index;
   Result := Delete(ind1, TRandomAccessIterator(finish).Index - ind1);
end;

function TRandomAccessContainerAdt.Extract(iter : TForwardIterator) : ItemType;
begin
   Assert(iter is TRandomAccessIterator, msgInvalidIterator);
   Result := Extract(TRandomAccessIterator(iter).Index);
end;

function TRandomAccessContainerAdt.LowIndex : IndexType;
begin
   Result := 0;
end;

function TRandomAccessContainerAdt.HighIndex : IndexType;
begin
   Result := Size - 1;
end;


{ ---------------------- TRandomAccessContainerIterator ------------------------ }

constructor TRandomAccessContainerIterator.
   Create(ind : IndexType; const Cont : TRandomAccessContainerAdt);
begin
   inherited Create(cont);
   FIndex := ind;
   FCont := cont;
end;

{$ifdef OVERLOAD_DIRECTIVE }
procedure TRandomAccessContainerIterator.Advance;
{$else }
procedure TRandomAccessContainerIterator.AdvanceOnePosition;
{$endif OVERLOAD_DIRECTIVE }
begin
   Inc(FIndex);
end;

procedure TRandomAccessContainerIterator.Advance(i : integer);
begin
   Inc(FIndex, i);
end;

procedure TRandomAccessContainerIterator.Retreat;
begin
   Dec(FIndex);
end;

function TRandomAccessContainerIterator.Distance(const Pos : TRandomAccessIterator)
   : IndexType;
begin
   Assert(pos is TRandomAccessContainerIterator, msgInvalidIterator);
   Assert(pos.Owner = Owner, msgWrongOwner);

   Result := TRandomAccessContainerIterator(pos).FIndex - FIndex;
end;

function TRandomAccessContainerIterator.Equal(const Pos : TIterator) : Boolean;
begin
   Assert(pos is TRandomAccessContainerIterator, msgInvalidIterator);

   Result := (TRandomAccessContainerIterator(pos).FIndex = FIndex)
               and (TRandomAccessContainerIterator(pos).FCont = FCont);
end;

function TRandomAccessContainerIterator.Less(const Pos : TRandomAccessIterator)
   : Boolean;
begin
   Assert(pos is TRandomAccessContainerIterator, msgInvalidIterator);
   Assert(pos.Owner = Owner, msgWrongOwner);

   Result := FIndex < TRandomAccessContainerIterator(pos).FIndex;
end;

function TRandomAccessContainerIterator.GetItem : ItemType;
begin
   Result := FCont.GetItem(FIndex);
end;

procedure TRandomAccessContainerIterator.SetItem(Aitem : ItemType);
begin
   FCont.SetItem(FIndex, aitem);
end;

function TRandomAccessContainerIterator.GetItemAt(i : IndexType) : ItemType;
begin
   Result := FCont.GetItem(FIndex + i);
end;

procedure TRandomAccessContainerIterator.SetItemAt(i : IndexType;
                                                   aitem : ItemType);
begin
   FCont.SetItem(FIndex + i, aitem);
end;

procedure TRandomAccessContainerIterator.ExchangeItem(iter : TIterator);
begin
   if iter.Owner = FCont then
   begin
      Assert((iter is TRandomAccessContainerIterator), msgInvalidIterator);
      
      { ExchangeItemsAt works with indicies relative to self.Index }
      ExchangeItemsAt(0, TRandomAccessContainerIterator(iter).FIndex - FIndex);
   end else
      DoExchangeItem(iter);
end;

procedure TRandomAccessContainerIterator.Insert(Aitem : ItemType);
begin
   FCont.Insert(FIndex, aitem);
end;

function TRandomAccessContainerIterator.Extract : ItemType;
begin
   Result := FCont.Extract(FIndex);
end;

function TRandomAccessContainerIterator.Delete(n : SizeType) : SizeType;
begin
   Result := FCont.Delete(FIndex, n);
end;

function TRandomAccessContainerIterator.Index : Integer;
begin
   Result := FIndex;
end;

function TRandomAccessContainerIterator.Owner : TContainerAdt;
begin
   Result := FCont;
end;

function TRandomAccessContainerIterator.IsStart : Boolean;
begin
   Result := (FIndex = FCont.LowIndex);
end;

function TRandomAccessContainerIterator.IsFinish : Boolean;
begin
   Result := (FIndex = FCont.HighIndex + 1); 
end;

{ -------------------- TSortedSetPriorityQueueInterface --------------------- }

constructor TSortedSetPriorityQueueInterface.Create(aset : TSortedSetAdt;
                                                    aowns : Boolean);
begin
   FSet := aset;
   owns := aowns;
end;

destructor TSortedSetPriorityQueueInterface.Destroy;
begin
   if owns then
      FSet.Free;
   inherited;
end;

function TSortedSetPriorityQueueInterface.
   CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TSortedSetPriorityQueueInterface.
      Create(TSortedSetAdt(FSet.CopySelf(ItemCopier)), true);
end;

procedure TSortedSetPriorityQueueInterface.Insert(aitem : ItemType);
begin
   FSet.Insert(aitem);
end;

function TSortedSetPriorityQueueInterface.First : ItemType;
begin
   Result := FSet.First;
end;

function TSortedSetPriorityQueueInterface.ExtractFirst : ItemType;
begin
   Result := FSet.ExtractFirst;
end;

procedure TSortedSetPriorityQueueInterface.Merge(aqueue : TPriorityQueueAdt);
begin
   Assert(aqueue is TSortedSetPriorityQueueInterface);
   while not aqueue.Empty do
   begin
      Insert(aqueue.ExtractFirst);
   end;
end;

procedure TSortedSetPriorityQueueInterface.Clear;
begin
   FSet.Clear;
end;

function TSortedSetPriorityQueueInterface.Empty : Boolean;
begin
   Result := FSet.Empty;
end;

function TSortedSetPriorityQueueInterface.Size : SizeType;
begin
   Result := FSet.Size;
end;

{$ifdef OVERLOAD_DIRECTIVE }

function CopyOf(const iter : TRandomAccessContainerIterator) :
   TRandomAccessContainerIterator;
begin
   Result := TRandomAccessContainerIterator(iter.CopySelf);
end;

{$endif OVERLOAD_DIRECTIVE }

