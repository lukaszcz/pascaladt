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
 adtiters.inc::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtiters.defs

type
   { a base class for all iterators; implements the registering of
     iterators within their parents' grabage collectors, and a few
     other basic things }
   TIterator = class
   private
      handle : TCollectorObjectHandle;
      
   protected
      { the argument should be the object that is going to own the
        iterator }
      {$warnings off }
      constructor Create(OwnerObject : TContainerAdt);
      {$warnings on }
      { exchanges self with iter using only general virtual methods }
      procedure DoExchangeItem(iter : TIterator);
      
   public
      destructor Destroy; override;
      { returns an exact copy of <self>; i.e. copies all the data }
      function CopySelf : TIterator; virtual; abstract;
      { returns true if <self> and <pos> both point to the same item
        in the same collection; it is assumed that pos.Owner =
        self.Owner and not subsequently checked. It is an error to
        pass such an iterator <pos> to this function that pos.Owner <>
        self.Owner; @see Owner }
      function Equal(const Pos : TIterator) : Boolean; virtual; abstract;
      { returns the item from the position pointed by self }
      function GetItem : ItemType; virtual; abstract;
      { assigns <ptr> to the item at the position pointed by the
        iterator; @see TContainerAdt.IsDefinedOrder,
        TDefinedOrderIterator, TSetIterator, TMapIterator }
      procedure SetItem(aitem : ItemType); virtual; abstract;
      { exchanges the item pointed to by <self> with the one pointed
        to by the argument; @see TContainerAdt.IsDefinedOrder,
        TDefinedOrderIterator, TSetIterator, TMapIterator }
      procedure ExchangeItem(iter : TIterator); virtual; abstract;
      { returns the container into which self points }
      function Owner : TContainerAdt; virtual; abstract;

      property Item : ItemType read GetItem write SetItem;
   end;
   
   { an iterator into a sequence allowing to write items into the
     sequence }
   TOutputIterator = class (TIterator)
      { if self is valid then _overwrites_ the current item with aitem
        and advances; if self is finish then inserts aitem before the
        current position (i.e. at the back) and stays where it is }
      procedure Write(aitem : ItemType); virtual; abstract;
   end;
   
   { an iterator into a sequence of items allowing to move forward }
   TForwardIterator = class (TOutputIterator)
   public
      { Goes one position forward. The second declaration only for
        compilers that do not support
        overloading. @include-declarations 2 }
{$ifdef OVERLOAD_DIRECTIVE }
      procedure Advance; overload; virtual; abstract;
{$else }
      procedure AdvanceOnePosition; virtual; abstract;
{$endif OVERLOAD_DIRECTIVE }
      { inserts before (at) the position where self points. Makes self
        point at the newly inserted item. invalidates all other
        iterators (in genereal) @see TContainerAdt.IsDefinedOrder,
        TSetIterator }
      procedure Insert(aitem : ItemType); overload; virtual; abstract;
      { the same as @<Delete> but returns the item instead of
        disposing it }
      function Extract : ItemType; virtual; abstract;
      { deletes the item to which self points and advances self to the
        next position. invalidates all other iterators (in general);
        implemented using Extract; @see TContainerAdt.IsDefinedOrder,
        TSetIterator }
      procedure Delete; overload;
      {$ifdef INLINE_DIRECTIVE }
      inline;
      {$endif }
      { deletes all items from the range [self, finish); after the
        deletion the iterator points to finish; invalidates all other
        iterators (in general); returns the number of items deleted;
        after the deletion the iterator points to finish; the default
        implementation uses only abstract methods and traverses the
        range twice. This may be a bit inefficient, so this is
        re-implemented by some containers. @complexity O(n)
        invocations of Delete(); }
      function Delete(finish : TForwardIterator) :
         SizeType; overload; virtual;
      { returns true if self is the first iterator }
      function IsStart : Boolean; virtual; abstract;
      { returns true if self is the 'one beyond last' iterator }
      function IsFinish : Boolean; virtual; abstract;
      
      { implements this procedure using Insert, Advance and SetItem }
      procedure Write(aitem : ItemType); override;
   end;
   
   { an iterator into a sequence of items allowing to move forward and
     backward }
   TBidirectionalIterator = class (TForwardIterator)
   public
      { goes back one position }
      procedure Retreat; virtual; abstract;
   end;
   
   { an iterator into a sequence of items allowing random access }
   TRandomAccessIterator = class (TBidirectionalIterator)
   public
      { returns the item at index self.Index + i (i may be negative) }
      function GetItemAt(i : IndexType) : ItemType; virtual; abstract;
      { sets the item at index self.Index + i }
      procedure SetItemAt(i : IndexType; aitem : ItemType); virtual; abstract;
      { exchanges items at positions i and j relative to self }
      procedure ExchangeItemsAt(i, j : IndexType); virtual; abstract;
      { this method is overriden to be equivalent to Advance(-1) }
      procedure Retreat; override;
      { this method is overriden to be equivalent to Advance(1) }
{$ifdef OVERLOAD_DIRECTIVE }
      procedure Advance; overload; override;
{$else }
      procedure AdvanceOnePosition; override;
{$endif OVERLOAD_DIRECTIVE }    
      { moves self by i positions }
      procedure Advance(i : IndexType);
{$ifdef OVERLOAD_DIRECTIVE }
      overload;
{$endif OVERLOAD_DIRECTIVE }
      virtual; abstract;
      { deletes items from the range [self, finish); after the
        deletion the iterator points to finish; invalidates all other
        iterators (in general); returns the number of items deleted;
        @complexity at best O(n) }
      function Delete(finish : TForwardIterator) :
         SizeType; overload; override;
      { deletes at most n items beginning with start, less if the end
        of the container is reached; returns the number of items
        actually deleted; after the deletion self points to the first
        item after the deleted sequence; @complexity at best O(n) }
      function Delete(n : SizeType) : SizeType; overload; virtual; abstract;
      { computes the distance between pos and self (pos - self) -
        i.e. by how much you have to advance self to get to pos }
      function Distance(const Pos : TRandomAccessIterator)
         : IndexType; virtual; abstract;
      { returns true if self is closer to the beginning of the
        collection than pos }
      function Less(const Pos : TRandomAccessIterator)
         : Boolean; virtual; abstract;
      { returns the index of the iterator within the container into
        which it points }
      function Index : IndexType; virtual; abstract;
      property Items[ind : IndexType] : ItemType read GetItemAt
                                           write SetItemAt; default;
   end;
   
(*   { an iterator into a string }   
   TStringIterator = class (TRandomAccessIterator)
   public
      { returns the character from the position pointed by self }
      function GetChar : CharType; virtual; abstract;
      { sets the character at the position pointed to by the iterator
        to aitem }
      procedure SetChar(c : CharType); virtual; abstract;
      
      { returns the item from the position pointed by self }
      function GetItem : ItemType; override;
      { sets the item at the position pointed to by the iterator to aitem }
      procedure SetItem(aitem : ItemType); override;
   end; *)
   
   { ----------------- TDefinedOrderIterator -------------- }
   
   { an iterator into a defined-order container; the container may be
     a set, a map, a priority queue or anything with a fixed, internal
     order of items. Syntatically, TDefinedOrderIterator is the same
     as @<TBidirectionalIterator>, but most of the modifying methods
     work differently as it points into a container with a defined
     order of items; @<ExchangeItem> raises an exception -
     @<EDefinedOrder>; @<Insert> does not insert before a position,
     but at the proper place in the container and moves to the newly
     inserted item or to finish if the item could not be
     inserted. @<SetItem> works like @<Delete> + @<Insert>. If the
     item returned by @<GetItem> (or the @<Item> property) is changed
     in a way that changes its place in the container (i.e you the key
     or whatever your comparison functor uses is changed), then
     @<ResetItem> should be called immediately. Other methods work as
     usual. }
   { Note that it is possible to use iterator of this type with many
     PascalAdt algorithms (and that's why it inherits from
     @<TBidirectionalIterator>, although it violates some of its
     method specifications). However, you should always make sure that
     the algorithm is not marked as a
     non-definded-order-iterator-only-algorithm.  }
   { @see TContainerAdt.IsDefinedOrder, TDefinedOrderContainerAdt,
     TSetIterator, TMapIterator }
   TDefinedOrderIterator = class (TBidirectionalIterator)
   public
      { raises @<EDefinedOrder> }
      procedure ExchangeItem(iter : TIterator); override;
      { inserts <ptr> at a proper place in the container and moves to
        the newly inserted item, or to finish if the item could not be
        inserted.  }
      {@decl procedure Insert(aitem : ItemType); overload; virtual; abstract; }
      { assigns <ptr> to the item at the position pointed by the
        iterator; calls @<ResetItem> automatically; }
      {@decl procedure SetItem(aitem : ItemType); virtual; abstract; }
      { returns the item from the position pointed by self; if you
        change the returned item in such a way that its key/order
        within the container is changed, then you have to call
        @<ResetItem> before attempting to use the container or the
        iterator; @see ResetItem }
      {@decl function GetItem : ItemType; virtual; abstract; }
      { moves the current item to its proper place in the container,
        if its not already in its proper place; this should be called
        whenever any operation changes an item returned by GetItem in
        such a way that its key/priority/order within container is
        changed; if you change the key of an item returned by GetItem
        and not call this method, then the behaviour is undefined;
        moves the iterator so that it still points to the item,
        although the item changes its position; note that due to this
        behaviour you may miss visiting some items or visit some
        others twice; @see GetItem, Extract }
      procedure ResetItem; virtual; abstract;
      { removes the item at the current position from the container
        and returns it; the iterator is moved either to the
        _beginning_ of the container or to the next item; this because
        the container probably has to be reorganised after deletion to
        keep the order of items, and thus it may not always be
        possible, in general, to find such a position from which the
        iteration through the items could be continued without
        visiting any already visited items and still visiting all
        items not yet visited; @see ResetItem }
      {@decl function Extract : ItemType; virtual; abstract;  }
      { the same as @<Extract>, but deletes the item instead of
        returning it }
      {@decl procedure Delete; }
      {@decl property Item : ItemType read GetItem write SetItem; }
   end;
   
   { ---------------- set iterator ---------------------- }
   
   { an iterator into a set; it differs from the
     @<TDefinedOrderIterator> only in that it specifies the behaviour
     of several methods more precisely; }
   TSetIterator = class (TDefinedOrderIterator)
   public
      { removes the item at the current position from the container
        and returns it; the iterator is moved to the next position,
        and iterating may be continued without missing any items or
        visiting any items twice }
      {@decl function Extract : ItemType; virtual; abstract;  }
      { the same as @<Extract>, but deletes the item instead of
        returning it }
      {@decl procedure Delete; }
   end;
   
   { ---------------- tree iterators -------------------- }
   TBasicTreeIterator = class;
   
   TTreeTraversalIterator = class (TBidirectionalIterator)
   public
      { moves the iterator to the first node in its owner tree,
        according to the traversal order for the iterator }
      procedure StartTraversal; virtual; abstract;
      { returns a normal tree iterator pointing to the same item as
        self }
      function TreeIterator : TBasicTreeIterator; virtual; abstract;
      
      { implements these methods using TreeIterator }
      function Equal(const Pos : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
      procedure SetItem(aitem : ItemType); override;
      procedure ExchangeItem(iter : TIterator); override;
      function Owner : TContainerAdt; override;
      function IsFinish : Boolean; override;
   end;

   TPreOrderIterator = class (TTreeTraversalIterator)
   end;

   TPostOrderIterator = class (TTreeTraversalIterator)
   end;

   TInOrderIterator = class (TTreeTraversalIterator)
   end;
   
   { TLevelOrderIterator is derived from TTreeTraversalIterator and
     indirectly from TBidirectionalIterator instead of directly from
     TForwardIterator in order to provide it with an interface common
     with other traversal iterators. However, it's highly inefficient
     to use its Retreat method - it takes an O(n) time (one step). }
   TLevelOrderIterator = class (TTreeTraversalIterator)
   end;
   
   { a generic tree iterator interface, a base class for all tree iterators }
   TBasicTreeIterator = class (TIterator)
   public
      { moves the iterator to point at its parent }
      procedure GoToParent; virtual; abstract;
      { deletes the item pointed by self together with its
        sub-tree. Moves self to its parent. If self is already the
        root it becomes invalid, equal to Finish. returns the number
        of items deleted; }
      function DeleteSubTree : SizeType; virtual; abstract;
      { returns the number of nodes (items) in the subtree of self
        (self included) }
      function SubTreeSize : SizeType; virtual; abstract;
      { returns a pre-order iterator pointing at the same item as self }
      function PreOrderIterator : TPreOrderIterator; virtual; abstract;
      { returns a post-order iterator pointing at the same item as self }
      function PostOrderIterator : TPostOrderIterator; virtual; abstract;
      { returns an in-order iterator pointing at the same item as self }
      function InOrderIterator : TInOrderIterator; virtual; abstract;
      { returns true if the iterator points to a leaf }
      function IsLeaf : Boolean; virtual; abstract;
      { returns true if the iterator points to the root }
      function IsRoot : Boolean; virtual; abstract;
   end;   
   
   { -------- concrete classes -------- }
   
   TReverseIterator = class (TBidirectionalIterator)
   private
      FIter : TBidirectionalIterator;
   public
      constructor Create(const iter : TBidirectionalIterator);
      { returns an exact copy of self; }
      function CopySelf : TIterator; override;
      { returns true if self and pos both point to the same item in
        the same collection }
      function Equal(const Pos : TIterator) : Boolean; override;
      { returns the item from the position pointed by self }
      function GetItem : ItemType; override;
      { sets the Item at the position pointed to by the iterator to
        aitem; }
      procedure SetItem(aitem : ItemType); override;
      { goes one position forward }
{$ifdef OVERLOAD_DIRECTIVE }
      procedure Advance; overload; override;
{$else }
      procedure AdvanceOnePosition; override;      
{$endif OVERLOAD_DIRECTIVE }
      { moves iter one position back }
      procedure Retreat; override;
      { exchanges Items pointed by the iterators }
      procedure ExchangeItem(iter : TIterator); override;
      { inserts aitem into the container; after insertion the iterator
        points to the same index }
      procedure Insert(aitem : ItemType); override;
      { the same as @<Delete> but returns the item instead of
        disposing it }
      function Extract : ItemType; override;
      { deletes items from the range [self, finish); }
      function Delete(finish : TForwardIterator) : SizeType; overload; override;
      { returns the container into which self points }
      function Owner : TContainerAdt; override;
      { Returns the underlying iterator. }
      function GetIterator : TBidirectionalIterator;
      { returns true if self is the first iterator }
      function IsStart : Boolean; override;
      { returns true if self is the 'one beyond last' iterator }
      function IsFinish : Boolean; override;
   end;
   
   { a pair of forward iterators; used mostly to return ranges or
     pairs; @see TSetIteratorRange, TMapIteratorRange }
   TForwardIteratorRange = class
   private
      FStart, FFinish : TForwardIterator;
      owner : TContainerAdt;
      handle : TCollectorObjectHandle;
   public 
      constructor Create(starti, finishi : TForwardIterator);
      { unregisters self from grabage collector; does _not_ destroy
        Start or Finish }
      destructor Destroy; override;
      { returns the start of the range }
      property Start : TForwardIterator read FStart;
      { returns the finish of the range (the one-beyond last iterator) }
      property Finish : TForwardIterator read FFinish;
      property First : TForwardIterator read FStart;
      property Second : TForwardIterator read FFinish;     
   end;
   { the same as TForwardIteratorRange, but the iterators do not
     necessarily denote a range }
   T&_mcp_prefix&ForwardIteratorPair = TForwardIteratorRange;
   
   { a pair of two set iterators; used frequently in connection with
     sets; an object of this class is owned by the container which is
     the owner of Start and is destroyed automatically (so you do not
     have to bother); however, Start and Finish are not owned by the
     object (as they are already owned by their 'parent'
     containers). @see TForwardIteratorRange, TMapIteratorRange }
   TSetIteratorRange = class
   private
      FStart, FFinish : TSetIterator;
      owner : TContainerAdt;
      handle : TCollectorObjectHandle;
      
   public
      constructor Create(starti, finishi : TSetIterator);
      { unregisters self from grabage collector; does _not_ destroy
        Start or Finish }
      destructor Destroy; override;
      { returns the start of the range }
      property Start : TSetIterator read FStart;
      { returns the finish of the range (the one-beyond last iterator) }
      property Finish : TSetIterator read FFinish;
      property First : TSetIterator read FStart;
      property Second : TSetIterator read FFinish;
   end;
   T&_mcp_prefix&SetIteratorPair = TSetIteratorRange;

{ tests if pos1 is nearer to the beginning of the container than pos2 }
function Less(const pos1, pos2 : TRandomAccessIterator) : Boolean; overload;
function Less(const pos1, pos2 : TForwardIterator) : Boolean; overload;

{ increments iter by step, either by invoking Advance method
  appropriate number of times or using the member routine (if iter is
  TRandomAccessIterator); returns iter (_not_ a copy of it);
  @complexity O(1) if iter is TRandomAccessIterator, O(n) otherwise }
function Advance(iter : TForwardIterator;
                 step : IndexType) : TForwardIterator; overload;
function Advance(iter : TRandomAccessIterator;
                 step : IndexType) : TRandomAccessIterator; overload;

{ decrements an iterator. @until-next-comment }
function Retreat(iter : TBidirectionalIterator;
                 step : IndexType) : TBidirectionalIterator; overload;
function Retreat(iter : TRandomAccessIterator;
                 step : IndexType) : TRandomAccessIterator; overload;

{ handy functions to copy iterators. @until-next-comment }
{$ifdef OVERLOAD_DIRECTIVE }
function CopyOf(const iter : TIterator) : TIterator; overload;
function CopyOf(const iter : TForwardIterator) : TForwardIterator; overload;
function CopyOf(const iter : TBidirectionalIterator) :
   TBidirectionalIterator; overload;
function CopyOf(const iter : TRandomAccessIterator) :
   TRandomAccessIterator; overload;
function CopyOf(const iter : TBasicTreeIterator) : TBasicTreeIterator; overload;
function CopyOf(const iter : TTreeTraversalIterator) :
   TTreeTraversalIterator; overload;
function CopyOf(const iter : TPreOrderIterator) : TPreOrderIterator; overload;
function CopyOf(const iter : TPostOrderIterator) : TPostOrderIterator; overload;
function CopyOf(const iter : TInOrderIterator) : TInOrderIterator; overload;
function CopyOf(const iter : TLevelOrderIterator) : TLevelOrderIterator; overload;
function CopyOf(const iter : TDefinedOrderIterator) :
   TDefinedOrderIterator; overload;
function CopyOf(const iter : TSetIterator) : TSetIterator; overload;
function CopyOf(const iter : TReverseIterator) : TReverseIterator; overload;

{ returns an iterator to the next item in the collection. The returned
  iterator is a copy. The old one remains
  unchanged. @until-next-comment }
function Next(const iter : TForwardIterator)
   : TForwardIterator; overload;
function Next(const iter : TBidirectionalIterator)
   : TBidirectionalIterator; overload;
function Next(const iter : TRandomAccessIterator)
   : TRandomAccessIterator; overload;
function Next(const iter : TRandomAccessIterator; i : IndexType)
   : TRandomAccessIterator; overload;

{ returns an iterator to the previous item in the collection @until-next-comment }
function Prev(const iter : TBidirectionalIterator)
   : TBidirectionalIterator; overload;
function Prev(const iter : TRandomAccessIterator)
   : TRandomAccessIterator; overload;
{$endif OVERLOAD_DIRECTIVE }

{ returns the distance between two iterators. The second iterator must
  be reachable from the first one }
function Distance(const iter1, iter2 : TForwardIterator) : IndexType;
{$ifdef OVERLOAD_DIRECTIVE }
overload;

function Distance(const iter1, iter2 : TRandomAccessIterator)
   : IndexType; overload;
{$endif OVERLOAD_DIRECTIVE }

{ returns the iterator pointing to the next node according to preorder
  traversal order }
function PreOrder(const node : TPreOrderIterator) : TPreOrderIterator;

{ returns the iterator to the next node according to postorder traversal order }
function PostOrder(const node : TPostOrderIterator) : TPostOrderIterator;

{ returns the iterator to the next node according to inorder traversal order }
function InOrder(const node : TInOrderIterator) : TInOrderIterator;

{ returns the iterator to the next node according to levelorder traversal order }
function LevelOrder(const node : TLevelOrderIterator) : TLevelOrderIterator;

{ ---------------------- debugging routines --------------------------- }

{ checks if the iterators represent a valid range; if in debug mode
  then simply performs some rudimentary O(1) checks; if in test mode
  then checks the whole range (O(n)) }
procedure CheckIteratorRange(start, finish : TForwardIterator);

