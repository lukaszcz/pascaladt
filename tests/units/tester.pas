unit tester;

interface

uses
   testutils, adtcontbase;

type
   TTester = class
   protected
      contName, iterName : String;
      FCont : TContainerAdt;
      { should create a container of a desired type; may return nil to
        indicate that a given container type is not available for
        testing; }
      function CreateContainer : TContainerAdt; virtual;
      { 1 by default, should be 2 for a map }
      function ObjectsInOneItem : SizeType; virtual;
      { the two following routines do nothing by default; }
      procedure TestContainer(cont : TContainerAdt); virtual;
      procedure BenchmarkContainer(cont : TContainerAdt); virtual;
   public
      constructor Create(acont, aiter : String; cont : TContainerAdt);
      destructor Destroy; override;
      { runs the tests }
      procedure Test; virtual;
      property TestedCont : TContainerAdt read FCont write FCont;
   end;

   TStringTester = class
   protected
      contName, iterName : String;
      FCont : TStringContainerAdt;
      { should create a container of a desired type; may return nil to
        indicate that a given container type is not available for
        testing; }
      function CreateContainer : TStringContainerAdt; virtual;
      { 1 by default, should be 2 for a map }
      function ObjectsInOneItem : SizeType; virtual;
      { the two following routines do nothing by default; }
      procedure TestContainer(cont : TStringContainerAdt); virtual;
      procedure BenchmarkContainer(cont : TStringContainerAdt); virtual;
   public
      constructor Create(acont, aiter : String; cont : TStringContainerAdt);
      destructor Destroy; override;
      { runs the tests }
      procedure Test; virtual;
      property TestedCont : TStringContainerAdt read FCont write FCont;
   end;

   TIntegerTester = class
   protected
      contName, iterName : String;
      FCont : TIntegerContainerAdt;
      { should create a container of a desired type; may return nil to
        indicate that a given container type is not available for
        testing; }
      function CreateContainer : TIntegerContainerAdt; virtual;
      { 1 by default, should be 2 for a map }
      function ObjectsInOneItem : SizeType; virtual;
      { the two following routines do nothing by default; }
      procedure TestContainer(cont : TIntegerContainerAdt); virtual;
      procedure BenchmarkContainer(cont : TIntegerContainerAdt); virtual;
   public
      constructor Create(acont, aiter : String; cont : TIntegerContainerAdt);
      destructor Destroy; override;
      { runs the tests }
      procedure Test; virtual;
      property TestedCont : TIntegerContainerAdt read FCont write FCont;
   end;

implementation

uses
   adtcont;

{ ---------------------------- TTester -------------------------------- }

constructor TTester.Create(acont, aiter : String; cont : TContainerAdt);
begin
   Assert(cont <> nil);
   contName := acont;
   iterName := aiter;
   FCont := cont;
end;

destructor TTester.Destroy;
begin
   FCont.Free;
end;

function TTester.CreateContainer : TContainerAdt;
begin
   Result := FCont.CopySelf(nil);
end;

function TTester.ObjectsInOneItem : SizeType;
begin
   Result := 1;
end;

procedure TTester.Test;
var
   cont1 : TContainerAdt;
begin
   cont1 := CreateContainer;
   if cont1 <> nil then
   begin
      testutils.iterName := iterName;
      StartTest(contName);

      TestContainer(cont1);

      StartDestruction(cont1.Size * ObjectsInOneItem, 'Destroy');
      cont1.Destroy;
      FinishDestruction;

      FinishTest;
   end;

   cont1 := CreateContainer;
   if cont1 <> nil then
   begin
      StartTest('(benchmark) ' + contName);

      BenchmarkContainer(cont1);

      StartDestruction(cont1.Size * ObjectsInOneItem, 'destructor');
      cont1.Destroy;
      FinishDestruction;

      FinishTest;
   end;
end;

procedure TTester.TestContainer(cont : TContainerAdt);
begin
   WriteLn('** Tests not available for ' + contName);
end;

procedure TTester.BenchmarkContainer(cont : TContainerAdt);
begin
   WriteLn('** Benchmark not available for ' + contName);
end;

{ ---------------------------- TStringTester -------------------------------- }

constructor TStringTester.Create(acont, aiter : String; cont : TStringContainerAdt);
begin
   Assert(cont <> nil);
   contName := acont;
   iterName := aiter;
   FCont := cont;
end;

destructor TStringTester.Destroy;
begin
   FCont.Free;
end;

function TStringTester.CreateContainer : TStringContainerAdt;
begin
   Result := FCont.CopySelf(nil);
end;

function TStringTester.ObjectsInOneItem : SizeType;
begin
   Result := 1;
end;

procedure TStringTester.Test;
var
   cont1 : TStringContainerAdt;
begin
   cont1 := CreateContainer;
   if cont1 <> nil then
   begin
      testutils.iterName := iterName;
      StartTest(contName);

      TestContainer(cont1);

      cont1.Destroy;

      FinishTest;
   end;

   cont1 := CreateContainer;
   if cont1 <> nil then
   begin
      StartTest('(benchmark) ' + contName);

      BenchmarkContainer(cont1);

      cont1.Destroy;

      FinishTest;
   end;
end;

procedure TStringTester.TestContainer(cont : TStringContainerAdt);
begin
   WriteLn('** Tests not available for ' + contName);
end;

procedure TStringTester.BenchmarkContainer(cont : TStringContainerAdt);
begin
   WriteLn('** Benchmark not available for ' + contName);
end;


{ ---------------------------- TIntegerTester -------------------------------- }

constructor TIntegerTester.Create(acont, aiter : String; cont : TIntegerContainerAdt);
begin
   Assert(cont <> nil);
   contName := acont;
   iterName := aiter;
   FCont := cont;
end;

destructor TIntegerTester.Destroy;
begin
   FCont.Free;
end;

function TIntegerTester.CreateContainer : TIntegerContainerAdt;
begin
   Result := FCont.CopySelf(nil);
end;

function TIntegerTester.ObjectsInOneItem : SizeType;
begin
   Result := 1;
end;

procedure TIntegerTester.Test;
var
   cont1 : TIntegerContainerAdt;
begin
   cont1 := CreateContainer;
   if cont1 <> nil then
   begin
      testutils.iterName := iterName;
      StartTest(contName);

      TestContainer(cont1);

      cont1.Destroy;

      FinishTest;
   end;

   cont1 := CreateContainer;
   if cont1 <> nil then
   begin
      StartTest('(benchmark) ' + contName);

      BenchmarkContainer(cont1);

      cont1.Destroy;

      FinishTest;
   end;
end;

procedure TIntegerTester.TestContainer(cont : TIntegerContainerAdt);
begin
   WriteLn('** Tests not available for ' + contName);
end;

procedure TIntegerTester.BenchmarkContainer(cont : TIntegerContainerAdt);
begin
   WriteLn('** Benchmark not available for ' + contName);
end;

end.
