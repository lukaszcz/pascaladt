program customer;

{ This is a demo program demostrating some basic features of the
  PascalAdt library. See docs/tutorial.txt for more information.  }

{$apptype console }

uses
   SysUtils, adtfunct, adthashfunct, adtcont, adtalgs, adtiters, adtlist,
   adthash, adtarray, adtavltree;

type
   TCustomer = class
   private
      FFirstName, FSurname : String;
      FAddress : String;
      FOrders : TListAdt;
   public
      constructor Create(aFirstName, aSurname, aAddress : String);
      destructor Destroy; override;
      
      property FirstName : String read FFirstName write FFirstName;
      property Surname : String read FSurname write FSurname;
      property Address : String read FAddress write FAddress;
      property Orders : TListAdt read FOrders;
   end;
   
   TCustomerKey = class (TCustomer)
   public
      constructor Create(aFirstName, aSurname : String);
   end;
   
   TOrder = record
      orderId : Cardinal;
      productName, price : String;
      customer : TCustomer;
   end;
   POrder = ^TOrder;
   
   TOrderDisposer = class (TFunctor, IUnaryFunctor)
   public
      function Perform(ptr : Pointer) : Pointer;
   end;
   
   TCustomerComparer = class (TFunctor, IBinaryComparer)
   public
      function Compare(ptr1, ptr2 : Pointer) : IndexType;
   end;
   
   TCustomerHasher = class (TFunctor, IHasher)
   public
      function Hash(ptr : Pointer) : UnsignedType;
   end;
   
   TOrderComparer = class (TFunctor, IBinaryComparer)
   public
      function Compare(ptr1, ptr2 : Pointer) : IndexType;
   end;
   
   TOrderCustomerComparer = class (TFunctor, IBinaryComparer)
   public
      function Compare(ptr1, ptr2 : Pointer) : IndexType;
   end;
   
   TOrderProductComparer = class (TFunctor, IUnaryPredicate)
   private
      FProduct : String;
   public
      constructor Create(product : String);
      function Test(ptr : Pointer) : Boolean;
   end;
   

{ global variables }  
var
   allOrders : TSortedSetAdt;
   allCustomers : THashSetAdt;
   unusedOrderId : Cardinal;
   

function CompareCustomers(customer1, customer2 : TCustomer) : IndexType;
begin
   Result := CompareStr(customer1.Surname, customer2.Surname);
   if Result = 0 then
      Result := CompareStr(customer1.FirstName, customer2.FirstName);
end;

{ ----------------------------- TCustomer ------------------------------ }

constructor TCustomer.Create(aFirstName, aSurname, aAddress : String);
begin
   FFirstName := aFirstName;
   FSurname := aSurname;
   FAddress := aAddress;
   FOrders := TSingleList.Create;
end;

destructor TCustomer.Destroy;
begin
   FOrders.Free
end;

constructor TCustomerKey.Create(aFirstName, aSurname : String);
begin
   FirstName := aFirstName;
   Surname := aSurname;
end;

{ -------------------- functors --------------------- }

function TOrderDisposer.Perform(ptr : Pointer) : Pointer;
begin
   Result := nil;
   Dispose(POrder(ptr));
end;

function TCustomerComparer.Compare(ptr1, ptr2 : Pointer) : IndexType;
begin
   Result := CompareCustomers(TCustomer(ptr1), TCustomer(ptr2));
end;

function TCustomerHasher.Hash(ptr : Pointer) : UnsignedType;
var
   nameStr : AnsiString;
begin
   nameStr := TCustomer(ptr).FirstName + TCustomer(ptr).Surname;
   Result := FNVHash(PChar(nameStr), Length(nameStr));
end;

function TOrderComparer.Compare(ptr1, ptr2 : Pointer) : IndexType;
begin
   Result := POrder(ptr1)^.orderId - POrder(ptr2)^.orderId;
end;

function TOrderCustomerComparer.Compare(ptr1, ptr2 : Pointer) : IndexType;
begin
   Result := CompareCustomers(POrder(ptr1)^.Customer, POrder(ptr2)^.Customer);
end;

constructor TOrderProductComparer.Create(product : String);
begin
   FProduct := product;
end;

function TOrderProductComparer.Test(ptr : Pointer) : Boolean;
begin
   Result := CompareStr(POrder(ptr)^.ProductName, FProduct) = 0;
end;


{ --------------------- routines ---------------------- }

procedure PrintOrderWithoutCustomerInfo(ptr : Pointer);
var
   order : POrder;
begin
   order := POrder(ptr);
   with order^ do
   begin
      WriteLn;
      WriteLn('Order ID: ', orderId);
      WriteLn('Product name: ', productName);
      WriteLn('Price: ', price);
   end;
end;
   
procedure PrintOrder(ptr : Pointer);
var
   order : POrder;
begin
   order := POrder(ptr);
   PrintOrderWithoutCustomerInfo(order);
   with order^ do
   begin
      WriteLn('Customer name: ', customer.FirstName, ' ', customer.Surname);
      WriteLn('Customer address: ', customer.Address);
   end;
end;

procedure PrintCustomer(ptr : Pointer);
var
   customer : TCustomer;
begin
   Assert(TObject(ptr) is TCustomer);
   customer := TCustomer(ptr);
   with customer do
   begin
      WriteLn;
      WriteLn('--------------------------------------------');
      WriteLn('Name: ', FirstName, ' ', Surname);
      WriteLn('Address: ', Address);
      WriteLn('Current number of orders: ', Orders.Size);
      WriteLn('Orders: ');
      ForEach(Orders.ForwardStart, Orders.ForwardFinish,
              Adapt(@PrintOrderWithoutCustomerInfo));
   end;
end;

procedure PrintCustomerName(ptr : Pointer);
var
   customer : TCustomer;
begin
   Assert(TObject(ptr) is TCustomer);
   customer := TCustomer(ptr);
   WriteLn(customer.Surname, ' ', customer.FirstName);
end;

procedure PrintCustomers;
var
   buff : PascalArrayType;
   iter : TForwardIterator;
   a : TPascalArray;
   comparer : IBinaryComparer;
   i : Integer;
begin
   SetLength(buff, allCustomers.Size);
   
   iter := allCustomers.Start;
   i := 0;
   while not iter.IsFinish do
   begin
      buff[i] := iter.Item;
      Inc(i);
      iter.Advance;
   end;
   
   a := TPascalArray.Create(buff);
   try
      comparer := TCustomerComparer.Create;
   
      Sort(a.Start, a.Finish, comparer);
      WriteLn('Registered customers:');
      ForEach(a.Start, a.Finish, Adapt(@PrintCustomerName));
   finally
      a.Free;
   end;
end;

procedure PrintOrders;
var
   iter : TForwardIterator;
begin
   iter := allOrders.Start;
   while not iter.IsFinish do
   begin
      PrintOrder(iter.Item);
      iter.Advance;
   end;
end;

procedure FindCustomer(firstName, surname : String);
var
   customerKey : TCustomerKey;
   customer : TCustomer;
begin
   customerKey := TCustomerKey.Create(firstName, surname);
   try
      customer := TCustomer(allCustomers.Find(customerKey));
      if customer <> nil then
         { the customer is registered in the database }
      begin
         WriteLn(firstName, ' ', surname, ' is our customer.');
         PrintCustomer(customer);
      end else
         { there's no such customer }
      begin
         WriteLn(firstName, ' ', surname, ' is not registered as our customer.');
      end;
   finally
      { customerKey is not stored anywhere within allCustomers, so we
        have to destroy it }
      customerKey.Free;
      { Although the customer object was retunred by the Find method,
        it is still owned by allCustomers, so we should not destroy
        it. }
   end;
end;

procedure AddCustomer;
var
   firstName, surname, address, answer : String;
   customer : TCustomer;
begin
   WriteLn('Fill in customer data.');
   Write('First name: '); ReadLn(firstName);
   Write('Surname: '); ReadLn(surname);
   Write('Address: '); ReadLn(address);
   customer := TCustomer.Create(firstName, surname, address);
   if not allCustomers.Insert(customer) then
   begin
      Write('Customer already in the database. Replace? (yes/no) ');
      ReadLn(answer);
      if LowerCase(answer) = 'yes' then
      begin
         allCustomers.Delete(customer);
         allCustomers.Insert(customer);
      end else
      begin
         { We have to destroy customer because it has not been
           successfully inserted and it is therefore not owned by
           the allCustomers container. }
         customer.Free;
         Exit;
      end;
   end;
   WriteLn('Customer ' + firstName + ' ' + surname + ' successfully added.');
end;

procedure RemoveCustomer(firstName, surname : String);
var
   customerKey : TCustomerKey;
   orderKey : TOrder;
   iter : TForwardIterator;
   customer : TCustomer;
   i : Integer;
begin
   customerKey := TCustomerKey.Create(firstName, surname);
   try
      customer := TCustomer(allCustomers.Find(customerKey));
      if customer <> nil then
      begin
         { remove the orders associated with the customer as well }
         iter := customer.Orders.ForwardStart;
         while not iter.IsFinish do
         begin
            orderKey.orderId := POrder(iter.Item)^.orderId;
            allOrders.Delete(@orderKey);
            iter.Delete;
         end;
         
         { remove the customer himself }
         i := allCustomers.Delete(customerKey);
         { in no way may this function return 0 since the desired
           customer was already found }
         Assert(i <> 0);
         
         WriteLn('Customer ', firstName, ' ', surname,
                 ' removed from the database.')
      end else
         WriteLn('No customer ', firstName, ' ', surname, ' in the database.');
   finally
      customerKey.Free;
   end;
end;

procedure FindOrder(orderId : Cardinal);
var
   order : POrder;
   orderKey : TOrder;
begin
   orderKey.orderId := orderId;
   order := allOrders.Find(@orderKey);
   if order <> nil then
   begin
      PrintOrder(order);
   end else
   begin
      WriteLn('Invalid order ID.');
   end;
end;

procedure FindOrders(productName : String);
var
   predicate : IUnaryPredicate;
   iter : TForwardIterator;
begin
   predicate := TOrderProductComparer.Create(productName);
   iter := Find(allOrders.Start, allOrders.Finish, predicate);
   if iter.IsFinish then
      WriteLn('No orders for this product.')
   else begin     
      while not iter.IsFinish do
      begin
         PrintOrder(iter.Item);
         iter.Advance;
         iter := Find(iter, allOrders.Finish, predicate);
      end;
   end;
end;

procedure AddOrder;
var
   order : POrder;
   surname, firstName : String;
   customerKey : TCustomerKey;
begin
   New(order);
   
   try
      WriteLn('Enter order data.');
      with order^ do
      begin
         Write('Product name: '); ReadLn(productName);
         Write('Price: '); ReadLn(price);      
      end;
      Write('Customer first name: '); ReadLn(firstName);
      Write('Customer surname: '); ReadLn(surname);
      
      { check if the specified customer is present in the database }
      customerKey := TCustomerKey.Create(firstName, surname);
      try
         order^.customer := TCustomer(allCustomers.Find(customerKey));
      finally
         customerKey.Free;
      end;
      
      if order^.customer <> nil then
      begin
         order^.orderId := unusedOrderId;
         Inc(unusedOrderId);
         order^.customer.Orders.PushBack(order);
         if not allOrders.Insert(order) then
            WriteLn('Error! Impossible!');
         WriteLn('Order successfully added.');
         WriteLn('Order ID: ', order^.orderId);
      end else
      begin
         Dispose(order);
         WriteLn('Invalid customer specified.');
      end;
   except
      { if an exception occurs the order is not automatically disposed
        (even if it occurs in allOrders.Insert) }
      Dispose(order);
      raise;
   end;
end;

procedure RemoveOrder(orderId : Cardinal);
var
   order : POrder;
   orderKey : TOrder;
   comparer : IBinaryComparer;
begin
   orderKey.orderId := orderId;
   order := POrder(allOrders.Find(@orderKey));
   if order <> nil then
   begin
      { remove the order from the list of the customer associated with
        it }
      comparer := TOrderComparer.Create;
      DeleteIf(order^.customer.Orders.ForwardStart, MAXINT,
               EqualTo(comparer, order));
      
      { remove the order itself }
      if allOrders.Delete(@orderKey) = 0 then
         WriteLn('Error! Impossible!');
      
      WriteLn('Order ', orderId, ' successfully removed.');
   end else
   begin
      WriteLn('Invaid order ID.');
   end;
end;

procedure Run;
var
   command, idStr, firstName, surname, product : String;
begin
   WriteLn('customer.pas demo');
   WriteLn('Type help for the list of available commands.');

   while true do
   begin
      WriteLn;
      Write('> '); ReadLn(command);
      command := LowerCase(command);
      if command = 'add-customer' then
      begin
         AddCustomer;
      end else if command = 'add-order' then
      begin
         AddOrder;
      end else if command = 'help' then
      begin
         WriteLn('add-customer -- add a customer to the database');
         WriteLn('add-order -- add an order');
         WriteLn('help -- print this message');
         WriteLn('quit -- exit the program');
         WriteLn('print-customers -- print the names of all registered customers');
         WriteLn('print-orders -- print all orders');
         WriteLn('print-customer-info -- print info for a specified customer');
         WriteLn('print-order-info -- print info for a specified order');
         WriteLn('print-product-orders -- print all orders for a certain product');
         WriteLn('remove-customer -- remove a customer');
         WriteLn('remove-order -- remove an order');
      end else if command = 'print-customers' then
      begin
         PrintCustomers;
      end else if command = 'print-orders' then
      begin
         PrintOrders;
      end else if command = 'print-customer-info' then
      begin
         Write('Enter customer''s first name: '); ReadLn(firstName);
         Write('Enter customer''s surname: '); ReadLn(surname);
         FindCustomer(firstName, surname);
      end else if command = 'print-order-info' then
      begin
         Write('Enter order''s ID: '); ReadLn(idStr);
         FindOrder(StrToInt(idStr));
      end else if command = 'print-product-orders' then
      begin
         Write('Enter product name: '); REadLN(product);
         FindOrders(product);
      end else if command = 'quit' then
      begin
         break;
      end else if command = 'remove-customer' then
      begin
         Write('Enter customer''s first name: '); ReadLn(firstName);
         Write('Enter customer''s surname: '); ReadLn(surname);
         RemoveCustomer(firstName, surname);
      end else if command = 'remove-order' then
      begin
         Write('Enter order''s ID: '); ReadLn(idStr);
         RemoveOrder(StrToInt(idStr));
      end else
      begin
         WriteLn('Invalid command. Type help for help.');
      end;
   end;
end;

begin
   allOrders := nil;
   allCustomers := nil;
   try
      allOrders := TAvlTree.Create(TOrderComparer.Create, TOrderDisposer.Create);
      allCustomers := TObjectHashTable.Create(TCustomerHasher.Create,
                                              TCustomerComparer.Create);
      unusedOrderId := 0;
            
      Run;
      
   finally
      allOrders.Free;
      allCustomers.Free;
   end;    
end.

