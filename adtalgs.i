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
 adtalgs.i::prefix=&_mcp_prefix&::item_type=&ItemType&
 }

&include adtalgs.defs

&define TForwardIteratorPair T&_mcp_prefix&ForwardIteratorPair


{ ======================= concrete iterators =============================== }
type
   { inserts items into a sequence before a given forward iterator }
   TInserter = class (TOutputIterator)
   private
      FPos : TForwardIterator;
      { See the implementation of the Owner method. }
      FOwner : TContainerAdt;
   public
      { apos is the iterator before which the items should be
        inserted; it may be a finish iterator, but to insert items at
        the back of a container it is better to use the default
        implementation of Write in TForwardIterator; @See
        TForwardIterator; }
      constructor Create(apos : TForwardIterator);
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      procedure Write(aitem : ItemType); override;
      function GetItem : ItemType; override;
      procedure SetItem(aitem : ItemType); override;
      procedure ExchangeItem(iter : TIterator); override;
      function Owner : TContainerAdt; override;
      { returns the position before which items are inserted }
      property Pos : TForwardIterator read FPos;
   end;
   
   { a base class for inserter iterators; implements the methods
     common to all inserters }
   TInserterBase = class (TOutputIterator)
   public
      { raises an exception }
      function GetItem : ItemType; override;
      { raises an exception }
      procedure SetItem(aitem : ItemType); override;
      { raises an exception }
      procedure ExchangeItem(iter : TIterator); override;
   end;

   { an output iterator writing into a container using the general
     InsertItem method; @See TBackInserter, TFrontInserter, TInserter
     }
   TBasicInserter = class (TInserterBase)
   private
      FCont : TContainerAdt;
   public
      { cont becomes the owner of the iterator; uses it to insert
        items }
      constructor Create(cont : TContainerAdt);
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      procedure Write(aitem : ItemType); override;
      function Owner : TContainerAdt; override;
   end;
   
   { an output iterator inserting at the back of a queue; @see
     TFrontInserter, TInserter }
   TBackInserter = class (TInserterBase)
   private
      FCont : TQueueAdt;
   public
      { cont becomes the owner of the iterator; uses it to insert
        items }
      constructor Create(cont : TQueueAdt);
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      procedure Write(aitem : ItemType); override;
      function Owner : TContainerAdt; override;
   end;
   
   { an output iterator inserting at the front of a deque }
   TFrontInserter = class (TInserterBase)
   private
      FCont : TDequeAdt;
   public
      { cont becomes the owner of the iterator; uses it to insert
        items }
      constructor Create(cont : TDequeAdt);
      function CopySelf : TIterator; override;
      function Equal(const Pos : TIterator) : Boolean; override;
      procedure Write(aitem : ItemType); override;
      function Owner : TContainerAdt; override;
   end;

{ ======================= non-modifying algorithms ============================ }
{ non-modifying algorithms do not change anything in the ranges they
  are applied to; they can be used with defined-order containers }

{ ------------------------- searching ------------------------------------ }

{ returns the first position p from the start of [start,finish) for
  which p.Item = aitem, according to comparer (linear search);
  @complexity worst-case O(n) }
function Find(const start, finish : TForwardIterator;
              aitem : ItemType;
              const comparer : IBinaryComparer = nil) : TForwardIterator; overload;
{ the same as above, but uses pred to test which item to return }
function Find(const start, finish : TForwardIterator;
              const pred : IUnaryPredicate) : TForwardIterator; overload;

{ ----------------------- other non-modifying ------------------------------- }

{ returns the number of items satisfying the predicate pred;
  @complexity O(n); }
function Count(const start, finish : TForwardIterator;
               const pred : IUnaryPredicate) : SizeType; overload;
{ returns an iterator pointing to the first minimal item in the range
  [start,finish); @complexity O(n) }
function Minimal(const start, finish : TForwardIterator;
                 const comparer : IBinaryComparer = nil) : TForwardIterator; overload;
{ returns an iterator pointing to the first maximal item in the range
  [start,finish); @complexity O(n); }
function Maximal(const start, finish : TForwardIterator;
                 const comparer : IBinaryComparer = nil) : TForwardIterator; overload;
{ returns true if two ranges are item-to-item equal; @complexity O(n);
  }
function Equal(const start1, finish1, start2 : TForwardIterator;
               const pred : IBinaryPredicate) : Boolean; overload;
{ returns the first pair of iterators such that Result.First is an
  iterator into the first range, Result.Second into the second, and
  First <> Second; if no such pair exists then Result.First = finish1;
  @complexity O(n); }
function Mismatch(const start1, finish1, start2 : TForwardIterator;
                  const pred : IBinaryPredicate) : TForwardIteratorPair; overload;
{ compares two ranges lexicographically; returns Result < 0 if range1
  < range2, Result > 0 if range1 > range2, and Result = 0 if range1 =
  range2; @complexity O(n) }
function LexicographicalCompare(const start1, finish1,
                                start2, finish2 : TForwardIterator;
                                const comparer : IBinaryComparer = nil) : Integer; overload;


{ ======================= modifying algorithms ============================ }
{ modifying algorithms may modify items of a given range but not their
  order within the range, i.e. they do not remove any items; they may
  either assign the items in the range or copy the changed items to
  some other range; the iterators designating the source range are
  never chaged; the items in the source rnage are not changed if the
  iterators are indicated const; the iterators designating the
  destination range are changed, but still remain either valid or
  finish; most of these algorithms cannot be used with defined-order
  containers, except for those which take const iterators, those which
  are indicated to accept defined-order ranges, or others under
  special circumstances (i.e. that the key is not modified) }

{ applies funct to every item from [start,finish); after applying the
  functor, the return value of the functor is re-assigned to where the
  item had originally been, but the item at that place is _never_
  disposed; this is suitable if you modify or just test the item in
  the functor and then return it; this may, however, make some items
  leak if you return a completely new item and do not dispose the old
  one in the functor; be careful with this! If you want to generate
  new items basing on the value of the old ones and do not care for
  the old ones, then you may use the Generate algorithm; The ForEach
  algorithm may be modifying or non-modifying depending on whether the
  functor changes the items; @complexity O(n); @see Generate, Combine, Copy }
procedure ForEach(start, finish : TForwardIterator;
                  const funct : IUnaryFunctor); overload;
{ generates new items basing on the value of the old ones using funct,
  and assignes them in the place of the old ones; the old items are
  all disposed! @complexity O(n); @see ForEach, Combine }
procedure Generate(start, finish : TForwardIterator;
                   const funct : IUnaryFunctor); overload;
{ copies items from [start1,finish1) to [start2,...) using itemCopier;
  the end of the second range is not given, but it must contain at
  least the same number of items as the first one; the items in the
  second range are disposed; @complexity O(n); @see Move }
procedure Copy(const start1, finish1 : TForwardIterator;
               start2 : TOutputIterator;
               const itemCopier : IUnaryFunctor); overload;
{ moves items from [start1,finish1) to before start2; in other words,
  inserts items from [start1,finish1) before start2, by calling
  start2.Insert; the range [start1,finish1) is left empty; @complexity
  O(n); @see Copy }
procedure Move(start1, finish1, start2 : TForwardIterator); overload;
{ 'combines' items from two ranges using <itemJoiner> and writes them
  to the third range; the number of valid position after start2 must
  be the same as between start1 and start2; itemJoiner should return a
  new item created basing on the data of its two arguments;
  @complexity O(n); @see Copy, ForEach, Generate }
procedure Combine(const start1, finish1, start2 : TForwardIterator;
                  start3 : TOutputIterator; const itemJoiner : IBinaryFunctor); overload;

{ ===================== mutating algorithms ======================== }
{ mutating algorithms do not change the values of the items, but
  change their relative order; they cannot be used with defined-order
  containers (an exception will be raised) }

{ ------------------------ sorting ---------------------------- }

{ a general sort algorithm; chooses the most suitable sorting
  algorithm for a given set of data (depending on its size);
  @complexity average O(n*log(n)) }
procedure Sort(start, finish : TRandomAccessIterator;
               const comparer : IBinaryComparer); overload;
{ a general stable sort algorithm; chooses the most suitable stable
  sorting algorithm for given data; @complexity O(n*log(n)) }
procedure StableSort(start, finish : TRandomAccessIterator;
                     const comparer : IBinaryComparer); overload;
{ implements the Quick-Sort algorithm; @stable
  no; @complexity average O(n*log(n)), worst-case O(n^2);
  @memory-usage O(log(n)) }
procedure QuickSort(start, finish : TRandomAccessIterator;
                    const comparer : IBinaryComparer); overload;
{ implements the Merge-Sort algorithm; @stable yes; @complexity
  O(n*log(n)); @memory-usage O(n); }
procedure MergeSort(start, finish : TRandomAccessIterator;
                    const comparer : IBinaryComparer); overload;
{ implements the Shell-Sort algorithm; @stable no; @complexity
  worst-case O(n^1.5) }
procedure ShellSort(start, finish : TRandomAccessIterator;
                    const comparer : IBinaryComparer); overload;
{ implements the Insertion-Sort algorithm; @stable yes; @complexity
  worst-case O(n^2) }
procedure InsertionSort(start, finish : TBidirectionalIterator;
                        const comparer : IBinaryComparer); overload;
procedure InsertionSort(start, finish : TRandomAccessIterator;
                        const comparer : IBinaryComparer); overload;

{ ------------------- other mutating algorithms -------------------------- }

{ rotates the items in the range [start,finish) circularly so that the
  item from <start> goes to newstart, start+1 to newstart+1, etc;
  newstart must be inside the range [start,finish); @complexity O(n) }
procedure Rotate(start, newstart, finish : TForwardIterator); overload;
{ reverses the order of the items in the range [start,finish);
  @complexity O(n); }
procedure Reverse(start, finish : TBidirectionalIterator); overload;
{ moves the items around randomly, so that it is euqiprobable that any
  of the items will be at a given position; @complexity O(n); }
procedure RandomShuffle(start, finish : TRandomAccessIterator); overload;
{ partitions [start,finish) according to pred; returns an iterator
  iter such that for each i in [start,iter) pred.Test(i.Item) is true,
  for each i in [iter, finish) pred.Test(i.Item) is false; @complexity
  O(n) }
function Partition(start, finish : TBidirectionalIterator; 
                   const pred : IUnaryPredicate) :
   TBidirectionalIterator; overload;
function Partition(start, finish : TRandomAccessIterator; 
                   const pred : IUnaryPredicate) :
   TRandomAccessIterator; overload;
{ the same as the ordinary Partition, but stable; i.e. does not change
  the relative order of the elements for which the predicate returns
  the same value; if you don't like the O(n) memory usage use the
  MemoryEfficientStableSort algorithm instead; @complexity O(n);
  @memory-usage O(n) }
function StablePartition(start, finish : TForwardIterator;
                         const pred : IUnaryPredicate) : TForwardIterator; overload;
{ the smae as StablePartition, but better memory usage, though worse
  running time; @complexity O(n*log(n)); @memory-usage O(1) }
function MemoryEfficientStablePartition(start, finish : TForwardIterator;
                                        const pred : IUnaryPredicate) :
   TForwardIterator; overload;
{ returns the k-th item in the range [start,finish) according to
  comparer; this is the same as if you sorted the range with the
  comparer and chose the item at start + k - 1; e.g. if comparer orders
  the items from the smallest to the greatest, then the function
  returns the k-th smallest item; if the range is empty returns
  nil; the algorithm used is the Blum-Floyd-Pratt-Rivest-Tarjan
  algorithm @complexity worst-case O(n); @memory-usage O(log(n)) }
function FindKthItem(start, finish : TRandomAccessIterator; k : SizeType;
                     const comparer : IBinaryComparer) : ItemType; overload;
{ implements the Hoare's algorithm for finding the k-th element;
  @complexity average O(n), worst-case O(n^2); }
function FindKthItemHoare(start, finish : TRandomAccessIterator; k : SizeType;
                          const comparer : IBinaryComparer) : ItemType; overload;

{ ======================= deleting algorithms ============================== }
{ deleting algorithms do not modify any items or their order, but may
  remove some from the container; since each call of member method
  Delete may invalidate al iterators except for the iterator on which
  the method is called, these routines do not accept ranges but a
  start iterator and the number of items instead. }

{ deletes at most n items starting from start (included); stops if the
  end of the container is reached; returns the number of items
  actually deleted; to delete a range use the member method Delete;
  @complexity O(n) }
function Delete(start : TForwardIterator; n : SizeType) : SizeType; overload;
{ deletes all items in the range [start,start+n) for which pred
  returns true }
function DeleteIf(start : TForwardIterator; n : SizeType;
                  const pred : IUnaryPredicate) : SizeType; overload;


{ ======================= sorted range algorithms ============================ }
{ these algorithms may be used only with sorted ranges; using them with
  defined-order containers either does not make sense or may be fatal
  in consequences }

{ ---------------------- non-modifying sorted range -------------------------- }

{ performs a binary search; the range should be sorted according to
  comparer; @complexity worst-case O(log(n)) }
function BinaryFind(const start, finish : TRandomAccessIterator; aitem : ItemType;
                    const comparer : IBinaryComparer) : TRandomAccessIterator; overload;
{ performs an interpolation search; the range should be sorted
  according to diff; @complexity average O(loglog(n)) worst-case O(n); }
function InterpolationFind(const start, finish : TRandomAccessIterator;
                           aitem : ItemType;
                           const diff : ISubtractor) : TRandomAccessIterator; overload;

{ ----------------------- deleting sorted range ----------------------------- }

{ deletes duplicated items from the range [start,start+n); if the end
  of the container is reached earlier then stops; to delete duplicates
  from a range call Unique(start,Distance(start,finish)); to delete
  all the items in the container after start inclusive, call
  Unique(start,-1); this might be implementation-dependent, however,
  since it will work only if SizeType(-1) is the larges unsigned value
  in SizeType; this algorithm may also be used with a TSetIterator;
  the requirement is that all equal items must come one after another
  in one consecutive sequence, but the whole range need not
  necessarily be sorted; @returns the number of duplicates deleted;
  @complexity O(n) }
function Unique(start : TForwardIterator; n : SizeType;
                const comparer : IBinaryComparer) : SizeType; overload;

{ ------------------------ mutating sorted range ----------------------------- }

{ merges two sorted ranges: [start1, finish1) and [start2, finish2);
  the resulting range is moved to output; items are removed from both
  source ranges (they become empty after executing this routine);
  @complexity O(n + m) }
procedure Merge(start1, finish1, start2, finish2 : TForwardIterator;
                output : TOutputIterator;
                const comparer : IBinaryComparer); overload;
{ the same as above, but copies the items and leaves the two source
  ranges intact; }
procedure MergeCopy(const start1, finish1, start2, finish2 : TForwardIterator;
                    output : TOutputIterator; const comparer : IBinaryComparer;
                    const itemCopier : IUnaryFunctor); overload;

{ =========================== set algorithms =============================== }
{ set algorithms operate on whole containers, which are sets; if a
  routine takes several sets as arguments then all of them should
  store the same kind of items and use the same disposers, comparers
  and hashers. Otherwise the behaviour is undefined. }

{ returns the union of <set1> and <set2>; <set1> and <set2> are left
  empty; the result is the same type as <set1>, it is obtained by
  calling set1.CopySelf(nil); Result.RepeatedItems is set to true and
  Result contains items from both sets, so we may basically say that
  each item is duplicated; to have a unique union of sets call the
  unique function on the resulting container; @complexity O(n); }
function SetUnion(set1, set2 : TSetAdt) : TSetAdt; overload;
{ the same as above, but copies the items and does not modify the
  containers; Result.RepeatedItems is set to true and Result contains
  items from both sets, so we may basically say that each item is
  duplicated; to have a unique union of sets call the unique function
  on the resulting container; @complexity O(n); }
function SetUnionCopy(const set1, set2 : TSetAdt;
                      const itemCopier : IUnaryFunctor) : TSetAdt; overload;
{ the same as above but does not create a new set but copies the items
  to set1 instead. }
function SetUnionCopyToArg(set1 : TSetAdt; const set2 : TSetAdt;
                           const itemCopier : IUnaryFunctor) : IUnaryFunctor; overload;

{ returns the intersection of <set1> and <set2>; after this operation
  <set1> = <set1> \ <set2> and <set2> = <set2> \ <set1>; to get a
  symmetric difference of two sets simply call this function on them
  and then pass the modified arguments to @<SetUnion>. the result is
  the same type as <set1>, it is obtained by calling
  set1.CopySelf(nil); Result.RepeatedItems is set to true and Result
  contains items from both sets, so we may basically say that each
  item is duplicated; to have a unique intersection of sets call the
  Unique function on the resulting container; @complexity O(n); }
function SetIntersection(set1, set2 : TSetAdt) : TSetAdt; overload;

{ returns the intersection of <set1> and <set2>; copies the items and
  leaves its arguments intact; the result is the same type as <set1>,
  it is obtained by calling set1.CopySelf(nil); Result.RepeatedItems
  is set to true and Result contains items from both sets, so we may
  basically say that each item is duplicated; to have a unique
  intersection of sets call the unique function on the resulting
  container; @complexity O(n); }
function SetIntersectionCopy(const set1, set2 : TSetAdt;
                             const itemCopier : IUnaryFunctor) : TSetAdt; overload;
{ returns <set1> \ <set2>; copies the items and leaves its arguments
  intact; the result is the same type as <set1>, it is obtained by
  calling set1.CopySelf(nil); if <set1> contains duplicated items then
  the result also might contain duplicated items; @complexity O(n);; }
function SetDifferenceCopy(const set1, set2 : TSetAdt;
                           const itemCopier : IUnaryFunctor) : TSetAdt; overload;
{ returns the symmetric difference of <set1> and <set2>; copies the
  items and leaves its arguments intact; the result is the same type
  as <set1>, it is obtained by calling set1.CopySelf(nil); if any of
  the sets contains duplicated items then the result also might
  contain duplicated items; @complexity O(n); }
function SetSymmetricDifferenceCopy(const set1, set2 : TSetAdt;
                                    const itemCopier : IUnaryFunctor) : TSetAdt; overload;
