(* This file is a part of the PascalAdt library, which provides
   commonly used algorithms and data structures for FPC and Delphi
   compilers.
   
   Copyright (C) 2004 by Lukasz Czajka
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   as published by the Free Software Foundation; either version 2.1 of
   the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
   02110-1301 USA *)

unit adtexcept;

{ This unit provides several exception classes used by the library.  }

interface

uses
   SysUtils;

type
   EPascalAdt = class (Exception)
   public
      constructor Create(s : String);
   end;
   
   EProgrammingError = class (EPascalAdt)
   public
      constructor Create(s : String);
   end;
   
   EInvalidArgument = class (EProgrammingError)
   public
      constructor Create(mName : String);
   end;
   
   EDefinedOrder = class (EProgrammingError)
   public
      { creates an exception with <methodName> as the name of the
        method that raises the exception }
      constructor Create(mName : String);
   end;
   
   ENotMapComparer = class (EProgrammingError)
   public
      constructor Create(s : String);
   end;
   
   ENoMapSwap = class (EProgrammingError)
   end;
   
   EInternalError = class (EPascalAdt)
   public
      constructor Create;
   end;
   

implementation

uses
   adtmsg;

constructor EPascalAdt.Create(s : String);
begin
   inherited Create('PascalAdt: ' + s);
end;

constructor EProgrammingError.Create(s : String);
begin
   inherited Create('Programming error: ' + s);
end;

constructor EInvalidArgument.Create(mName : String);
begin
   inherited Create('Invalid argument (in ' + mName + ')');
end;

constructor EDefinedOrder.Create(mName : String);
begin
   inherited Create('Violating fixed, internally defined order ' +
                       'of container items (in ' + mName + ')');
end;

constructor ENotMapComparer.Create(s : String);
begin
   inherited Create(s + ': Comparer used in the set passed to ' +
                       'the constructor is not TMapComparer');
end;

constructor EInternalError.Create;
begin
   inherited Create(msgInternalError);
end;


end.
