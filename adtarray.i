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
 adtarray.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtarray.defs

type
   { --------------------------- TArray --------------------------------- }
   
   TArrayIterator = class;
   
   TArray = class (TArrayAdt)
   private
      FItems : TDynamicArray;
      firstIndex : IndexType;

   protected
      { returns the current capacity of the container }
      function GetCapacity : SizeType; override;
      { sets the capacity to cap, but only if cap is bigger than
        the current capacity }
      procedure SetCapacity(cap : SizeType); override;
      
   public
      { afirstIndex is the base index; i.e. the first index at which
        the array starts }
      constructor Create(afirstIndex : IndexType); overload;
      { the same as above, but assumes <afirstIndex> = 0 }
      constructor Create; overload;
      { creates a copy of <cont>; if <itemCopier> = nil then does not copy
        the items }
      constructor CreateCopy(const cont : TArray;
                             const itemCopier : IUnaryFunctor); overload;
      { destroyes the container }
      destructor Destroy; override;
      { returns an iterator pointing to the first element }
      function RandomAccessStart : TRandomAccessIterator; override;
      { returns an iterator to the one beyond last element }
      function RandomAccessFinish : TRandomAccessIterator; override;
      { returns the start iterator }
      function Start : TArrayIterator;
      { returns the finish iterator }
      function Finish : TArrayIterator;
      { returns a copy of self }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { swaps self with <cont>; @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { returns the element at the given index }
      function GetItem(index : IndexType) : ItemType; override;
      { sets the element at the given index }
      procedure SetItem(index : IndexType; elem : ItemType); override;
      { inserts item at index, i.e. the new element will be at
        position index; items from range <index,finish) are moved
        rightwards. }
      procedure Insert(index : IndexType;
                       aitem : ItemType); overload; override;
      { deletes element at index; all items after index are moved
        leftwards }
      procedure Delete(index : IndexType); overload; override;
      { deletes n items beginning with start }
      function Delete(astart : IndexType;
                      n : SizeType) : SizeType; overload; override;
      { Removes the item at <index> from the container, but does not
        dispose it. Returns the removed item. }
      function Extract(index : IndexType) : ItemType; overload; override; 
      { pushes elem at the back }
      procedure PushBack(aitem : ItemType); override;
      { pushes aitem at the front; @complexity O(n) }
      procedure PushFront(aitem : ItemType); override;
      { deletes the element at the back of the container }
      procedure PopBack; override;
      { deletes the element at the front of the container; @complexity
        O(n) }
      procedure PopFront; override;
      { returns the element at the back }
      function Back : ItemType; override;
      { returns the element at the front }
      function Front : ItemType; override;
      { clears the container - removes all items; @complexity O(n). }
      procedure Clear; override;
      { returns true if container is empty; equivalent to Size = 0,
        but may be faster; @complexity guaranteed worst-case O(1). }
      function Empty : Boolean; override;
      { returns the number of items; @complexity guaranteed average,
        amortized or worst-case O(1) and never more than worst-case
        O(n). }
      function Size : SizeType; override;
      { returns the lowest index in the collection }
      function LowIndex : IndexType; override;
      { returns the highest index in the collection }
      function HighIndex : IndexType; override;
      { sets the lowest (first) index; returns the old one; }
      function SetLowIndex(ind : IndexType) : IndexType;
   end;
      
   TArrayIterator = class (TRandomAccessContainerIterator)
   public
      { returns an exact copy of self; i.e. copies all the data }
      function CopySelf : TIterator; override;
      { exchanges items at positions i and j relative to self }
      procedure ExchangeItemsAt(i, j : IndexType); override;
   end;
   
   { --------------------------- TStack ---------------------------------- }
   T&_mcp_prefix&Stack = TArray;
   
   { ------------------------- TPascalArray ------------------------------ }
   
   TPascalArrayType = array of ItemType;
   TPascalArrayIterator = class;
   
   { Provides a wrapper for the Delphi dynamic array, allowing it to
     be used in the algorithms of PascalAdt library.  }
   TPascalArray = class (TArrayAdt)
   private
      FPascalArray : TPascalArrayType;
      
   protected
      { returns the current capacity of the container }
      function GetCapacity : SizeType; override;
      { sets the capacity to cap, but only if cap is bigger than
        the current capacity }
      procedure SetCapacity(cap : SizeType); override;
      
   public
      constructor Create(pascalArray : TPascalArrayType); overload;
      { creates a copy of cont; if itemCopier = nil then does not copy
        the items }
      constructor CreateCopy(const cont : TPascalArray;
                             const itemCopier : IUnaryFunctor); overload;
      { destroyes the container }
      destructor Destroy; override;
      { returns an iterator pointing to the first element }
      function RandomAccessStart : TRandomAccessIterator; override;
      { returns an iterator to the one beyond last element }
      function RandomAccessFinish : TRandomAccessIterator; override;
      { returns the start iterator }
      function Start : TPascalArrayIterator;
      { returns the finish iterator }
      function Finish : TPascalArrayIterator;
      { returns a copy of self }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { swaps self with <cont>; @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { returns the element at the given index }
      function GetItem(index : IndexType) : ItemType; override;
      { sets the element at the given index }
      procedure SetItem(index : IndexType; elem : ItemType); override;
      { inserts item at index, i.e. the new element will be at
        position index; items from range <index,finish) are moved
        rightwards. }
      procedure Insert(index : IndexType;
                       aitem : ItemType); overload; override;
      { deletes element at index; all items after index are moved
        leftwards }
      procedure Delete(index : IndexType); overload; override;
      { deletes n items beginning with start }
      function Delete(astart : IndexType;
                      n : SizeType) : SizeType; overload; override;
      { Removes the item at <index> from the container, but does not
        dispose it. Returns the removed item. }
      function Extract(index : IndexType) : ItemType; overload; override; 
      { pushes elem at the back }
      procedure PushBack(aitem : ItemType); override;
      { pushes aitem at the front; @complexity O(n) }
      procedure PushFront(aitem : ItemType); override;
      { deletes the element at the back of the container }
      procedure PopBack; override;
      { deletes the element at the front of the container; @complexity
        O(n) }
      procedure PopFront; override;
      { returns the element at the back }
      function Back : ItemType; override;
      { returns the element at the front }
      function Front : ItemType; override;
      { clears the container - removes all items; @complexity O(n). }
      procedure Clear; override;
      { returns true if container is empty; equivalent to Size = 0,
        but may be faster; @complexity guaranteed worst-case O(1). }
      function Empty : Boolean; override;
      { returns the number of items; @complexity guaranteed average,
        amortized or worst-case O(1) and never more than worst-case
        O(n). }
      function Size : SizeType; override;
      property PascalArray : TPascalArrayType read FPascalArray;
   end;
   
   TPascalArrayIterator = class (TRandomAccessContainerIterator)
   public
      { returns an exact copy of self; i.e. copies all the data }
      function CopySelf : TIterator; override;
      { exchanges items at positions i and j relative to self }
      procedure ExchangeItemsAt(i, j : IndexType); override;
   end;
   

