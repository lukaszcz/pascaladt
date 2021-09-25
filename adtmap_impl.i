(* This file is a part of the PascalAdt library, which provides
   commonly used algorithms and data structures for the FPC and Delphi
   compilers.
   
   Copyright (C) 2004, 2005, 2006 by Lukasz Czajka
   
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
   02110-1301 USA @discard *)


{@discard
 adtmap_impl.inc::map_prefix=&_mcp_map_prefix&::item_prefix=&_mcp_item_prefix&::key_prefix=&_mcp_key_prefix&::item_type=&KeyType&::key_type=&KeyType&
 }

&include adtmap.defs
&include adtmap_impl.mcp

&define TMapIteratorPair T&_mcp_map_prefix&IteratorPair

type
   TMapDisposer = class (TFunctor, IUnaryFunctor)
   private
      FMap : TMap;
   public
      constructor Create(amap : TMap);
      function Perform(aitem : TObject) : TObject;
      property Map : TMap read FMap;
   end;
   
   TMapCopier = class (TMapAdtCopier, IUnaryFunctor)
   private
      FMap : TMap;
      
   public
      constructor Create(const keycp : IKeyUnaryFunctor;
                         const itemcp : IItemUnaryFunctor);
      { disposes both the key and the item }
      function Perform(aitem : TObject) : TObject; override;
      
      property Map : TMap write FMap;
   end;
   
{ ------------------------- TMapAdtCopier ------------------------------ }

constructor TMapAdtCopier.Create(const keycp : IKeyUnaryFunctor;
                                 const itemcp : IItemUnaryFunctor);
begin
   inherited Create;
   FKeyCp := keycp;
   FItemCp := itemcp;
end;

{ ---------------------------- TMapAdt ----------------------------------- }

constructor TMapAdt.Create;
begin
   inherited Create;
   ItemDisposer := &_mcp_default_disposer(&ItemType);
   KeyDisposer := &_mcp_default_disposer(&KeyType);
   FOwnsKeys := true;
end;

constructor TMapAdt.CreateCopy(const cont : TMapAdt);
begin
   inherited CreateCopy(TItemContainerAdt(cont));
   FKeyDisposer := cont.FKeyDisposer;
   FOwnsKeys := cont.FOwnsKeys;
end;

procedure TMapAdt.SetKeyDisposer(const akeydisp : IKeyUnaryFunctor);
begin
   FKeyDisposer := akeydisp;
end;

function TMapAdt.GetKeyDisposer : IKeyUnaryFunctor;
begin
   Result := FKeyDisposer;
end;

&if (&ItemType& != TObject)
function TMapAdt.CopySelf(const itemcopier : IItemUnaryFunctor) : TItemContainerAdt;
begin
   Result := nil;
   raise EInvalidArgument.Create('TMapAdt.CopySelf - use the second CopySelf version with appropriate TMapAdtCopier passed');
end;
&endif

procedure TMapAdt.&<DisposeKey>(key : KeyType);
begin
   &_mcp_dispose_key(key, FKeyDisposer.Perform, OwnsKeys, FKeyDisposer);
end;

procedure TMapAdt.SetKeyHasher(akeyhasher : I&_mcp_key_prefix&Hasher);
begin
   { do nothing by default }
end;

procedure TMapAdt.BasicSwap(cont : TItemContainerAdt);
begin
   inherited;
   if cont is TMapAdt then
   begin
      ExchangePtr(TMapAdt(cont).FKeyDisposer, FKeyDisposer);
   end else
      raise ENoMapSwap.Create('A map container may be swapped' +
                                 ' only with another map.');
end;

procedure TMapAdt.Swap(cont : TItemContainerAdt);
var
   buffer1 : array of KeyType;
   buffer2 : array of ItemType;
   map1, map2 : TMapAdt;
   i, bufSize : SizeType;
   owns1, owns2 : Boolean;
   ownsKeys1, ownsKeys2 : Boolean;
   iter : TMapIterator;
begin
   if Size < cont.Size then
   begin
      map1 := self;
      map2 := TMapAdt(cont);
   end else
   begin
      map1 := TMapAdt(cont);
      map2 := self;
   end;
   
   owns1 := map1.OwnsItems;
   owns2 := map2.OwnsItems;
   ownsKeys1 := map1.OwnsKeys;
   ownsKeys2 := map2.OwnsKeys;
   try
      i := 0;
      bufSize := 0;
      try
         SetLength(buffer1, map1.Size);
         SetLength(buffer2, map1.Size);
         map1.OwnsItems := false;
         map2.OwnsItems := false;
         map1.OwnsKeys := false;
         map2.OwnsKeys := false;
         
         iter := map1.Start;
         while not iter.IsFinish do
         begin
            buffer1[bufSize] := iter.Key;
            buffer2[bufSize] := iter.Item;
            iter.Delete;
            Inc(bufSize);
         end;
         
         iter.Destroy;
         iter := map2.Start;
         while not iter.IsFinish do
         begin
            map1.Insert(iter.Key, iter.Item);
            iter.Delete;
         end;
         
         while i <> bufSize do
         begin
            map2.Insert(buffer1[i], buffer2[i]);
            Inc(i);
         end;

      except
         { see the comment in TContainerAdt.Swap }
         while i <> bufSize do
         begin
            with map1 do
            begin
               DisposeKey(buffer1[i]);
               DisposeItem(buffer2[i]);
            end;
            Inc(i);
         end;
         raise;
      end;
      
      BasicSwap(cont);

   finally
      map1.OwnsItems := owns1;
      map2.OwnsItems := owns2;
      map1.OwnsKeys := ownsKeys1;
      map2.OwnsKeys := ownsKeys2;
   end;
end;

function TMapAdt.Extract(key : KeyType) : SizeType; 
var
   owns : Boolean;
begin
   owns := OwnsItems;
   try
      OwnsItems := false;
      Result := Delete(key);
   finally
      OwnsItems := owns;
   end;
end;

function TMapAdt.InsertItem(aitem : ItemType) : Boolean;
begin
   Result := false;
end;

function TMapAdt.ExtractItem : ItemType;
begin
   Result := DefaultItem;
   Assert(false);
end;

function TMapAdt.CanExtract : Boolean;
begin
   Result := false;
end;

{ ----------------------------- TMapIterator --------------------------------- }

procedure TMapIterator.Insert(aitem : ItemType);
begin
   raise EDefinedOrder.Create('TMapIterator.Insert');
end;


{ -------------------- TMapIteratorRange ---------------------------- }

constructor TMapIteratorRange.Create(starti, finishi : TMapIterator);
begin
   inherited Create;
   FStart := starti;
   FFinish := finishi;
   owner := FStart.Owner;
   handle := owner.GrabageCollector.RegisterObject(self);
end;

destructor TMapIteratorRange.Destroy;
begin
   owner.GrabageCollector.UnregisterObject(handle);
   inherited;
end;


{ ------------------ TMapEntry ----------------------------- }

constructor TMapEntry.Create(akey : KeyType; aitem : ItemType);
begin
   FKey := akey;
   FItem := aitem;
end;

{ ---------------------- TMapDisposer ---------------------------- }

constructor TMapDisposer.Create(amap : TMap);
begin
   FMap := amap;
end;

function TMapDisposer.Perform(aitem : TObject) : TObject;
var
   k : KeyType;
begin
   Result := nil;
   if aitem <> nil then
   begin
      k := TMapEntry(aitem).Key;
      with FMap do
      begin
         DisposeKey(k);
         DisposeItem(TMapEntry(aitem).Item);
      end;
   end;
end;

{ ----------------------- TMapCopier ----------------------------- }

constructor TMapCopier.Create(const keycp : IKeyUnaryFunctor;
                                          const itemcp : IItemUnaryFunctor);
begin
   inherited Create(keycp, itemcp);
end;

function TMapCopier.Perform(aitem : TObject) : TObject;
var
   e : TMapEntry;
begin
   if aitem <> nil then
   begin
      e := TMapEntry.Create(DefaultKey, DefaultItem);
      try
         e.Key := KeyCopier.Perform(TMapEntry(aitem).Key);
         e.Item := ItemCopier.Perform(TMapEntry(aitem).Item);
      except
         with FMap do
         begin
            DisposeKey(e.Key);
            DisposeItem(e.Item);
         end;
         e.Destroy;
         raise;
      end;
      Result := e;
   end else
      Result := nil;
end;

{ --------------------------- TMapComparer ---------------------------------- }

constructor TMapComparer.Create(const keycmp : IKeyBinaryComparer);
begin
   inherited Create;
   FKeyCmp := keycmp;
end;

function TMapComparer.Compare(aitem1, aitem2 : TObject) : Integer;
begin
   _mcp_compare_assign_aux(&TMapEntry&(aitem1).Key, &TMapEntry&(aitem2).Key,
                           Result, &KeyType&, FKeyCmp);
end;

{ --------------------------- TMapHasher ---------------------------------- }

constructor TMapHasher.Create(const akeyhasher : IKeyHasher);
begin
   inherited Create;
   fkeyhasher := akeyhasher;
end;

function TMapHasher.Hash(aitem : TObject) : UnsignedType;
begin
   Result := fkeyhasher.Hash(TMapEntry(aitem).Key);
end;

{ ------------------------------ TMap ------------------------------------- }

class function TMap.CreateCopier(const keyCopier : IKeyUnaryFunctor;
                                 const itemCopier : IItemUnaryFunctor) :
   TMapAdtCopier;
begin
   Result := TMapCopier.Create(keyCopier, itemCopier);
end;

constructor TMap.Create(aset : TSetAdt);
begin
   Assert(aset <> nil);
   inherited Create;
   FSet := aset;
   aset.ItemComparer := TMapComparer.Create(&_mcp_comparer(&KeyType));
   if aset is THashSetAdt then
   begin
      THashSetAdt(aset).Hasher := TMapHasher.Create(&_mcp_hasher(&KeyType));
   end;
   FSet.ItemDisposer := TMapDisposer.Create(self);
   FEntry := TMapEntry.Create(DefaultKey, DefaultItem);
   // CachedEntry := nil;
end;

constructor TMap.Create;
begin
   Create(THashTable.Create);
end;

constructor TMap.CreateCopy(const cont : TMap; const mapCopier : IUnaryFunctor);
begin
   Assert((mapCopier = nil) or (mapCopier.GetObject is TMapCopier));

   inherited CreateCopy(TMapAdt(cont));
   if mapCopier <> nil then
      TMapCopier(mapCopier.GetObject).Map := cont;
   FSet := TSetAdt(cont.FSet.CopySelf(mapCopier));
   FEntry := TMapEntry.Create(DefaultKey, DefaultItem);
   // CachedEntry := nil
end;

destructor TMap.Destroy;
begin
   FSet.Free;
   FEntry.Free;
   inherited;
end;

procedure TMap.SetOwnsItems(b : Boolean);
begin
   inherited;
   if not OwnsItems and not OwnsKeys then
      FSet.OwnsItems := false
   else
      FSet.OwnsItems := true;
end;

procedure TMap.SetRepeatedItems(b : Boolean);
begin
   FSet.RepeatedItems := b;
end;

function TMap.GetRepeatedItems : Boolean;
begin
   Result := FSet.RepeatedItems;
end;

procedure TMap.SetKeyComparer(cmp : IKeyBinaryComparer);
begin
   TMapComparer(FSet.ItemComparer.GetObject).KeyComparer := cmp;
end;

function TMap.GetKeyComparer : IKeyBinaryComparer;
begin
   Result := TMapComparer(FSet.ItemComparer.GetObject).KeyComparer;   
end;

function TMap.CopySelf(const mapCopier : IUnaryFunctor) : TItemContainerAdt;
begin
   Result := TMap.CreateCopy(self, mapCopier);
end;

procedure TMap.Swap(cont : TItemContainerAdt);
begin
   if cont is TMap then
   begin
      BasicSwap(cont);
      ExchangePtr(FSet, TMap(cont).FSet);
   end else
   begin
      inherited;
   end;
end;
      
function TMap.Start : TMapIterator;
begin
   Result := TMapAdaptorIterator.Create(FSet.Start, self);
end;

function TMap.Finish : TMapIterator;
begin
   Result := TMapAdaptorIterator.Create(FSet.Finish, self);
end;

function TMap.Has(key : KeyType) : Boolean;
var
   e : TMapEntry;
begin
   FEntry.Key := key;
   e := TMapEntry(FSet.Find(FEntry));
   Result := e <> nil;
   if Result then
      CachedEntry := e;
end;

function TMap.Find(key : KeyType) : ItemType;
var
   obj : TMapEntry;
begin
   FEntry.Key := key;
   if (not RepeatedItems) and (CachedEntry <> nil) and (CachedEntry.Key = key) then
      Result := CachedEntry.Item
   else begin
      obj := TMapEntry(FSet.Find(FEntry));
      if obj <> nil then
      begin
         CachedEntry := obj;
         Result := obj.Item;
      end
&if (&_mcp_accepts_nil)         
      else
         Result := nil;
&else
      else
         Assert(false);
&endif
   end;
end;

function TMap.Count(key : KeyType) : SizeType;
begin
   FEntry.Key := key;
   Result := FSet.Count(FEntry);
end;

procedure TMap.Associate(key : KeyType; aitem : ItemType);
var
   e1, e2 : TMapEntry;
begin
   if (not RepeatedItems) and (CachedEntry <> nil) and (CachedEntry.Key = key) then
   begin
      DisposeKey(CachedEntry.Key);
      DisposeItem(CachedEntry.Item);
      CachedEntry.Key := key;
      CachedEntry.Item := aitem;
   end else
   begin
      e1 := TMapEntry.Create(key, aitem);
      
      try
         e2 := TMapEntry(FSet.FindOrInsert(e1));
      except
         { don't destroy the item and the key! }
         e1.Destroy;
         raise;
      end;
      
      if e2 <> nil then
      begin
         DisposeKey(e2.Key);
         DisposeItem(e2.Item);
         e2.Key := e1.Key;
         e2.Item := e1.Item;
         e1.Destroy;
      end;
   end;
end;

function TMap.Insert(pos : TMapIterator;
                     key : KeyType; aitem : ItemType) : Boolean;
var
   e : TMapEntry;
begin
   Assert(pos is TMapAdaptorIterator, msgInvalidIterator);
   
   e := TMapEntry.Create(key, aitem);
   
   try
      Result := FSet.Insert(TMapAdaptorIterator(pos).FSIter, e);
   except
      e.Destroy;
      raise;
   end;
   
   if not Result then
      e.Destroy;
end;

function TMap.Insert(key : KeyType; aitem : ItemType) : Boolean;
var
   e : TMapEntry;
begin
   e := TMapEntry.Create(key, aitem);
   
   try
      Result := FSet.Insert(e);
   except
      e.Destroy;
      raise;
   end;
   
   if not Result then
      e.Destroy;
end;

procedure TMap.Delete(pos : TMapIterator);
begin
   Assert(pos is TMapAdaptorIterator, msgInvalidIterator);
   
   CachedEntry := nil;
   FSet.Delete(TMapAdaptorIterator(pos).FSIter);
end;

function TMap.Delete(key : KeyType) : SizeType;
begin
   FEntry.Key := key;
   Result := FSet.Delete(FEntry);
   CachedEntry := nil;
end;

function TMap.LowerBound(key : KeyType) : TMapIterator;
begin
   FEntry.Key := key;
   Result := TMapAdaptorIterator.Create(FSet.LowerBound(FEntry), self);
end;

function TMap.UpperBound(key : KeyType) : TMapIterator;
begin
   FEntry.Key := key;
   Result := TMapAdaptorIterator.Create(FSet.UpperBound(FEntry), self);
end;

function TMap.EqualRange(key : KeyType) : TMapIteratorRange;
var
   srange : TSetIteratorRange;
begin
   FEntry.Key := key;
   srange := FSet.EqualRange(FEntry);
   Result := TMapIteratorRange.Create(
      TMapAdaptorIterator.Create(srange.Start, self),
      TMapAdaptorIterator.Create(srange.Finish, self));
   srange.Destroy; { this is O.K. because TSetIteratorRange object
                     does not own its iterators and does not destroy
                     them }
end;

procedure TMap.Clear;
begin
   FSet.Clear;
   CachedEntry := nil;
   GrabageCollector.FreeObjects;
end;

function TMap.Empty : Boolean;
begin
   Result := FSet.Empty;
end;

function TMap.Size : SizeType;
begin
   Result := FSet.Size;
end;

procedure TMap.SetKeyHasher(akeyhasher : I&_mcp_key_prefix&Hasher);
begin
   if FSet is THashSetAdt then
   begin
      (FSet as THashSetAdt).Hasher := TMapHasher.Create(akeyhasher);
   end;
end;

function TMap.IsSorted : Boolean;
begin
   Result := FSet is TSortedSetAdt;
end;


{ -------------------- TMapAdaptorIterator ------------------------------ }

constructor TMapAdaptorIterator.Create(siter : TSetIterator; map : TMap);
begin
   inherited Create(map);
   FSIter := siter;
   FMap := map;
end;

function TMapAdaptorIterator.CopySelf : TItemIterator;
begin
   Result := TMapAdaptorIterator.Create(TSetIterator(FSiter.CopySelf), FMap);
end;

function TMapAdaptorIterator.Equal(const Pos : TItemIterator) : Boolean;
begin
   Assert(pos is TMapAdaptorIterator, msgInvalidIterator);
   
   Result := FSiter.Equal(TMapAdaptorIterator(pos).FSIter);
end;

function TMapAdaptorIterator.Key : KeyType;
begin
   Result := TMapEntry(FSIter.GetItem).Key;
end;

function TMapAdaptorIterator.GetItem : ItemType; 
begin
   Result := TMapEntry(FSIter.GetItem).Item;
end;

procedure TMapAdaptorIterator.SetItem(aitem : ItemType);
var
   e : TMapEntry;
begin
   e := TMapEntry(FSIter.GetItem);
   with FMap do
      DisposeItem(e.Item);
   e.Item := aitem;
end;

procedure TMapAdaptorIterator.ExchangeItem(iter : TItemIterator);
var
   e1, e2 : TMapEntry;
   temp : ItemType;
begin
   Assert(iter is TMapAdaptorIterator, msgInvalidIterator);
   
   e1 := TMapEntry(FSIter.GetItem);
   e2 := TMapEntry(TMapAdaptorIterator(iter).FSIter.GetItem);
   temp := e1.Item;
   e1.Item := e2.Item;
   e2.Item := temp;
end;

procedure TMapAdaptorIterator.Advance;
begin
   FSIter.Advance;
end;

procedure TMapAdaptorIterator.Retreat;
begin
   FSIter.Retreat;
end;

procedure TMapAdaptorIterator.Insert(akey : KeyType; aitem : ItemType);
var
   e : TMapEntry;
begin
   e := TMapEntry.Create(akey, aitem);
   try
      FSIter.Insert(e);
   except
      e.Destroy;
      raise;
   end;
   if FSIter.IsFinish then
      e.Destroy;
end;

function TMapAdaptorIterator.Extract : ItemType;
var
   e : TMapEntry;
begin
   e := TMapEntry(FSIter.Extract);
   with FMap do
      DisposeKey(e.Key);
   Result := e.Item;
   e.Destroy;
   FMap.CachedEntry := nil;
end;

function TMapAdaptorIterator.Delete(finish : TItemForwardIterator) : SizeType;
begin
   Assert(finish is TMapAdaptorIterator, msgInvalidIterator);
   Assert(TMapAdaptorIterator(finish).FMap = FMap, msgWrongOwner);
   Result := FSIter.Delete(TMapAdaptorIterator(finish).FSIter);
   FMap.CachedEntry := nil;
end;

function TMapAdaptorIterator.Owner : TItemContainerAdt;
begin
   Result := FMap;
end;

function TMapAdaptorIterator.IsStart : Boolean; 
begin
   Result := FSIter.IsStart;
end;

function TMapAdaptorIterator.IsFinish : Boolean; 
begin
   Result := FSIter.IsFinish;
end;

{ -------------------- non-member routines -------------------------------- }

function CopyOf(const iter : TMapIterator) : TMapIterator;
begin
   Result := TMapIterator(iter.CopySelf);
end;

function CopyOf(const iter : TMapAdaptorIterator) : TMapAdaptorIterator;
begin
   Result := TMapAdaptorIterator(iter.CopySelf);
end;

