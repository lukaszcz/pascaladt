{@discard
 
  This file is a part of the PascalAdt library, which provides
  commonly used algorithms and data structures for the FPC and Delphi
  compilers.
  
  Copyright (C) 2004, 2005, 2006 by Lukasz Czajka
  
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
 adtutils_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtutils.defs
&include adtutils_impl.mcp

procedure ExchangeItem(var item1, item2 : ItemType); &_mcp_inline
var
   temp : ItemType;
begin
   temp := item1;
   item1 := item2;
   item2 := temp;
end;

procedure SafeMove(var src, dest : ItemType; num : SizeType);
&if (&ItemType == TObject || &ItemType == Integer || &ItemType == Pointer ||
        &ItemType == Cardinal || &ItemType == Real)
begin
   system.Move(src, dest, num*SizeOf(ItemType));
end;
&else
var
   psrc, pdest : PItemType;
begin 
   psrc := @src;
   pdest := @dest;
   if (psrc <> pdest) and (num > 0) then
   begin
      if (PointerValueType(psrc) < PointerValueType(pdest)) and
            (PointerValueType(psrc) + UnsignedType(num)*SizeOf(ItemType) >= PointerValueType(pdest)) then
      begin
         Inc(pdest, num - 1);
         Inc(psrc, num - 1);
         while (num > 0) do
         begin
            pdest^ := psrc^;
            Dec(num);
            Dec(pdest);
            Dec(psrc);
         end;
      end else
      begin
         while (num > 0) do
         begin
            pdest^ := psrc^;
            Dec(num);
            Inc(pdest);
            Inc(psrc);
         end;
      end;
   end;
end;
&endif
