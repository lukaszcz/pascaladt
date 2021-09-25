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
   
   
implementation

uses
   adtcont;

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

end.
