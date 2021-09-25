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
 adttree.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adttree.defs

type

{ =========================== General tree class ============================= }
   
   { a node of an LCRS tree @see TTree @include-declarations 2 }
   PTreeNode = ^TTreeNode;
   TTreeNode = record
      Parent, LeftMostChild, RightSibling : PTreeNode;
      Item : ItemType;
   end;

   TTreeIterator = class;

   { implements a tree using the LCRS (leftmost-child, right sibling)
     representation }
   TTree = class(TBasicTreeAdt)
   private
      FRoot : PTreeNode;
      FSize : SizeType;
      FValidSize : Boolean;

      procedure InitFields;
      procedure DisposeNodeAndItem(node : PTreeNode);
      { removes the node's subtree from the tree structure (the
        subtree itself is not deleted), this may take even O(n) time
        when almost n Items are siblings of the removed node and node
        is the right-most child, because the left sibling of node
        needs to be found; this procedure does not maintain FSize or
        FValidSize, and does not modify the given argument - only
        'disconnects' it from the tree, but all its members still
        point where they pointed }
      procedure RemoveConnections(node : PTreeNode);
      { does nothing if node is nil; root can be nil; does not
        maintain FSize field ! }
      procedure InsertNodeAsRightMostLeaf(var proot : PTreeNode;
                                          node : PTreeNode);

   public
      constructor Create; overload;
      { creates a copy of cont; uses itemCopier to copy items }
      constructor CreateCopy(const cont : TTree;
                             const itemCopier : IUnaryFunctor); overload;
      { frees all Items and deallocates any allocated memory; @complexity O(n). }
      destructor Destroy; override;
      { returns an exact copy of self; @complexity O(n). }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { returns the iterator pointing at the root of the tree }
      function Root : TTreeIterator;
      { returns the iterator pointing at the root of the tree; returns
        the same as Root }
      function BasicRoot : TBasicTreeIterator; override;
      { returns an invalid iterator representing the end of traversal;
        it can be used to mark the end of sequence when using tree
        traversal iterators as forward iterators in algorithms }
      function Finish : TBasicTreeIterator; override;
      { returns an iterator for traversing the tree in preorder traversal order }
      function PreOrderIterator : TPreOrderIterator; override;
      { returns an iterator for traversing the tree in postorder
        traversal order; @complexity O(h), but if counted as a part of
        traversal then amortized O(1). }
      function PostOrderIterator : TPostOrderIterator; override;
      { returns an iterator for traversing the tree in inorder
        traversal order; @complexity O(h), but if counted as a part of
        traversal then amortized O(1). }
      function InOrderIterator : TInOrderIterator; override;
      { returns an iterator for traversing the tree in levelorder traversal order }
      function LevelOrderIterator : TLevelOrderIterator; override;
      { deletes the given node together with its subtree, invalidates
        the given iterator; returns the number of items deleted;
        @complexity worst case O(n). }
      function DeleteSubTree(node : TBasicTreeIterator) : SizeType; override;
      { inserts the given Item as the root of the tree; the old root
        becomes the left-most child of the new one }
      procedure InsertAsRoot(aitem : ItemType); override;
      { inserts aitem into the tree as a right sibling of node }
      procedure InsertAsRightSibling(node : TBasicTreeIterator; aitem : ItemType);
      { inserts aitem into the tree as a left-most child of node }
      procedure InsertAsLeftMostChild(node : TBasicTreeIterator; aitem : ItemType);
      { moves sourcenode (together with its subtrees) to become a
        right sibling of destnode; destnode cannot be an ancestor of
        sourcenode, sourcenode can be from different tree; @complexity
        O(ls), where ls is the number of left siblings of
        sourcenode. }
      procedure MoveToRightSibling(destnode, sourcenode : TBasicTreeIterator);
      { moves sourcenode (together with its subtrees) to become a
        leftmost child of destnode; destnode cannot be an ancestor of
        sourcenode, sourcenode can be from different tree; @complexity
        O(ls), where ls is the number of left siblings of
        sourcenode. }
      procedure MoveToLeftMostChild(destnode, sourcenode : TBasicTreeIterator);
      { deletes all Items; equivalent to: if not Empty then
        Delete(Root); @complexity O(n). }
      procedure Clear; override;
      { returns true if the tree contains no Items }
      function Empty : Boolean; override;
      { returns the number of Items; @complexity amortized O(1). }
      function Size : SizeType; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
      
      { returns a pointer to the root node (PBinaryTreeNode); this may
        be sometimes useful in performance-critical parts of
        application, but does not have the common, extensible
        interface }
      property RootNode : PTreeNode read FRoot;
      { inserts pointer at node; node should be the place to which to
        assign the new node (e.g. parent^.LeftMostChild) }
      procedure InsertNode(var node : PTreeNode; parent, rsibling : PTreeNode;
                           aitem : ItemType);
      { removes node without violating pre-order; returns the parent
        of the node actually removed (this is not necessarily
        node^.Parent); fadvance indicates if to assign node the next
        node after it in pre-order; @complexity O(h) }
      function ExtractNodePreOrder(var node : PTreeNode;
                                   fadvance : Boolean) : PTreeNode;
      { removes node without violating post-order; returns the parent
        of the node actually removed (this is not necessarily
        node^.Parent); fadvance indicates if to assign node the next
        node after it in post-order; @complexity O(h) }
      function ExtractNodePostOrder(var node : PTreeNode;
                                    fadvance : Boolean) : PTreeNode;
      { removes node without violating in-order; returns the parent of
        the node actually removed (this is not necessarily
        node^.Parent); fadvance indicates if to assign node the next
        node after it in in-order; @complexity O(h) }
      function ExtractNodeInOrder(var node : PTreeNode;
                                  fadvance : Boolean) : PTreeNode;
      { deletes the subtree of node; returns the number of nodes
        deleted }
      function NodeSubTreeDelete(node : PTreeNode) : SizeType;
      { returns the size of the subtree of node (i.e. the overall
        number of nodes in the subtree) }
      function NodeSubTreeSize(node : PTreeNode) : SizeType;
      { allocates new node }
      procedure NewNode(var node : PTreeNode);
      { deallocates a node }
      procedure DisposeNode(node : PTreeNode);
   end;

   { an iterator into TTree }
   TTreeIterator = class (TBasicTreeIterator)
   private
      Node : PTreeNode;
      FTree : TTree;

   public
      { argnode is the node at which iterator will point; tree is the
        owner of this node }
      constructor Create(argnode : PTreeNode; tree : TTree);
      { returns an exact copy of self; i.e. copies all the data }
      function CopySelf : TIterator; override;
      { returns true if iter and self point at the same node }
      function Equal(const iter : TIterator) : Boolean; override;
      { returns Item from the position pointed by self }
      function GetItem : ItemType; override;
      { sets the Item at the position pointed to by iterator to aitem }
      procedure SetItem(aitem : ItemType); override;
      { exchanges item pointed by iter with item pointed by self }
      procedure ExchangeItem(iter : TIterator); override;
      { moves the iterator to its parent }
      procedure GoToParent; override;
      { moves the iterator to point at its leftmost child }
      procedure GoToLeftMostChild;
      { moves iterator to point at its right sibling }
      procedure GoToRightSibling;
      { inserts Item as a right sibling of self; moves self to newly
        inserted item }
      procedure InsertAsRightSibling(aitem : ItemType);
      { inserts aitem as the left-most child of self; moves self to
        newly inserted item }
      procedure InsertAsLeftMostChild(aitem : ItemType);
      { deletes Item pointed to by self together with the whole
        subtree of self and moves self to its parent; returns the
        number of items deleted; @complexity worst case O(n) }
      function DeleteSubTree : SizeType; override;
      { returns the size of the subtree of self; @complexity O(n),
        where n is the number of items in the subtree }
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
   end;

   { a preorder iterator into @<TTree> }
   TTreePreOrderIterator = class (TPreOrderIterator)
   private
      Node : PTreeNode;
      FTree : TTree;
      
      {$warnings off }
      constructor Create(tree : TTree);
      {$warnings on }
   public
      { returns a copy of the iterator }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its owner tree,
        according to preorder traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to preorder
        traversal order; @complexity amortized O(1) }
{$ifdef OVERLOAD_DIRECTIVE }      
      procedure Advance; overload; override;
{$else }
      procedure AdvanceOnePosition; override;
{$endif OVERLOAD_DIRECTIVE }
      { moves self to previous position according to pre-order;
        @complexity amortized O(1) }
      procedure Retreat; override;
      { inserts item before position; does not violate previous
        pre-order; goes to the newly inserted item; @complexity
        usually O(ls), where ls is the number of left siblings of
        self, but O(h) when you insert as the last node (i.e. using
        finish iterator). }
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      { returns true if self is the first iterator }
      function IsStart : Boolean; override;
      { returns a tree iterator pointing at the same node }
      function TreeIterator : TBasicTreeIterator; override;
      
      { re-implemented for efficiency reasons }
      function Equal(const iter : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
   end;

   { a postorder iterator into @<TTree> }
   TTreePostOrderIterator = class (TPostOrderIterator)
   private
      Node : PTreeNode;
      FTree : TTree;
      
      {$warnings off }
      constructor Create(tree : TTree);
      {$warnings on }
   public
      { returns a copy of the iterator }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its owner tree,
        according to post-order traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to preorder
        traversal order; @complexity amortized O(1) }
{$ifdef OVERLOAD_DIRECTIVE }      
      procedure Advance; overload; override; 
{$else }
      procedure AdvanceOnePosition; override;
{$endif OVERLOAD_DIRECTIVE }
      { moves self to previous position according to post-order;
        @complexity amortized O(1) }
      procedure Retreat; override;
      { inserts item before position; does not violate previous
        post-order; goes to the newly inserted item }
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      { returns true if self is the first iterator; @complexity worst
        case O(n) }
      function IsStart : Boolean; override;
      { returns a tree iterator pointing at the same node }
      function TreeIterator : TBasicTreeIterator; override;
      
      { re-implemented for efficiency reason }
      function GetItem : ItemType; override;
   end;

   { an inorder iterator into @<TTree> }
   TTreeInOrderIterator = class (TInOrderIterator)
   private
      Node : PTreeNode;
      FTree : TTree;
      
      {$warnings off }
      constructor Create(tree : TTree);
      {$warnings on }
   public
      { returns a copy of the iterator }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its owner tree,
        according to inorder traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to inorder
        traversal order; @complexity amortized O(1) }
{$ifdef OVERLOAD_DIRECTIVE }
      procedure Advance; overload; override; 
{$else }
      procedure AdvanceOnePosition; override;
{$endif OVERLOAD_DIRECTIVE }
      { moves self to previous position according to in-order;
        @complexity amortized O(1) }
      procedure Retreat; override;
      { inserts item before position; does not violate previous
        in-order; goes to the newly inserted item; @complexity usually
        O(1), but O(h) when you insert as last item (i.e. using finish
        iterator). }
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      { returns true if self is the first iterator; @complexity worst case O(n) }
      function IsStart : Boolean; override;
      { returns a tree iterator pointing at the same node }
      function TreeIterator : TBasicTreeIterator; override;

      { re-implemented for efficiency reason }
      function GetItem : ItemType; override;
   end;

   { a levelorder iterator into @<TTree> }
   TTreeLevelOrderIterator = class (TLevelOrderIterator)
   private
      queue : TPointerDynamicArray;
      FTree : TTree;
      Node : PTreeNode;

      { pushes children of Node at the queue }
      procedure PushChildren;
      {$warnings off }
      constructor Create(tree : TTree); 
      {$warnings on }
   public
      destructor Destroy; override;
      { returns a copy of the iterator }
      function CopySelf : TIterator; override;
      { moves the iterator to the first node in its owner tree,
        according to levelorder traversal }
      procedure StartTraversal; override;
      { moves the iterator to the next node according to levelorder
        traversal order. }
{$ifdef OVERLOAD_DIRECTIVE }
      procedure Advance; overload; override; 
{$else }
      procedure AdvanceOnePosition; override;
{$endif OVERLOAD_DIRECTIVE }
      { moves self to previous position according to level-order;
        @complexity worst-case O(n). }
      procedure Retreat; override;
      { inserts item before position; does not violate previous
        level-order; goes to the newly inserted item; @complexity
        worst case O(n) }
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      { returns true if self is the first iterator }
      function IsStart : Boolean; override;
      { returns a tree iterator pointing at the same node }
      function TreeIterator : TBasicTreeIterator; override;

      { re-implemented for efficiency reason }
      function GetItem : ItemType; override;
   end;
   
{ -------------------------- Useful routines ---------------------------  }
   
{ returns the parent of iter or nil if iter has no parent (i.e. iter
  is the root) }
function Parent(const iter : TTreeIterator) : TTreeIterator;
{ returns the left-most child of iter or nil if iter does not have the
  left-most child }
function LeftMostChild(const iter : TTreeIterator) : TTreeIterator;
{ returns the right sibling of iter or nil if iter has no right
  sibling }
function RightSibling(const iter : TTreeIterator) : TTreeIterator;
{ returns the right-most child of iter or nil if iter does not have
  the right-most child; @complexity O(c), where c is the number of
  children of iter }
function RightMostChild(const iter : TTreeIterator) : TTreeIterator;
{ returns the left sibling (neighbour) of node or nil if node is the
  left-most child; @complexity O(ls), where ls is the number of left
  siblings of node }
function LeftSibling(const iter : TTreeIterator) : TTreeIterator;
{ returns the left-most leaf of the subtree of iter; the left-most
  leaf is the node visited first in post-order and in-order traversal;
  @complexity worst case O(n). }
function LeftMostLeaf(const iter : TTreeIterator) : TTreeIterator;
{ returns the right-most leaf of the subtree of iter; the right-most
  leaf is the node visited last in pre-order traversal; @complexity
  worst case O(n). }
function RightMostLeaf(const iter : TTreeIterator) : TTreeIterator;
{ returns the depth of iter; @complexity O(h), where h is the height
  of the whole tree }
function Depth(const iter : TTreeIterator) : SizeType;
{ returns the height of iter; @complexity O(n). }
function Height(const iter : TTreeIterator) : SizeType;
{ returns the number of children of <iter>; @complexity O(c), where c
  is the number of children of <iter> }
function Children(const iter : TTreeIterator) : SizeType;

{$ifdef OVERLOAD_DIRECTIVE }
function CopyOf(const iter : TTreeIterator) : TTreeIterator; overload;
{$endif OVERLOAD_DIRECTIVE }


{ ------------------------ low-level routines ------------------------------ }

{ returns the right-most child of node; @complexity takes exactly O(c)
  time, where c is the number of children of node }
function RightMostChildNode(node : PTreeNode) : PTreeNode;
{ returns the left sibling (neighbour) of node or nil if node is the
  left-most child; @complexity O(ls), where ls is the number of left
  siblings of node }
function LeftSiblingNode(node : PTreeNode) : PTreeNode;
{ Right-most leaf in a sub-tree is the node which is visited in
  pre-order traversal after all other nodes the sub-tree. This
  algorithm is worst-case O(n) time when all nodes are children of the
  root of the subtree or if every node has exactly one child; n is the
  number of nodes in the subtree. }
function RightMostLeafNode(subtree : PTreeNode) : PTreeNode;
{ Left-most leaf in a sub-tree is the node that is visited in
  post-order and in-order traversals before any other node in the
  sub-tree. This is worst-case O(n) time when every node in the
  sub-tree has exactly one child; n is the number of nodes in the
  sub-tree. }
function LeftMostLeafNode(subtree : PTreeNode) : PTreeNode;
{ returns the last node in in-order traversal; @complexity worst case O(n). }
function LastInOrderNode(node : PTreeNode) : PTreeNode;
{ returns the depth of node; @complexity worst case O(h). }
function NodeDepth(node : PTreeNode) : SizeType;
{ returns the height of node; @complexity worst case O(n). }
function NodeHeight(node : PTreeNode) : SizeType;
{ returns the number of children of <node>; @complexity O(c), where c
  is the number of children of <node> }
function NodeChildren(node : PTreeNode) : SizeType;
{ returns the next node accoring to pre-order; @complexity amortized O(1). }
function NextPreOrderNode(node : PTreeNode) : PTreeNode;
{ returns the next node accoring to post-order; @complexity amortized O(1). }
function NextPostOrderNode(node : PTreeNode) : PTreeNode;
{ returns the next node accoring to in-order; @complexity amortized O(1). }
function NextInOrderNode(node : PTreeNode) : PTreeNode;
{ returns the previous node accoring to pre-order; @complexity amortized O(1). }
function PrevPreOrderNode(node, root : PTreeNode) : PTreeNode;
{ returns the previous node accoring to post-order; @complexity amortized O(1). }
function PrevPostOrderNode(node, root : PTreeNode) : PTreeNode;
{ returns the previous node accoring to in-order; @complexity amortized O(1). }
function PrevInOrderNode(node, root : PTreeNode) : PTreeNode;
