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
 adtbintree.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtbintree.defs

type
   
{ =========================== General binary tree ============================ }

   { a node of a binary tree @see TBinaryTree @include-declarations 2 }
   PBinaryTreeNode = ^TBinaryTreeNode;
   { this record should be packed to prevent the compiler from
     re-arranging the order of the fields; important for the
     implementation of the Avl-tree! @see TAvlTreeNode }
   TBinaryTreeNode = packed record
      Item : ItemType;
      Parent, LeftChild, RightChild : PBinaryTreeNode;
   end;
   
   TBinaryTreeIterator = class;

   { a binary tree }
   TBinaryTree = class(TBasicTreeAdt)
   private
      FRoot : PBinaryTreeNode;
      FSize : SizeType;
      FValidSize : Boolean;
      
      procedure InitFields;
      procedure DisposeNodeAndItem(node : PBinaryTreeNode);
      { replaces node old with newnode; old is disconnected from the tree;
        only Parent field of new is changed, no fields of old are
        changed; newnode can be nil }
      procedure ReplaceNode(old, pnewnode : PBinaryTreeNode);
      procedure RemoveConnections(node : PBinaryTreeNode);
   public
      { creates an empty tree }
      constructor Create; overload;
      { creates a copy of cont; uses <itemCopier> to copy items; if
        <itemCopier> is nil then does not copy the items }
      constructor CreateCopy(const cont : TBinaryTree;
                             const itemCopier : IUnaryFunctor); overload;
      { frees all Items and deallocates any allocated memory }
      destructor Destroy; override;
      { copies all items in self; uses ItemCopier to perform the
        copying; @complexity O(n) }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { returns the iterator pointing at the root of the tree }
      function Root : TBinaryTreeIterator;
      { returns the iterator pointing at the root of the tree }
      function BasicRoot : TBasicTreeIterator; override;
      { returns an invalid iterator representing the end of traversal;
        it can be used to mark the end of sequence when using tree
        traversal iterators as forward iterators in algorithms }
      function Finish : TBasicTreeIterator; override;
      { returns an iterator for traversing the tree in preorder traversal order }
      function PreOrderIterator : TPreOrderIterator; override;
      { returns an iterator for traversing the tree in postorder traversal order }
      function PostOrderIterator : TPostOrderIterator; override;
      { returns an iterator for traversing the tree in inorder traversal order }
      function InOrderIterator : TInOrderIterator; override;
      { returns an iterator for traversing the tree in levelorder traversal order }
      function LevelOrderIterator : TLevelOrderIterator; override;
      { deletes the given node together with its subtree, invalidates
        the given iterator; @complexity O(m), where m is the number of
        items in the sub-tree }
      function DeleteSubTree(node : TBasicTreeIterator) : SizeType; override;
      { inserts the given Item as the root of the tree; the old root
        becomes the left child of the newly inserted item }
      procedure InsertAsRoot(aitem : ItemType); override;
      { inserts aitem as the left child of node; the previous left child
        of node becomes the left child of the new node }
      procedure InsertAsLeftChild(const node : TBasicTreeIterator;
                                  aitem : ItemType);
      { inserts aitem as the right child of node; the previous right
        child of node becomes the right child of the new node }
      procedure InsertAsRightChild(const node : TBasicTreeIterator;
                                   aitem : ItemType);
      { moves src to the left child of node; if node already has a
        left child the behaviour is undefined (you should always check
        with HasLeftChild first); node cannot be an ancestor of src,
        src can be from a different tree }
      procedure MoveToLeftChild(const node, src : TBasicTreeIterator);
      { moves src to the right child of node; if node already has a
        right child the behaviour is undefined (you should always
        check with HasRightChild first); node cannot be an ancestor of
        src, src can be from a different tree }
      procedure MoveToRightChild(const node, src : TBasicTreeIterator);
      { performs a single left rotation on the given node }
      procedure RotateSingleLeft(const node : TBasicTreeIterator);
      { performs a double left rotation on the given node }
      procedure RotateDoubleLeft(const node : TBasicTreeIterator);
      { performs a single right rotation on the given node }
      procedure RotateSingleRight(const node : TBasicTreeIterator);
      { performs a double right rotation on the given node }
      procedure RotateDoubleRight(const node : TBasicTreeIterator);
      { deletes all Items; equivalent to: if not Empty then
        DeleteSubTree(Root); @complexity O(n) }
      procedure Clear; override;
      { returns true if the tree contains no Items }
      function Empty : Boolean; override;
      { returns the number of Items; @complexity amortized O(1), worst case O(n) }
      function Size : SizeType; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
      
      { returns a pointer to the root node (PBinaryTreeNode); this may
        be sometimes useful in performance-critical parts of
        application, but does not have the common, extensible
        interface }
      property RootNode : PBinaryTreeNode read FRoot;
      { inserts pointer at node; node should be the place to which to
        assign the new node (e.g. parent^.LeftChild) }
      procedure InsertNode(var node : PBinaryTreeNode;
                           parent : PBinaryTreeNode; aitem : ItemType); overload;
      { replaces node with its left child; node is disposed (but not
        the item); returns the right child of node, which must be
        re-connected somewhere in the tree !!! }
      function ReplaceNodeWithLeftChild(node : PBinaryTreeNode) : PBinaryTreeNode;
      { replaces node with its right child; node is disposed (but not
        the item); returns the left child of node, which must be
        re-connected somewhere in the tree !!! }
      function ReplaceNodeWithRightChild(node : PBinaryTreeNode) : PBinaryTreeNode;
      { disconnects node from the tree so that the pre-order of other
        nodes is preserved; returns the parent of the node actually
        disposed (this is not necessarily node^.Parent), nil if this
        was the last node; node is disposed (but not the item); after
        extraction node points to the next node according to
        pre-order; fadvance indicates whether to assign node the next
        node in pre-order; this is because advancing to the next node
        may take an O(h) time; @complexity O(h), where h is the height
        of the tree }
      function ExtractNodePreOrder(var node : PBinaryTreeNode;
                                   fadvance : Boolean) : PBinaryTreeNode;
      { disconnects <node> from the tree so that the post-order of other
        nodes is preserved; returns the parent of the node actually
        disposed (this is not necessarily node^.Parent), nil if this
        was the last node; node is disposed (but not the item); after
        extraction node points to the next node according to
        post-order; @complexity O(h), where h is the height of the
        tree }
      function ExtractNodePostOrder(var node : PBinaryTreeNode;
                                    fadvance : Boolean) : PBinaryTreeNode;
      { disconnects <node> from the tree so that the in-order of other
        nodes is preserved; returns the parent of the node actually
        disposed (this is not necessarily node^.Parent since items may
        be swapped inside the tree), nil if this was the last node;
        <node> is disposed (but not the item); after the extraction
        <node> points to the next node according to the in-order (if
        fadvance is true); fadvance indicates whether to assign <node>
        the next node in in-order; this is because advancing to the
        next node may take O(h) time; @complexity O(h), where h is the
        height of the tree }
      function ExtractNodeInOrder(var node : PBinaryTreeNode;
                                  fadvance : Boolean) : PBinaryTreeNode;
      { the same as @<ExtractNodeInOrder>, but has one additional
        boolean var parameter which is set to true when the node
        actually disposed was the left child, and to false if it was a
        right child. }
      function ExtractNodeInOrderAux(var node : PBinaryTreeNode;
                                     fadvance : Boolean;
                                     var isLeftChild : Boolean) : PBinaryTreeNode;
      { performs a single left rotation on the given node }
      procedure RotateNodeSingleLeft(node : PBinaryTreeNode);
      { performs a double left rotation on the given node }
      procedure RotateNodeDoubleLeft(node : PBinaryTreeNode);
      { performs a single right rotation on the given node }
      procedure RotateNodeSingleRight(node : PBinaryTreeNode);
      { performs a double right rotation on the given node }
      procedure RotateNodeDoubleRight(node : PBinaryTreeNode);
      { deletes the subtree of node; returns the number of nodes
        deleted }
      function NodeSubTreeDelete(node : PBinaryTreeNode) : SizeType;
      { returns the size of the subtree of node (i.e. the overall
        number of nodes in the subtree) }
      function NodeSubTreeSize(node : PBinaryTreeNode) : SizeType;
      { allocates new node }
      procedure NewNode(var node : PBinaryTreeNode); virtual;
      { deallocates a node }
      procedure DisposeNode(var node : PBinaryTreeNode); virtual;
   end;

   { an iterator into TBinaryTree }
   TBinaryTreeIterator = class(TBasicTreeIterator)
   private
      Node : PBinaryTreeNode;
      FTree : TBinaryTree;

   public
      { argnode is the node at which iterator will point; tree is the
        owner of this node }
      constructor Create(argnode : PBinaryTreeNode; tree : TBinaryTree);
      { returns an exact copy of self; i.e. copies all the data }
      function CopySelf : TIterator; override;
      { returns true if iter and self point at the same node }
      function Equal(const iter : TIterator) : Boolean; override;
      { returns Item from the position pointed by self }
      function GetItem : ItemType; override;
      { sets the Item at the position pointed to by iterator to aitem }
      procedure SetItem(aitem : ItemType); override;
      { exchanges the item pointed to by self with the one pointed
        to by the argument }
      procedure ExchangeItem(iter : TIterator); override;
      { moves self to its parent }
      procedure GoToParent; override;
      { moves the iterator to point at its left child }
      procedure GoToLeftChild;
      { moves iterator to point at its right child }
      procedure GoToRightChild;
      { inserts aitem as the left child of self; previous left child
        becomes the left child of the new node; advances to newly
        inserted item }
      procedure InsertAsLeftChild(aitem : ItemType);
      { inserts aitem as the right child of self; previous righ child
        becomes the right child of the new node; advances to newly
        inserted item }
      procedure InsertAsRightChild(aitem : ItemType);
      { removes the iterator together with its sub-tree; @complexity
        O(m), where m is the number of items in the sub-tree }
      function DeleteSubTree : SizeType; override;
      { returns the number of nodes (items) in the subtree of self
        (self included) }
      function SubTreeSize : SizeType; override;
      { returns a pre-order iterator pointing at the same item as self }
      function PreOrderIterator : TPreOrderIterator; override;
      { returns a post-order iterator pointing at the same item as self }
      function PostOrderIterator : TPostOrderIterator; override;
      { returns an in-order iterator pointing at the same item as self }
      function InOrderIterator : TInOrderIterator; override;
      { returns container into which self points }
      function Owner : TContainerAdt; override;
      { returns true if the iterator points to a leaf }
      function IsLeaf : Boolean; override;
      { returns true if the iterator points to the root }
      function IsRoot : Boolean; override;
      { returns true if the node is the left child of its parent; false
        for the root }
      function IsLeftChild : Boolean;
      { returns true if the node is the right child of its parent;
        false for the root }
      function IsRightChild : Boolean;
      { returns true if the node has a left child }
      function HasLeftChild : Boolean;
      { returns true if the node has a right child }
      function HasRightChild : Boolean;
   end;

   { preorder iterator into TBinaryTree }
   TBinaryTreePreOrderIterator = class (TPreOrderIterator)
   private
      Node : PBinaryTreeNode;
      FTree : TBinaryTree;
      
      {$warnings off }
      constructor Create(tree : TBinaryTree);
      {$warnings on }
   public
      { returns a copy of self }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its tree, according to
        inorder traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to inorder
        traversal order; @complexity amortized O(1) }
      procedure Advance; overload; override;
      { moves the iterator to the previous node; @complexity amortized O(1). }
      procedure Retreat; override;
      { Inserts at the current position, advances to next position
        according to pre-order traversal. Does not change pre-order
        order of nodes. }
      procedure Insert(aitem : ItemType); override;
      { the same as Delete but returns the removed item instead of
        disposing it; @complexity O(h), where h is the height of the
        tree }
      function Extract : ItemType; override;
      { returns a normal tree iterator pointing at the same item as
        self }
      function TreeIterator : TBasicTreeIterator; override;
      { returns true if self is the first iterator }
      function IsStart : Boolean; override;
   end;

   { postorder iterator into TBinaryTree }
   TBinaryTreePostOrderIterator = class (TPostOrderIterator)
   private
      Node : PBinaryTreeNode;
      FTree : TBinaryTree;
      
      {$warnings off }
      constructor Create(tree : TBinaryTree);
      {$warnings on }
   public
      { returns a copy of self }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its tree, according to
        postorder traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to postorder
        traversal order; @complexity amortized O(1) }
      procedure Advance; overload; override; 
      { moves the iterator to the previous node; @complexity amortized O(1). }
      procedure Retreat; override;
      { Inserts at the current position, advances to next position
        according to post-order traversal. Does not change post-order
        order of nodes. }
      procedure Insert(aitem : ItemType); override;
      { the same as Delete but returns the removed item instead of
        disposing it; @complexity O(h), where h is the height of the
        tree }
      function Extract : ItemType; override;
      { returns a normal tree iterator pointing at the same item as
        self }
      function TreeIterator : TBasicTreeIterator; override;
      { returns true if self is the first iterator; @complexity worst
        case O(h), where h is the height of the tree }
      function IsStart : Boolean; override;
   end;

   { inorder iterator into TBinaryTree }
   TBinaryTreeInOrderIterator = class (TInOrderIterator)
   private
      Node : PBinaryTreeNode;
      FTree : TBinaryTree;
      
      {$warnings off }
      constructor Create(tree : TBinaryTree);
      {$warnings on }
   public
      { returns a copy of self }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its tree, according to
        inorder traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to inorder
        traversal order; @complexity amortized O(1) }
      procedure Advance; overload; override; 
      { moves the iterator to the previous node; @complexity amortized O(1). }
      procedure Retreat; override;
      { Inserts at the current position, advances to next position
        according to in-order traversal. Does not change in-order
        order of nodes.  }
      procedure Insert(aitem : ItemType); override;
      { the same as Delete but returns the removed item instead of
        disposing it; Removes the node pointed by self. Moves self to
        next position according to in-order traversal. Reorganises the
        tree so as not to change in-order of nodes. @complexity O(h),
        where h is the height of hte tree @complexity O(h), where h is
        the height of the tree }
      function Extract : ItemType; override;
      { returns a normal tree iterator pointing at the same item as
        self }
      function TreeIterator : TBasicTreeIterator; override;
      { returns true if self is the start iterator; @complexity worst
        case O(h), where h is the height of the tree }
      function IsStart : Boolean; override;
   end;

   { levelorder iterator into TBinaryTree }
   TBinaryTreeLevelOrderIterator = class (TLevelOrderIterator)
   private
      Node : PBinaryTreeNode;
      FTree : TBinaryTree;
      queue : TPointerDynamicArray; { this queue is used to store
                                      pointers to the nodes to be
                                      visited }
      
      { pushes children at the queue }
      procedure PushChildren;
      { performs initialization (you still have to call StartTraversal) }
      {$warnings off }
      constructor Create(tree : TBinaryTree);
      {$warnings on }
   public
      destructor Destroy; override;
      { returns a copy of self }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its tree, according to
        levelorder traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to levelorder
        traversal order }
      procedure Advance; overload; override; 
      { moves the iterator to the previous node; @complexity worst case O(n). }
      procedure Retreat; override;
      { Inserts at the current position, advances to next position
        according to level-order traversal. Does not change level-order
        order of nodes. @complexity worst case O(n). }
      procedure Insert(aitem : ItemType); override;
      { the same as Delete but returns the removed item instead of
        disposing it; Removes the node pointed by self. Moves self to
        next position according to level-order traversal. Reorganises
        the tree so as not to change level-order of nodes. @complexity
        worst-case O(n) }
      function Extract : ItemType; override;
      { returns a normal tree iterator pointing at the same item as
        self }
      function TreeIterator : TBasicTreeIterator; override;
      { returns true if self is the first iterator }
      function IsStart : Boolean; override;
   end;
   
{ ---------------------- non-member routines -------------------------------- }
   
{ returns the parent of iter or nil if iter does not have parent }
function Parent(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
{ returns the right child of iter or nil if iter does not have a right child }
function RightChild(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
{ returns the left child of iter or nil if iter does not have a left child }
function LeftChild(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
{ returns the right-most leaf in the subtree of iter; it's the node
  visited last in pre-order traversal; @complexity O(h), where h is
  the height of the whole tree }
function RightMostLeaf(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
{ returns the left-most leaf in the subtree of iter; it's the node
  visited first in post-order traversal; @complexity O(h), where h is
  the height of the whole tree }
function LeftMostLeaf(const iter : TBinaryTreeIterator) : TBinaryTreeIterator;
{ returns the depth of iter; @complexity O(h), where h is
  the height of the whole tree }
function Depth(const iter : TBinaryTreeIterator) : SizeType;
{ returns the height of iter; @complexity worst case O(n) }
function Height(const iter : TBinaryTreeIterator) : SizeType;

{$ifdef OVERLOAD_DIRECTIVE }
function CopyOf(const iter : TBinaryTreeIterator) : TBinaryTreeIterator; overload;
{$endif OVERLOAD_DIRECTIVE }


{ ----------------------- low-level routines ---------------------------- }

{ returns the left-most leaf in subtree; @complexity O(h), h is the
  height of the tree }
function LeftMostLeafNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the right-most leaf in subtree; @complexity O(h), h is the
  height of the tree }
function RightMostLeafNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the node which is visited first in in-order traversal; it's
  the node whose all ancestors are left children of their parents
  (except for the root). @complexity O(h), where h is the height of
  the tree }
function FirstInOrderNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the node which is visited last in in-order traversal; it's
  the node whose all ancestors are right children of their parents
  (except for the root). @complexity O(h), where h is the height of
  the tree }
function LastInOrderNode(subtree : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the next node according to pre-order traversal; @complexity
  amortized O(1) }
function NextPreOrderNode(node : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the next node according to post-order traversal; @complexity
  amortized O(1) }
function NextPostOrderNode(node : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the next node according to in-order traversal; @complexity
  amortized O(1) }
function NextInOrderNode(node : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the previous node according to pre-order traversal; @complexity
  amortized O(1) }
function PrevPreOrderNode(node, root : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the previous node according to post-order traversal; @complexity
  amortized O(1) }
function PrevPostOrderNode(node, root : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the previous node according to in-order traversal; @complexity
  amortized O(1) }
function PrevInOrderNode(node, root : PBinaryTreeNode) : PBinaryTreeNode;
{ returns the depth of node; @complexity O(h), where h is the height
  of the tree }
function NodeDepth(node : PBinaryTreeNode) : SizeType;
{ returns the height of node; @complexity O(h), where h is the height
  of the tree }
function NodeHeight(node : PBinaryTreeNode) : SizeType;

