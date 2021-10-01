program testallconts;

{$apptype console }

uses
   SysUtils, testutils, tester, testcont, testbintree, testtree, adtcont,
   adt23tree, adtavltree, adtbinomqueue, adtbintree, adttree, adtbstree, adthash,
   adtlist, adtarray, adtqueue, adtsplaytree;

procedure TestUsing(t : TTester);
begin
   Assert(t <> nil);
   t.Test;
   t.Destroy;
end;

begin
   if ParamCount = 1 then
      RandSeed := StrToInt(ParamStr(1))
   else
      Randomize;

   WriteLn;
   WriteLn('PascalAdt test suit.');
   WriteLn;
   WriteLn('RandSeed: ', RandSeed);
   WriteLn;

   { ----------------- queues & arrays ---------------------- }
   TestUsing(TRandomAccessContainerTester.Create('TArray', 'TArrayIterator',
                                                 TArray.Create));
   TestUsing(TRandomAccessContainerTester.Create('TSegDeque',
                                                 'TSegDequeIterator',
                                                 TSegDeque.Create));
   TestUsing(TRandomAccessContainerTester.Create('TCircularDeque',
                                                 'TCircularDequeIterator',
                                                 TCircularDeque.Create));

   { ------------------- basic trees ------------------------ }
   TestUsing(TTreeTester.Create('TTree', 'TTreeIterator', TTree.Create));
   TestUsing(TBinaryTreeTester.Create('TBinaryTree', 'TBinaryTreeIterator',
                                      TBinaryTree.Create));

   { -------------------- hash sets -------------------------- }
   TestUsing(THashSetTester.Create('THashTable', 'THashTableIterator',
                                   THashTable.Create));
   TestUsing(THashSetTester.Create('TScatterTable', 'TScatterTableIterator',
                                   TScatterTable.Create));

   { ---------------- sets based on trees --------------------- }
   TestUsing(TSortedSetTester.Create('TSplayTree', 'TBinaryTreeIterator',
                                     TSplayTree.Create));
   TestUsing(TSortedSetTester.Create('TAvlTree', 'TBinaryTreeIterator',
                                     TAvlTree.Create));
   TestUsing(TSortedSetTester.Create('TBinarySearchTree',
                                     'TBinarySearchTreeIterator',
                                     TBinarySearchTree.Create));
   TestUsing(TConcatenableSortedSetTester.Create('T23Tree',
                                                 'T23TreeIterator',
                                                 T23Tree.Create));


   { --------------------- priority queues -------------------- }
   TestUsing(TPriorityQueueTester.Create('TBinomialQueue',
                                         'TBinomialQueueIterator',
                                         TBinomialQueue.Create));

   { ----------------- lists --------------------- }
   TestUsing(TSingleListTester.Create('TSingleList', 'TSingleListIterator',
                                      TSingleList.Create));
   TestUsing(TDoubleListTester.Create('TDoubleList', 'TDoubleListIterator',
                                      TDoubleList.Create));
   TestUsing(TDoubleListTester.Create('TXorList', 'TXorListIterator',
                                      TXorList.Create));

end.
