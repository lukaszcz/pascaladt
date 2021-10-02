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
 adtcontbase.inc::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtcontbase.defs

type
   { The base class for all PascalAdt containers. PascalAdt containers
     store pointers to objects or variables. The items in any such
     container should satisfy two requirements: (1) nil pointers
     cannot be stored, (2) no two equal pointer values should be
     stored in one container, i.e. the objects/variables pointed to
     may be equal but not the pointers themselves. The second
     requirement must be satisfied only for sets and maps,
     i.e. descendants of TSetAdt or TMapAdt (see @<adtcont>.pas; }
   TContainerAdt = class
   private
      FDisposer : IUnaryFunctor;
      FGrabageCollector : TGrabageCollector;
      FOwnsItems : Boolean;

   protected
      {$warnings off }
      constructor Create; overload;
      { creates self as a copy of cont; this should be called by every
        'copy-constructor' of a descendant container }
      constructor CreateCopy(const cont : TContainerAdt); overload;
      {$warnings on }

      procedure SetOwnsItems(b : Boolean); virtual;
      procedure SetDisposer(const proc : IUnaryFunctor); virtual;
      function GetDisposer : IUnaryFunctor; virtual;
      { swaps basic functors, everything except for the items }
      procedure BasicSwap(cont : TContainerAdt); virtual;
{$ifdef TEST_PASCAL_ADT }
      { Writes some information about the container to the log  }
      procedure WriteLog(msg : String); overload;
      procedure WriteLog; overload;
{$endif TEST_PASCAL_ADT }

   public
      { deletes all items; @complexity O(n). }
      destructor Destroy; override;

{$ifdef TEST_PASCAL_ADT }
      { writes out some information about the container to the log file }
      procedure LogStatus(mname : String); virtual;
      { formats aitem for displaying it }
      function FormatItem(aitem : ItemType) : String;
{$endif TEST_PASCAL_ADT }

      { returns a copy of self. copies all the data into the new
        object of then same type. Uses ItemCopier to copy items. This
        functor should return exact copy of item, i.e. the new object
        that can be modified and destroyed without changing the
        original one. If the passed copier is nil then the items
        should not be copied, but only an empty container of the same
        type as self and using the same disposer, comparer, hasher,
        etc. @complexity O(n). }
      function CopySelf(const ItemCopier :
                        IUnaryFunctor) : TContainerAdt; virtual; abstract; overload;
      { calls CopySelf with the identity functor }
      function CopySelf : TContainerAdt; overload;
      { swaps the content with <cont>; the types of items used by both
        containers should be the same if the containers are not of the
        same type; if they are the types of items may be different; if
        self and <cont> are of the same type then it takes O(1) time,
        otherwise O(m+n) time and O(min(m,n)) memory, where n and m
        are the sizes of the containers (using the default
        implementation); if <cont> and self are of different types
        then no guarantee is made on the order of items in the swapped
        containers; in other words, they are only guaranteed to
        exchange items, but where the items will be in the internal
        structure of the containers cannot be determined; the default
        implementation of this method is not entirely exception safe
        if InsertItem or ExtractItem in any of the containers raise
        exceptions; it does not leak anything but may destroy some
        user data in case of an exception; }
      procedure Swap(cont : TContainerAdt); virtual;
      { inserts aitem somewhere into the container; returns true if
        successful, false if aitem could not be inserted }
      { @postcondition Result implies Size = old Size + 1 }
      { @postcondition not Result implies Size = old Size }
      function InsertItem(aitem : ItemType) : Boolean; virtual; abstract;
      { removes some item from the container and returns it }
      { @precondition CanExtract }
      { @postcondition Size = old Size - 1 }
      function ExtractItem : ItemType; virtual; abstract;
      { returns true if an item may be extracted by ExtractItem; this
        is not necessarily equivalent to not Empty }
      { @postcondition Empty implies not Result }
      function CanExtract : Boolean; virtual; abstract;
      { clears the container - removes all items; @complexity O(n). }
      { @postcondition Empty }
      procedure Clear; virtual; abstract;
      { returns true if container is empty; equivalent to Size = 0,
        but may be faster; @complexity guaranteed worst-case O(1). }
      function Empty : Boolean; virtual; abstract;
      { returns the number of items; @complexity guaranteed average,
        amortized or worst-case O(1) and never more than worst-case
        O(n). }
      function Size : SizeType; virtual; abstract;
      { Returns true if the container has a well-defined, internal
        order of items. Examples of such containers are THeap, TSet,
        ... You cannot insert at any position you wish, because there
        is a well-defined, fixed relationship between the items'
        values and their positions. That's why such containers cannot
        be sorted or applied any algorithms that change the order of
        items. ExchangeItem, SetItem, Insert and Delete methods of
        these containers' iterators usually raise exceptions or
        perform some different action than desribed for general,
        abstract iterator interfaces. They should not be used in any
        generic routines which use these methods, and expect them to
        work as desribed. All algorithms that cannot be used with
        iterators into defined-order containers are marked so in their
        description. It is a programming error to pass such iterators
        to these routines, and the behaviour is undefined (possibly
        assertion failed if compiling in DEBUG mode, but not
        always). }
      function IsDefinedOrder : Boolean; virtual; abstract;
      { if OwnsItems is true and Disposer <> nil and aitem <> nil then
        this procedure invokes Disposer to dispose the given Item }
      procedure &expand-non-prefixed-off DisposeItem &expand-non-prefixed-on
         (aitem : ItemType);
      { indicates whether Items are automatically deleted when removed
        from the container; always true on creation of the container }
      property OwnsItems : Boolean read FOwnsItems write SetOwnsItems;
      { returns the grabage collector used to keep track of iterators }
      property GrabageCollector : TGrabageCollector read FGrabageCollector;
      { gives the functor used to destroy items (nil if none is set);
        remember that this functor is still owned by the container and
        will be destroyed automatically with it }
      property ItemDisposer : IUnaryFunctor read GetDisposer write SetDisposer;

      { @inv Empty <=> Size = 0 }
   end;
