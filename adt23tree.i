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
 adt23tree.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adt23tree.defs

type
   P23TreeNode = ^T23TreeNode;
   T23TreeNode = record
      Parent : P23TreeNode;
      Child : array[1..3] of P23TreeNode;
      LowItem : array[2..3] of ItemType;
      StoredItems : 1..2; { the number of items stored in the LowItem
                            array }
   end;
   
   { 2-3 tree is a data structure that provides all set operations
     with worst-case O(log(n)) time; however, the complicated
     implementation of the methods (and thus large constant factors)
     make splay trees or AVL-trees better choices for ordinary usage
     as a set; nevertheless, 2-3 trees support the additional
     Concatenate and Split operations which make it possible to use
     them also as concatenable priority queues. }
   T23Tree = class (TConcatenableSortedSetAdt)
   private
      FRoot : P23TreeNode;
      FHeight, FSize : SizeType;
      FValidSize : Boolean;
      LowestItem : ItemType; { the lowest item in the tree }
      
      { creates a copy of tree, but without any items; i.e. copies
        only the inherited fields and initializes the rest to default
        values }
      {$warnings off }
      constructor CreateCopyWithoutItems(const tree : T23Tree);
      {$warnings on }
      { performs initialization; called from constructors }
      procedure InitFields;
      { deletes the whole sub-tree of node (including node) }
      procedure DeleteSubTree(node : P23TreeNode);
      { advances pair (node,low) to next item }
      procedure AdvanceNode(var node : P23TreeNode; var low : Integer);
      { retreats pair (node,low) to previous item; does not accept (nil,1) }
      procedure RetreatNode(var node : P23TreeNode; var low : Integer);
      { finds a node containing aitem; starts searching from node; if
        aitem is found then assigns the node which contains it to found
        and assigns the number of LowItem that contains aitem to low and
        returns true; if not found assigns the parent of the place
        where aitem should be inserted to found and the number of child
        _after_ which aitem should be inserted to low and returns false;
        if aitem was not found and should be inserted before LowestItem
        then assigns nil to inserted, 1 to low and returns false }
      function FindNode(aitem : ItemType; startNode : P23TreeNode;
                        var found : P23TreeNode; var low : Integer) : Boolean;
      { assigns to (lb,low) the first position >= aitem; returns true if
        the returned position = aitem, otherwise false }
      function LowerBoundNode(aitem : ItemType; node : P23TreeNode;
                              var lb : P23TreeNode;
                              var low : Integer) : Boolean;
      { inserts node after the cnum-th child of parent; aitem is the
        lowest (logically) item in the sub-tree of node; assigns
        inserted the node which will in the end contain aitem and
        assigns low the number of LowItem where aitem will be stored;
        parent and aitem cannot be nil, node may be; lowptr cannot be
        smaller than LowestItem; maintains FHeight, but not FSize }
      procedure InsertNode(parent : P23TreeNode; cnum : Integer;
                           aitem : ItemType; node : P23TreeNode;
                           var inserted : P23TreeNode; var low : Integer);
      { inserts aitem into the sub-tree of node; inserted is assigned
        the node containing newly inserted item; low is the number of
        LowItem in that node containing aitem; returns true if aitem was
        actually inserted, false if it could not be inserted (in such
        case sets inserted to nil and low to 0) }
      function DoInsert(aitem : ItemType; node : P23TreeNode;
                          var inserted : P23TreeNode;
                          var low : Integer) : Boolean;
      { deletes (nnode,low); reorganises internal structure of the
        tree if needed; iterators (and pointers to nodes) are
        invalidated }
      function DeleteNode(nnode : P23TreeNode; low : Integer) : ItemType;
      { concatenates sub-trees of node1 and node2 and assigns the new
        tree to self; every item in the subtree of node1 must be
        smaller or equal to every item in the subtree of node2 or the
        other way round; self must be empty or be one of the sub-trees
        of node1 or node2; items are not copied, so node1 and node2
        should be previously disconnected from any structures they are
        parts of }
      procedure Implant(node1, node2 : P23TreeNode;
                        lowitem1, lowitem2 : ItemType;
                        height1, height2 : SizeType);
      { allocates new node using Allocator and assigns it to node }
      procedure NewNode(var node : P23TreeNode);
      { deallocates node using Allocator }
      procedure DisposeNode(var node : P23TreeNode);
      
   protected
      
   public
      constructor Create;
      { creates a copy of cont; itemCopier may be nil only if cont is
        empty; @complexity O(n) }
      constructor CreateCopy(const cont : T23Tree;
                             const itemCopier : IUnaryFunctor); overload;
      { destroys the tree }
      destructor Destroy; override;
      
{$ifdef TEST_PASCAL_ADT }
      procedure LogStatus(mName : String); override;
{$endif TEST_PASCAL_ADT }

      { returns a copy of self; @complexity O(n) }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { returns the start iterator }
      function Start : TSetIterator; override;
      { returns the finish iterator }
      function Finish : TSetIterator; override;
&if (&_mcp_accepts_nil)
      { if RepeatedItems is false and there is an item equal to aitem in
        the set, then returns this item; in all other cases inserts
        aitem into the set and returns nil; @complexity worst-case
        O(log(n)) }
      function FindOrInsert(aitem : ItemType) : ItemType; override;
      { returns the first item equal to aitem, or nil if not found; if
        you need an iterator to that item use LowerBound or EqualRange
        instead; @complexity worst-case O(log(n)) }
      function Find(aitem : ItemType) : ItemType; override;
&endif &# end &_mcp_accepts_nil
      { returns true if the given item is present in the set;
        @complexity worst-case O(log(n)) }
      function Has(aitem : ItemType) : Boolean; override;
      { returns the number of items in the set equal to aitem;
        @complexity worst-case O(log(n)) }
      function Count(aitem : ItemType) : SizeType; override;
      { the same as below, but uses pos as a hint where to insert;
        @complexity worst-case O(n) if you give a wrong hint, usually
        O(1) if aitem is to be inserted just before/after pos }
      function Insert(pos : TSetIterator;
                      aitem : ItemType) : Boolean; overload; override; 
      { inserts aitem into the set; returns true if self was inserted,
        or false if it cannot be inserted (this happens for non-multi
        (without repeated items) set when item equal to aitem is already
        in the set); if the item is not inserted it is not owned by
        the container and not disposed! @complexity worst-case
        O(log(n)) }
      function Insert(aitem : ItemType) : Boolean; overload; override; 
      { removes the item at pos from the set; @complexity worst-case
        O(log(n)) }
      procedure Delete(pos : TSetIterator); overload; override; 
      { removes all items equal to aitem from the set; returns the
        number of deleted items; @complexity worst-case O(m*log(n)),
        where m is the number of deleted items }
      function Delete(aitem : ItemType) : SizeType; overload; override; 
      { returns the first item >= aitem, or Finish if container is empty
        (for TSortedSetAdt); @complexity worst-case O(log(n)) }
      function LowerBound(aitem : ItemType) : TSetIterator; override;
      { returns the first item > aitem, or Finish if container is empty
        (for TSortedSetAdt); @complexity worst-case O(log(n)) }
      function UpperBound(aitem : ItemType) : TSetIterator; override;
      { returns a range <LowerBound, UpperBound), works faster than
        calling these two functions separately; @complexity worst-case
        O(log(n)) }
      function EqualRange(aitem : ItemType) : TSetIteratorRange; override;
      { returns the first item according to ItemComparer }
      function First : ItemType; override;
      { removes the first item from the tree and returns it; @complexity worst-case
        O(log(n)); @see DeleteFirst }
      function ExtractFirst : ItemType; override;
      { concatenates aset with self; every item in one of the
        concatenated sets must be larger than or equal to every item
        in the other one; aset is destroyed; @complexity worst-case
        O(log(n)) }
      procedure Concatenate(aset : TConcatenableSortedSetAdt); override;
      { splits itself into two trees according to the item aitem; every
        item smaller than or equal to aitem is left in the original
        tree, and every item larger than aitem goes to the newly created
        tree which is returned by this function; @complexity
        worst-case O(log(n)) }
      function Split(aitem : ItemType) : TConcatenableSortedSetAdt; override;
      { clears the container - removes all items; @complexity O(n). }
      procedure Clear; override;
      { returns true if container is empty; equivalent to Size = 0,
        but may be faster }
      function Empty : Boolean; override;
      { returns number of items; @complexity O(n) }
      function Size : SizeType; override;
      
      { @impl-inv Empty <=> FSize = 0 and FValidSize }
   end;
   
   T23TreeIterator = class (TSetIterator)
   private
      FNode : P23TreeNode;
      FTree : T23Tree;
      FLow : Integer;
      
      procedure GoToStartNode;
      
   public
      constructor Create(anode : P23TreeNode; low : Integer; tree : T23Tree);
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
      procedure SetItem(aitem : ItemType); override;
      procedure ResetItem; override;
      procedure Advance; overload; override; 
      procedure Retreat; override;
      { @fetch-related }
      { @complexity worst-case O(log(n)) }
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      function Owner : TContainerAdt; override;
      function IsStart : Boolean; override;
      function IsFinish : Boolean; override;
   end;
   
