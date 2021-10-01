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
 adtfunct.inc::prefix:&_mcp_prefix&::item_type:&ItemType&
 }

&include adtfunct.defs

&if (&ItemType == Integer)
   &define _mcp_special_adapt_prefix Integer
&else
   &define _mcp_special_adapt_prefix &NULL
&endif

type
   { --------------------- General functor interfaces ------------------------ }

   { a functor taking one pointer argument and returning a pointer
     obtained by somehow transforming the argument; this functor
     should be prepared to handle nil-pointers }
   IUnaryFunctor = interface (IFunctor)
      { applies the functor to the given element, returns a
        transformed element; if the element is not changed by the
        functor, returns it unchanged }
      function Perform(aitem : ItemType) : ItemType;
   end;

   { a functor taking two pointer arguments and returning a pointer
     based on their values }
   IBinaryFunctor = interface (IFunctor)
      { applies the functor to the given elements, returns an element
        combined from both arguments; }
      function Perform(aitem1, aitem2 : ItemType) : ItemType;
   end;

   { a functor testing an item; returns a boolean value indicating
     whether the test was positive }
   IUnaryPredicate = interface (IFunctor)
      { returns the boolean result of applying the predicate to the element }
      function Test(aitem : ItemType) : Boolean;
   end;

   { a binary predicate; returns a boolean value basing on the values
     of its two arguments }
   IBinaryPredicate = interface (IFunctor)
      { returns the boolean result of applying the predicate to the
        arguments }
      function Test(aitem1, aitem2 : ItemType) : Boolean;
   end;

   { a functor used to compare items }
   IBinaryComparer = interface (IFunctor)
      { should return some value < 0 if aitem1 < aitem2, some value > 0 if aitem1 >
        aitem2 and 0 if aitem1 = aitem2 }
      function Compare(aitem1, aitem2 : ItemType) : Integer;
   end;

   { a comparer that allows the values of the items to be subtracted;
     it basically means that it must be possible to map the set all
     possible items to the set of integers, injectively }
   ISubtractor = interface (IBinaryComparer)
      { returns the difference Key(aitem2) - Key(aitem1); it should be a
        32-bit value; it is guaranteed that each key is uniquely
        identified by some 32-bit value }
      {@decl function Compare(aitem1, aitem2 : ItemType) : Integer; }
   end;

   { a functor used for hashing items }
   IHasher = interface (IFunctor)
      { should return an unsigned value; @see adtdefs.inc }
      function Hash(aitem : ItemType) : UnsignedType;
   end;

   { ------------------- Procedure/Function types ----------------------- }

   TUnaryProcedure = procedure(aitem : ItemType);
   TUnaryObjectProcedure = procedure(aitem : ItemType) of object;
   TBinaryProcedure = procedure(aitem1, aitem2 : ItemType);
   TBinaryObjectProcedure = procedure(aitem1, aitem2 : ItemType) of object;

   TUnaryFunction = function(aitem : ItemType) : ItemType;
   TUnaryObjectFunction = function(aitem : ItemType) : ItemType of object;
   TBinaryFunction = function(aitem1, aitem2 : ItemType) : ItemType;
   TBinaryObjectFunction = function(aitem1, aitem2 : ItemType) : ItemType of object;

   TUnaryBoolFunction = function(aitem : ItemType) : Boolean;
   TUnaryObjectBoolFunction = function(aitem : ItemType) : Boolean of object;
   TBinaryBoolFunction = function(aitem1, aitem2 : ItemType) : Boolean;
   TBinaryObjectBoolFunction = function(aitem1, aitem2 : ItemType) : Boolean of object;

   TBinaryIntegerFunction = function(aitem1, aitem2 : ItemType) : Integer;
   TBinaryObjectIntegerFunction =
      function(aitem1, aitem2 : ItemType) : Integer of object;

   { ---------------------- adaptors (wrappers) ---------------------------- }

   { TLess, TGreater and TEqual functors are wrappers around
     IBinaryComparer, which adapt it to the IBinaryPredicate
     interface; @until-next-comment; }

   TLess = class (TFunctor, IBinaryPredicate)
   private
      cmp : IBinaryComparer;
   public
      constructor Create(const c : IBinaryComparer);
      function Test(aitem1, aitem2 : ItemType) : Boolean;
   end;

   TGreater = class (TFunctor, IBinaryPredicate)
   private
      cmp : IBinaryComparer;
   public
      constructor Create(const c : IBinaryComparer);
      function Test(aitem1, aitem2 : ItemType) : Boolean;
   end;

   TEqual = class (TFunctor, IBinaryPredicate)
   private
      cmp : IBinaryComparer;
   public
      constructor Create(const c : IBinaryComparer);
      function Test(aitem1, aitem2 : ItemType) : Boolean;
   end;

   { the TxxxBinder functors are provided purely for efficiency
     reasons; they perfrom the same work as the functor obtained from
     the consequent application of Txxx (TLess, TEqual, ...) and then
     TBind2nd; the pointer passed to the constructor is not owned by
     the object and not disposed with its destruction unless you
     provide a disposer; @until-next-comment; }
   TLessBinder = class (TFunctor, IUnaryPredicate)
   private
      cmp : IBinaryComparer;
      aitem2 : ItemType;
      disposer : IUnaryFunctor;
   public
      constructor Create(const c : IBinaryComparer; p : ItemType); overload;
      constructor Create(const c : IBinaryComparer; p : ItemType;
                         const disp : IUnaryFunctor); overload;
      destructor Destroy; override;
      function Test(p : ItemType) : Boolean;
      property Item : ItemType read aitem2 write aitem2;
   end;

   TGreaterBinder = class (TFunctor, IUnaryPredicate)
   private
      cmp : IBinaryComparer;
      aitem2 : ItemType;
      disposer : IUnaryFunctor;
   public
      constructor Create(const c : IBinaryComparer; p : ItemType); overload;
      constructor Create(const c : IBinaryComparer; p : ItemType;
                         const disp : IUnaryFunctor); overload;
      destructor Destroy; override;
      function Test(p : ItemType) : Boolean;
      property Item : ItemType read aitem2 write aitem2;
   end;

   TEqualBinder = class (TFunctor, IUnaryPredicate)
   private
      cmp : IBinaryComparer;
      aitem2 : ItemType;
      disposer : IUnaryFunctor;
   public
      constructor Create(const c : IBinaryComparer; p : ItemType); overload;
      constructor Create(const c : IBinaryComparer; p : ItemType;
                         const disp : IUnaryFunctor); overload;
      destructor Destroy; override;
      function Test(p : ItemType) : Boolean;
      property Item : ItemType read aitem2 write aitem2;
   end;

   { ---------------------- Specific functors --------------------------- }

   { an identity functor; useful in connection with functions
     manipulating functors }
   TIdentity = class (TFunctor, IUnaryFunctor)
   public
      { does nothing; returns its argument; useful when copying
        containers but not items themselves }
      function Perform(aitem : ItemType) : ItemType;
   end;

{ ----------------------- routines ---------------------- }

{ adapts <f> to the unary functor interface so that it performs its
  operation and then nil returned instead of returning the argument;
  appropriate for disposers }
function AdaptReturnNil(f : TUnaryProcedure) : IUnaryFunctor; overload;
function AdaptObjectReturnNil(f : TUnaryObjectProcedure) : IUnaryFunctor; overload;

{ adapts <f> to the standard functor interface; if <f> is a procedure
  taking one argument then the functor returns its argument; if <f> is
  a procedure taking two arguments then the functor returns nil; }
function Adapt(f : TUnaryProcedure) : IUnaryFunctor; overload;
function Adapt(f : TBinaryProcedure) : IBinaryFunctor; overload;
function Adapt(f : TUnaryFunction) : IUnaryFunctor; overload;
function Adapt(f : TBinaryFunction) : IBinaryFunctor; overload;
function Adapt(f : TUnaryBoolFunction) : IUnaryPredicate; overload;
function Adapt(f : TBinaryBoolFunction) : IBinaryPredicate; overload;
function &_mcp_special_adapt_prefix&Adapt(f : TBinaryIntegerFunction) : IBinaryComparer; overload;

{ adapts an object method <f> to the standard functor interface; if
  <f> is a procedure then the functor returns its argument; @See Adapt }
function AdaptObject(f : TUnaryObjectProcedure) : IUnaryFunctor; overload;
function AdaptObject(f : TBinaryObjectProcedure) : IBinaryFunctor; overload;
function AdaptObject(f : TUnaryObjectFunction) : IUnaryFunctor; overload;
function AdaptObject(f : TBinaryObjectFunction) : IBinaryFunctor; overload;
function AdaptObject(f : TUnaryObjectBoolFunction) : IUnaryPredicate; overload;
function AdaptObject(f : TBinaryObjectBoolFunction) : IBinaryPredicate; overload;
function &_mcp_special_adapt_prefix&AdaptObject(f : TBinaryObjectIntegerFunction) : IBinaryComparer; overload;

{ converts IBinaryComparer to corresponding IBinaryPredicate tests }
function LessTest(const comparer : IBinaryComparer) : IBinaryPredicate;
function GreaterTest(const comparer : IBinaryComparer) : IBinaryPredicate;
function EqualTest(const comparer : IBinaryComparer) : IBinaryPredicate;

{ returns a predicate which returns true if its argument is equal to
  aitem with respect to comparer }
function EqualTo(const comparer : IBinaryComparer;
                 aitem : ItemType) : IUnaryPredicate; overload;
function EqualTo(const comparer : IBinaryComparer; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryPredicate; overload;

{ returns a predicate which returns true if its argument is less than
  aitem with respect to comparer }
function LessThan(const comparer : IBinaryComparer;
                  aitem : ItemType) : IUnaryPredicate; overload;
function LessThan(const comparer : IBinaryComparer; aitem : ItemType;
                  const disposer : IUnaryFunctor) : IUnaryPredicate; overload;

{ returns a predicate which returns true if its argument is greater than
  aitem with respect to comparer }
function GreaterThan(const comparer : IBinaryComparer;
                     aitem : ItemType) : IUnaryPredicate; overload;
function GreaterThan(const comparer : IBinaryComparer; aitem : ItemType;
                     const disposer : IUnaryFunctor) : IUnaryPredicate; overload;

{ binds aitem to the first argument of pred; In other words, the
  following: @code f := Bind1st(pred, aitem); ... x := f.Perform(aitem2); @end-code
  is equivalent to @code ... x := pred.Perform(aitem, aitem2); @end-code <ptr> will
  not be disposed automatically; @see Bind2nd, Bind1st[2] }
function Bind1st(const pred : IBinaryPredicate;
                 aitem : ItemType) : IUnaryPredicate; overload;
function Bind1st(const fun : IBinaryFunctor;
                 aitem : ItemType) : IUnaryFunctor; overload;

{ the same as above but binds to the second argument; }
function Bind2nd(const pred : IBinaryPredicate;
                 aitem : ItemType) : IUnaryPredicate; overload;
function Bind2nd(const fun : IBinaryFunctor;
                 aitem : ItemType) : IUnaryFunctor; overload;

{ binds aitem to fun; the returned functor always uses aitem as the
  argument to fun, regardless of the pointer actually passed to it;
  aitem is _not_ disposed automatically; }
function Bind(const fun : IUnaryFunctor;
              aitem : ItemType) : IUnaryFunctor; overload;

{ binds aitem to the first argument of pred; uses disposer to
  automatically dispose aitem, i.e. aitem is owned by the returned object;
  pred is owned by the returned object }
function Bind1st(const pred : IBinaryPredicate; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryPredicate; overload;
function Bind1st(const fun : IBinaryFunctor; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryFunctor; overload;

function Bind2nd(const pred : IBinaryPredicate; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryPredicate; overload;
function Bind2nd(const fun : IBinaryFunctor; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryFunctor; overload;

function Bind(const fun : IUnaryFunctor; aitem : ItemType;
              const disposer : IUnaryFunctor) : IUnaryFunctor; overload;

{ negates its predicate argument; in other words, @code
  Negate(pred).Test(aitem) @end-code is equivalent to @code not pred.Test(aitem)
  @end-code; }
function Negate(const pred : IUnaryPredicate) : IUnaryPredicate; overload;
function Negate(const pred : IBinaryPredicate) : IBinaryPredicate; overload;

{ returns an unary predicate returning true if and only if both pred1
  and pred2 return true for its argument }
function PredAnd(const pred1, pred2 : IUnaryPredicate) : IUnaryPredicate; overload;

{ returns an unary predicate returning true if and only if pred1 or
  pred2 returns true for its argument }
function PredOr(const pred1, pred2 : IUnaryPredicate) : IUnaryPredicate; overload;

{ returns an unary predicate returning true if and only if either
  pred1 or pred2 returns true for its argument, but not both }
function PredXor(const pred1, pred2 : IUnaryPredicate) : IUnaryPredicate; overload;


{ calling the returned functor is equivalent to f(g(x)); }
function Compose_F_Gx(const f, g : IUnaryFunctor) : IUnaryFunctor; overload;

{ calling the returned functor is equivalent to f(g(x, y)); }
function Compose_F_Gxy(const f : IUnaryFunctor;
                       const g : IBinaryFunctor) : IBinaryFunctor; overload;

{ calling the returned functor is equivalent to f(g(x), h(y)); }
function Compose_F_Gx_Hy(const f : IBinaryFunctor;
                         const g, h : IUnaryFunctor) : IBinaryFunctor; overload;

{ returns a TIdentity; it is more efficient to call this function
  instead of creating TIdentity directly, because here an existing
  object is reused intead of creating a new one }
function &_mcp_prefix&Identity : IUnaryFunctor;
