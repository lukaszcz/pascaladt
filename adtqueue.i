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
 adtqueue.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtqueue.defs

type

{ ======================= Circular double-ended queue ======================== }
   
   TCircularDequeIterator = class;

   { Implements a 0-based circular double-ended queue. A circular
     deque (double-ended queue) uses one array to store its items. The
     array is treated as circular, e.g. if there is not enough place
     at the front to push an item, the sequence of items 'wraps
     around' and the item is stored at the back of the allocated
     place. Requires reallocation only when the whole preallocated
     space becomes used-up.  }
   TCircularDeque = class (TArrayAdt)
   private
      FItems : TDynamicArray;

   protected
      { returns the current capacity of the container }
      function GetCapacity : SizeType; override;
      { sets the capacity to cap, but only if cap is bigger than current capacity }
      procedure SetCapacity(cap : SizeType); override;

   public
      constructor Create; overload;
      constructor CreateCopy(const cont : TCircularDeque;
                             const itemCopier : IUnaryFunctor); overload;
      destructor Destroy; override;
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      function RandomAccessStart : TRandomAccessIterator; override;
      function RandomAccessFinish : TRandomAccessIterator; override;
      { returns an iterator to the first Item in the deque }
      function Start : TCircularDequeIterator;
      { returns an iterator to the 'one beyond last' Item in the deque }
      function Finish : TCircularDequeIterator;
      function GetItem(index : IndexType) : ItemType; override;
      procedure SetItem(index : IndexType; aitem : ItemType); override;
      procedure Insert(index : IndexType; aitem : ItemType); overload; override;
      procedure Delete(index : IndexType); overload; override; 
      function Delete(starti : IndexType;
                      n : SizeType) : SizeType; overload; override; 
      function Extract(index : IndexType) : ItemType; overload; override; 
      function Front : ItemType; override;
      function Back : ItemType; override;
      procedure PushFront(aitem : ItemType); override;
      procedure PopFront; override;
      procedure PushBack(aitem : ItemType); override;
      procedure PopBack; override;
      procedure Clear; override;
      { returns true if the deque is empty, false otherwise }
      function Empty : Boolean; override;
      function Size : SizeType; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
   end;
   
   TCircularDequeIterator = class(TRandomAccessContainerIterator)
   public
      function CopySelf : TIterator; override;
      { exchanges items at positions i and j relative to self }
      procedure ExchangeItemsAt(i, j : IndexType); override;
   end;

{ =============== Segmented implementation of double-ended queue ============= }

   TSegDequeIterator = class;

   { Implements a 0-based deque using segments. A segmented
     double-ended queue stores its items in several segments. It
     prevents the whole array from being reallocated when it the whole
     preallocated memory becomes used-up. Only a new segment is
     allocated and the already-present segments are left intact. Using
     segments makes accessing an item at a given index a bit slower
     than in an ordinary array or in @<TCircularDeque>, but it still
     takes constant time.  }
   TSegDeque = class (TArrayAdt)
   private
      FItems : TSegArray;
   protected
      { returns the current capacity of the container }
      function GetCapacity : SizeType; override;
      { sets the capacity to <cap>, but only if <cap> is bigger than
        the current capacity }
      procedure SetCapacity(cap : SizeType); override;

   public
      constructor Create; overload;
      constructor CreateCopy(const cont : TSegDeque;
                             const itemCopier : IUnaryFunctor); overload;
      destructor Destroy; override;
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      function RandomAccessStart : TRandomAccessIterator; override;
      function RandomAccessFinish : TRandomAccessIterator; override;
      { returns an iterator to the first Item in the deque }
      function Start : TSegDequeIterator;
      { returns an iterator to the 'one beyond last' Item in the deque }
      function Finish : TSegDequeIterator;
      function GetItem(index : IndexType) : ItemType; override;
      procedure SetItem(index : IndexType; aitem : ItemType); override;
      procedure Insert(index : IndexType; aitem : ItemType); overload; override;
      procedure Delete(index : IndexType); overload; override; 
      function Delete(starti : IndexType;
                      n : SizeType) : SizeType; overload; override; 
      function Extract(index : IndexType) : ItemType; overload; override; 
      function Front : ItemType; override;
      function Back : ItemType; override;
      procedure PushFront(aitem : ItemType); override;
      procedure PopFront; override;
      procedure PushBack(aitem : ItemType); override;
      procedure PopBack; override;
      procedure Clear; override;
      function Empty : Boolean; override;
      function Size : SizeType; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
   end;

   TSegDequeIterator = class(TRandomAccessContainerIterator)
   public
      function CopySelf : TIterator; override;
      { exchanges items at positions i and j relative to self }
      procedure ExchangeItemsAt(i, j : IndexType); override;
   end;

   { the default deque type }
   T&_mcp_prefix&Deque = TSegDeque;

