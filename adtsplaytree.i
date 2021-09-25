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
 adtsplaytree.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtsplaytree.defs

type
   { a splay tree; guarantees amortized O(log(n)) complexity for all
     set operations; this data structure is very fast when a small
     number of all items is accessed most of the time, which is
     usually the case; however, if you know that the items are going
     to be distributed randomly, it would be better to use another
     structure with the worst-case O(log(n)) time, such as the AVL-tree,
     or the red-black tree. }
   TSplayTree = class (TBinarySearchTreeBase)
   private
      { finds the first item greater or equal to <ptr> and moves it to
        the root using tree rotations (so that the order of items is
        preserved); starts searching from node; if the item found is
        equal to <ptr> returns the node that contains it, otherwise
        returns nil; }
      function Splay(aitem : ItemType; node : PBinaryTreeNode) : PBinaryTreeNode;
      { moves node to the root using tree rotations (so that the order
        of items is not changed) }
      procedure SplayNode(node : PBinaryTreeNode);
      { removes the node currently placed at the root }
      procedure DeleteNodeAtRoot;
      
   protected      
      { returns the first node with item >= aitem; starts searching from
        node; node can be nil }
      function LowerBoundNode(aitem : ItemType;
                              node : PBinaryTreeNode) : PBinaryTreeNode; override;
      { inserts <ptr> at proper position in the tree; starts searching
        from node; returns the newly created node or nil if <ptr> could
        not be inserted }
      function InsertNode(aitem : ItemType;
                          node : PBinaryTreeNode) : PBinaryTreeNode; override;   
     
   public
      { creates a splay tree }
      constructor Create; overload;
      { creates a copy of cont; uses itemCopier to copy items }
      constructor CreateCopy(const cont : TSplayTree;
                             const itemCopier : IUnaryFunctor); overload;
      { returns a copy of self }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap; }
      procedure Swap(cont : TContainerAdt); override;
&if (&_mcp_accepts_nil)      
      { if RepeatedItems is false and there is an item equal to <ptr> in
        the set, then returns this item; in all other cases inserts
        <ptr> into the set and returns nil }
      function FindOrInsert(aitem : ItemType) : ItemType; override;
      { returns the iterator pointing at the first item with the key
        equal to that of aitem, or nil if not found; @complexity amortized
        O(log(n)), worst case O(n). }
      function Find(aitem : ItemType) : ItemType; override;
&endif
      { @fetch-related }
      { @complexity amortized O(log(n)), worst-case O(n) } 
      function Has(aitem : ItemType) : Boolean; override;
      { returns the number of items in the set equal to aitem;
        @complexity amortized O(log(n)), worst case O(n) }
      function Count(aitem : ItemType) : SizeType; override;
      { inserts <ptr> into the set; returns true if self was inserted,
        or false if it cannot be inserted (this happens for non-multi
        (without repeated items) set when item equal to <ptr> is already
        in the set); @complexity amortized O(log(n)), worst case O(n). }
      {@decl function Insert(aitem : ItemType) : Boolean; override; overload; }
      { the same as above, but uses <pos> as a hint where to insert;
        @complexity amortized O(log(n)), worst case O(n). }
      {@decl function Insert(pos : TSetIterator;
                             aitem : ItemType) : Boolean; override; overload; }
      { removes all items equal to <ptr> from the set; returns the
        number of deleted items; @complexity amortized O(m*log(n))
        where m is the number of deleted items, worst case O(n) }
      function Delete(aitem : ItemType) : SizeType; overload; override; 
      { removes the item at <pos> from the set }
      procedure Delete(pos : TSetIterator); overload; override;       
      { returns the first item >= aitem, or Finish if container is
        empty; @complexity amortized O(log(n)), worst case O(n).}
      {@decl function LowerBound(aitem : ItemType) : TSetIterator; override; }
      { returns the first item > aitem, or Finish if container is empty;
        @complexity amortized O(log(n)), worst case O(n). }
      {@decl function UpperBound(aitem : ItemType) : TSetIterator; override; }
      { returns a range <LowerBound, UpperBound), works faster than
        calling these two functions separately; @complexity amortized
        O(log(n)), worst case O(n). }
      {@decl function EqualRange(aitem : ItemType) : TSetIteratorRange; override; }
   end;
