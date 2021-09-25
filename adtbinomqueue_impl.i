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
 adtbinomqueue_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtbinomqueue.defs
&include adtbinomqueue_impl.mcp

&define TBinomialTreeNode T&_mcp_prefix&BinomialTreeNode
&define PBinomialTreeNode P&_mcp_prefix&BinomialTreeNode


{ Notes on the implementation of TBinomialQueue: }
{ TBinomialQueue is a binomial priority queue. It consists of at most
  log(n) binomial trees, each of different size. The roots of the
  binomial trees are stored in the FTrees array. A binomial tree is
  denoted as B(k). A tree B(k) has 2^k nodes, and its root is a parent
  of k binomial trees: B(k-1), B(k-2), ..., B(0) from left to
  right. B(0) is a single node. The tree at FTrees[k] is B(k). }
{ Due to this organisation it is comparatively easy to merge two
  binomial queues. The algorithm just imitates the algorithm of the
  addition of two binary numbers. Other operations are implemented
  using this notion.  }
{ FSize stores the overall number of items. }
{ A position within a TBinomialQueue is represented by a (node,index)
  pair, where node is a pointer to the positon, index is the index of
  the tree containing node within FTrees. The finish position is
  represented by (nil,-1). }

{ ---------------------- TBinomialQueue ------------------------------ }

constructor TBinomialQueue.Create; 
begin
   inherited Create;
   FTrees := nil;
end;

constructor TBinomialQueue.CreateCopy(const cont : TBinomialQueue;
                                      const itemCopier : IUnaryFunctor);

   function CopyTree(node : PBinomialTreeNode) : PBinomialTreeNode;
   var
      pdest : ^PBinomialTreeNode;
      destParent, dest : PBinomialTreeNode;
   begin
      Assert((node^.Parent = nil) and (node^.RightSibling = nil));
      Result := nil;
      pdest := @Result;
      destParent := nil;
      { copy the tree while going pre-order }
      try
         while node <> nil do
         begin
            NewNode(pdest^, DefaultItem); { may raise }
            Inc(FSize);
            with pdest^^ do
            begin
               Parent := destParent;
               Item := itemCopier.Perform(node^.Item); { may raise }
            end;
            if node^.LeftmostChild <> nil then
            begin
               node := node^.LeftmostChild;
               destParent := pdest^;
               pdest := @pdest^^.LeftmostChild;
            end else
            begin
               dest := nil;
               while (node^.Parent <> nil) and (node^.RightSibling = nil) do
               begin
                  node := node^.Parent;
                  dest := destParent;
                  destParent := destParent^.Parent;
               end;
               if dest <> nil then
               begin
                  pdest := @dest^.RightSibling;
                  node := node^.RightSibling;
               end else
                  break;
            end;
         end;
      except
         DestroyTree(Result, false);
         raise;
      end;
   end;
   
var
   i : IndexType;
begin
   inherited CreateCopy(TPriorityQueueAdt(cont));
   if itemCopier <> nil then
   begin
      SetLength(FTrees, Length(cont.FTrees)); { may raise }
      for i := 0 to Length(FTrees) - 1 do
         FTrees[i] := nil;
      for i := 0 to Length(FTrees) - 1 do
      begin
         if cont.FTrees[i] <> nil then
            FTrees[i] := CopyTree(cont.FTrees[i]); { may raise }
      end;
   end;
end;

destructor TBinomialQueue.Destroy; 
begin
   Clear;
   inherited;
end;

function TBinomialQueue.FirstIndex : IndexType;
var
   i : IndexType;
   minItem : ItemType;
begin
   Assert(FSize <> 0);
   Result := 0;
   while FTrees[Result] = nil do
      Inc(Result);
   minItem := FTrees[Result]^.Item;   
   i := Result + 1;
   while i < Length(Ftrees) do
   begin
      if (FTrees[i] <> nil) and
            (_mcp_lt(Ftrees[i]^.Item, minItem)) then
      begin
         minItem := Ftrees[i]^.Item;
         Result := i;
      end;
      Inc(i);
   end;
end;

procedure TBinomialQueue.DestroyTree(node : PBinomialTreeNode;
                                     disposeItems : Boolean);
var
   nnode : PBinomialTreeNode;
begin
   Assert((node = nil) or ((node^.Parent = nil) and (node^.RightSibling = nil)));
   { destroy the tree while going post-order }
   node := LeftMostLeafNode(node);
   while node <> nil do
   begin
      nnode := NextPostOrderNode(node);
      if disposeItems then
         DisposeItem(node^.Item);
      Dec(FSize);
      { since we are traversing post-order, the node will never be
        visited again, even not while coming towards some other node }
      DisposeNode(node);
      node := nnode;
   end;
end;

procedure TBinomialQueue.ConnectAsLeftmostChild(parent, node : PBinomialTreeNode);
begin
   Assert((node^.Parent = nil) and (node^.RightSibling = nil));
   node^.Parent := parent;
   node^.RightSibling := parent^.LeftmostChild;
   Parent^.LeftmostChild := node;
end;

procedure TBinomialQueue.CheckTreesLength(additionalSize : SizeType);
var
   oldlen : SizeType;
   i : IndexType;
begin
   if FSize + additionalSize > (1 shl Length(FTrees)) - 1 then
   begin
      oldlen := Length(FTrees);
      SetLength(FTrees, CeilLog2(FSize + additionalSize));
      for i := oldlen to Length(FTrees) - 1 do
         FTrees[i] := nil;
   end;
end;

{ returns the root of the tree of the merged nodes }
function TBinomialQueue.MergeNodes(node1, node2 : PBinomialTreeNode) : PBinomialTreeNode;
begin
   if _mcp_lte(node1^.Item, node2^.Item) then
   begin
      ConnectAsLeftmostChild(node1, node2);
      Result := node1;
   end else
   begin
      ConnectAsLeftmostChild(node2, node1);
      Result := node2;
   end;   
end;

{ CheckTreesLength should be called earlier with the number of items
  in <forest> }
procedure TBinomialQueue.MergeForest(forest : TBinomialForest);
var
   i : IndexType;
   carry, node : PBinomialTreeNode;
begin
   { FTrees should have been grown earlier }
   Assert(Length(forest) <= Length(FTrees));
   i := 0;
   carry := nil;
   while i < Length(forest) do
   begin
      if (forest[i] <> nil) and (FTrees[i] <> nil) then
      begin
         node := MergeNodes(forest[i], FTrees[i]);
         FTrees[i] := carry;
         carry := node;
      end else if carry <> nil then
      begin
         if forest[i] <> nil then
         begin
            Assert(FTrees[i] = nil);
            carry := MergeNodes(forest[i], carry);
         end else if FTrees[i] <> nil then
         begin
            carry := MergeNodes(FTrees[i], carry);
            FTrees[i] := nil;
         end else
         begin
            FTrees[i] := carry;
            carry := nil;
         end;
      end else if forest[i] <> nil then
      begin
         Assert(FTrees[i] = nil);
         FTrees[i] := forest[i];
      end;
      Inc(i);
   end;
   while (i < Length(FTrees)) and (carry <> nil) do
   begin
      if FTrees[i] <> nil then
      begin
         carry := MergeNodes(carry, FTrees[i]);
         FTrees[i] := nil;
      end else
      begin
         FTrees[i] := carry;
         carry := nil;
      end;
      Inc(i);
   end;
end;

function TBinomialQueue.InsertNode(node : PBinomialTreeNode) : IndexType;
var
   i : IndexType;   
begin
   Result := -1;
   Assert((node^.Parent = nil) and (node^.RightSibling = nil) and
             (node^.LeftmostChild = nil));
   if (FSize = (1 shl Length(FTrees)) - 1) then
   begin
      { we would have an 'overflow' - grow the array }
      try
         SetLength(FTrees, Length(FTrees) + 1); { may raise }
         FTrees[Length(FTrees) - 1] := nil;
      except
         DisposeNode(node);
         raise;
      end;
   end;
   { perform an operation analogous to binary addition of numbers on
     the array of trees - node is an equivalent of a carry flag }
   for i := 0 to Length(FTrees) - 1 do
   begin
      if FTrees[i] <> nil then
      begin
         node := MergeNodes(node, FTrees[i]);
         FTrees[i] := nil;
      end else
      begin
         FTrees[i] := node;
         node := nil;
         Result := i;
         break;
      end;
   end;
   Assert(node = nil, msgInternalError);
   Inc(FSize);
end;

function TBinomialQueue.DeleteNode(index : IndexType) : ItemType;
var
   node, child : PBinomialTreeNode;
   i : IndexType;
   forest : TBinomialForest;
begin
   Result := FTrees[index]^.Item;
   node := FTrees[index];
   SetLength(forest, index); { may raise }
   
   Assert(index = NodeChildren(node));
   
   child := node^.LeftmostChild;
   for i := Length(forest) - 1 downto 0 do
   begin
      forest[i] := child;
      child := child^.RightSibling;
      with forest[i]^ do
      begin
         Parent := nil;
         RightSibling := nil;
      end;
   end;

   FTrees[index] := nil;
   { this cannot raise an exception, since we are actually removing an
     item, not adding, so more space certainly will not be needed.  }
   MergeForest(forest);
   if (Length(FTrees) <> 0) and (FTrees[Length(FTrees) - 1] = nil) then
      SetLength(FTrees, Length(FTrees) - 1);
   DisposeNode(node);
   Dec(FSize);
end;

procedure TBinomialQueue.NewNode(var node : PBinomialTreeNode; aitem : ItemType);
begin
   New(node);
   with node^ do
   begin
      Parent := nil;
      RightSibling := nil;
      LeftmostChild := nil;
      Item := aitem;
   end;   
end;

procedure TBinomialQueue.DisposeNode(node : PBinomialTreeNode);
begin
   Dispose(node);
end;

function TBinomialQueue.Start : TBinomialQueueIterator;
begin
   if FSize <> 0 then
      Result := TBinomialQueueIterator.Create(FTrees[0], 0, self)
   else
      Result := TBinomialQueueIterator.Create(nil, -1, self);
end;

function TBinomialQueue.Finish : TBinomialQueueIterator;
begin
   Result := TBinomialQueueIterator.Create(nil, -1, self);
end;

function TBinomialQueue.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TBinomialQueue.CreateCopy(self, itemcopier);
end;

procedure TBinomialQueue.Swap(cont : TContainerAdt);
begin
   if cont is TBinomialQueue then
   begin
      BasicSwap(cont);
      ExchangePtr(FTrees, TBinomialQueue(cont).FTrees);
      ExchangeData(FSize, TBinomialQueue(cont).FSize, SizeOf(SizeType));
   end else
      inherited;
end;

procedure TBinomialQueue.Insert(aitem : ItemType);
var
   node : PBinomialTreeNode;
begin
   NewNode(node, aitem); { may raise, but harmless }
   InsertNode(node);
end;

function TBinomialQueue.First : ItemType;
begin
   Assert(FSize <> 0, msgReadEmpty);
   Result := FTrees[FirstIndex]^.Item;
end;

function TBinomialQueue.ExtractFirst : ItemType;
begin
   Result := DeleteNode(FirstIndex);
end;

procedure TBinomialQueue.Merge(aqueue : TPriorityQueueAdt);
var
   forest : TBinomialForest;
   bqueue : TBinomialQueue;
begin
   Assert(aqueue is TBinomialQueue);
   bqueue := TBinomialQueue(aqueue);
   forest := bqueue.FTrees;
   CheckTreesLength(bqueue.FSize); { may raise }
   { MergeForest is exception-safe, so as long as bqueue is changed
     only after a successful invocation of this method, the Merge
     method is also exception-safe }
   MergeForest(forest);
   FSize := FSize + bqueue.FSize;
   bqueue.FTrees := nil;
   bqueue.FSize := 0;
   bqueue.Destroy;
end;

procedure TBinomialQueue.Clear;
var
   i : IndexType;
begin
   for i := 0 to Length(FTrees) - 1 do
      DestroyTree(FTrees[i], true);
   Ftrees := nil;
   Assert(FSize = 0);
end;

function TBinomialQueue.Empty : Boolean; 
begin
   Result := FSize = 0;
end;

function TBinomialQueue.Size : SizeType; 
begin
   Result := FSize;
end;

{ --------------------- TBinomialQueueIterator -------------------------- }

constructor TBinomialQueueIterator.Create(anode : PBinomialTreeNode;
                                          atreeindex : IndexType;
                                          acont : TBinomialQueue);
begin
   inherited Create(acont);
   FNode := anode;
   FTreeIndex := atreeindex;
   FCont := acont;
   if (FNode = nil) and (FTreeIndex <> -1) then
      AdvanceToNearestItem;
end;

procedure TBinomialQueueIterator.AdvanceToNearestItem;
begin
   Assert(FTreeIndex <> -1);
   if FCont.FSize <> 0 then
   begin
      while FNode = nil do
      begin
         Inc(FTreeIndex);
         if FTreeIndex < Length(FCont.FTrees) then
         begin
            FNode := FCont.Ftrees[FTreeIndex];
         end else
         begin
            FTreeIndex := -1;
            break;
         end;
      end;
   end else
   begin
      FNode := nil;
      FTreeIndex := -1;
   end;
end;

procedure TBinomialQueueIterator.RetreatToNearestItem;
begin
   Assert(FTreeIndex <> -1);
   if FCont.FSize <> 0 then
   begin
      while FNode = nil do
      begin
         Dec(FTreeIndex);
         Assert(FTreeIndex >= 0, msgRetreatingStartIterator);
         FNode := RightMostLeafNode(FCont.Ftrees[FTreeIndex]);
      end;
   end else
   begin
      FNode := nil;
      FTreeIndex := -1;
   end;
end;

function TBinomialQueueIterator.CopySelf : TIterator; 
begin
   Result := TBinomialQueueIterator.Create(FNode, FTreeIndex, FCont);
end;

function TBinomialQueueIterator.Equal(const Pos : TIterator) : Boolean; 
begin
   Assert(pos is TBinomialQueueIterator, msgInvalidIterator);
   Result := TBinomialQueueIterator(pos).FNode = FNode;
end;

function TBinomialQueueIterator.GetItem : ItemType; 
begin
   Assert(FNode <> nil, msgInvalidIterator);
   Result := FNode^.Item;
end;

procedure TBinomialQueueIterator.SetItem(aitem : ItemType); 
begin
   Assert(FNode <> nil, msgInvalidIterator);
   with FCont do
      DisposeItem(FNode^.Item);
   FNode^.Item := aitem;
   ResetItem;
end;

procedure TBinomialQueueIterator.ResetItem;

   function GetMinimalChild(node : PBinomialTreeNode) : PBinomialTreeNode;
   begin
      Result := node^.LeftmostChild;
      if Result <> nil then
      begin
         with FCont do
         begin
            node := Result^.RightSibling;
            while node <> nil do
            begin
               if _mcp_lt(node^.Item, Result^.Item) then
                  Result := node;
               node := node^.RightSibling;
            end;
         end;
      end;
   end;
   
var
   child : PBinomialTreeNode;
begin
   with FCont do
   begin
      if (FNode^.Parent <> nil) and
            (_mcp_lt(FNode^.Item, FNode^.Parent^.Item)) then
      begin
         repeat
            adtutils.ExchangeItem(FNode^.Item, FNode^.Parent^.Item);
            FNode := FNode^.Parent;
         until (FNode^.Parent = nil) or
            (_mcp_gte(FNode^.Item, FNode^.Parent^.Item));
      end else if FNode^.LeftmostChild <> nil then
      begin
         child := GetMinimalChild(FNode);
         while (child <> nil) and
                  (_mcp_lt(child^.Item, FNode^.Item)) do
         begin
            adtutils.ExchangeItem(child^.Item, FNode^.Item);
            FNode := child;
            child := GetMinimalChild(FNode);
         end;
      end;
   end;
end;

procedure TBinomialQueueIterator.ExchangeItem(iter : TIterator); 
begin
   raise EDefinedOrder.Create('TBinomialQueueIterator.ExchangeItem');
end;

procedure TBinomialQueueIterator.Advance; 
begin
   Assert(FNode <> nil, msgAdvancingFinishIterator);
   FNode := NextPreOrderNode(FNode);
   if FNode = nil then
   begin
      Inc(FTreeIndex);
      if FTreeIndex <> Length(FCont.FTrees) then
      begin
         FNode := FCont.FTrees[FTreeIndex];
         AdvanceToNearestItem;
      end else
      begin
         FTreeIndex := -1;
      end;
   end;
end;

procedure TBinomialQueueIterator.Retreat; 
begin
   Assert(not IsStart, msgRetreatingStartIterator);
   with FCont do
   begin
      if FNode = nil then
      begin
         FNode := RightMostLeafNode(FTrees[Length(FTrees) - 1]);
         FTreeIndex := Length(FTrees) - 1;
         RetreatToNearestItem;
      end else
      begin
         if FNode^.Parent <> nil then
         begin
            FNode := PrevPreOrderNode(FNode, FTrees[FTreeIndex]);            
         end else
         begin
            Dec(FTreeIndex);
            FNode := RightMostLeafNode(FTrees[FTreeIndex]);
            RetreatToNearestItem;
         end;
      end;
   end;
end;

procedure TBinomialQueueIterator.Insert(aitem : ItemType);
var
   node : PBinomialTreeNode;
begin
   FCont.NewNode(node, aitem);
   FTreeIndex := FCont.InsertNode(node);
   FNode := node;
end;

function TBinomialQueueIterator.Extract : ItemType;
begin
   Assert(FNode <> nil, msgDeletingInvalidIterator);
   { move the node up the tree }
   Result := FNode^.Item;
   FNode^.Item := DefaultItem;
   while FNode^.Parent <> nil do
   begin
      adtutils.ExchangeItem(FNode^.Item, FNode^.Parent^.Item);
      FNode := FNode^.Parent;
   end;
   FCont.DeleteNode(FTreeIndex);
   { just move to the first item of the container to assure that all
     items are visited }
   if FCont.FSize <> 0 then
   begin
      FNode := FCont.FTrees[0];
      FTreeIndex := 0;
      AdvanceToNearestItem;
   end else
   begin
      FNode := nil;
      FTreeIndex := -1;
   end;
end;

function TBinomialQueueIterator.IsStart : Boolean;
var
   i : IndexType;
begin
   with FCont do
   begin
      if FSize <> 0 then
      begin
         if FNode = FTrees[FTreeIndex] then
         begin
            i := 0;
            while FTrees[i] = nil do
               Inc(i);
            result := (FNode = FTrees[i]);
         end else
            Result := false;
      end else
         Result := FNode = nil;
   end;
end;

function TBinomialQueueIterator.IsFinish : Boolean; 
begin
   Result := FNode = nil;
end;

function TBinomialQueueIterator.Owner : TContainerAdt; 
begin
   Result := FCont;
end;
