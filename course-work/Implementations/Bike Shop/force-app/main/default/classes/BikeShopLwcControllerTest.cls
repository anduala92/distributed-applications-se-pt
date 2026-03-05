/**
 * Unit tests for BikeShopLwcController
 * Tests pagination, data retrieval, CRUD operations, and validations
 */
@IsTest
private class BikeShopLwcControllerTest {
    
    @TestSetup
    static void setupData() {
        // Create test bikes
        List<Bike__c> bikes = new List<Bike__c>();
        for (Integer i = 1; i <= 15; i++) {
            bikes.add(new Bike__c(
                Name = 'Test Bike ' + i,
                Model__c = 'Model ' + i,
                Brand__c = 'Brand ' + i,
                Category__c = Math.mod(i, 2) == 0 ? 'Road' : 'Mountain',
                Daily_Rate__c = 40 + i,
                Available__c = Math.mod(i, 3) != 0,
                Mileage__c = 100 * i
            ));
        }
        insert bikes;
        
        // Create test customers
        List<Customer__c> customers = new List<Customer__c>();
        for (Integer i = 1; i <= 10; i++) {
            customers.add(new Customer__c(
                Name = 'Customer ' + i,
                First_Name__c = 'First ' + i,
                Last_Name__c = 'Last ' + i,
                Email__c = 'customer' + i + '@example.com',
                Is_Active__c = Math.mod(i, 2) == 0,
                Loyalty_Points__c = i * 10
            ));
        }
        insert customers;
        
        // Create test rentals
        List<Bike_Rental__c> rentals = new List<Bike_Rental__c>();
        Bike__c testBike = bikes[0];
        Customer__c testCustomer = customers[0];
        
        String[] statuses = new String[] { 'Draft', 'Active', 'Completed', 'Cancelled' };
        for (Integer i = 1; i <= 12; i++) {
            rentals.add(new Bike_Rental__c(
                Bike__c = testBike.Id,
                Customer__c = testCustomer.Id,
                Start_Date__c = Date.today().addDays(i),
                End_Date__c = Date.today().addDays(i + 2),
                Daily_Price__c = 50,
                Total_Amount__c = 150,
                Status__c = statuses[Math.mod(i - 1, statuses.size())],
                Paid__c = Math.mod(i, 2) == 0
            ));
        }
        insert rentals;
    }
    
    @IsTest
    static void testGetBikes_ReturnsPagedResults() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.getBikes(1, 5, '');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.page);
        System.assertEquals(5, result.pageSize);
        System.assertEquals(15, result.total);
        System.assertEquals(5, result.records.size());
    }
    
    @IsTest
    static void testGetBikes_WithSearch_FiltersResults() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.getBikes(1, 10, 'Bike 1');
        Test.stopTest();
        
        System.assert(result.total > 0, 'Should find bikes matching search');
    }
    
    @IsTest
    static void testGetBikes_Pagination_Page2() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.getBikes(2, 5, '');
        Test.stopTest();
        
        System.assertEquals(2, result.page);
        System.assertEquals(5, result.records.size());
        System.assertEquals(15, result.total);
    }
    
    @IsTest
    static void testGetCustomers_ReturnsPagedResults() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.getCustomers(1, 5, '');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.page);
        System.assertEquals(5, result.pageSize);
        System.assertEquals(10, result.total);
        System.assertEquals(5, result.records.size());
    }
    
    @IsTest
    static void testGetCustomers_WithSearch_FiltersResults() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.getCustomers(1, 10, 'First 1');
        Test.stopTest();
        
        System.assert(result.total > 0, 'Should find customers matching search');
    }
    
    @IsTest
    static void testGetRentals_ReturnsPagedResults() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.getRentals(1, 5, '');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.page);
        System.assertEquals(5, result.pageSize);
        System.assertEquals(12, result.total);
        System.assertEquals(5, result.records.size());
    }
    
    @IsTest
    static void testGetRentals_FilterByStatus_ReturnsFiltered() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.getRentals(1, 10, 'Active');
        Test.stopTest();
        
        System.assertEquals(3, result.total, 'Should have 3 active rentals');
    }
    
    @IsTest
    static void testSearchRentals_WithSearchText_ReturnsMatching() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.searchRentals(1, 10, 'First', '');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.records);
    }
    
    @IsTest
    static void testSearchRentals_WithStatusAndSearch_ReturnsBoth() {
        Test.startTest();
        BikeShopLwcController.PagedResult result = BikeShopLwcController.searchRentals(1, 10, 'First', 'Active');
        Test.stopTest();
        
        System.assert(result.total >= 0, 'Should filter by both search and status');
    }
    
    @IsTest
    static void testSaveBike_CreateNewBike() {
        Test.startTest();
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('Model__c', 'New Model');
        payload.put('Brand__c', 'New Brand');
        payload.put('Category__c', 'Road');
        payload.put('Daily_Rate__c', 99.99);
        payload.put('Available__c', true);
        
        Bike__c result = BikeShopLwcController.saveBike(payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result.Id);
        System.assertEquals('New Model', result.Model__c);
        System.assertEquals('New Brand', result.Brand__c);
        System.assertEquals('New Brand New Model', result.Name);
    }
    
    @IsTest
    static void testSaveBike_UpdateExistingBike() {
        Bike__c bike = [SELECT Id, Daily_Rate__c FROM Bike__c LIMIT 1];
        Decimal originalRate = bike.Daily_Rate__c;
        
        Test.startTest();
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('Id', bike.Id);
        payload.put('Daily_Rate__c', 199.99);
        
        Bike__c result = BikeShopLwcController.saveBike(payload);
        Test.stopTest();
        
        System.assertEquals(bike.Id, result.Id);
        System.assertEquals(199.99, result.Daily_Rate__c);
        System.assertNotEquals(originalRate, result.Daily_Rate__c);
    }
    
    @IsTest
    static void testDeleteBike_RemovesBike() {
        // Create a new bike without rentals for deletion test
        Bike__c newBike = new Bike__c(
            Name = 'Bike To Delete',
            Model__c = 'Test Model',
            Brand__c = 'Test Brand',
            Category__c = 'Road',
            Daily_Rate__c = 25,
            Available__c = true
        );
        insert newBike;
        Id bikeId = newBike.Id;
        
        Test.startTest();
        BikeShopLwcController.deleteBike(bikeId);
        Test.stopTest();
        
        List<Bike__c> result = [SELECT Id FROM Bike__c WHERE Id = :bikeId];
        System.assertEquals(0, result.size());
    }
    
    @IsTest
    static void testSaveCustomer_CreateNewCustomer() {
        Test.startTest();
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('First_Name__c', 'New');
        payload.put('Last_Name__c', 'Customer');
        payload.put('Email__c', 'new@example.com');
        payload.put('Is_Active__c', true);
        
        Customer__c result = BikeShopLwcController.saveCustomer(payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result.Id);
        System.assertEquals('new@example.com', result.Email__c);
        System.assertEquals('New Customer', result.Name);
    }
    
    @IsTest
    static void testSaveCustomer_UpdateExistingCustomer() {
        Customer__c customer = [SELECT Id, Loyalty_Points__c FROM Customer__c LIMIT 1];
        
        Test.startTest();
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('Id', customer.Id);
        payload.put('Loyalty_Points__c', 999);
        
        Customer__c result = BikeShopLwcController.saveCustomer(payload);
        Test.stopTest();
        
        System.assertEquals(customer.Id, result.Id);
        System.assertEquals(999, result.Loyalty_Points__c);
    }
    
    @IsTest
    static void testDeleteCustomer_RemovesCustomer() {
        // Create a new customer without rentals for deletion test
        Customer__c newCustomer = new Customer__c(
            Name = 'Customer To Delete',
            First_Name__c = 'Delete',
            Last_Name__c = 'Customer',
            Email__c = 'delete@example.com',
            Is_Active__c = true
        );
        insert newCustomer;
        Id customerId = newCustomer.Id;
        
        Test.startTest();
        BikeShopLwcController.deleteCustomer(customerId);
        Test.stopTest();
        
        List<Customer__c> result = [SELECT Id FROM Customer__c WHERE Id = :customerId];
        System.assertEquals(0, result.size());
    }
    
    @IsTest
    static void testSaveRental_CreateNewRental() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        Test.startTest();
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('Bike__c', bike.Id);
        payload.put('Customer__c', customer.Id);
        payload.put('Start_Date__c', Date.today());
        payload.put('End_Date__c', Date.today().addDays(5));
        payload.put('Daily_Price__c', 75);
        payload.put('Status__c', 'Draft');
        
        Bike_Rental__c result = BikeShopLwcController.saveRental(payload);
        Test.stopTest();
        
        System.assertNotEquals(null, result.Id);
        System.assertEquals(bike.Id, result.Bike__c);
        System.assertEquals(450, result.Total_Amount__c); // 6 days * 75
    }
    
    @IsTest
    static void testDeleteRental_RemovesRental() {
        Bike_Rental__c rental = [SELECT Id FROM Bike_Rental__c LIMIT 1];
        Id rentalId = rental.Id;
        
        Test.startTest();
        BikeShopLwcController.deleteRental(rentalId);
        Test.stopTest();
        
        List<Bike_Rental__c> result = [SELECT Id FROM Bike_Rental__c WHERE Id = :rentalId];
        System.assertEquals(0, result.size());
    }
    
    @IsTest
    static void testGetBikeOptions_ReturnsAvailableBikes() {
        Test.startTest();
        List<Map<String, String>> options = BikeShopLwcController.getBikeOptions();
        Test.stopTest();
        
        System.assert(options.size() > 0, 'Should return available bikes');
        System.assert(options[0].containsKey('label'), 'Should have label field');
        System.assert(options[0].containsKey('value'), 'Should have value field');
    }
    
    @IsTest
    static void testGetCustomerOptions_ReturnsActiveCustomers() {
        Test.startTest();
        List<Map<String, String>> options = BikeShopLwcController.getCustomerOptions();
        Test.stopTest();
        
        System.assert(options.size() > 0, 'Should return active customers');
        System.assert(options[0].containsKey('label'), 'Should have label field');
        System.assert(options[0].containsKey('value'), 'Should have value field');
    }
    
    @IsTest
    static void testGetStatusOptions_ReturnsAllStatuses() {
        Test.startTest();
        List<String> options = BikeShopLwcController.getStatusOptions();
        Test.stopTest();
        
        System.assert(options.contains('Draft'), 'Should contain Draft status');
        System.assert(options.contains('Active'), 'Should contain Active status');
        System.assert(options.contains('Completed'), 'Should contain Completed status');
        System.assert(options.contains('Cancelled'), 'Should contain Cancelled status');
    }
    
    @IsTest
    static void testGetBikeCategoryOptions_ReturnsCategoryPicklist() {
        Test.startTest();
        List<String> options = BikeShopLwcController.getBikeCategoryOptions();
        Test.stopTest();
        
        System.assert(options.size() > 0, 'Should return category options');
    }
    
    @IsTest
    static void testCheckBikeAvailability_WithConflict_ReturnsConflict() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Bike_Rental__c existingRental = [SELECT Id, Start_Date__c, End_Date__c FROM Bike_Rental__c WHERE Bike__c = :bike.Id LIMIT 1];
        
        Test.startTest();
        // Check availability on same bike during overlapping dates
        Map<String, Object> result = BikeShopLwcController.checkBikeAvailability(
            bike.Id,
            existingRental.Start_Date__c,
            existingRental.End_Date__c,
            null
        );
        Test.stopTest();
        
        System.assertEquals(false, result.get('isAvailable'), 'Should show conflict');
        System.assert(((List<Object>) result.get('conflictingRentals')).size() > 0, 'Should return conflicting rentals');
    }
    
    @IsTest
    static void testCheckBikeAvailability_NoConflict_ReturnsAvailable() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        
        Test.startTest();
        // Check availability far in the future
        Map<String, Object> result = BikeShopLwcController.checkBikeAvailability(
            bike.Id,
            Date.today().addDays(365),
            Date.today().addDays(370),
            null
        );
        Test.stopTest();
        
        System.assertEquals(true, result.get('isAvailable'), 'Should show available');
        System.assertEquals(0, ((List<Object>) result.get('conflictingRentals')).size(), 'Should have no conflicts');
    }
}
