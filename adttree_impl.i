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
 adttree_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adttree.defs
&include adttree_impl.mcp

{ ---------------------- helper functions ---------------------------------- }

{ returns the right-most child of node; takes exactly O(n) time, where
  n is the number of children of node }
function RightMostChildNode(node : PTreeNode) : PTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   Result := node^.LeftmostChild;

   if Result <> nil then
      while (Result^.RightSibling <> nil) do
         Result := Result^.RightSibling;
end;

{ returns the left sibling (neighbour) of node or nil if node is the
  left-most child; @complexity O(ls), where ls is the number of left
  siblings of node }
function LeftSiblingNode(node : PTreeNode) : PTreeNode;
begin
   Result := nil;
   if (node^.Parent <> nil) and (node^.Parent^.LeftmostChild <> node) then
   begin
      Result := node^.Parent^.LeftmostChild;
      while Result^.RightSibling <> node do
         Result := Result^.RightSibling;
   end;
end;

{ Right-most leaf in a sub-tree is the node which is visited in
  pre-order traversal after all other nodes the sub-tree. This
  algorithm is worst-case O(n) time when all nodes are children of the
  root of the subtree or if every node has exactly one child; n is the
  number of nodes in the subtree. }
function RightMostLeafNode(subtree : PTreeNode) : PTreeNode;
begin
   if subtree <> nil then
   begin
      Result := RightMostChildNode(subtree);
      while Result <> nil do
      begin
         subtree := Result;
         Result := RightMostChildNode(subtree);
      end;
      Result := subtree;
   end else
      Result := nil;
end;

{ Left-most leaf in a sub-tree is the node that is visited in
  post-order and in-order traversals before any other node in the
  sub-tree. This is worst-case O(n) time when every node in the
  sub-tree has exactly one child; n is the number of nodes in the
  sub-tree. }
function LeftMostLeafNode(subtree : PTreeNode) : PTreeNode;
begin
   if subtree <> nil then
   begin
      Result := subtree;
      while Result^.LeftmostChild <> nil do
         Result := Result^.LeftmostChild;
   end else
      Result := nil;
end;

function LastInOrderNode(node : PTreeNode) : PTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   while (node^.LeftmostChild <> nil) and
            (node^.LeftmostChild^.RightSibling <> nil) do
   begin
      node := RightMostChildNode(node);
   end;
   Result := node;
end;

function NodeDepth(node : PTreeNode) : SizeType;
begin
   Assert(node <> nil, msgInvalidIterator);

   Result := 0;
   while node^.Parent <> nil do
   begin
      Inc(Result);
      node := node^.Parent;
   end;
end;

function NodeHeight(node : PTreeNode) : SizeType;
var
   h : SizeType;
begin
   Assert(node <> nil, msgInvalidIterator);

   Result := 0;
   node := node^.LeftmostChild;
   while node <> nil do
   begin
      h := NodeHeight(node) + 1;
      if h > Result then
         Result := h;

      node := node^.RightSibling;
   end;
end;

function NodeChildren(node : PTreeNode) : SizeType;
begin
   Result := 0;
   if node <> nil then
   begin
      node := node^.LeftmostChild;
      while node <> nil do
      begin
         Inc(Result);
         node := node^.RightSibling;
      end;
   end;
end;

function NextPreOrderNode(node : PTreeNode) : PTreeNode;
begin
   Assert(Node <> nil, msgInvalidIterator);

   if node^.LeftmostChild <> nil then
   begin
      node := node^.LeftmostChild;
   end else
   begin
      while (node <> nil) and (node^.RightSibling = nil) do
         node := node^.Parent;

      if node <> nil then
         node := node^.RightSibling;
   end;
   Result := node;
end;

function NextPostOrderNode(node : PTreeNode) : PTreeNode;
begin
   Assert(Node <> nil, msgInvalidIterator);

   if Node^.RightSibling <> nil then
   begin
      Node := LeftMostLeafNode(Node^.RightSibling);
   end else
   begin
      Node := Node^.Parent;
   end;
   Result := node;
end;

function NextInOrderNode(node : PTreeNode) : PTreeNode;
begin
   Assert(Node <> nil, msgInvalidIterator);

   if (Node^.LeftmostChild <> nil) and
         (Node^.LeftmostChild^.RightSibling <> nil) then
      { after visiting the parent start traversing the remaining
        children from left to right }
   begin
      Node := LeftMostLeafNode(Node^.LeftmostChild^.RightSibling);
   end else if Node^.Parent = nil then { it's the root }
   { we now know that Node has at most one child; see if statement above }
   begin
      Node := nil; { end of traversal }
   end else if Node^.Parent^.LeftmostChild = Node then
   { go to the parent after traversing the left-most subtree }
   begin
      Node := Node^.Parent;
   end else if Node^.RightSibling = nil then
    { no more subtrees to traverse - go to the ancestor node which has
      not yet been traversed }
   begin
      while (Node <> nil) and (Node^.RightSibling = nil) do
      begin
         if (Node^.Parent <> nil) and (Node^.Parent^.LeftmostChild = Node) then
         begin
         { if Node is the left-most child of its parent then parent has
           not yet been visited }
            Node := Node^.Parent;
            Break;
         end;
         Node := Node^.Parent;
      end;
      if Node <> nil then
      begin
         if (Node^.Parent <> nil) and (Node^.Parent^.LeftmostChild = Node) then
         begin
            { Node is the left-most child of its parent, so parent has
              not yet been visited -> do nothing }
            Node := Node^.Parent;
         end else
         begin
            { we have already visited parent and now traverse
              sub-trees from left to right }
            Node := LeftMostLeafNode(Node^.RightSibling);
         end;
      end;
   end else
   begin
    { after visiting the parent (some steps before, not necessarily
      one) traverse all subtrees from left to right, except for the
      left-most one }
      Node := LeftMostLeafNode(Node^.RightSibling);
   end;
   Result := node;
end;

function PrevPreOrderNode(node, root : PTreeNode) : PTreeNode;
begin
   if node <> nil then
   begin
      Result := LeftSiblingNode(node);
      if Result <> nil then
      begin
         Result := RightMostLeafNode(Result);
      end else
      begin
         Assert(node^.Parent <> nil, msgRetreatingStartIterator);
         Result := node^.Parent;
      end;
   end else
      Result := RightMostLeafNode(root);
end;

function PrevPostOrderNode(node, root : PTreeNode) : PTreeNode;
begin
   if node <> nil then
   begin
      Result := RightMostChildNode(node);
      if Result = nil then
      begin
         Result := node;
         while (Result^.Parent <> nil) and
                  (Result^.Parent^.LeftmostChild = Result) do
         begin
            Result := Result^.Parent;
         end;
         Assert(Result^.Parent <> nil, msgRetreatingStartIterator);
         Result := LeftSiblingNode(Result);
      end;
   end else
      Result := root;
end;

function PrevInOrderNode(node, root : PTreeNode) : PTreeNode;
begin
   if node <> nil then
   begin
      Result := node^.LeftmostChild;
      if result <> nil then
         Result := LastInOrderNode(Result)
      else begin
         Result := node;
         while (Result^.Parent <> nil) and
                  (Result^.Parent^.LeftmostChild = result) do
         begin
            Result := Result^.Parent;
         end;
         Assert(Result^.Parent <> nil, msgRetreatingStartIterator);
         if Result^.Parent^.LeftmostChild^.RightSibling = Result then
            { result is the second child - go to the parent }
         begin
            Result := Result^.Parent;
         end else
            Result := LastInOrderNode(LeftSiblingNode(Result));
      end;
   end else
      Result := LastInOrderNode(root);
end;

{ replaces node with its children; if fadvance if true returns the
  next node after node accoring to PRE-order }
function ReplaceNodeWithChildren(node : PTreeNode;
                                 fadvancePreOrder : Boolean) : PTreeNode;
var
   lsib, child : PTreeNode;
begin
   Assert(node^.Parent <> nil, msgInternalError);

   lsib := LeftSiblingNode(node);
   child := node^.LeftmostChild;
   if child <> nil then
   begin
      Result := child;
      if lsib <> nil then
      begin
         lsib^.RightSibling := child;
      end else
         node^.Parent^.LeftmostChild := child;

      while child^.RightSibling <> nil do
      begin
         child^.Parent := node^.Parent;
         child := child^.RightSibling;
      end;
      child^.Parent := node^.Parent;
      child^.RightSibling := node^.RightSibling;
   end else
   begin
      if lsib <> nil then
         lsib^.RightSibling := node^.RightSibling
      else
         node^.Parent^.LeftmostChild := node^.RightSibling;

      if node^.RightSibling <> nil then
      begin
         Result := node^.RightSibling;
      end else
      begin
         if fadvancePreOrder then
            Result := NextPreOrderNode(node)
         else
            Result := nil;
      end;
   end;
end;

{ replaces Node with its right-most child and moves all other children
  of Node, from right to left, one by one, to the left-most leaves of
  the new sub-tree of right-most child of Node; Node is disconnected
  from the tree; returns the subtree which contains the left-most leaf
  of the sub-tree of right-most child of Node, or nil if there is no
  right-most child. }
function ReorganiseTreeRight(Node : PTreeNode; FTree : TTree) : PTreeNode;
const
   InitialStackSize = 128;
var
   rchild, temp, lleaf : PTreeNode;
   stack : TPointerDynamicBuffer;
   top : IndexType;
begin
   Assert(Node <> nil, msgInvalidIterator);

   { replace the removed node with its right-most child, then move all
     other children (from right to left) to left-most leaves of
     the right-most child }

   if Node^.LeftmostChild <> nil then
      BufferAllocate(stack, InitialStackSize)
   else
      stack := nil;
   top := -1;

   try
      { Find the right-most child and push the other children at the
        stack, in order to retrieve them easily from right to left,
        later. }
      rchild := Node^.LeftMostChild;
      if rchild <> nil then
      begin
         while rchild^.RightSibling <> nil do
         begin
            Inc(top);
            if top >= stack^.Capacity then
               BufferReallocate(stack, stack^.Capacity * 2);
            stack^.Items[top] := rchild;
            rchild := rchild^.RightSibling;
         end;
      end;
      { from now on no exceptions can be raised }

      { disconnect Node from the tree and put its right-most child in
        its place }
      if Node^.Parent <> nil then
      begin
         temp := Node^.Parent^.LeftMostChild;

         if temp <> Node then
         begin
            while temp^.RightSibling <> Node do
               temp := temp^.RightSibling;

            if rchild <> nil then
               temp^.RightSibling := rchild
            else
               temp^.RightSibling := Node^.RightSibling;

         end else
         begin
            if rchild <> nil then
               Node^.Parent^.LeftMostChild := rchild
            else
               Node^.Parent^.LeftMostChild := Node^.RightSibling;
         end;
      end else
      begin
         FTree.FRoot := rchild;
      end;

      { In each step make one child the only child of the left-most
        leaf. Start from the one-before right-most child and proceed
        from right to left (that's why a stack is needed). }
      if rchild <> nil then
      begin
         rchild^.Parent := Node^.Parent;
         rchild^.RightSibling := Node^.RightSibling;

         Result := rchild;
         while top <> -1 do
         begin
            lleaf := LeftMostLeafNode(Result);
            Result := stack^.Items[top];
            Dec(top);

            lleaf^.LeftMostChild := Result;
            Result^.Parent := lleaf;
            Result^.RightSibling := nil;
         end;
      end else
         Result := nil;
   finally
      if stack <> nil then
         BufferDeallocate(stack);
   end;
end;

{ returns the newly created node }
function InsertAsRightMostLeaf(tree : TTree; aitem : ItemType) : PTreeNode;
begin
   {$warnings off }
   tree.NewNode(Result);
   {$warnings on }
   with Result^ do
   begin
      Item := aitem;
      Leftmostchild := nil;
      RightSibling := nil;
   end;
   tree.InsertNodeAsRightMostLeaf(tree.FRoot, Result);
   Inc(tree.FSize);
end;

{ **************************************************************************** }
{                        LCRS representation of a tree                         }
{ **************************************************************************** }
(* Notes on implementation of TTree:
 *  TTree is a left-most child, right sibling (LCRS) representation of a general
 * purpose tree. Every tree is composed of nodes, each of which contains a pointer
 * to its left-most child, its right sibling and its parent. This assures that
 * all the three basic tree operations take O(1) time. The tree object contains
 * a pointer to the root node and the number of Items in the tree. It also
 * contains FValidSize field, which indicates whether the FSize field is valid
 * (it may be invalidated after move operation). Size operation takes amortized
 * O(1) time, with the worst case of O(n), when FSize is invalid. The absence of
 * some node (child, sibling, root, etc.) is indicated by a nil pointer in its
 * place.
 *)

{ ------------------------------ TTree members ------------------------------- }

constructor TTree.Create;
begin
   inherited;
   InitFields;
end;

constructor TTree.CreateCopy(const cont : TTree;
                             const itemCopier : IUnaryFunctor);

var
   src, destparent : PTreeNode;
   dest : ^PTreeNode;

begin
   inherited CreateCopy(cont);
   InitFields;

   if itemCopier <> nil then
   begin
      try
         { copy the tree structure while moving pre-order }
         destparent := nil;
         dest := @FRoot;
         src := cont.FRoot;
         while src <> nil do
         begin
            NewNode(dest^); { may raise }
            with dest^^ do
            begin
               Item := itemCopier.Perform(src^.Item); { may raise }
               Parent := destparent;
               Leftmostchild := nil;
               RightSibling := nil;
            end;
            Inc(FSize);

            if src^.Leftmostchild <> nil then
            begin
               src := src^.Leftmostchild;
               destparent := dest^;
               dest := @dest^^.Leftmostchild;
            end else if src^.RightSibling <> nil then
            begin
               src := src^.RightSibling;
               // destparent doesn't change
               dest := @dest^^.RightSibling;
            end else
               { we have to go back to some ancestor node }
            begin
               while (src <> nil) and (src^.RightSibling = nil) do
               begin
                  src := src^.Parent;
                  dest := @dest^^.Parent;
               end;

               if src <> nil then
               begin
                  src := src^.RightSibling;
                  { necessary since destparent is not adjusted in the
                    loop }
                  destparent := dest^^.Parent;
                  dest := @dest^^.RightSibling;
               end; { else end of traversal }
            end;
         end;

      except
         DisposeNode(dest^);
         dest^ := nil;
         raise;
      end;

      cont.FValidSize := true;
      cont.FSize := FSize;
   end;
end;

destructor TTree.Destroy;
begin
   Clear;
   inherited;
end;

procedure TTree.InitFields;
begin
   FRoot := nil;
   FSize := 0;
   FValidSize := true;
end;

procedure TTree.DisposeNodeAndItem(node : PTreeNode);
begin
   DisposeItem(node^.Item);
   DisposeNode(node);
end;

procedure TTree.RemoveConnections(node : PTreeNode);
var
   xnode : PTreeNode;
begin
   Assert(Node <> nil);

   if Node^.Parent = nil then
      FRoot := nil
   else
   begin
      xnode := Node^.Parent^.LeftmostChild;
      if xnode = Node then
      begin
         Node^.Parent^.LeftmostChild := Node^.RightSibling;
      end else
      begin
         while xnode^.RightSibling <> node do
            xnode := xnode^.RightSibling;
         xnode^.RightSibling := Node^.RightSibling;
      end;
   end;
end;

procedure TTree.InsertNodeAsRightMostLeaf(var proot : PTreeNode;
                                          node : PTreeNode);
var
   rleaf : PTreeNode;
begin
   if (proot <> nil) and (node <> nil) then
   begin
      rleaf := RightMostLeafNode(proot);
      rleaf^.Leftmostchild := node;
      while node <> nil do
      begin
         node^.Parent := rleaf;
         node := node^.RightSibling;
      end;
   end else if (proot = nil) then
   begin
      Assert((node = nil) or (node^.RightSibling = nil), msgInternalError);

      proot := node;
      if node <> nil then
         node^.Parent := nil;
   end;
end;

function TTree.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TTree.CreateCopy(self, itemCopier);
end;

procedure TTree.Swap(cont : TContainerAdt);
var
   tree : TTree;
begin
   if cont is TTree then
   begin
      BasicSwap(cont);
      tree := TTree(cont);
      ExchangePtr(FRoot, tree.FRoot);
      ExchangeData(FSize, tree.FSize, SizeOf(SizeType));
      ExchangeData(FValidSize, tree.FValidSize, SizeOf(Boolean));
   end else
      inherited;
end;

function TTree.Root : TTreeIterator;
begin
   Result := TTreeIterator.Create(FRoot, self);
end;

function TTree.BasicRoot : TBasicTreeIterator;
begin
   Result := TTreeIterator.Create(FRoot, self);
end;

function TTree.Finish : TBasicTreeIterator;
begin
   Result := TTreeIterator.Create(nil, self);
end;

function TTree.PreOrderIterator : TPreOrderIterator;
begin
   Result := TTreePreOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TTree.PostOrderIterator : TPostOrderIterator;
begin
   Result := TTreePostOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TTree.InOrderIterator : TInOrderIterator;
begin
   Result := TTreeInOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TTree.LevelOrderIterator : TLevelOrderIterator;
begin
   Result := TTreeLevelOrderIterator.Create(self);
   Result.StartTraversal;
end;

function TTree.DeleteSubTree(node : TBasicTreeIterator) : SizeType;
var
   xnode : PTreeNode;
begin
   Assert(node is TTreeIterator, msgInvalidIterator);
   Assert(TTreeIterator(node).Node <> nil, msgDeletingInvalidIterator);
   Assert(node.Owner = self, msgWrongOwner);

   xnode := TTreeIterator(node).Node;
   Result := NodeSubTreeDelete(xnode);
end;

procedure TTree.InsertAsRoot(aitem : ItemType);
var
   temp : PTreeNode;
begin
   NewNode(temp);
   temp^.LeftMostChild := FRoot;
   if FRoot <> nil then
      FRoot^.Parent := temp;
   FRoot := temp;
   temp^.Parent := nil;
   temp^.RightSibling := nil;
   temp^.Item := aitem;

   Inc(FSize);
end;

procedure TTree.InsertAsRightSibling(node : TBasicTreeIterator;
                                     aitem : ItemType);
var
   xnode, pnewnode : PTreeNode;
begin
   Assert(node is TTreeIterator, msgInvalidIterator);
   Assert(node.Owner = self, msgWrongOwner);
   Assert(TTreeIterator(node).Node <> FRoot, msgInsertingRootSibling);

   xnode := TTreeIterator(node).Node;

   NewNode(pnewnode);
   pnewnode^.Item := aitem;
   pnewnode^.LeftmostChild := nil;
   pnewnode^.Parent := xnode^.Parent;
   pnewnode^.RightSibling := xnode^.RightSibling;
   xnode^.RightSibling := pnewnode;
   Inc(FSize);
end;

procedure TTree.InsertAsLeftMostChild(node : TBasicTreeIterator;
                                      aitem : ItemType);
var
   xnode, pnewnode : PTreeNode;
begin
   Assert(node is TTreeIterator, msgInvalidIterator);
   Assert(node.Owner = self, msgWrongOwner);
   Assert(TTreeIterator(node).Node <> nil, msgInvalidIterator);

   xnode := TTreeIterator(node).Node;
   NewNode(pnewnode);
   pnewnode^.Item := aitem;
   pnewnode^.LeftmostChild := nil;
   pnewnode^.Parent := xnode;
   pnewnode^.RightSibling := xnode^.LeftmostChild;
   xnode^.LeftMostChild := pnewnode;
   Inc(FSize);
end;

procedure TTree.MoveToRightSibling(destnode, sourcenode : TBasicTreeIterator);
var
   dest, source : PTreeNode;
   tree2 : TTree;
begin
   Assert(destnode is TTreeIterator, msgInvalidIterator);
   Assert(sourcenode is TTreeIterator, msgInvalidIterator);
   Assert(TTreeIterator(sourcenode).Node <> nil, msgInvalidIterator);
   Assert(destnode.Owner = self, msgWrongOwner);
   Assert(TTreeIterator(destnode).Node <> FRoot);

   source := TTreeIterator(sourcenode).Node;
   dest := TTreeIterator(destnode).Node;
   tree2 := TTreeIterator(sourcenode).FTree;

   if source^.LeftmostChild = nil then
   begin
      Inc(FSize);
      Dec(tree2.FSize);
   end else if source^.Parent = nil then { source is the root }
   begin
      FSize := FSize + tree2.FSize;
      FValidSize := FValidSize and tree2.FValidSize;
      tree2.FSize := 0;
      tree2.FValidSize := true;
   end else if tree2 <> self then
   begin
      FValidSize := false;
      tree2.FValidSize := false;
   end;

   tree2.RemoveConnections(source);

   source^.RightSibling := dest^.RightSibling;
   source^.Parent := dest^.Parent;
   dest^.RightSibling := source;
   { the iterators are invalidated anyway, so there's no need to set  }
end;

procedure TTree.MoveToLeftMostChild(destnode, sourcenode : TBasicTreeIterator);
var
   dest, source : PTreeNode;
   tree2 : TTree;
begin
   Assert(destnode is TTreeIterator, msgInvalidIterator);
   Assert(sourcenode is TTreeIterator, msgInvalidIterator);
   Assert(destnode.Owner = self, msgWrongOwner);

   source := TTreeIterator(sourcenode).Node;
   dest := TTreeIterator(destnode).Node;
   tree2 := TTreeIterator(sourcenode).FTree;

   if source^.LeftmostChild = nil then
   begin
      Inc(FSize);
      Dec(tree2.FSize);
   end else if source^.Parent = nil then { source is the root }
   begin
      FSize := FSize + tree2.FSize;
      FValidSize := FValidSize and tree2.FValidSize;
      tree2.FSize := 0;
      tree2.FValidSize := true;
   end else if tree2 <> self then
   begin
      FValidSize := false;
      tree2.FValidSize := false;
   end;

   tree2.RemoveConnections(source);

   source^.RightSibling := dest^.LeftmostChild;
   source^.Parent := dest;
   dest^.LeftmostChild := source;
end;

procedure TTree.Clear;
begin
   if FRoot <> nil then
   begin
      NodeSubTreeDelete(FRoot);
      FRoot := nil;
      FSize := 0;
      FValidSize := true;
   end;
   GrabageCollector.FreeObjects;
end;

function TTree.Empty : Boolean;
begin
   Result := FRoot = nil;
end;

function TTree.Size : SizeType;
begin
   if not FValidSize then
   begin
      FSize := NodeSubTreeSize(FRoot);
      FValidSize := true;
   end;
   Result := FSize;
end;

function TTree.IsDefinedOrder : Boolean;
begin
   Result := false;
end;

procedure TTree.InsertNode(var node : PTreeNode; parent, rsibling : PTreeNode;
                           aitem : ItemType);
begin
   NewNode(node);
   node^.Parent := parent;
   with node^ do
   begin
      RightSibling := rsibling;
      LeftmostChild := nil;
      Item := aitem;
   end;
   Inc(FSize);
end;

function TTree.ExtractNodePreOrder(var node : PTreeNode;
                                   fadvance : Boolean) : PTreeNode;
var
   node1, child, nnode : PTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   if node^.Parent <> nil then
   begin
      { insert the children of node at the place of node }
      nnode := ReplaceNodeWithChildren(node, fadvance);
      Result := node^.Parent;
      DisposeNode(node);
      node := nnode;
   end else
   begin
      child := node^.LeftmostChild;
      Result := node^.Parent;
      DisposeNode(node);
      node := child;
      FRoot := child;
      if child <> nil then
      begin
         child^.Parent := nil;
         node1 := child^.RightSibling;
         child^.RightSibling := nil;
         InsertNodeAsRightMostLeaf(child, node1);
      end;
   end;
   Dec(FSize);
end;

function TTree.ExtractNodePostOrder(var node : PTreeNode;
                                    fadvance : Boolean) : PTreeNode;
var
   nnode : PTreeNode;
begin
   Assert(node <> nil, msgInvalidIterator);

   if node^.Parent <> nil then
   begin
      { move children of node to the place of node }
      if node^.RightSibling <> nil then
      begin
         if fadvance then
            nnode := LeftMostLeafNode(node^.RightSibling)
         else
            nnode := nil;
      end else
         nnode := node^.Parent;

      ReplaceNodeWithChildren(node, false);
      Result := node^.Parent;
      DisposeNode(node);
      node := nnode;
   end else
   begin
      ReorganiseTreeRight(node, self);
      Result := node^.Parent;
      DisposeNode(node);
      node := nil;
   end;
   Dec(FSize);
end;

function TTree.ExtractNodeInOrder(var node : PTreeNode;
                                  fadvance : Boolean) : PTreeNode;
var
   child, lsib, nnode, parent : PTreeNode;

   { returns the parent of the node actually disposed }
   function ShiftItemsUp(aparent, rsib : PTreeNode) : PTreeNode;
   begin
      nnode := LeftMostLeafNode(rsib);
      while (nnode^.Parent^.LeftmostChild = nnode) and
               (nnode^.RightSibling <> nil) do
      begin
         aparent^.Item := nnode^.Item;
         nnode^.Item := nnode^.Parent^.Item;
         aparent := nnode^.Parent;
         nnode := LeftMostLeafNode(nnode^.RightSibling);
      end;
      aparent^.Item := nnode^.Item;
      Result := nnode^.Parent;
      RemoveConnections(nnode);
      DisposeNode(nnode);
   end;

begin
   Assert(node <> nil, msgInvalidIterator);

   child := node^.LeftmostChild;
   if child <> nil then
   begin
      if child^.RightSibling <> nil then
      begin
         Result := ShiftItemsUp(node, child^.RightSibling);
      end else
      begin
         if fadvance then
            nnode := NextInOrderNode(node)
         else
            nnode := nil;

         { replace node with child }
         parent := node^.Parent;
         lsib := LeftSiblingNode(node);
         if lsib <> nil then
            lsib^.RightSibling := child
         else if parent <> nil then
            parent^.LeftmostChild := child
         else
            FRoot := child;
         child^.Parent := parent;
         child^.RightSibling := node^.RightSibling;
         Result := node^.Parent;
         DisposeNode(node);
         node := nnode;
      end;
   end else
   begin
      if (node^.Parent <> nil) and
            (node^.Parent^.LeftmostChild = node) and
            (node^.RightSibling <> nil) then
      begin
         node^.Item := node^.Parent^.Item;
         Result := ShiftItemsUp(node^.Parent, node^.RightSibling);
      end else
      begin
         if fadvance then
            nnode := NextInOrderNode(node)
         else
            nnode := nil;
         Result := node^.Parent;
         RemoveConnections(node);
         DisposeNode(node);
         node := nnode;
      end;
   end;
   Dec(FSize);
end;

function TTree.NodeSubTreeDelete(node : PTreeNode) : SizeType;
var
   node2, nnode : PTreeNode;
begin
   RemoveConnections(node);
   Result := FSize;
   { delete while moving post-order }
   node2 := LeftMostLeafNode(node);
   while node2 <> node do
   begin
      if node2^.RightSibling <> nil then
         nnode := LeftMostLeafNode(node2^.RightSibling)
      else begin
         nnode := node2^.Parent;
         nnode^.LeftmostChild := nil;
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

function TTree.NodeSubTreeSize(node : PTreeNode) : SizeType;
var
   sbroot : PTreeNode;
begin
   { count the size while moving pre-order }
   Result := 0;
   if node <> nil then
   begin
      Result := 1;
      sbroot := node;
      node := node^.LeftmostChild;
      if node <> nil then
      begin
         while (node <> sbroot^.RightSibling) do
         begin
            Inc(Result);
            if node^.LeftmostChild <> nil then
               node := node^.LeftmostChild
            else if node^.RightSibling <> nil then
               node := node^.RightSibling
            else begin
               node := node^.Parent;
               while (node <> sbroot) and (node^.RightSibling = nil) do
               begin
                  node := node^.Parent;
               end;
               node := node^.RightSibling;
            end;
         end; { end while }
      end;
   end; { end if node <> nil }
end;

procedure TTree.NewNode(var node : PTreeNode);
begin
   GetMem(Pointer(node), SizeOf(TTreeNode));
end;

procedure TTree.DisposeNode(node : PTreeNode);
begin
   FreeMem(node);
end;

{ ------------------------ TTreeIterator members ------------------------ }

constructor TTreeIterator.Create(argnode : PTreeNode; tree : TTree);
begin
   inherited Create(tree);
   Node := argnode;
   FTree := tree;
end;

function TTreeIterator.CopySelf : TIterator;
begin
   Result := TTreeIterator.Create(Node, FTree);
end;

function TTreeIterator.Equal(const iter : TIterator) : Boolean;
begin
   Assert(iter is TTreeIterator);
   Assert(iter.Owner = FTree);

   Result := (TTreeIterator(iter).Node = Node);
end;

function TTreeIterator.GetItem : ItemType;
begin
   Assert(Node <> nil, msgReadingInvalidIterator);
   Result := Node^.Item;
end;

procedure TTreeIterator.SetItem(aitem : ItemType);
begin
   Assert(Node <> nil, msgWritingInvalidIterator);
   with FTree do
      DisposeItem(Node^.Item);
   Node^.Item := aitem;
end;

procedure TTreeIterator.ExchangeItem(iter : TIterator);
begin
   if iter is TTreeIterator then
   begin
      ExchangePtr(Node^.Item, TTreeIterator(iter).Node^.Item);
   end else
      DoExchangeItem(iter);
end;

procedure TTreeIterator.GoToParent;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Node := Node^.Parent;
end;

procedure TTreeIterator.GoToLeftMostChild;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Node := Node^.LeftmostChild;
end;

procedure TTreeIterator.GoToRightSibling;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Node := Node^.RightSibling;
end;

procedure TTreeIterator.InsertAsRightSibling(aitem : ItemType);
begin
   FTree.InsertAsRightSibling(self, aitem);
   Node := Node^.RightSibling;
end;

procedure TTreeIterator.InsertAsLeftMostChild(aitem : ItemType);
begin
   FTree.InsertAsLeftMostChild(self, aitem);
   Node := Node^.LeftmostChild;
end;

function TTreeIterator.DeleteSubTree : SizeType;
var
   temp : PTreeNode;
begin
   Assert(Node <> nil, msgDeletingInvalidIterator);
   temp := Node;
   Node := Node^.Parent;
   Result := FTree.NodeSubTreeDelete(temp);
end;

function TTreeIterator.SubTreeSize : SizeType;
begin
   Result := FTree.NodeSubTreeSize(Node);
end;

function TTreeIterator.PreOrderIterator : TPreOrderIterator;
begin
   Result := TTreePreOrderIterator.Create(FTree);
   TTreePreOrderIterator(Result).Node := Node
end;

function TTreeIterator.PostOrderIterator : TPostOrderIterator;
begin
   Result := TTreePostOrderIterator.Create(FTree);
   TTreePostOrderIterator(Result).Node := Node
end;

function TTreeIterator.InOrderIterator : TInOrderIterator;
begin
   Result := TTreeInOrderIterator.Create(FTree);
   TTreeInOrderIterator(Result).Node := Node;
end;

function TTreeIterator.Owner : TContainerAdt;
begin
   Result := FTree;
end;

function TTreeIterator.IsLeaf : Boolean;
begin
   Result := (Node <> nil) and (Node^.LeftmostChild = nil);
end;

function TTreeIterator.IsRoot : Boolean;
begin
   Result := (Node = FTree.FRoot);
end;

{ -------------------------- TTreePreOrderIterator ------------------------- }

constructor TTreePreOrderIterator.Create(tree : TTree);
begin
   inherited Create(tree);
   FTree := tree;
end;

function TTreePreOrderIterator.CopySelf : TIterator;
begin
   Result := TTreePreOrderIterator.Create(FTree);
   TTreePreOrderIterator(Result).Node := Node;
end;

procedure TTreePreOrderIterator.StartTraversal;
begin
   Node := FTree.FRoot;
end;

{$ifdef OVERLOAD_DIRECTIVE }
procedure TTreePreOrderIterator.Advance;
{$else }
procedure TTreePreOrderIterator.AdvanceOnePosition;
{$endif OVERLOAD_DIRECTIVE }
begin
   Node := NextPreOrderNode(Node);
end;

procedure TTreePreOrderIterator.Retreat;
begin
   Node := PrevPreOrderNode(Node, FTree.FRoot)
end;

procedure TTreePreOrderIterator.Insert(aitem : ItemType);
var
   pnewnode : PTreeNode;
   lsibling : PTreeNode;
begin
   if Node <> nil then
   begin
      { to assure that the newly inserted node is before Node in
        pre-order and the order of other nodes is not changed, the new
        node is placed where Node has been and Node is made its
        only-child. }
      FTree.NewNode(pnewnode);
      pnewnode^.Item := aitem;
      pnewnode^.Parent := Node^.Parent;
      pnewnode^.LeftmostChild := Node;
      pnewnode^.RightSibling := Node^.RightSibling;
      Node^.RightSibling := nil;
      { adjust left sibling }
      if Node^.Parent <> nil then
      begin
         lsibling := Node^.Parent^.Leftmostchild;
         if lsibling <> Node then
         begin
            while lsibling^.RightSibling <> Node do
               lsibling := lsibling^.RightSibling;
            lsibling^.RightSibling := pnewnode;
         end else
         begin
            Node^.Parent^.Leftmostchild := pnewnode;
         end;
      end else
      begin
         FTree.FRoot := pnewnode;
      end;
      Node^.Parent := pnewnode;

      Node := pnewnode;
      Inc(FTree.FSize);
   end else
   begin
      Node := InsertAsRightMostLeaf(FTree, aitem);
   end;
end;

function TTreePreOrderIterator.Extract : ItemType;
begin
   Result := Node^.Item;
   FTree.ExtractNodePreOrder(Node, true);
end;

function TTreePreOrderIterator.IsStart : Boolean;
begin
   Result := Node = FTree.FRoot;
end;

function TTreePreOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TTreeIterator.Create(Node, FTree)
end;

function TTreePreOrderIterator.Equal(const iter : TIterator) : Boolean;
begin
   if iter is TTreePreOrderIterator then
   begin
      Result := (Node = TTreePreOrderIterator(iter).Node);
   end else if iter is TTreeIterator then
   begin
      Result := Node = TTreeIterator(iter).Node
   end else
      Result := inherited Equal(iter);
end;

function TTreePreOrderIterator.GetItem : ItemType;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Result := Node^.Item;
end;

{ -------------------------- TTreePostOrderIterator ------------------------- }

constructor TTreePostOrderIterator.Create(tree : TTree);
begin
   inherited Create(tree);
   FTree := tree;
end;

function TTreePostOrderIterator.CopySelf : TIterator;
begin
   Result := TTreePostOrderIterator.Create(FTree);
   TTreePostOrderIterator(Result).Node := Node;
end;

procedure TTreePostOrderIterator.StartTraversal;
begin
   Node := LeftMostLeafNode(FTree.FRoot);
end;

{$ifdef OVERLOAD_DIRECTIVE }
procedure TTreePostOrderIterator.Advance;
{$else }
procedure TTreePostOrderIterator.AdvanceOnePosition;
{$endif OVERLOAD_DIRECTIVE }
begin
   Node := NextPostOrderNode(Node);
end;

procedure TTreePostOrderIterator.Retreat;
begin
   Node := PrevPostOrderNode(Node, FTree.FRoot)
end;

procedure TTreePostOrderIterator.Insert(aitem : ItemType);
var
   pnewnode, child : PTreeNode;
begin
   if Node <> nil then
   begin
      { make pnewnode the only child of node and take all its children }
      FTree.NewNode(pnewnode);
      pnewnode^.Item := aitem;
      with pnewnode^ do
      begin
         RightSibling := nil;
         LeftMostChild := Node^.LeftMostChild;
         Parent := Node;
      end;
      Node^.LeftMostChild := pnewnode;
      { adjust Parent fields in children }
      child := pnewnode^.LeftMostChild;
      while child <> nil do
      begin
         child^.Parent := pnewnode;
         child := child^.RightSibling;
      end;

      Node := pnewnode;
      Inc(FTree.FSize);
   end else
   begin
      FTree.InsertAsRoot(aitem);
      Node := FTree.FRoot;
   end;
end;

function TTreePostOrderIterator.Extract : ItemType;
begin
   Result := Node^.Item;
   FTree.ExtractNodePostOrder(Node, true);
end;

function TTreePostOrderIterator.IsStart : Boolean;
begin
   if Node <> nil then
   begin
      Result := (Node^.LeftMostChild = nil) and
         (Node = LeftMostLeafNode(FTree.FRoot));
   end else
      Result := FTree.FRoot = nil;
end;

function TTreePostOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TTreeIterator.Create(Node, FTree)
end;

function TTreePostOrderIterator.GetItem : ItemType;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Result := Node^.Item;
end;

{ -------------------------- TTreeInOrderIterator ------------------------- }

constructor TTreeInOrderIterator.Create(tree : TTree);
begin
   inherited Create(tree);
   FTree := tree;
end;

function TTreeInOrderIterator.CopySelf : TIterator;
begin
   Result := TTreeInOrderIterator.Create(FTree);
   TTreeInOrderIterator(Result).Node := Node;
end;

procedure TTreeInOrderIterator.StartTraversal;
begin
   Node := LeftMostLeafNode(FTree.FRoot);
end;

{$ifdef OVERLOAD_DIRECTIVE }
procedure TTreeInOrderIterator.Advance;
{$else }
procedure TTreeInOrderIterator.AdvanceOnePosition;
{$endif OVERLOAD_DIRECTIVE }
begin
   Node := NextInOrderNode(Node);
end;

procedure TTreeInOrderIterator.Retreat;
begin
   Node := PrevInOrderNode(Node, FTree.FRoot)
end;

procedure TTreeInOrderIterator.Insert(aitem : ItemType);
var
   pnewnode : PTreeNode;
begin
   if Node <> nil then
   begin
      { make pnewnode the left-most child of node; the old left-most child
        of Node becomes the left-most child of pnewnode }
      FTree.NewNode(pnewnode);
      pnewnode^.Item := aitem;
      with pnewnode^ do
      begin
         Parent := Node;
         Leftmostchild := Node^.Leftmostchild;

         if Leftmostchild <> nil then
         begin
            RightSibling := Node^.Leftmostchild^.RightSibling;
            with Leftmostchild^ do
            begin
               Parent := pnewnode;
               RightSibling := nil;
            end;
         end else
            RightSibling := nil;
      end;
      Node^.Leftmostchild := pnewnode;

   end else
      { inserting before the Finish iterator -> insert after all other
        nodes }
   begin
      if FTree.Froot <> nil then
         Node := LastInOrderNode(FTree.FROOT);

      FTree.NewNode(pnewnode);
      with pnewnode^ do
      begin
         Item := aitem;
         Leftmostchild := nil;
         RightSibling := nil;
         Parent := Node;
      end;

      if Node <> nil then
      begin
         if Node^.Leftmostchild <> nil then
         begin
            Assert(Node^.Leftmostchild^.RightSibling = nil, msgInternalError);
            Node^.Leftmostchild^.RightSibling := pnewnode;
         end else
         begin
            Node^.Leftmostchild := pnewnode;
            ExchangePtr(pnewnode^.Item, Node^.Item);
            pnewnode := Node; { in order for Node to be properly set
                                to the newly created node }
         end;
      end else
         FTree.FRoot := pnewnode;

   end;
   Node := pnewnode;
   Inc(FTree.FSize);
end;

function TTreeInOrderIterator.Extract : ItemType;
begin
   Result := Node^.Item;
   FTree.ExtractNodeInOrder(Node, true);
end;

function TTreeInOrderIterator.IsStart : Boolean;
begin
   if Node <> nil then
      Result := ((Node^.LeftMostChild = nil) and
                    (Node = LeftMostLeafNode(FTree.FRoot)))
   else
      Result := FTree.FRoot = nil;
end;

function TTreeInOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TTreeIterator.Create(Node, FTree)
end;

function TTreeInOrderIterator.GetItem : ItemType;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Result := Node^.Item;
end;

{ -------------------------- TTreeLevelOrderIterator ------------------------- }

constructor TTreeLevelOrderIterator.Create(tree : TTree);
begin
   inherited Create(tree);
   FTree := tree;
   ArrayAllocate(queue, InitialQueueCapacity, 0);
end;

constructor TTreeLevelOrderIterator.CreateCopy(tree : TTree;
                                               anode : PTreeNode;
                                               aqueue : TPointerDynamicArray);
begin
   inherited Create(tree);
   FTree := tree;
   node := anode;
   queue := aqueue;
end;

destructor TTreeLevelOrderIterator.Destroy;
begin
   ArrayDeallocate(queue);
   inherited;
end;

{ pushes children of Node at the queue }
procedure TTreeLevelOrderIterator.PushChildren;
var
   child : PTreeNode;
   lastSize : SizeType;
begin
   Assert(Node <> nil, msgInternalError);

   lastSize := queue^.Size; { in case of an exception }
   try
      child := Node^.LeftMostChild;
      while child <> nil do
      begin
         ArrayCircularPushBack(queue, child);
         child := child^.RightSibling;
      end;
   except
      queue^.Size := lastSize;
      raise;
   end;
end;

function TTreeLevelOrderIterator.CopySelf : TIterator;
var
   queue2 : TPointerDynamicArray;
begin
   queue2 := nil;
   Result := nil;
   try
      ArrayCopy(queue, queue2);
      Result := TTreeLevelOrderIterator.CreateCopy(FTree, Node, queue2);
   except
      ArrayDeallocate(queue2);
      Result.Free;
      raise;
   end;
end;

procedure TTreeLevelOrderIterator.StartTraversal;
begin
   Node := FTree.FRoot;
   ArrayClear(queue, InitialQueueCapacity, 0);
end;

{$ifdef OVERLOAD_DIRECTIVE }
procedure TTreeLevelOrderIterator.Advance;
{$else }
procedure TTreeLevelOrderIterator.AdvanceOnePosition;
{$endif OVERLOAD_DIRECTIVE }
begin
   Assert(Node <> nil, msgAdvancingInvalidIterator);

   PushChildren;
   if queue^.Size <> 0 then
      Node := ArrayCircularPopFront(queue)
   else
      Node := nil;
end;

procedure TTreeLevelOrderIterator.Retreat;
var
   next : PTreeNode;
   lastSize : SizeType;
begin
   Assert(FTree.FRoot <> nil, msgRetreatingStartIterator);

   next := Node;
   StartTraversal;
   lastSize := queue^.Size;
   PushChildren;
   while (queue^.Size <> 0) and
            (ArrayCircularGetItem(queue, 0) <> next) do
   begin
      Node := ArrayCircularPopFront(queue);
      lastSize := queue^.Size;
      PushChildren;
   end;
   queue^.Size := lastSize;
end;

procedure TTreeLevelOrderIterator.Insert(aitem : ItemType);
var
   lsibling, pnewnode : PTreeNode;
begin
   FTree.NewNode(pnewnode);
   pnewnode^.Item := aitem;

   if Node <> nil then
   begin
      if Node^.Parent <> nil then
         { insert as left sibling of Node }
      begin
         lsibling := Node^.Parent^.LeftMostChild;
         if lsibling <> Node then
         begin
            while lsibling^.RightSibling <> Node do
               lsibling := lsibling^.RightSibling;

            lsibling^.RightSibling := pnewnode;
         end else
            { Node is the left-most child }
         begin
            Node^.Parent^.LeftMostChild := pnewnode;
         end;

         with pnewnode^ do
         begin
            Parent := Node^.Parent;
            LeftMostChild := nil;
            RightSibling := Node;
         end;
      end else
         { Node is the root - insert as root and make Node the only child
           of root. }
      begin
         FTree.FRoot := pnewnode;
         with pnewnode^ do
         begin
            Parent := nil;
            RightSibling := nil;
            LeftMostChild := Node;
         end;
         Node^.Parent := pnewnode;
      end;
   end else
      { insert as a child of the last node }
   begin
      if FTree.FRoot <> nil then
      begin
         StartTraversal;
         PushChildren;
         while queue^.Size <> 0 do
         begin
            Node := ArrayCircularPopFront(queue);
            PushChildren;
         end;

         Node^.LeftMostChild := pnewnode;
         with pnewnode^ do
         begin
            LeftMostChild := nil;
            RightSibling := nil;
            Parent := Node;
         end;
      end else
      begin
         { insert as root }
         with pnewnode^ do
         begin
            LeftMostChild := nil;
            RightSibling := nil;
            Parent := nil;
         end;
         FTree.FRoot := pnewnode;
         FTree.FValidSize := true;
         FTree.FSize := 0; { will be increased below }
      end;
   end;

   Node := pnewnode;
   Inc(FTree.FSize);
end;

function TTreeLevelOrderIterator.Extract : ItemType;
var
   todispose, lchild, rchild, parent, lsibling, root : PTreeNode;
begin
   Assert(Node <> nil, msgInvalidIterator);

   todispose := Node;

   lchild := Node^.LeftMostChild;
   parent := Node^.Parent;

   { disconnect Node from the tree }
   FTree.RemoveConnections(Node);

   { advance one position; we have to push children only when the next
     node is the left-most child of the deleted one, because in other
     cases they will be connected to the next node and they would be
     pushed twice (second time when moving away from the next node) }
   if queue^.Size = 0 then
      PushChildren;

   if queue^.Size <> 0 then
   begin
      Node := ArrayCircularPopFront(queue);

      if lchild <> nil then
      begin
         if Node <> lchild then
         begin
            { Connect children of the deleted node at the left of the
              next node.  }
            lchild^.Parent := Node;

            rchild := lchild;
            while rchild^.RightSibling <> nil do
            begin
               rchild := rchild^.RightSibling;
               rchild^.Parent := Node;
            end;

            rchild^.RightSibling := Node^.LeftMostChild;
            Node^.LeftMostChild := lchild;

         end else { not Node <> lchild }
            { The next node is the left-most child of the previous one ->
              there are no nodes on levels >= the levels of children of
              the next node, except for these children themselves. }
         begin
            if parent <> nil then
               { Insert the children of the deleted node at the right of
                 its parent (from left to right). }
            begin
               lsibling := parent^.LeftMostChild;
               if lsibling = nil then
                  parent^.LeftMostChild := lchild
               else
               begin
                  while lsibling^.RightSibling <> nil do
                  begin
                     lsibling := lsibling^.RightSibling;
                  end;
                  lsibling^.RightSibling := lchild;
               end;

               while lchild <> nil do
               begin
                  lchild^.Parent := parent;
                  lchild := lchild^.RightSibling;
               end;
            end else
               { The deleted node was the root - make the left-most child
                 of the deleted node the root and connect the rest of the
                 children at the left of the new root. }
            begin
               { we have to clear the queue }
               queue^.Size := 0;

               FTree.FRoot := lchild;
               root := lchild;
               root^.Parent := nil;
               rchild := root^.RightSibling;
               root^.RightSibling := nil;

               if rchild <> nil then
               begin
                  lchild := rchild;
                  lchild^.Parent := root;

                  while rchild^.RightSibling <> nil do
                  begin
                     rchild := rchild^.RightSibling;
                     rchild^.Parent := root;
                  end;

                  rchild^.RightSibling := root^.LeftMostChild;
                  root^.LeftMostChild := lchild;
               end;
            end;
         end; { end not Node <> lchild }
      end; { end lchild <> nil }
   end else
      Node := nil;

   Result := todispose^.Item;
   FTree.DisposeNode(todispose);
   Dec(FTree.FSize);
end;

function TTreeLevelOrderIterator.IsStart : Boolean;
begin
   Result := Node = FTree.FRoot;
end;

function TTreeLevelOrderIterator.TreeIterator : TBasicTreeIterator;
begin
   Result := TTreeIterator.Create(Node, FTree);
end;

function TTreeLevelOrderIterator.GetItem : ItemType;
begin
   Assert(Node <> nil, msgInvalidIterator);
   Result := Node^.Item;
end;

{ ------------------------------ Routines -------------------------------- }

function Parent(const iter : TTreeIterator) : TTreeIterator;
begin
   Assert(iter.Node <> nil, msgInvalidIterator);

   with iter do
      if Node^.Parent <> nil then
         Result := TTreeIterator.Create(Node^.Parent, FTree)
      else
         Result := nil;
end;

function LeftMostChild(const iter : TTreeIterator) : TTreeIterator;
begin
   Assert(iter.Node <> nil, msgInvalidIterator);

   with iter do
      if Node^.LeftMostChild <> nil then
         Result := TTreeIterator.Create(Node^.LeftMostChild, FTree)
      else
         Result := nil;
end;

function RightSibling(const iter : TTreeIterator) : TTreeIterator;
begin
   Assert(iter.Node <> nil, msgInvalidIterator);

   with iter do
      if Node^.RightSibling <> nil then
         Result := TTreeIterator.Create(Node^.LeftMostChild, FTree)
      else
         Result := nil;
end;

function RightMostChild(const iter : TTreeIterator) : TTreeIterator;
begin
   Assert(iter.Node <> nil, msgInvalidIterator);

   with iter do
      if Node^.LeftMostChild <> nil then
         Result := TTreeIterator.Create(RightMostChildNode(Node), FTree)
      else
         Result := nil;
end;

function LeftSibling(const iter : TTreeIterator) : TTreeIterator;
var
   node : PTreeNode;
begin
   Assert(iter.Node <> nil, msgInvalidIterator);

   node := LeftSiblingNode(iter.Node);
   if node <> nil then
      Result := TTreeIterator.Create(node, iter.Ftree)
   else
      Result := nil;
end;

function LeftMostLeaf(const iter : TTreeIterator) : TTreeIterator;
begin
   Assert(iter.Node <> nil, msgInvalidIterator);

   Result := TTreeIterator.Create(LeftMostLeafNode(iter.Node), iter.FTree);
end;

function RightMostLeaf(const iter : TTreeIterator) : TTreeIterator;
begin
   Assert(iter.Node <> nil, msgInvalidIterator);

   Result := TTreeIterator.Create(RightMostLeafNode(iter.Node), iter.FTree);
end;

function Depth(const iter : TTreeIterator) : SizeType;
begin
   Result := NodeDepth(iter.Node);
end;

function Height(const iter : TTreeIterator) : SizeType;
begin
   Result := NodeHeight(iter.Node);
end;

function Children(const iter : TTreeIterator) : SizeType;
begin
   Result := NodeChildren(iter.Node);
end;

function CopyOf(const iter : TTreeIterator) : TTreeIterator;
begin
   Result := TTreeIterator(iter.CopySelf);
end;
