(* This file is a part of the PascalAdt library, which provides
   commonly used algorithms and data structures for the FPC and Delphi
   compilers.
   
   Copyright (C) 2004, 2005, 2006 by Lukasz Czajka
   
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
   02110-1301 USA @discard *)

{@discard
 adtmap.inc::map_prefix=&_mcp_map_prefix&::item_prefix=&_mcp_item_prefix&::key_prefix=&_mcp_key_prefix&::item_type=&ItemType&::key_type=&KeyType&
}

&include adtmap.defs

&define TMapIteratorPair T&_mcp_map_prefix&IteratorPair

type
   TMapIterator = class;
   TMapIteratorRange = class;

   { a functor that should be used to copy the contents of a map
     (@<TMapAdt>) }
   TMapAdtCopier = class (TFunctor, IUnaryFunctor)
   private
      FKeyCp : IKeyUnaryFunctor;
      FItemCp : IItemUnaryFunctor;
      
   protected
      {$warnings off }
      constructor Create(const keycp : IKeyUnaryFunctor;
                         const itemcp : IItemUnaryFunctor);
      {$warnings on }
      
   public
      function Perform(aitem : TObject) : TObject; virtual; abstract;
      property KeyCopier : IKeyUnaryFunctor read FKeyCp;
      property ItemCopier : IItemUnaryFunctor read FItemCp;
   end;
   
   { represents a map or a multimap, also called a dictionary }
   TMapAdt = class (TItemDefinedOrderContainerAdt)
   private
      FKeyDisposer : IKeyUnaryFunctor;
      FOwnsKeys : Boolean;
      
      procedure SetKeyDisposer(const akeydisp : IKeyUnaryFunctor);
      function GetKeyDisposer : IKeyUnaryFunctor;
      
   protected
      {$warnings off }
      constructor Create; overload;
      constructor CreateCopy(const cont : TMapAdt); overload;
      {$warnings on }
      
      procedure BasicSwap(cont : TItemContainerAdt); override;
      procedure SetRepeatedItems(b : Boolean); virtual; abstract;
      function GetRepeatedItems : Boolean; virtual; abstract;
      function GetKeyComparer : IKeyBinaryComparer; virtual; abstract;
      procedure SetKeyComparer(cmp : IKeyBinaryComparer); virtual; abstract;
      
   public
      { returns a copier suitable to be used by the CopySelf method or
        the copy constructor; only the functor returned by this
        function can be passed to these methods as only it knows the
        internal structure of the map and how to copy both the key and the
        item }
      class function CreateCopier(const keyCopier : IKeyUnaryFunctor;
                                  const itemCopier : IItemUnaryFunctor) :
         TMapAdtCopier; virtual; abstract;
      
&if (&ItemType != TObject)
      { raises an exception; the second CopySelf should be used instead }
      function CopySelf(const itemCopier : IItemUnaryFunctor) : TItemContainerAdt; override;
      { this CopySelf should be used; mapCopier must be the functor
        returned by CreateCopier }
      function CopySelf(const mapCopier : IUnaryFunctor) : TItemContainerAdt; virtual; abstract;
&endif
      { <cont> must be of the type TMapAdt; otherwise the exception
        ENoMapSwap is raised } 
      procedure Swap(cont : TItemContainerAdt); override;
      { returns the start iterator }
      function Start : TMapIterator; virtual; abstract;
      { returns the finish iterator }
      function Finish : TMapIterator; virtual; abstract;
      { returns true if the key is associated with any item; }
      function Has(key : KeyType) : Boolean; virtual; abstract;
      { returns the first item associated with key, or nil if not
        found (if ItemType is either TObject or Pointer); if ItemType is
        any other type then you should check Has() earlier; in most
        implementations the found values are cached, so there is
        almost no overhead by calling two functions instead of one; if
        you need an iterator to that item use LowerBound or EqualRange
        instead }
      { @pre ItemType <> TObject and ItemType <> Pointer implies Has(key)  }
      function Find(key : KeyType) : ItemType; virtual; abstract;
      { returns the number of items in the map associated with <key> }
      function Count(key : KeyType) : SizeType; virtual; abstract;
      { associates <key> with <aitem>; if @<RepeatedItems> is false and
        there is already an item associated with key, then changes
        this item to <aitem>; in all other cases works like insert;
        <key> and <aitem> are _always_ inserted into the map; the old key
        may be destroyed }
      procedure Associate(key : KeyType; aitem : ItemType); virtual; abstract;
      { the same as below, but uses <pos> as a hint where to insert
        (only in implementations where it makes sense) }
      function Insert(pos : TMapIterator; key : KeyType;
                      aitem : ItemType) : Boolean; overload; virtual; abstract;
      { associates <aitem> with <key>; if @<RepeatedItems> is false and
        there already is some item associted with <key>, <aitem> is not
        inserted and false is returned, otherwise true is returned }
      function Insert(key : KeyType;
                      aitem : ItemType) : Boolean; overload; virtual; abstract;
      { removes the item at <pos> from the map }
      procedure Delete(pos : TMapIterator); overload; virtual; abstract;
      { removes all items associated with <key> from the map; returns the
        number of deleted items }
      function Delete(key : KeyType) : SizeType; overload; virtual; abstract;
      { removes all items associated with <key> from the map, but does
        not dispose them; returns the number of removed items }
      function Extract(key : KeyType) : SizeType; virtual;
      { returns the iterator starting the range of items associated
        with <key> }
      function LowerBound(key : KeyType) : TMapIterator; virtual; abstract;
      { returns the iterator that ends the range of items associated
        with <key> }
      function UpperBound(key : KeyType) : TMapIterator; virtual; abstract;
      { returns the range <LowerBound, UpperBound). works faster than
        calling these two functions separately }
      function EqualRange(key : KeyType) : TMapIteratorRange; virtual; abstract;
      { returns true if items in the map are in sorted order (defined
        by the keys they are associated with) }
      function IsSorted : Boolean; virtual; abstract;
      { disposes a given key with KeyDisposer (if non-nil) }
      procedure &<DisposeKey>(key : KeyType);
      { sets the hasher for keys; this is relevant only if the map is
        implemented as a hash table; if it's not the procedure does
        nothing (it's the default implementation); }
      procedure SetKeyHasher(akeyhasher : I&_mcp_key_prefix&Hasher); virtual;
      { returns true if multiple items associated with the same key are allowed }
      property RepeatedItems : Boolean read GetRepeatedItems write
                                  SetRepeatedItems;
      { indicates whether the map owns the keys; true by default; }
      property OwnsKeys : Boolean read FOwnsKeys write FOwnsKeys;
      { returns the functor used to compare the keys }
      property KeyComparer : IKeyBinaryComparer read GetKeyComparer write
                                SetKeyComparer;
      { returns the functor used to dispose the keys }
      property KeyDisposer : IKeyUnaryFunctor read GetKeyDisposer write
                                SetKeyDisposer;
      { returns the first item associated with <key>; if no item is
        associated with <key> returns nil; when being assigned
        associates the item being assigned with <key>; if
        @<RepeatedItems> is false and there already exists an item
        associated with <key> then changes this item to the one being
        assigned; in all other cases associates another item with
        <key> without removing any already existing associations;
        <key> and the item being assigned are always inserted into the
        map when assinging; the old key may be destroyed }
      property Items[key : KeyType] : ItemType read Find
                                         write Associate; default;
      
      { always returns false }
      function InsertItem(aitem : ItemType) : Boolean; override;
      { should never be called since its precondition is always false }
      function ExtractItem : ItemType; override;
      { returns false }
      function CanExtract : Boolean; override;
   end;   
      
   { ----------------- map iterator --------------------- }
   { an iterator into a map; the iterator into a map represents a
     position that is composed of two things: the key and the item; in
     order to retrieve the key additional Key function is introduced;
     because maps are containers with internally-defined order of
     items, the modifying operations work differently than specified
     in the ancestor classes; SetItem, GetItem and ExchangeItem
     operate only on items without keys associated with them; Insert
     raises EDefinedOrder, but there is a new version of Insert
     available that takes two arguments - the key and the item - and
     inserts them at a proper place in the map (associating the item
     with the key) and moves to the newly created position or to
     finish if the item could not be associated; Delete works as
     expected. }
   { @see TContainerAdt.IsDefinedOrder, TDefinedOrderIterator,
     TSetIterator }
   TMapIterator = class (TItemBidirectionalIterator)
   public
      { returns the key at the current position }
      function Key : KeyType; virtual; abstract;
      { raises EDefinedOrder }
      procedure Insert(aitem : ItemType); overload; override;
      { inserts into the map (associates aitem with akey) and moves to
        the newly inserted position or to finish if the item could not
        be inserted }
      procedure Insert(akey : KeyType;
                       aitem : ItemType); overload; virtual; abstract;
   end;
   
   
   { -------------- a map iterator pair ------------------------ }
   { a pair of two map iterators; used frequently in connection with
     maps; an object of this class is owned by the container which is
     the owner of Start and is destroyed automatically (so you do not
     have to bother); however, Start and Finish are not owned by the
     object (as they are already owned by their 'parent'
     containers). }
   TMapIteratorRange = class
   private
      FStart, FFinish : TMapIterator;
      owner : TItemContainerAdt;
      handle : TCollectorObjectHandle;
      
   public
      constructor Create(starti, finishi : TMapIterator);
      { unregisters self from grabage collector; does _not_ destroy
        Start or Finish }
      destructor Destroy; override;
      { returns the start of the range }
      property Start : TMapIterator read FStart;
      { returns the finish of the range (the one-beyond last iterator) }
      property Finish : TMapIterator read FFinish;
      property First : TMapIterator read FStart;
      property Second : TMapIterator read FFinish;
   end;
   TMapIteratorPair = TMapIteratorRange;
   
   { -------- container adaptors and their helper classes ---------- }
   
   TMap = class;
   
   TMapEntry = class
   private
      FKey : KeyType;
      FItem : ItemType;
   public
      constructor Create(akey : KeyType; aitem : ItemType);
      property Key : KeyType read FKey write FKey;
      property Item : ItemType read FItem write FItem;
   end;
   
   { the comparer that should be used with @<TMap> }
   TMapComparer = class (TFunctor, IBinaryComparer)
   private
      fkeycmp : IKeyBinaryComparer;
      
   public
      { creates a map comparer. <keycmp> should compare keys; }
      constructor Create(const keycmp : IKeyBinaryComparer);
      { compares the keys of items }
      function Compare(aitem1, aitem2 : TObject) : Integer;
      property KeyComparer : IKeyBinaryComparer read fkeycmp write fkeycmp;
   end;
   
   { the hasher that should be used with @<TMap> }
   TMapHasher = class (TFunctor, IHasher)
   private
      fkeyhasher : IKeyHasher;
      
   public
      { keyhasher is owned by the object and destroyed with its
        destruction }
      constructor Create(const akeyhasher : IKeyHasher);
      function Hash(aitem : TObject) : UnsignedType;
      property KeyHasher : IKeyHasher read fkeyhasher;
   end;
   
   { adapts the general set interface to implement a map }
   TMap = class (TMapAdt)
   private
      { this is used not to create an object every time a simple
        lookup is needed only }
      FEntry : TMapEntry;
      { a cached entry; used to optimize sequences like:
        @c if map.Has(x) then y := map.Find(x); @ec }
      CachedEntry : TMapEntry;
      FSet : TSetAdt;
      
   protected
      procedure SetOwnsItems(b : Boolean); override;
      procedure SetRepeatedItems(b : Boolean); override;
      function GetRepeatedItems : Boolean; override;
      procedure SetKeyComparer(cmp : IKeyBinaryComparer); override;
      function GetKeyComparer : IKeyBinaryComparer; override;
      
   public
      { returns a copier suitable for use by CopySelf method or the
        copy constructor; only the functor returned by this function
        can be passed to these methods as only it knows the internal
        structure of the map and how to copy both key and item }
      class function CreateCopier(const keyCopier : IKeyUnaryFunctor;
                                  const itemCopier : IItemUnaryFunctor) :
         TMapAdtCopier; override;
      
      { <aset> is a set for storing objects; appropriate disposers and
        comparers are automatically chosen in the constructor, basing
        on the type of the map; if you need to use non-standard ones
        set them later via Item/KeyDisposer/Comparer }
      constructor Create(aset : TSetAdt); overload;
      { calls the above constructor with aset = THashTable }
      constructor Create; overload;
      { creates a copy of <cont> }
      constructor CreateCopy(const cont : TMap;
                             const mapCopier : IUnaryFunctor); overload;
      { destroys itself }
      destructor Destroy; override;
      { returns a copy of self; the item copier must be one returned
        from CreateCopier }
      function CopySelf(const mapCopier : IUnaryFunctor) : TItemContainerAdt; override;
      { @see TMapAdt.Swap; }
      procedure Swap(cont : TItemContainerAdt); override;
      { returns the start iterator }
      function Start : TMapIterator; override;
      { returns the finish iterator }
      function Finish : TMapIterator; override;
      function Has(key : KeyType) : Boolean; override;
      function Find(key : KeyType) : ItemType; override;
      function Count(key : KeyType) : SizeType; override;
      procedure Associate(key : KeyType; aitem : ItemType); override;
      function Insert(pos : TMapIterator;
                      key : KeyType;
                      aitem : ItemType) : Boolean; overload; override; 
      function Insert(key : KeyType;
                      aitem : ItemType) : Boolean; overload; override; 
      procedure Delete(pos : TMapIterator); overload; override; 
      function Delete(key : KeyType) : SizeType; overload; override; 
      { returns the iterator starting the range of items associated
        with <key> }
      function LowerBound(key : KeyType) : TMapIterator; override;
      { returns the iterator that ends a range of items associated
        with <key> }
      function UpperBound(key : KeyType) : TMapIterator; override;
      { Returns the range <LowerBound, UpperBound). Works faster than
        calling these two functions separately. }
      function EqualRange(key : KeyType) : TMapIteratorRange; override;
      procedure Clear; override;
      function Empty : Boolean; override;
      function Size : SizeType; override;
      procedure SetKeyHasher(akeyhasher : IKeyHasher); override;
      { returns true if items in the map are in sorted order (defined
        by the keys they are associated with); checks if the
        underlying TSetAdt is a TSortedSetAdt }
      function IsSorted : Boolean; override;
   end;
   
   { an iterator into @<TMap> }
   TMapAdaptorIterator = class (TMapIterator)
   private
      FSIter : TSetIterator;
      FMap : TMap;
      
   public
      constructor Create(siter : TSetIterator; map : TMap);
      { returns an exact copy of self; i.e. copies all the data }
      function CopySelf : TItemIterator; override;
      { returns true if self and pos both point to the same item in
        the same collection }
      function Equal(const Pos : TItemIterator) : Boolean; override;
      { returns the key at the current position }
      function Key : KeyType; override;
      { returns item from the position pointed by self }
      function GetItem : ItemType; override;
      { sets the item at the position pointed to by iterator to aitem
        @see TContainerAdt.IsDefinedOrder, TSetIterator }
      procedure SetItem(aitem : ItemType); override;
      { exchanges the item pointed to by self with the one pointed
        to by the argument @see TContainerAdt.IsDefinedOrder, TSetIterator }
      procedure ExchangeItem(iter : TItemIterator); override;
      { moves self one position forward } 
      procedure Advance; overload; override; 
      { goes back one position }
      procedure Retreat; override;
      { inserts into the map (associates <aitem> with key) and moves to
        newly inserted position or to finish if item could not be
        inserted }
      procedure Insert(akey : KeyType; aitem : ItemType); override;
      { the same as @<Delete> but returns the item instead of
        disposing it; disposes the key anyway; }
      function Extract : ItemType; override;
      { deletes items from the range [self, finish); }
      function Delete(finish : TItemForwardIterator) : SizeType; overload; override;
      { returns the container into which self points }
      function Owner : TItemContainerAdt; override;
      { returns true if self is the first iterator }
      function IsStart : Boolean; override;
      { returns true if self is the 'one beyond last' iterator }
      function IsFinish : Boolean; override;
   end;
   
function CopyOf(const iter : TMapIterator) : TMapIterator; overload;   
function CopyOf(const iter : TMapAdaptorIterator) : TMapAdaptorIterator; overload;
