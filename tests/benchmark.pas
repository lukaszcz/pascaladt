program benchmark;

uses
   adtcont, adthash, adtavltree, adtbstree, adtsplaytree, adt23tree, testsetspeed, adtlog;

procedure DoBenchmark(aset : TStringSetAdt; className : String);
begin
   BenchmarkSet(aset, className);
   aset.Destroy;   
end;

begin
   OpenLogStream;
   DoBenchmark(TStringHashTable.Create, 'TStringHashTable');
   DoBenchmark(TStringScatterTable.Create, 'TStringScatterTable');
   DoBenchmark(TStringAvlTree.Create, 'TStringAvlTree');
   DoBenchmark(TStringSplayTree.Create, 'TStringSplayTree');
   DoBenchmark(TString23Tree.Create, 'TString23Tree');
   DoBenchmark(TStringBinarySearchTree.Create, 'TStringBinarySearchTree');
   WriteLn;
   WriteLn('Done. See the log file for details (pascaladt.log).');
end.
