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
 adtutils.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtutils.defs


type
   { represents a pair of items  }
   TPair = record
      First, Second : ItemType;
   end;
   PPair = ^TPair;

procedure ExchangeItem(var item1, item2 : ItemType); overload; &_mcp_inline&
{ this is needed to correctly move AnsiStrings/interfaces/records containing them }   
procedure SafeMove(var src, dest : ItemType; num : SizeType); overload;
