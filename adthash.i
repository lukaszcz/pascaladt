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
 adthash.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adthash.defs

type
   { ========================== THashTable =============================== }

   PHashNode = ^THashNode;
   THashNode = record
      Item : ItemType;
      Next : PHashNode;
   end;

   { THashTable is an open hash table. All set operations are average
     O(1), provided that a decent hash function is used. Default hash
     function uses the FNV algorithm, which in most cases is
     sufficiently good and need not be replaced. Warning: the hashing
     function must not raise exceptions. }
   THashTable = class (THashSetAdt)
   private
      FBuckets : array of THashNode;
      FCapacity : SizeType; { size of FBuckets array }
      FSize : SizeType; { number of items stored in hash table }
      FTableSize : SizeType; { log2(FCapacity) }
      { maximal value of (FSize/FCapacity) shl htRatioFactor; default is 80% }
      FMaxFillRatio : SizeType;
      { the same as above, but minimal value; default is 10%; this
        should be larger than MaxFillRatio/2 }
      FMinFillRatio : SizeType;
      { true if the table has been grown automatically since the last
        user call to Clear, Rehash or since creation of the object }
      FCanShrink : Boolean;
      { index of the first non-empty bucket; -1 if the container has
        been modified since it was last set; used only to efficiently
        implement THashTableIterator.IsStart method }
      FFirstUsedBucket : IndexType;

      { returns an index into an appropriate bucket within the hash
        table obtained from the value passed; the value should be the
        result of the hashing function }
      function GetBucketIndex(value : UnsignedType) : IndexType;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif INLINE_DIRECTIVE }
      procedure CheckMinFillRatio;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif INLINE_DIRECTIVE }
      procedure CheckMaxFillRatio;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif }

      { initializes all fields to their default values }
      procedure InitFields;
      { initializes FBuckets, FCapacity, FSize, FTableSize,
        FFirstUsedBucket and FCanBeShrunk to their default values }
      procedure InitBuckets;
      { if (bucket,node) represents a valid position (i.e. the one
        where Item <> nil) does nothing; otherwise sets (bucket,node)
        to the nearest item after the position they represent }
      procedure AdvanceToNearestItem(var bucket : IndexType;
                                     var node : PHashNode);
      { if (bucket,node) represents a valid position (i.e. the one
        where Item <> nil) does nothing; otherwise sets (bucket,node)
        to the nearest item before the position they represent }
      procedure RetreatToNearestItem(var bucket : IndexType;
                                     var node : PHashNode);
      { returns the number of items equal to aitem that are in the list
        in bucket after or at node; assumes that item at (bucket,node)
        is equal to aitem; sets (bucket,node) to position just after the
        chain of items equal to aitem (this is not necessairily a valid
        position, you should call AdvanceToNearestItem before
        dereferencing it) }
      function EqualItemsAhead(var bucket : IndexType;
                               var node : PHashNode;
                               aitem : ItemType) : SizeType;
      { if the node containing item equal to aitem has been found then
        returns true and assigns (bucket,node) the position at which
        it was found; if an item equal to aitem hasn't been found then
        returns false, assigns (bucket,node) the position at which aitem
        should be inserted }
      function FindNode(aitem : ItemType; var bucket : IndexType;
                        var node : PHashNode) : Boolean;
      { inserts aitem before or after position (bucket,node); this has
        to be the correct position returned by FindNode; sets
        (bucket,node) to point to the newly inserted node; does not
        call CheckMaxFillRatio; see notes on the implementation of
        THashTable }
      procedure InsertNode(var bucket : IndexType; var node : PHashNode;
                           aitem : ItemType);
      { returns the item at position (bucket,node) and removes this
        position; after the operation (bucket,node) will point to the
        next position after the deleed one if you call
        AdvanceToNearestItem on them; does not shrink the table
        automatically inorder not to invalidate iterators }
      function ExtractNode(bucket : IndexType; node : PHashNode) : ItemType;
      { deletes all items without changing the capacity }
      procedure ClearBuckets;
      { allocates a new node }
      procedure NewNode(var node : PHashNode);
      { deallocates the node (does not touch the item) }
      procedure DisposeNode(node : PHashNode);

   protected
      function GetCapacity : SizeType; override;
      { returns the capacity that should be used for table with
        approximately 2^ex items; this simply converts FTableSize to
        FCapacity }
      function CalculateCapacity(ex : SizeType) : SizeType; override;
      function GetMaxFillRatio : SizeType; override;
      procedure SetMaxFillRatio(fr : SizeType); override;
      function GetMinFillRatio : SizeType; override;
      procedure SetMinFillRatio(fr : SizeType); override;

   public
      { creates a new THashTable.   }
      constructor Create;
      { creates a copy of ht; if itemCopier is nil then does not copy
        the items }
      constructor CreateCopy(const ht : THashTable;
                             const itemCopier : IUnaryFunctor); overload;
      { frees all items and releases any allocated memory }
      destructor Destroy; override;

{$ifdef TEST_PASCAL_ADT }
      { writes some information about the hash table to the log file
        including the average number of items in a bucket, number of
        buckets empty, filled, etc. }
      procedure LogStatus(mname : String); override;
{$endif TEST_PASCAL_ADT }

      { returns an exact copy of self; @complexity O(n) }
      function CopySelf(const ItemCopier : IUnaryFunctor) :
         TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { returns the start iterator; @complexity worst-case O(n) }
      function Start : TSetIterator; override;
      { returns the finish iterator }
      function Finish : TSetIterator; override;
&if (&_mcp_accepts_nil)
      { if RepeatedItems is false and there is an item equal to aitem in
        the set, then returns this item; in all other cases inserts
        aitem into the set and returns nil }
      function FindOrInsert(aitem : ItemType) : ItemType; override;
      { returns the first item equal to aitem, or nil if not found; if
        you need an iterator to that item use LowerBound or EqualRange
        instead; @complexity average O(1), worst-case O(n) }
      function Find(aitem : ItemType) : ItemType; override;
&endif &# end &_mcp_accepts_nil
      { returns true if the given item is present in the set; }
      { @complexity average O(1), worst-case O(n) }
      function Has(aitem : ItemType) : Boolean; override;
      { returns the number of items in the set equal to aitem;
        @complexity average O(1), worst-case O(n) }
      function Count(aitem : ItemType) : SizeType; override;
      { exactly the same as below; pos is discarded; @complexity
        average O(1), worst-case O(n) }
      function Insert(pos : TSetIterator;
                      aitem : ItemType) : Boolean; overload; override;
      { inserts aitem into the set; returns true if self was inserted,
        or false if it cannot be inserted (this happens for non-multi
        (without repeated items) set when item equal to aitem is already
        in the set); if the item is not inserted it is not owned by
        the container and not disposed !  @complexity average O(1),
        worst-case O(n) }
      function Insert(aitem : ItemType) : Boolean; overload; override;
      { removes the item at pos from the set; }
      procedure Delete(pos : TSetIterator); overload; override;
      { removes all items equal to aitem from the set; returns the
        number of deleted items; @complexity average O(1), worst-case
        O(n) }
      function Delete(aitem : ItemType) : SizeType; overload; override;
      { returns the iterator starting the range of items equal to aitem;
        @complexity average O(1), worst-case O(n) }
      function LowerBound(aitem : ItemType) : TSetIterator; override;
      { returns the iterator that ends a range of items equal to aitem;
        @complexity average O(1), worst-case O(n) }
      function UpperBound(aitem : ItemType) : TSetIterator; override;
      { returns a range <LowerBound, UpperBound), works faster than
        calling these two functions separately; @complexity average
        O(1), worst-case O(n) }
      function EqualRange(aitem : ItemType) : TSetIteratorRange; override;
      { rehashes the table making it 2^EX times larger; ex may be
        negative, but the resulting capacity of the table cannot be
        less than its minimal allowe value. }
      procedure Rehash(ex : SizeType); override;
      { clears the container - removes all items; @complexity O(n). }
      procedure Clear; override;
      { returns true if container is empty; equivalent to Size = 0,
        but may be faster; }
      function Empty : Boolean; override;
      { returns number of items;  }
      function Size : SizeType; override;
      { returns the minimal allowed capacity for the set }
      function MinCapacity : SizeType; override;
   end;

   THashTableIterator = class (TSetIterator)
   private
      FBucket : IndexType;
      FNode : PHashNode;
      FTable : THashTable;

      {$warnings off }
      constructor Create(abucket : IndexType; anode : PHashNode;
                         tab : THashTable);
      {$warnings on }

   public
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
      { @fetch-related }
      { @complexity O(1) if <ptr> is equal to the old item. Average
        O(1) and worst-case O(n) if not. }
      procedure SetItem(aitem : ItemType); override;
      { @fetch-related }
      { @complexity average O(1), worst-case O(n) }
      procedure ResetItem; override;
      procedure Advance; overload; override;
      procedure Retreat; override;
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      function Owner : TContainerAdt; override;
      { returns true if self is the first iterator; @complexity
        amortized O(1), worst-case O(m) }
      function IsStart : Boolean; override;
      function IsFinish : Boolean; override;
   end;


&# TScatterTable only for objects, pointers or strings (there must be two
&# special values not taken by any valid representation of the type)
&if (&_mcp_are_two_special_values)
   { ========================== TScatterTable =============================== }


   { TScatterTable is a closed hash table. All set operations are average
     O(1), provided that a decent hash function is used. Default hash
     function uses the FNV algorithm, which in most cases is sufficiently
     good and need not be replaced. Warning: the hashing function must
     not raise exceptions. }
   TScatterTable = class (THashSetAdt)
   private
      FArray : TDynamicArray;
      { log2 from the capacity of the table }
      FTableSize : SizeType;
      { the number of fields marked stDeleted; if this number exceeds
        the number of items stored then the table is rehashed, but
        without changing its size }
      FDeletedFields : SizeType;
      { maximal value of (FSize/FCapacity) shl stRatioFactor; default is 70% }
      FMaxFillRatio : SizeType;
      { the same as above, but minimal value; default is 10%; this
        should be larger than MaxFillRatio/2 }
      FMinFillRatio : SizeType;
      { true if the table has been grown automatically since the last
        user call to Clear, Rehash or since creation of the object }
      FCanShrink : Boolean;
      { index of the first non-empty collision chain; -1 if the container has
        been modified since it was last set; used only to efficiently
        implement TScatterTableIterator.IsStart method }
      FFirstUsedIndex : IndexType;
      FFirstUsedOffset : SizeType;

      { returns the first offset from the original position that
        should be probed when collision occurs; }
      function FirstProbe : SizeType;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif }
      { returns the next offset that should be probed after off }
      function NextProbe(off : UnsignedType) : SizeType;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif }
      function GetIndex(val : UnsignedType) : IndexType;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif }
      procedure CheckDeletedFields;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif }
      procedure CheckMaxFillRatio;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif }
      procedure CheckMinFillRatio;
{$ifdef INLINE_DIRECTIVE }
      inline;
{$endif }

      procedure InitFields;
      procedure InitBasicFields;
      procedure ZeroOutFArray;
      procedure AdvanceToNearestItem(var h : IndexType; var p : SizeType);
      { Inserts aitem into the table. Returns the offset at which aitem
        has been inserted and sets h to the value to which it hashes,
        i.e. its chain index. If aitem cannot be inserted then the
        result of the function is undefined (ie. it can be anything);
        you should check for such a case by comparing the size of the
        container before and after calling this method.  }
      function DoInsert(aitem : ItemType; var h : IndexType) : SizeType; overload;
      { the same as above but returns true if aitem was inserted, false
        if not; }
      function DoInsert(aitem : ItemType) : Boolean; overload;

   protected
      function GetCapacity : SizeType; override;
      { returns the capacity that should be used for table with
        approximately 2^ex items; this simply converts FTableSize to
        FCapacity }
      function CalculateCapacity(ex : SizeType) : SizeType; override;
      function GetMaxFillRatio : SizeType; override;
      procedure SetMaxFillRatio(fr : SizeType); override;
      function GetMinFillRatio : SizeType; override;
      procedure SetMinFillRatio(fr : SizeType); override;

   public
      { creates a new TScatterTable.   }
      constructor Create;
      { creates a copy of st; if <itemCopier> is nil then does not
        copy the items }
      constructor CreateCopy(const st : TScatterTable;
                             const itemCopier : IUnaryFunctor); overload;
      { frees all items and releases any allocated memory }
      destructor Destroy; override;

{$ifdef TEST_PASCAL_ADT }
      { writes some information about the hash table to the log file }
      procedure LogStatus(mname : String); override;
{$endif TEST_PASCAL_ADT }

      { returns an exact copy of self; @complexity O(n) }
      function CopySelf(const ItemCopier : IUnaryFunctor) :
         TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { returns the start iterator; @complexity worst-case O(m) }
      function Start : TSetIterator; override;
      { returns the finish iterator }
      function Finish : TSetIterator; override;
&if (&_mcp_accepts_nil)
      { if RepeatedItems is false and there is an item equal to aitem in
        the set, then returns this item; in all other cases inserts
        aitem into the set and returns nil }
      function FindOrInsert(aitem : ItemType) : ItemType; override;
      { returns the first item equal to aitem, or nil if not found; if
        you need an iterator to that item use LowerBound or EqualRange
        instead; @complexity average O(1), worst-case O(m) }
      function Find(aitem : ItemType) : ItemType; override;
&endif &# end &_mcp_accepts_nil
      { returns true if the given item is present in the set; }
      { @complexity average O(1), worst-case O(n) }
      function Has(aitem : ItemType) : Boolean; override;
      { returns the number of items in the set equal to aitem;
        @complexity average O(1), worst-case O(n) }
      function Count(aitem : ItemType) : SizeType; override;
      { exactly the same as below; pos is discarded; @complexity
        average O(1), worst-case O(n) }
      function Insert(pos : TSetIterator;
                      aitem : ItemType) : Boolean; overload; override;
      { inserts aitem into the set; returns true if self was inserted,
        or false if it cannot be inserted (this happens for non-multi
        (without repeated items) set when item equal to aitem is already
        in the set); if the item is not inserted it is not owned by
        the container and not disposed !  @complexity average O(1),
        worst-case O(n) }
      function Insert(aitem : ItemType) : Boolean; overload; override;
      { removes the item at pos from the set; }
      procedure Delete(pos : TSetIterator); overload; override;
      { removes all items equal to aitem from the set; returns the
        number of deleted items; @complexity average O(1), worst-case
        O(n) }
      function Delete(aitem : ItemType) : SizeType; overload; override;
      { returns the iterator starting the range of items equal to aitem;
        @complexity average O(1), worst-case O(m), where m is the
        capacity }
      function LowerBound(aitem : ItemType) : TSetIterator; override;
      { returns the iterator that ends a range of items equal to aitem;
        @complexity average O(1), worst-case O(m), where m is the
        capacity ) }
      function UpperBound(aitem : ItemType) : TSetIterator; override;
      { returns a range <LowerBound, UpperBound), works faster than
        calling these two functions separately; @complexity average
        O(1), worst-case O(m), where m is the capacity }
      function EqualRange(aitem : ItemType) : TSetIteratorRange; override;
      { rehashes the table making it 2^EX times larger; ex may be
        negative, but the resulting capacity of the table cannot be
        less than its minimal allowe value. }
      procedure Rehash(ex : SizeType); override;
      { clears the container - removes all items; @complexity O(m). }
      procedure Clear; override;
      { returns true if container is empty; equivalent to Size = 0,
        but may be faster; }
      function Empty : Boolean; override;
      { returns number of items;  }
      function Size : SizeType; override;
      { returns the minimal allowed capacity for the set }
      function MinCapacity : SizeType; override;
   end;

   TScatterTableIterator = class (TSetIterator)
   private
      FBase : IndexType;
      FOffset : SizeType;
      FTable : TScatterTable;

      {$warnings off }
      constructor Create(abase : IndexType; aoff : SizeType;
                         tab : TScatterTable);
      {$warnings on }

   public
      { returns an exact copy of self; i.e. copies all the data }
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
      { @fetch-related }
      { @complexity O(1) if <ptr> is equal to the old item. Average
        O(1) and worst-case O(n) if not. }
      procedure SetItem(aitem : ItemType); override;
      { @fetch-related }
      { @complexity average O(1), worst-case O(n) }
      procedure ResetItem; override;
      procedure Advance; overload; override;
      procedure Retreat; override;
      procedure Insert(aitem : ItemType); override;
      function Extract : ItemType; override;
      function Owner : TContainerAdt; override;
      { returns true if self is the first iterator; @complexity
        amortized O(1), worst-case O(m) }
      function IsStart : Boolean; override;
      function IsFinish : Boolean; override;
   end;
&endif &# end &_mcp_are_two_special_values
