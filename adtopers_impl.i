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
 adtopers_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtopers.defs
&include adtopers_impl.mcp

operator < (const iter1, iter2 : TRandomAccessIterator) : Boolean;
begin
   Result := iter1.Less(iter2);
end;

operator > (const iter1, iter2 : TRandomAccessIterator) : Boolean;
begin
   Result := iter2.Less(iter1);
end;

operator <= (const iter1, iter2 : TRandomAccessIterator) : Boolean;
begin
   Result := not iter2.Less(iter1);
end;

operator >= (const iter1, iter2 : TRandomAccessIterator) : Boolean;
begin
   Result := not iter1.Less(iter2);
end;

operator - (const iter1, iter2 : TRandomAccessIterator) : IndexType;
begin
   Result := Distance(iter2, iter1);
end;

operator - (const iter : TRandomAccessIterator;
            ind : IndexType) : TRandomAccessIterator;
begin
   Result := TRandomAccessIterator(iter.CopySelf);
   iter.Advance(ind);
end;

operator + (const iter : TRandomAccessIterator;
            ind : IndexType) : TRandomAccessIterator;
begin
   Result := TRandomAccessIterator(iter.CopySelf);
   iter.Advance(-ind);
end;
