unit testbintree;

interface

uses
   tester, testcont, adtcontbase, adtbintree;

type
   TBinaryTreeTester = class (TBasicTreeTester)
   protected
      procedure TestContainer(cont : TContainerAdt); override;
   end;

implementation

uses
   adtiters, testiters, testutils;   

var
   tree, tree2 : TBinaryTree;
   iter, iter2, iter3, child, t, lt, rt : TBinaryTreeIterator;
   piter, piter2 : TPreOrderIterator;
   liter : TLevelOrderIterator;
   obj : TTestObject;
   copier : TTestObjectCopier;
   i : IndexType;
   n : SizeType;
   lastsize : SizeType;
   

procedure InsertPreOrder(node : TBinaryTreeIterator; h : SizeType);
begin
   if h <> 0 then
   begin
      lastSize := tree.Size;
      node.InsertAsLeftChild(TTestObject.Create(i));
      Test(TTestObject(node.Item).Value = i, 'InsertAsLeftChild',
           'does not advance to newly inserted item');
      Test(tree.Size = lastSize + 1, 'InsertAsLeftChild', 'wrong size');
      Inc(i);
      
      InsertPreOrder(CopyOf(node), h - 1);
      
      node.GoToParent;
      
      lastSize := tree.Size;
      node.InsertAsRightChild(TTestObject.Create(i));
      Test(TTestObject(node.Item).Value = i, 'InsertAsRightChild',
           'does not advance to newly inserted item');
      Test(tree.Size = lastSize + 1, 'InsertAsRightChild', 'wrong size');
      Inc(i);
      
      InsertPreOrder(CopyOf(node), h - 1);
   end;
   node.Destroy;
end;

procedure InsertPostOrder(node : TBinaryTreeIterator; h : SizeType);
begin
   if h <> 0 then
   begin
      lastSize := tree.Size;
      node.InsertAsLeftChild(TTestObject.Create(i));
      Test(TTestObject(node.Item).Value = i, 'InsertAsLeftChild',
           'does not advance to newly inserted item');
      Test(tree.Size = lastSize + 1, 'InsertAsLeftChild', 'wrong size');
      
      InsertPostOrder(CopyOf(node), h - 1);
      
      obj := TTestObject.Create(i);
      StartDestruction(1, 'SetItem');
      node.SetItem(obj);
      FinishDestruction;
      Inc(i);
      
      node.GoToParent;
      
      lastSize := tree.Size;
      node.InsertAsRightChild(TTestObject.Create(i));
      Test(TTestObject(node.Item).Value = i, 'InsertAsRightChild',
           'does not advance to newly inserted item');
      Test(tree.Size = lastSize + 1, 'InsertAsRightChild', 'wrong size');
      
      InsertPostOrder(CopyOf(node), h - 1);
      
      obj := TTestObject.Create(i);
      StartDestruction(1, 'SetItem');
      node.Item := obj;
      FinishDestruction;
      Inc(i);      
   end;
   node.Destroy;
end;

procedure InsertInOrder(node : TBinaryTreeIterator; h : SizeType);
begin
   if h <> 0 then
   begin
      lastSize := tree.Size;
      node.InsertAsLeftChild(TTestObject.Create(i));
      Test(TTestObject(node.Item).Value = i, 'InsertAsLeftChild',
           'does not advance to newly inserted item');
      Test(tree.Size = lastSize + 1, 'InsertAsLeftChild', 'wrong size');
      
      if h <> 1 then
         InsertInOrder(CopyOf(node), h - 1)
      else
         Inc(i);
      
      node.GoToParent;
      
      obj := TTestObject.Create(i);
      StartDestruction(1, 'SetItem');
      node.Item := obj;
      FinishDestruction;
      Inc(i);
      
      lastSize := tree.Size;
      node.InsertAsRightChild(TTestObject.Create(i));
      Test(TTestObject(node.Item).Value = i, 'InsertAsRightChild',
           'does not advance to newly inserted item');
      Test(tree.Size = lastSize + 1, 'InsertAsRightChild', 'wrong size');
      
      if h <> 1 then
         InsertInOrder(CopyOf(node), h - 1)
      else
         Inc(i);
   end;
   node.Destroy;
end;

procedure TBinaryTreeTester.TestContainer(cont : TContainerAdt);
begin
   inherited;
   Assert(cont is TBinaryTree);
   tree := TBinaryTree(cont);
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertPreOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'InsertAsRoot',
        'wrong item at the root');
   i := 1;
   n := 2047;
   StartSilentMode;
   InsertPreOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { ----------------------- LeftMostLeaf (non-member) -------------------- }
   iter := LeftMostLeaf(tree.Root);
   testutils.Test(TTestObject(iter.Item).Value = 10, 'LeftMostLeaf (non-member)',
        'goes to wrong item');
   
   { ----------------------- RightMostLeaf (non-member) -------------------- }
   iter := RightMostLeaf(tree.Root);
   testutils.Test(TTestObject(iter.Item).Value = n - 1, 'RightMostLeaf (non-member)',
        'goes to wrong item');
   
   { ----------------------- Depth (non-member) -------------------- }
   testutils.Test(Depth(iter) = 10, 'Depth (non-member)');
   testutils.Test(Depth(tree.Root) = 0, 'Depth (non-member)', 'wrong depth for the root');
   
   { ----------------------- Height (non-member) -------------------- }
   testutils.Test(Height(iter) = 0, 'Height (non-member)');
   testutils.Test(Height(tree.Root) = 10, 'Height (non-member)');
   
   { ---------------------- test PreOrderIterator --------------------- }
   TestTraversalIterator(tree.PreOrderIterator, 'TBinaryTreePreOrderIterator');
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertPostOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(2046));
   testutils.Test(TTestObject(tree.Root.Item).Value = 2046, 'InsertAsRoot',
        'wrong item at the root');
   i := 0;
   n := 2047;
   StartSilentMode;
   InsertPostOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { ---------------------- test PostOrderIterator --------------------- }
   TestTraversalIterator(tree.PostOrderIterator, 'TBinaryTreePostOrderIterator');
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertInOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'InsertAsRoot',
        'wrong item at the root');
   i := 0;
   n := 2047;
   StartSilentMode;
   InsertInOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { ---------------------- test InOrderIterator --------------------- }
   TestTraversalIterator(tree.InOrderIterator, 'TBinaryTreeInOrderIterator');
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertPreOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'InsertAsRoot',
        'wrong item at the root');
   i := 1;
   n := 2047;
   StartSilentMode;
   InsertPostOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { ---------------------- test LevelOrderIterator --------------------- }
   liter := tree.LevelOrderIterator;
   i := 0;
   while not liter.IsFinish do
   begin
      obj := TTestObject.Create(i);
      StartDestruction(1, 'SetItem');
      liter.Item := obj;
      FinishDestruction;
      liter.Advance;
      Inc(i);
   end;
   
   liter.StartTraversal;
   TestTraversalIterator(tree.LevelOrderIterator, 'TBinaryTreeLevelOrderIterator');
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertPreOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'InsertAsRoot',
        'wrong item at the root');
   i := 1;
   n := 2047;
   StartSilentMode;
   InsertPreOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { ------------------------- DeleteSubTree ----------------------------- }
   iter := tree.Root;
   iter.GoToLeftChild;
   
   StartDestruction((n - 1) div 2, 'DeleteSubTree');
   iter.DeleteSubTree;
   FinishDestruction;
   
   TestIter(TTestObject(iter.Item).Value = 0, 'DeleteSubTree',
            'iterator not moved to parent');
   testutils.Test(tree.Size = (n - 1) div 2 + 1, 'DeleteSubTree', 'wrong size');
   piter := tree.PreOrderIterator;
   piter.Advance;
   CheckRange(piter, tree.Finish.PreOrderIterator, true,
              (n - 1) div 2 + 1, (n - 1) div 2, 'DeleteSubTree');
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertPreOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'InsertAsRoot',
        'wrong item at the root');
   i := 1;
   n := 2047;
   StartSilentMode;
   InsertPreOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { ------------------------ MoveToLeftChild --------------------------- }
   iter := tree.Root;
   while iter.HasLeftChild do
      iter.GoToLeftChild;
   iter2 := RightChild(tree.Root);
   tree.MoveToLeftChild(iter, iter2);
   testutils.Test(tree.Size = n, 'MoveToLeftChild', 'wrong size');
   testutils.Test(not tree.Root.HasRightChild, 'MoveToLeftChild', 'src not disconnected');
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'MoveToLeftChild',
        'wrong item at the root');
   
   piter := tree.PreOrderIterator;
   piter2 := tree.PreOrderIterator;
   while TTestObject(piter2.Item).Value <> (n - 1) div 2 + 1 do
      piter2.Advance;
   CheckRange(piter, piter2, true, 0, 11,
              'MoveToLeftChild (first sub-tree)');
   piter := TPreOrderIterator(piter2.CopySelf);
   Advance(piter, (n - 1) div 2);
   CheckRange(piter2, piter, true, (n - 1) div 2 + 1, (n - 1) div 2,
              'MoveToLeftChild (second sub-tree)');
   CheckRange(piter, tree.Finish.PreOrderIterator, true, 11, (n - 1) div 2 - 10,
              'MoveToLeftChild (first sub-tree - continued)');
   
   { ------------------------ MoveToRightChild -------------------------- }
   iter := TBinaryTreeIterator(piter2.TreeIterator);
   tree.MoveToRightChild(tree.Root, iter);
   testutils.Test(tree.Size = n, 'MoveToRightChild', 'wrong size');
   testutils.Test(tree.Root.HasRightChild, 'MoveToRightChild', 'src not connected');
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'MoveToRightChild',
        'wrong item at the root');
   piter := tree.PreOrderIterator;
   piter.Advance;
   iter := tree.Root;
   iter.GoToRightChild;
   CheckRange(piter, iter.PreOrderIterator, true, 1, (n - 1) div 2,
              'MoveToRightChild (first sub-tree)');
   CheckRange(iter.PreOrderIterator, tree.Finish.PreOrderIterator, true,
              (n - 1) div 2 + 1, (n - 1) div 2,
              'MoveToRightChild (second sub-tree)');
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertPreOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'InsertAsRoot',
        'wrong item at the root');
   i := 1;
   n := 2047;
   StartSilentMode;
   InsertPreOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { --------------------------- CopySelf ------------------------------- }
   copier := TTestObjectCopier.Create;
   tree2 := TBinaryTree(tree.CopySelf(copier));
   copier.Free;
   testutils.Test(tree2.Size = n, 'CopySelf', 'wrong size in destination');
   CheckRange(tree2.PreOrderIterator, tree2.Finish.PreOrderIterator,
              true, 0, n, 'CopySelf');
      
   { --------------- MoveToLeftChild (different containers) --------------- }
   iter := tree.Root;
   while iter.HasLeftChild do
      iter.GoToLeftChild;
   tree.MoveToLeftChild(iter, tree2.Root);
   testutils.Test(tree.Size = 2*n, 'MoveToLeftChild (different containers)',
        'wrong size in destination tree');
   testutils.Test(tree2.Size = 0, 'MoveToLeftChild', 'wrong size in source tree');
   
   iter.GoToLeftChild;
   iter3 := CopyOf(iter);
   CheckRange(tree.PreOrderIterator, iter.PreOrderIterator, true,
              0, 11, 'MoveToLeftChild');
   iter2 := RightChild(Parent(Parent(iter)));
   CheckRange(iter.PreOrderIterator, iter2.PreOrderIterator, true,
              0, n, 'MoveToLeftChild');
   iter := CopyOf(iter2);
   iter2 := tree.Root;
   iter2.GoToRightChild;
   CheckRange(iter.PreOrderIterator, iter2.PreOrderIterator, true,
              11, (n - 1) div 2 - 10, 'MoveToLeftChild');
   CheckRange(iter2.PreOrderIterator, tree.Finish.PreOrderIterator, true,
              (n - 1) div 2 + 1, (n - 1) div 2, 'MoveToLeftChild');
   
   { -------------- MoveToRightChild (different containers) -------------- }
   tree2.InsertAsRoot(iter3.Item);
   iter2 := CopyOf(iter3);
   iter2.GoToRightChild;
   tree2.MoveToRightChild(tree2.Root, iter2);
   
   iter2 := CopyOf(iter3);
   iter2.GoToLeftChild;
   tree2.MoveToLeftChild(tree2.Root, iter2);
   
   tree.OwnsItems := false;
   tree.DeleteSubTree(iter3);
   tree.OwnsItems := true;
   
   testutils.Test(tree.Size = n, 'MoveToRightChild & MoveToLeftChild (different containers)',
        'wrong size in source container');
   testutils.Test(tree2.Size = n, 'MoveToRightChild & ...',
        'wrong size in destination tree');
   CheckRange(tree.PreOrderIterator, tree.Finish.PreOrderIterator, true,
              0, n, 'MoveToRightChild & ... (source tree)');
   CheckRange(tree2.PreOrderIterator, tree2.Finish.PreOrderIterator, true,
              0, n, 'MoveToRightChild & ... (destination tree)');
   
   { --------------------------- Clear --------------------------------- }
   StartDestruction(tree.Size, 'Clear');
   tree.Clear;
   FinishDestruction;
   testutils.Test(tree.Size = 0, 'Clear', 'wrong size');
   
   { -------------------------- InsertInOrder ---------------------------- }
   tree.InsertAsRoot(TTestObject.Create(0));
   testutils.Test(TTestObject(tree.Root.Item).Value = 0, 'InsertAsRoot',
        'wrong item at the root');
   i := 0;
   n := 2047;
   StartSilentMode;
   InsertInOrder(tree.Root, 10);
   StopSilentMode;
   testutils.Test(tree.Size = n, 'InsertAsLeftChild & InsertAsRightChild', 'wrong size');
   
   { ------------------------ RotateSingleRight ----------------------------- }
   iter := tree.Root;
   iter.GoToLeftChild;
   iter.GoToRightChild;
   iter.GoToLeftChild;
   child := LeftChild(iter);
   t := RightChild(child);
   tree.RotateSingleRight(iter);
   testutils.Test(iter.Equal(RightChild(child)), 'RotateSingleRight');
   testutils.Test(t.Equal(LeftChild(iter)), 'RotateSingleRight');
   CheckRange(tree.InOrderIterator, tree.Finish.InOrderIterator, true,
              0, n - 1, 'RotateSingleRight');
   
   { ------------------------ RotateSingleLeft ----------------------------- }
   tree.RotateSingleLeft(child);
   testutils.Test(child.Equal(LeftChild(iter)), 'RotateSingleLeft');
   testutils.Test(t.Equal(RightChild(child)), 'RotateSingleLeft');
   CheckRange(tree.InOrderIterator, tree.Finish.InOrderIterator, true,
              0, n - 1, 'RotateSingleLeft');
   
   { ------------------------ RotateDoubleRight --------------------------- }
   lt := LeftChild(t);
   rt := RightChild(t);
   tree.RotateDoubleRight(iter);
   testutils.Test(lt.Equal(RightChild(child)), 'RotateDoubleRight');
   testutils.Test(rt.Equal(LeftChild(iter)), 'RotateDoubleRight');
   testutils.Test(child.Equal(LeftChild(t)), 'RotateDoubleRight');
   testutils.Test(iter.Equal(RightChild(t)), 'RotateDoubleRight');
   CheckRange(tree.InOrderIterator, tree.Finish.InOrderIterator, true,
              0, n - 1, 'RotateDoubleRight');

   { ------------------------ RotateDoubleLeft --------------------------- }
   iter := t;
   child := RightChild(iter);
   t := LeftChild(child);
   lt := LeftChild(t);
   rt := RightChild(t);
   tree.RotateDoubleLeft(iter);
   testutils.Test(lt.Equal(RightChild(iter)), 'RotateDoubleLeft');
   testutils.Test(rt.Equal(LeftChild(child)), 'RotateDoubleLeft');
   testutils.Test(iter.Equal(LeftChild(t)), 'RotateDoubleLeft');
   testutils.Test(child.Equal(RightChild(t)), 'RotateDoubleLeft');
   CheckRange(tree.InOrderIterator, tree.Finish.InOrderIterator, true,
              0, n - 1, 'RotateDoubleLeft');
   
   { -------------------------- destruction ----------------------------- }
   StartDestruction(tree2.Size, 'destructor (second tree)');
   tree2.Destroy;
   FinishDestruction; 
end;

end.
