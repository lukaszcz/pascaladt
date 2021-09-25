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
 adtavltree.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtavltree.defs

type
   PAvlTreeNode = ^TAvlTreeNode;
   { this record should be packed to prevent the compiler from
     re-arranging the order of the fields; @see TBinaryTreeNode }
   TAvlTreeNode = packed record
      Item : ItemType;
      Parent, LeftChild, RightChild : PAvlTreeNode;
      bf : -1..1;
   end;
   
   { implements a set using the AVL-tree; guarantees worst-case
     O(log(n)) time for all set operations }
   TAvlTree = class (TBinarySearchTreeBase)
   private
      { reorganises the tree after deletion; parent is the parent of
        the node actually removed; wasLeftChild indicates whether the node
        actually removed was the left child (true) or the right child
        (false) }
      procedure ReorganiseAfterDeletion(parent : PAvlTreeNode;
                                        wasLeftChild : Boolean);
      { reorganises the tree as if the height of the sub-tree of
        <node> increased; parent^.bf cannot be 0, you have to handle
        this case separately; parent must be the parent of <node>;
        returns the node placed at the position of parent }
      function Reorganise(parent, node : PAvlTreeNode) : PAvlTreeNode;
      
   protected
      { inserts aitem at proper position in the tree; starts searching
        from node; returns the newly created node or nil if aitem could
        not be inserted }
      function InsertNode(aitem : ItemType;
                          node : PBinaryTreeNode) : PBinaryTreeNode; override;
      
   public      
      { creates an AVL tree }
      constructor Create;
      { creates a copy of cont; uses itemCopier to copy items }
      constructor CreateCopy(const cont : TAvlTree;
                             const itemCopier : IUnaryFunctor); overload;
      { returns a copy of self }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap; }
      procedure Swap(cont : TContainerAdt); override;
      { returns the iterator pointing at the first item with the key
        equal to that of aitem, or nil if not found; @complexity
        worst-case O(log(n)) }
      {@decl function Find(aitem : ItemType) : ItemType; override; }
      { returns the number of items in the set equal to aitem;
        @complexity worst-case O(log(n)) }
      {@decl function Count(aitem : ItemType) : SizeType; override; }
      { inserts aitem into the set; returns true if self was inserted,
        or false if it cannot be inserted (this happens for non-multi
        (without repeated items) set when item equal to aitem is already
        in the set); @complexity worst-case O(log(n)) }
      {@decl function Insert(aitem : ItemType) : Boolean; override; overload; }
      { the same as above, but uses pos as a hint where to insert;
        @complexity worst case O(log(n)). }
      {@decl function Insert(pos : TSetIterator;
                             aitem : ItemType) : Boolean; override; overload; }
      { removes all items equal to aitem from the set; returns the
        number of deleted items; @complexity worst case O(m*log(n)),
        where m is the number of deleted items }
      function Delete(aitem : ItemType) : SizeType; overload; override; 
      { removes the item at pos from the set }
      procedure Delete(pos : TSetIterator); overload; override; 
      { returns the first item >= aitem, or Finish if container is
        empty; @complexity worst case O(log(n)) }
      {@decl function LowerBound(aitem : ItemType) : TSetIterator; override; }
      { returns the first item > aitem, or Finish if container is empty;
        @complexity worst-case O(log(n)) }
      {@decl function UpperBound(aitem : ItemType) : TSetIterator; override; }
      { returns a range <LowerBound, UpperBound), works faster than
        calling these two functions separately; @complexity worst case
        O(log(n)) }
      {@decl function EqualRange(aitem : ItemType) : TSetIteratorRange; override; }
   end;
