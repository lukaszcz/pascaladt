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
 adtdarray.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtdarray.defs


type
   { dynamic array of pointers; this is used as a low-level interface to
     memory for some PascalADT library containers. Memory allocated
     using this structure is guaranteed to be stored in one block. It
     is not safe to have multiple dynamic arrays variables pointing to
     one physical array, since the array may be reallocated and its
     address changed. Allocator field is the allocator used to
     allocate and dispose the array. It is _not_ owned by the array
     and will _not_ be destroyed when it's deallocated, so you have to
     manage it yourself. If it's nil then GetMem, FreeMem and
     ReallocMem are used. Indicies are zero-based. StartIndex field is
     a physical index at which elements start (logical - given by the
     user - and physical indicies are not the same). The array may be
     used either as circular or normal. When used as circular all
     elements which do not exceed the physical upper array boundary
     are stored from the physical beginning of the array. Routines
     manipulating array as circular have ArrayCircular- prefix, normal
     routines have Array- prefix. Don't use this structure directly,
     but TDynamicArray instead. @See TDynamicArray, TSegArray. }
   TDynamicArrayRec = record
      StartIndex : IndexType;
      Size, Capacity : SizeType;
      Items : array of ItemType
   end;
   { @See TDynamicArrayRec }
   TDynamicArray = ^TDynamicArrayRec;
   { @See TDynamicArray, TDynamicArrayRec }
   PDynamicArray = ^TDynamicArray;
   
   { This is basically the same as TDynamicArray but with no
     StartIndex and Size fields to save space. Intended primarily for
     temporary buffers. @see TDynamicArray. }
   TDynamicBufferRec = record
      Capacity : SizeType;
      Items : array of ItemType;
   end;
   { @see TDynamicBufferRec, TDynamicArray }
   TDynamicBuffer = ^TDynamicBufferRec;
   { @see TDynamicBuffer }
   PDynamicBuffer = ^TDynamicBuffer;
   
   
{ allocates a new dynamic array. Previous content is lost (but not
  disposed). No items are reserved for use. Argument StartIndex is the
  absolute physical index from which the array will begin (you can
  always reset it by direct manipulation of the array structure) }
procedure ArrayAllocate(var a : TDynamicArray; capacity : SizeType;
                        StartIndex : IndexType); overload;

{ Reallocates the array - i.e. sets its capacity. }   
procedure ArrayReallocate(var a : TDynamicArray; newcap : SizeType); overload;

{ Disposes the array. If the array is nil than nothing
  happens. Assings nil to a. }
procedure ArrayDeallocate(var a : TDynamicArray); overload;

{ clears the state of the array and sets new capacity and StartIndex;
  sets Size to zero }
procedure ArrayClear(var a : TDynamicArray; capacity : SizeType;
                     StartIndex : IndexType); overload;

{ Grows the array by the factor of daGrowRate if StartIndex+Size+n <=
  capacity*daGrowRate and capacity < deMaxMemChunk. If capacity >=
  deMaxMemChunk and StartIndex+Size+n <= capacity + deMaxMemChunk then
  grows array by deMaxMemChunk, otherwise grows the array by n. }
procedure ArrayExpand(var a : TDynamicArray; n : SizeType); overload;

{ returns pointer stored at index }
function ArrayGetItem(const a : TDynamicArray;
                      index : IndexType) : ItemType; overload;

{ Sets item at index to elem. Returns the item previously stored there. }
function ArraySetItem(a : TDynamicArray; index : IndexType;
                      elem : ItemType) : ItemType; overload;

{ Reserves n items starting at position index. The place for new items
  is made in the range [index, index + n). All items being previously
  stored within this range are moved right. The array is reallocated
  if necessary to hold the new items (by calling Expand). }
procedure ArrayReserveItems(var a : TDynamicArray;
                            index : IndexType; n : SizeType); overload;

{ Removes n items starting at <index> from the array. In other words
  the range of items [index, index + n) is removed. All items after
  this range are moved left. }
procedure ArrayRemoveItems(a : TDynamicArray; index : IndexType;
                           n : SizeType); overload;

{ pushes elem at the front of the array. This takes O(n) time when
  a^.StartIndex = 0. LeaveSpaceAtFront indicates if to leave some more
  space at the front if StartIndex is 0 - increase StartIndex (true), or if
  to leave StartIndex unchanged (false). }
procedure ArrayPushFront(var a : TDynamicArray; elem : ItemType;
                         leaveSpaceAtFront : Boolean); overload;

{ pushes elem at the back of the array. }
procedure ArrayPushBack(var a : TDynamicArray; elem : ItemType); overload;

{ pops element from the front and returns it. Boolean argument
  iftomove indicates if items are to be moved left so that
  a^.StartIndex remains unchanged (true) or if to increase
  a^.StartIndex without moving the items (false).  This takes O(n)
  time if iftomove = true. }
function ArrayPopFront(a : TDynamicArray; iftomove : Boolean) : ItemType; overload;

{ pops element from the back and returns it. }
function ArrayPopBack(a : TDynamicArray) : ItemType; overload;

{ copies everything in the array to another array (i.e. makes an exact
  copy, even of unreserved items). Re-allocates dest if it's non-nil,
  allocates new array otherwise. alloc is used as a new allocator for
  dest (don't forget to destroy the old one!). }
procedure ArrayCopy(const src : TDynamicArray; var dest : TDynamicArray); overload;

{ applies proc to each reserved element }
procedure ArrayApplyFunctor(a : TDynamicArray;
                            const proc : IUnaryFunctor); overload;


{ routines treating TDynamicArray as circular }


{ Moves elements in the array circularly, i.e. when n + srcIndex >=
  Capacity the remaining number of elements (n + srcIndex - Capacity +
  1) are moved from the beginning. }
procedure ArrayCircularMove(a : TDynamicArray; srcIndex, destIndex : IndexType;
                            n : SizeType); overload;

{ expands array to hold at least n more elements.Treats array as
  circular starting at index a^.StartIndex }
procedure ArrayCircularExpand(var a : TDynamicArray; n : SizeType); overload;

{ converts logical index into circular array into an absolute index
  into the same array (physically) }
function ArrayCircularLogicalToAbs(const a : TDynamicArray;
                                   logindex : IndexType) : IndexType; overload;

{ returns item at logical index, treating array as circular }
function ArrayCircularGetItem(const a : TDynamicArray;
                              index : IndexType) : ItemType; overload;

{ sets item at logical index, treating array as circular; returns the old item }
function ArrayCircularSetItem(a : TDynamicArray; index : IndexType;
                              elem : ItemType) : ItemType; overload;

{ reserves items circularly; StartIndex is the absolute index of the
  first item in the logical circular array; the space for n elements
  is reserved after index, when there is not enough space at after the
  index and there is enough space at the beginning some elements are
  moved to the beginning. }
procedure ArrayCircularReserveItems(var a : TDynamicArray;
                                    index : IndexType; n : SizeType); overload;

{ removes n elements beginning at logical index; treats array as
  circular with first absolute index = a^.StartIndex.  }
procedure ArrayCircularRemoveItems(a : TDynamicArray;
                                   index : IndexType; n : SizeType); overload;

{ pushes elem at the front of the array. Treats array circularly. }
procedure ArrayCircularPushFront(var a : TDynamicArray;
                                 elem : ItemType); overload;

{ pushes elem at the back of the array. Treats array circularly.  }
procedure ArrayCircularPushBack(var a : TDynamicArray;
                                elem : ItemType); overload;

{ pops element from the front and returns it. Treats array circularly.. }
function ArrayCircularPopFront(a : TDynamicArray) : ItemType; overload;

{ pops element from the back and returns it. Treats array circularly. }
function ArrayCircularPopBack(a : TDynamicArray) : ItemType; overload;

{ applies proc to each reserved element }
procedure ArrayCircularApplyFunctor(a : TDynamicArray;
                                    const proc : IUnaryFunctor); overload;


{ Some rudimentary routines for TDynamicBuffer. @discard-comment }
{ Note: TDynamicBuffers should not used anymore in new code, since
  dynamic arrays were introduced into the language. They are kept
  mostly because TSegArray heavily depends on them. }


{ Allocates a buffer of Size = capacity * SizeOf(ItemType). }
procedure BufferAllocate(var b : TDynamicBuffer; capacity : SizeType); overload;

{ Reallocates buffer. }
procedure BufferReallocate(var b : TDynamicBuffer; newcap : SizeType); overload;

{ Deallocates buffer. If buffer is nil than does nothing. Sets b to
  nil. }
procedure BufferDeallocate(var b : TDynamicBuffer); overload;

{ Expands buffer to hold at least n more items. If capacity <
  bufMaxMemChunk then the new capacity becomes capacity * bufGrowRate,
  otherwise it becomes capacity + bufMaxMemChunk. If n + capacity is
  greater than any of the chosen capacities, it becomes the new
  capacity. }
procedure BufferExpand(var b : TDynamicBuffer; n : SizeType); overload;

{ copies everything in the buffer to another buffer.  Re-allocates
  dest if it's non-nil, allocates new buffer otherwise. }
procedure BufferCopy(const src : TDynamicBuffer;
                     var dest : TDynamicBuffer); overload;
