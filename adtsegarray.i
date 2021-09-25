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
 adtsegarray.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtsegarray.defs

type
   { This is a segmented array. Each segment has a capacity of
     saSegmentCapacity. The segment at Segments[FirstSegIndex] is
     guaranteed to be always valid (allocated). }
   TSegArrayRec = record
      Size : SizeType;
      FirstSegIndex, LastSegIndex : IndexType;
      InnerStartIndex : IndexType;
      ItemsInLastSeg : SizeType;
      Segments : &<TPointerDynamicArray>; { this is a dynamic array of @<TDynamicBuffer>s  }
   end;
   { @see TSegArrayRec }
   TSegArray = ^TSegArrayRec;
   PSegArray = ^TSegArray;

{ Allocates a segmented array. If alloc is nil then menages memory
  with standard routines. The allocator is not owned by the array and
  will not be destroyed with its deallocation! }
procedure SegArrayAllocate(var a : TSegArray;
                           segments : SizeType;
                           StartIndex1, StartIndex2 : IndexType); overload;

{ Deallocates a segmented array. If <a> is nil then nothing
  happens. The argument <a> is set to nil. }
procedure SegArrayDeallocate(var a : TSegArray); overload;

{ Clears the state of a TSegArray. Reallocates the array to have
  <segments> segments, from which only one will be allocated. If
  <segments> is <= 0, then leaves 1 segment. }
procedure SegArrayClear(var a : TSegArray; segments : SizeType); overload;

{ Expands the array towards right (back) to hold at least n more elements. }
procedure SegArrayExpandRight(a : TSegArray; n : SizeType); overload;

{ Expands the array towards left (front) to hold at least n more elements.  }
procedure SegArrayExpandLeft(a : TSegArray; n : SizeType); overload;

{ Converts a logical index into <a> to a (segment,offset) pair. }
procedure SegArrayLogicalToSegOff(const a : TSegArray; index : IndexType;
                                  var segment, offset : IndexType); overload; _mcp_inline

{ Returns the element at an absolute logical index.  }
function SegArrayGetItem(const a : TSegArray;
                         index : IndexType) : ItemType; overload;

{ Sets an element at an absolute logical index. Returns the old
  element. }
function SegArraySetItem(a : TSegArray; index : IndexType;
                         elem : ItemType) : ItemType; overload;

{ Pushes an element at the front of the array. }
procedure SegArrayPushFront(a : TSegArray; elem : ItemType); overload;

{ Pushes an element at the back. }
procedure SegArrayPushBack(a : TSegArray; elem : ItemType); overload;

{ Pops an element from the front and returns it. }
function SegArrayPopFront(a : TSegArray) : ItemType; overload;

{ Pops an element from the back and returns it. }
function SegArrayPopBack(a : TSegArray) : ItemType; overload;

{ Reserves n items starting at index. }
procedure SegArrayReserveItems(a : TSegArray; index : IndexType;
                               n : SizeType); overload;

{ Removes n items starting at index. Deallocates space if it can (the
  space for storing elements, i.e. some segments, not the elements
  themselves!). }
procedure SegArrayRemoveItems(a : TSegArray; index : IndexType;
                              n : SizeType); overload;

{ Copies all the data from <src> to <dest>. Anything in <dest> is
  lost. <dest> can be nil. }
procedure SegArrayCopy(const src : TSegArray; var dest : TSegArray); overload;

{ Applies a functor to every reserved item. }
procedure SegArrayApplyFunctor(a : TSegArray;
                               const proc : IUnaryFunctor); overload;

