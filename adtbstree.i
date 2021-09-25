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
 adtbstree.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtbstree.defs

type
{ ======================== TBinarySearchTreeBase ============================= }
   
   { provides parts of implementation common to all containers based
     on some kind of binary search tree }
   TBinarySearchTreeBase = class (TSortedSetAdt)
   private
      FBinaryTree : TBinaryTree;
      
   protected      
      {$warnings off }
      { creates a base binary search tree; assigns btree to FBinaryTree }
      constructor Create(btree : TBinaryTree); overload;
      { as above, but assigns a new TBinaryTree to FBinaryTree }
      constructor Create; overload;
      { creates a copy of cont; uses itemCopier to copy items }
      constructor CreateCopy(const cont : TBinarySearchTreeBase;
                             const itemCopier : IUnaryFunctor); overload;
      {$warnings on }
      
      procedure SetOwnsItems(b : Boolean); override;
      procedure SetDisposer(const proc : IUnaryFunctor); override;
      function GetDisposer : IUnaryFunctor; override;
      
      { returns the first node that contains an item equal to aitem, or nil
        if no such item exists; starts searching from node; node can
        be nil; sets parent to the parent of the returned node or nil if
        aitem has been found at the root; sets parent even if aitem is not found }
      function FindNode(aitem : ItemType; node : PBinaryTreeNode;
                        var parent : PBinaryTreeNode) : PBinaryTreeNode;
      { returns the first node with item >= aitem; starts searching from
        node; node can be nil }
      function LowerBoundNode(aitem : ItemType;
                              node : PBinaryTreeNode) : PBinaryTreeNode; virtual;
      { inserts aitem at proper position in the tree; starts searching
        from node; returns the newly created node or nil if aitem could
        not be inserted }
      function InsertNode(aitem : ItemType;
                          node : PBinaryTreeNode) : PBinaryTreeNode; virtual;
      { exchanges the binary tree of self (FBinaryTree) with that of
        <tree> }
      procedure ExchangeBinaryTrees(tree : TBinarySearchTreeBase);
   public
      { deletes all items and deallocates any allocated memory }
      destructor Destroy; override;
      function Start : TSetIterator; override;
      function Finish : TSetIterator; override;
&if (&_mcp_accepts_nil)
      function FindOrInsert(aitem : ItemType) : ItemType; override;      
      function Find(aitem : ItemType) : ItemType; override;
&endif &# end &_mcp_accepts_nil
      function Has(aitem : ItemType) : Boolean; override;	
      function Count(aitem : ItemType) : SizeType; override;
      function Insert(aitem : ItemType) : Boolean; overload; override;
      function Insert(pos : TSetIterator;
                      aitem : ItemType) : Boolean; overload; override; 
      { removes the item at pos from the set; pos should be advanced
        to the next position }
      {@decl procedure Delete(pos : TSetIterator); override; overload; }
      { returns the first item >= aitem, or Finish if container is
        empty }
      function LowerBound(aitem : ItemType) : TSetIterator; override;
      { returns the first item > aitem, or Finish if container is empty }
      function UpperBound(aitem : ItemType) : TSetIterator; override;
      { returns a range <LowerBound, UpperBound), works faster than
        calling these two functions separately }
      function EqualRange(aitem : ItemType) : TSetIteratorRange; override;
      procedure Clear; override;
      function Empty : Boolean; override;
      function Size : SizeType; override;
      { returns the binary tree by means of which this container is
        implemented }
      property BinaryTree : TBinaryTree read FBinaryTree;
   end;   
   
   TBinarySearchTreeBaseIterator = class (TSetIterator)
   private
      FNode : PBinaryTreeNode;
      FTree : TBinarySearchTreeBase;
      
      procedure GoToStartNode;
   public
      constructor Create(anode : PBinaryTreeNode; tree : TBinarySearchTreeBase);
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
      procedure SetItem(aitem : ItemType); override;
      procedure ResetItem; override;
      procedure Advance; overload; override; 
      procedure Retreat; override;
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      function IsStart : Boolean; override;
      function IsFinish : Boolean; override;
      function Owner : TContainerAdt; override;
      
      property Node : PBinaryTreeNode read FNode write FNode;
   end;
   
{ ============================ TBinarySearchTree ============================= }
   
   { implements a set using the ordinary binary search tree;
     guarantees average O(log(n)) time for all set operations }
   TBinarySearchTree = class (TBinarySearchTreeBase)
   public
      { creates a binary search tree }
      constructor Create; overload;
      { creates a copy of cont; uses itemCopier to copy items }
      constructor CreateCopy(const cont : TBinarySearchTree;
                             const itemCopier : IUnaryFunctor); overload;
      { returns a copy of self }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;      
      { returns the iterator pointing at the first item with the key
        equal to that of aitem, or nil if not found; @complexity average
        O(log(n)), worst case O(n). }
      {@decl function Find(aitem : ItemType) : ItemType; override; }
      { returns the number of items in the set equal to aitem;
        @complexity average O(log(n)), worst case O(n) }
      {@decl function Count(aitem : ItemType) : SizeType; override; }
      { inserts aitem into the set; returns true if self was inserted,
        or false if it cannot be inserted (this happens for non-multi
        (without repeated items) set when item equal to aitem is already
        in the set); @complexity average O(log(n)), worst case O(n). }
      {@decl function Insert(aitem : ItemType) : Boolean; override; overload; }
      { the same as above, but uses pos as a hint where to insert;
        @complexity average O(log(n)), worst case O(n). }
      {@decl function Insert(pos : TSetIterator;
                      aitem : ItemType) : Boolean; override; overload; }
      { removes all items equal to aitem from the set; returns the
        number of deleted items; @complexity average O(m*log(n)),
        where m is the number of deleted items, worst case O(n) }
      function Delete(aitem : ItemType) : SizeType; overload; override; 
      { removes the item at pos from the set }
      procedure Delete(pos : TSetIterator); overload; override; 
      { returns the first item >= aitem, or Finish if container is
        empty; @complexity average O(log(n)), worst case O(n).}
      {@decl function LowerBound(aitem : ItemType) : TSetIterator; override; }
      { returns the first item > aitem, or Finish if container is empty;
        @complexity average O(log(n)), worst case O(n). }
      {@decl function UpperBound(aitem : ItemType) : TSetIterator; override; }
      { returns a range <LowerBound, UpperBound), works faster than
        calling these two functions separately; @complexity average
        O(log(n)), worst case O(n). }
      {@decl function EqualRange(aitem : ItemType) : TSetIteratorRange; override; }
   end;
   
