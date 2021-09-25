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
 adtlist.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtlist.defs

type
{ ============================ Singly linked list ============================ }

   { a node of a singly linked list @see &TSingleList&
     @include-declarations 2 }
   PSingleListNode = ^TSingleListNode;
   TSingleListNode = record
      Item : ItemType;
      Next : PSingleListNode;
   end;
   
   TSingleListIterator = class;

   { implements a singly linked list }
   TSingleList = class (TListAdt)
   private
      FStartNode : PSingleListNode;
      FFinishNode : PSingleListNode;
      FSize : SizeType;
      { this field is true when FSize indicates correct number of
        Items; if it's false then number of Items must be
        calculated }
      FValidSize : Boolean;      
      
      procedure InitFields;
      procedure DisposeNodeAndItem(node : PSingleListNode);
      { sets the given item }
      procedure DoSetItem(pos : PSingleListNode; aitem : ItemType);
      { DoMove, unlike other DoXXX methods, does not maintain FSize
        item Sizeer, so the callee needs to update it itself }
      procedure DoMove(dest, source1, source2 : PSingleListNode;
                       list2 : TSingleList);
   public
      constructor Create; overload;
      { a copy-constructor; creates self as a copy of <cont>; uses
        <itemCopier> to copy the items from cont }
      constructor CreateCopy(const cont : TSingleList;
                             const itemCopier : IUnaryFunctor); overload;
      destructor Destroy; override;
      { returns a copy of self, i.e. copies all the data into the new
        object of the same type }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap; }
      procedure Swap(cont : TContainerAdt); override;
      { returns the start iterator; @see Tutorial }
      function ForwardStart : TForwardIterator; override;
      { returns the finish iterator; @see Tutorial }
      function ForwardFinish : TForwardIterator; override;
      { returns the start iterator }
      function Start : TSingleListIterator;
      { returns the finish iterator }
      function Finish : TSingleListIterator;
      { inserts aitem at position pos; iterator pos is invalidated }
      procedure Insert(pos : TForwardIterator; aitem : ItemType); override;
      { deletes the item pointed to by the iterator pos; frees the
        item if @<OwnsItems> is true; }
      procedure Delete(pos : TForwardIterator); override;
      { deletes all items in the range [start,finish); returns the
        number of deleted items; @complexity O(n), where n is the
        number of items in the range }
      function Delete(astart, afinish : TForwardIterator) : SizeType; override;
      { deletes the item pointed to by the iterator pos; this
        procedure does not free the item itself even if @<OwnsItems>
        is true; returns the removed item }
      function Extract(pos : TForwardIterator) : ItemType; override;
      { moves the item pointed by Source before the position Dest;
        Dest must be a non-finish iterator into this list, Source may
        point into another list. }
      procedure Move(Source, Dest : TForwardIterator); overload; override;
      { moves the items from the range [SourceStart, SourceFinish)
        before the position Dest; SourceStart and SourceFinish must be
        in the same list, and Dest must be in the list on which this
        method is called. }
      procedure Move(SourceStart, SourceFinish,
                     Dest : TForwardIterator); overload; override;
      { returns the first item in the list }
      function Front : ItemType; override;
      { returns the last item in the list }
      function Back : ItemType; override;
      { adds an item at the back of the list }
      procedure PushBack(aitem : ItemType); override;
      { adds an item at the front of the list }
      procedure PushFront(aitem : ItemType); override;
      { pops an item from the back; for a singly linked list it takes
        O(n) time }
      procedure PopBack; override;
      { pops an item from the front of the list }
      procedure PopFront; override;
      { deletes all items }
      procedure Clear; override;
      { returns true if the list does not contain any items, false
        otherwise; it is equivalent to Size = 0, but may be faster }
      function Empty : Boolean; override;
      { returns the number of items }
      function Size : SizeType; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
      
      { returns a pointer to the start node in the list; this property
        should be used only in performance-critical code as it does
        not adhere to the common container interface }
      property StartNode : PSingleListNode read FStartNode;
      { returns the pointer to the finish node in the list; this
        property should be used only in performance-critical code as
        it does not adhere to the common container interface }
      property FinishNode : PSingleListNode read FFinishNode;
      { inserts <ptr> at <pos>; pos points to the newly inserted node;
        returns the pointer to the created node; this method should be
        used only in performance-critical code as it does not adhere
        to the common container interface }
      function InsertNode(pos : PSingleListNode; aitem : ItemType) : PSingleListNode;
      { extracts the item at <pos> and returns it (without deleting);
        the node at <pos> is removed from the list; <pos> points to
        the next node; this method should be used only in
        performance-critical code as it does not adhere to the common
        container interface }
      function ExtractNode(pos : PSingleListNode) : ItemType;
      { allocates a new node using @<Allocator> }
      procedure NewNode(var node : PSingleListNode);
      { disposes node using @<Allocator> }
      procedure DisposeNode(node : PSingleListNode);
   end;

   { an iterator into a singly linked list (@<TSingleList>) }
   TSingleListIterator = class (TForwardIterator)
   private
      Node : PSingleListNode;
      FList : TSingleList;
   public
      { creates a new iterator; <list> is the owner of <xnode> }
      constructor Create(xnode : PSingleListNode; list : TSingleList);
      { returns a copy of <self> }
      function CopySelf : TIterator; override;
      { advances the iterator to the next item }
      procedure Advance; overload; override;
      { retrieves the item stored at the position pointed by the
        iterator }
      function GetItem : ItemType; override;
      { assigns aitem to the item at the position pointed to by the
        iterator }
      procedure SetItem(aitem : ItemType); override;
      { exchanges the item pointed to by <self> with the one pointed
        to by the argument }
      procedure ExchangeItem(iter : TIterator); override;
      { the same as @<Delete> but returns the item instead of disposing it }
      function Extract : ItemType; override;
      { deletes items from the range [self, finish); after the
        deletion the iterator points to finish; invalidates all other
        iterators (in general); returns the number of items deleted;
        after the deletion the iterator points to <afinish> }
      function Delete(afinish : TForwardIterator) :
         SizeType; overload; override; 
      { inserts an item before the position of <self>; leaves <self>
        pointing to after the inserted item (unchanged) }
      procedure Insert(aitem : ItemType); override;
      { returns true if <pos> points to the same position as <self> }
      function Equal(const pos : TIterator) : Boolean; override;
      { returns the container into which <self> points }
      function Owner : TContainerAdt; override;
      { returns true if <self> is the first iterator - the start
        iterator }
      function IsStart : Boolean; override;
      { returns true if <self> is the 'one beyond last' iterator - the
        finish iterator }
      function IsFinish : Boolean; override;
   end;

{ ============================ Doubly linked list ============================ }

   { a doubly-linked list node. @see TDoubleList @include-declarations
     2 }
   PDoubleListNode = ^TDoubleListNode;
   TDoubleListNode = record
      Item : ItemType;
      Next : PDoubleListNode;
      Prev : PDoubleListNode;
   end;
   
   TDoubleListIterator = class;

   { implements a doubly linked list }
   TDoubleList = class (TDoubleListAdt)
   private
      FStartNode : PDoubleListNode;
      FSize : SizeType;
      { this field is true when FSize indicates correct number of
        items; if it's false then number of Items must be
        re-calculated }
      FValidSize : Boolean;
      
      function GetFinishNode : PDoubleListNode;
{$ifdef INLINE_DIRECTIVE_IN_INTERFACE }
      inline;
{$endif }
      procedure InitFields;
      procedure DisposeNodeAndItem(node : PDoubleListNode);
      procedure DoSetItem(pos : PDoubleListNode; aitem : ItemType);
      { DoMove, unlike other DoXXX methods, does not maintain FSize
        item Sizeer, so the callee needs to update it itself }
      procedure DoMove(dest, source1, source2 : PDoubleListNode;
                       list2 : TDoubleList);
   public
      constructor Create; overload;
      { a copy-constructor; creates self as a copy of cont; uses
        itemCopier to copy items from cont }
      constructor CreateCopy(const cont : TDoubleList;
                             const itemCopier : IUnaryFunctor); overload;
      destructor Destroy; override;
      { returns a copy of self, i.e. copies all the data into the new
        object of then same type }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap; }
      procedure Swap(cont : TContainerAdt); override;
      function ForwardStart : TForwardIterator; override;
      function ForwardFinish : TForwardIterator; override;
      { returns the start iterator }
      function Start : TDoubleListIterator;
      { returns the finish iterator }
      function Finish : TDoubleListIterator;
      procedure Insert(pos : TForwardIterator; aitem : ItemType); override;
      procedure Delete(pos : TForwardIterator); override;
      function Delete(astart, afinish : TForwardIterator) : SizeType; override;
      function Extract(pos : TForwardIterator) : ItemType; override;
      { moves the item pointed by Source before the position Dest;
        Dest must be a non-finish iterator into this list, Source may
        point into another list. }
      procedure Move(Source, Dest : TForwardIterator); overload; override;
      { moves the items from the range [SourceStart, SourceFinish)
        before the position Dest; SourceStart and SourceFinish must be
        in the same list, and Dest must be in the list on which this
        method is called. }
      procedure Move(SourceStart, SourceFinish,
                     Dest : TForwardIterator); overload; override;
      { returns the first item in the list }
      function Front : ItemType; override;
      { returns the last item in the list }
      function Back : ItemType; override;
      { adds an item at the back of the list }
      procedure PushBack(aitem : ItemType); override;
      { pops an item from the back of the list }
      procedure PopBack; override;
      { adds an item at the front of the list }
      procedure PushFront(aitem : ItemType); override;
      { pops an item from the front of the list }
      procedure PopFront; override;
      { deletes all Items }
      procedure Clear; override;
      { returns true if the list does not contain any items, false
        otherwise; it is equivalent to Size = 0, but may be faster }
      function Empty : Boolean; override;
      { returns the number of items }
      function Size : SizeType; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
      
      { returns a pointer to the start node in the list; this property
        should be used only in performance-critical code as it does
        not adhere to the common container interface }
      property StartNode : PDoubleListNode read FStartNode;
      { returns a pointer to the finish node in the list; this
        property should be used only in performance-critical code as
        it does not adhere to the common container interface }
      property FinishNode : PDoubleListNode read GetFinishNode;
      { inserts aitem at pos; pos is left unchanged (except that its
        Prev field points at the newly inserted node); returns the
        pointer to the created node; this method should be used only
        in performance-critical code as it does not adhere to the
        common container interface }
      function InsertNode(pos : PDoubleListNode; aitem : ItemType) : PDoubleListNode;
      { extracts the item at pos and returns it (without deleting);
        pos becomes an invalid pointer; this method should be used
        only in performance-critical code as it does not adhere to the
        common container interface }
      function ExtractNode(pos : PDoubleListNode) : ItemType;
      { allocates a new node using allocator }
      procedure NewNode(var node : PDoubleListNode);
      { disposes a node using allocator }
      procedure DisposeNode(node : PDoubleListNode);
   end;

   { an iterator into a doubly linked list }
   TDoubleListIterator = class (TBidirectionalIterator)
   private
      Node : PDoubleListNode;
      FList : TDoubleList;
   public
      { creates new iterator; the list is the owner of xnode }
      constructor Create(xnode : PDoubleListNode; list : TDoubleList);
      function CopySelf : TIterator; override;
      procedure Advance; overload; override; 
      procedure Retreat; override;
      function Equal(const pos : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
      procedure SetItem(aitem : ItemType); override;
      procedure ExchangeItem(iter : TIterator); override;
      function Extract : ItemType; override;
      function Delete(afinish : TForwardIterator) :
         SizeType; overload; override; 
      procedure Insert(aitem : ItemType); override;
      function Owner : TContainerAdt; override;
      function IsStart : Boolean; override;
      function IsFinish : Boolean; override;
   end;

{ ================================= XOR list ================================= }

   { a XOR list node }
   TXListNode = record
      Item : ItemType;
      PN : PointerValueType;
   end;
   PXListNode = ^TXListNode;
   
   TXorListIterator = class;

   { Implements a XOR list. A XOR list is essentially a doubly-linked
     list, but it uses a dirty trick of xor'ing the next and previous
     node pointers together, thanks to which it uses the same amount
     of memory as a singly-linked list. Generally, TDoubleList should
     be used, and TXorList only in critical code where low memory
     usage is vital.  }
   TXorList = class (TDoubleListAdt)
   private
      FStartNode : PXListNode;
      BackNode : PXListNode; { truly last node, i.e. NOT one beyond last }
      FSize : SizeType;
      { this field is true when FSize indicates correct number of Items;
         if it's false then the number of Items must be re-calculated }
      FValidSize : Boolean;
      
      procedure InitFields;
      { allocates new node using allocator }
      procedure NewNode(var node : PXListNode);
      { disposes node using allocator }
      procedure DisposeNode(node : PXListNode);
      procedure DisposeNodeAndItem(node : PXListNode);
      procedure DoSetItem(pos : PXListNode; aitem : ItemType);
      { returns the pointer to the created node, prev - node before pos }
      function DoInsert(pos, prev : PXListNode; aitem : ItemType) : PXListNode;
      { returns the node to be disposed, prev - node before pos }
      function DoDelete(pos, prev : PXListNode) : PXListNode;
      { DoMove, unlike other DoXXX methods, does not maintain FSize
        item Sizeer, so the callee needs to update it itself;
        prevdest - node before dest, prevs1 - node before source1,
        prevs2 - node before source2; moves [source1, source2) to
        between destprev and dest }
      procedure DoMove(dest, prevdest,
                       source1, prevs1,
                       source2, prevs2 : PXListNode; list2 : TXorList);
      procedure DoClear;
   public
      constructor Create; overload;
      { a copy-constructor; creates self as a copy of cont; uses
        itemCopier to copy items from cont }
      constructor CreateCopy(const cont : TXorList;
                             const itemCopier : IUnaryFunctor); overload;
      destructor Destroy; override;
      { returns a copy of self, i.e. copies all the data into the new
        object of then same type }
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap; }
      procedure Swap(cont : TContainerAdt); override;
      function ForwardStart : TForwardIterator; override;
      function ForwardFinish : TForwardIterator; override;
      { returns an iterator to the first item in the list (the start
        iterator) }
      function Start : TXorListIterator;
      { returns an iterator pointing to one position after the end of
        list (the finish iterator) }
      function Finish : TXorListIterator;
      { inserts <ptr> at the position <pos> }
      procedure Insert(pos : TForwardIterator; aitem : ItemType); override;
      { deletes the item pointed to by the iterator pos }
      procedure Delete(pos : TForwardIterator); override;
      { deletes all items in the range [start,finish); returns the
        number of deleted items; @complexity O(n), where n is the
        number of items in the range }
      function Delete(astart, afinish : TForwardIterator) : SizeType; override;
      function Extract(pos : TForwardIterator) : ItemType; override;
      procedure Move(Source, Dest : TForwardIterator); overload; override;
      procedure Move(SourceStart, SourceFinish,
                     Dest : TForwardIterator); overload; override;
      function Front : ItemType; override;
      function Back : ItemType; override;
      procedure PushBack(aitem : ItemType); override;
      procedure PopBack; override;
      procedure PushFront(aitem : ItemType); override;
      procedure PopFront; override;
      procedure Clear; override;
      function Empty : Boolean; override;
      function Size : SizeType; override;
      { returns false }
      function IsDefinedOrder : Boolean; override;
   end;

   { an iterator into a XOR list }
   TXorListIterator = class (TBidirectionalIterator)
   private
      Node : PXListNode;
      Prev : PXListNode;
      FList : TXorList;
   protected
      { creates a new iterator }
      {$warnings off }
      constructor Create(thisnode, prevnode : PXListNode; list : TXorList);
      {$warnings on }
   public
      function CopySelf : TIterator; override;
      procedure Advance; overload; override; 
      procedure Retreat; override;
      function Equal(const pos : TIterator) : Boolean; override;
      function GetItem : ItemType; override;
      procedure SetItem(aitem : ItemType); override;
      procedure ExchangeItem(iter : TIterator); override;
      function Extract : ItemType; override;
      function Delete(afinish : TForwardIterator) :
         SizeType; overload; override; 
      procedure Insert(aitem : ItemType); override;
      function Owner : TContainerAdt; override;
      function IsStart : Boolean; override;
      function IsFinish : Boolean; override;
   end;
   
   
{ ---------------------------- Useful routines ---------------------------------- }

function CopyOf(const iter : TSingleListIterator) : TSingleListIterator; overload;
function CopyOf(const iter : TDoubleListIterator) : TDoubleListIterator; overload;
function CopyOf(const iter : TXorListIterator) : TXorListIterator; overload;


