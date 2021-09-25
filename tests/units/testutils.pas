unit testutils;

interface

uses
   adtiters, adtfunct;

type
   TTestObject = class
   private
      FField : Integer;
   public
      constructor Create(int : Integer);
      destructor Destroy; override;
      property Value : Integer read FField write FField;
   end;
   
   TTestObjectCopier = class (TFunctor, IUnaryFunctor)
   public
      function Perform(aitem : TObject) : TObject;
   end;
   
   TTestObjectComparer = class (TFunctor, IBinaryComparer, ISubtractor)
   public
      function Compare(aitem1, aitem2 : TObject) : Integer;
   end;
   
   TTestObjectHasher = class (TFunctor, IHasher)
   public
      function Hash(aitem : TObject) : UnsignedType;
   end;

var
   { name of iterators for currently tested container }
   IterName : String;
   
{ Checks the parameters passed on command line and sets various
  variables appropriately. This should be called once at the beginning
  of the main test program. Valid options are: }
   { --silent or -s => be silent - show messages only for failed tests }
procedure CheckTestParams;   
{ Starts a test - title = name of tested thing  }
procedure StartTest(title : string);
{ Ends a test }   
procedure FinishTest;
{ Tests condition, if it's false it means that thing 'title' failed,
  otherwise passed. Prints appropriate message. }
procedure Test(condition : Boolean; title : string); overload;
{ The same as above, but prints additional 'failed' message if test failed. }
procedure Test(condition : Boolean; title, failed : string); overload;
{ The two routines below are esentially the same as those above, but
  prepend current value of IterName to the displayed title. }
procedure TestIter(condition : Boolean; title : string); overload;
procedure TestIter(condition : Boolean; title, failed : string); overload;
{ Checks if items in the specified range are in descending (ascend =
  false) or ascending (ascend = true) order, i.e. if each next one is
  smaller/larger than the previous by one. Start item is tested
  against fnum. Also checks if the number of items in the range =
  count. testname - name of the thing tested. }
procedure CheckRange(const Start, finish : TForwardIterator; ascend : Boolean;
                     fnum, count : Integer; testname : string);
{ Notifies that objs objects are going to be destroyed. This allows to
  check if they were really destroyed and print appropriate messages. }
procedure StartDestruction(objs : Integer; testname : string);
{ Notifies that the code supposed to destroy objects (after
  StartDestruction) ends.  }
procedure FinishDestruction;
{ Enters silent mode - no messages are printed for successful tests,
  only for failures.  }
procedure StartSilentMode;
{ Leaves silent mode. }
procedure StopSilentMode;
{ returns the content of a TTestObject }
function TestObjectValue(obj : TObject) : Integer;
{ returns a functor to compare TTestObjects }
function TestObjectComparer : ISubtractor;
{ returns a functor to copy TTestObjects }
function TestObjectCopier : IUnaryFunctor;

implementation

uses
   SysUtils, adthashfunct;

var
   objectCount, oldObjectsCount, ObjectsToDestroy : Cardinal;
   failures, numtests, leakmsg : Cardinal;
   destrname, testtitle : string;
   silent : Boolean;
   GlobalSilent : Boolean;
   
constructor TTestObject.Create(int : Integer);
begin
   FField := int;
   Inc(objectCount);
//   WriteLn(IntToStr(objectCount));
end;

destructor TTestObject.Destroy;
begin
   Dec(objectCount);
//   WriteLn(IntToStr(objectCount));
end;

function TTestObjectCopier.Perform(aitem : TObject) : TObject;
begin
   Result := TTestObject.Create(TTestObject(aitem).Value);
end;

function TTestObjectComparer.Compare(aitem1, aitem2 : TObject) : Integer;
begin
   Result := TTestObject(aitem1).Value - TTestObject(aitem2).Value;
end;

function TTestObjectHasher.Hash(aitem : TObject) : UnsignedType;
begin
   Result := FNVHash(@TTestObject(aitem).FField, SizeOf(Integer));
end;


procedure CheckTestParams;
begin
   GlobalSilent := false;
   
   if (ParamCount = 1) and
         ((ParamStr(1) = '--silent') or (ParamStr(1) = '-s')) then
   begin
      GlobalSilent := true;
   end else if ParamCount <> 0 then
   begin
      WriteLn('testutils: error - wrong number of parameters');
      Halt;
   end;
end;

procedure StartTest(title : string);
begin
   testtitle := title;
   WriteLn;
   WriteLn('Testing ' + testtitle + '...');
   WriteLn;
   objectCount := 0;
   failures := 0;
   ObjectsToDestroy := 0;
   numtests := 0;
   leakmsg := 0;
   silent := false;
end;

procedure FinishTest;
begin
   Test(objectCount = 0, 'Proper object deallocation',
        'Total objects leaked: ' + IntToStr(objectCount));
   WriteLn;
   WriteLn('           Summary for ' + testtitle);
   WriteLn;
   WriteLn('Number of tests carried out: ' + IntToStr(numtests));
   if failures = 0 then
      WriteLn('All (' + IntToStr(numtests) + ') tests successfully completed.')
   else
   begin
      WriteLn('Total number of tests that FAILED: ' + IntToStr(failures));
      WriteLn('Number of tests successfully completed: '
              + IntToStr(numtests - failures));
   end;
   WriteLn; WriteLn;
end;

procedure Test(condition : Boolean; title : string);
begin
   if not (silent or GlobalSilent) then
      Inc(numtests);
   if condition then
   begin
      if not (silent or GlobalSilent) then
         WriteLn(title + ' - passed');
   end else
   begin
      WriteLn('!! ' + title + ' - FAILED');
      Inc(failures);
      if silent then
         Inc(numtests);
      if failures > 50 then
      begin
         WriteLn;
         WriteLn('FATAL - too many tests failed - aborting...');
         Halt;
      end;
   end;
end;

procedure Test(condition : Boolean; title, failed : string);
begin
   Test(condition, title);
   if not condition then
      WriteLn('     - ', failed);
end;

procedure TestIter(condition : Boolean; title : string);
begin
   Test(condition, IterName + '.' + title);
end;

procedure TestIter(condition : Boolean; title, failed : string);
begin
   Test(condition, IterName + '.' + title, failed);
end;

procedure CheckRange(const Start, finish : TForwardIterator; ascend : Boolean;
                     fnum, count : Integer; testname : string);
var
   num : Integer;
   iter : TForwardIterator;
   wasInSilent : Boolean;
begin
   iter := CopyOf(start);
   num := fnum;
   wasInSilent := silent;
   if not wasInSilent then
      StartSilentMode;
   
   while (not iter.Equal(finish)) and (count <> 0) do
   begin
      if TTestObject(iter.Item).Value <> fnum then
      begin
	 if ascend then
	    num := fnum - num
	 else
	    num := num - fnum;
         Test(false, testname,
	      'Wrong order of items starting from the ' + IntToStr(num) + 'th');
	 WriteLn('   Remaining items are: ');
         if count > 30 then
         begin
            WriteLn('      (too many items, only first 30 written)');
            count := 30;
         end;
               
	 while (not Start.Equal(finish)) and (count <> 0) do
	 begin
	    Write(TTestObject(iter.Item).Value, ' ');
	    iter.Advance;
	    dec(count);
	 end;
	 WriteLn;
         Exit;
      end;
      iter.Advance;
      Dec(count);
      if ascend then
         Inc(fnum)
      else
         Dec(fnum);
   end;
   if not wasInSilent then
      StopSilentMode;
   Test(count = 0, testname, 'Wrong number of items');
   
   if not (silent or globalSilent) then
      Write('Destroying iterator...');
   iter.Destroy;
   if not (silent or GlobalSilent) then
      WriteLn(' - passed');
end;

procedure StartDestruction(objs : Integer; testname : string);
begin
   if objectsToDestroy <> 0 then
   begin
      WriteLn('FATAL: error in testutils - previous destruction unfinished !');
      Halt;
   end;
   destrname := testname;
   objectsToDestroy := objs;
   oldObjectsCount := objectCount;
   if objectsToDestroy > objectCount then
   begin
      WriteLn('!! ' + destrname +
                 ' - attempting to destroy more objects than existing');
   end;
end;

procedure FinishDestruction;
begin
   if oldObjectsCount - objectsToDestroy < objectCount then
   begin
      writeLN('!! ' + destrname + ' leaked '
              + IntToStr(objectsToDestroy - (oldObjectsCount - objectCount))
              + ' objects !!!');
      Inc(leakmsg);
   end else if oldObjectsCount - objectsToDestroy > objectCount then
   begin
      WriteLn('!! ' + destrname + ' destroyed too many objects ('
              + IntToStr(oldObjectsCount - objectCOunt) + ' instead of '
              + IntToStr(objectsToDestroy) + ') !!!');
      Inc(leakmsg);
   end;
   objectsToDestroy := 0;
   
   if leakmsg > 30 then
   begin
      WriteLn('FATAL - too many objects leaked - halting...');
      Halt;
   end;
end;

procedure StartSilentMode;
begin
   if silent then
      WriteLn('testutils: already in silent mode...');
   silent := true;
end;

procedure StopSilentMode;
begin
   if not silent then
      WriteLn('testutils: not in silent mode...');
   silent := false;
end;

function TestObjectValue(obj : TObject) : Integer;
begin
   Assert(obj is TTestObject);
   Result := TTestObject(obj).Value;
end;

function TestObjectComparer : ISubtractor;
begin
   Result := TTestObjectComparer.Create;
end;

function TestObjectCopier : IUnaryFunctor;
begin
   Result := TTestObjectCopier.Create;
end;

end.

