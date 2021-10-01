unit testtree;

interface

uses
   tester, testcont, adtcontbase;

type
   TTreeTester = class (TBasicTreeTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;

implementation

uses
   testutils, testiters, adtiters, adttree;

var
   tree, tree2 : TTree;
   iter1, iter2 : TTreeIterator;
   piter : TPreOrderIterator;
   obj : TTestObject;
   i : IndexType;
   n : SizeType;
   liter : TLevelOrderIterator;
   copier : TTestObjectCopier;

procedure InsertPreOrder(iter : TTreeIterator; level : SizeType);
begin
   if level <> 0 then
   begin
      iter.InsertAsLeftMostChild(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsLeftMostChild',
           'inserts at wrong position');
      Inc(i);

      InsertPreOrder(CopyOf(iter), level - 1);

      iter.InsertAsRightSibling(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsRightSibling',
           'inserts at wrong position');
      Inc(i);

      InsertPreOrder(CopyOf(iter), level - 1);

      iter.InsertAsRightSibling(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsRightSibling',
           'inserts at wrong position');
      Inc(i);

      InsertPreOrder(CopyOf(iter), level - 1);
   end;
   iter.Destroy;
end;

procedure InsertPostOrder(iter : TTreeIterator; level : SizeType);
var
   iter2 : TTreeIterator;
begin
   if level <> 0 then
   begin
      iter.InsertAsLeftMostChild(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsLeftMostChild',
           'inserts at wrong position');
      iter2 := CopyOf(iter);

      iter.InsertAsRightSibling(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsRightSibling',
           'inserts at wrong position');

      iter.InsertAsRightSibling(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsRightSibling',
           'inserts at wrong position');
      Dec(i);

      InsertPostOrder(iter, level - 1);
      iter := CopyOf(iter2);
      iter.GoToRightSibling;

      obj := TTestObject.Create(i);
      Dec(i);
      StartDestruction(1, 'SetItem');
      iter.SetItem(obj);
      FinishDestruction;

      InsertPostOrder(iter, level - 1);

      iter := iter2;
      obj := TTestObject.Create(i);
      Dec(i);
      StartDestruction(1, 'SetItem');
      iter.SetItem(obj);
      FinishDestruction;

      InsertPostOrder(CopyOf(iter), level - 1);
   end;
   iter.Destroy;
end;

procedure InsertInOrder(iter : TTreeIterator; level : SizeType);
begin
   if level <> 0 then
   begin
      iter.InsertAsLeftMostChild(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsLeftMostChild',
           'inserts at wrong position');

      if level <> 1 then
         InsertInOrder(CopyOf(iter), level - 1)
      else
         Inc(i);

      iter.GoToParent;

      obj := TTestObject.Create(i);
      Inc(i);
      StartDestruction(1, iterName + '.SetItem');
      iter.SetItem(obj);
      FinishDestruction;

      iter.GoToLeftMostChild;

      iter.InsertAsRightSibling(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsRightSibling',
           'inserts at wrong position');

      if level <> 1 then
         InsertInOrder(CopyOf(iter), level - 1)
      else
         Inc(i);

      iter.InsertAsRightSibling(TTestObject.Create(i));
      Test(TTestObject(iter.Item).Value = i, 'InsertAsRightSibling',
           'inserts at wrong position');

      if level <> 1 then
         InsertInOrder(CopyOf(iter), level - 1)
      else
         Inc(i);
   end;
   iter.Destroy;
end;

{ =================== main prog ===================== }

procedure TTreeTester.TestContainer(cont : TContainerAdt);
begin
   inherited;

   Assert(cont is TTree);
   tree := TTree(cont);

   testutils.Test(not tree.IsDefinedOrder, 'IsDefinedOrder', 'returns true');

   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;

   { ------------------ InsertPreOrder ------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));

   n := 88573;
   i := 1;
   StartSilentMode;
   InsertPreOrder(tree.Root, 10); { height is 10 }
   StopSilentMode;
   testutils.Test(tree.Size = n,
        'InsertAsLeftMostChild & InsertAsRightSibling (InsertPreOrder)',
        'wrong size');

   { ---------------------- Height (non-member) ---------------------- }
   testutils.Test(Height(tree.Root) = 10, 'Height (non-member)');

   { ---------------------- LeftMostLeaf (non-member) ---------------------- }
   iter1 := LeftMostLeaf(tree.Root);
   testutils.Test(TTestObject(iter1.Item).Value = 10, 'LeftMostLeaf (non-member)',
        'wrong item');
   testutils.Test(iter1.IsLeaf, 'LeftMostLeaf', 'not a leaf !!!');

   { ---------------------- Depth (non-member) ---------------------- }
   testutils.Test(Depth(iter1) = 10, 'Depth (non-member)');

   { ---------------------- RightMostLeaf (non-member) ---------------------- }
   iter1 := RightMostLeaf(tree.Root);
   testutils.Test(TTestObject(iter1.Item).Value = n - 1, 'RightMostLeaf', 'wrong item');
   testutils.Test(iter1.IsLeaf, 'RightMostLeaf', 'not a leaf !!!');

   { ---------------------- Depth (non-member) ---------------------- }
   testutils.Test(Depth(iter1) = 10, 'Depth (non-member)');

   { ---------------------- test PreOrderIterator ---------------------- }
   TestTraversalIterator(tree.PreOrderIterator, 'TTreePreOrderIterator');

   { ------------------ Clear ------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Empty, 'Clear', 'not empty');


   { ------------------ InsertPostOrder ------------------------- }
   tree.InsertAsRoot(TTestObject.Create(n - 1));

   n := 88573;
   i := n - 2;
   StartSilentMode;
   InsertPostOrder(tree.Root, 10); { height is 10 }
   StopSilentMode;
   testutils.Test(tree.Size = n,
        'InsertAsLeftMostChild & InsertAsRightSibling (InsertPostOrder)',
        'wrong size');

   { ---------------------- test PostOrderIterator ---------------------- }
   TestTraversalIterator(tree.PostOrderIterator, 'TTreePostOrderIterator');

   { ------------------ Clear ------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Empty, 'Clear', 'not empty');


   { ------------------ InsertInOrder ------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));

   n := 88573;
   i := 0;
   StartSilentMode;
   InsertInOrder(tree.Root, 10); { height is 10 }
   StopSilentMode;
   testutils.Test(tree.Size = n,
        'InsertAsLeftMostChild & InsertAsRightSibling (InsertInOrder)',
        'wrong size');

   { ---------------------- test InOrderIterator ---------------------- }
   TestTraversalIterator(tree.InOrderIterator, 'TTreeInOrderIterator');

   { ------------------ Clear ------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Empty, 'Clear', 'not empty');


   { ------------------ InsertPreOrder ------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));

   n := 3280;
   i := 1;
   StartSilentMode;
   InsertPreOrder(tree.Root, 7); { height is 7 }
   StopSilentMode;
   testutils.Test(tree.Size = n,
        'InsertAsLeftMostChild & InsertAsRightSibling (InsertPreOrder)',
        'wrong size');

   { ----------------------- test LevelOrderIterator ------------------ }
   i := 0;
   liter := tree.LevelOrderIterator;
   while not liter.IsFinish do
   begin
      obj := TTestObject.Create(i);
      StartDestruction(1, IterName + '.SetItem');
      liter.SetItem(obj);
      FinishDestruction;
      liter.Advance;
      Inc(i);
   end;

   liter.StartTraversal;
   TestTraversalIterator(liter, 'TTreeLevelOrderIterator');

   { ------------------ Clear ------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Empty, 'Clear', 'not empty');


   { ------------------ InsertPreOrder ------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));

   n := 88573;
   i := 1;
   StartSilentMode;
   InsertPreOrder(tree.Root, 10); { height is 10 }
   StopSilentMode;
   testutils.Test(tree.Size = n,
        'InsertAsLeftMostChild & InsertAsRightSibling (InsertPreOrder)',
        'wrong size');

   { ------------------ MoveToRightSibling ------------------------- }
   iter1 := tree.Root;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;
   iter2 := CopyOf(iter1);
   iter2.GoToRightSibling;
   tree.MoveToRightSibling(iter2, iter1);
   testutils.Test(tree.Size = n, 'MoveToRightSibling', 'wrong size');
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'MoveToRightSibling',
        'wrong item at the root');

   piter := tree.PreOrderIterator;
   piter.Advance;
   iter1 := tree.Root;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;

   CheckRange(piter, iter1.PreOrderIterator, true, 1, (n - 1) div 3,
              'MoveToRightSibling (checking first sub-tree)');
   Advance(piter, (n - 1) div 3);
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true,
              ((n - 1) div 3) * 2 + 1, (n - 1) div 3,
              'MoveToRightSibling (second sub-tree)');
   Advance(piter, (n - 1) div 3);
   CheckRange(piter, tree.Finish.PreOrderIterator, true,
              (n - 1) div 3 + 1, (n - 1) div 3,
              'MoveToRightSibling (third sub-tree)');

   { ------------------ MoveToLeftMostChild ------------------------- }
   iter1 := tree.Root;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;
   tree.MoveToLeftMostChild(tree.Root, iter1);
   testutils.Test(tree.Size = n, 'MoveToLeftMostChild', 'wrong size');
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'MoveToLeftMostChild',
        'changes item at the root');

   piter := tree.PreOrderIterator;
   piter.Advance;
   iter1 := tree.Root;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;

   CheckRange(piter, iter1.PreOrderIterator, true,
              ((n - 1) div 3) * 2 + 1, (n - 1) div 3,
              'MoveToRightSibling (checking first sub-tree)');
   Advance(piter, (n - 1) div 3);
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true, 1, (n - 1) div 3,
              'MoveToRightSibling (second sub-tree)');
   Advance(piter, (n - 1) div 3);
   CheckRange(piter, tree.Finish.PreOrderIterator, true,
              (n - 1) div 3 + 1, (n - 1) div 3,
              'MoveToRightSibling (third sub-tree)');

   { ---------------------- DeleteSubTree ------------------------- }
   iter1 := tree.Root;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;
   iter1.DeleteSubTree;
   testutils.Test(tree.Size = n - ((n - 1) div 3), 'DeleteSubTree', 'wrong size');
   TestIter(iter1.IsRoot, 'DeleteSubTree',
            'does not go to parent after deletion');
   testutils.Test(TTestObject(iter1.Item).Value = 0, 'DeleteSubTree',
        'messes sth up with parent''s item');

   piter := tree.PreOrderIterator;
   piter.Advance;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;

   CheckRange(piter, iter1.PreOrderIterator, true,
              ((n - 1) div 3) * 2 + 1, (n - 1) div 3,
              'DeleteSubTree (checking first sub-tree)');
   Advance(piter, (n - 1) div 3);
   CheckRange(piter, tree.Finish.PreOrderIterator, true,
              (n - 1) div 3 + 1, (n - 1) div 3,
              'DeleteSubTree (second sub-tree)');

   { ------------------------------------------------------------- }
   { discard the old tree - will be destroyed by the inherited Test  }
   cont := CreateContainer;
   Assert(cont is TTree);
   tree := TTree(cont);

   { ------------------ InsertPreOrder ------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));

   n := 88573;
   i := 1;
   StartSilentMode;
   InsertPreOrder(tree.Root, 10); { height is 10 }
   StopSilentMode;
   testutils.Test(tree.Size = n,
        'InsertAsLeftMostChild & InsertAsRightSibling (InsertPreOrder)',
        'wrong size');

   { ------------------ CopySelf ------------------------- }
   copier := TTestObjectCopier.Create;
   tree2 := TTree(tree.CopySelf(copier));
   copier.Free;
   CheckRange(tree2.PreOrderIterator, tree2.Finish.PreOrderIterator,
              true, 0, n, 'CopySelf');

   { ----------------- MoveToRightSibling (different containers) ---------- }
   iter1 := tree.Root;
   iter1.GoToLeftMostChild;
   iter2 := tree2.Root;
   iter2.GoToLeftMostChild;
   tree.MoveToRightSibling(iter1, iter2);
   testutils.Test(tree.Size = ((n - 1) div 3) * 4 + 1, 'MoveToRightSibling',
        'wrong size in destination tree');
   testutils.Test(tree2.Size = ((n - 1) div 3) * 2 + 1, 'MoveToRightSibling',
        'wrong size in source tree');

   piter := tree.PreOrderIterator;
   piter.Advance;
   iter1 := tree.Root;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;

   CheckRange(piter, iter1.PreOrderIterator, true, 1, (n - 1) div 3,
              'MoveToRightSibling (first tree, first sub-tree)');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true, 1, (n - 1) div 3,
              'MoveToRightSibling (first tree, second sub-tree)');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true, (n - 1) div 3 + 1, (n - 1) div 3,
              'MoveToRightSibling (first tree, third sub-tree)');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true,
              ((n - 1) div 3) * 2 + 1, (n - 1) div 3,
              'MoveToRightSibling (first tree, fourth sub-tree)');

   piter := tree2.PreOrderIterator;
   piter.Advance;
   iter1 := tree2.Root;
   iter1.GoToLeftMostChild;
   iter1.GoToRightSibling;

   CheckRange(piter, iter1.PreOrderIterator, true,
              (n - 1) div 3 + 1, (n - 1) div 3,
              'MoveToRightSibling (second tree, first sub-tree)');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true,
              ((n - 1) div 3) * 2 + 1, (n - 1) div 3,
              'MoveToRightSibling (second tree, second sub-tree)');


   { ----------------- MoveToLeftMostChild (different containers) ---------- }
   tree.MoveToLeftMostChild(tree.Root, tree2.Root);
   testutils.Test(tree.Size = 2 * n, 'MoveToLeftMostChild (different containers)',
        'wrong size in destination tree');
   testutils.Test(tree2.Size = 0, 'MoveToLeftMostChild', 'wrong size in source tree');
   testutils.Test(tree2.Empty, 'MoveToLeftMostChild',
        'empty returns false for the source tree');
   testutils.Test(tree2.Root.PreOrderIterator.IsFinish, 'MoveToLeftMostChild',
        'root not removed (?)');

   piter := tree.PreOrderIterator;
   testutils.Test(TTestObject(piter.Item).Value = 0, 'MoveToLeftMostChild',
        'wrong item at root');
   piter.Advance;
   testutils.Test(TTestObject(piter.Item).Value = 0, 'MoveToLeftMostChild',
        'wrong item at left-most child');
   piter.Advance;
   iter1 := TTreeIterator(piter.TreeIterator);
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true, (n - 1) div 3 + 1, (n - 1) div 3,
              'MoveToLeftMostChild (different containers)');
   piter := iter1.PreOrderIterator;
   iter1.GoToParent;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true,
              ((n - 1) div 3) * 2 + 1, (n - 1) div 3, 'MoveToLeftMostChild');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true, 1, (n - 1) div 3,
              'MoveToLeftMostChild');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true, 1, (n - 1) div 3,
              'MoveToLeftMostChild');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true, (n - 1) div 3 + 1, (n - 1) div 3,
              'MoveToLeftMostChild');
   piter := iter1.PreOrderIterator;
   iter1.GoToRightSibling;
   CheckRange(piter, iter1.PreOrderIterator, true,
              ((n - 1) div 3) * 2 + 1, (n - 1) div 3,
              'MoveToLeftMostChild');

   { -------------------------- Destroy -------------------------- }
   StartDestruction(tree.Size, 'destructor');
   tree.Destroy;
   FinishDestruction;

   Write('destroying empty tree...');
   StartDestruction(tree2.Size, 'destructor');
   tree2.Destroy;
   FinishDestruction;
   WriteLn(' - passed');
end;

end.
