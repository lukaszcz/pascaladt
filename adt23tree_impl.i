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
 adt23tree_impl.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adt23tree.defs
&include adt23tree_impl.mcp

{$R+}

{ ========================================================================== }
{                 Notes on the implementation of T23Tree                     }
{ -------------------------------------------------------------------------- }
{ T23Tree is implemented as a variant of a 23-tree with items stored
  in internal nodes. In ordinary 23-trees items are stored in leaves
  and in internal nodes only keys are stored, which enables fast
  lookup. Each internal node has two or three children and all leaves
  are on the same level. The keys of the smallest items in the 2nd and
  3rd sub-tree are stored in each internal node. T23Tree
  implementation differs in the way that instead of these keys whole
  items are stored, and they are not present in the sub-tree to which
  they belong. Therefore, no leaves exist physically. The nodes which
  are logically parents of leaves contain in their LowItem fields the
  items that should be stored in the leaves, and the Child fields are
  all set to nil. The item normally stored in the left-most leaf is
  stored in the LowestItem field. This field should be treated as a
  node which is the parent of the root. This way, the height of a tree
  consisting only of the LowestItem and the root node is 1, whereas
  the height of a tree consisting only of the LowestItem node is 0
  (this is important in the implementation of the Concatenate and
  Split operations). When I mention the existence of some entity I
  usually mean its physical existence within the internal structure
  used to represent the 23-tree. I also sometimes talk about logical
  existence, which should be understood as the existence of an entity
  within the logical, implementation-independent structure of a
  23-tree (i.e. the keys in iternal nodes, items in leaves, ...). }
{   An example T23Tree graphically:   }
{
                          +----------------+
                          | LowestItem = 0 |
                          +----------------+
                                 |
                                 |
                             +----+----+
                         +---|  5 | 10 |
                         |   +----+----+
                        1|      |    |     3
                         |     2|    +------------+
                         |      |                 |
                 +----+----+   +----+----+     +----+----+
         +-------|  3 | nil| +-|  7 | nil|   +-| 13 | nil|
         |       +----+----+ | +----+----+   | +----+----+  2
        1|         |         |    |  2      1|    +--------------+
         |        2|        1|    +------+   +-------+           |
         |         |         |           |           |           |
   +----+----+ +----+----+ +----+----+ +----+----+ +----+----+ +----+----+
   |  1 |  2 | |  4 | nil| |  6 | nil| |  8 |  9 | | 11 | 12 | | 14 | 15 |
   +----+----+ +----+----+ +----+----+ +----+----+ +----+----+ +----+----+
}
{ Boxes represent the nodes. The numbers in the boxes represent
  LowItem[2] (the first number) and LowItem[3] (the second
  number). The links represent the parentship relation. The number
  beside each link tells which child of its parent is the node at the
  bottom of the link (i.e. if this number is n then the node is
  pointed by (node's parent)^.Child[n]). Note that the nodes at the
  lowest level have no physical children, although they are logically
  the parents of leaves. They don't need to have children as the items
  normally stored in the leaves are stored either in their LowItem[]'s
  or in the LowItem[]'s of some higher nodes. }

{  How are repeated items managed? }
{ When one node contains some item in LowItem[n], but not in
  LowItem[n-1], an equal item may be also stored in LowItem[n+1], the
  sub-tree of Child[n], the sub-tree of Child[n-1] and also the
  sub-tree of Child[n+1] if LowItem[n+1] contains an equal item. }

{  How is a position within a 23-tree represented ? }
{ The position of an item is represented by a pair (node,low), where
  node is the pointer to the node which has the appropriate LowItem
  and low is the number of this LowItem (2 or 3). The end of range is
  represented by the (nil,0) pair. The first item (LowestItem) is
  represented by the (nil,1) pair. }
{ ========================================================================== }


{ ------------------ test routines ------------------------  }

function NodeConsistent(node : P23TreeNode) : Boolean;
begin
   with node^ do
   begin
      Assert((Child[1] <> nil) or ((Child[2] = nil) and (Child[3] = nil)));
      Assert((Child[2] <> nil) or (Child[3] = nil));
      Result := true;
   end;
end;

{ -------------------------- non-member routines --------------------------- }

{ returns the left-most leaf of the sub-tree of node; if node is nil
  then nil is returned }
function LeftMostLeafNode(node : P23TreeNode) : P23TreeNode;
begin
   if node <> nil then
   begin
      while node^.Child[1] <> nil do
         node := node^.Child[1];
   end;
   Result := node;
end;

{ returns the right-most leaf of the sub-tree of node; if node is nil
  then nil is returned }
function RightMostLeafNode(node : P23TreeNode) : P23TreeNode;
begin
   if node <> nil then
   begin
      while node^.Child[2] <> nil do
      begin
         if node^.Child[3] <> nil then
            node := node^.Child[3]
         else
            node := node^.Child[2]
      end;
   end;
   Result := node;
end;

function SubTreeSize(node : P23TreeNode) : SizeType;
var
   finish, parent : P23TreeNode;
begin
   Result := 0;
   if node <> nil then
   begin
      { visit all nodes in pre-order counting items in each node }
      finish := node^.Parent;
      repeat
         Inc(Result);
         if node^.StoredItems = 2 then
            Inc(Result);

         if node^.Child[1] <> nil then
            node := node^.Child[1]
         else begin
            parent := node^.Parent;
            while (parent <> finish) and
                     ((parent^.Child[3] = node) or
                         ((parent^.Child[2] = node) and
                              (parent^.Child[3] = nil))) do
            begin
               node := parent;
               parent := parent^.Parent;
            end;
            if parent <> finish then
            begin
               if parent^.Child[1] = node then
                  node := parent^.Child[2]
               else
                  node := parent^.Child[3];
            end else
               break;
         end;
      until false;
   end;
end;



{ -------------------------- T23Tree --------------------------------- }

constructor T23Tree.Create;
begin
   inherited;
   InitFields;
end;

constructor T23Tree.CreateCopy(const cont : T23Tree;
                               const itemCopier : IUnaryFunctor);
var
   item2, item3 : ItemType;
   pdest : ^P23TreeNode;
   src, destparent : P23TreeNode;
   storedi : 1..2;

begin
   if itemCopier = nil then
      CreateCopyWithoutItems(cont)
   else begin
      inherited CreateCopy(TSetAdt(cont));
      FSize := cont.FSize;
      FValidSize := cont.FValidSize;
      FHeight := cont.FHeight;
      LowestItem := DefaultItem; { O.K. }
      if cont.LowestItem <> DefaultItem then
         LowestItem := itemCopier.Perform(cont.LowestItem);

      if cont.FRoot = nil then
      begin
         FRoot := nil;
         Exit;
      end;

      try
         { copy every node while moving in pre-order }
         pdest := @FRoot; { pointer to where to place the newly created node }
         destparent := nil;
         src := cont.FRoot;

         repeat
            if src^.StoredItems >= 1 then
            begin
               item2 := itemCopier.Perform(src^.LowItem[2]); { may raise }
               storedi := 1;
            end;

            if src^.StoredItems = 2 then
            begin
               item3 := itemCopier.Perform(src^.LowItem[3]); { may raise }
               storedi := 2;
            end;

            NewNode(pdest^); { may raise }
            with pdest^^ do
            begin
               StoredItems := storedi;
               LowItem[2] := item2;
               LowItem[3] := item3;
               Parent := destparent;
               Child[1] := nil;
               Child[2] := nil;
               Child[3] := nil;
            end;

            if src^.Child[1] <> nil then
            begin
               src := src^.Child[1];
               destparent := pdest^;
               pdest := @(pdest^^.Child[1]);
            end else
            begin
               { we have to go up the tree to the nearest unvisited node }
               while src^.Parent <> nil do
               begin
                  if (src^.Parent^.Child[1] = src) and
                        (src^.Parent^.Child[2] <> nil) then
                  begin
                     src := src^.Parent^.Child[2];
                     pdest := @(destparent^.Child[2]);
                     break;
                  end else if (src^.Parent^.Child[2] = src) and
                                 (src^.Parent^.Child[3] <> nil) then
                  begin
                     src := src^.Parent^.Child[3];
                     pdest := @(destparent^.Child[3]);
                     break;
                  end else
                  begin
                     src := src^.Parent;
                     destparent := destparent^.Parent;
                  end;
               end;

            end;

         until src^.Parent = nil;

      except
         if storedi >= 1 then
            DisposeItem(item2);
         if storedi = 2 then
            DisposeItem(item3);
         raise;
      end;
   end; { end not itemCopier = nil }
end;

constructor T23Tree.CreateCopyWithoutItems(const tree : T23Tree);
begin
   inherited CreateCopy(TSetAdt(tree));
   InitFields;
end;

destructor T23Tree.Destroy;
begin
   Clear;
   inherited;
end;

procedure T23Tree.InitFields;
begin
   LowestItem := DefaultItem;
   FRoot := nil;
   FSize := 0;
   FValidSize := true;
   FHeight := 0;
end;

procedure T23Tree.DeleteSubTree(node : P23TreeNode);
var
   parent, fin : P23TreeNode;
   child : Integer;
begin
   if node <> nil then
   begin
      { visit all nodes in post-order destroying every visited node }
      fin := node^.Parent;
      node := LeftMostLeafNode(node);
      parent := node^.Parent;
      while parent <> fin do
      begin
         if parent^.Child[1] = node then
            child := 1
         else if parent^.Child[2] = node then
            child := 2
         else
            child := 3;

         if node^.StoredItems >= 1 then
         begin
            DisposeItem(node^.LowItem[2]);
            Dec(FSize);
         end;

         if node^.StoredItems = 2 then
         begin
            DisposeItem(node^.LowItem[3]);
            Dec(FSize);
         end;

         DisposeNode(node);

         if (child = 1) or ((child = 2) and (parent^.Child[3] <> nil)) then
            node := LeftMostLeafNode(parent^.Child[child + 1])
         else { all children of parent visited - go to parent }
            node := parent;

         parent := node^.Parent;
      end;

      if node^.StoredItems >= 1 then
      begin
         DisposeItem(node^.LowItem[2]);
         Dec(FSize);
      end;

      if node^.StoredItems = 2 then
      begin
         DisposeItem(node^.LowItem[3]);
         Dec(FSize);
      end;

      DisposeNode(node);
   end;
end;

{ Recursive schema of traversal of a 2-3 tree with items contained in
  internal nodes: }
{ 1) traverse the 1st sub-tree (if exists); 1st sub-tree does not
  exist when we are at the level of leaves, because the lowest item in
  this sub-tree is contained in some higher internal node }
{ 2) visit the 2nd's sub-tree's smallest item (this is LowItem[2]) }
{ 3) traverse the 2nd sub-tree }
{ 4) visit the smallest item of the 3rd sub-tree (if exists) }
{ 5) traverse the 3rd sub-tree if it exists }
{ NOTE: the fact that StoredItems >= n-1 (i.e. there exists the lowest
  item of the n-th sub-tree) does not imply that Child[n] is non-nil
  (i.e. there exists the n-th sub-tree); this is because the lowest
  item of a sub-tree is not stored in this sub-tree, but in its
  parent; so, when there is only one item in a sub-tree the sub-tree
  does not physically exist (although it exists logically); in the
  above discussion I referred to the physical existence, not logical }
{ advances pair (node,low) to next item }
procedure T23Tree.AdvanceNode(var node : P23TreeNode; var low : Integer);

   procedure FinishTraversalOfSubTree;
   var
      current : P23TreeNode;
   begin
      { go up the tree as long as we need to finish the traversal
        of the sub-tree we are currently visiting - i.e. as long as
        the next item to visit does not exist in the current
        sub-tree }
      current := node^.Parent;
      while (current <> nil) and
               ((current^.Child[3] = node) or
                   ((current^.Child[2] = node) and
                       (current^.StoredItems < 2))) do
      begin
         node := current;
         current := current^.Parent;
      end;

      if current <> nil then
      begin
         if current^.Child[1] = node then
            low := 2 { step 2 }
         else { current^.Child[2] = node -> step 4 }
            low := 3;
      end else
         low := 0; { whole tree traversed }
      node := current;
   end;

begin
   Assert((node <> nil) or (low = 1), msgAdvancingFinishIterator);

   if (node = nil) and (low = 1) then
   begin
      node := LeftMostLeafNode(FRoot);
      if node <> nil then
         low := 2
      else
         low := 0;
   end else if node^.Child[low] <> nil then
      { now step 3 (if low is 2) or 5 (if low is 3) -> start traversal
        of the low-th sub-tree - go to the second-smallest item in
        that sub-tree (because the first-smallest was already visited)
        - this is the LowItem[2] at the left-most leaf of this
        sub-tree }
   begin
      node := LeftMostLeafNode(node^.Child[low]);
      low := 2;
   end else if low = 2 then
      { skip step 3; go to step 4 - visit lowest item in the 3rd sub-tree }
   begin
      Inc(low);
      if node^.StoredItems < 2 then
         { no lowest item in third sub-tree - finish traversal of
           sub-tree of node }
      begin
         FinishTraversalOfSubTree;
      end;
   end else { (low = 3) and (node^.Child[3] = nil) }
   begin
      FinishTraversalOfSubTree;
   end;
end;

{ Recursive schema of backwards traversal of a 2-3 tree with items
  contained in internal nodes: }
{ 1) traverse the 3rd sub-tree (if exists) }
{ 2) visit the lowest item in the 3rd sub-tree (if exists) }
{ 3) traverse the 2nd sub-tree }
{ 4) visit the lowest item in the 2nd sub-tree }
{ 5) traverse the 1st sub-tree }
{ retreats the pair (node,low) to the previous item; does not accept (nil,1) }
procedure T23Tree.RetreatNode(var node : P23TreeNode; var low : Integer);
var
   parent : P23TreeNode;
begin
   Assert((node <> nil) or (low = 0), msgInternalError);

   if low = 2 then
   begin
      if node^.Child[1] <> nil then
      begin
         { traverse 1st sub-tree }
         node := RightMostLeafNode(node^.Child[1]);
         if node^.StoredItems = 2 then
            low := 3
         else
            low := 2;
      end else
      begin
         { we traversed the first sub-tree - finish traversal of
           sub-tree of node }
         { go up as long as we have to finish traversal - i.e. as long
           as node is the first child of parent }
         parent := node^.Parent;
         while (parent <> nil) and (parent^.Child[1] = node) do
         begin
            node := parent;
            parent := parent^.Parent;
         end;

         if parent <> nil then
         begin
            if parent^.Child[3] = node then
               low := 3 { finished traversal of 3rd sub-tree -> visit
                          3rd sub-tree's lowest item }
            else
               low := 2;
         end else
            low := 1; { go to the first item in the tree }
         node := parent;
      end;
   end else if low = 3 then
   begin
      if node^.Child[2] <> nil then
      begin
         { traverse second sub-tree }
         node := RightMostLeafNode(node^.Child[2]);
         if node^.StoredItems = 2 then
            low := 3
         else
            low := 2;
      end else
      begin
         { visit 2nd sub-tree's lowest item }
         low := 2;
      end;
   end else { low = 0 }
   begin
      node := RightMostLeafNode(FRoot);
      if node <> nil then
      begin
         if node^.StoredItems = 2 then
            low := 3
         else
            low := 2;
      end else
      begin
         Assert((FSize <> 0) or not FValidSize, msgRetreatingStartIterator);
         low := 1;
      end;
   end;
end;

function T23Tree.FindNode(aitem : ItemType; startNode : P23TreeNode;
                          var found : P23TreeNode; var low : Integer) : Boolean;
var
   i : Integer;

   function FindNodeAux(node : P23TreeNode) : Boolean;
   begin
      Result := false;
      while node <> nil do
      begin
         found := node;
         _mcp_compare_assign(aitem, node^.LowItem[2], i);
         if i < 0 then
         begin
            low := 1;
            node := node^.Child[1];
         end else if i > 0 then
         begin
            if node^.StoredItems = 2 then
            begin
               _mcp_compare_assign(aitem, node^.LowItem[3], i);
               if i < 0 then
               begin
                  low := 2;
                  node := node^.Child[2];
               end else if i > 0 then
               begin
                  low := 3;
                  node := node^.Child[3];
               end else { i = 0 -> node^.LowItem[3] = aitem }
               begin
                  { we have to find the _first_ occurence }
                  if RepeatedItems then
                  begin
                     if not FindNodeAux(node^.Child[2]) then
                     begin
                        { reset found and low to values they had
                          before invoking this function }
                        found := node;
                        low := 3;
                     end;
                  end else
                     low := 3;

                  Result := true;
                  Exit;
               end;
            end else { no third sub-tree }
            begin
               low := 2;
               node := node^.Child[2];
            end;
         end else { i = 0 -> node^.LowItem[2] = aitem }
         begin
            { we have to find the _first_ item equal to aitem }
            if RepeatedItems then
            begin
               if not FindNodeAux(node^.Child[1]) then
               begin
                  found := node;
                  low := 2;
               end;
            end else
               low := 2;

            Result := true;
            Exit;
         end;
      end; { end while node <> nil }
   end; { end FindNodeAux }

begin
   if (FSize <> 0) or not FValidSize then
   begin
      _mcp_compare_assign(aitem, LowestItem, i);
      if i < 0 then
      begin
         found := nil;
         low := 1;
         Result := false;
         Exit;
      end else if i = 0 then
      begin
         found := nil;
         low := 1;
         Result := true;
         Exit;
      end;
   end;

   found := nil;
   low := 0;
   Result := FindNodeAux(startNode);
end;

function T23Tree.LowerBoundNode(aitem : ItemType; node : P23TreeNode;
                                var lb : P23TreeNode;
                                var low : Integer) : Boolean;
var
   i : Integer;
begin
   if (FSize <> 0) or not FValidSize then
   begin
      _mcp_compare_assign(aitem, LowestItem, i);
      if i <= 0 then
      begin
         lb := nil;
         low := 1;
         if i = 0 then
            Result := true
         else
            Result := false;
      end else if FRoot <> nil then
      begin
         if not FindNode(aitem, node, lb, low) then
         begin
            if (low = 3) or (lb^.StoredItems = 1) then
            begin
               AdvanceNode(lb, low);
            end else
               Inc(low);
            Result := false;
         end else
            Result := true;
      end else
         { only one item in the container which is smaller than aitem }
      begin
         lb := nil;
         low := 0;
         Result := false;
      end;

   end else { empty container }
   begin
      lb := nil;
      low := 0;
      Result := false;
   end;
end;

procedure T23Tree.InsertNode(parent : P23TreeNode; cnum : Integer;
                             aitem : ItemType; node : P23TreeNode;
                             var inserted : P23TreeNode; var low : Integer);
var
   pnewnode, tempnode, oldroot, ln, rn, pparent : P23TreeNode;
   pnum : Integer; { which child is parent in its parent ? }
   itemlow : ItemType; { the lowest item in the sub-tree of node
                       (logically - i.e. not physically contained
                       within that sub-tree) }
   templow : ItemType;

begin
   Assert(parent <> nil, msgInternalError);
   Assert((cnum >= 1) and (cnum <= 3));
//   Assert(aitem <> nil);
   itemlow := DefaultItem; { to shut the compiler up }
   try
      { now, insert aitem into the tree as cnum+1 child of parent; if
        parent has 4 children after insertion we have to distribute
        the excessive child among neighbour nodes or split it (the
        node with 4 children) into two nodes with two children each
        and proceed up the tree applying the same rule to the newly
        created node (to insert it on the higher level); cnum is the
        number of the child of parent _after_ which to insert; itemlow
        indicates the lowest item in the sub-tree of node; node is the
        node from the previous level that must be inserted as a cnum+1
        child of parent }
      itemlow := aitem;
      while parent <> nil do
      begin
         { insert node as (cnum + 1)th child and shift children > cnum
           right, until one has to be shifted to the 4th child and assign
           it to node (this may be as well the original node - when cnum
           is 3 before this loop) }
         Assert((cnum >= 1) and (cnum <= 3));
         Assert(cnum > 0);
         Assert(NodeConsistent(parent));
         Assert((node = nil) or NodeConsistent(node));

         if (cnum < 3) and (aitem = itemlow) then
         begin
            inserted := parent;
            low := cnum + 1;
         end;

         if cnum = 1 then
         begin
            tempnode := parent^.Child[2];
            templow := parent^.LowItem[2];
            Inc(cnum);

            parent^.Child[2] := node;
            if node <> nil then
               node^.Parent := parent;
            parent^.LowItem[2] := itemlow;

            node := tempnode;
            itemlow := templow;
         end;

         if cnum = 2 then
         begin
            if parent^.StoredItems = 2 then
            begin
               tempnode := parent^.Child[3];
               templow := parent^.LowItem[3];
               Inc(cnum);
            end else
               parent^.StoredItems := 2;
            parent^.Child[3] := node;
            if node <> nil then
               node^.Parent := parent;
            parent^.LowItem[3] := itemlow;

            node := tempnode;
            itemlow := templow;
         end;


         if (cnum = 3) then
         begin
            { parent would have 4 children after insertion - we can
              try three things: }
            { - if parent has a right neighbour and this neighbour
              has 2 children then move the 4th child of parent to the
              1st child of its right neighbour }
            { - if parent has a left neighbour and this neighbour has
              2 children then move the first child of parent to the
              3rd child of its left neighbour }
            { - otherwise, if both neighbours of parent have 3
              children or don't exist, we have to split it into two
              nodes with two children each }

            pparent := parent^.Parent;
            if pparent <> nil then
            begin
               if (pparent^.Child[1] = parent) then
                  pnum := 1
               else if pparent^.Child[2] = parent then
                  pnum := 2
               else { if pparent^.Child[3] = parent then }
                  pnum := 3;
            end;

            if (pparent <> nil) and (pnum + 1 <= 3) and
                  (pparent^.Child[pnum + 1] <> nil) and
                  (pparent^.Child[pnum + 1]^.StoredItems < 2) then
            begin
               { move the 4th child of parent to the 1st child of its
                 right neighbour }

               rn := pparent^.Child[pnum + 1];
               with rn^ do
               begin
                  StoredItems := 2;
                  LowItem[3] := LowItem[2];
                  LowItem[2] := pparent^.LowItem[pnum + 1];
                  Child[3] := Child[2];
                  Child[2] := Child[1];
                  Child[1] := node;
                  if node <> nil then
                     node^.Parent := rn;

                  pparent^.LowItem[pnum + 1] := itemlow;
               end;

               if pparent^.LowItem[pnum + 1] = aitem then
               begin
                  inserted := pparent;
                  low := pnum + 1;
               end;

               break;

            end else if (pparent <> nil) and (pnum - 1 >= 1) and
                           (pparent^.Child[pnum - 1] <> nil) and
                           (pparent^.Child[pnum - 1]^.StoredItems < 2) then
            begin
               { move the 1st child of parent to the 3rd child of
                 parent's left neighbour }
               ln := pparent^.Child[pnum - 1];
               with parent^ do
               begin
                  ln^.Child[3] := Child[1];
                  if ln^.Child[3] <> nil then
                     ln^.Child[3]^.Parent := ln;
                  ln^.LowItem[3] := pparent^.LowItem[pnum];
                  ln^.StoredItems := 2;

                  pparent^.LowItem[pnum] := LowItem[2];
                  LowItem[2] := LowItem[3];
                  LowItem[3] := itemlow;

                  Child[1] := Child[2];
                  Child[2] := Child[3];
                  Child[3] := node;
               end;
               if node <> nil then
                  node^.Parent := parent;

               if parent^.LowItem[3] = aitem then
               begin
                  inserted := parent;
                  low := 3;
               end else if parent^.LowItem[2] = aitem then
               begin
                  inserted := parent;
                  low := 2;
               end else if pparent^.LowItem[pnum] = aitem then
               begin
                  inserted := pparent;
                  low := pnum;
               end;

               break; { propagation finished - the tree is 'in
                        Ordnung' }

            end else { cannot move the execessive child to neighbours }
            begin
               { because cnum is 3 the node from the previous level is
                 required to be inserted after the 3rd child (ie. as
                 the 4th child in parent - as the 2nd child in
                 pnewnode, because the last two children of parent go
                 to pnewnode) }
               NewNode(pnewnode);
               pnewnode^.Child[1] := parent^.Child[3];
               with pnewnode^ do
               begin
                  if Child[1] <> nil then
                     Child[1]^.Parent := pnewnode;

                  Child[2] := node;
                  if node <> nil then
                     node^.Parent := pnewnode;

                  LowItem[2] := itemlow;

                  Child[3] := nil;
                  LowItem[3] := DefaultItem;

                  StoredItems := 1;
               end;
               itemlow := parent^.LowItem[3];

               with parent^ do
               begin
                  Child[3] := nil;
                  LowItem[3] := DefaultItem;
                  StoredItems := 1;
               end;

               if pnewnode^.LowItem[2] = aitem then
               begin
                  inserted := pnewnode;
                  low := 2;
               end;

               { now pnewnode must be inserted at higher level }
               node := pnewnode;

               { go one level up }
               parent := pparent;
               cnum := pnum;

            end;

         end else
            { not cnum = 3 => there is no excessive child - no need to
              proceed }
         begin
            break;
         end;

      end; { end while (parent <> nil) and (there is at least one item
             to be inserted) }

      if parent = nil then
      begin
         { the root was splitted - we have to create a new root with the
           two nodes obtained from splitting the old root as its children }
         oldroot := FRoot;
         NewNode(FRoot);
         with FRoot^ do
         begin
            Child[1] := oldroot;
            Child[2] := node;
            Child[3] := nil;
            LowItem[2] := itemlow;
            LowItem[3] := DefaultItem;
            Parent := nil;
            StoredItems := 1;
         end;
         oldroot^.Parent := FRoot;
         node^.Parent := FRoot;
         Inc(FHeight);
      end;

   except
      { now, we cannot get the tree back to its previous state and we
        are left with node not connected anywhere and itemlow not
        placed anywhere in the tree - just dispose node and itemlow not
        to leak anything, regardless of how valueable data they may
        contain }
      if node <> nil then
      begin
         { we cannot dispose the item we insert as it is supposed to
           be left intact when an exception occurs }
         if inserted^.LowItem[low] = aitem then
         begin { should be always true, above; but no one ever
                 knows...  }
            inserted^.LowItem[low] := DefaultItem;
            if low = 3 then
               inserted^.StoredItems := 1
            else { low = 2 }
            begin
               DeleteNode(inserted, low);
            end;
         end;

         if itemlow <> aitem then
            DisposeItem(itemlow);
         DeleteSubTree(node);
         FValidSize := false;
      end;
      raise;
   end;
end;

function T23Tree.DoInsert(aitem : ItemType; node : P23TreeNode;
                            var inserted : P23TreeNode;
                            var low : Integer) : Boolean;
var
   parent : P23TreeNode; { a would-be parent of the new node }
   cnum : Integer; { the number of the child _after_ which new node
                     should be inserted (in parent) }
   tmp : ItemType;
   dummy1 : P23TreeNode;
   dummy2 : Integer;
begin
{$ifdef TEST_PASCAL_ADT }
//   LogStatus('DoInsert (aitem = ' + FormatItem(aitem)  +
//                ', node = %' + IntToStr(PointerValueType(node)) + '%)');
{$endif TEST_PASCAL_ADT }

   if (FSize = 0) and FValidSize then
   begin
      LowestItem := aitem;
      FSize := 1;
      FValidSize := true;
      inserted := nil;
      low := 1;
      Result := true;

   end else if FRoot = nil then
   begin
      NewNode(FRoot);
      with FRoot^ do
      begin
         if _mcp_lt(aitem, LowestItem) then
         begin
            LowItem[2] := LowestItem;
            LowestItem := aitem;
         end else
            LowItem[2] := aitem;

         LowItem[3] := DefaultItem;
         for cnum := 1 to 3 do
            Child[cnum] := nil;
         Parent := nil;
         StoredItems := 1;
      end;
      FSize := 2;
      FValidSize := true;
      FHeight := 1;
      inserted := FRoot;
      low := 2;
      Result := true;

   end else if node = nil then
   begin
      Result := DoInsert(aitem, FRoot, inserted, low);

   end else if FindNode(aitem, node, parent, cnum) then
   begin
      if RepeatedItems then
      begin
         if (parent = nil) and (cnum = 1) then
            { aitem is equal to LowestItem }
         begin
            if FRoot <> nil then
            begin
               { insert just after the first position in the tree }
               InsertNode(LeftMostLeafNode(FRoot), 1, aitem,
                          nil, inserted, low);
               Inc(FSize);
               Result := true;
            end else
            begin
               NewNode(FRoot);
               with FRoot^ do
               begin
                  LowItem[2] := aitem;
                  LowItem[3] := DefaultItem;
                  Child[1] := nil;
                  Child[2] := nil;
                  Child[3] := nil;
                  Parent := nil;
                  StoredItems := 1;
               end;
               inserted := FRoot;
               low := 2;
               FSize := 2;
               FValidSize := true;
               FHeight := 1;
               Result := true;
            end;
         end else
         begin
            { insert just after the found node }
            if parent^.Child[cnum] <> nil then
            begin
               { insert in the first node in the physical sub-tree of
                 the child }
               parent := LeftMostLeafNode(parent^.Child[cnum]);
               cnum := 1;
            end; { else parent (the found node) is a physical leaf and
                   we can insert aitem just after the position found (as
                   the (cnum + 1)th child) }
            InsertNode(parent, cnum, aitem, nil, inserted, low);
            Inc(FSize);
            Result := true;
         end;

      end else
      begin
         inserted := nil;
         low := 0;
         Result := false;
      end;

   end else if (parent = nil) and (cnum = 1) then
      { aitem should be inserted just before LowestItem }
   begin
      tmp := LowestItem;
      LowestItem := aitem;
      inserted := nil;
      low := 1;
      Result := DoInsert(tmp, FRoot, dummy1, dummy2);
   end else
      { not FindNode(...) -> (parent,cnum) pair has been assigned the
        position where an item equal to aitem should be placed (see
        the FindNode specification) }
   begin
      InsertNode(parent, cnum, aitem, nil, inserted, low);
      Inc(FSize);
      Result := true;
   end;
end;

function T23Tree.DeleteNode(nnode : P23TreeNode; low : Integer) : ItemType;
var
   leaf, child1, child2, prevnode, node, ln : P23TreeNode;
   cnum : Integer;
   onlyOne : Boolean;
begin
{$ifdef TEST_PASCAL_ADT }
//   LogStatus('DeleteNode (node = %' + IntToStr(PointerValueType(node)) + '%, low = ' +
//                IntToStr(low) + ')');
{$endif TEST_PASCAL_ADT }

   Assert((nnode <> nil) or (low = 1), msgInvalidIterator);
   Assert((low >= 1) and (low <= 3), msgInternalError);

   Dec(FSize);

   if (nnode = nil) and (low = 1) then
   begin
      Result := LowestItem;

      if FRoot <> nil then
      begin
         node := LeftMostLeafNode(FRoot);
         low := 2;
         LowestItem := node^.LowItem[2];
      end else
      begin
         LowestItem := DefaultItem;
         FSize := 0;
         FValidSize := true;
         Exit;
      end;
   end else
   begin
      Result := nnode^.LowItem[low];

      node := nnode;
   end;

   { now we have to place the second-lowest (logically) item from the
     sub-tree of node^.Child[low] to node^.LowItem[low] and reorganise
     the tree appropriately; the (physical) lowest item in a sub-tree
     is always in its left-most (physical) leaf }
   leaf := LeftMostLeafNode(node^.Child[low]);
   if leaf <> nil then
   begin
      { the second item in the left-most leaf is the next item after
        node }
      node^.LowItem[low] := leaf^.LowItem[2];

      with leaf^ do
      begin
         LowItem[2] := LowItem[3];
         LowItem[3] := DefaultItem;
         if StoredItems = 2 then
         begin
            StoredItems := 1;
            onlyOne := false;
         end else
            onlyOne := true;
      end;

      prevnode := leaf;
      node := leaf^.Parent;

   end else
   begin
      { node is a leaf (physically, logically it is a parent of leaves)
        - we don't have to find the new low item (as it does not
        exist) - just shift some items if necessary }
      if low = 3 then
      begin
         node^.LowItem[3] := DefaultItem;
         node^.StoredItems := 1;
         onlyOne := false;
      end else if low = 2 then
      begin
         with node^ do
         begin
            LowItem[2] := LowItem[3];
            LowItem[3] := DefaultItem;
            if StoredItems = 2 then
            begin
               StoredItems := 1;
               onlyOne := false;
            end else
               onlyOne := true;
         end;
      end;

      prevnode := node;
      node := node^.Parent;
   end;

   { onlyOne indicates whether the node altered on the previous level
     (prevnode) has only one child }
   while (node <> nil) and onlyOne do
   begin
      if node^.Child[1] = prevnode then
      begin
         { now the first child of node is left with only one child
           -> we have to add some children to it (to the first child of
           node) as it must have at least two }
         child1 := node^.Child[1];
         child2 := node^.Child[2];
         if child2^.StoredItems = 2 then
            { child2 has 3 children -> move the first child of
              child2 to child1 }
         begin
            child1^.Child[2] := child2^.Child[1];
            if child1^.Child[2] <> nil then
               child1^.Child[2]^.Parent := child1;

            child1^.LowItem[2] := node^.LowItem[2];
            child1^.StoredItems := 1;

            node^.LowItem[2] := child2^.LowItem[2];
            with child2^ do
            begin
               Child[1] := Child[2];
               Child[2] := Child[3];
               LowItem[2] := LowItem[3];
               Child[3] := nil;
               LowItem[3] := DefaultItem;
               StoredItems := 1;
            end;

            onlyOne := false; //

         end else
            { child2 has 2 children -> move the two children of
              child2 to child1 }
         begin
            child1^.Child[2] := child2^.Child[1];
            if child1^.Child[2] <> nil then
               child1^.Child[2]^.Parent := child1;

            child1^.Child[3] := child2^.Child[2];
            if child1^.Child[3] <> nil then
               child1^.Child[3]^.Parent := child1;

            child1^.LowItem[2] := node^.LowItem[2];
            child1^.LowItem[3] := child2^.LowItem[2];
            child1^.StoredItems := 2;
            { child2 does not contain any items any more - remove it }
            with node^ do
            begin
               LowItem[2] := LowItem[3];
               Child[2] := Child[3];
               LowItem[3] := DefaultItem;
               Child[3] := nil;
               if StoredItems = 2 then
               begin
                  StoredItems := 1;
                  onlyOne := false;
               end else
                  onlyOne := true;
            end;
            DisposeNode(child2);
         end;

      end else { not node^.Child[1] = prevnode }
      begin
         if node^.Child[2] = prevnode then
            cnum := 2
         else
            cnum := 3;

         ln := node^.Child[cnum - 1]; { left neighbour of prevnode }
         if ln^.StoredItems = 2 then
            { left neighbour of prevnode has 3 children -> move its
              3rd child to prevnode }
         begin
            with prevnode^ do
            begin
               LowItem[2] := node^.LowItem[cnum];
               Child[2] := Child[1];

               Child[1] := ln^.Child[3];
               if Child[1] <> nil then
                  Child[1]^.Parent := prevnode;

               node^.LowItem[cnum] := ln^.LowItem[3];
               StoredItems := 1;
            end;
            ln^.LowItem[3] := DefaultItem;
            ln^.Child[3] := nil;
            ln^.StoredItems := 1;

            onlyOne := false; //

         end else
            { left neighbour of prevnode has two children -> move the
              only child of prevnode to it }
         begin
            ln^.LowItem[3] := node^.LowItem[cnum];
            ln^.Child[3] := prevnode^.Child[1];
            if ln^.Child[3] <> nil then
               ln^.Child[3]^.Parent := ln;
            ln^.StoredItems := 2;

            { prevnode does not contain any items any longer and may
              be removed }
            DisposeNode(prevnode);

            with node^ do
            begin
               if cnum = 2 then
               begin
                  LowItem[2] := LowItem[3];
                  Child[2] := Child[3];
               end;
               LowItem[3] := DefaultItem;
               Child[3] := nil;
               if StoredItems = 2 then
               begin
                  StoredItems := 1;
                  onlyOne := false;
               end else
                  onlyOne := true;
            end;
         end;
      end;

      prevnode := node;
      node := node^.Parent;

   end; { end while (node <> nil) and onlyOne }

   if onlyOne then
      { the root remained with only one child - make this child the
        new root }
   begin
      child1 := prevnode^.Child[1];
      DisposeNode(prevnode); { i.e. dispose the root }
      FRoot := child1;
      if FRoot <> nil then
         FRoot^.Parent := nil
      else begin
         FSize := 1;
         FValidSize := true;
      end;
      Dec(FHeight);
   end;

end;

procedure T23Tree.Implant(node1, node2 : P23TreeNode;
                          lowitem1, lowitem2 : ItemType;
                          height1, height2 : SizeType);
var
   tmp, rubbish1 : P23TreeNode;
   rubbish2, num : Integer;
begin
   Assert((FRoot = nil) or (FRoot = node1) or (FRoot = node2), msgInternalError);

   if _mcp_gt(lowitem1, lowitem2) then
   begin
      ExchangeData(node1, node2, SizeOf(P23TreeNode));
      ExchangeData(lowitem1, lowitem2, SizeOf(ItemType));
      ExchangeData(height1, height2, SizeOf(SizeType));
   end;

{$ifdef DEBUG_PASCAL_ADT }
   if node1 <> nil then
   begin
      tmp := RightMostLeafNode(node1);
      if tmp^.StoredItems = 2 then
         Assert(_mcp_lte(tmp^.LowItem[3], lowitem2), msgItemsNotSmaller)
      else
         Assert(_mcp_lte(tmp^.LowItem[2], lowitem2), msgItemsNotSmaller);
   end;
{$endif }

   if height1 = height2 then
   begin
      NewNode(FRoot);
      with FRoot^ do
      begin
         Parent := nil;
         LowItem[2] := lowitem2;
         LowItem[3] := DefaultItem;
         Child[1] := node1;
         Child[2] := node2;
         Child[3] := nil;
         if Child[1] <> nil then
            Child[1]^.Parent := FRoot;
         if Child[2] <> nil then
            Child[2]^.Parent := FRoot;
         StoredItems := 1;
      end;
      LowestItem := lowitem1;
      FHeight := height1 + 1;

   end else if height1 < height2 then
   begin
      { connect node1 at the left of node2 in such a way that the
        leaves of node1 will be at the same level as those of node2 }
      FRoot := node2;
      FRoot^.Parent := nil;
      FHeight := height2;

      Dec(height2);
      while height2 <> height1 do
      begin
         Dec(height2);
         node2 := node2^.Child[1];
      end;

      tmp := node2^.Child[1];
      node2^.Child[1] := node1;
      if node1 <> nil then
         node1^.Parent := node2;
      LowestItem := lowitem1;
      InsertNode(node2, 1, lowitem2, tmp, rubbish1, rubbish2);

   end else { height1 > height2 }
   begin
      FRoot := node1;
      FRoot^.Parent := nil;
      FHeight := height1;
      LowestItem := lowitem1;

      Dec(height1);
      while height1 <> height2 do
      begin
         Dec(height1);
         if node1^.Child[3] <> nil then
            node1 := node1^.Child[3]
         else
            node1 := node1^.Child[2];
      end;

      if node1^.StoredItems = 2 then
         num := 3
      else
         num := 2;

      InsertNode(node1, num, lowitem2, node2, rubbish1, rubbish2);
   end;
end;

procedure T23Tree.NewNode(var node : P23TreeNode);
begin
   New(node);
end;

procedure T23Tree.DisposeNode(var node : P23TreeNode);
begin
   Dispose(node);
end;

{$ifdef TEST_PASCAL_ADT }
procedure T23Tree.LogStatus(mName : String);
var
   queuei : TIntegerDynamicArray;
   queuen : TPointerDynamicArray;
   level, clev : Integer;
   cnode, par : P23TreeNode;
begin
   inherited LogStatus('T23Tree.' + mName);

   if (FSize = 0) and FValidSize then
   begin
      WriteLog('The tree is empty');
      Exit;
   end else if FSize = 1 then
   begin
      WriteLog('Size = 1');
      WriteLog('LowestItem: ' + FormatItem(LowestItem));
      Exit;
   end;

   level := 0;
   ArrayAllocate(queuei, 100, 0);
   ArrayAllocate(queuen, 100, 0);

   try
      ArrayCircularPushBack(queuei, level + 1);
      ArrayCircularPushBack(queuen, FRoot);

      { print the content of the tree by levels }
      WriteLog;
      WriteLog('Contents of T23Tree (by reversed levels):');
      WriteLog;
      if (FSize <> 0) or not FValidSize then
         WriteLog('LowestItem: ' + FormatItem(LowestItem))
      else
         WriteLog('LowestItem: none');
      WriteLog;

      while queuei^.Size <> 0 do
      begin
         clev := ArrayCircularPopFront(queuei);
         cnode := P23TreeNode(ArrayCircularPopFront(queuen));
         if clev <> level then
         begin
            level := clev;
            WriteLog('*******************************');
            WriteLog('level *' + IntToStr(level) + '*');
         end;

         WriteLog;
         WriteLog('node <' + IntToStr(PointerValueType(cnode)) + '>');
         par := cnode^.Parent;
         WriteLog('Parent: %' + IntToStr(PointerValueType(par)) + '%');
         if par = nil then
         begin
            if (level <> 1) then
               WriteLog('!!!!! Wrong parent !!!!!');
         end else
         begin
            if (par^.Child[1] <> cnode) and (par^.Child[2] <> cnode) and
                  (par^.Child[3] <> cnode) then
            begin
               WriteLog('!!!!! Wrong parent !!!!!');
            end;
         end;

         if cnode^.StoredItems >= 1 then { always true  }
            WriteLog('LowItem[2]: ' + FormatItem(cnode^.LowItem[2]))
         else
            WriteLog('LowItem[2]: none');

         if cnode^.StoredItems = 2 then
            WriteLog('LowItem[3]: ' + FormatItem(cnode^.LowItem[3]))
         else
            WriteLog('LowItem[3]: none');

         WriteLog('Child[1]: %' +
                     IntToStr(PointerValueType(cnode^.Child[1])) + '%');
         WriteLog('Child[2]: %' +
                     IntToStr(PointerValueType(cnode^.Child[2])) + '%');
         WriteLog('Child[3]: %' +
                     IntToStr(PointerValueType(cnode^.Child[3])) + '%');
         WriteLog;
         for clev := 1 to 3 do
         begin
            if cnode^.Child[clev] <> nil then
            begin
               ArrayCircularPushBack(queuei, level + 1);
               ArrayCircularPushBack(queuen, cnode^.Child[clev]);
            end;
         end;
      end;

   finally
      ArrayDeallocate(queuei);
      ArrayDeallocate(queuen);
   end;

end;

{$endif TEST_PASCAL_ADT }

function T23Tree.CopySelf(const ItemCopier :
                             IUnaryFunctor) : TContainerAdt;
begin
   Result := T23Tree.CreateCopy(self, itemCopier);
end;

procedure T23Tree.Swap(cont : TContainerAdt);
var
   tree : T23Tree;
begin
   if cont is T23Tree then
   begin
      BasicSwap(cont);
      tree := T23Tree(cont);
      ExchangePtr(FRoot, tree.Froot);
      ExchangeData(LowestItem, tree.LowestItem, SizeOf(ItemType));
      ExchangeData(FHeight, tree.FHeight, SizeOf(SizeType));
      ExchangeData(FSize, tree.FSize, SizeOf(SizeType));
      ExchangeData(FValidSize, tree.FValidSize, SizeOf(Boolean));
   end else
      inherited;
end;

function T23Tree.Start : TSetIterator;
begin
   Result := T23TreeIterator.Create(nil, 1, self);
end;

function T23Tree.Finish : TSetIterator;
begin
   Result := T23TreeIterator.Create(nil, 0, self);
end;

&if (&_mcp_accepts_nil)
function T23Tree.FindOrInsert(aitem : ItemType) : ItemType;
var
   node : P23TreeNode;
   low : Integer;
begin
   if RepeatedItems then
   begin
      DoInsert(aitem, FRoot, node, low);
      Result := nil;
   end else
   begin
      if not FindNode(aitem, FRoot, node, low) then
      begin
         DoInsert(aitem, node, node, low);
         Result := nil;
      end else if (node = nil) and (low = 1) then
         Result := LowestItem
      else
         Result := node^.LowItem[low];
   end;
end;

function T23Tree.Find(aitem : ItemType) : ItemType;
var
   node : P23TreeNode;
   low : Integer;
begin
   if FindNode(aitem, FRoot, node, low) then
   begin
      if (node = nil) and (low = 1) then
         Result := LowestItem
      else
         Result := node^.LowItem[low]
   end else
      Result := nil;
end;
&endif &# end &_mcp_accepts_nil

function T23Tree.Has(aitem : ItemType) : Boolean;
var
   node : P23TreeNode;
   low : Integer;
begin
   Result := FindNode(aitem, FRoot, node, low);
end;

function T23Tree.Count(aitem : ItemType) : SizeType;
var
   node : P23TreeNode;
   low : Integer;
begin
   Result := 0;
   if FindNode(aitem, FRoot, node, low) then
   begin
      repeat
         Inc(Result);
         AdvanceNode(node, low);
      until (node = nil) or (not _mcp_equal(node^.LowItem[low], aitem));
   end;
end;

function T23Tree.Insert(pos : TSetIterator; aitem : ItemType) : Boolean;
var
   node, nextnode, prevnode : P23TreeNode;
   low, i, nextlow, prevlow : Integer;
begin
   Assert(pos is T23TreeIterator, msgInvalidIterator);

   node := T23TreeIterator(pos).FNode;
   low := T23TreeIterator(pos).FLow;

   if node = nil then
   begin
      Result := DoInsert(aitem, FRoot, node, low);
      Exit;
   end;

   _mcp_compare_assign(node^.LowItem[low], aitem, i);
   if i < 0 then
   begin
      { get the last position < aitem }
      nextnode := node;
      nextlow := low;
      while i < 0 do
      begin
         node := nextnode;
         low := nextlow;
         AdvanceNode(nextnode, nextlow);
         if nextnode <> nil then
         begin
            _mcp_compare_assign(nextnode^.LowItem[nextlow], aitem, i);
         end else
         begin
            i := 0;
         end;
      end;
   end else if i > 0 then
   begin
      { get the first position <= aitem }
      while i > 0 do
      begin
         RetreatNode(node, low);
         if node <> nil then
         begin
            _mcp_compare_assign(node^.LowItem[low], aitem, i);
         end else
         begin
            i := 0;
            node := FRoot;
         end;
      end;
   end else { i = 0 }
   begin
      { get the first position = aitem }
      prevnode := node;
      prevlow := low;
      while i = 0 do
      begin
         node := prevnode;
         low := prevlow;
         RetreatNode(prevnode, prevlow);
         if prevnode <> nil then
         begin
            _mcp_compare_assign(prevnode^.LowItem[prevlow], aitem, i);
         end else
            i := 0;
      end;
   end;

   Result := DoInsert(aitem, node, node, low);
end;

function T23Tree.Insert(aitem : ItemType) : Boolean;
var
   inserted : P23TreeNode;
   low : Integer;
begin
   Result := DoInsert(aitem, FRoot, inserted, low);
end;

procedure T23Tree.Delete(pos : TSetIterator);
var
   aitem : ItemType;
begin
   Assert(pos is T23TreeIterator, msgInvalidIterator);
   Assert(T23TreeIterator(pos).FNode <> nil, msgInvalidIterator);

   aitem := DeleteNode(T23TreeIterator(pos).FNode,
                       T23TreeIterator(pos).FLow);
   DisposeItem(aitem);
end;

function T23Tree.Delete(aitem : ItemType) : SizeType;
var
   node : P23TreeNode;
   low : Integer;
   temp : ItemType;
begin
   node := FRoot;
   Result := 0;
   while FindNode(aitem, FRoot, node, low) do
   begin
      Inc(Result);
      temp := DeleteNode(node, low);
      DisposeItem(temp);
   end;
end;

function T23Tree.LowerBound(aitem : ItemType) : TSetIterator;
var
   node : P23TreeNode;
   low : Integer;
begin
   LowerBoundNode(aitem, FRoot, node, low);
   Result := T23TreeIterator.Create(node, low, self)
end;

function T23Tree.UpperBound(aitem : ItemType) : TSetIterator;
var
   node : P23TreeNode;
   low : Integer;
begin
   if LowerBoundNode(aitem, FRoot, node, low) then
   begin
      repeat
         AdvanceNode(node, low);
      until (node = nil) or (not _mcp_equal(node^.LowItem[low], aitem));
   end;
   Result := T23TreeIterator.Create(node, low, self);
end;

function T23Tree.EqualRange(aitem : ItemType) : TSetIteratorRange;
var
   node : P23TreeNode;
   low : Integer;
   iter1, iter2 : T23TreeIterator;
   bfound : Boolean;
begin
   bfound := LowerBoundNode(aitem, FRoot, node, low);
   iter1 := T23TreeIterator.Create(node, low, self);
   if bfound then
   begin
      repeat
         AdvanceNode(node, low);
      until (node = nil) or (not _mcp_equal(node^.LowItem[low], aitem));
   end;
   iter2 := T23TreeIterator.Create(node, low, self);
   Result := TSetIteratorRange.Create(iter1, iter2);
end;

function T23Tree.First : ItemType;
begin
   Assert((FSize <> 0) or not FValidSize, msgReadEmpty);
   Result := LowestItem;
end;

function T23Tree.ExtractFirst : ItemType;
begin
   Result := DeleteNode(nil, 1);
end;

procedure T23Tree.Concatenate(aset : TConcatenableSortedSetAdt);
var
   tree : T23Tree;
begin
   Assert(aset is T23Tree, msgWrongContainerType);

   tree := T23Tree(aset);

   Implant(FRoot, tree.FRoot, LowestItem, tree.LowestItem,
           FHeight, tree.FHeight);

   FValidSize := FValidSize and tree.FValidSize;
   FSize := FSize + tree.FSize;

   with tree do
   begin
      LowestItem := DefaultItem;
      FRoot := nil;
      FSize := 0;
      FHeight := 0;
      Destroy;
   end;

end;

function T23Tree.Split(aitem : ItemType) : TConcatenableSortedSetAdt;
var
   lforest1, rforest1 : TPointerDynamicArray;
   lforest2, rforest2 : TDynamicArray; { generic }
   lforest3, rforest3 : TIntegerDynamicArray;
   firstlow, itemlow : ItemType;
   node, dnode : P23TreeNode;
   depth, height : SizeType;
   tree : T23Tree;
   i : IndexType;

begin
   lforest1 := nil;
   lforest2 := nil;
   lforest3 := nil;
   rforest1 := nil;
   rforest2 := nil;
   rforest3 := nil;
   try
      ArrayAllocate(lforest1, 90, 0);
      ArrayAllocate(lforest2, 90, 0);
      ArrayAllocate(lforest3, 90, 0);
      ArrayAllocate(rforest1, 90, 0);
      ArrayAllocate(rforest2, 90, 0);
      ArrayAllocate(rforest3, 90, 0);

      tree := T23Tree.CreateCopyWithoutItems(self);

      if (FSize <> 0) or not FValidSize then
      begin
         _mcp_compare_assign(aitem, LowestItem, i);
         if i < 0 then
         begin
            tree.FRoot := FRoot;
            tree.LowestItem := LowestItem;
            tree.FSize := FSize;
            tree.FValidSize := FValidSize;
            tree.FHeight := FHeight;
            FRoot := nil;
            LowestItem := DefaultItem;
            FSize := 0;
            FValidSize := true;
            FHeight := 0;
         end else
         begin
            { descend down the tree along the path to the _last_ item
              equal to aitem adding nodes on the left to the left forest
              (lforest) and nodes on the right to rforest }
            firstlow := LowestItem;
            node := FRoot;
            depth := 1;
            while node <> nil do
            begin
               dnode := node;
               _mcp_compare_assign(aitem, node^.LowItem[2], i);
               if i < 0 then
               begin
                  if node^.StoredItems = 2 then
                  begin
                     ArrayPushBack(rforest1, node^.Child[3]);
                     ArrayPushBack(rforest2, node^.LowItem[3]);
                     ArrayPushBack(rforest3, depth);
                  end;
                  ArrayPushBack(rforest1, node^.Child[2]);
                  ArrayPushBack(rforest2, node^.LowItem[2]);
                  ArrayPushBack(rforest3, depth);

                  node := node^.Child[1];
               end else { i >= 0 }
               begin
                  ArrayPushBack(lforest1, node^.Child[1]);
                  ArrayPushBack(lforest2, firstlow);
                  ArrayPushBack(lforest3, depth);
                  firstlow := node^.LowItem[2];
                  node := node^.Child[2];
               end; { end if }

               Inc(depth);

               DisposeNode(dnode);

            end; { end while }

            { now firstlow <= aitem and every node with items > aitem is
              placed in the right forest (rforest) and every node with
              items <= aitem is placed in the left forest (lforest) ->
              just join the nodes in each forest into one tree }

            height := FHeight; { the original height of the whole tree }

            { join the nodes with items <= aitem into one tree  }
            LowestItem := firstlow;
            FRoot := nil;
            FHeight := 0;
            FValidSize := false;

            while lforest1^.Size <> 0 do
            begin
               Assert(lforest1^.Size = lforest2^.Size);
               Assert(lforest2^.Size = lforest3^.Size);

               node := P23TreeNode(ArrayPopBack(lforest1));
               itemlow := ArrayPopBack(lforest2);
               depth := ArrayPopBack(lforest3);
               Implant(node, FRoot, itemlow, LowestItem,
                       height - depth, FHeight);
            end;

            { join the nodes with items > aitem into one tree }
            if rforest1^.Size <> 0 then
            begin
               Assert(rforest1^.Size = rforest2^.Size);
               Assert(rforest2^.Size = rforest3^.Size);

               with tree do
               begin
                  FRoot := P23TreeNode(ArrayPopBack(rforest1));
                  LowestItem := ArrayPopBack(rforest2);
                  FHeight := height - ArrayPopBack(rforest3);

                  if FRoot <> nil then
                     FRoot^.Parent := nil;
                  FValidSize := false;

                  while rforest1^.Size <> 0 do
                  begin
                     node := P23TreeNode(ArrayPopBack(rforest1));
                     itemlow := ArrayPopBack(rforest2);
                     depth := ArrayPopBack(rforest3);

                     Implant(FRoot, node, LowestItem, itemlow,
                             FHeight, height - depth);
                  end;
               end;
            end else
            begin
               with tree do
               begin
                  LowestItem := DefaultItem;
                  FRoot := nil;
                  FSize := 0;
                  FHeight := 0;
                  FValidSize := true;
               end;
            end;
         end;
      end;

      Result := tree;

   finally
      ArrayDeallocate(lforest1);
      ArrayDeallocate(lforest2);
      ArrayDeallocate(lforest3);
      ArrayDeallocate(rforest1);
      ArrayDeallocate(rforest2);
      ArrayDeallocate(rforest3);
   end;
end;

procedure T23Tree.Clear;
var
   aitem : ItemType;
begin
   DeleteSubTree(FRoot);
   aitem := LowestItem;
   DisposeItem(aitem);
   LowestItem := DefaultItem;
   FRoot := nil;
   FValidSize := true;
   FSize := 0;
   FHeight := 0;
   GrabageCollector.FreeObjects;
end;

function T23Tree.Empty : Boolean;
begin
   Result := (FSize = 0) and FValidSize;
end;

function T23Tree.Size : SizeType;
begin
   if not FValidSize then
   begin
      FSize := SubTreeSize(FRoot) + 1;
      FValidSize := true;
   end;
   Result := FSize;
end;

{ -------------------------- T23TreeIterator --------------------------------- }

constructor T23TreeIterator.Create(anode : P23TreeNode; low : Integer;
                                   tree : T23Tree);
begin
   inherited Create(tree);
   FTree := tree;
   FLow := low;
   FNode := anode;
end;

procedure T23TreeIterator.GoToStartNode;
begin
   FNode := LeftMostLeafNode(FTree.FRoot);
   if FNode <> nil then
      FLow := 2
   else
      FLow := 0;
end;

function T23TreeIterator.CopySelf : TIterator;
begin
   Result := T23TreeIterator.Create(FNode, FLow, FTree);
end;

function T23TreeIterator.Equal(const Pos : TIterator) : Boolean;
begin
   Assert(pos is T23TreeIterator, msgInvalidIterator);

   Result := (FNode = T23TreeIterator(pos).FNode) and
      (FLow = T23TreeIterator(pos).FLow);
end;

function T23TreeIterator.GetItem : ItemType;
begin
   Assert((FNode <> nil) or (FLow = 1), msgInvalidIterator);

   if FLow <> 1 then
      Result := FNode^.LowItem[FLow]
   else
      Result := FTree.LowestItem;
end;

procedure T23TreeIterator.SetItem(aitem : ItemType);
var
   oldItem : ItemType;
begin
   Assert((FNode <> nil) or (FLow = 1), msgInvalidIterator);

   if FLow <> 1 then
   begin
      oldItem := FNode^.LowItem[FLow];
      FNode^.LowItem[FLow] := aitem;
   end else
   begin
      oldItem := FTree.LowestItem;
      FTree.LowestItem := aitem;
   end;

   with FTree do
   begin
      if _mcp_equal(oldItem, aitem) then
      begin
         DisposeItem(oldItem);
      end else
      begin
         DisposeItem(oldItem);
         ResetItem; // may raise
      end;
   end;
end;

procedure T23TreeIterator.ResetItem;
var
   aitem : ItemType;
begin
   aitem := FTree.DeleteNode(FNode, FLow);
   FTree.DoInsert(aitem, FTree.FRoot, FNode, FLow);
end;

procedure T23TreeIterator.Advance;
begin
   FTree.AdvanceNode(FNode, FLow);
end;

procedure T23TreeIterator.Retreat;
begin
   FTree.RetreatNode(FNode, FLow)
end;

procedure T23TreeIterator.Insert(aitem : ItemType);
begin
   FTree.DoInsert(aitem, FTree.FRoot, FNode, FLow);
end;

function T23TreeIterator.Extract : ItemType;
var
   aitem : ItemType;
   nextNode : P23TreeNode;
   nextLow : Integer;
   shouldSearch : Boolean;
begin
   Assert(not IsFinish, msgDeletingInvalidIterator);

   nextNode := FNode;
   nextLow := FLow;
   FTree.AdvanceNode(nextNode, nextLow);
   if nextNode <> nil then
   begin
      shouldSearch := true;
      aitem := nextNode^.LowItem[nextLow]
   end else
      shouldSearch := false;

   { keep in mind that the tree is reorganised in this function, so we
     have to find aitem in the the tree again }
   Result := FTree.DeleteNode(FNode, FLow);

   if shouldSearch then
   begin
      FTree.LowerBoundNode(aitem, FTree.FRoot, FNode, FLow);
      while (FNode <> nil) and (FNode^.LowItem[FLow] <> aitem) do
         FTree.AdvanceNode(FNode, FLow);
   end else
   begin
      FNode := nil;
      FLow := 0;
   end;

   { note: this function is not 100% correct with repeated items (some
     may be visited more than once); but how to fix it?  }
end;

function T23TreeIterator.Owner : TContainerAdt;
begin
   Result := FTree;
end;

function T23TreeIterator.IsStart : Boolean;
begin
   Result := (FNode = nil) and ((FLow = 1) or
                                   ((FLow = 0) and
                                       (FTree.FSize = 0) and FTree.FValidSize));
end;

function T23TreeIterator.IsFinish : Boolean;
begin
   Result := (FNode = nil) and (FLow = 0);
end;
