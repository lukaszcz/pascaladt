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
 adtfunct_impl.inc::prefix:&_mcp_prefix&::item_type:&ItemType&
 }

&include adtfunct.defs
&include adtfunct_impl.mcp

&if (&ItemType == Integer)
   &define _mcp_special_adapt_prefix Integer
&else
   &define _mcp_special_adapt_prefix &NULL
&endif

var
   var&_mcp_prefix&Identity : IUnaryFunctor;

type
   { -------------- Procedure/Function adaptors (wrappers) -------------------- }

   TUnaryProcedureAdaptor = class (TFunctor, IUnaryFunctor)
   private
      proc : TUnaryProcedure;
      retItem : Boolean;
   public
      { returnItem - true to return a given item, false to return DefaultItem }
      constructor Create(p : TUnaryProcedure; returnItem : Boolean);
      { performs the operation defined by its first constructor argument }
      function Perform(aitem : ItemType) : ItemType;
   end;

   TUnaryObjectProcedureAdaptor = class (TFunctor, IUnaryFunctor)
   private
      proc : TUnaryObjectProcedure;
      retItem : Boolean;
   public
      { returnItem - true to return given item, false to return DefaultItem }
      constructor Create(p : TUnaryObjectProcedure; returnItem : Boolean);
      { performs the operation defined by its first constructor argument }
      function Perform(aitem : ItemType) : ItemType;
   end;

   TBinaryProcedureAdaptor = class (TFunctor, IBinaryFunctor)
   private
      proc : TBinaryProcedure;
   public
      constructor Create(p : TBinaryProcedure);
      { performs the operation defined by its first constructor
        argument; always returns DefaultItem }
      function Perform(aitem1, aitem2 : ItemType) : ItemType;
   end;

   TBinaryObjectProcedureAdaptor = class (TFunctor, IBinaryFunctor)
   private
      proc : TBinaryObjectProcedure;
   public
      constructor Create(p : TBinaryObjectProcedure);
      { performs the operation defined by its first constructor
        argument; always returns  }
      function Perform(aitem1, aitem2 : ItemType) : ItemType;
   end;

   TUnaryFunctionAdaptor = class (TFunctor, IUnaryFunctor)
   private
      fun : TUnaryFunction;
   public
      constructor Create(f : TUnaryFunction);
      { performs the operation defined by its constructor argument }
      function Perform(aitem : ItemType) : ItemType;
   end;

   TUnaryObjectFunctionAdaptor = class (TFunctor, IUnaryFunctor)
   private
      fun : TUnaryObjectFunction;
   public
      constructor Create(f : TUnaryObjectFunction);
      { performs the operation defined by its constructor argument }
      function Perform(aitem : ItemType) : ItemType;
   end;

   TBinaryFunctionAdaptor = class (TFunctor, IBinaryFunctor)
   private
      fun : TBinaryFunction;
   public
      constructor Create(f : TBinaryFunction);
      { performs the operation defined by its constructor argument }
      function Perform(aitem1, aitem2 : ItemType) : ItemType;
   end;

   TBinaryObjectFunctionAdaptor = class (TFunctor, IBinaryFunctor)
   private
      fun : TBinaryObjectFunction;
   public
      constructor Create(f : TBinaryObjectFunction);
      { performs the operation defined by its constructor argument }
      function Perform(aitem1, aitem2 : ItemType) : ItemType;
   end;

   TUnaryBoolFunctionAdaptor = class (TFunctor, IUnaryPredicate)
   private
      fun : TUnaryBoolFunction;
   public
      constructor Create(f : TUnaryBoolFunction);
      { performs the operation defined by its constructor argument }
      function Test(aitem : ItemType) : Boolean;
   end;

   TUnaryObjectBoolFunctionAdaptor = class (TFunctor, IUnaryPredicate)
   private
      fun : TUnaryObjectBoolFunction;
   public
      constructor Create(f : TUnaryObjectBoolFunction);
      { performs the operation defined by its constructor argument }
      function Test(aitem : ItemType) : Boolean;
   end;

   TBinaryBoolFunctionAdaptor = class (TFunctor, IBinaryPredicate)
   private
      fun : TBinaryBoolFunction;
   public
      constructor Create(f : TBinaryBoolFunction);
      { performs the operation defined by its constructor argument }
      function Test(aitem1, aitem2 : ItemType) : Boolean;
   end;

   TBinaryObjectBoolFunctionAdaptor = class (TFunctor, IBinaryPredicate)
   private
      fun : TBinaryObjectBoolFunction;
   public
      constructor Create(f : TBinaryObjectBoolFunction);
      { performs the operation defined by its constructor argument }
      function Test(aitem1, aitem2 : ItemType) : Boolean;
   end;

   TBinaryIntegerFunctionAdaptor = class (TFunctor, IBinaryComparer)
   private
      fun : TBinaryIntegerFunction;
   public
      constructor Create(f : TBinaryIntegerFunction);
      { performs the operation defined by its constructor argument }
      function Compare(aitem1, aitem2 : ItemType) : Integer;
   end;

   TBinaryObjectIntegerFunctionAdaptor = class (TFunctor,IBinaryComparer)
   private
      fun : TBinaryObjectIntegerFunction;
   public
      constructor Create(f : TBinaryObjectIntegerFunction);
      { performs the operation defined by its constructor argument }
      function Compare(aitem1, aitem2 : ItemType) : Integer;
   end;

   { ---------------------- other adaptors --------------------------- }

   TPredicateBinder1st = class (TFunctor, IUnaryPredicate)
   private
      bpred : IBinaryPredicate;
      aitem1 : ItemType;
      disposer : IUnaryFunctor;
   public
      { aitemDisposer, if non-nil, is used to dispose <p> when the
        functor is destroyed }
      constructor Create(const pr : IBinaryPredicate; p : ItemType;
                         const aitemDisposer : IUnaryFunctor);
      destructor Destroy; override;
      function Test(aitem : ItemType) : Boolean;
   end;

   TPredicateBinder2nd = class (TFunctor, IUnaryPredicate)
   private
      bpred : IBinaryPredicate;
      aitem2 : ItemType;
      disposer : IUnaryFunctor;
   public
      { aitemDisposer, if non-nil, is used to dispose <p> when the
        functor is destroyed }
      constructor Create(const pr : IBinaryPredicate; p : ItemType;
                         const aitemDisposer : IUnaryFunctor);
      destructor Destroy; override;
      function Test(aitem : ItemType) : Boolean;
   end;

   TFunctorBinder1st = class (TFunctor, IUnaryFunctor)
   private
      bfun : IBinaryFunctor;
      aitem1 : ItemType;
      disposer : IUnaryFunctor;
   public
      { aitemDisposer, if non-nil, is used to dispose <p> when the
        functor is destroyed }
      constructor Create(const f : IBinaryFunctor; p : ItemType;
                         const aitemDisposer : IUnaryFunctor);
      destructor Destroy; override;
      function Perform(aitem : ItemType) : ItemType;
   end;

   TFunctorBinder2nd = class (TFunctor, IUnaryFunctor)
   private
      bfun : IBinaryFunctor;
      aitem2 : ItemType;
      disposer : IUnaryFunctor;
   public
      { aitemDisposer, if non-nil, is used to dispose <p> when the
        functor is destroyed }
      constructor Create(const f : IBinaryFunctor; p : ItemType;
                         const aitemDisposer : IUnaryFunctor);
      destructor Destroy; override;
      function Perform(aitem : ItemType) : ItemType;
   end;

   TUnaryFunctorBinder = class (TFunctor, IUnaryFunctor)
   private
      fun : IUnaryFunctor;
      Fptr : ItemType;
      disposer : IUnaryFunctor;
   public
      { is disp is nil then the pointer is not disposed }
      constructor Create(const f : IUnaryFunctor; p : ItemType;
                         const disp : IUnaryFunctor);
      destructor Destroy; override;
      function Perform(aitem : ItemType) : ItemType;
   end;


   TBinaryPredicateNegator = class (TFunctor, IBinaryPredicate)
   private
      bpred : IBinaryPredicate;
   public
      constructor Create(const p : IBinaryPredicate);
      function Test(aitem1, aitem2 : ItemType) : Boolean;
   end;

   TUnaryPredicateNegator = class (TFunctor, IUnaryPredicate)
   private
      pred : IUnaryPredicate;
   public
      constructor Create(const p : IUnaryPredicate);
      function Test(aitem : ItemType) : Boolean;
   end;

   { ------------------------- PredXXX --------------------------- }

   TPredAnd = class (TFunctor, IUnaryPredicate)
   private
      pred1, pred2 : IUnaryPredicate;
   public
      constructor Create(const apred1, apred2 : IUnaryPredicate);
      function Test(aitem : ItemType) : Boolean;
   end;

   TPredOr = class (TFunctor, IUnaryPredicate)
   private
      pred1, pred2 : IUnaryPredicate;
   public
      constructor Create(const apred1, apred2 : IUnaryPredicate);
      function Test(aitem : ItemType) : Boolean;
   end;

   TPredXor = class (TFunctor, IUnaryPredicate)
   private
      pred1, pred2 : IUnaryPredicate;
   public
      constructor Create(const apred1, apred2 : IUnaryPredicate);
      function Test(aitem : ItemType) : Boolean;
   end;

   { -------------------------- Composers --------------------------- }

   TFunctorComposer_F_Gx = class (TFunctor, IUnaryFunctor)
   private
      f, g : IUnaryFunctor;
   public
      constructor Create(const af, ag : IUnaryFunctor);
      function Perform(aitem : ItemType) : ItemType;
   end;

   TFunctorComposer_F_Gxy = class (TFunctor, IBinaryFunctor)
   private
      f : IUnaryFunctor;
      g : IBinaryFunctor;
   public
      constructor Create(const af : IUnaryFunctor; const ag : IBinaryFunctor);
      function Perform(aitem1, aitem2 : ItemType) : ItemType;
   end;

   TFunctorComposer_F_Gx_Hy = class (TFunctor, IBinaryFunctor)
   private
      f : IBinaryFunctor;
      g, h : IUnaryFunctor;
   public
      constructor Create(const af : IBinaryFunctor;
                         const ag, ah : IUnaryFunctor);
      function Perform(aitem1, aitem2 : ItemType) : ItemType;
   end;

{ ======================== Local helper routines ============================ }

{ ---------------------- TUnaryProcedureAdaptor --------------------------- }

constructor TUnaryProcedureAdaptor.Create(p : TUnaryProcedure;
                                          returnItem : Boolean);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   proc := p;
   retItem := returnItem;
end;

function TUnaryProcedureAdaptor.Perform(aitem : ItemType) : ItemType;
begin
   proc(aitem);
   if retItem then
      Result := aitem
   else
      Result := DefaultItem;
end;

{ -------------------- TUnaryObjectProcedureAdaptor ------------------------- }

constructor TUnaryObjectProcedureAdaptor.Create(p : TUnaryObjectProcedure;
                                                returnItem : Boolean);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   proc := p;
   retItem := returnItem;
end;

function TUnaryObjectProcedureAdaptor.Perform(aitem : ItemType) : ItemType;
begin
   proc(aitem);
   if retItem then
      Result := aitem
   else
      Result := DefaultItem;
end;

{ ---------------------- TBinaryProcedureAdaptor --------------------------- }

constructor TBinaryProcedureAdaptor.Create(p : TBinaryProcedure);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   proc := p;
end;

function TBinaryProcedureAdaptor.Perform(aitem1, aitem2 : ItemType) : ItemType;
begin
   proc(aitem1, aitem2);
   Result := DefaultItem;
end;

{ ------------------ TBinaryObjectProcedureAdaptor --------------------------- }

constructor TBinaryObjectProcedureAdaptor.Create(p : TBinaryObjectProcedure);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   proc := p;
end;

function TBinaryObjectProcedureAdaptor.Perform(aitem1, aitem2 : ItemType) : ItemType;
begin
   proc(aitem1, aitem2);
   Result := DefaultItem;
end;

{ ---------------------- TUnaryFunctionAdaptor --------------------------- }

constructor TUnaryFunctionAdaptor.Create(f : TUnaryFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TUnaryFunctionAdaptor.Perform(aitem : ItemType) : ItemType;
begin
   Result := fun(aitem);
end;

{ -------------------- TUnaryObjectFunctionAdaptor --------------------------- }

constructor TUnaryObjectFunctionAdaptor.Create(f : TUnaryObjectFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TUnaryObjectFunctionAdaptor.Perform(aitem : ItemType) : ItemType;
begin
   Result := fun(aitem);
end;

{ ---------------------- TBinaryFunctionAdaptor --------------------------- }

constructor TBinaryFunctionAdaptor.Create(f : TBinaryFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TBinaryFunctionAdaptor.Perform(aitem1, aitem2 : ItemType) : ItemType;
begin
   Result := fun(aitem1, aitem2);
end;

{ -------------------- TBinaryObjectFunctionAdaptor --------------------------- }

constructor TBinaryObjectFunctionAdaptor.Create(f : TBinaryObjectFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TBinaryObjectFunctionAdaptor.Perform(aitem1, aitem2 : ItemType) : ItemType;
begin
   Result := fun(aitem1, aitem2);
end;

{ ---------------------- TUnaryBoolFunctionAdaptor --------------------------- }

constructor TUnaryBoolFunctionAdaptor.Create(f : TUnaryBoolFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TUnaryBoolFunctionAdaptor.Test(aitem : ItemType) : Boolean;
begin
   Result := fun(aitem);
end;

{ -------------------- TUnaryObjectBoolFunctionAdaptor ------------------------ }

constructor TUnaryObjectBoolFunctionAdaptor.Create(f : TUnaryObjectBoolFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TUnaryObjectBoolFunctionAdaptor.Test(aitem : ItemType) : Boolean;
begin
   Result := fun(aitem);
end;

{ ---------------------- TBinaryBoolFunctionAdaptor --------------------------- }

constructor TBinaryBoolFunctionAdaptor.Create(f : TBinaryBoolFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TBinaryBoolFunctionAdaptor.Test(aitem1, aitem2 : ItemType) : Boolean;
begin
   Result := fun(aitem1, aitem2);
end;

{ --------------------- TBinaryObjectBoolFunctionAdaptor ---------------------- }

constructor TBinaryObjectBoolFunctionAdaptor.
   Create(f : TBinaryObjectBoolFunction);
begin
   fun := f;
end;

function TBinaryObjectBoolFunctionAdaptor.Test(aitem1, aitem2 : ItemType) : Boolean;
begin
   Result := fun(aitem1, aitem2);
end;

{ -------------------- TBinaryIntegerFunctionAdaptor -------------------------- }

constructor TBinaryIntegerFunctionAdaptor.Create(f : TBinaryIntegerFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function TBinaryIntegerFunctionAdaptor.Compare(aitem1, aitem2 : ItemType) : Integer;
begin
   Result := fun(aitem1, aitem2);
end;

{ ---------------- TBinaryObjectIntegerFunctionAdaptor ------------------------ }

constructor
   TBinaryObjectIntegerFunctionAdaptor.Create(f : TBinaryObjectIntegerFunction);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
end;

function
   TBinaryObjectIntegerFunctionAdaptor.Compare(aitem1, aitem2 : ItemType) : Integer;
begin
   Result := fun(aitem1, aitem2);
end;

{ ------------------------- TPredicateBinder1st --------------------------------- }

constructor TPredicateBinder1st.Create(const pr : IBinaryPredicate; p : ItemType;
                                       const aitemDisposer : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   bpred := pr;
   aitem1 := p;
   disposer := aitemDisposer;
end;

function TPredicateBinder1st.Test(aitem : ItemType) : Boolean;
begin
   Result := bpred.Test(aitem1, aitem);
end;

destructor TPredicateBinder1st.Destroy;
begin
   if disposer <> nil then
      _mcp_dispose_item(aitem1, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ---------------- TPredicateBinder2nd -------------------- }

constructor TPredicateBinder2nd.Create(const pr : IBinaryPredicate; p : ItemType;
                                       const aitemDisposer : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   bpred := pr;
   aitem2 := p;
   disposer := aitemDisposer;
end;

function TPredicateBinder2nd.Test(aitem : ItemType) : Boolean;
begin
   Result := bpred.Test(aitem, aitem2);
end;

destructor TPredicateBinder2nd.Destroy;
begin
   if (disposer <> nil) then
      _mcp_dispose_item(aitem2, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ------------------------- TFunctorBinder1st --------------------------------- }

constructor TFunctorBinder1st.Create(const f : IBinaryFunctor; p : ItemType;
                                     const aitemDisposer : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   bfun := f;
   aitem1 := p;
   disposer := aitemDisposer;
end;

function TFunctorBinder1st.Perform(aitem : ItemType) : ItemType;
begin
   Result := bfun.Perform(aitem1, aitem);
end;

destructor TFunctorBinder1st.Destroy;
begin
   if (disposer <> nil) then
      _mcp_dispose_item(aitem1, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ------------------------- TFunctorBinder2nd --------------------------------- }

constructor TFunctorBinder2nd.Create(const f : IBinaryFunctor; p : ItemType;
                                     const aitemDisposer : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   bfun := f;
   aitem2 := p;
   disposer := aitemDisposer;
end;

function TFunctorBinder2nd.Perform(aitem : ItemType) : ItemType;
begin
   Result := bfun.Perform(aitem, aitem2);
end;

destructor TFunctorBinder2nd.Destroy;
begin
   if (disposer <> nil) then
      _mcp_dispose_item(aitem2, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ------------------- TUnaryFunctorBinder ----------------------------- }

constructor TUnaryFunctorBinder.Create(const f : IUnaryFunctor; p : ItemType;
                                       const disp : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   fun := f;
   Fptr := p;
   disposer := disp;
end;

function TUnaryFunctorBinder.Perform(aitem : ItemType) : ItemType;
begin
   Result := fun.Perform(Fptr);
end;

destructor TUnaryFunctorBinder.Destroy;
begin
   if (disposer <> nil) then
      _mcp_dispose_item(Fptr, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ------------------- TBinaryPredicateNegator ----------------------------- }

constructor TBinaryPredicateNegator.Create(const p : IBinaryPredicate);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   bpred := p;
end;

function TBinaryPredicateNegator.Test(aitem1, aitem2 : ItemType) : Boolean;
begin
   Result := not bpred.Test(aitem1, aitem2);
end;

{ --------------------- TUnaryPredicateNegator --------------------------- }

constructor TUnaryPredicateNegator.Create(const p : IUnaryPredicate);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   pred := p;
end;

function TUnaryPredicateNegator.Test(aitem : ItemType) : Boolean;
begin
   Result := not pred.Test(aitem);
end;

{ --------------------------- TPredAnd ------------------------------ }

constructor TPredAnd.Create(const apred1, apred2 : IUnaryPredicate);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   pred1 := apred1;
   pred2 := apred2;
end;

function TPredAnd.Test(aitem : ItemType) : Boolean;
begin
   Result := pred1.Test(aitem) and pred2.Test(aitem);
end;

{ --------------------------- TPredOr ------------------------------ }

constructor TPredOr.Create(const apred1, apred2 : IUnaryPredicate);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   pred1 := apred1;
   pred2 := apred2;
end;

function TPredOr.Test(aitem : ItemType) : Boolean;
begin
   Result := pred1.Test(aitem) or pred2.Test(aitem);
end;

{ --------------------------- TPredXor ------------------------------ }

constructor TPredXor.Create(const apred1, apred2 : IUnaryPredicate);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   pred1 := apred1;
   pred2 := apred2;
end;

function TPredXor.Test(aitem : ItemType) : Boolean;
begin
   Result := pred1.Test(aitem) xor pred2.Test(aitem);
end;

{ ---------------------- TFunctorComposer_F_Gx ---------------------- }

constructor TFunctorComposer_F_Gx.Create(const af, ag : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   f := af;
   g := ag;
end;

function TFunctorComposer_F_Gx.Perform(aitem : ItemType) : ItemType;
begin
   Result := f.Perform(g.Perform(aitem));
end;

{ ---------------------- TFunctorComposer_F_Gxy ---------------------- }

constructor TFunctorComposer_F_Gxy.Create(const af : IUnaryFunctor;
                                          const ag : IBinaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   f := af;
   g := ag;
end;

function TFunctorComposer_F_Gxy.Perform(aitem1, aitem2 : ItemType) : ItemType;
begin
   Result := f.Perform(g.Perform(aitem1, aitem2));
end;

{ ---------------------- TFunctorComposer_F_Gx_Hy ---------------------- }

constructor TFunctorComposer_F_Gx_Hy.Create(const af : IBinaryFunctor;
                                            const ag, ah : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   f := af;
   g := ag;
   h := ah;
end;

function TFunctorComposer_F_Gx_Hy.Perform(aitem1, aitem2 : ItemType) : ItemType;
begin
   Result := f.Perform(g.Perform(aitem1), h.Perform(aitem2));
end;


{ ======================= Global routines ================================ }

{ ------------------------- TLess --------------------------------- }

constructor TLess.Create(const c : IBinaryComparer);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
end;

function TLess.Test(aitem1, aitem2 : ItemType) : Boolean;
begin
   Result := cmp.Compare(aitem1, aitem2) < 0;
end;

{ ------------------------- Tgreater --------------------------------- }

constructor TGreater.Create(const c : IBinaryComparer);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
end;

function TGreater.Test(aitem1, aitem2 : ItemType) : Boolean;
begin
   Result := cmp.Compare(aitem1, aitem2) > 0;
end;

{ ------------------------- TEqual --------------------------------- }

constructor TEqual.Create(const c : IBinaryComparer);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
end;

function TEqual.Test(aitem1, aitem2 : ItemType) : Boolean;
begin
   Result := cmp.Compare(aitem1, aitem2) = 0;
end;

{ ------------------------- TLessBinder --------------------------------- }

constructor TLessBinder.Create(const c : IBinaryComparer; p : ItemType);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
   aitem2 := p;
   disposer := nil;
end;

constructor TLessBinder.Create(const c : IBinaryComparer; p : ItemType;
                               const disp : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
   aitem2 := p;
   disposer := disp;
end;

function TLessBinder.Test(p : ItemType) : Boolean;
begin
   Result := cmp.Compare(p, aitem2) < 0;
end;

destructor TLessBinder.Destroy;
begin
   if disposer <> nil then
      _mcp_dispose_item(aitem2, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ------------------------- TGreaterBinder --------------------------------- }

constructor TGreaterBinder.Create(const c : IBinaryComparer; p : ItemType);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
   aitem2 := p;
end;

constructor TGreaterBinder.Create(const c : IBinaryComparer; p : ItemType;
                                  const disp : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
   aitem2 := p;
   disposer := disp;
end;

function TGreaterBinder.Test(p : ItemType) : Boolean;
begin
   Result := cmp.Compare(p, aitem2) > 0;
end;

destructor TGreaterBinder.Destroy;
begin
   if disposer <> nil then
      _mcp_dispose_item(aitem2, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ------------------------- TEqualBinder --------------------------------- }

constructor TEqualBinder.Create(const c : IBinaryComparer; p : ItemType);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
   aitem2 := p;
end;

constructor TEqualBinder.Create(const c : IBinaryComparer; p : ItemType;
                                const disp : IUnaryFunctor);
begin
{$ifdef DEBUG_PASCAL_ADT }
   inherited Create;
{$endif }
   cmp := c;
   aitem2 := p;
   disposer := disp;
end;

function TEqualBinder.Test(p : ItemType) : Boolean;
begin
   Result := cmp.Compare(p, aitem2) = 0;
end;

destructor TEqualBinder.Destroy;
begin
   if disposer <> nil then
      _mcp_dispose_item(aitem2, disposer.Perform, true, disposer);
{$ifdef DEBUG_PASCAL_ADT }
   inherited Destroy;
{$endif }
end;

{ ---------------------------- TIdentity ------------------------------------ }

function TIdentity.Perform(aitem : ItemType) : ItemType;
begin
   Result := aitem;
end;

{ ------------------------------- routines -------------------------------- }

{$ifdef OVERLOAD_DIRECTIVE }

function AdaptReturnNil(f : TUnaryProcedure) : IUnaryFunctor;
begin
   Result := TUnaryProcedureAdaptor.Create(f, false);
end;

function AdaptObjectReturnNil(f : TUnaryObjectProcedure) : IUnaryFunctor;
begin
   Result := TUnaryObjectProcedureAdaptor.Create(f, false);
end;

function Adapt(f : TUnaryProcedure) : IUnaryFunctor;
begin
   Result := TUnaryProcedureAdaptor.Create(f, true);
end;

function Adapt(f : TBinaryProcedure) : IBinaryFunctor;
begin
   Result := TBinaryProcedureAdaptor.Create(f);
end;

function Adapt(f : TUnaryFunction) : IUnaryFunctor;
begin
   Result := TUnaryFunctionAdaptor.Create(f);
end;

function Adapt(f : TBinaryFunction) : IBinaryFunctor;
begin
   Result := TBinaryFunctionAdaptor.Create(f);
end;

function Adapt(f : TUnaryBoolFunction) : IUnaryPredicate;
begin
   Result := TUnaryBoolFunctionAdaptor.Create(f);
end;

function Adapt(f : TBinaryBoolFunction) : IBinaryPredicate;
begin
   Result := TBinaryBoolFunctionAdaptor.Create(f);
end;

function &_mcp_special_adapt_prefix&Adapt(f : TBinaryIntegerFunction) : IBinaryComparer;
begin
   Result := TBinaryIntegerFunctionAdaptor.Create(f);
end;



function AdaptObject(f : TUnaryObjectProcedure) : IUnaryFunctor;
begin
   Result := TUnaryObjectProcedureAdaptor.Create(f, true);
end;

function AdaptObject(f : TBinaryObjectProcedure) : IBinaryFunctor;
begin
   Result := TBinaryObjectProcedureAdaptor.Create(f);
end;

function AdaptObject(f : TUnaryObjectFunction) : IUnaryFunctor;
begin
   Result := TUnaryObjectFunctionAdaptor.Create(f);
end;

function AdaptObject(f : TBinaryObjectFunction) : IBinaryFunctor;
begin
   Result := TBinaryObjectFunctionAdaptor.Create(f);
end;

function AdaptObject(f : TUnaryObjectBoolFunction) : IUnaryPredicate;
begin
   Result := TUnaryObjectBoolFunctionAdaptor.Create(f);
end;

function AdaptObject(f : TBinaryObjectBoolFunction) : IBinaryPredicate;
begin
   Result := TBinaryObjectBoolFunctionAdaptor.Create(f);
end;

function &_mcp_special_adapt_prefix&AdaptObject(f : TBinaryObjectIntegerFunction) : IBinaryComparer;
begin
   Result := TBinaryObjectIntegerFunctionAdaptor.Create(f);
end;

function LessTest(const comparer : IBinaryComparer) : IBinaryPredicate;
begin
   Result := TLess.Create(comparer);
end;

function GreaterTest(const comparer : IBinaryComparer) : IBinaryPredicate;
begin
   Result := TGreater.Create(comparer);
end;

function EqualTest(const comparer : IBinaryComparer) : IBinaryPredicate;
begin
   Result := TEqual.Create(comparer);
end;

function EqualTo(const comparer : IBinaryComparer;
                 aitem : ItemType) : IUnaryPredicate;
begin
   Result := TEqualBinder.Create(comparer, aitem);
end;

function EqualTo(const comparer : IBinaryComparer; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryPredicate;
begin
   Result := TEqualBinder.Create(comparer, aitem, disposer);
end;

function LessThan(const comparer : IBinaryComparer;
                  aitem : ItemType) : IUnaryPredicate;
begin
   Result := TLessBinder.Create(comparer, aitem);
end;

function LessThan(const comparer : IBinaryComparer; aitem : ItemType;
                  const disposer : IUnaryFunctor) : IUnaryPredicate;
begin
   Result := TLessBinder.Create(comparer, aitem, disposer);
end;

function GreaterThan(const comparer : IBinaryComparer;
                     aitem : ItemType) : IUnaryPredicate;
begin
   Result := TGreaterBinder.Create(comparer, aitem);
end;

function GreaterThan(const comparer : IBinaryComparer; aitem : ItemType;
                     const disposer : IUnaryFunctor) : IUnaryPredicate;
begin
   Result := TGreaterBinder.Create(comparer, aitem, disposer);
end;

function Bind1st(const pred : IBinaryPredicate; aitem : ItemType) : IUnaryPredicate;
begin
   Result := TPredicateBinder1st.Create(pred, aitem, nil);
end;

function Bind1st(const fun : IBinaryFunctor; aitem : ItemType) : IUnaryFunctor;
begin
   Result := TFunctorBinder1st.Create(fun, aitem, nil);
end;

function Bind2nd(const pred : IBinaryPredicate; aitem : ItemType) : IUnaryPredicate;
begin
   Result := TPredicateBinder2nd.Create(pred, aitem, nil);
end;

function Bind2nd(const fun : IBinaryFunctor; aitem : ItemType) : IUnaryFunctor;
begin
   Result := TFunctorBinder2nd.Create(fun, aitem, nil);
end;

function Bind(const fun : IUnaryFunctor; aitem : ItemType) : IUnaryFunctor;
begin
   Result := TUnaryFunctorBinder.Create(fun, aitem, nil);
end;

function Bind1st(const pred : IBinaryPredicate; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryPredicate;
begin
   Result := TPredicateBinder1st.Create(pred, aitem, disposer);
end;

function Bind1st(const fun : IBinaryFunctor; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryFunctor;
begin
   Result := TFunctorBinder1st.Create(fun, aitem, disposer);
end;

function Bind2nd(const pred : IBinaryPredicate; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryPredicate;
begin
   Result := TPredicateBinder2nd.Create(pred, aitem, disposer);
end;

function Bind2nd(const fun : IBinaryFunctor; aitem : ItemType;
                 const disposer : IUnaryFunctor) : IUnaryFunctor;
begin
   Result := TFunctorBinder2nd.Create(fun, aitem, disposer);
end;

function Bind(const fun : IUnaryFunctor; aitem : ItemType;
              const disposer : IUnaryFunctor) : IUnaryFunctor;
begin
   Result := TUnaryFunctorBinder.Create(fun, aitem, disposer);
end;

function Negate(const pred : IUnaryPredicate) : IUnaryPredicate;
begin
   Result := TUnaryPredicateNegator.Create(pred);
end;

function Negate(const pred : IBinaryPredicate) : IBinaryPredicate;
begin
   Result := TBinaryPredicateNegator.Create(pred);
end;

function PredAnd(const pred1, pred2 : IUnaryPredicate) : IUnaryPredicate;
begin
   Result := TPredAnd.Create(pred1, pred2);
end;

function PredOr(const pred1, pred2 : IUnaryPredicate) : IUnaryPredicate;
begin
   Result := TPredOr.Create(pred1, pred2);
end;

function PredXor(const pred1, pred2 : IUnaryPredicate) : IUnaryPredicate;
begin
   Result := TPredXor.Create(pred1, pred2);
end;

function Compose_F_Gx(const f, g : IUnaryFunctor) : IUnaryFunctor;
begin
   Result := TFunctorComposer_F_Gx.Create(f, g);
end;

function Compose_F_Gxy(const f : IUnaryFunctor;
                       const g : IBinaryFunctor) : IBinaryFunctor;
begin
   Result := TFunctorComposer_F_Gxy.Create(f, g);
end;

function Compose_F_Gx_Hy(const f : IBinaryFunctor;
                         const g, h : IUnaryFunctor) : IBinaryFunctor;
begin
   Result := TFunctorComposer_F_Gx_Hy.Create(f, g, h);
end;

function &_mcp_prefix&Identity : IUnaryFunctor;
begin
   Result := var&_mcp_prefix&Identity;
end;

{$endif OVERLOAD_DIRECTIVE }
