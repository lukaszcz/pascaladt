program testallalgs;

{$apptype console }

uses
   testalgs, testutils, adtcont, adtcontbase, adtlist, adtqueue, adtarray;

var
   ls : TSingleList;
   ls2 : TDoubleList;
   q : TSegDeque;
   a : TArray;

begin
   StartTest('Algorithms (single list)');
   ls := TSingleList.Create;
   testalgs.TestAllAlgs(ls);
   StartDestruction(ls.Size, 'destructor');
   ls.Destroy;
   FinishDestruction;
   FinishTest;

   StartTest('Algorithms (double list)');
   ls2 := TDoubleList.Create;
   testalgs.TestAllAlgs(TDoubleListAdt(ls2));
   StartDestruction(ls2.Size, 'destructor');
   ls2.Destroy;
   FinishDestruction;
   FinishTest;

   StartTest('Algorithms (queue)');
   q := TSegDeque.Create;
   testalgs.TestAllAlgs(TRandomAccessContainerAdt(q));
   StartDestruction(q.Size, 'destructor');
   q.Destroy;
   FinishDestruction;
   FinishTest;

   StartTest('Algorithms (array)');
   a := TArray.Create;
   testalgs.TestAllAlgs(TRandomAccessContainerAdt(a));
   StartDestruction(a.Size, 'destructor');
   a.Destroy;
   FinishDestruction;
   FinishTest;
end.
