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
 adtbintree_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtbintree.defs
&include adtbintree_impl.mcp

{ ---------------------------- Helper routines ------------------------------- }

function LeftMostLeafNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Result := subtree;
   while subtree <> nil do
   begin
      Result := subtree;
      subtree := Result^.LeftChild;
      if subtree = nil then
         subtree := Result^.RightChild;
   end;
end;

function RightMostLeafNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Result := subtree;   
   while subtree <> nil do
   begin
      Result := subtree;
      subtree := Result^.RightChild;
      if subtree = nil then
         subtree := Result^.LeftChild;
   end;
end;


{ returns the node which is visited first in in-order traversal; it's
  the node whose all ancestors are left children of their parents
  (except for the root). }
function FirstInOrderNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Result := subtree;
   
   if Result <> nil then
      while Result^.LeftChild <> nil do
         Result := Result^.LeftChild;
end;

{ returns the node which is visited last in in-order traversal; it's
  the node whose all ancestors are right children of their parents
  (except for the root). }
function LastInOrderNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Result := subtree;
   
   if Result <> nil then
      while Result^.RightChild <> nil do
         Result := Result^.RightChild;
end;

function NextPreOrderNode(node : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   if node^.LeftChild <> nil then
      node := node^.LeftChild
   else if node^.RightChild <> nil then
      node := node^.RightChild
   else
   begin
      while (node^.Parent <> nil) and
         ((node^.Parent^.RightChild = node) or (node^.Parent^.RightChild = nil)) do
      begin
         node := node^.Parent;
      end;
      node := node^.Parent;
      if node <> nil then
         node := node^.RightChild;
   end;
   Result := node;
end;

function NextPostOrderNode(node : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   if node^.Parent = nil then
      node := nil
   else if node^.Parent^.LeftChild = node then
   begin
      if node^.Parent^.RightChild <> nil then
      begin
         node := LeftMostLeafNode(node^.Parent^.RightChild);
      end else
         node := node^.Parent;
   end else
      node := node^.Parent;
   Result := node;
end;

function NextInOrderNode(node : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   if node^.RightChild <> nil then
   begin
      node := FirstInOrderNode(node^.RightChild);
   end else { node is the right child of its parent }
   begin
      { go to the ancestor node that has not yet been visited; this is the
         node whose right child has not yet been visited }
      while (node^.Parent <> nil) and (node^.Parent^.LeftChild <> node) do
      begin
         node := node^.Parent;
      end;
      node := node^.Parent;
   end;
   Result := node;
end;

function PrevPreOrderNode(node, root : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Assert(root <> nil, msgRetreatingStartIterator);
   Assert(node <> root, msgRetreatingStartIterator);
   
   if node <> nil then
   begin
      if node^.Parent^.LeftChild <> node then
         Result := RightMostLeafNode(node^.Parent^.LeftChild)
      else begin
         Result := node^.Parent;
      end;
   end else
      Result := RightMostLeafNode(root);
end;

function PrevPostOrderNode(node, root : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Assert(root <> nil, msgRetreatingStartIterator);
   
   if node <> nil then
   begin
      if node^.RightChild <> nil then
         Result := node^.RightChild
      else if node^.LeftChild <> nil then
         Result := node^.LeftChild
      else begin
         while (node^.Parent <> nil) and
                  ((node^.Parent^.LeftChild = node) or
                      (node^.Parent^.LeftChild = nil)) do
         begin
            node := node^.Parent;
         end;
         Assert(node^.Parent <> nil, msgRetreatingStartIterator);
         Result := node^.Parent^.LeftChild;
      end;
   end else
      Result := root;
end;

function PrevInOrderNode(node, root : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Assert(root <> nil, msgRetreatingStartIterator);
   
   if node <> nil then
   begin
      if node^.LeftChild <> nil then
         Result := LastInOrderNode(node^.LeftChild)
      else begin
         while (node^.Parent <> nil) and (node^.Parent^.LeftChild = node) do
         begin
            node := node^.Parent;
         end;
         Result := node^.Parent;
         Assert(Result <> nil, msgRetreatingStartIterator);
      end;
   end else
      Result := LastInOrderNode(root);
end;

function NodeDepth(node : PBinaryTreeNode) : SizeType;
begin
   Result := 0;
   while node^.Parent <> nil do
   begin
      Inc(Result);
      node := node^.Parent;
   end;
end;

function NodeHeight(node : PBinaryTreeNode) : SizeType;
begin
   Result := 0;
   if node^.LeftChild <> nil then
      Result := NodeHeight(node^.leftchild) + 1;
   if node^.RightChild <> nil then
      Result := Max(Result, NodeHeight(node^.RightChild) + 1);
end;

{ inserts node at the left of parent and shifts parent left, i.e. if
  parent has three children after insertion, takes the right-most one
  and calls itself recursively for the next node after parent in
  level-order; queue is modified and deallocated; it should contain
  nodes as if parent has just been visited }
procedure InsertLeftAndShiftBy1(parent, node : PBinaryTreeNode;
                                var queue : TPointerDynamicArray);
begin
   try
      try
         repeat
            node^.Parent := parent;
            if parent^.LeftChild = nil then
            begin
               parent^.LeftChild := node;
               break;
            end else if parent^.RightChild = nil then
            begin
               parent^.RightChild := parent^.LeftChild;
               parent^.LeftChild := node;
               break;
            end else
            begin
               ArrayCircularPushBack(queue, node); { may raise  }
               ArrayCircularPushBack(queue, parent^.LeftChild); { may raise }
               parent^.LeftChild := node;
               node := parent^.RightChild;
               parent^.RightChild := ArrayCircularGetItem(queue, queue^.Size - 1);
               parent := ArrayCircularPopFront(queue);
            end;
         until false;
      except
         { save what you can - insert node somewhere in order not to
           leak it, no matter where }
         while parent^.LeftChild <> nil do
            parent := parent^.LeftChild;
         parent^.LeftChild := node;
         node^.Parent := parent;
         
         raise;
      end;
   finally
      ArrayDeallocate(queue);
   end;
end;

{ the same as above, but inserts two nodes }
procedure InsertLeftAndShiftBy2(parent, node1, node2 : PBinaryTreeNode;
                                queue : TPointerDynamicArray);
begin
   try
      try
         repeat
            node1^.Parent := parent;
            node2^.Parent := parent;
            if (parent^.LeftChild = nil) and (parent^.RightChild = nil) then
            begin
               parent^.LeftChild := node1;
               parent^.RightChild := node2;
               break;
            end else if (parent^.LeftChild = nil) then
            begin
               parent^.LeftChild := node1;
               node1 := parent^.RightChild;
               parent^.RightChild := node2;
               
               ArrayCircularPushBack(queue, parent^.LeftChild);
               ArrayCircularPushBack(queue, parent^.RightChild);

               parent := ArrayCircularPopFront(queue);
               InsertLeftAndShiftBy1(parent, node1, queue);
               queue := nil;
               break;
            end else if (parent^.RightChild = nil) then
            begin
               parent^.RightChild := node2;
               node2 := parent^.RightChild;
               parent^.LeftChild := node1;
               
               ArrayCircularPushBack(queue, parent^.LeftChild);
               ArrayCircularPushBack(queue, parent^.RightChild);
               
               parent := ArrayCircularPopFront(queue);
               InsertLeftAndShiftBy1(parent, node2, queue);
               queue := nil;
               break;
            end else
            begin
               ArrayCircularPushBack(queue, node1);
               ArrayCircularPushBack(queue, node2);
               node1 := parent^.LeftChild;
               node2 := parent^.RightChild;
               parent^.LeftChild := ArrayCircularGetItem(queue, queue^.Size - 2);
               parent^.RightChild := ArrayCircularGetItem(queue, queue^.Size - 1);
               parent := ArrayCircularPopFront(queue);
            end;
         until false;
      except
         { insert node1 and node2 somewhere in order not to leak them }
         while parent^.LeftChild <> nil do
            parent := parent^.LeftChild;
         parent^.LeftChild := node1;
         node1^.Parent := parent;
         while parent^.LeftChild <> nil do
            parent := parent^.LeftChild;
         node1^.Parent := nil;
         
         raise;
      end;
   finally
      ArrayDeallocate(queue);
   end;
end;


{ **************************************************************************** }
{                                Binary tree                                   }
{ **************************************************************************** }
(* Notes on implementation of TBinaryTree:
 *  TBinaryTree is a binary tree implemented as linked nodes. Each node has
 * a pointer to its Parent, left child (LeftChild) and right child (RightChild).
 * If some of them is not present the appropriate pointer is nil. The number of
 * Items is stored in FSize field, so that the Size operation takes an amortized
 * O(1) time.
 *
 *)

{ ------------------------------ TBinaryTree --------------------------------- }

constructor TBinaryTree.Create;
begin
   inherited;
   InitFields;
end;

constructor TBinaryTree.CreateCopy(const cont : TBinaryTree;
                                   const itemCopier : IUnaryFunctor);
var
   src, destparent : PBinaryTreeNode;
   pdest : ^PBinaryTreeNode;
begin
   inherited CreateCopy(cont);
   InitFields;
   
   if itemCopier <> nil then
   begin
      { copy nodes while going pre-order }
      
      src := cont.FRoot;
      pdest := @FRoot;
      destparent := nil;
      
      try
         repeat
            NewNode(pdest^);
            with pdest^^ do
            begin
               Item := itemCopier.Perform(src^.Item); { may raise }
               Parent := destparent;
               LeftChild := nil;
               RightChild := nil;
            end;
            Inc(FSize);
            
            if src^.LeftChild <> nil then
            begin
               destparent := pdest^;
               pdest := @pdest^^.LeftChild;
               src := src^.LeftChild;
            end else if src^.RightChild <> nil then
            begin
               destparent := pdest^;
               pdest := @pdest^^.RightChild;
               src := src^.RightChild;
            end else
            begin
               while (src^.Parent <> nil) and
                        ((src^.Parent^.RightChild = src) or
                            (src^.Parent^.RightChild = nil)) do
               begin
                  src := src^.Parent;
                  pdest := @pdest^^.Parent;
                  destparent := destparent^.Parent;
               end;
               
               if src^.Parent = nil then
               begin
                  break;
               end else
               begin
                  src := src^.Parent^.RightChild;
                  pdest := @destparent^.RightChild;
               end;
            end;
            
         until false;
         
      except
         DisposeNode(pdest^);
         pdest^ := nil;
         raise;
      end;
      
      cont.FSize := FSize;
      cont.FValidSize := true;
   end; { end itemCopier <> nil }
end; { end CreateCopy }

destructor TBinaryTree.Destroy;
begin
   Clear;
   inherited;
end;

procedure TBinaryTree.InitFields;
begin
   FRoot := nil;
   FSize := 0;
   FValidSize := true;
end;

procedure TBinaryTree.DisposeNodeAndItem(node : PBinaryTreeNode);
begin
   DisposeItem(node^.Item);
   DisposeNode(node);
end;

procedure TBinaryTree.ReplaceNode(old, pnewnode : PBinaryTreeNode);
begin
   Assert(old <> nil, msgInternalError);
   
   if old^.Parent <> nil then
   begin
      if old^.Parent^.LeftChild = old then
         old^.Parent^.LeftChild := pnewnode
      else
         old^.Parent^.RightChild := pnewnode;
      
      if pnewnode <> nil then
         pnewnode^.Parent := old^.Parent;
      
   end else
   begin
      FRoot := pnewnode;
      
      if pnewnode <> nil then
         pnewnode^.Parent := nil;
   end;
end;

{ this cannot manipulate FSize or FValidSize as they are changed later }
procedure TBinaryTree.RemoveConnections(node : PBinaryTreeNode);
begin
   Assert(node <> nil, msgInternalError);

   if node^.Parent = nil then
   begin
      FRoot := nil;
   end else if node^.Parent^.LeftChild = node then
   begin
      node^.Parent^.LeftChild := nil;
   end else { node^.Parent^.RightChild = node }
   begin
      node^.Parent^.RightChild := nil;
   end;
end;

function TBinaryTree.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TBinaryTree.CreateCopy(self, ItemCopier);   
end;

procedure TBinaryTree.Swap(cont : TContainerAdt);
var
   tree : TBinaryTree;
begin
   if cont is TBinaryTree then
   begin
      BasicSwap(cont);
      tree := TBinaryTree(cont);
      ExchangePtr(FRoot, tree.FRoot);
      ExchangeData(FSize, tree.FSize, SizeOf(SizeType));
      ExchangeData(FValidSize, tree.FValidSize, SizeOf(Boolean));
   end else
      inherited;
end;

function TBinaryTree.Root : TBinaryTreeIterator;
begin
   Result := TBinaryTreeIterator.Create(FRoot, self);
end;

function TBinaryTree.BasicRoot : TBasicTreeIterator;
begin
   Result := TBinaryTreeIterator.Create(FRoot, self);
end;

function TBinaryTree.Finish : TBasicTreeIterator;
begin
   Result := TBinaryTreeIterator.Create(nil, self);
end;

function TBinaryTree.PreOrderIterator : TPreOrderIterator;
begin
   Result := TBinaryTreePreOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TBinaryTree.PostOrderIterator : TPostOrderIterator;
begin
   Result := TBinaryTreePostOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TBinaryTree.InOrderIterator : TInOrderIterator;
begin
   Result := TBinaryTreeInOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TBinaryTree.LevelOrderIterator : TLevelOrderIterator;
begin
   Result := TBinaryTreeLevelOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TBinaryTree.DeleteSubTree(node : TBasicTreeIterator) : SizeType;
var
   xnode : PBinaryTreeNode;
begin
   Assert(node is TBinaryTreeIterator, msgDeletingInvalidIterator);
   Assert(node.Owner = self, msgWrongOwner);
   Assert(TBinaryTreeIterator(node).Node <> nil, msgInvalidIterator);

   xnode := TBinaryTreeIterator(node).Node;
   Result := NodeSubTreeDelete(xnode);
end;

procedure TBinaryTree.InsertAsRoot(aitem : ItemType);
var
   temp : PBinaryTreeNode;
begin
   NewNode(temp);
   temp^.LeftChild := FRoot;
   if FRoot <> nil then
      FRoot^.Parent := temp;
   FRoot := temp;
   temp^.Parent := nil;
   temp^.RightChild := nil;
   temp^.Item := aitem;
   
   Inc(FSize);
end;

procedure TBinaryTree.InsertAsLeftChild(const node : TBasicTreeIterator;
                                        aitem : ItemType);
var
   xnode, pnewnode : PBinaryTreeNode;
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   Assert(node.Owner = self, msgWrongOwner);

   xnode := TBinaryTreeIterator(node).Node;
   NewNode(pnewnode);
   pnewnode^.Item := aitem;
   pnewnode^.LeftChild := xnode^.LeftChild;
   xnode^.LeftChild := pnewnode;
   pnewnode^.RightChild := nil;
   pnewnode^.Parent := xnode;
   Inc(FSize);
end;

procedure TBinaryTree.InsertAsRightChild(const node : TBasicTreeIterator;
                                         aitem : ItemType);
var
   xnode, pnewnode : PBinaryTreeNode;
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   Assert(node.Owner = self, msgWrongOwner);

   xnode := TBinaryTreeIterator(node).Node;
   NewNode(pnewnode);
   pnewnode^.Item := aitem;
   pnewnode^.RightChild := xnode^.RightChild;
   xnode^.RightChild := pnewnode;
   pnewnode^.LeftChild := nil;
   pnewnode^.Parent := xnode;
   Inc(FSize);
end;

procedure TBinaryTree.MoveToLeftChild(const node, src : TBasicTreeIterator);
var
   dest, source : PBinaryTreeNode;
   tree2 : TBinaryTree;
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   Assert(src is TBinaryTreeIterator, msgInvalidIterator);
   Assert(TBinaryTreeIterator(node).Node <> nil, msgInvalidIterator);
   Assert(TBinaryTreeIterator(src).Node <> nil, msgInvalidIterator);
   Assert(TBinaryTreeIterator(node).Node^.LeftChild = nil, msgHasLeftChild);
   Assert(node.Owner = self, msgWrongOwner);
   
   dest := TBinaryTreeIterator(node).Node;
   source := TBinaryTreeIterator(src).Node;
   tree2 := TBinaryTreeIterator(src).FTree;
   
   if (source^.RightChild = nil) and (source^.LeftChild = nil) then
   begin
      Inc(FSize);
      Dec(tree2.FSize);
   end else if source^.Parent = nil then
   begin
      FSize := FSize + tree2.FSize;
      FValidSize := FValidSize and tree2.FValidSize;
      tree2.FSize := 0;
      tree2.FValidSize := true;
      tree2.FRoot := nil;
   end else if tree2 <> self then
   begin
      FValidSize := false;
      tree2.FValidSize := false;
   end;
   
   tree2.RemoveConnections(source);
   
   dest^.LeftChild := source;
   source^.Parent := dest;
end;

procedure TBinaryTree.MoveToRightChild(const node, src : TBasicTreeIterator);
var
   dest, source : PBinaryTreeNode;
   tree2 : TBinaryTree;
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   Assert(src is TBinaryTreeIterator, msgInvalidIterator);
   Assert(TBinaryTreeIterator(node).Node <> nil, msgInvalidIterator);
   Assert(TBinaryTreeIterator(src).Node <> nil, msgInvalidIterator);
   Assert(TBinaryTreeIterator(node).Node^.RightChild = nil, msgHasRightChild);
   Assert(node.Owner = self, msgWrongOwner);
   
   dest := TBinaryTreeIterator(node).Node;
   source := TBinaryTreeIterator(src).Node;
   tree2 := TBinaryTreeIterator(src).FTree;
   
   if (source^.RightChild = nil) and (source^.LeftChild = nil) then
   begin
      Inc(FSize);
      Dec(tree2.FSize);
   end else if source^.Parent = nil then
   begin
      FSize := FSize + tree2.FSize;
      FValidSize := FValidSize and tree2.FValidSize;
      tree2.FSize := 0;
      tree2.FValidSize := true;
      tree2.FRoot := nil;
   end else if tree2 <> self then
   begin
      FValidSize := false;
      tree2.FValidSize := false;
   end;
   
   tree2.RemoveConnections(source);
   
   dest^.RightChild := source;
   source^.Parent := dest;
end;

procedure TBinaryTree.RotateSingleLeft(const node : TBasicTreeIterator);
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   
   RotateNodeSingleLeft(TBinaryTreeIterator(node).Node);
end;

procedure TBinaryTree.RotateDoubleLeft(const node : TBasicTreeIterator);
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   
   RotateNodeDoubleLeft(TBinaryTreeIterator(node).Node);
end;

procedure TBinaryTree.RotateSingleRight(const node : TBasicTreeIterator);
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   
   RotateNodeSingleRight(TBinaryTreeIterator(node).Node);
end;

procedure TBinaryTree.RotateDoubleRight(const node : TBasicTreeIterator);
begin
   Assert(node is TBinaryTreeIterator, msgInvalidIterator);
   
   RotateNodeDoubleRight(TBinaryTreeIterator(node).Node);
end;

procedure TBinaryTree.Clear;
begin
   if FRoot <> nil then
   begin
      NodeSubTreeDelete(FRoot);
      FRoot := nil;
   end;
   FSize := 0;
   FValidSize := true;
   
   GrabageCollector.FreeObjects;
end;

function TBinaryTree.Empty : Boolean;
begin
   Result := (FRoot = nil);
end;

function TBinaryTree.Size : SizeType;
begin
   if not FValidSize then
   begin
      FSize := NodeSubTreeSize(FRoot);
      FValidSize := true;
   end;
   Result := FSize;
end;

function TBinaryTree.IsDefinedOrder : Boolean;
begin
   Result := false;
end;

procedure TBinaryTree.InsertNode(var node : PBinaryTreeNode;
                                 parent : PBinaryTreeNode; aitem : ItemType);
begin
   NewNode(node);
   node^.Parent := parent;
   with node^ do
   begin
      LeftChild := nil;
      RightChild := nil;
      Item := aitem;
   end;
   Inc(FSize);
end;

function TBinaryTree.
   ReplaceNodeWithLeftChild(node : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Result := node^.RightChild;
   ReplaceNode(node, node^.LeftChild);
   DisposeNode(node);
   Dec(FSize);
end;

function TBinaryTree.
   ReplaceNodeWithRightChild(node : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Result := node^.LeftChild;
   ReplaceNode(node, node^.RightChild);
   DisposeNode(node);
   Dec(FSize);
end;

function TBinaryTree.ExtractNodePreOrder(var node : PBinaryTreeNode;
                                         fadvance : Boolean) : PBinaryTreeNode;
var
   lleaf, next : PBinaryTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);
   
   if (node^.RightChild = nil) then
   begin
      ReplaceNode(node, node^.LeftChild);
      next := node;
      node := node^.LeftChild;
      if fadvance and (node = nil) then
         node := NextPreOrderNode(next);
      Result := next^.Parent;
      DisposeNode(next);
   end else if node^.LeftChild = nil then
   begin
      ReplaceNode(node, node^.RightChild);
      next := node;
      node := node^.RightChild;
      Result := next^.Parent;
      DisposeNode(next);
   end else { node has both children }
   begin
      { 'shift' items up on the path from node to the left-most leaf
        in the sub-tree of node - nodes on this path are visited first
        starting from node, so we can shift them up without changing
        pre-order of nodes; }
      lleaf := node;
      next := node;
      while next <> nil do
      begin
         lleaf^.Item := next^.Item;
         lleaf := next;
         next := next^.LeftChild;
         if next = nil then
            next := lleaf^.RightChild;
      end;
      
      Result := lleaf^.Parent;            
      RemoveConnections(lleaf);
      DisposeNode(lleaf);
   end;
   Dec(FSize);
end;

function TBinaryTree.ExtractNodePostOrder(var node : PBinaryTreeNode;
                                          fadvance : Boolean) : PBinaryTreeNode;
var
   rleaf, next : PBinaryTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   if (node^.LeftChild = nil) or (node^.RightChild = nil) then
   begin
      if fadvance then
         next := NextPostOrderNode(node)
      else
         next := nil;
      
      if node^.LeftChild = nil then
         ReplaceNode(node, node^.RightChild)
      else
         ReplaceNode(node, node^.LeftChild);

      Result := node^.Parent;
      DisposeNode(node);
   end else { node has both children }
   begin
      next := node;
      { shift items up on the path from node to the right-most leaf in
        the sub-tree of node; this path is visited last in post-order }
      rleaf := node;
      while node <> nil do
      begin
         rleaf^.Item := node^.Item;
         rleaf := node;
         node := node^.RightChild;
         if node = nil then
            node := rleaf^.LeftChild;
      end;
      
      Result := rleaf^.Parent;
      RemoveConnections(rleaf);
      DisposeNode(rleaf);
   end;
   node := next;
   Dec(FSize);
end;

function TBinaryTree.ExtractNodeInOrder(var node : PBinaryTreeNode;
                                        fadvance : Boolean) : PBinaryTreeNode;
var
   dummy : Boolean;
begin
   Result := ExtractNodeInOrderAux(node, fadvance, dummy);
end;

function TBinaryTree.
   ExtractNodeInOrderAux(var node : PBinaryTreeNode; fadvance : Boolean;
                         var isLeftChild : Boolean) : PBinaryTreeNode;
var
   nnode : PBinaryTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);
   
   if (node^.RightChild <> nil) and (node^.LeftChild <> nil) then
   begin
      { 'toss a coin' and either replace node with the next item after
        it or the previous one; this is to keep the binary tree random
        when used to implement binary search tree }
      if Random(2) = 0 then
      begin
         { replace with the next item }
         
         nnode := FirstInOrderNode(node^.RightChild);
         
         if nnode^.Parent^.LeftChild = nnode then
         begin
            isLeftChild := true;
            nnode^.Parent^.LeftChild := nnode^.RightChild
         end else { will happen when nnode = node^.RightChild }
         begin
            isLeftChild := false;
            nnode^.Parent^.RightChild := nnode^.RightChild;
         end;
         
         if nnode^.RightChild <> nil then
            nnode^.RightChild^.Parent := nnode^.Parent;
         
         node^.Item := nnode^.Item;
         Result := nnode^.Parent;
         DisposeNode(nnode);
      end else
      begin
         { replace with the previous item }
         
         nnode := LastInOrderNode(node^.LeftChild);
         
         if nnode^.Parent^.RightChild = nnode then
         begin
            isLeftChild := false;
            nnode^.Parent^.RightChild := nnode^.LeftChild;
         end else
         begin
            isLeftChild := true;
            nnode^.Parent^.LeftChild := nnode^.LeftChild;
         end;
         
         if nnode^.LeftChild <> nil then
            nnode^.LeftChild^.Parent := nnode^.Parent;
         
         node^.Item := nnode^.Item;
         
         if fadvance then
            node := FirstInOrderNode(node^.RightChild)
         else
            node := nil;
         
         Result := nnode^.Parent;
         DisposeNode(nnode);
      end;
   end else
   begin
      if fadvance then
         nnode := NextInOrderNode(node)
      else
         nnode := nil;
      
      Result := node^.Parent;
      isLeftChild := (node^.Parent <> nil) and (node^.Parent^.LeftChild = node);
      
      if node^.RightChild <> nil then
         ReplaceNode(node, node^.RightChild)
      else
         ReplaceNode(node, node^.LeftChild);
      
      DisposeNode(node);
      node := nnode;
   end;
   Dec(FSize);
end;

procedure TBinaryTree.RotateNodeSingleLeft(node : PBinaryTreeNode);
var
   parent, rchild : PBinaryTreeNode;
begin
   Assert((node <> nil) and (node^.RightChild <> nil),
          msgInvalidNodeForSingleLeftRotation);
   
   parent := node^.Parent;
   rchild := node^.RightChild;
   
   node^.RightChild := rchild^.LeftChild;
   if rchild^.LeftChild <> nil then
      rchild^.LeftChild^.Parent := node;
   
   rchild^.LeftChild := node;
   node^.Parent := rchild;
   
   rchild^.Parent := parent;
   if parent <> nil then
   begin
      if parent^.LeftChild = node then
         parent^.LeftChild := rchild
      else
         parent^.RightChild := rchild;
   end else
   begin
      FRoot := rchild;
   end;
end;

procedure TBinaryTree.RotateNodeDoubleLeft(node : PBinaryTreeNode);
var
   parent, rchild, t : PBinaryTreeNode;
begin
   Assert((node <> nil) and (node^.RightChild <> nil) and
             (node^.RightChild^.LeftChild <> nil),
          msgInvalidNodeForDoubleLeftRotation);
   
   parent := node^.Parent;
   rchild := node^.RightChild;
   t := rchild^.LeftChild;
   
   node^.RightChild := t^.LeftChild;
   if t^.LeftChild <> nil then
      t^.LeftChild^.Parent := node;
   
   rchild^.LeftChild := t^.RightChild;
   if t^.RightChild <> nil then
      t^.RightChild^.Parent := rchild;
   
   t^.LeftChild := node;
   t^.RightChild := rchild;
   node^.Parent := t;
   rchild^.Parent := t;
   
   t^.Parent := parent;
   if parent <> nil then
   begin
      if parent^.LeftChild = node then
         parent^.LeftChild := t
      else
         parent^.RightChild := t;
   end else
      FRoot := t;
end;

procedure TBinaryTree.RotateNodeSingleRight(node : PBinaryTreeNode);
var
   parent, lchild : PBinaryTreeNode;
begin
   Assert((node <> nil) and (node^.LeftChild <> nil),
          msgInvalidNodeForSingleRightRotation);
   
   parent := node^.Parent;
   lchild := node^.LeftChild;
   
   node^.LeftChild := lchild^.RightChild;
   if node^.LeftChild <> nil then
      node^.LeftChild^.Parent := node;
   
   lchild^.RightChild := node;
   node^.Parent := lchild;
   
   lchild^.Parent := parent;
   if parent <> nil then
   begin
      if parent^.LeftChild = node then
         parent^.LeftChild := lchild
      else
         parent^.RightChild := lchild;
   end else
      FRoot := lchild;
end;

procedure TBinaryTree.RotateNodeDoubleRight(node : PBinaryTreeNode);
var
   parent, lchild, t : PBinaryTreeNode;
begin
   Assert((node <> nil) and (node^.LeftChild <> nil) and
             (node^.LeftChild^.RightChild <> nil),
          msgInvalidNodeForDoubleRightRotation);
   
   parent := node^.Parent;
   lchild := node^.LeftChild;
   t := lchild^.RightChild;
   
   lchild^.RightChild := t^.LeftChild;
   if lchild^.RightChild <> nil then
      lchild^.RightChild^.Parent := lchild;
   
   node^.LeftChild := t^.RightChild;
   if node^.LeftChild <> nil then
      node^.LeftChild^.Parent := node;
   
   t^.LeftChild := lchild;
   t^.RightChild := node;
   lchild^.Parent := t;
   node^.Parent := t;
   
   t^.Parent := parent;
   if parent <> nil then
   begin
      if parent^.LeftChild = node then
         parent^.LeftChild := t
      else
         parent^.RightChild := t;
   end else
      FRoot := t;
end;

function TBinaryTree.NodeSubTreeDelete(node : PBinaryTreeNode) : SizeType;
var
   node2, nnode : PBinaryTreeNode;
begin
   RemoveConnections(node);
   Result := FSize;

   { delete nodes while moving post-order }

   node2 := LeftMostLeafNode(node);
   while node2 <> node do
   begin
      nnode := node2;
      if (nnode = nnode^.Parent^.RightChild) or
            (nnode^.Parent^.RightChild = nil) then
      begin
         nnode := nnode^.Parent;
      end else
      begin
         nnode := LeftMostLeafNode(nnode^.Parent^.RightChild);
      end;
      
      DisposeItem(node2^.Item);
      DisposeNode(node2);
      Dec(FSize);
      
      node2 := nnode;
   end;
   DisposeNodeAndItem(node);
   Dec(FSize);
   
   Result := Result - FSize;
end;

function TBinaryTree.NodeSubTreeSize(node : PBinaryTreeNode) : SizeType;
var
   node2 : PBinaryTreeNode;
begin
   if node <> nil then
   begin
      { count size while going pre-order }
      Result := 1; { the argument won't be visited again... }
      if node^.LeftChild <> nil then
         node2 := node^.LeftChild
      else if node^.RightChild <> nil then
         node2 := node^.RightChild
      else
         node2 := node;
      
      while node2 <> node do
      begin
         Inc(Result);
         if node2^.LeftChild <> nil then
         begin
            node2 := node2^.LeftChild;
         end else if node2^.RightChild <> nil then
         begin
            node2 := node2^.RightChild;
         end else
         begin
            while (node2 <> node) and ((node2^.Parent^.RightChild = node2) or
                                          (node2^.Parent^.RightChild = nil)) do
            begin
               node2 := node2^.Parent;
            end;
            if node2 <> node then
               node2 := node2^.Parent^.RightChild;
         end;
      end; { end while node2 <> node }
   end else { not node <> nil }
      Result := 0;
end;

procedure TBinaryTree.NewNode(var node : PBinaryTreeNode);
begin
   New(node);
end;

procedure TBinaryTree.DisposeNode(var node : PBinaryTreeNode);
begin
   Dispose(node);
end;

{ -------------------------- TBinaryTreeIterator ---------------------------- }

constructor TBinaryTreeIterator.Create(argnode : PBinaryTreeNode;
                                       tree : TBinaryTree);
begin
   inherited Create(tree);
   Node := argnode;
   FTree := tree;
end;

procedure TBinaryTreeIterator.GoToParent;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Node := Node^.Parent;
end;

procedure TBinaryTreeIterator.GoToLeftChild;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Node := NOde^.LeftChild;
end;

procedure TBinaryTreeIterator.GoToRightChild;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Node := NOde^.RightChild;
end;

procedure TBinaryTreeIterator.InsertAsLeftChild(aitem : ItemType);
begin
   FTree.InsertAsLeftChild(self, aitem);
   Node := Node^.LeftChild;
end;

procedure TBinaryTreeIterator.InsertAsRightChild(aitem : ItemType);
begin
   FTree.InsertAsRightChild(self, aitem);
   Node := Node^.RightChild;
end;

function TBinaryTreeIterator.CopySelf : TIterator;
begin
   Result := TBinaryTreeIterator.Create(Node, FTree);
end;

function TBinaryTreeIterator.GetItem : ItemType;
begin
   Assert(Node <> nil, msgDereferencingInvalidIterator);
   Result := Node^.Item;
end;

procedure TBinaryTreeIterator.SetItem(aitem : ItemType);
begin
   Assert(Node <> nil, msgDereferencingInvalidIterator);
   with FTree do
      DisposeItem(Node^.Item);
   Node^.Item := aitem;
end;

function TBinaryTreeIterator.Equal(const iter : TIterator) : Boolean;
begin
   Assert(iter is TBinaryTreeIterator, msgInvalidIterator);
   
   Result := (TBinaryTreeIterator(iter).Node = Node);
end;

procedure TBinaryTreeIterator.ExchangeItem(iter : TIterator);
begin
   if iter is TBinaryTreeIterator then
   begin
      ExchangePtr(TBinaryTreeIterator(iter).Node^.Item, Node^.Item);
   end else
      DoExchangeItem(iter);
end;

function TBinaryTreeIterator.DeleteSubTree : SizeType;
var
   parent : PBinaryTreeNode;
begin
   parent := Node^.Parent;
   Result := FTree.NodeSubTreeDelete(Node);
   Node := parent;
end;

function TBinaryTreeIterator.SubTreeSize : SizeType;
begin
   Result := FTree.NodeSubTreeSize(Node);
end;

function TBinaryTreeIterator.PreOrderIterator : TPreOrderIterator;
begin
   Result := TBinaryTreePreOrderIterator.Create(FTree);
   TBinaryTreePreOrderIterator(Result).Node := Node;
end;

function TBinaryTreeIterator.PostOrderIterator : TPostOrderIterator;
begin
   Result := TBinaryTreePostOrderIterator.Create(FTree);
   TBinaryTreePostOrderIterator(Result).Node := Node;
end;

function TBinaryTreeIterator.InOrderIterator : TInOrderIterator;
begin
   Result := TBinaryTreeInOrderIterator.Create(FTree);
   TBinaryTreeInOrderIterator(Result).Node := Node;
end;

function TBinaryTreeIterator.Owner : TContainerAdt;
begin
   Result := FTree;
end;

function TBinaryTreeIterator.IsLeaf : Boolean;
begin
   Result := (Node <> nil) and (Node^.LeftChild = nil) and
      (Node^.RightChild = nil);
end;

function TBinaryTreeIterator.IsRoot : Boolean;
begin
   Result := (Node = FTree.FRoot);
end;

function TBinaryTreeIterator.IsLeftChild : Boolean;
begin
   if (Node <> nil) and (Node^.Parent <> nil) then
      Result := node = Node^.Parent^.LeftChild
   else
      Result := false;
end;

function TBinaryTreeIterator.IsRightChild : Boolean;
begin
   if (Node <> nil) and (Node^.Parent <> nil) then
      Result := node = Node^.Parent^.RightChild
   else
      Result := false;
end;

function TBinaryTreeIterator.HasLeftChild : Boolean;
begin
   Result := (Node <> nil) and (Node^.LeftChild <> nil);
end;

function TBinaryTreeIterator.HasRightChild : Boolean;
begin
   Result := (Node <> nil) and (Node^.RightChild <> nil);
end;


{ ---------------------- TBinaryTreePreOrderIterator ----------------------- }

constructor TBinaryTreePreOrderIterator.Create(tree : TBinaryTree);
begin
   inherited Create(tree);
   FTree := tree;
end;

function TBinaryTreePreOrderIterator.CopySelf : TIterator;
begin
   Result := TBinaryTreePreOrderIterator.Create(FTree);
   TBinaryTreePreOrderIterator(Result).Node := Node;
end;

procedure TBinaryTreePreOrderIterator.StartTraversal;
begin
   Node := FTree.FRoot;
end;

procedure TBinaryTreePreOrderIterator.Advance;
begin
   Assert(node <> nil, msgInvalidIterator);
   
   node := NextPreOrderNode(node);
end;

procedure TBinaryTreePreOrderIterator.Retreat;
begin
   node := PrevPreOrderNode(node, FTree.FRoot);
end;

procedure TBinaryTreePreOrderIterator.Insert(aitem : ItemType);
var
   pnewnode : PBinaryTreeNode;
begin
   FTree.NewNode(pnewnode);
   pnewnode^.Item := aitem;
   pnewnode^.RightChild := nil;
   if Node <> nil then
      { insert as parent of Node and make Node a left child }
   begin
      FTree.ReplaceNode(Node, pnewnode);
      
      with pnewnode^ do
      begin
         Node^.Parent := pnewnode;
         LeftChild := Node;
      end;
   end else
      { insert as the last node - after all other nodes - as the
        right-most leaf }
   begin
      pnewnode^.LeftChild := nil;
      if FTree.FRoot <> nil then
      begin
         Node := RightMostLeafNode(FTree.FRoot);
         Node^.LeftChild := pnewnode;
         pnewnode^.Parent := Node;
      end else
      begin
         FTree.FRoot := pnewnode;
         pnewnode^.Parent := nil;
      end;
   end;
   
   Node := pnewnode;
   Inc(FTree.FSize);
end;

function TBinaryTreePreOrderIterator.Extract : ItemType;
begin
   Result := Node^.Item;
   FTree.ExtractNodePreOrder(Node, true);
end;

function TBinaryTreePreOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TBinaryTreeIterator.Create(Node, FTree);
end;

function TBinaryTreePreOrderIterator.IsStart : Boolean;
begin
   Result := (Node = FTree.FRoot);
end;

{ ---------------------- TBinaryTreePostOrderIterator ------------------------ }

constructor TBinaryTreePostOrderIterator.Create(tree : TBinaryTree);
begin
   inherited Create(tree);
   FTree := tree;
end;

function TBinaryTreePostOrderIterator.CopySelf : TIterator;
begin
   Result := TBinaryTreePostOrderIterator.Create(FTree);
   TBinaryTreePostOrderIterator(Result).Node := Node;
end;

procedure TBinaryTreePostOrderIterator.StartTraversal;
begin
   Node := LeftMostLeafNode(FTree.FRoot);
end;

procedure TBinaryTreePostOrderIterator.Advance;
begin
   node := NextPostOrderNode(node);
end;

procedure TBinaryTreePostOrderIterator.Retreat;
begin
   node := PrevPostOrderNode(node, FTree.FRoot);
end;

procedure TBinaryTreePostOrderIterator.Insert(aitem : ItemType);
var
   pnewnode : PBinaryTreeNode;
begin
   if Node <> nil then
      { insert as the left child of Node taking both children of Node }
   begin
      FTree.NewNode(pnewnode);
      pnewnode^.Item := aitem;
      with pnewnode^ do
      begin
         Parent := Node;
         LeftChild := Node^.LeftChild;
         RightChild := Node^.RightChild;
         if LeftChild <> nil then
            LeftChild^.Parent := pnewnode;
         if RightChild <> nil then
            RightChild^.Parent := pnewnode;
      end;
      Node^.LeftChild := pnewnode;
      Node^.RightChild := nil;
      
      Node := pnewnode;
      Inc(FTree.FSize);
   end else
      { insert as the last node - as the root }
   begin
      FTree.InsertAsRoot(aitem);
      Node := FTree.FRoot;
   end;
end;

function TBinaryTreePostOrderIterator.Extract : ItemType;
begin
   Result := Node^.Item;
   FTree.ExtractNodePostOrder(Node, true);
end;

function TBinaryTreePostOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TBinaryTreeIterator.Create(Node, FTree);
end;

function TBinaryTreePostOrderIterator.IsStart : Boolean;
begin
   if Node <> nil then
   begin
      Result := (Node^.LeftChild = nil) and (Node^.RightChild = nil) and
         (Node = LeftMostLeafNode(FTree.FRoot));
   end else
   begin
      Result := FTree.FRoot = nil;
   end;
end;

{ ------------------------- TBinaryTreeInOrderIterator ----------------------- }

constructor TBinaryTreeInOrderIterator.Create(tree : TBinaryTree);
begin
   inherited Create(tree);
   FTree := tree;
end;

function TBinaryTreeInOrderIterator.CopySelf : TIterator;
begin
   Result := TBinaryTreeInOrderIterator.Create(FTree);
   TBinaryTreeInOrderIterator(Result).Node := Node;
end;

procedure TBinaryTreeInOrderIterator.StartTraversal;
begin
   Node := FirstInOrderNode(FTree.FRoot);
end;

procedure TBinaryTreeInOrderIterator.Advance;
begin
   node := NextInOrderNode(node);
end;

procedure TBinaryTreeInOrderIterator.Retreat;
begin
   node := PrevInOrderNode(node, FTree.FRoot);
end;

procedure TBinaryTreeInOrderIterator.Insert(aitem : ItemType);
var
   pnewnode : PBinaryTreeNode;
begin
   FTree.NewNode(pnewnode);
   pnewnode^.Item := aitem;
   
   if Node <> nil then
      { make pnewnode the left child of Node and make Node's left child
        pnewnode's left child. }
   begin
      with pnewnode^ do
      begin
         LeftChild := Node^.LeftChild;
         RightChild := nil;
         Parent := Node;
         if LeftChild <> nil then
            LeftChild^.Parent := pnewnode;
      end;
      Node^.LeftChild := pnewnode;
   end else
   begin
      Node := LastInOrderNode(FTree.FRoot);
      if Node <> nil then
      begin
         Node^.RightChild := pnewnode;
         pnewnode^.Parent := Node;
      end else
         { insert as root }
      begin
         FTree.FRoot := pnewnode;
         pnewnode^.Parent := nil;
      end;
      pnewnode^.LeftChild := nil;
      pnewnode^.RightChild := nil;
   end;
   
   Node := pnewnode;
   Inc(FTree.FSize);
end;

function TBinaryTreeInOrderIterator.Extract : ItemType;
begin
   Result := Node^.Item;
   FTree.ExtractNodeInOrder(Node, true);
end;

function TBinaryTreeInOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TBinaryTreeIterator.Create(Node, FTree);
end;

function TBinaryTreeInOrderIterator.IsStart : Boolean;
begin
   if Node <> nil then
   begin
      Result := (Node^.LeftChild = nil) and
         (Node = FirstInOrderNode(FTree.FRoot));
   end else
   begin
      Result := FTree.FRoot = nil;
   end;
end;

{ ---------------------- TBinaryTreeLevelOrderIterator ----------------------- }

constructor TBinaryTreeLevelOrderIterator.Create(tree : TBinaryTree);
begin
   inherited Create(tree);
   FTree := tree;
   ArrayAllocate(queue, InitialQueueSize, 0);
end;

destructor TBinaryTreeLevelOrderIterator.Destroy;
begin
   ArrayDeallocate(queue);
   inherited;
end;

function TBinaryTreeLevelOrderIterator.CopySelf : TIterator;
var
   queue2 : TPointerDynamicArray;
begin
   queue2 := nil;
   Result := nil;
   try
      ArrayCopy(queue, queue2);
      Result := TBinaryTreeLevelOrderIterator.Create(FTree);
      TBinaryTreeLevelOrderIterator(Result).Node := Node;
      TBinaryTreeLevelOrderIterator(Result).queue := queue2;
   except
      ArrayDeallocate(queue2);
      Result.Free;
      raise;
   end;
end;

{ pushes children of Node at the back of the queue }
procedure TBinaryTreeLevelOrderIterator.PushChildren;
begin
   if Node <> nil then
   begin      
      try
         if Node^.LeftChild <> nil then
            ArrayCircularPushBack(queue, Node^.LeftChild);
         
         if Node^.RightChild <> nil then
            ArrayCircularPushBack(queue, Node^.RightChild);
      except
         if ArrayCircularGetItem(queue, queue^.Size - 1) = Node^.RightChild then
            Dec(queue^.Size);
         
         if ArrayCircularGetItem(queue, queue^.Size - 1) = Node^.LeftChild then
            Dec(queue^.Size);
         
         raise;
      end;
   end;
end;

procedure TBinaryTreeLevelOrderIterator.StartTraversal;
begin
   Node := FTree.FRoot;
   ArrayClear(queue, InitialQueueSize, 0);
end;

procedure TBinaryTreeLevelOrderIterator.Advance;
begin
   Assert(Node <> nil, msgAdvancingInvalidIterator);
   
   PushChildren;
   if queue^.Size <> 0 then
   begin
      Node := ArrayCircularPopFront(queue);
   end else
      Node := nil;
end;

procedure TBinaryTreeLevelOrderIterator.Retreat;
var
   nextNode : PBinaryTreeNode;
begin
   Assert(FTree.FRoot <> nil, msgRetreatingStartIterator);
   Assert(Node <> FTree.FRoot, msgRetreatingStartIterator);
   
   if Node <> nil then
   begin
      queue^.Size := 0;
      nextNode := Node;
      ArrayCircularPushBack(queue, FTree.FRoot);
      while ArrayCircularGetItem(queue, 0) <> nextNode do
      begin
         Node := ArrayCircularPopFront(queue);
         PushChildren;
      end;
      if ArrayCircularGetItem(queue, queue^.Size - 1) = Node^.RightChild then
         Dec(queue^.Size);
      if ArrayCircularGetItem(queue, queue^.Size - 1) = Node^.LeftChild then
         Dec(queue^.Size);
   end else
   begin { find the last node }
      queue^.Size := 0;
      Node := FTree.FRoot;
      PushChildren;
      while queue^.Size <> 0 do
      begin
         Node := ArrayCircularPopFront(queue);
         PushChildren;
      end;
   end;
end;

procedure TBinaryTreeLevelOrderIterator.Insert(aitem : ItemType);
var
   pnewnode, xnode, parent : PBinaryTreeNode;
   queue2 : TPointerDynamicArray;
   
   procedure PushChildrenLocal;
   begin
      if xnode^.LeftChild <> nil then
         ArrayCircularPushBack(queue, xnode^.LeftChild);
      if xnode^.RightChild <> nil then
         ArrayCircularPushBack(queue, xnode^.RightChild);
   end;

begin
   FTree.NewNode(pnewnode);
   pnewnode^.Item := aitem;
   with pnewnode^ do
   begin
      LeftChild := nil;
      RightChild := nil;
   end;
   
   if Node <> nil then
   begin
      if Node^.Parent <> nil then
         { insert as left sibling of Node and shift the parent of Node by 1 }
      begin
         parent := Node^.Parent;
         if (parent^.LeftChild = nil) then
         begin
            parent^.LeftChild := pnewnode;
            pnewnode^.Parent := parent;
         end else if parent^.RightChild = nil then
         begin
            parent^.RightChild := Node;
            parent^.LeftChild := pnewnode;
            pnewnode^.Parent := parent;
         end else
         begin
            queue2 := nil;
            try
               { we have to find parent's place in in-order
                 traversal (to know what is the next node after
                 parent) }
               ArrayClear(queue, InitialQueueSize, 0);
               xnode := FTree.FRoot;
               PushChildrenLocal;
               while (xnode <> parent) do
               begin
                  Assert(queue^.Size <> 0, msgInternalError);
                  
                  xnode := ArrayCircularPopFront(queue);
                  PushChildrenLocal;
               end;
               Dec(queue^.Size, 2); { we know that parent has 2 children }
               
               ArrayCircularPushBack(queue, pnewnode);
               ArrayCircularPushBack(queue, parent^.LeftChild);
               ArrayCopy(queue, queue2);
                  
               { insert pnewnode and make Node point to the one
                 excessive child of parent }
               
               if Node = parent^.LeftChild then
                  Node := parent^.RightChild;
               
               parent^.RightChild := parent^.LeftChild;
               parent^.LeftChild := pnewnode;
               pnewnode^.Parent := parent;
               
               try
                  { get the next node (next after parent) }
                  xnode := ArrayCircularPopFront(queue);
                  ArrayCircularPopFront(queue2);

                  { insert the one excessive node at the left of the
                    node after its parent and shift right }
                  InsertLeftAndShiftBy1(xnode, Node, queue2);
                  
                  { now find the new node }
                  while xnode <> pnewnode do
                  begin
                     xnode := ArrayCircularPopFront(queue);
                     PushChildrenLocal;
                  end;
                  { pnewnode may have one child if all nodes from
                    pnewnode to the position of its left child had both
                    children - we have to check and remove the child
                    of node from the queue }
                  xnode := ArrayCircularGetItem(queue, queue^.Size - 1);
                  if xnode^.Parent = pnewnode then
                     Dec(queue^.Size);
               except
                  { now, we cannot remove pnewnode from the tree, so
                    just increase the size }
                  Inc(FTree.FSize);
                  raise;
               end;
            except
               ArrayDeallocate(queue2);
               ArrayClear(queue, InitialQueueSize, 0);
               Node := nil;
               FTree.DisposeNode(pnewnode);
               raise;
            end;
         end;
      end else
         { insert as the root, make Node the left child of pnewnode }
      begin
         FTree.FRoot := pnewnode;
         with pnewnode^ do
         begin
            Parent := nil;
            RightChild := nil;
            LeftChild := Node;
         end;
         Node^.Parent := pnewnode;
      end;
   end else
      { insert as the last node }
   begin
      try
         StartTraversal;
         PushChildren; { may raise }
         while queue^.Size <> 0 do
         begin
            Node := ArrayCircularPopFront(queue);
            PushChildren; { may raise }
         end;
      except
         Node := nil;
         FTree.DisposeNode(pnewnode);
         ArrayClear(queue, InitialQueueSize, 0);
         raise;
      end;
      
      if Node <> nil then
         Node^.LeftChild := pnewnode
      else
         FTree.FRoot := pnewnode;
      pnewnode^.Parent := Node;
   end;
   
   Node := pnewnode;
   Inc(FTree.FSize);
end;

function TBinaryTreeLevelOrderIterator.Extract : ItemType;
var
   xnode, lchild, rchild : PBinaryTreeNode;
   queue2 : TPointerDynamicArray;
begin
   Assert(Node <> nil, msgInvalidIterator);
   
   xnode := Node;
   lchild := Node^.LeftChild;
   rchild := Node^.RightChild;
   
   FTree.RemoveConnections(xnode);
   
   if queue^.Size = 0 then
      PushChildren;
   
   if queue^.Size <> 0 then
   begin
      Node := ArrayCircularPopFront(queue);
      
      if (Node <> lchild) and (Node <> rchild) then
         { shift the next node right by 2 and make the children of the
           deleted node the children of the next node }
      begin
         queue2 := nil;
         if (lchild <> nil) or (rchild <> nil) then
            ArrayCopy(queue, queue2);
         
         if (lchild = nil) and (rchild <> nil) then
            InsertLeftAndShiftBy1(Node, rchild, queue2)
         else if (rchild = nil) and (lchild <> nil) then
            InsertLeftAndShiftBy1(Node, lchild, queue2)
         else if (lchild <> nil) and (rchild <> nil) then
            InsertLeftAndShiftBy2(Node, lchild, rchild, queue2);
         
      end else
         { there are no nodes on levels larger than that of the
           deleted node's children's and there are no nodes to the
           right of the deleted node at the same level }
      begin
         if (lchild <> nil) and (rchild <> nil) then
         begin
            queue2 := nil;
            ArrayAllocate(queue2, InitialQueueSize, 0);
            
            { replace the deleted node with its left child, make its
              right child left child's left child and shift left child
              right by 1 }
            queue^.Size := 0; { we have to clear the queue to avoid
                                visiting rchild twice later on }
            FTree.ReplaceNode(lchild^.Parent, lchild);
            InsertLeftAndShiftBy1(lchild, rchild, queue2);
            
         end else if (lchild <> nil) then
         begin
            FTree.ReplaceNode(lchild^.Parent, lchild);
         end else { rchild <> nil }
         begin
            FTree.ReplaceNode(rchild^.Parent, rchild);
         end;
      end;
   end else
      { the node to remove is the last node }
   begin
      Node := nil;
   end;
   
   Dec(FTree.FSize);
   Result := xnode^.Item;
   FTree.DisposeNode(xnode);
end;

function TBinaryTreeLevelOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TBinaryTreeIterator.Create(Node, FTree);
end;

function TBinaryTreeLevelOrderIterator.IsStart : Boolean;
begin
   Result := (Node = FTree.FRoot);
end;


{ --------------------------- routines ----------------------------------- }

function Parent(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
begin
   Assert((iter <> nil) and (iter.Node <> nil), msgInvalidIterator);
   
   if iter.Node^.Parent <> nil then
      Result := TBinaryTreeIterator.Create(iter.Node^.Parent, iter.FTree)
   else
      Result := nil;
end;

function RightChild(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
begin
   Assert((iter <> nil) and (iter.Node <> nil), msgInvalidIterator);
   
   if iter.Node^.RightChild <> nil then
      Result := TBinaryTreeIterator.Create(iter.Node^.RightChild, iter.FTree)
   else
      Result := nil;
end;

function LeftChild(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
begin
   Assert((iter <> nil) and (iter.Node <> nil), msgInvalidIterator);
   
   if iter.Node^.LeftChild <> nil then
      Result := TBinaryTreeIterator.Create(iter.Node^.LeftChild, iter.FTree)
   else
      Result := nil;
end;

function RightMostLeaf(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
begin
   Assert((iter <> nil) and (iter.Node <> nil), msgInvalidIterator);
   
   Result := TBinaryTreeIterator.Create(RightMostLeafNode(iter.Node), iter.FTree);
end;

function LeftMostLeaf(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
begin
   Assert((iter <> nil) and (iter.Node <> nil), msgInvalidIterator);
   
   Result := TBinaryTreeIterator.Create(LeftMostLeafNode(iter.Node), iter.FTree);
end;

function Depth(const iter : TBinaryTreeIterator) : SizeType;
begin
   Assert((iter <> nil) and (iter.Node <> nil), msgInvalidIterator);
   
   Result := NodeDepth(iter.Node);
end;

function Height(const iter : TBinaryTreeIterator) : SizeType;
begin
   Assert((iter <> nil) and (iter.Node <> nil), msgInvalidIterator);
   
   Result := NodeHeight(iter.Node);
end;

function CopyOf(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
begin
   Result := TBinaryTreeIterator(iter.CopySelf);
end;

