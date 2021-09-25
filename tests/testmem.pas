program testmem;

uses
   adtmem, testutils;

procedure TestGrabageCollector;
var
   grab : TGrabageCollector;
   handle : TCollectorObjectHandle;
   i : integer;
begin
   StartTest('TGrabageCollector');
   grab := TGrabageCollector.Create;
   for i := 0 to 100 do
      handle := grab.RegisterObject(TTestObject.Create(i));
   Test(TTestObject(grab.GetObject(handle)).Value = 100, 'GetObject');
   handle := grab.RegisterObject(TTestObject.Create(10));
   grab.RegisterObject(TTestObject.Create(100));
   StartDestruction(1, 'UnregisterObject & Free');
   (grab.UnregisterObject(handle)).Free;
   FinishDestruction;
   StartDestruction(102, 'DestroyObjects');
   grab.FreeObjects;
   FinishDestruction;
   for i := 1 to 200 do
      grab.RegisterObject(TTestObject.Create(i));
   StartDestruction(200, 'destructor');
   grab.Destroy;
   FinishDestruction;
   FinishTest;
end;

begin
   TestGrabageCollector;
end.

