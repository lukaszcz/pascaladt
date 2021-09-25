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
 adtbstree_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtbstree.defs
&include adtbstree_impl.mcp

{ -------------------- TBinarysearchTreeBase --------------------------------- }

constructor TBinarySearchTreeBase.Create(btree : TBinaryTree);
begin
   inherited Create;
   FBinaryTree := btree;
end;

constructor TBinarySearchTreeBase.Create;
begin
   inherited Create;
   FBinaryTree := TBinaryTree.Create;
end;

constructor TBinarySearchTreeBase.CreateCopy(const cont : TBinarySearchTreeBase;
                                             const itemCopier : IUnaryFunctor);
begin
   inherited CreateCopy(TSetAdt(cont));
   FBinaryTree := TBinaryTree(cont.FBinaryTree.CopySelf(itemCopier));
end;

destructor TBinarySearchTreeBase.Destroy;
begin
   FBinaryTree.Free;
   inherited;
end;

procedure TBinarySearchTreeBase.SetOwnsItems(b : Boolean);
begin
   inherited;
   FBinaryTree.OwnsItems := b;
end;

procedure TBinarySearchTreeBase.SetDisposer(const proc : IUnaryFunctor);
begin
   inherited;
   FBinaryTree.ItemDisposer := proc;
end;

function TBinarySearchTreeBase.GetDisposer : IUnaryFunctor;
begin
   Result := FBinaryTree.ItemDisposer;
end;

function TBinarySearchTreeBase.
   FindNode(aitem : ItemType; node : PBinaryTreeNode;
            var parent : PBinaryTreeNode) : PBinaryTreeNode;
var
   i : Integer;
begin
   parent := nil;
   Result := node;
   while Result <> nil do
   begin
      _mcp_compare_assign(aitem, Result^.Item, i);
      if i < 0 then
      begin
         parent := Result;
         Result := Result^.LeftChild;
      end else if i > 0 then
      begin
         parent := Result;
         Result := Result^.RightChild;
      end else
      begin
         { we have to find the _first_ node equal to aitem and there may
           be such node in the left sub-tree }
         if RepeatedItems and (Result^.LeftChild <> nil) then
         begin
            node := FindNode(aitem, Result^.LeftChild, parent);
            if node = nil then
            begin
               parent := Result^.Parent;
            end else
               Result := node;
         end;
         break;
      end;
   end;
end;

function TBinarySearchTreeBase.
   LowerBoundNode(aitem : ItemType; node : PBinaryTreeNode) : PBinaryTreeNode;
var
   dummy : PBinaryTreeNode;
   i : Integer;
begin
   Result := node;
   i := -1; { to avoid special case (node = nil) in the if below the loop }
   while Result <> nil do
   begin
      _mcp_compare_assign(aitem, Result^.Item, i);
      if i < 0 then
      begin
         node := Result;
         Result := Result^.LeftChild;
      end else if i > 0 then
      begin
         node := Result;
         Result := Result^.RightChild;
      end else
      begin
         { we have to find the _first_ node equal to aitem and there may
           be such node in the left sub-tree }
         if RepeatedItems and (Result^.LeftChild <> nil) then
         begin
            node := FindNode(aitem, Result^.LeftChild, dummy);
            if node <> nil then
            begin
               Result := node;
            end;
         end;
         break;
      end;
   end;

   if Result = nil then
   begin
      if i < 0 then
      begin
         { there is no left child and aitem < node, so the first node
           with item >= aitem is the parent of result (stored in node) }
         Result := node;
      end else { i > 0 }
      begin
         { there is no right child and aitem > node, so the first node
           with item >= aitem is the first ancestor node from which we
           turned left, or nil if there is no such node }
         while (node^.Parent <> nil) and (node^.Parent^.LeftChild <> node) do
         begin
            node := node^.Parent;
         end;
         node := node^.Parent;
         Result := node;
      end;
   end;
end;

function TBinarySearchTreeBase.
   InsertNode(aitem : ItemType; node : PBinaryTreeNode) : PBinaryTreeNode;
var
   i : Integer;
   parent : PBinaryTreeNode;
begin
   if node <> nil then
   begin
      while node <> nil do
      begin
         _mcp_compare_assign(aitem, node^.Item, i);
         parent := node;
         if i < 0 then
         begin
            node := node^.LeftChild;
         end else if i > 0 then
         begin
            node := node^.RightChild;
         end else { i = 0 }
         begin
            break;
         end;
      end;

      if i < 0 then
      begin
         BinaryTree.InsertNode(parent^.LeftChild, parent, aitem);
         Result := parent^.LeftChild;
      end else if i > 0 then
      begin
         BinaryTree.InsertNode(parent^.RightChild, parent, aitem);
         Result := parent^.RightChild;
      end else { i = 0 }
      begin
         if RepeatedItems then
         begin
            { insert as first node in the sub-tree of the right child of node }
            if node^.RightChild <> nil then
            begin
               parent := FirstInOrderNode(node^.RightChild);
               FBinaryTree.InsertNode(parent^.LeftChild, parent, aitem);
               Result := parent^.LeftChild;
            end else
            begin
               FBinaryTree.InsertNode(node^.RightChild, node, aitem);
               Result := node^.RightChild;
            end;
         end else
            Result := nil;
      end;

   end else { not node <> nil }
   begin
      if node = FBinaryTree.RootNode then
      begin
         FBinaryTree.InsertAsRoot(aitem);
         Result := FBinaryTree.RootNode;
      end else
         Result := InsertNode(aitem, BinaryTree.RootNode);
   end;
end;

procedure TBinarySearchTreeBase.
   ExchangeBinaryTrees(tree : TBinarySearchTreeBase);
begin
   ExchangePtr(FBinaryTree, tree.FBinaryTree);
end;

function TBinarySearchTreeBase.Start : TSetIterator;
begin
   Result := TBinarySearchTreeBaseIterator.Create(nil, self);
   TBinarySearchTreeBaseIterator(Result).GoToStartNode;
end;

function TBinarySearchTreeBase.Finish : TSetIterator;
begin
   Result := TBinarySearchTreeBaseIterator.Create(nil, self);
end;

&if (&_mcp_accepts_nil)
function TBinarySearchTreeBase.FindOrInsert(aitem : ItemType) : ItemType;
var
   parent, node : PBinaryTreeNode;
begin
   if RepeatedItems then
   begin
      InsertNode(aitem, FBinaryTree.RootNode);
      Result := nil;
   end else
   begin
      node := FindNode(aitem, FBinaryTree.RootNode, parent);
      if node <> nil then
         Result := node^.Item
      else begin
         InsertNode(aitem, parent);
         Result := nil;
      end;
   end;
end;

function TBinarySearchTreeBase.Find(aitem : ItemType) : ItemType;
var
   node, parent : PBinaryTreeNode;
begin
   node := FindNode(aitem, FBinaryTree.RootNode, parent);
   if node <> nil then
      Result := node^.Item
   else
      Result := nil;
end;
&endif &# end &_mcp_accepts_nil

function TBinarySearchTreeBase.Has(aitem : ItemType) : Boolean;
var
   dummy : PBinaryTreeNode;
begin
   Result := FindNode(aitem, FBinaryTree.RootNode, dummy) <> nil;
end;

function TBinarySearchTreeBase.Count(aitem : ItemType) : SizeType;
var
   node, parent : PBinaryTreeNode;
begin
   Result := 0;
   node := FindNode(aitem, FBinaryTree.RootNode, parent);

   if node <> nil then
   begin
      repeat
         Inc(Result);
         node := NextInOrderNode(node);
      until (node = nil) or (not _mcp_equal(node^.Item, aitem));
   end;
end;

function TBinarySearchTreeBase.Insert(aitem : ItemType) : Boolean;
begin
   Result := InsertNode(aitem, BinaryTree.RootNode) <> nil;
end;

function TBinarySearchTreeBase.Insert(pos : TSetIterator;
                                      aitem : ItemType) : Boolean;
var
   node, node2 : PBinaryTreeNode;
begin
   Assert(pos is TBinarySearchTreeBaseIterator, msgInvalidIterator);

   node := TBinarySearchTreeBaseIterator(pos).Node;
   if (node <> nil) then
   begin
      { find the node to start searching from and assign it to node }
      node2 := node;
      while node2^.Parent <> nil do
      begin
         if node2^.Parent^.LeftChild = node then
         begin
            if _mcp_lt(aitem, node2^.Parent^.Item) then
               break
            else begin
               node := node2^.Parent;
            end;
         end else
         begin
            if _mcp_lt(aitem, node2^.Parent^.Item) then
               node := node2^.Parent;
         end;
         node2 := node2^.Parent;
      end;
      Result := InsertNode(aitem, node) <> nil;
   end else
      Result := InsertNode(aitem, BinaryTree.RootNode) <> nil;
end;

function TBinarySearchTreeBase.LowerBound(aitem : ItemType) : TSetIterator;
var
   node: PBinaryTreeNode;
begin
   node := LowerBoundNode(aitem, FBinaryTree.RootNode);
   Result := TBinarySearchTreeBaseIterator.Create(node, self);
end;

function TBinarySearchTreeBase.UpperBound(aitem : ItemType) : TSetIterator;
var
   node : PBinaryTreeNode;
begin
   node := LowerBoundNode(aitem, FBinaryTree.RootNode);
   while (node <> nil) and (_mcp_equal(aitem, node^.Item)) do
   begin
      node := NextInOrderNode(node);
   end;
   Result := TBinarySearchTreeBaseIterator.Create(node, self);
end;

function TBinarySearchTreeBase.EqualRange(aitem : ItemType) : TSetIteratorRange;
var
   node : PBinaryTreeNode;
   iter1, iter2 : TBinarySearchTreeBaseIterator;
begin
   node := LowerBoundNode(aitem, FBinaryTree.RootNode);
   iter1 := TBinarySearchTreeBaseIterator.Create(node, self);

   while (node <> nil) and (_mcp_equal(aitem, node^.Item)) do
      node := NextInOrderNode(node);

   iter2 := TBinarySearchTreeBaseIterator.Create(node, self);
   Result := TSetIteratorRange.Create(iter1, iter2);
end;

procedure TBinarySearchTreeBase.Clear;
begin
   FBinaryTree.Clear;
   GrabageCollector.FreeObjects;
end;

function TBinarySearchTreeBase.Empty : Boolean;
begin
   Result := FBinaryTree.RootNode = nil;
end;

function TBinarySearchTreeBase.Size : SizeType;
begin
   Result := FBinaryTree.Size;
end;

{ -------------------- TBinarySearchTreeBaseIterator ------------------------- }

constructor TBinarySearchTreeBaseIterator.Create(anode : PBinaryTreeNode;
                                                 tree : TBinarySearchTreeBase);
begin
   inherited Create(tree);
   FTree := tree;
   Node := anode;
end;

procedure TBinarySearchTreeBaseIterator.GoToStartNode;
begin
   Node := FirstInOrderNode(FTree.BinaryTree.RootNode);
end;

function TBinarySearchTreeBaseIterator.CopySelf : TIterator;
begin
   Result := TBinarySearchTreeBaseIterator.Create(Node, FTree);
end;

function TBinarySearchTreeBaseIterator.Equal(const Pos : TIterator) : Boolean;
begin
   Assert(pos is TBinarySearchTreeBaseIterator, msgInvalidIterator);

   Result := TBinarySearchTreeBaseIterator(pos).Node = Node;
end;

function TBinarySearchTreeBaseIterator.GetItem : ItemType;
begin
   Assert(node <> nil, msgInvalidIterator);

   Result := Node^.Item;
end;

procedure TBinarySearchTreeBaseIterator.SetItem(aitem : ItemType);
begin
   Assert(Node <> nil, msgInvalidIterator);

   with FTree do
   begin
      if _mcp_equal(Node^.Item, aitem) then
      begin
         DisposeItem(Node^.Item);
         Node^.Item := aitem;
      end else
      begin
         DisposeItem(Node^.Item);
         Node^.Item := aitem;
         ResetItem;
      end;
   end;
end;

procedure TBinarySearchTreeBaseIterator.ResetItem;
var
   aitem : ItemType;
begin
   Assert(Node <> nil, msgInvalidIterator);
   aitem := Node^.Item;
   FTree.BinaryTree.ExtractNodeInOrder(FNode, false);
   Node := FTree.InsertNode(aitem, FTree.BinaryTree.RootNode);
   Assert(Node <> nil, msgChangedRepeatedItems);
end;

procedure TBinarySearchTreeBaseIterator.Advance;
begin
   Assert(Node <> nil, msgInvalidIterator);

   Node := NextInOrderNode(Node);
end;

procedure TBinarySearchTreeBaseIterator.Retreat;
begin
   Node := PrevInOrderNode(Node, FTree.BinaryTree.RootNode);
end;

procedure TBinarySearchTreeBaseIterator.Insert(aitem : ItemType);
begin
   Node := FTree.InsertNode(aitem, FTree.BinaryTree.RootNode);
end;

function TBinarySearchTreeBaseIterator.Extract : ItemType;
begin
   Assert(Node <> nil, msgDeletingInvalidIterator);

   Result := node^.Item;
   FTree.BinaryTree.ExtractNodeInOrder(FNode, true);
end;

function TBinarySearchTreeBaseIterator.IsStart : Boolean;
begin
   if Node <> nil then
   begin
      Result := (Node^.LeftChild = nil) and
         (FirstInOrderNode(FTree.BinaryTree.RootNode) = Node);
   end else
   begin
      Result := FTree.BinaryTree.RootNode = nil;
   end;
end;

function TBinarySearchTreeBaseIterator.IsFinish : Boolean;
begin
   Result := Node = nil;
end;

function TBinarySearchTreeBaseIterator.Owner : TContainerAdt;
begin
   Result := FTree;
end;

{ ------------------------- TBinarySearchTree ------------------------------ }

constructor TBinarySearchTree.Create;
begin
   inherited Create;
end;

constructor TBinarySearchTree.CreateCopy(const cont : TBinarySearchTree;
                                         const itemCopier : IUnaryFunctor);
begin
   inherited CreateCopy(cont, itemCopier);
end;

function TBinarySearchTree.CopySelf(const ItemCopier :
                                       IUnaryFunctor) : TContainerAdt;
begin
   Result := TBinarySearchTree.CreateCopy(self, ItemCopier);
end;

procedure TBinarySearchTree.Swap(cont : TContainerAdt);
begin
   if cont is TBinarySearchTree then
   begin
      BasicSwap(cont);
      ExchangePtr(FBinaryTree, TBinarySearchTree(cont).FBinaryTree);
   end else
      inherited;
end;

function TBinarySearchTree.Delete(aitem : ItemType) : SizeType;
var
   node, temp : PBinaryTreeNode;
begin
   Result := 0;
   node := FindNode(aitem, FBinaryTree.RootNode, temp);
   while (node <> nil) and (_mcp_equal(aitem, node^.Item)) do
   begin
      DisposeItem(node^.Item);
      BinaryTree.ExtractNodeInOrder(node, true);
      Inc(Result);
   end;
end;

procedure TBinarySearchTree.Delete(pos : TSetIterator);
var
   node : PBinaryTreeNode;
begin
   Assert(pos is TBinarySearchTreeBaseIterator, msgInvalidIterator);

   node := TBinarySearchTreeBaseIterator(pos).Node;
   DisposeItem(node^.Item);
   BinaryTree.ExtractNodeInOrder(node, true);
   TBinarySearchTreeBaseIterator(pos).Node := node;
end;
