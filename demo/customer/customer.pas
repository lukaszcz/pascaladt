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
      constructor Create(aFirstName, aSurname, aAddress : String); overload;
      constructor Create(aFirstName, aSurname : String); overload;
      destructor Destroy; override;

      property FirstName : String read FFirstName write FFirstName;
      property Surname : String read FSurname write FSurname;
      property Address : String read FAddress write FAddress;
      property Orders : TListAdt read FOrders;
   end;

   TOrder = class
   public
      orderId : Cardinal;
      productName, price : String;
      customer : TCustomer;
   end;

   TCustomerComparer = class (TFunctor, IBinaryComparer)
   public
      function Compare(obj1, obj2 : TObject) : Integer;
   end;

   TCustomerHasher = class (TFunctor, IHasher)
   public
      function Hash(obj : TObject) : UnsignedType;
   end;

   TOrderComparer = class (TFunctor, IBinaryComparer)
   public
      function Compare(obj1, obj2 : TObject) : Integer;
   end;

   TOrderCustomerComparer = class (TFunctor, IBinaryComparer)
   public
      function Compare(obj1, obj2 : TObject) : Integer;
   end;

   TOrderProductComparer = class (TFunctor, IUnaryPredicate)
   private
      FProduct : String;
   public
      constructor Create(product : String);
      function Test(obj : TObject) : Boolean;
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
   FOrders.OwnsItems := False;
end;

constructor TCustomer.Create(aFirstName, aSurname : String);
begin
   FirstName := aFirstName;
   Surname := aSurname;
   FAddress := '';
   FOrders := nil;
end;

destructor TCustomer.Destroy;
begin
   FOrders.Free
end;

{ -------------------- functors --------------------- }

function TCustomerComparer.Compare(obj1, obj2 : TObject) : Integer;
begin
   Result := CompareCustomers(TCustomer(obj1), TCustomer(obj2));
end;

function TCustomerHasher.Hash(obj : TObject) : UnsignedType;
var
   nameStr : AnsiString;
begin
   nameStr := TCustomer(obj).FirstName + TCustomer(obj).Surname;
   Result := FNVHash(PChar(nameStr), Length(nameStr));
end;

function TOrderComparer.Compare(obj1, obj2 : TObject) : Integer;
begin
   Result := TOrder(obj1).orderId - TOrder(obj2).orderId;
end;

function TOrderCustomerComparer.Compare(obj1, obj2 : TObject) : Integer;
begin
   Result := CompareCustomers(TOrder(obj1).Customer, TOrder(obj2).Customer);
end;

constructor TOrderProductComparer.Create(product : String);
begin
   FProduct := product;
end;

function TOrderProductComparer.Test(obj : TObject) : Boolean;
begin
   Result := CompareStr(TOrder(obj).ProductName, FProduct) = 0;
end;


{ --------------------- routines ---------------------- }

procedure PrintOrderWithoutCustomerInfo(obj : TObject);
var
   order : TOrder;
begin
   Assert(obj is TOrder);
   order := TOrder(obj);
   with order do
   begin
      WriteLn;
      WriteLn('Order ID: ', orderId);
      WriteLn('Product name: ', productName);
      WriteLn('Price: ', price);
   end;
end;

procedure PrintOrder(obj : TObject);
var
   order : TOrder;
begin
   Assert(obj is TOrder);
   order := TOrder(obj);
   PrintOrderWithoutCustomerInfo(order);
   with order do
   begin
      WriteLn('Customer name: ', customer.FirstName, ' ', customer.Surname);
      WriteLn('Customer address: ', customer.Address);
   end;
end;

procedure PrintCustomer(obj : TObject);
var
   customer : TCustomer;
begin
   Assert(obj is TCustomer);
   customer := TCustomer(obj);
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

procedure PrintCustomerName(obj : TObject);
var
   customer : TCustomer;
begin
   Assert(obj is TCustomer);
   customer := TCustomer(obj);
   WriteLn(customer.Surname, ' ', customer.FirstName);
end;

procedure PrintCustomers;
var
   buff : TPascalArrayType;
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
   { It is necessary to indicate that a should not destroy its items.
     By default all containers own their items. }
   a.OwnsItems := false;
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
   customerKey : TCustomer;
   customer : TCustomer;
begin
   customerKey := TCustomer.Create(firstName, surname);
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
   customerKey : TCustomer;
   orderKey : TOrder;
   iter : TForwardIterator;
   customer : TCustomer;
   i : Integer;
begin
   customerKey := TCustomer.Create(firstName, surname);
   orderKey := TOrder.Create;
   try
      customer := TCustomer(allCustomers.Find(customerKey));
      if customer <> nil then
      begin
         { remove the orders associated with the customer as well }
         iter := customer.Orders.ForwardStart;
         while not iter.IsFinish do
         begin
            orderKey.orderId := TOrder(iter.Item).orderId;
            allOrders.Delete(orderKey);
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
      orderKey.Free;
   end;
end;

procedure FindOrder(orderId : Cardinal);
var
   order : TOrder;
   orderKey : TOrder;
begin
   orderKey := TOrder.Create;
   try
      orderKey.orderId := orderId;
      order := TOrder(allOrders.Find(orderKey));
      if order <> nil then
      begin
         PrintOrder(order);
      end else
      begin
         WriteLn('Invalid order ID.');
      end;
   finally
      orderKey.Free;
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
   order : TOrder;
   surname, firstName : String;
   customerKey : TCustomer;
begin
   order := TOrder.Create;

   try
      WriteLn('Enter order data.');
      with order do
      begin
         customer := nil;
         Write('Product name: '); ReadLn(productName);
         Write('Price: '); ReadLn(price);
      end;
      Write('Customer first name: '); ReadLn(firstName);
      Write('Customer surname: '); ReadLn(surname);

      { check if the specified customer is present in the database }
      customerKey := TCustomer.Create(firstName, surname);
      try
         order.customer := TCustomer(allCustomers.Find(customerKey));
      finally
         customerKey.Free;
      end;

      if order.customer <> nil then
      begin
         order.orderId := unusedOrderId;
         Inc(unusedOrderId);
         order.customer.Orders.PushBack(order);
         if not allOrders.Insert(order) then
            WriteLn('Error! Impossible!');
         WriteLn('Order successfully added.');
         WriteLn('Order ID: ', order.orderId);
      end else
      begin
         order.Destroy;
         WriteLn('Invalid customer specified.');
      end;
   except
      { if an exception occurs the order is not automatically destroyed
        (even if it occurs in allOrders.Insert) }
      order.Destroy;
      raise;
   end;
end;

procedure RemoveOrder(orderId : Cardinal);
var
   order : TOrder;
   orderKey : TOrder;
   comparer : IBinaryComparer;
begin
   orderKey := TOrder.Create;
   try
      orderKey.orderId := orderId;
      order := TOrder(allOrders.Find(orderKey));
      if order <> nil then
      begin
         { remove the order from the list of the customer associated with
           it }
         comparer := TOrderComparer.Create;
         DeleteIf(order.customer.Orders.ForwardStart, MAXINT,
                  EqualTo(comparer, order));

         { remove the order itself }
         if allOrders.Delete(orderKey) = 0 then
            WriteLn('Error! Impossible!');

         WriteLn('Order ', orderId, ' successfully removed.');
      end else
      begin
         WriteLn('Invaid order ID.');
      end;
   finally
      orderKey.Destroy;
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
      allOrders := TAvlTree.Create;
      allOrders.ItemComparer := TOrderComparer.Create;
      allCustomers := THashTable.Create;
      allCustomers.Hasher := TCustomerHasher.Create;
      allCustomers.ItemComparer := TCustomerComparer.Create;
      unusedOrderId := 0;

      Run;

   finally
      allOrders.Free;
      allCustomers.Free;
   end;
end.
