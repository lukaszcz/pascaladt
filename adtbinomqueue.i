{@discard
 
  This file is a part of the PascalAdt library, which provides
  commonly used algorithms and data structures for the FPC and Delphi
  compilers.
  
  Copyright (C) 2005 by Lukasz Czajka
  
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
 adtbinomqueue.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtbinomqueue.defs

&define TBinomialTreeNode T&_mcp_prefix&BinomialTreeNode
&define PBinomialTreeNode P&_mcp_prefix&BinomialTreeNode


type
   TBinomialTreeNode = TTreeNode;
   PBinomialTreeNode = PTreeNode;
   
   TBinomialForest = array of PBinomialTreeNode;
   
   TBinomialQueueIterator = class;
   
   { implements a binomial priority queue; a binomial priority queue
     is a data structure allowing to perform all concatenable priority
     queue operations in O(log(n)); in contrast to an ordinary heap,
     where the @<Merge> operation takes O(n) time, in a binomial queue
     it may be performed in O(log(n)) time; on the other hand, the
     @<First> operation takes O(log(n)) time instead of O(1) like in
     an ordinary heap; however, you amy always pre-fetch and cache the
     item if you find it necessary; }
   TBinomialQueue = class (TPriorityQueueAdt)
   private
      { an array of roots of binomial trees }
      FTrees : TBinomialForest;
      FSize : SizeType;
      
      { returns the index of the item with the highest priority }
      function FirstIndex : IndexType;
      { destroys the tree of <node>; disposeItems indicates whether to
        dispose items; handles the FSize field }
      procedure DestroyTree(node : PBinomialTreeNode; disposeItems : Boolean);
      { connects <node> as the left-most child of <parent>; <node>
        must be the root of a tree; }
      procedure ConnectAsLeftmostChild(parent, node : PBinomialTreeNode);
      { checks whether FTrees may store <additionalSize> more items;
        if not grows FTrees; }
      procedure CheckTreesLength(additionalSize : SizeType);
      { merges two nodes into one tree; returns the root of the new
        tree }
      function MergeNodes(node1, node2 : PBinomialTreeNode) : PBinomialTreeNode;
      { merges <forest> with self; this mehtod does not handle the
        FSize field and expects CheckTreesLength to have been called
        earlier }
      procedure MergeForest(forest : TBinomialForest);
      { inserts <node> into the queue; <node> must be a single node -
        it can have neither a parent nor children; returns the index
        of the tree in which <node> is finally placed }
      function InsertNode(node : PBinomialTreeNode) : IndexType;
      { removes the node at FTrees[index]; retruns the item of that
        node (which is therefore not disposed) }
      function DeleteNode(index : IndexType) : ItemType;
      { creates a new node and assigns nil to all of its fields,
        except for the Item field, to which <ptr> is assigned }
      procedure NewNode(var node : PBinomialTreeNode; aitem : ItemType);
      procedure DisposeNode(node : PBinomialTreeNode);
   public
      constructor Create; overload;
      constructor CreateCopy(const cont : TBinomialQueue;
                             const itemCopier : IUnaryFunctor); overload;
      destructor Destroy; override;
      { returns the start iterator into the binomial queue }
      function Start : TBinomialQueueIterator;
      { returns the finish iterator }
      function Finish : TBinomialQueueIterator;
      function CopySelf(const ItemCopier :
                           IUnaryFunctor) : TContainerAdt; override;
      { @see TContainerAdt.Swap }
      procedure Swap(cont : TContainerAdt); override;
      { @fetch-related }
      { @complexity O(log(n)); }
      procedure Insert(aitem : ItemType); override;
      { @fetch-related }
      { @complexity O(log(n)); }
      function First : ItemType; override;
      { removes the item with the highest priority, i.e. the one that
        comes first in a chain of comparisons, e.g. if you use
        integers as items and < as comparison this would be actually
        the smallest integer in the queue. Returns the removed
        item. @complexity O(log(n)); @see DeleteFirst }
      function ExtractFirst : ItemType; override;
      { <aqueue> must be a TBinomialQueue; @complexity O(log(n)); @see
        TPriorityQueueAdt.Merge; }
      procedure Merge(aqueue : TPriorityQueueAdt); override;
      procedure Clear; override;
      function Empty : Boolean; override;
      function Size : SizeType; override;
   end;
   
   { an iterator into a binomial priority queue; since
     @<TBinomialQueue> is a defined-order container, some methods of
     this iterator work a bit different than usual; }
   { @see TDefinedOrderIterator, TDefinedOrderContainerAdt,
     TContainerAdt.IsDefinedOrder }
   TBinomialQueueIterator = class (TDefinedOrderIterator)
   private
      FNode : PBinomialTreeNode;
      FTreeIndex : IndexType;
      FCont : TBinomialQueue;
      
      { advances to the nearest item from FTrees[FTreeIndex] if FNode
        = nil; otherwise does nothing }
      procedure AdvanceToNearestItem;
      { retreats to the nearest item from FTrees[FTreeIndex] if FNode
        = nil; otherwise does nothing }
      procedure RetreatToNearestItem;
   public
      constructor Create(anode : PBinomialTreeNode; atreeindex : IndexType;
                         acont : TBinomialQueue);
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      { returns the item at the position of self; if you wish to
        change the returned item in a way that changes its item, then
        don't forget to call @<ResetItem>; }
      function GetItem : ItemType; override;
      { sets the item at the current position; calls @<ResetItem>
        after setting the item; @complexity worst-case O(log(n)^2), if
        the new item has higher priority than the old one then
        worst-case O(log(n)); }
      procedure SetItem(aitem : ItemType); override;
      { this should be called whenever any operation changes an item
        returned by @<GetItem> in such a way that its priority is
        changed; if you change the priority of an item returned by
        GetItem and not call this method, then the behaviour is
        undefined; moves the iterator so that it still points to the
        item, although the item changes its position; @complexity
        worst-case O(log(n)^2), if the new item has higher priority
        than the old one then worst-case O(log(n)); }
      procedure ResetItem; override;
      { raises EDefinedOrder }
      procedure ExchangeItem(iter : TIterator); override;
      procedure Advance; overload; override;
      procedure Retreat; override;
      { inserts <ptr> into the queue; makes <self> point to the newly
        inserted item; @complexity O(log(n)); }
      procedure Insert(aitem : ItemType); overload; override;
      { removes the item at the current position from the binomial
        queue and returns it; moves <self> to the _first_ item in the
        container; @complexity O(log(n)); }
      function Extract : ItemType; override;
      { @fetch-related }
      { @complexity worst-case O(log(n)) }
      function IsStart : Boolean; override;
      function IsFinish : Boolean; override;
      function Owner : TContainerAdt; override;
   end;

