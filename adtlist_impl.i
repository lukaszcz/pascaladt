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
 adtlist_impl.inc::prefix:&_mcp_prefix&::item_type:&ItemType&
 }

&include adtlist.defs
&include adtlist_impl.mcp

(* Notes on the parts of implementation common to all lists:
 *  Every list in this module has, in addition to fields needed to manage the
 * representation itself, FSize and FValidSize fields. These are responsible
 * of keeping track of the number of Items stored in the list. The basic idea
 * is that FSize keeps the exact number of Items, so it is incremented when
 * new item is added and decremented when Items are removed. However,
 * it is not always possible to know how many Items are added. Such situation
 * occurs when moving a range of Items from one list to another (or the same).
 * There is no way of knowing how many Items are in a range, excepty for iterating
 * through all its Items, which is too expensive. In such situation FValidSize
 * fields of both lists are set to false to indicate that FSize fields do not
 * show a proper number of Items. Next time, when Size method is called and
 * FValidSize is false it recalculates the number of Items in the list by
 * iterating through all Items, updates FSize field and sets FValidSize back
 * to true. This takes O(n) time, but happens rarely, so we can say that the amortized
 * complexity of Size operation is O(1).
 *)

{ **************************************************************************** }
{                              Singly linked list                              }
{ **************************************************************************** }
(* Notes on implementation of TSingleList:
 *  TSingleList is implemented using a header (FStartNode), which itself does not
 * contain any data (FStartNode^.Item = DefaultItem). The position in the list is
 * represented by the pointer to the node _before_ the desired one, e.g.
 * data for the first node is stored in FStartNode^.Next^.Item. The 'one beyond
 * last' node is also stored (as FFinishNode) and its Next field is nil.
 *  TSingleList graphically:
 *   node 1:     node 2:            node n:   node n+1:         node F: (the one
 *  +-----+      +-----+           +-----+    +-----+           +-----+   beyond
 *  | nil |  ->  |  1  | -> ... -> | n-1 | -> |  n  | -> ... -> | F-1 |   the last
 *  +-----+      +-----+           +-----+    +-----+           +-----+    node)
 *
 * The number inside each node represents item field; it specifies which node's
 * data is stored there.
 * F - one beyond last node (FFinishNode)
 * Node 1 is the first node (FStartNode).
 * Arrows show which node points to which (via its Next field).
 *)


{----------------------------- TSingleList members -------------------------------}

constructor TSingleList.Create;
begin
   inherited Create;
   InitFields;
end;

constructor TSingleList.CreateCopy(const cont : TSingleList;
                                   const itemCopier : IUnaryFunctor);
var
   pnode : PSingleListNode;
begin
   inherited CreateCopy(cont);
   InitFields;
   
   if itemCopier <> nil then
   begin
      pnode := cont.FStartNode;
      FSize := 0;
      while pnode <> cont.FFinishNode do
      begin     
         NewNode(FFinishNode^.Next);
         FFinishNode := FFinishNode^.Next;
         
         { in case of an exception...  }
         FFinishNode^.Next := nil;
         FFinishNode^.Item := DefaultItem;
         
         FFinishNode^.Item := ItemCopier.Perform(pnode^.Next^.Item);
         
         Inc(FSize);
         
         pnode := pnode^.Next;
      end;
      cont.FValidSize := true;
      cont.FSize := FSize;
   end;
end;

destructor TSingleList.Destroy;
begin
   { if FStartNode is not nil then the object was fully constructed
     (nothing can raise an exception except for the allocation of
     FStartNode) }
   if FStartNode <> nil then 
   begin
      Clear;
      DisposeNode(FStartNode);
   end;
   inherited;
end;

procedure TSingleList.InitFields;
begin
   NewNode(FStartNode);
   FStartNode^.Item := DefaultItem;
   FStartNode^.Next := nil;
   FFinishNode := FStartNode;
   FValidSize := true;
   FSize := 0;
end;

procedure TSingleList.DisposeNodeAndItem(node : PSingleListNode);
begin
   DisposeItem(node^.Item); { may throw, but it's harmless }
   DisposeNode(node);
end;

procedure TSingleList.DoSetItem(pos : PSingleListNode; aitem : ItemType);
begin
   with pos^.Next^ do
   begin
      DisposeItem(Item);
      Item := aitem;
   end;
end;

{ does not maintain FSize field ! }
procedure TSingleList.DoMove(dest, source1, source2 : PSingleListNode;
                             list2 : TSingleList);
var
   temp : PSingleListNode;
begin
   Assert((dest <> nil) and (source1 <> nil) and (source2 <> nil),
          msgInvalidIterator);
   Assert(source1^.Next <> nil, msgInvalidIteratorRange);
   
   if (dest = source1) or (dest = source2) then
      Exit;

   temp := dest^.Next;
   dest^.Next := source1^.Next;
   source1^.Next := source2^.Next;
   source2^.Next := temp;
   if (source1^.Next = nil) then
      list2.FFinishNode := source1;
   if (source2^.Next = nil) then
      FFinishNode := source2;
end;


function TSingleList.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TSingleList.CreateCopy(self, ItemCopier);
end;

procedure TSingleList.Swap(cont : TContainerAdt);
var
   ls2 : TSingleList;
begin
   if cont is TSingleList then
   begin
      BasicSwap(cont);
      ls2 := TSingleList(cont);
      ExchangePtr(FStartNode, ls2.FStartNode);
      ExchangePtr(FFinishNode, ls2.FFinishNode);
      ExchangeData(FSize, ls2.FSize, SizeOf(SizeType));
      ExchangeData(FValidSize, ls2.FValidSize, SizeOf(Boolean));
   end else
      inherited;
end;

function TSingleList.ForwardStart : TForwardIterator;
begin
   Result := TSingleListIterator.Create(FStartNode, self);
end;

function TSingleList.ForwardFinish : TForwardIterator;
begin
   Result := TSingleListIterator.Create(FFinishNode, self);
end;

function TSingleList.Start : TSingleListIterator;
begin
   Result := TSingleListIterator.Create(FStartNode, self);
end;

function TSingleList.Finish : TSingleListIterator;
begin
   Result := TSingleListIterator.Create(FFinishNode, self);
end;

procedure TSingleList.Insert(pos : TForwardIterator; aitem : ItemType);
begin
   Assert((pos is TSingleListIterator) and (pos.Owner = self), msgInvalidIterator);

   InsertNode(TSingleListIterator(pos).Node, aitem);
end;

procedure TSingleList.Delete(pos : TForwardIterator);
var
   aitem : ItemType;
begin
   Assert(pos is TSingleListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);
   
   aitem := ExtractNode(TSingleListIterator(pos).Node);
   DisposeItem(aitem);
   pos.Destroy;
end;

function TSingleList.Delete(astart, afinish : TForwardIterator) : SizeType;
var
   pos, fin, npos : PSingleListNode;
begin
   Assert((astart is TSingleListIterator) and (afinish is TSingleListIterator),
          msgInvalidIterator);
   Assert((TSingleListIterator(astart).Node <> nil) and
             (TSingleListIterator(afinish).Node <> nil), msgInvalidIterator);
   
   Result := FSize;
   pos := TSingleListIterator(astart).Node;
   fin := TSingleListIterator(afinish).Node^.Next;
   if fin = nil then
      FFinishNode := pos;
   
   while (pos^.Next <> fin) do
   begin
      DisposeItem(pos^.Next^.Item);
      Dec(FSize);
      npos := pos^.Next^.Next;
      DisposeNode(pos^.Next);
      pos^.Next := npos;
   end;
   
   Result := Result - FSize;
end;

function TSingleList.Extract(pos : TForwardIterator) : ItemType;
begin
   Assert(pos is TSingleListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);
   
   Result := ExtractNode(TSingleListIterator(pos).Node);
   pos.Destroy;
end;

procedure TSingleList.Move(Source, Dest : TForwardIterator);
var
   temp : PSingleListNode;
   list2 : TSingleList;
begin
   Assert(dest is TSingleListIterator, msgInvalidIterator);
   Assert(Source is TSingleListIterator, msgInvalidIterator);
   Assert(dest.Owner = self, msgWrongOwner);

   list2 := TSingleListIterator(Source).FList;
   temp := TSingleListIterator(source).Node;
   DoMove(TSingleListIterator(dest).Node, temp, temp^.Next, list2);
   Inc(FSize);
   Dec(list2.FSize);
end;

procedure TSingleList.Move(SourceStart, SourceFinish, Dest : TForwardIterator);
var
   list2 : TSingleList;
   source1, source2 : PSingleListNode;
begin
   Assert(Dest is TSingleListIterator, msgInvalidIterator);
   Assert(SourceStart is TSingleListIterator, msgInvalidIterator);
   Assert(SourceFinish is TSingleListIterator, msgInvalidIterator);
   Assert(dest.Owner = self, msgWrongOwner);
   Assert(SourceStart.Owner = SourceFinish.Owner, msgWrongRangeOwner);
   Assert((SourceStart.Owner <> Dest.Owner) or
             not (Less(SourceStart, Dest) and Less(Dest, SourceFinish)),
          msgMovingBadRange);

   list2 := TSingleListIterator(SourceFinish).FList;
   source1 := TSingleListIterator(SourceStart).Node;
   source2 := TSingleListIterator(SourceFinish).Node;
   if source1 = source2 then { special case - empty range }
      Exit;

   DoMove(TSingleListIterator(Dest).Node, source1, source2, list2);
   if SourceStart.Owner <> self then
   begin
      FValidSize := false;
      list2.FValidSize := false;
   end;
end;

function TSingleList.Front : ItemType;
begin
   Assert(FStartNode^.Next <> nil, msgReadEmpty);
   Result := FStartNode^.Next^.Item;
end;

function TSingleList.Back : ItemType;
begin
   Assert(FStartNode^.Next <> nil, msgReadEmpty);
   Result := FFinishNode^.Item;
end;

procedure TSingleList.PushBack(aitem : ItemType);
begin
   NewNode(FFinishNode^.Next);
   FFinishNode := FFinishNode^.Next;
   FFinishNode^.Item := aitem;
   FFinishNode^.Next := nil;
   Inc(FSize);
end;

procedure TSingleList.PushFront(aitem : ItemType);
var
   temp : PSingleListNode;
begin
   NewNode(temp);
   temp^.Next := FStartNode;
   FStartNode^.Item := aitem;
   FStartNode := temp;
   Inc(FSize);
end;

procedure TSingleList.PopBack;
var
   prev : PSingleListNode;
begin
   Assert(FStartNode^.Next <> nil, msgPopEmpty);
   
   prev := FStartNode;
   while prev^.Next <> FFinishNode do
   begin
      prev := prev^.Next
   end;
   DisposeNodeAndItem(FFinishNode);
   prev^.Next := nil;
   FFinishNode := prev;
   Dec(FSize);
end;

procedure TSingleList.PopFront;
var
   temp : PSingleListNode;
begin
   Assert(FStartNode^.Next <> nil, msgPopEmpty);
   temp := FStartNode^.Next^.Next;
   DisposeNodeAndItem(FStartNode^.Next);
   FStartNode^.Next := temp;
   if FStartNode^.Next = nil then
      FFinishNode := FStartNode;
   Dec(FSize);
end;

procedure TSingleList.Clear;
var
   temp, dnode : PSingleListNode;
begin
   dnode := FStartNode^.Next;
   while dnode <> nil do
   begin
      temp := dnode;
      dnode := dnode^.Next;
      DisposeNodeAndItem(temp);
   end;
   FStartNode^.Next := nil;
   FFinishNode := FStartNode;
   FSize := 0;
   FValidSize := true;
   
   { destroy all iterators into container, as they are not valid anyway }
   GrabageCollector.FreeObjects;
end;

function TSingleList.Empty : Boolean;
begin
   Result := (FStartNode^.Next = nil);
end;

function TSingleList.Size : SizeType;
var
   temp : PSingleListNode;
begin
{$ifdef DEBUG_PASCAL_ADT }
   Assert(SizeCanRecalc or FValidSize, msgMoveNotUpdate);
   SizeCanRecalc := true;
{$endif DEBUG_PASCAL_ADT }

   if not FValidSize then
   begin
      FSize := 0;
      temp := FStartNode;
      while temp^.Next <> nil do
      begin
         Inc(FSize);
         temp := temp^.Next;
      end;
      FValidSize := true;
   end;
   Result := FSize;
end;

function TSingleList.IsDefinedOrder : Boolean;
begin
   Result := false;
end;

function TSingleList.InsertNode(pos : PSingleListNode;
                                aitem : ItemType) : PSingleListNode;
begin
   Assert(pos <> nil, msgInvalidIterator);
   
   {$warnings off }
   NewNode(Result);
   {$warnings on }
   Result^.Next := pos^.Next;
   Result^.Item := aitem;
   pos^.Next := Result;
   if (Result^.Next = nil) then
      FFinishNode := Result;
   Inc(FSize);
end;

function TSingleList.ExtractNode(pos : PSingleListNode) : ItemType;
var
   todispose : PSingleListNode;
begin
   Assert((pos <> nil) and (pos^.Next <> nil), msgInvalidIterator);
   
   todispose := pos^.Next;
   Result := pos^.Next^.Item;
   pos^.Next := pos^.Next^.Next;
   if (pos^.Next = nil) then
      FFinishNode := pos;
   
   DisposeNode(todispose);
   Dec(FSize);
end;

procedure TSingleList.NewNode(var node : PSingleListNode);
begin
   New(node);
end;

procedure TSingleList.DisposeNode(node : PSingleListNode);
begin
   Dispose(node);
end;

{ ----------------------- TSingleListIterator members ----------------------- }

constructor TSingleListIterator.Create(xnode : PSingleListNode;
                                       list : TSingleList);
begin
   inherited Create(list);
   Node := xnode;
   FList := list;
end;

function TSingleListIterator.CopySelf : TIterator;
begin
   Result := TSingleListIterator.Create(Node, FList);
end;

procedure TSingleListIterator.Advance;
begin
   Assert((Node <> nil) and (Node^.Next <> nil), msgAdvancingFinishIterator);
   Node := Node^.Next;
end;

function TSingleListIterator.GetItem : ItemType;
begin
   Assert((Node <> nil) and (Node^.Next <> nil), msgDereferencingInvalidIterator);
   Result := Node^.Next^.Item;
end;

procedure TSingleListIterator.SetItem(aitem : ItemType);
begin
   Assert((Node <> nil) and (Node^.Next <> nil), msgDereferencingInvalidIterator);
   FList.DoSetItem(Node, aitem);
end;

procedure TSingleListIterator.ExchangeItem(iter : TIterator);
var
   aitem : ItemType;
   xnode : PSingleListNode;
begin
   Assert((Node <> nil) and (Node^.Next <> nil), msgInvalidIterator);
   
   if iter is TSingleListIterator then
   begin
      xnode := TSingleListIterator(iter).Node;
      Assert((xnode <> nil) and (xnode^.Next <> nil), msgInvalidIterator);
      aitem := xnode^.Next^.Item;
      xnode^.Next^.Item := Node^.Next^.Item;
      Node^.Next^.Item := aitem;
   end else
      DoExchangeItem(iter);
end;

function TSingleListIterator.Extract : ItemType;
begin
   Result := FList.ExtractNode(Node);
end;

function TSingleListIterator.Delete(afinish : TForwardIterator) : SizeType;
begin
   Result := FList.Delete(self, afinish);
   { Node is made to point at finish in this routine }
end;

procedure TSingleListIterator.Insert(aitem : ItemType);
begin
   FList.InsertNode(Node, aitem);
end;

function TSingleListIterator.Equal(const pos : TIterator) : Boolean;
begin
   Assert((Node <> nil) and (pos is TSingleListIterator), msgInvalidIterator);
   Assert(TSingleListIterator(pos).Node <> nil, msgInvalidIterator);

   Result := (Node = TSingleListIterator(pos).Node);
end;

function TSingleListIterator.Owner : TContainerAdt;
begin
   Result := FList;
end;

function TSingleListIterator.IsStart : Boolean;
begin
   Result := Node = FList.FStartNode;
end;

function TSingleListIterator.IsFinish : Boolean;
begin
   Result := (Node = FList.FFinishNode);
end;



{ **************************************************************************** }
{                              Doubly linked list                              }
{ **************************************************************************** }
(* Notes on implementation of TDoubleList:
 *  The list is represented by a header - FStartNode and implemented as a circular list.
 * The one beyond last node's Next field points to FStartNode and the first node's Prev
 * field points to the one beyond last node. Unlike TSingleList, the header node (FStartNode)
 * contains an item, because a position is represented by a pointer to the desired
 * node (not the one before). However, the 'one beyond last' node (FStartNode^.Prev)
 * does not contain an item; it is only used to somehow indicate the end of a
 * sequence. An empty list is represented by a single node, whose Prev and Next
 * fields point to themselves.
 *  TDoubleList graphically:
 *      node 1:       node 2:             node n:             node F: (the one beyond last one)
 *    +-------+      +-------+           +-------+           +-------+
 * <- | L | 2 |  ->  | 1 | 3 | -> ... -> |n-1|n+1| -> ... -> |L-1| 1 | -> (this node does not
 * -> +-------+  <-  +-------+ <-     <- +-------+ <-     <- +-------+ <-  cointain an item,
 *      P   N          P   N               P   N               P   N     its aitem field is nil)
 * P - Prev field; N - Next field; F - 'one beyond last' node;
 * Node 1 is the first node (FStartNode).
 * Each node stores its own item, except for node F, which does not have an
 * item and contains DefaultItem in the aitem field.
 *)


{ ----------------------------- TDoubleList members ----------------------------- }

constructor TDoubleList.Create;
begin
   inherited Create;
   InitFields;
end;

constructor TDoubleList.CreateCopy(const cont : TDoubleList;
                                   const itemCopier : IUnaryFunctor);
var
   pnode, pnode2 : PDoubleListNode;
begin
   inherited CreateCopy(cont);
   InitFields;
   
   if itemCopier <> nil then
   begin
      pnode := cont.FStartNode;
      pnode2 := FStartNode;
      try
         while pnode^.Next <> cont.FStartNode do
         begin
            pnode2^.Next := nil; { in case of an exception }
            
            NewNode(pnode2^.Next); { may raise }
            pnode2^.Next^.Prev := pnode2;
            pnode2^.Item := ItemCopier.Perform(pnode^.Item); { may raise }
            
            pnode2 := pnode2^.Next;
            pnode := pnode^.Next;
            
            Inc(FSize);
         end;
         pnode2^.Next := nil;
         
      finally
         if pnode2^.Next <> nil then
            DisposeNode(pnode2^.Next);
         pnode2^.Next := FStartNode;
         FStartNode^.Prev := pnode2;
         pnode2^.Item := DefaultItem;
      end;
      cont.FSize := FSize;
      cont.FValidSize := true;
   end;
end;

destructor TDoubleList.Destroy;
begin
   if FStartNode <> nil then
   begin
      Clear;
      DisposeNode(FStartNode);
   end;
   inherited;
end;

function TDoubleList.GetFinishNode : PDoubleListNode;
begin
   Result := FStartNode^.Prev;
end;

procedure TDoubleList.InitFields;
begin
   NewNode(FStartNode);
   FStartNode^.Item := DefaultItem;
   FStartNode^.Next := FStartNode;
   FStartNode^.Prev := FStartNode;
   FValidSize := true;
end;

procedure TDoubleList.DisposeNodeAndItem(node : PDoubleListNode);
begin
   DisposeItem(node^.Item);
   DisposeNode(node);
end;

procedure TDoubleList.DoSetItem(pos : PDoubleListNode; aitem : ItemType);
begin
   DisposeItem(pos^.Item);
   pos^.Item := aitem;
end;

procedure TDoubleList.DoMove(dest, source1, source2 : PDoubleListNode;
                             list2 : TDoubleList);
var
   temp : PDoubleListNode;
begin
   Assert((source1 <> nil) and (dest <> nil) and (source2 <> nil),
          msgInvalidIterator);
   Assert(source1 <> source2);
   
   if (dest = source1) or (dest = source2) then
      Exit;
   
   temp := dest^.Prev;
   dest^.Prev := source2^.Prev;
   source1^.Prev^.Next := source2;
   source2^.Prev := source1^.Prev;
   source1^.Prev := temp;
   temp^.Next := source1;
   dest^.Prev^.Next := dest;
   if (list2.FStartNode = source1) then
      list2.FStartNode := source2;
   if FStartNode = dest then
      FStartNode := source1;
end;

function TDoubleList.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TDoubleList.CreateCopy(self, ItemCopier);
end;

procedure TDoubleList.Swap(cont : TContainerAdt);
var
   ls2 : TDoubleList;
begin
   if cont is TDoubleList then
   begin
      BasicSwap(cont);
      ls2 := TDoubleList(cont);
      ExchangePtr(FStartNode, ls2.FStartNode);
      ExchangeData(FSize, ls2.FSize, SizeOf(SizeType));
      ExchangeData(FValidSize, ls2.FValidSize, SizeOf(Boolean));
   end else
      inherited;
end;

function TDoubleList.ForwardStart : TForwardIterator;
begin
   Result := Start;
end;

function TDoubleList.ForwardFinish : TForwardIterator;
begin
   Result := Finish;
end;

function TDoubleList.Start : TDoubleListIterator;
begin
   Result := TDoubleListIterator.Create(FStartNode, self);
end;

function TDoubleList.Finish : TDoubleListIterator;
begin
   Result := TDoubleListIterator.Create(FStartNode^.Prev, self);
end;

procedure TDoubleList.Insert(pos : TForwardIterator; aitem : ItemType);
begin
   Assert(pos is TDoubleListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);
   InsertNode(TDoubleListIterator(pos).Node, aitem);
end;

procedure TDoubleList.Delete(pos : TForwardIterator);
var
   aitem : ItemType;
begin
   Assert(pos is TDoubleListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);
   
   aitem := ExtractNode(TDoubleListIterator(pos).Node);
   DisposeItem(aitem);
   pos.Destroy; { pos is invalidated so it cannot be used anyway }
end;

function TDoubleList.Delete(astart, afinish : TForwardIterator) : SizeType;
var
   pos, fin, npos : PDoubleListNode;
begin
   Assert((astart is TDoubleListIterator) and (afinish is TDoubleListIterator),
          msgInvalidIterator);
   Assert((TDoubleListIterator(astart).Node <> nil) and
             (TDoubleListIterator(afinish).Node <> nil), msgInvalidIterator);
   
   Result := FSize;
   pos := TDoubleListIterator(astart).Node;
   fin := TDoubleListIterator(afinish).Node;
   
   pos^.Prev^.Next := fin;
   fin^.Prev := pos^.Prev;
   if FStartNode = pos then
      FStartNode := fin;
   
   while (pos <> fin) do
   begin
      npos := pos^.Next;
      DisposeItem(pos^.Item);
      Dec(FSize);
      DisposeNode(pos);
      pos := npos;
   end;
   
   Result := Result - FSize;
end;

function TDoubleList.Extract(pos : TForwardIterator) : ItemType;
begin
   Assert(pos is TDoubleListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);
   
   Result := ExtractNode(TDoubleListIterator(pos).Node);
   pos.Destroy;
end;

procedure TDoubleList.Move(Source, Dest : TForwardIterator);
var
   list2 : TDoubleList;
   snode : PDoubleListNode;
begin
   Assert(Dest is TDoubleListIterator, msgInvalidIterator);
   Assert(Source is TDoubleListIterator, msgInvalidIterator);
   Assert(Dest.Owner = self, msgWrongOwner);
   Assert(TDoubleListIterator(Source).Node^.Next <>
             TDoubleList(Source.Owner).FStartNode, msgMovingInvalidIterator);

   list2 := TDoubleListIterator(Source).FList;
   snode := TDoubleListIterator(Source).Node;
   DoMove(TDoubleListIterator(Dest).Node, snode, snode^.Next, list2);
   Inc(FSize);
   Dec(list2.FSize);
end;

procedure TDoubleList.Move(SourceStart, SourceFinish, Dest : TForwardIterator);
var
   source1, source2 : PDoubleListNode;
   list2 : TDoubleList;
begin
   Assert(Dest is TDoubleListIterator, msgInvalidIterator);
   Assert(SourceStart is TDoubleListIterator, msgInvalidIterator);
   Assert(SourceFinish is TDoubleListIterator, msgInvalidIterator);
   Assert(SourceStart.Owner = SourceFinish.Owner, msgWrongRangeOwner);
   Assert(Dest.Owner = self, msgWrongOwner);
   Assert(TDoubleListIterator(SourceStart).Node^.Next <>
            TDoubleList(SourceStart.Owner).FStartNode,
                  msgMovingInvalidIterator);
   Assert((SourceStart.Owner <> Dest.Owner) or
             not (Less(SourceStart, Dest) and Less(Dest, SourceFinish)),
          msgMovingBadRange);

   source1 := TDoubleListIterator(SourceStart).Node;
   source2 := TDoubleListIterator(SourceFinish).Node;
   if source1 = source2 then { special case - empty range }
      Exit;

   list2 := TDoubleListIterator(SourceStart).FList;
   DoMove(TDoubleListIterator(Dest).Node, source1, source2, list2);
   if SourceStart.Owner <> self then
   begin
      FValidSize := false;
      list2.FValidSize := false;
   end;
end;

function TDoubleList.Front : ItemType;
begin
   Assert(FStartNode^.Next <> FStartNode, msgReadEmpty);
   Result := FStartNode^.Item;
end;

function TDoubleList.Back : ItemType;
begin
   Assert(FStartNode^.Next <> FStartNode, msgReadEmpty);
   Result := FStartNode^.Prev^.Prev^.Item;
end;

procedure TDoubleList.PushBack(aitem : ItemType);
var
   temp : PDoubleListNode;
begin
   NewNode(temp);
   temp^.Item := aitem;
   temp^.Next := FStartNode^.Prev;
   temp^.Prev := FStartNode^.Prev^.Prev;
   FStartNode^.Prev^.Prev^.Next := temp;
   FStartNode^.Prev^.Prev := temp;
   if FStartNode^.Prev = temp then { temp is the first inserted Item }
      FStartNode := temp;
   Inc(FSize);
end;

procedure TDoubleList.PopBack;
var
   lastnode, newback  : PDoubleListNode;
begin
   Assert(FStartNode^.Next <> FStartNode, msgPopEmpty);
   
   lastnode := FStartNode^.Prev;
   newback := lastnode^.Prev^.Prev;
   DisposeNodeAndItem(newback^.Next); { may throw }
   newback^.Next := lastnode;
   lastnode^.Prev := newback;
   if newback^.Next = newback then
      FStartNode := newback;
   Dec(FSize);
end;

procedure TDoubleList.PushFront(aitem : ItemType);
var
   pnewnode : PDoubleListNode;
begin
   NewNode(pnewnode);
   pnewnode^.Item := aitem;
   pnewnode^.Next := FStartNode;
   pnewnode^.Prev := FStartNode^.Prev;
   FStartNode^.Prev^.Next := pnewnode;
   FStartNode^.Prev := pnewnode;
   FStartNode := pnewnode;
   Inc(FSize);
end;

procedure TDoubleList.PopFront;
var
   newfirst, lastnode : PDoubleListNode;
begin
   Assert(FStartNode^.Next <> FStartNode, msgPopEmpty);

   lastnode := FStartNode^.Prev;
   newfirst := FStartNode^.Next;
   DisposeNodeAndItem(FStartNode); { may throw exception }
   FStartNode := newfirst;
   FStartNode^.Prev := lastnode;
   lastnode^.Next := FStartNode;
   Dec(FSize);
end;

procedure TDoubleList.Clear;
var
   lastnode : PDoubleListNode;
begin
   FValidSize := false; { in case of an exception }
   lastnode := FStartNode^.Prev;
   while FStartNode <> lastnode do
   begin
      FStartNode := FStartNode^.Next;
      DisposeNodeAndItem(FStartNode^.Prev); { exception possible here }
   end;
   FStartNode^.Next := FStartNode;
   FStartNode^.Prev := FStartNode;
   FSize := 0;
   FValidSize := true;
   
   { destroy all iterators into container, as they are not valid anyway }
   GrabageCollector.FreeObjects;
end;

function TDoubleList.Empty : Boolean;
begin
   Result := (FStartNode^.Next = FStartNode);
end;

function TDoubleList.Size : SizeType;
var
   temp : PDoubleListNode;
begin
{$ifdef DEBUG_PASCAL_ADT }
   Assert(SizeCanRecalc or FValidSize, msgMoveNotUpdate);
   SizeCanRecalc := true;
{$endif DEBUG_PASCAL_ADT }

   if not FValidSize then
   begin
      FSize := 0;
      temp := FStartNode;
      while temp^.Next <> FStartNode do
      begin
         Inc(FSize);
         temp := temp^.Next;
      end;
      FValidSize := true;
   end;
   Result := FSize;
end;

function TDoubleList.IsDefinedOrder : Boolean;
begin
   Result := false;
end;

function TDoubleList.InsertNode(pos : PDoubleListNode;
                                aitem : ItemType) : PDoubleListNode;
begin
   Assert(pos <> nil);
   
   {$warnings off }
   NewNode(Result);
   {$warnings on }
   Result^.Item := aitem;
   Result^.Next := pos;
   Result^.Prev := pos^.Prev;
   pos^.Prev^.Next := Result;
   pos^.Prev := Result;
   if pos = FStartNode then
      FStartNode := Result;
   Inc(FSize);
end;

function TDoubleList.ExtractNode(pos : PDoubleListNode) : ItemType;
begin
   Assert((pos <> nil) and (pos^.Next <> FStartNode), msgDeletingInvalidIterator);
   
   pos^.Prev^.Next := pos^.Next;
   pos^.Next^.Prev := pos^.Prev;
   if pos = FStartNode then
      FStartNode := pos^.Next;
   Result := pos^.Item;
   DisposeNode(pos);
   Dec(FSize);
end;

procedure TDoubleList.NewNode(var node : PDoubleListNode);
begin
   New(node);
end;

procedure TDoubleList.DisposeNode(node : PDoubleListNode);
begin
   Dispose(node);
end;

{ ------------------------- TDoubleListIterator members ------------------------- }

constructor TDoubleListIterator.Create(xnode : PDoubleListNode;
                                       list : TDoubleList);
begin
   inherited Create(list);
   Node := xnode;
   FList := list;
end;

function TDoubleListIterator.CopySelf : TIterator;
begin
   Result := TDoubleListIterator.Create(Node, FList);
end;

procedure TDoubleListIterator.Advance;
begin
   Assert(Node^.Next <> FList.FStartNode, msgAdvancingFinishIterator);
   Node := Node^.Next;
end;

procedure TDoubleListIterator.Retreat;
begin
   Assert(Node <> FList.FStartNode, msgRetreatingStartIterator);
   Node := Node^.Prev;
end;

function TDoubleListIterator.Equal(const pos : TIterator) : Boolean;
begin
   Assert(pos is TDoubleListIterator, msgInvalidIterator);
   Result := (TDoubleListIterator(pos).Node = Node);
end;

function TDoubleListIterator.GetItem : ItemType;
begin
   Assert(Node^.Next <> FList.FStartNode, msgDereferencingInvalidIterator);
   Result := Node^.Item;
end;

procedure TDoubleListIterator.SetItem(aitem : ItemType);
begin
   Assert(Node^.Next <> FList.FStartNode, msgDereferencingInvalidIterator);
   Flist.DoSetItem(Node, aitem);
end;

procedure TDoubleListIterator.ExchangeItem(iter : TIterator);
var
   aitem : ItemType;
   xnode : PDoubleListNode;
begin
   Assert((Node^.Next <> FList.FStartNode), msgInvalidIterator);
   
   if iter is TDoubleListIterator then
   begin
      xnode := TDoubleListIterator(iter).Node;
      Assert(xnode^.Next <> TDoubleList(iter.Owner).FStartNode,
             msgInvalidIterator);
      aitem := xnode^.Item;
      xnode^.Item := Node^.Item;
      Node^.Item := aitem;
   end else
      DoExchangeItem(iter);
end;

function TDoubleListIterator.Extract : ItemType;
begin
   Node := Node^.Next;
   Result := FList.ExtractNode(Node^.Prev);
end;

function TDoubleListIterator.Delete(afinish : TForwardIterator) : SizeType;
var
   nnode : PDoubleListNode;
begin
   Assert((afinish is TDoubleListIterator), msgInvalidIterator);
   nnode := TDoubleListIterator(afinish).Node;
   Result := FList.Delete(self, afinish);
   Node := nnode;
end;

procedure TDoubleListIterator.Insert(aitem : ItemType);
begin
   Node := FList.InsertNode(Node, aitem);
end;

function TDoubleListIterator.Owner : TContainerAdt;
begin
   Result := FList;
end;

function TDoubleListIterator.IsStart : Boolean;
begin
   Result := Node = FList.FStartNode;
end;

function TDoubleListIterator.IsFinish : Boolean;
begin
   Result := (Node^.Next = FList.FStartNode);
end;



{ **************************************************************************** }
{                                   XOR list                                   }
{ **************************************************************************** }
(* Notes on implementation of TXorList:
 *  Xor-list is essentially a doubly-linked list using a clever trick to save
 * memory. It uses only one PointerValueType (32bit in Delphi) field to store both Prev
 * and Next pointers (TXListNode.PN). These pointers are xor'ed together. This
 * implies that to read a next or prev pointer value you must already have one
 * of them. This is why TXorListIterator stores additional field Prev, which
 * points to a node before the node to which iterator points. To get the next
 * node in such representation you need to xor current node's PN field with
 * the address of the previous node. Indeed, Node^.PN = Prev xor Next, so
 * Node^.PN xor Prev = Next xor Prev xor Prev = Next. To get the previous
 * node having the next one is just the opposite (Node^.PN xor Next). The list
 * object itself stores two pointers: FStartNode - the pointer to the first node,
 * and BackNode - the pointer to the last node (NOT one beyond last). When a list
 * is empty they are both nil, when it contains one item they both point to this
 * item. Note that because there is no node before FStartNode it stores in its
 * PN field an exact address of the next node. Simirally, BackNode stores the exact
 * address of the node before it, since there is no node after it with which the
 * value of PN could be xor'ed.
 *
 *  TXorList graphically:
 *      node 1:        node 2:                node n:                node B: (BackNode)
 *    +---------+    +---------+           +-----------+           +-----------+
 *    | nil ^ 2 | -> |  1 ^ 3  | -> ... -> | n-1 ^ n+1 | -> ... -> | B-1 ^ nil |
 *    +---------+ <- +---------+ <-     <- +-----------+ <-     <- +-----------+
 *
 *  ^ represents xor operation; the numbers inside each node represent which addresses
 * of which nodes are stored in the node as, respectively, the previous and the next node's
 * address. All nodes contain Item. nil indicates pointer with value 0 (no node
 * before/after), and when xored with second address it doesn't change the result,
 * as for all n, n xor 0 = n
 *)

{ ------------------------------ TXorList members ------------------------------ }

constructor TXorList.Create;
begin
   inherited Create;
   InitFields;
end;

constructor TXorList.CreateCopy(const cont : TXorList;
                                const itemCopier : IUnaryFunctor);
var
   curr1, prev1, prev2, temp : PXListNode;
begin
   inherited CreateCopy(cont);
   InitFields;
   
   if itemCopier <> nil then
   begin
      curr1 := cont.FStartNode;
      prev1 := nil;
      prev2 := nil;
      while curr1 <> nil do
      begin
         NewNode(BackNode); { may raise }
         
         BackNode^.PN := PointerValueType(prev2);
         if prev2 <> nil then
         begin
            prev2^.PN := PointerValueType(prev2^.PN) xor
               PointerValueType(BackNode);
         end else
            FStartNode := BackNode;         
         
         BackNode^.Item := DefaultItem; { in case of an exception }
         BackNode^.Item := ItemCopier.Perform(curr1^.Item); { may raise }
         
         prev2 := BackNode;
         Inc(FSize);
         
         temp := curr1;
         curr1 := PXListNode(PointerValueType(prev1) xor curr1^.PN);
         prev1 := temp;
      end;
      cont.FValidSize := true;
      cont.FSize := FSize;
   end;
end;

destructor TXorList.Destroy;
begin
   Clear; { if object was not fully constructed Clear still works ok }
   inherited;
end;

procedure TXorList.InitFields;
begin
   FStartNode := nil;
   BackNode := nil;
   FSize := 0;
   FValidSize := true;
end;

procedure TXorList.NewNode(var node : PXListNode);
begin
   New(node);
end;

procedure TXorList.DisposeNode(node : PXListNode);
begin
   Dispose(node);
end;

procedure TXorList.DisposeNodeAndItem(node : PXListNode);
begin
   DisposeItem(node^.Item);
   DisposeNode(node);
end;

procedure TXorList.DoSetItem(pos : PXListNode; aitem : ItemType);
begin
   DisposeItem(pos^.Item);
   pos^.Item := aitem;
end;

{ inserts between prev and pos }
function TXorList.DoInsert(pos, prev : PXListNode; aitem : ItemType) : PXListNode;
begin
   {$warnings off }
   NewNode(Result);
   {$warnings on }
   Result^.Item := aitem;
   Result^.PN := PointerValueType(prev) xor PointerValueType(pos); { pos^.NEXT  }

   if pos <> nil then { not the finish node }
      pos^.PN := PointerValueType(Result) xor (pos^.PN xor PointerValueType(prev))
   else
      BackNode := Result;

   if prev <> nil then { not the first node }
      prev^.PN := (prev^.PN xor PointerValueType(pos)) xor PointerValueType(Result)
   else
      FStartNode := Result;
   Inc(FSize);
end;

{ returns node to be disposed }
function TXorList.DoDelete(pos, prev : PXListNode) : PXListNode;
var
   next : PXListNode;
begin
   Assert(pos <> nil, msgDeletingInvalidIterator);

   Result := pos;
   if prev <> nil then
   begin
      next := PXListNode(pos^.PN xor PointerValueType(prev));
      { i.e. prev^.Prev xor pos^.Next }
      prev^.PN := (prev^.PN xor PointerValueType(pos)) xor PointerValueType(next);
      if next <> nil then
      begin
         next^.PN :=
            (next^.PN xor PointerValueType(pos)) xor PointerValueType(prev);
      end;
   end else
   begin
      FStartNode := PXListNode(pos^.PN); { i.e.: FStartNode := Next(FStartNode); }
      if FStartNode <> nil then { if it wasn't the last item... }
         FStartNode^.PN := FStartNode^.PN xor PointerValueType(pos);
   end;
   
   if pos = BackNode then
      BackNode := prev;
   
   Dec(FSize);
end;

{ prevdest - node before dest, prevs1 - node before source1, pres2 -
  node before source2 }
{ inserts the range [source1, source2) between prevdest and dest }
procedure TXorList.DoMove(dest, prevdest, source1, prevs1,
                          source2, prevs2 : PXListNode; list2 : TXorList);
begin
   Assert((source1 <> source2) and (source1 <> nil) and (prevs2 <> nil),
          msgInvalidIteratorRange);
   
   if (dest <> nil) and ((source1 = dest) or (source2 = dest)) then
      Exit;

   if prevs1 <> nil then
      prevs1^.PN := prevs1^.PN xor PointerValueType(source1) xor
         PointerValueType(source2)
   else
      list2.FStartNode := source2;
   if source2 <> nil then
      source2^.PN := PointerValueType(prevs1) xor
         (source2^.PN xor PointerValueType(prevs2))
   else
      list2.BackNode := prevs1;
   prevs2^.PN := (prevs2^.PN xor PointerValueType(source2)) xor
      PointerValueType(dest);
   source1^.PN := PointerValueType(prevdest) xor
      (source1^.PN xor PointerValueType(prevs1));
   if prevdest <> nil then
      prevdest^.PN := (prevdest^.PN xor PointerValueType(dest)) xor
         PointerValueType(source1)
   else
      FStartNode := source1;
   if dest <> nil then
      dest^.PN := PointerValueType(prevs2) xor
         (dest^.PN xor PointerValueType(prevdest))
   else
      BackNode := prevs2;
end;

procedure TXorList.DoClear;
var
   next, temp : PXListNode;
begin
   FValidSize := false; { in case an exception is thrown }
   if FStartNode <> nil then
   begin
      next := PXListNode(FStartNode^.PN);
      while next <> nil do
      begin
         temp := FStartNode;
         FStartNode := next;
         next := PXListNode(next^.PN xor PointerValueType(temp));
         DisposeNodeAndItem(temp);
      end;
      if FStartNode <> nil then
         DisposeNodeAndItem(FStartNode);
   end;
   FStartNode := nil;
   BackNode := nil;
   FValidSize := true;
   FSize := 0;
end;

function TXorList.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TXorList.CreateCopy(self, ItemCopier);
end;

procedure TXorList.Swap(cont : TContainerAdt);
var
   ls2 : TXorList;
begin
   if cont is TXorList then
   begin
      BasicSwap(cont);
      ls2 := TXorList(cont);
      ExchangePtr(FStartNode, ls2.FStartNode);
      ExchangePtr(BackNode, ls2.BackNode);
      ExchangeData(FSize, ls2.FSize, SizeOf(SizeType));
      ExchangeData(FValidSize, ls2.FValidSize, SizeOf(Boolean));
   end else
      inherited;
end;

function TXorList.ForwardStart : TForwardIterator;
begin
   Result := Start;
end;

function TXorList.ForwardFinish : TForwardIterator;
begin
   Result := Finish;
end;

function TXorList.Start : TXorListIterator;
begin
   Result := TXorListIterator.Create(FStartNode, nil, self);
end;

function TXorList.Finish : TXorListIterator;
begin
   Result := TXorListIterator.Create(nil, BackNode, self);
end;

procedure TXorList.Insert(pos : TForwardIterator; aitem : ItemType);
var
   obj : TXorListIterator;
begin
   Assert(pos is TXorListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);

   obj := TXorListIterator(pos);
   DoInsert(obj.Node, obj.Prev, aitem);
end;

procedure TXorList.Delete(pos : TForwardIterator);
var
   obj : TXorListIterator;
begin
   Assert(pos is TXorListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);

   obj := TXorListIterator(pos);
   DisposeNodeAndItem( DoDelete(obj.Node, obj.Prev) );
end;

function TXorList.Delete(astart, afinish : TForwardIterator) : SizeType;
var
   pos, fin, npos, prevpos, prevfin : PXListNode;
begin
   Assert((astart is TXorListIterator) and (afinish is TXorListIterator),
          msgInvalidIterator);
   
   Result := FSize;
   pos := TXorListIterator(astart).Node;
   fin := TXorListIterator(afinish).Node;
   prevpos := TXorListIterator(astart).Prev;
   prevfin := TXorListIterator(afinish).Prev;
   
   if (FStartNode = pos) and (fin = nil) then
   begin
      DoClear;
   end else
   begin
      if FStartNode = pos then
         FStartNode := fin;
      if (fin = nil) and (pos <> nil) then
         BackNode := prevpos;
      
      if prevpos <> nil then
      begin
         prevpos^.PN := prevpos^.PN xor PointerValueType(pos) xor
            PointerValueType(fin);
      end;
      if fin <> nil then
      begin
         fin^.PN := fin^.PN xor PointerValueType(prevfin) xor
            PointerValueType(prevpos);
      end;
      
      while (pos <> fin) do
      begin
         DisposeItem(pos^.Item);
         Dec(FSize);
         npos := PXListNode(pos^.PN xor PointerValueType(prevpos));
         prevpos := pos;
         DisposeNode(pos);
         pos := npos;
      end;
      
      Result := Result - FSize;
   end;
end;

function TXorList.Extract(pos : TForwardIterator) : ItemType;
var
   obj : TXorListIterator;
   aitem : PXListNode;
begin
   Assert(pos is TXorListIterator, msgInvalidIterator);
   Assert(pos.Owner = self, msgWrongOwner);

   obj := TXorListIterator(pos);
   aitem := DoDelete(obj.Node, obj.Prev);
   Result := aitem^.Item;
   DisposeNode(aitem);
end;

procedure TXorList.Move(Source, Dest : TForwardIterator);
var
   destobj, sourceobj : TXorListIterator;
   list2 : TXorList;
begin
   Assert((Dest is TXorListIterator) and
            (Source is TXorListIterator), msgInvalidIterator);
   Assert(TXorListIterator(Source).Node <> nil, msgInvalidIterator);
   Assert(Dest.Owner = self, msgWrongOwner);

   destobj := TXorListIterator(Dest);
   sourceobj := TXorListIterator(Source);
   list2 := TXorListIterator(sourceobj).FList;
   DoMove(destobj.Node, destobj.Prev, sourceobj.Node, sourceobj.Prev,
          PXListNode(sourceobj.Node^.PN xor PointerValueType(sourceobj.Prev)),
          sourceobj.Node, list2);
   Inc(FSize);
   Dec(list2.FSize);
end;

procedure TXorList.Move(SourceStart, SourceFinish, Dest : TForwardIterator);
var
   destobj, source1, source2 : TXorListIterator;
   list2 : TXorList;
begin
   Assert((Dest is TXorListIterator) and
            (SourceStart is TXorListIterator) and
            (SourceFinish is TXorListIterator), msgInvalidIterator);
   Assert(TXorListIterator(SourceStart).Node <> nil, msgInvalidIterator);
   Assert(Dest.Owner = self, msgWrongOwner);
   Assert(SourceStart.Owner = SourceFinish.Owner, msgWrongRangeOwner);
   Assert((SourceStart.Owner <> Dest.Owner) or
             not (Less(SourceStart, Dest) and Less(Dest, SourceFinish)),
          msgMovingBadRange);

   source1 := TXorListIterator(SourceStart);
   source2 := TXorListIterator(SourceFinish);
   if source1.Node = source2.Node then { empty range }
      Exit;
   destobj := TXorListIterator(Dest);
   list2 := TXorListIterator(source1).FList;
   DoMove(destobj.Node, destobj.Prev,
          source1.Node, source1.Prev, source2.Node, source2.Prev,
          list2);
   if SourceStart.Owner <> self then
   begin
      FValidSize := false;
      list2.FValidSize := false;
   end;
end;

function TXorList.Front : ItemType;
begin
   Assert(FStartNode <> nil, msgReadEmpty);
   Result := FStartNode^.Item;
end;

function TXorList.Back : ItemType;
begin
   Assert(BackNode <> nil, msgReadEmpty);
   Result := BackNode^.Item;
end;

procedure TXorList.PushBack(aitem : ItemType);
var
   node : PXListNode;
begin
   NewNode(node);
   node^.Item := aitem;
   node^.PN := PointerValueType(BackNode);
   if BackNode <> nil then
      BackNode^.PN := BackNode^.PN xor PointerValueType(node)
   else
      FStartNode := Node;
   BackNode := Node;
   Inc(FSize);
end;

procedure TXorList.PopBack;
var
   prev : PXListNode;
begin
   Assert(BackNode <> nil, msgEmpty);
   prev := PXListNode(BackNode^.PN);
   if prev <> nil then
      prev^.PN := prev^.PN xor PointerValueType(BackNode)
   else
      FStartNode := nil;
   DisposeNodeAndItem(BackNode);
   BackNode := prev;
   Dec(FSize);
end;

procedure TXorList.PushFront(aitem : ItemType);
var
   node : PXListNode;
begin
   NewNode(node);
   node^.Item := aitem;
   node^.PN := PointerValueType(FStartNode);
   if FStartNode <> nil then
      FStartNode^.PN := PointerValueType(node) xor FStartNode^.PN
   else
      BackNode := node;
   FStartNode := node;
   Inc(FSize);
end;

procedure TXorList.PopFront;
var
   next : PXListNode;
begin
   Assert(FStartNode <> nil, msgEmpty);
   next := PXListNode(FStartNode^.PN);
   if next <> nil then
   begin
      { next no longer connected to FStartNode }
      next^.PN := next^.PN xor PointerValueType(FStartNode);
   end else
      BackNode := nil;
   DisposeNodeAndItem(FStartNode);
   FStartNode := next;
   Dec(FSize);
end;

procedure TXorList.Clear;
begin
   DoClear;
   { destroy all iterators into container, as they are not valid anyway }
   GrabageCollector.FreeObjects;
end;

function TXorList.Empty : Boolean;
begin
   Result := (FStartNode = nil);
end;

function TXorList.Size : SizeType;
var
   prev, curr, temp : PXListNode;
begin
{$ifdef DEBUG_PASCAL_ADT }
   Assert(SizeCanRecalc or FValidSize, msgMoveNotUpdate);
   SizeCanRecalc := true;
{$endif DEBUG_PASCAL_ADT }

   if not FValidSize then
   begin
      FSize := 0;
      prev := nil;
      curr := FStartNode;
      while curr <> nil do
      begin
         Inc(FSize);
         temp := prev;
         prev := curr;
         curr := PXListNode(curr^.PN xor PointerValueType(temp));
      end;
      FValidSize := true;
   end;
   Result := FSize;
end;

function TXorList.IsDefinedOrder : Boolean;
begin
   Result := false;
end;

{ --------------------------- TXorListIterator members ------------------------- }

constructor TXorListIterator.Create(thisnode, prevnode : PXListNode;
                                    list : TXorList);
begin
   inherited Create(list);
   Node := thisnode;
   Prev := prevnode;
   FList := list;
end;

function TXorListIterator.CopySelf : TIterator;
begin
   Result := TXorListIterator.Create(Node, Prev, FList);
end;

procedure TXorListIterator.Advance;
var
   next : PXListNode;
begin
   Assert(Node <> nil, msgAdvancingFinishIterator);

   next := PXListNode(Node^.PN xor PointerValueType(Prev));
   Prev := Node;
   Node := next;
end;

procedure TXorListIterator.Retreat;
var
   prevprev : PXListNode;
begin
   Assert(Prev <> nil, msgRetreatingStartIterator);

   prevprev := PXListNode(Prev^.PN xor PointerValueType(Node));
   Node := Prev;
   Prev := prevprev;
end;

function TXorListIterator.Equal(const pos : TIterator) : Boolean;
begin
   Assert(pos is TXorListIterator, msgInvalidIterator);
   Result := (Node = TXorListIterator(pos).Node);
end;

function TXorListIterator.GetItem : ItemType;
begin
   Assert(Node <> nil, msgDereferencingInvalidIterator);
   Result := Node^.Item;
end;

procedure TXorListIterator.SetItem(aitem : ItemType);
begin
   Assert(Node <> nil, msgDereferencingInvalidIterator);
   FList.DoSetItem(Node, aitem);
end;

procedure TXorListIterator.ExchangeItem(iter : TIterator);
var
   aitem : ItemType;
   xnode : PXListNode;
begin
   Assert((Node <> nil), msgInvalidIterator);
   
   if iter is TXorListIterator then
   begin
      xnode := TXorListIterator(iter).Node;
      Assert(xnode <> nil, msgInvalidIterator);
      aitem := xnode^.Item;
      xnode^.Item := Node^.Item;
      Node^.Item := aitem;
   end else
      DoExchangeItem(iter);
end;

function TXorListIterator.Extract : ItemType;
var
   temp : PXListNode;
begin
   Result := Node^.Item;
   temp := PXListNode(Node^.PN xor PointerValueType(Prev));
   with FList do
      DisposeNode(FList.DoDelete(Node, Prev));
   Node := temp;
end;

function TXorListIterator.Delete(afinish : TForwardIterator) : SizeType;
var
   nnode : PXListNode;
begin
   Assert((afinish is TXorListIterator), msgInvalidIterator);
   nnode := TXorListIterator(afinish).Node;
   Result := FList.Delete(self, afinish);
   Node := nnode;
   { Prev stays the same }
end;

procedure TXorListIterator.Insert(aitem : ItemType);
begin
   Node := FList.DoInsert(Node, Prev, aitem);
end;

function TXorListIterator.Owner : TContainerAdt;
begin
   Result := FList;
end;

function TXorListIterator.IsStart : Boolean;
begin
   Result := Node = FList.FStartNode;
end;

function TXorListIterator.IsFinish : Boolean;
begin
   Result := (Node = nil);
end;

{ --------------------------- non-member routines ------------------------------  }

function CopyOf(const iter : TSingleListIterator) : TSingleListIterator;
begin
   Result := TSingleListIterator(iter.CopySelf);
end;

function CopyOf(const iter : TDoubleListIterator) : TDoubleListIterator;
begin
   Result := TDoubleListIterator(iter.CopySelf);
end;

function CopyOf(const iter : TXorListIterator) : TXorListIterator;
begin
   Result := TXorListIterator(iter.CopySelf);
end;



