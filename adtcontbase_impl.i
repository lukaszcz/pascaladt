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
 adtcontbase_impl.inc::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtcontbase.defs
&include adtcontbase_impl.mcp

&define Identity &_mcp_prefix&Identity

{ TContainerAdt members }

constructor TContainerAdt.Create;
begin
   FDisposer := &_mcp_default_disposer(&ItemType);
   FOwnsItems := true;
   FGrabageCollector := TGrabageCollector.Create;
end;

constructor TContainerAdt.CreateCopy(const cont : TContainerAdt);
begin
   Assert(cont <> nil, msgNilObject);
   FDisposer := cont.FDisposer;
   FOwnsItems := cont.FOwnsItems;
   FGrabageCollector := TGrabageCollector.Create;
end;

destructor TContainerAdt.Destroy;
begin
   FGrabageCollector.Free;
end;

procedure TContainerAdt.SetOwnsItems(b : Boolean);
begin
   FOwnsItems := b;
end;

procedure TContainerAdt.SetDisposer(const proc : IUnaryFunctor);
begin
   FDisposer := proc;
end;

function TContainerAdt.GetDisposer : IUnaryFunctor;
begin
   Result := FDisposer;
end;

procedure TContainerAdt.BasicSwap(cont : TContainerAdt);
begin
   ExchangePtr(FDisposer, cont.FDisposer);
   ExchangeData(FOwnsItems, cont.FOwnsItems, SizeOf(Boolean));
end;

{$ifdef TEST_PASCAL_ADT }
procedure TContainerAdt.WriteLog(msg : String);
begin
   WriteLogStream(msg);
end;

procedure TContainerAdt.WriteLog;
begin
   WriteLogStream('');
end;

procedure TContainerAdt.LogStatus(mName : String);
begin
   Inc(logNumber);
   WriteLog;
   WriteLog;
   WriteLog('----------------------------------------------');
   WriteLog('(' + IntToStr(logNumber) + ')');
   WriteLog(mName);
   WriteLog;
   WriteLog('Size: ' + IntToStr(Size));
   if FOwnsItems then
      WriteLog('OwnsItems: true')
   else
      WriteLog('OwnsItems: false');
   WriteLog('Existing iterators: ' +
               IntToStr(FGrabageCollector.RegisteredObjects));
end;

function TContainerAdt.FormatItem(aitem : ItemType) : String;
begin
&if (&ItemType == String)
   Result := aitem;
&elseif (&ItemType == TObject)
   if aitem is TTestObject then
      Result := IntToStr(TTestObject(aitem).Value)
   else
      Result := Format('<object address: %X>', [PointerValueType(aitem)]);
&elseif (&ItemType == Real)
   Result := FloatToStr(aitem);
&elseif (&ItemType == Integer || &ItemType == Cardinal)
   Result := IntToStr(aitem);
&elseif (&ItemType == Pointer)
   Result := Format('<pointer: %X>', [PointerValueType(aitem)]);
&else
   Result := '<not printable>';
&endif
end;

{$endif TEST_PASCAL_ADT }

procedure TContainerAdt.Swap(cont : TContainerAdt);
var
   temp : TDynamicBuffer;
   cont1, cont2 : TContainerAdt;
   i : SizeType;
   tempSize : SizeType;
   aitem : ItemType;
begin
   if Size < cont.Size then
   begin
      cont1 := self;
      cont2 := cont;
   end else
   begin
      cont1 := cont;
      cont2 := self;
   end;

   BufferAllocate(temp, cont1.Size);
   { this try..finally produces a linking error with FPC 2.0 for some
     strange reason }
//   try
      i := 0; { for exception handling }
      tempSize := 0;
      try
         while cont1.CanExtract do
         begin
            aitem := cont1.ExtractItem; { may raise }
            temp^.Items[i] := aitem;
            Inc(tempSize);
         end;

         while cont2.CanExtract do
         begin
            aitem := cont2.ExtractItem; { may raise }
            cont1.InsertItem(aitem); { may raise }
         end;

         for i := 0 to tempSize - 1 do
         begin
            cont2.InsertItem(temp^.Items[i]); { may raise }
         end;
         i := tempSize;

      except
         { since the exception was probably raised by the InsertItem
           routine there is no point in trying to re-insert the items
           from temp; the only thing we can do here is to at least
           dispose these items safely }
         while i <> tempSize do
         begin
            with cont1 do
               DisposeItem(temp^.Items[i]);
            Inc(i);
         end;
         BufferDeallocate(temp);
         raise;
      end;

      BasicSwap(cont);

//   finally
      BufferDeallocate(temp);
//   end;
end;

procedure TContainerAdt.&<DisposeItem>(aitem : ItemType);
begin
   &_mcp_dispose_item(aitem, FDisposer.Perform, OwnsItems, FDisposer);
end;

function TContainerAdt.CopySelf : TContainerAdt;
begin
   Result := CopySelf(Identity);
end;
