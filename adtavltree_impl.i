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
 adtavltree_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtavltree.defs
&include adtavltree_impl.mcp

type
   { this class is a special version of TBinaryTree that should be
     used with TAvlTree; it allocates larger nodes with one additional
     field needed by the AVL-trees.  }
   TAvlBinaryTree = class (TBinaryTree)
   public
      procedure NewNode(var node : PBinaryTreeNode); override;
   end;
   
{ ------------------------ TAvlBinaryTree --------------------------------- }
   
procedure TAvlBinaryTree.NewNode(var node : PBinaryTreeNode);
begin
   New(PAvlTreeNode(node));
end;

{ ------------------------- TAvlTree -------------------------------------- }

constructor TAvlTree.Create;
begin
   inherited Create(TAvlBinaryTree.Create);
end;

constructor TAvlTree.CreateCopy(const cont : TAvlTree;
                                const itemCopier : IUnaryFunctor);
var
   destnode, srcnode : PBinaryTreeNode;
begin
   if itemCopier <> nil then
   begin
      inherited CreateCopy(cont, itemCopier);

      { copy bf fields (TBinaryTree does not know about them) }
      destnode := BinaryTree.RootNode;
      srcnode := cont.BinaryTree.RootNode;
      while destnode <> nil do
      begin
         Assert(srcnode <> nil, msgInternalError);
         PAvlTreeNode(destnode)^.bf := PAvlTreeNode(srcnode)^.bf;
         destnode := NextPreOrderNode(destnode);
         srcnode := NextPreOrderNode(srcnode);
      end;
   end else
   begin
      inherited Create(TAvlBinaryTree.Create);
      ItemDisposer := cont.ItemDisposer;
      ItemComparer := cont.ItemComparer;
   end;
end;

procedure TAvlTree.ReorganiseAfterDeletion(parent : PAvlTreeNode;
                                           wasLeftChild : Boolean);
var
   node : PAvlTreeNode;
begin
   if parent <> nil then
   begin
      if parent^.bf = -1 then
      begin
         if wasLeftChild then
            parent := Reorganise(parent, parent^.RightChild)
         else
            parent^.bf := 0;
         
      end else if parent^.bf = +1 then
      begin
         if not wasLeftChild then
            parent := Reorganise(parent, parent^.LeftChild)
         else
            parent^.bf := 0;
      
      end else { parent^.bf = 0 }
      begin
         if wasLeftChild then
            parent^.bf := -1
         else { parent^.RightChild = nil }
            parent^.bf := +1;
      end;
      
      node := parent;
      parent := parent^.Parent;
      
      while (parent <> nil) and (node^.bf = 0) do
         { if node^.bf is 0 it means that in the previous
           reorganisation the height of the whole sub-tree of node
           decreased, so we need to proceed. }
      begin
         if parent^.bf = 0 then
         begin
            if parent^.LeftChild = node then
               parent^.bf := -1
            else
               parent^.bf := +1;
         end else
         begin
            if parent^.LeftChild = node then
               parent := Reorganise(parent, parent^.RightChild)
            else
               parent := Reorganise(parent, parent^.LeftChild);
            
         end;
         
         node := parent;
         parent := parent^.Parent;
      end;
   end;
end;

function TAvlTree.Reorganise(parent, node : PAvlTreeNode) : PAvlTreeNode;
var
   prev : PAvlTreeNode;
begin
   Assert((parent <> nil), msgInternalError);
   Assert((node <> nil), msgInternalError);
   Assert(parent^.bf <> 0, msgInternalError);
   
   if parent^.bf = +1 then
   begin
      if parent^.LeftChild = node then
      begin
         { new parent^.bf is +2 }
         if node^.bf = +1 then
         begin
            parent^.bf := 0;
            node^.bf := 0;
            BinaryTree.RotateNodeSingleRight(PBinaryTreeNode(parent));
            Result := node;
         end else if node^.bf = -1 then
         begin
            prev := node^.RightChild;
            if prev^.bf = +1 then
            begin
               parent^.bf := -1;
               node^.bf := 0;
            end else if prev^.bf = -1 then
            begin
               parent^.bf := 0;
               node^.bf := +1;
            end else { prev^.bf = 0 }
            begin
               parent^.bf := 0;
               node^.bf := 0;
            end;
            prev^.bf := 0;
            BinaryTree.RotateNodeDoubleRight(PBinaryTreeNode(parent));
            Result := prev;
         end else { node^.bf = 0 }
         begin
            { if node has no children then parent must have node as
              its only left-child, so after the rotation parent won't
              have any children; if node has both (it can only have
              both or none, since node^.bf = 0) children then parent
              also must have the second child whose sub-tree has
              height smaller by one than the sub-trees of node's
              children; the right child of node if connected to parent
              in the rotation and parent^.bf becomes +1 }
            if (node^.LeftChild <> nil) then { node has both children }
               parent^.bf := +1
            else
               parent^.bf := 0;
            node^.bf := -1;
            BinaryTree.RotateNodeSingleRight(PBinaryTreeNode(parent));
            Result := node;
         end;
      end else { node is the right child of parent }
      begin
         parent^.bf := 0;
         Result := parent;
      end;
   end else { not parent^.bf = +1 => parent^.bf = -1 }
   begin
      if parent^.LeftChild = node then
      begin
         parent^.bf := 0;
         Result := parent;
      end else { node is the right child of parent }
      begin
         { new parent^.bf = -2 }
         if node^.bf = -1 then
         begin
            parent^.bf := 0;
            node^.bf := 0;
            BinaryTree.RotateNodeSingleLeft(PBinaryTreeNode(parent));
            Result := node;
         end else if node^.bf = +1 then
         begin
            prev := node^.LeftChild;
            if prev^.bf = -1 then
            begin
               parent^.bf := +1;
               node^.bf := 0;
            end else if prev^.bf = +1 then
            begin
               parent^.bf := 0;
               node^.bf := -1;
            end else { prev^.bf = 0 }
            begin
               parent^.bf := 0;
               node^.bf := 0;
            end;
            prev^.bf := 0;
            BinaryTree.RotateNodeDoubleLeft(PBinaryTreeNode(parent));
            Result := prev;
         end else { node^.bf = 0 }
         begin
            if node^.LeftChild <> nil then { node has both children }
               parent^.bf := -1
            else
               parent^.bf := 0;
            node^.bf := +1;
            BinaryTree.RotateNodeSingleLeft(PBinaryTreeNode(parent));
            Result := node;
         end;
      end;
   end; { end not parent^.bf = +1 }
end;

function TAvlTree.InsertNode(aitem : ItemType;
                             node : PBinaryTreeNode) : PBinaryTreeNode;
var
   parent, curr : PAvlTreeNode;
   { parent is the parent of curr; these two nodes constitute a part
     of path from the newly inserted node to the root and move up each
     step actualising bf values of nodes; actualising stops when we
     reach the root or new bf of parent is either +2 or -2, then we
     perform appropriate rotation to re-organise the tree; when
     parent's new bf is 0 we also stop, but without any rotations }
begin
   Result := inherited InsertNode(aitem, node);
   if Result <> nil then
   begin
      curr := PAvlTreeNode(Result);
      parent := curr^.Parent;
      curr^.bf := 0; { curr was inserted as a leaf and has no
                       children, so it must have bf = 0 }
      
      while (parent <> nil) and (parent^.bf = 0) do
      begin
         if parent^.LeftChild = curr then
            parent^.bf := +1
         else
            parent^.bf := -1;
         
         curr := parent;
         parent := parent^.Parent;
      end;
      
      if parent <> nil then
      begin
         Reorganise(parent, curr);
      end;
   end;
end;

function TAvlTree.CopySelf(const ItemCopier : IUnaryFunctor) : TContainerAdt;
begin
   Result := TAvlTree.CreateCopy(self, itemCopier); 
end;

procedure TAvlTree.Swap(cont : TContainerAdt);
begin
   if cont is TAvlTree then
   begin
      BasicSwap(cont);
      ExchangeBinaryTrees(TAvlTree(cont));
   end else
      inherited;
end;

function TAvlTree.Delete(aitem : ItemType) : SizeType;
var
   node, parent : PBinaryTreeNode;
   wasLeftChild : Boolean;
begin
   Result := 0;
   node := FindNode(aitem, BinaryTree.RootNode, parent);
   if node <> nil then
   begin
      repeat
         Inc(Result);
         DisposeItem(node^.Item);
         parent := BinaryTree.ExtractNodeInOrderAux(node, true, wasLeftChild);
         ReorganiseAfterDeletion(PAvlTreeNode(parent), wasLeftChild);
      until (node = nil) or (not _mcp_equal(aitem, node^.Item));
   end;
end;

procedure TAvlTree.Delete(pos : TSetIterator);
var
   node, parent : PBinaryTreeNode;
   wasLeftChild : Boolean;
begin
   Assert(pos is TBinarySearchTreeBaseIterator, msgInvalidIterator);
   
   node := TBinarySearchTreeBaseIterator(pos).Node;
   DisposeItem(node^.Item);
   parent := BinaryTree.ExtractNodeInOrderAux(node, true, wasLeftChild);
   ReorganiseAfterDeletion(PAvlTreeNode(parent), wasLeftChild);
   TBinarySearchTreeBaseIterator(pos).Node := node;
end;
