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
 adtsplaytree_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtsplaytree.defs
&include adtsplaytree_impl.mcp

{ --------------------------- TSplayTree ---------------------------------- }

constructor TSplayTree.Create;
begin
   inherited;
end;

constructor TSplayTree.CreateCopy(const cont : TSplayTree;
                                  const itemCopier : IUnaryFunctor); 
begin
   inherited CreateCopy(cont, itemCopier);
end;

function TSplayTree.Splay(aitem : ItemType;
                          node : PBinaryTreeNode) : PBinaryTreeNode;
var
   parent : PBinaryTreeNode;
begin
   Result := FindNode(aitem, node, parent);
   if Result <> nil then
      SplayNode(Result)
   else if parent <> nil then
      SplayNode(parent);
end;

procedure TSplayTree.SplayNode(node : PBinaryTreeNode);
var
   y, z : PBinaryTreeNode;
begin
   Assert(node <> nil, msgInternalError);
   
   y := node^.Parent;
   if y <> nil then
      z := y^.Parent
   else
      z := nil;
   
   while (z <> nil) and (y <> nil) do
   begin
      if z^.LeftChild = y then
      begin
         if y^.LeftChild = node then
         begin
            BinaryTree.RotateNodeSingleRight(z);
            BinaryTree.RotateNodeSingleRight(y);
         end else { node is the right child of y }
         begin
            BinaryTree.RotateNodeDoubleRight(z);
         end;
      end else { y is the right child }
      begin
         if y^.LeftChild = node then
         begin
            BinaryTree.RotateNodeDoubleLeft(z);
         end else { node is the right child of y }
         begin
            BinaryTree.RotateNodeSingleLeft(z);
            BinaryTree.RotateNodeSingleLeft(y);
         end;
      end;
      
      y := node^.Parent;
      if y <> nil then
         z := y^.Parent
      else
         z := nil;
   end;
   
   if y <> nil then
   begin
      if y^.LeftChild = node then
         BinaryTree.RotateNodeSingleRight(y)
      else
         BinaryTree.RotateNodeSingleLeft(y);
   end;
end;

procedure TSplayTree.DeleteNodeAtRoot;
var
   root, rchild : PBinaryTreeNode;
   aitem : ItemType;
begin
   root := BinaryTree.RootNode;
   aitem := root^.Item;
   
   if root^.LeftChild <> nil then
   begin
      rchild := BinaryTree.ReplaceNodeWithLeftChild(root);
      { move the previous node to the root }
      Splay(aitem, BinaryTree.RootNode);
      
      root := BinaryTree.RootNode;
      { because the previous node is the largest in the tree, it
        can't have a right child }
      Assert(root^.RightChild = nil, msgInternalError);
      
      root^.RightChild := rchild;
      if rchild <> nil then
         rchild^.Parent := root;
   end else
   begin
      BinaryTree.ReplaceNodeWithRightChild(root);
   end;
   DisposeItem(aitem);
end;

function TSplayTree.LowerBoundNode(aitem : ItemType;
                                   node : PBinaryTreeNode) : PBinaryTreeNode;
begin
   Result := inherited LowerBoundNode(aitem, node);
   if Result <> nil then
      SplayNode(Result);
end;

function TSplayTree.InsertNode(aitem : ItemType;
                               node : PBinaryTreeNode) : PBinaryTreeNode;
var
   root, oldroot, lchild, rchild : PBinaryTreeNode;
begin
   if node <> nil then
   begin
      Result := Splay(aitem, node);
      { now the found node (or its parent) is at the root of the tree }
      if (Result = nil) or RepeatedItems then
      begin
         oldroot := BinaryTree.RootNode;
         lchild := oldroot^.LeftChild;
         rchild := oldroot^.RightChild;
         
         BinaryTree.InsertAsRoot(aitem);
         root := BinaryTree.RootNode;
         
         if _mcp_lt(oldroot^.Item, aitem) then
         begin
            oldroot^.RightChild := nil;
            root^.RightChild := rchild;
            if rchild <> nil then
               rchild^.Parent := root;
         end else
         begin
            oldroot^.LeftChild := nil;
            root^.LeftChild := lchild;
            if lchild <> nil then
               lchild^.Parent := root;
            root^.RightChild := oldroot;
         end;
         Result := root;
         
      end else { there already is such node and RepeatedItems is false }
      begin
         Result := nil;
      end;
      
   end else
   begin
      if BinaryTree.RootNode = node then
      begin
         BinaryTree.InsertAsRoot(aitem);
         Result := BinaryTree.RootNode;
      end else
         Result := InsertNode(aitem, BinaryTree.RootNode);
   end;
end;

function TSplayTree.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TSplayTree.CreateCopy(self, itemCopier);
end;

procedure TSplayTree.Swap(cont : TContainerAdt);
begin
   if cont is TSplayTree then
   begin
      BasicSwap(cont);
      ExchangeBinaryTrees(TSplayTree(cont));
   end else
      inherited;
end;

&if (&_mcp_accepts_nil)
function TSplayTree.FindOrInsert(aitem : ItemType) : ItemType;
var
   node : PBinaryTreeNode;
begin
   if RepeatedItems then
   begin
      InsertNode(aitem, BinaryTree.RootNode);
      Result := nil;
   end else
   begin
      node := Splay(aitem, BinaryTree.RootNode);
      if node <> nil then
         Result := node^.Item
      else begin
         InsertNode(aitem, BinaryTree.RootNode);
         Result := nil;
      end;
   end;
end;

function TSplayTree.Find(aitem : ItemType) : ItemType;
var
   node : PBinaryTreeNode;
begin
   node := Splay(aitem, BinaryTree.RootNode);
   if node <> nil then
      Result := node^.Item
   else
      Result := nil;
end;
&endif

function TSplayTree.Has(aitem : ItemType) : Boolean;
begin
   Result := Splay(aitem, BinaryTree.RootNode) <> nil;
end;

function TSplayTree.Count(aitem : ItemType) : SizeType;
var
   node : PBinaryTreeNode;
begin
   node := Splay(aitem, BinaryTree.RootNode);
   Result := 0;
   if node <> nil then
   begin
      repeat
         Inc(Result);
         node := NextInOrderNode(node);
      until (node = nil) or (not _mcp_equal(node^.Item, aitem));
   end;
end;

function TSplayTree.Delete(aitem : ItemType) : SizeType;
begin
   Result := 0;
   while Splay(aitem, BinaryTree.RootNode) <> nil do
   begin
      { the found node is at the root }
      DeleteNodeAtRoot;
      Inc(Result);
   end;
end;

procedure TSplayTree.Delete(pos : TSetIterator);
var
   node, nnode : PBinaryTreeNode;
begin
   Assert((pos <> nil) and (pos is TBinarySearchTreeBaseIterator),
          msgInvalidIterator);
   Assert(TBinarySearchTreeBaseIterator(pos).Node <> nil, msgInvalidIterator);
   
   node := TBinarySearchTreeBaseIterator(pos).Node;
   nnode := NextInOrderNode(node);
   
   SplayNode(node);
   DeleteNodeAtRoot;
   
   TBinarySearchTreeBaseIterator(pos).Node := nnode;
end;
