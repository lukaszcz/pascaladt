{@discard
  
   This file is a part of the PascalAdt library, which provides
   commonly used algorithms and data structures for the FPC and Delphi
   compilers.
   
   Copyright (C) 2004, 2005 by Lukasz Czajka
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   as published by the Free Software Foundation; either version 2.1 of
   the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
   02110-1301 USA }

{@discard
 adtcont.inc::prefix=&_mcp_prefix&::item_type=&ItemType&
}

&include adtcont.defs

type
   { if a class inherits from TDefinedOrderContainerAdt it implies
     that it has an internally defined order of items, but it's not
     the other way round; i.e. every class inheriting from this is
     defined-order, but there may be some defined-order class that
     does not inherit from this one; @see TContainerAdt.IsDefinedOrder
     }
   TDefinedOrderContainerAdt = class (TContainerAdt)
   public
      { returns true; @see TContainerAdt.IsDefinedOrder }
      function IsDefinedOrder : Boolean; override;
   end;
   
   { An abstract interface of a priority queue. }
   TPriorityQueueAdt = class (TContainerAdt)
   private
      FComparer : IBinaryComparer;
   protected
      {$warnings off }
      constructor Create; overload;
      constructor CreateCopy(const cont : TPriorityQueueAdt); overload;
      {$warnings on }
   public
      { adds an item to the priority queue }
      procedure Insert(aitem : ItemType); virtual; abstract;
      { returns the item with the highest priority, i.e. the one that
        comes first in the chain of comparisons, e.g. if you use
        integers as items and < as comparison this would be actually
        the smallest integer in the queue. }
      function First : ItemType; virtual; abstract;
      { removes the item with the highest priority, i.e. the one that
        comes first in the chain of comparisons, e.g. if you use
        integers as items and < as comparison this would be actually
        the smallest integer in the queue. Returns the removed
        item. @see DeleteFirst }
      function  ExtractFirst : ItemType; virtual; abstract;
      { the same as @<ExtractFirst>, but deletes the item instead of
        returning it }
      procedure DeleteFirst;
      { merges <self> and <aqueue> into one priority queue; <self> and
        <aqueue> must be of the same concrete type; no restriction on
        the items in <self> or <aqueue> is imposed; <aqueue> is
        _destroyed_; @complexity guaranteed O(n), but not worse than
        O(log(n)) for most implementations; @see
        TConcatenableSortedSetAdt,
        TConcatenableSortedSetAdt.Concatenate; }
      procedure Merge(aqueue : TPriorityQueueAdt); virtual; abstract;
      { returns the comparer used to compare items }
      property ItemComparer : IBinaryComparer read FComparer write FComparer;
      
      { inserts <aitem> somewhere into the container; returns true if
        successful, false if <aitem> could not be inserted; implemented with
        Insert }
      function InsertItem(aitem : ItemType) : Boolean; override;
      { removes some item from the container and returns it; if there
        are no more items to extract then returns nil; implemented as
        First + DeleteFirst }
      function ExtractItem : ItemType; override;
      { @fetch-related }
      { implemented with not Empty }
      function CanExtract : Boolean; override;
      { returns true by default }
      function IsDefinedOrder : Boolean; override;
   end;
   
   
   { -------------------- associative containers ------------------------ }
   
   { represents a set or a multiset; items that are equal must be
     adjacent; remember that pointers given in arguments of methods
     are never disposed, unless they become owned by the set (i.e. are
     inserted into it); @<ItemComparer> needs not define an order of
     items, it only needs to return 0 when items are equal and
     non-zero if they are not (unless the container is also
     TSortedSet) }
   TSetAdt = class (TDefinedOrderContainerAdt)
   private
      FRepeatedItems : Boolean;
      FComparer : IBinaryComparer;
      
      procedure SetRepeatedItems(b : Boolean);
      procedure SetComparer(comp : IBinaryComparer);
   protected
      {$warnings off }
      constructor Create; overload;
      constructor CreateCopy(const cont : TSetAdt); overload;
      {$warnings on }

      procedure BasicSwap(cont : TContainerAdt); override;

   public         
      { returns true if the set needs a hasher to work; false by
        default; overriden in THashSetAdt; if you want to create a map
        from TSetAdt class reference and you don't know the actual
        type of the class, then you should always call this function
        to determine whether to provide a hasher or not; }
      class function NeedsHasher : Boolean; virtual;     
      
      { returns the start iterator }
      function Start : TSetIterator; virtual; abstract;
      { returns the finish iterator }
      function Finish : TSetIterator; virtual; abstract;
&if (&_mcp_accepts_nil)
      { if @<RepeatedItems> is false and there is an item equal to
        <aitem> in the set, then returns this item; in all other cases
        inserts <aitem> into the set and returns nil; this operation
        is needed only to make it possible to efficiently implement
        the @<Associate> operation in a map when using a set to
        implement a map; this is present only for TObject and Pointer
        generic specializations }
      function FindOrInsert(aitem : ItemType) : ItemType; virtual; abstract;
      { returns the first item equal to aitem, or nil if not found;
        This function is present only for TObject and Pointer generic
        specializations; if you need an iterator to that item use
        @<LowerBound> or @<EqualRange> instead }
      { @post Result <> nil <=> Has(aitem) }
      function Find(aitem : ItemType) : ItemType; virtual; abstract;
&endif &# end &_mcp_accepts_nil
      { returns true if the given item is present in the set; }
      { @post Result <=> aitem in self }
      function Has(aitem : ItemType) : Boolean; virtual; abstract;
      { returns the number of items in the set equal to <aitem> }
      { @post Result >= 0 }
      { @post Result <= Size }
      { @post not RepeatedItems implies Result <= 1 }
      { @post Has(aitem) implies Result >= 1 }
      function Count(aitem : ItemType) : SizeType; virtual; abstract;
      { the same as below, but uses pos as a hint where to insert
        (only in implementations where it makes sense) }
      function Insert(pos : TSetIterator;
                      aitem : ItemType) : Boolean; overload; virtual; abstract;
      { inserts <aitem> into the set; returns true if it was inserted,
        or false if it could not be inserted (this happens for a
        non-multi (without repeated items) set when an item equal to
        <aitem> is already in the set); if the item is not inserted it
        is not owned by the container and not disposed! }
      { @post Result <=> ((not old Find(aitem)) or RepeatedItems) }
      { @post Result implies Size = old Size + 1 }
      { @post Result implies Count(pos.Item) = old Count(old pos.Item) + 1 }
      function Insert(aitem : ItemType) : Boolean; overload; virtual; abstract;
      { removes the item at <pos> from the set }
      { @pre pos is valid and not pos.IsFinish }
      { @post Size = old Size - 1 }
      { @post Count(pos.Item) = old Count(old pos.Item) - 1 }
      procedure Delete(pos : TSetIterator); overload; virtual; abstract;
      { removes all items equal to <aitem> from the set; returns the
        number of deleted items }
      { @post Result = old Count(aitem)  }
      { @post Size = old Size - Result }
      { @post Count(aitem) = 0 }
      function Delete(aitem : ItemType) : SizeType; overload; virtual; abstract;
      { removes all items equal to <aitem> from the set, but does not
        dispose them; returns the number of items removed; }
      { @post Result = old Count(aitem)  }
      { @post Size = old Size - Result }
      { @post Count(aitem) = 0 }
      { @post No items disposed }
      function Extract(aitem : ItemType) : SizeType; virtual;
      { returns the first item >= aitem, or Finish if container is empty
        (for TSortedSetAdt); or returns the iterator starting the
        range of items equal to <aitem> (for any set) }
      { @post not Result.Equal(Finish) implies
              ((Result.Item = aitem and Prev(Result).Item <> aitem) or
               (Result.Item <> aitem and not Has(aitem)))  }
      { @post Result.Equal(Finish) implies not Has(aitem) }
      function LowerBound(aitem : ItemType) : TSetIterator; virtual; abstract;
      { returns the first item > aitem, or Finish if container is empty
        (for TSortedSetAdt); or returns the iterator that ends a range
        of items equal to <aitem> (for any set) }
      { @post Result.Equal(Finish) or Result.Item <> aitem }
      function UpperBound(aitem : ItemType) : TSetIterator; virtual; abstract;
      { returns the range <LowerBound, UpperBound), works faster than
        calling these two functions separately }
      { @post Result.First = LowerBound(aitem) }
      { @post Result.Second = UpperBound(aitem) }
      function EqualRange(aitem : ItemType) : TSetIteratorRange; virtual; abstract;
      { returns the functor used to compare the items }
      property ItemComparer : IBinaryComparer read FComparer write SetComparer;
      { returns true if multiple items with the same key (i.e. equal
        according to @<ItemComparer>) are allowed; false by default; }
      property RepeatedItems : Boolean read FRepeatedItems write SetRepeatedItems;
      
      { inserts <aitem> somewhere into the container; returns true if
        successful, false if <aitem> could not be inserted; implemented with
        Insert }
      function InsertItem(aitem : ItemType) : Boolean; override;
      { removes some item from the container and returns it;
        implemented as Start.Item + Delete(Start); }
      function ExtractItem : ItemType; override;
      { @fetch-related }
      { implemented with not Empty }
      function CanExtract : Boolean; override;
      
      
      { @inv not RepeatedItems implies foreach x in self holds
                                         not exists(y : y in self and x = y) }
      { @inv Empty <=> Start.Equal(Finish) }
   end;
   
   { a set or multiset with sorted item; any container inheriting from
     this must keep items in sorted order (defined by
     @<ItemComparer>); @see adtavltree.TAvlTree,
     adtsplaytree.TSplayTree, adt23tree.T23Tree }
   TSortedSetAdt = class (TSetAdt)
      { returns the item that comes first in the order defined in the
        set }
      { @pre not Empty }
      { @post foreach x in self holds Result <= x }
      function First : ItemType; virtual;
      { removes the first item from the sorted set and returns it }
      { @pre not Empty }
      { @post Size = old Size - 1 }
      { @post Result = old First }
      function ExtractFirst : ItemType; virtual;
      { the same as @<ExtractFirst>, but disposes the item instead of
        returning it }
      { @pre not Empty }
      { @post Size = old Size - 1 }
      procedure DeleteFirst;
      { returns the priority queue interface to the set; destroying
        the interface does not destroy the set; you have to destroy
        the interface and the set separately; do not confuse it with
        delphi interfaces, this is just an ordinary object that gives
        you access to a sorted set through the methods of a priority
        queue }
      function PriorityQueueInterface : TPriorityQueueAdt; virtual;
      
      { @inv self is sorted }
   end;
   
   { a sorted set that supports Concatenate and Split operations, so
     it can be used as a concatenable priority queue; @see adt23tree.T23Tree }
   TConcatenableSortedSetAdt = class (TSortedSetAdt)
      { concatenates aset with self; every item in one of the
        concatenated sets must be larger than or equal to every item
        in the other one; <aset> is _destroyed_ }
      { @pre aset <> nil }
      { @pre (foreach x, y : (x in aset and y in self) holds x <= y) or
             (foreach x, y : (x in self and y in aset) holds x <= y) }
      { @post foreach x : (x in old aset or x in old self) holds x in self }
      procedure Concatenate(aset : TConcatenableSortedSetAdt); virtual; abstract;
      { splits itself into two sets according to the item aitem; every
        item smaller than or equal to <aitem> is left in the original set,
        and every item larger than <aitem> goes to the newly created set
        which is returned by this function }
      { @post foreach x : (x in old self and x <= aitem) holds x in self }
      { @post foreach x : (x in old self and x > aitem) holds x in Result }
      function Split(aitem : ItemType) :
         TConcatenableSortedSetAdt; virtual; abstract;
   end;
   
   { a set that uses hashing; @see adthash }
   THashSetAdt = class (TSetAdt)
   private
      FHasher : IHasher;
      FAutoShrink : Boolean; { true if the table is shrunk automatically }
      
   protected
      
      {$warnings off }
      constructor Create; overload;
      constructor CreateCopy(const cont : THashSetAdt); overload;
      {$warnings on }
      
      procedure BasicSwap(cont : TContainerAdt); override;
      { by default calls Rehash }
      procedure SetCapacity(cap : SizeType); virtual;
      function GetCapacity : SizeType; virtual; abstract;
      { returns the capacity that should be used for table with
        approximately 2^ex; this simply converts FTableSize to
        FCapacity }
      function CalculateCapacity(ex : SizeType) : SizeType; virtual; abstract;
      function GetMaxFillRatio : SizeType; virtual; abstract;
      procedure SetMaxFillRatio(fr : SizeType); virtual; abstract;
      function GetMinFillRatio : SizeType; virtual; abstract;
      procedure SetMinFillRatio(fr : SizeType); virtual; abstract;
      
   public
{$ifdef TEST_PASCAL_ADT }
      procedure LogStatus(mname : String); override;
{$endif }
      { returns true }
      class function NeedsHasher : Boolean; override;
      
      { rehashes the set making it approximately 2^EX times larger
        (i.e. the capacity is increased (decreased)); ex may be
        negative, but the resulting capacity of the set cannot be less
        than its minimal allowed value. }
      { @pre Capacity * 2^ex >= MinCapacity }
      { @post Capacity = approx. old Capacity * 2^ex }
      procedure Rehash(ex : SizeType); virtual; abstract;
      { returns the minimal allowed capacity for the set }
      function MinCapacity : SizeType; virtual; abstract;
      { returns the hasher used to hash items }
      property Hasher : IHasher read FHasher write FHasher;
      { returns the capacity; in hash sets it is not necessarily the
        maximal number of items allowed, but rather the number of free
        buckets or slots or whatever that influences the performance
        of the set; when assigning to this property the set rehashes
        itself to have the capacity closest to the given value; }
      { @inv Capacity >= MinCapacity }
      property Capacity : SizeType read GetCapacity write SetCapacity;
      { maximal value of (Size/Capacity)*100%; the default is 80%;
        this shouldn't be less than 50% }
      { @inv MaxFillRatio >= 50% }
      property MaxFillRatio : SizeType read GetMaxFillRatio write SetMaxFillRatio;
      { the same as above, but minimal value; the default is 10%; this
        should be larger than MaxFillRatio/2 }
      { @inv MinFillRatio > MaxFillRatio/2 }
      property MinFillRatio : SizeType read GetMinFillRatio write SetMinFillRatio;
      { if true then the table's capacity is decreased by half each
        time Size/Capacity goes below MinFillRatio; this may be useful
        for sparing memory; false by default }
      property AutoShrink : Boolean read FAutoShrink write FAutoShrink;
      
      { @inv MinCapacity > 0 }
      { @inv Capacity >= MinCapacity }
   end;
   
   { -------------------- tree containers ------------------------ }
   
   { An abstract interface of a tree. Both ordinary and binary trees
     inherit from this class.  }
   TBasicTreeAdt = class (TContainerAdt)
   public
      { returns an iterator pointing to the root of the tree }
      function BasicRoot : TBasicTreeIterator; virtual; abstract;
      { returns an iterator representing the end of traversal; it can
        be used to mark the end of a sequence when using tree
        traversal iterators as forward iterators in algorithms }
      function Finish : TBasicTreeIterator; virtual; abstract;
      { returns an iterator for traversing the tree in the preorder
        traversal order }
      function PreOrderIterator : TPreOrderIterator; virtual; abstract;
      { returns an iterator for traversing the tree in the postorder
        traversal order }
      function PostOrderIterator : TPostOrderIterator; virtual; abstract;
      { returns an iterator for traversing the tree in the inorder
        traversal order }
      function InOrderIterator : TInOrderIterator; virtual; abstract;
      { returns an iterator for traversing the tree in the levelorder
        traversal order }
      function LevelOrderIterator : TLevelOrderIterator; virtual; abstract;
      { deletes the given node together with its subtree; invalidates
        the given iterator; returns the number of items deleted; }
      function DeleteSubTree(node : TBasicTreeIterator) :
         SizeType; virtual; abstract;
      { inserts <aitem> as the root of the tree }
      procedure InsertAsRoot(aitem : ItemType); virtual; abstract;
      
      { inserts <aitem> somewhere into the container; returns true if
        successful, false if <aitem> could not be inserted; implemented with
        @<InsertAsRoot> }
      function InsertItem(aitem : ItemType) : Boolean; override;
      { removes some item from the container and returns it; if there
        are no more items to extract then returns nil; implemented as
        PostOrderIterator.Item + DeleteSubTree(PostOrderIterator) }
      function ExtractItem : ItemType; override;
      { @fetch-related }
      { implemented with not Empty }
      function CanExtract : Boolean; override;
   end;
   
   { -------------------- sequential containers ------------------------ }   
   
   { An abstract interface of a queue. }
   TQueueAdt = class (TContainerAdt)
   public
      { pushes <aitem> at the back }
      procedure PushBack(aitem : ItemType); virtual; abstract;
      { deletes the item at the front of the queue }
      procedure PopFront; virtual; abstract;
      { returns the item at the front }
      function Front : ItemType; virtual; abstract;
      
      { inserts <aitem> somewhere into the container; returns true if
        successful, false if <aitem> could not be inserted; implemented with
        @<PushBack> }
      function InsertItem(aitem : ItemType) : Boolean; override;
      { removes some item from the container and returns it; if there
        are no more items to extract then returns nil; implemented as
        @<Front> + @<PopFront> }
      function ExtractItem : ItemType; override;
      { @fetch-related }
      { implemented with not Empty }
      function CanExtract : Boolean; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
   end;
   
   { An abstract interface of a double-ended queue. }
   TDequeAdt = class (TQueueAdt)
   public
      { pushes <aitem> at the front }
      procedure PushFront(aitem : ItemType); virtual; abstract;
      { deletes the item at the back of the deque }
      procedure PopBack; virtual; abstract;
      { returns the item at the back }
      function Back : ItemType; virtual; abstract;
   end;
   
   { there are no separate stacks for the sake of simplicity }
   T&_mcp_prefix&StackAdt = TDequeAdt;
   
   { represents a sequential list of items supporting forward
     iterators; the requirement that the pointers stored in the
     container be pairwise unequal does not have to be satisifed for
     classes descended from this one; (and you, therefore, have to
     re-implement the TForwardIterator.Delete(TForwardIterator)
     method); }
   TListAdt = class (TDequeAdt)
   private
{$ifdef DEBUG_PASCAL_ADT }
      FSizeCanRecalc : Boolean;
{$endif DEBUG_PASCAL_ADT }
   protected
{$ifdef DEBUG_PASCAL_ADT }
      {$warnings off }
      constructor Create; overload;
      {$warnings on }
{$endif DEBUG_PASCAL_ADT }
   public
      { ------- basic methods (most of them take an O(1) time) --------------- }
      { returns an iterator to the first element in the container (the
        start iterator) }
      function ForwardStart : TForwardIterator; virtual; abstract;
      { returns the finish iterator; returns an iterator pointing to
        the one beyond last element }
      function ForwardFinish : TForwardIterator; virtual; abstract;
      { deletes the item at <pos>; <pos> is invalidated for most
        containers }
      procedure Delete(pos : TForwardIterator); overload; virtual; abstract;
      { deletes all items in the range [start,finish); returns the
        number of deleted items; @complexity O(n) }
      function Delete(start, finish : TForwardIterator) :
         SizeType; overload; virtual; abstract;
      { removes the item at <pos> from the list without actually
        destroying it; the same as Delete if either OwnsElements is
        false or the disposer is nil; returns the removed item. }
      function Extract(pos : TForwardIterator) : ItemType;
      overload; virtual; abstract;
      { inserts an item before <pos>; i.e. the new element will be at
        the position <pos> }
      procedure Insert(pos : TForwardIterator;
                       aitem : ItemType); overload; virtual; abstract;
      
      { ------ algorithms (may take a considerable amount of time) -------- }
      { for each algorithm here a default implementation is provided
        using the general algorithms @discard-recent-comment }
      
      { moves elements from the range [SourceStart, SourceFinish) to before
        <Dest>; }
      procedure Move(SourceStart, SourceFinish,
                     Dest : TForwardIterator); overload; virtual;
      { moves <Source> to before <Dest>. }
      procedure Move(Source, Dest : TForwardIterator); overload; virtual;

{$ifdef DEBUG_PASCAL_ADT }
      { This field is present only when compiling in the debug mode.
        It is used only for the purpose of testing the library. }
      property SizeCanRecalc : Boolean read FSizeCanRecalc
                                   write FSizeCanRecalc;
{$endif DEBUG_PASCAL_ADT }
   end;
   
   { TDoubleListAdt is essentially TListAdt with support for
     bidirectional iterators. Its two new methods are implemented by
     means of casting the result of ForwardStart (ForwardFinish) to
     TBidirectionalIterator. This means that the class which inherits
     from TDoubleListAdt must return an iterator derived from
     TBidirectionalIterator in those two functions (although their
     return types are marked as TForwardIterator). }
   TDoubleListAdt = class (TListAdt)
   public
      { returns an iterator to the first element in the container }
      function BidirectionalStart : TBidirectionalIterator;
      { returns an iterator pointing to the one beyond last element }
      function BidirectionalFinish : TBidirectionalIterator;      
   end;
   
   { Represents a container with random access to items.  }
   TRandomAccessContainerAdt = class (TDoubleListAdt)
   protected
      { returns the current capacity of the container }
      function GetCapacity : SizeType; virtual; abstract;
      { sets the capacity to <cap>; sets only if <cap> is bigger than
        the current capacity }
      procedure SetCapacity(cap : SizeType); virtual; abstract;
      
   public
      { returns an iterator to the first element in the container }
      function ForwardStart : TForwardIterator; override;
      { returns an iterator pointing to the one beyond last element }
      function ForwardFinish : TForwardIterator; override;
      { returns an iterator pointing to the first element }
      function RandomAccessStart : TRandomAccessIterator; virtual; abstract;
      { returns an iterator to the one beyond last element }
      function RandomAccessFinish : TRandomAccessIterator; virtual; abstract;
      { returns the element at the given index }
      function GetItem(index : IndexType) : ItemType; virtual; abstract;
      { sets the element at the given index }
      procedure SetItem(index : IndexType; elem : ItemType); virtual; abstract;
      { inserts an item at <index>; the new element will be at the
        position <index>; the items from the range <index,finish) are
        moved rightwards. }
      procedure Insert(index : IndexType;
                       aitem : ItemType); overload; virtual; abstract;
      procedure Insert(iter : TForwardIterator;
                       aitem : ItemType); overload; override; 
      { deletes the item at <index>; all items after index are moved
        leftwards }
      procedure Delete(index : IndexType); overload; virtual; abstract; 
      procedure Delete(iter : TForwardIterator); overload; override; 
      { deletes at most n items beginning with start, less if the end
        of the container is reached; returns the number of items
        actually deleted; @complexity O(n) }
      function Delete(start : IndexType; n : SizeType) :
         SizeType; overload; virtual; abstract; 
      { deletes all the items from the range [starti,finishi); returns
        the number of items deleted; @complexity O(n) }
      function Delete(start, finish : TForwardIterator) :
         SizeType; overload; override; 
      { Removes the item at <index> from the container, but does not
        dispose it. Returns the removed item. }
      function Extract(index : IndexType) : ItemType; overload; virtual; abstract;
      function Extract(iter : TForwardIterator) : ItemType; overload; override; 
      { returns the lowest index in the collection; for containers
        with fixed, zero-based indices always returns 0 (default) }
      function LowIndex : IndexType; virtual;
      { returns the highest index in the collection; for containers
        with fixed, zero-based indices always returns Size - 1 (default) }
      function HighIndex : IndexType; virtual;
      
      property Capacity : SizeType read GetCapacity write SetCapacity;
   end;
   
   { Represents an array. }
   TArrayAdt = class (TRandomAccessContainerAdt)
   public
      property Items[index : IndexType] : ItemType read GetItem
                                           write SetItem; default;
   end;
   
   { a class used as a base class for most random access iterators;
     the only abstract methods left in this class are @<TIterator.ExchangeItemsAt>
     and @<TIterator.CopySelf> }
   TRandomAccessContainerIterator = class (TRandomAccessIterator)
   protected
      FIndex : IndexType;
      FCont : TRandomAccessContainerAdt;
      
   public      
      constructor Create(ind : IndexType;
                         const cont : TRandomAccessContainerAdt);      
      { computes the distance between pos and self (pos - self) }
      function Distance(const Pos : TRandomAccessIterator) :
         IndexType; override;
      { returns true if self and pos both point to the same item in
        the same collection }
      function Equal(const Pos : TIterator) : Boolean; override;
      { returns true if self is closer to the beginning of the
        collection than pos }
      function Less(const Pos : TRandomAccessIterator) : Boolean; override;
      { returns element from the position pointed by self }
      function GetItem : ItemType; override;
      { sets the element at the position pointed to by iterator to
        Elem; }
      procedure SetItem(Aitem : ItemType); override;
      { returns the item at index self.Index + i (i may be negative) }
      function GetItemAt(i : IndexType) : ItemType; override;
      { sets the item at index self.Index + i }
      procedure SetItemAt(i : IndexType; aitem : ItemType); override;
      { exchanges the item pointed to by self with the one pointed to
        by the argument }
      procedure ExchangeItem(iter : TIterator); override;
      { Goes one position forward. Second declaration only for
        compilers that do not support
        overloading. @include-declarations 2 }
{$ifdef OVERLOAD_DIRECTIVE }
      procedure Advance; overload; override;
{$else }
      procedure AdvanceOnePosition; override;
{$endif OVERLOAD_DIRECTIVE }

      { moves self by i positions }
      procedure Advance(i : integer); overload; override;
      { moves iter one position back }
      procedure Retreat; override;
      { inserts <aitem> into the container; after insertion the iterator
        points to the same index }
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      { deletes at most n items beginning with start, less if the end
        of the container is reached; returns the number of items
        actually deleted; after the deletion self points to the next
        item after the deleted sequence }
      function Delete(n : SizeType) : SizeType; overload; override; 
      { returns index of iterator within container into which it
        points }
      function Index : IndexType; override;
      { returns the container into which self points }
      function Owner : TContainerAdt; override;
      { returns true if self is the first iterator }
      function IsStart : Boolean; override;
      { returns true if self is the 'one beyond last' iterator }
      function IsFinish : Boolean; override;
   end;
      

{$ifdef OVERLOAD_DIRECTIVE }
   
function CopyOf(const iter : TRandomAccessContainerIterator) :
   TRandomAccessContainerIterator; overload;

{$endif OVERLOAD_DIRECTIVE }

