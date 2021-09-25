(* This file is a part of the PascalAdt library, which provides
   commonly used algorithms and data structures for the FPC and Delphi
   compilers.
   
   Copyright (C) 2004, 2005 by Lukasz Czajka
   
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

unit adtmsg;

{ @profile none }

interface

const
   msgInternalError = 'PascalAdt: Internal PascalADT library error. My fault! Please report this bug to lukasz.czajka{[at]}students{[dot]}mimuw.edu.pl with a desription of what you did and the source code that caused the problem, if possible. Possible solution would be also very appretiated.';
   msgVersion = 'PascalADT library version 0.4. Copyright (C) by Dj Kosmos.';
   msgMoveNotUpdate = 'PascalAdt: Debug libtest failed: Move operation does not update internal count, although it can (instead of setting FValidcount to false).';
   msgMemoryLeak = 'PascalAdt: Memory leak detected in the standard TDefaultAllocator. Memory chunks leaked: ';

   { iterator error messages }
   msgInvalidIterator = 'PascalAdt: Invalid iterator passed to method.';
   msgInvalidRange = 'PascalAdt: Invalid iterator range: the start of the range is further than the finish.';
   msgDereferencingInvalidIterator = 'PascalAdt: Dereferencing invalid iterator.';
   msgReadingInvalidIterator = 'PascalAdt: Reading invalid iterator.';
   msgWritingInvalidIterator = 'PascalAdt: Writing invalid iterator.';
   msgAdvancingFinishIterator  =
   'PascalAdt: Advancing the finish iterator in the container.';
   msgRetreatingStartIterator =
   'PascalAdt: Retreating the start iterator in the container.';
   msgDeletingInvalidIterator = 'PascalAdt: Invalid iterator passed to Delete method.';
   msgMovingInvalidIterator = 'PascalAdt: Moving invalid iterator.';
   msgInvalidIteratorRange = 'PascalAdt: Iterators represent an invalid range.';
   msgWrongOwner = 'PascalAdt: Wrong owner - the owner of the iterator passed to the method is not the container on which the method has been called.';
   msgWrongRangeOwner = 'PascalAdt: Invalid iterator range - iterators representing the same range have different owners.';
   msgAdvancingInvalidIterator = 'PascalAdt: Advancing an invalid iterator.';
   msgMovingBadRange = 'PascalAdt: Move: The destination iterator points inside the range to move.';
   msgLeakedIterators = 'PascalAdt: Some iterators leaked. Probably you failed to destroy some container and iterators into this container were not destroyed.';
   msgFunctorsLeaked = 'PascalAdt: Some functors leaked. There is either a bug in the library or you screwed sth up. Functors leaked: ';

   { container errors }
   msgPopEmpty = 'PascalAdt: Cannot pop an empty container.';
   msgEmpty = 'PascalAdt: Container is empty.';
   msgReadEmpty = 'PascalAdt: Reading empty container.';
   msgInvalidIndex = 'PascalAdt: Invalid index.';
   msgInvalidDimensions = 'PascalAdt: Invalid number of dimensions.';
   msgNilArray = 'PascalAdt: nil passed to function that expected a valid TDynamicArray.';
   msgNilFunctor = 'PascalAdt: nil passed to function which expected a valid functor.';
   msgNilObject = 'PascalAdt: does not accept nil objects';
   msgInsertingRootSibling = 'PascalAdt: Trying to insert item into a tree as a sibling of the root (root cannot have siblings).';
   msgWrongContainerType = 'PascalAdt: Two containers were expected to be exactly the same type.';
   msgHasLeftChild			       = 'PascalAdt: TBinaryTree: Cannot move to the left child of node, because node already has a left child.';
   msgHasRightChild			       = 'PascalAdt: TBinaryTree: Cannot move to the right child of node, because node already has a right child.';
   msgReferenceCountNotZero		       = 'PascalAdt: TReferencedObject: Trying to call destroy on an object with non-zero reference count. You should probably call RemoveReference instead.';
   msgSetItemsNotEqual			       = 'PascalAdt: TSetIterator.SetItem: The new item is not equal to the old one.';
   msgInvalidNodeForSingleRightRotation	       = 'PascalAdt: TBinaryTree.RotateSingleRight: Single right rotation can be only performed on node that has a left child.';
   msgInvalidNodeForSingleLeftRotation	       = 'PascalAdt: TBinaryTree.RotateSingleLeft: Single left rotation can be only performed on node that has a right child.';      
   msgInvalidNodeForDoubleRightRotation	       = 'PascalAdt: TBinaryTree.RotateDoubleRight: Double right rotation can be only performed on node that has a left child which has a right child.';
   msgInvalidNodeForDoubleLeftRotation	       = 'PascalAdt: TBinaryTree.RotateDoubleLeft: Double left rotation can be only performed on node that has a right child which has a left child.';
   msgInvalidMapCopier			       = 'PascalAdt: TMapAdt.CopySelf: Copier passed to this method is not the one returned by CreateCopier.';
   msgItemsNotSmaller			       = 'PascalAdt: Concatenate: Not all items in one of the containers are smaller than or equal to items in the other.';
   msgContainerTooSmall			       = 'PascalAdt: Trying to make the size of the container less than its minimal allowed size.';
   msgWrongRehashArg			       = 'PascalAdt: Rehash: Trying to make the table too small.';
   msgWrongHash				       = 'PascalAdt: SetItem: The new item must hash to the same value as the old one.';
   msgChangedRepeatedItems		       = 'PascalAdt: TSetAdt: RepeatedItems changed when container was non-empty.';
   msgChangingRepeatedItemsInNonEmptyContainer =  'PascalAdt: TSetAdt: RepeatedItems should be changed only when the container is empty';
   
   { other msgs }
   msgInvalidArgument = 'PascalAdt: Invalid argument passed to a routine.';
   
   { exception messages }
   msgOutOfMemory = 'PascalAdt: Out of memory';
   msgNoArgCreate = 'Programming error: calling TContainerAdt.Create with no arguments';

implementation

end.
