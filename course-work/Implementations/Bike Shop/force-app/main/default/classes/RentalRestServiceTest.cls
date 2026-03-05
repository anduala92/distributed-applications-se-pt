/**
 * Unit tests for RentalRestService REST API
 * Tests GET, POST, PATCH, DELETE operations for Rentals
 */
@IsTest
private class RentalRestServiceTest {
    
    @TestSetup
    static void setupData() {
        Bike__c bike = new Bike__c(
            Name = 'Test Bike',
            Model__c = 'Model X',
            Brand__c = 'Brand X',
            Category__c = 'Road',
            Daily_Rate__c = 50,
            Available__c = true
        );
        insert bike;
        
        Customer__c customer = new Customer__c(
            Name = 'Test Customer',
            First_Name__c = 'Test',
            Last_Name__c = 'Customer',
            Email__c = 'test@example.com',
            Is_Active__c = true
        );
        insert customer;
        
        Bike_Rental__c rental = new Bike_Rental__c(
            Bike__c = bike.Id,
            Customer__c = customer.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(3),
            Daily_Price__c = 50,
            Total_Amount__c = 200,
            Status__c = 'Active',
            Paid__c = false
        );
        insert rental;
    }
    
    @IsTest
    static void testGetRentals_WithoutFilter_ReturnsAllRentals() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'GET';
        req.addParameter('page', '1');
        req.addParameter('pageSize', '10');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalListResponseDto response = RentalRestService.getRentals();
        
        System.assertEquals(1, response.total);
        System.assert(response.records != null);
    }
    
    @IsTest
    static void testGetRentals_FilterByStatus_ReturnsFiltered() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'GET';
        req.addParameter('status', 'Active');
        req.addParameter('page', '1');
        req.addParameter('pageSize', '10');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalListResponseDto response = RentalRestService.getRentals();
        
        System.assertEquals(1, response.total);
        System.assertEquals(1, response.records.size());
    }
    
    @IsTest
    static void testGetRentals_FilterByStatusNoMatch_ReturnsEmpty() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'GET';
        req.addParameter('status', 'Cancelled');
        req.addParameter('page', '1');
        req.addParameter('pageSize', '10');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalListResponseDto response = RentalRestService.getRentals();
        
        System.assertEquals(0, response.total);
    }
    
    @IsTest
    static void testGetRentals_FilterByCustomer_ReturnsFiltered() {
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'GET';
        req.addParameter('customerId', customer.Id);
        req.addParameter('page', '1');
        req.addParameter('pageSize', '10');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalListResponseDto response = RentalRestService.getRentals();
        
        System.assertEquals(1, response.total);
    }
    
    @IsTest
    static void testGetRentals_FilterByBoth_ReturnsFiltered() {
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'GET';
        req.addParameter('status', 'Active');
        req.addParameter('customerId', customer.Id);
        req.addParameter('page', '1');
        req.addParameter('pageSize', '10');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalListResponseDto response = RentalRestService.getRentals();
        
        System.assertEquals(1, response.total);
    }
    
    @IsTest
    static void testGetRentals_Pagination() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        // Create additional rentals
        List<Bike_Rental__c> rentals = new List<Bike_Rental__c>();
        for (Integer i = 0; i < 10; i++) {
            rentals.add(new Bike_Rental__c(
                Bike__c = bike.Id,
                Customer__c = customer.Id,
                Start_Date__c = Date.today().addDays(i),
                End_Date__c = Date.today().addDays(i + 2),
                Daily_Price__c = 50,
                Total_Amount__c = 150,
                Status__c = 'Draft',
                Paid__c = false
            ));
        }
        insert rentals;
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'GET';
        req.addParameter('page', '1');
        req.addParameter('pageSize', '5');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalListResponseDto response = RentalRestService.getRentals();
        
        System.assertEquals(5, response.records.size());
        System.assertEquals(11, response.total); // 10 new + 1 from setup
    }
    
    @IsTest
    static void testCreateRental_WithValidData_CreatesSuccessfully() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{' +
            '"Bike__c":"' + bike.Id + '",' +
            '"Customer__c":"' + customer.Id + '",' +
            '"Start_Date__c":"2026-03-10",' +
            '"End_Date__c":"2026-03-13",' +
            '"Daily_Price__c":50,' +
            '"Status__c":"Draft"' +
        '}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalDto createdRental = RentalRestService.createRental();
        
        System.assertNotEquals(null, createdRental.id);
        System.assertEquals(bike.Id, createdRental.bikeId);
        System.assertEquals(customer.Id, createdRental.customerId);
        System.assertEquals(200, createdRental.totalAmount); // 4 days * 50
        System.assertEquals(201, RestContext.response.statusCode);
    }
    
    @IsTest
    static void testCreateRental_WithMissingBike_FailsValidation() {
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{' +
            '"Customer__c":"' + customer.Id + '",' +
            '"Start_Date__c":"2026-03-10",' +
            '"End_Date__c":"2026-03-13",' +
            '"Daily_Price__c":50,' +
            '"Status__c":"Draft"' +
        '}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalRestService.createRental();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.assert(errorResponse.containsKey('error'));
        System.assert(((String) errorResponse.get('error')).contains('Bike'));
    }
    
    @IsTest
    static void testCreateRental_WithMissingCustomer_FailsValidation() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{' +
            '"Bike__c":"' + bike.Id + '",' +
            '"Start_Date__c":"2026-03-10",' +
            '"End_Date__c":"2026-03-13",' +
            '"Daily_Price__c":50,' +
            '"Status__c":"Draft"' +
        '}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalRestService.createRental();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.assert(errorResponse.containsKey('error'));
        System.assert(((String) errorResponse.get('error')).contains('Customer'));
    }
    
    @IsTest
    static void testCreateRental_WithEndDateBeforeStart_FailsValidation() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{' +
            '"Bike__c":"' + bike.Id + '",' +
            '"Customer__c":"' + customer.Id + '",' +
            '"Start_Date__c":"2026-03-13",' +
            '"End_Date__c":"2026-03-10",' +
            '"Daily_Price__c":50,' +
            '"Status__c":"Draft"' +
        '}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalRestService.createRental();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.assert(errorResponse.containsKey('error'));
        System.assert(((String) errorResponse.get('error')).contains('End Date'));
    }
    
    @IsTest
    static void testCreateRental_WithNegativePrice_FailsValidation() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{' +
            '"Bike__c":"' + bike.Id + '",' +
            '"Customer__c":"' + customer.Id + '",' +
            '"Start_Date__c":"2026-03-10",' +
            '"End_Date__c":"2026-03-13",' +
            '"Daily_Price__c":-50,' +
            '"Status__c":"Draft"' +
        '}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalRestService.createRental();
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        System.assert(errorResponse.containsKey('error'));
        System.assert(((String) errorResponse.get('error')).contains('negative'));
    }
    
    @IsTest
    static void testUpdateRental_WithValidData_UpdatesSuccessfully() {
        Bike_Rental__c rental = [SELECT Id FROM Bike_Rental__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals/' + rental.Id;
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf('{' +
            '"Status__c":"Completed",' +
            '"Paid__c":true' +
        '}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalDto updatedRental = RentalRestService.updateRental();
        
        System.assertEquals('Completed', updatedRental.status);
        System.assertEquals(true, updatedRental.paid);
    }
    
    @IsTest
    static void testDeleteRental_WithValidId_DeletesSuccessfully() {
        Bike_Rental__c rental = [SELECT Id FROM Bike_Rental__c LIMIT 1];
        Id rentalId = rental.Id;
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals/' + rentalId;
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalRestService.deleteRental();
        
        List<Bike_Rental__c> deletedRentals = [SELECT Id FROM Bike_Rental__c WHERE Id = :rentalId];
        System.assertEquals(0, deletedRentals.size());
    }
    
    @IsTest
    static void testCreateRental_CalculatesTotalAmount_Correctly() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Customer__c customer = [SELECT Id FROM Customer__c LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/bikeshop/v1/rentals';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{' +
            '"Bike__c":"' + bike.Id + '",' +
            '"Customer__c":"' + customer.Id + '",' +
            '"Start_Date__c":"2026-03-10",' +
            '"End_Date__c":"2026-03-17",' +
            '"Daily_Price__c":100,' +
            '"Status__c":"Draft"' +
        '}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        RentalDto createdRental = RentalRestService.createRental();
        
        // 8 days (10-17 inclusive) * 100 = 800
        System.assertEquals(800, createdRental.totalAmount);
    }
}
