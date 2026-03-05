public with sharing class BikeShopLwcController {
    public class PagedResult {
        @AuraEnabled public Integer page;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer total;
        @AuraEnabled public List<SObject> records;
    }

    private static Integer normalizePage(Integer pageNumber) {
        if (pageNumber == null || pageNumber < 1) {
            return 1;
        }
        return pageNumber;
    }

    private static Integer normalizePageSize(Integer pageSize) {
        if (pageSize == null || pageSize < 1) {
            return 10;
        }
        return pageSize > 100 ? 100 : pageSize;
    }

    @AuraEnabled(cacheable=true)
    public static PagedResult getBikes(Integer pageNumber, Integer pageSize, String search) {
        Integer page = normalizePage(pageNumber);
        Integer size = normalizePageSize(pageSize);
        Integer offsetRows = (page - 1) * size;

        List<Bike__c> rows;
        Integer total;

        if (String.isBlank(search)) {
            total = [SELECT COUNT() FROM Bike__c];
            rows = [
                SELECT Id, Name, Model__c, Brand__c, Category__c,
                       Daily_Rate__c, Available__c, Mileage__c,
                       Last_Service_Date__c
                FROM Bike__c
                ORDER BY CreatedDate DESC
                LIMIT :size
                OFFSET :offsetRows
            ];
        } else {
            String likeSearch = '%' + search + '%';
            total = [
                SELECT COUNT()
                FROM Bike__c
                WHERE Name LIKE :likeSearch
                   OR Model__c LIKE :likeSearch
                   OR Brand__c LIKE :likeSearch
            ];
            rows = [
                SELECT Id, Name, Model__c, Brand__c, Category__c,
                       Daily_Rate__c, Available__c, Mileage__c,
                       Last_Service_Date__c
                FROM Bike__c
                WHERE Name LIKE :likeSearch
                   OR Model__c LIKE :likeSearch
                   OR Brand__c LIKE :likeSearch
                ORDER BY CreatedDate DESC
                LIMIT :size
                OFFSET :offsetRows
            ];
        }

        PagedResult result = new PagedResult();
        result.page = page;
        result.pageSize = size;
        result.total = total;
        result.records = rows;
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static PagedResult getCustomers(Integer pageNumber, Integer pageSize, String search) {
        Integer page = normalizePage(pageNumber);
        Integer size = normalizePageSize(pageSize);
        Integer offsetRows = (page - 1) * size;

        List<Customer__c> rows;
        Integer total;

        if (String.isBlank(search)) {
            total = [SELECT COUNT() FROM Customer__c];
            rows = [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c,
                       Phone__c, Birth_Date__c, Loyalty_Points__c,
                       Is_Active__c
                FROM Customer__c
                ORDER BY CreatedDate DESC
                LIMIT :size
                OFFSET :offsetRows
            ];
        } else {
            String likeSearch = '%' + search + '%';
            total = [
                SELECT COUNT()
                FROM Customer__c
                WHERE First_Name__c LIKE :likeSearch
                   OR Last_Name__c LIKE :likeSearch
                   OR Email__c LIKE :likeSearch
            ];
            rows = [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c,
                       Phone__c, Birth_Date__c, Loyalty_Points__c,
                       Is_Active__c
                FROM Customer__c
                WHERE First_Name__c LIKE :likeSearch
                   OR Last_Name__c LIKE :likeSearch
                   OR Email__c LIKE :likeSearch
                ORDER BY CreatedDate DESC
                LIMIT :size
                OFFSET :offsetRows
            ];
        }

        PagedResult result = new PagedResult();
        result.page = page;
        result.pageSize = size;
        result.total = total;
        result.records = rows;
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static PagedResult getRentals(Integer pageNumber, Integer pageSize, String status) {
        Integer page = normalizePage(pageNumber);
        Integer size = normalizePageSize(pageSize);
        Integer offsetRows = (page - 1) * size;

        List<Bike_Rental__c> rows;
        Integer total;

        if (String.isBlank(status)) {
            total = [SELECT COUNT() FROM Bike_Rental__c];
            rows = [
                SELECT Id, Name, Bike__c, Bike__r.Name, Customer__c,
                       Customer__r.Name, Start_Date__c, End_Date__c,
                       Daily_Price__c, Total_Amount__c, Status__c,
                       Paid__c
                FROM Bike_Rental__c
                ORDER BY CreatedDate DESC
                LIMIT :size
                OFFSET :offsetRows
            ];
        } else {
            total = [
                SELECT COUNT()
                FROM Bike_Rental__c
                WHERE Status__c = :status
            ];
            rows = [
                SELECT Id, Name, Bike__c, Bike__r.Name, Customer__c,
                       Customer__r.Name, Start_Date__c, End_Date__c,
                       Daily_Price__c, Total_Amount__c, Status__c,
                       Paid__c
                FROM Bike_Rental__c
                WHERE Status__c = :status
                ORDER BY CreatedDate DESC
                LIMIT :size
                OFFSET :offsetRows
            ];
        }

        PagedResult result = new PagedResult();
        result.page = page;
        result.pageSize = size;
        result.total = total;
        result.records = rows;
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static PagedResult searchRentals(Integer pageNumber, Integer pageSize, String searchText, String status) {
        Integer page = normalizePage(pageNumber);
        Integer size = normalizePageSize(pageSize);
        Integer offsetRows = (page - 1) * size;

        List<Bike_Rental__c> rows;
        Integer total;
        
        String searchPattern = '%' + (String.isBlank(searchText) ? '' : searchText.trim()) + '%';
        
        // Build WHERE clause dynamically
        String whereClause = '(Bike__r.Name LIKE :searchPattern OR Customer__r.Name LIKE :searchPattern OR Name LIKE :searchPattern)';
        
        if (!String.isBlank(status)) {
            whereClause += ' AND Status__c = :status';
        }
        
        // Count total matching records
        String countQuery = 'SELECT COUNT() FROM Bike_Rental__c WHERE ' + whereClause;
        total = Database.countQuery(countQuery);
        
        // Fetch paginated records
        String queryString = 'SELECT Id, Name, Bike__c, Bike__r.Name, Customer__c, ' +
                            'Customer__r.Name, Start_Date__c, End_Date__c, ' +
                            'Daily_Price__c, Total_Amount__c, Status__c, ' +
                            'Paid__c ' +
                            'FROM Bike_Rental__c ' +
                            'WHERE ' + whereClause + ' ' +
                            'ORDER BY CreatedDate DESC ' +
                            'LIMIT :size OFFSET :offsetRows';
        
        rows = Database.query(queryString);

        PagedResult result = new PagedResult();
        result.page = page;
        result.pageSize = size;
        result.total = total;
        result.records = rows;
        return result;
    }

    @AuraEnabled
    public static Bike__c saveBike(Map<String, Object> payload) {
        if (payload == null) {
            payload = new Map<String, Object>();
        }

        Id recordId = payload.containsKey('Id') ? (Id) String.valueOf(payload.get('Id')) : null;
        Bike__c bike;

        if (recordId == null) {
            bike = new Bike__c();
        } else {
            bike = [
                SELECT Id, Name, Model__c, Brand__c, Category__c,
                       Daily_Rate__c, Available__c, Mileage__c,
                       Last_Service_Date__c
                FROM Bike__c
                WHERE Id = :recordId
                LIMIT 1
            ];
        }

        if (payload.containsKey('Name')) bike.Name = String.valueOf(payload.get('Name'));
        if (payload.containsKey('Model__c')) bike.Model__c = String.valueOf(payload.get('Model__c'));
        if (payload.containsKey('Brand__c')) bike.Brand__c = String.valueOf(payload.get('Brand__c'));
        if (payload.containsKey('Category__c')) bike.Category__c = String.valueOf(payload.get('Category__c'));
        if (payload.containsKey('Daily_Rate__c') && payload.get('Daily_Rate__c') != null) bike.Daily_Rate__c = Decimal.valueOf(String.valueOf(payload.get('Daily_Rate__c')));
        if (payload.containsKey('Available__c')) bike.Available__c = (Boolean) payload.get('Available__c');
        if (payload.containsKey('Mileage__c') && payload.get('Mileage__c') != null) bike.Mileage__c = Integer.valueOf(String.valueOf(payload.get('Mileage__c')));
        if (payload.containsKey('Last_Service_Date__c') && payload.get('Last_Service_Date__c') != null) bike.Last_Service_Date__c = Date.valueOf(String.valueOf(payload.get('Last_Service_Date__c')));

        if (String.isBlank(bike.Name) && !String.isBlank(bike.Brand__c) && !String.isBlank(bike.Model__c)) {
            bike.Name = bike.Brand__c + ' ' + bike.Model__c;
        }

        upsert bike;
        return bike;
    }

    @AuraEnabled
    public static void deleteBike(Id bikeId) {
        delete [SELECT Id FROM Bike__c WHERE Id = :bikeId LIMIT 1];
    }

    @AuraEnabled
    public static Customer__c saveCustomer(Map<String, Object> payload) {
        if (payload == null) {
            payload = new Map<String, Object>();
        }

        Id recordId = payload.containsKey('Id') ? (Id) String.valueOf(payload.get('Id')) : null;
        Customer__c customer;

        if (recordId == null) {
            customer = new Customer__c();
        } else {
            customer = [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c,
                       Phone__c, Birth_Date__c, Loyalty_Points__c,
                       Is_Active__c
                FROM Customer__c
                WHERE Id = :recordId
                LIMIT 1
            ];
        }

        if (payload.containsKey('Name')) customer.Name = String.valueOf(payload.get('Name'));
        if (payload.containsKey('First_Name__c')) customer.First_Name__c = String.valueOf(payload.get('First_Name__c'));
        if (payload.containsKey('Last_Name__c')) customer.Last_Name__c = String.valueOf(payload.get('Last_Name__c'));
        if (payload.containsKey('Email__c')) customer.Email__c = String.valueOf(payload.get('Email__c'));
        if (payload.containsKey('Phone__c')) customer.Phone__c = String.valueOf(payload.get('Phone__c'));
        if (payload.containsKey('Birth_Date__c') && payload.get('Birth_Date__c') != null) customer.Birth_Date__c = Date.valueOf(String.valueOf(payload.get('Birth_Date__c')));
        if (payload.containsKey('Loyalty_Points__c') && payload.get('Loyalty_Points__c') != null) customer.Loyalty_Points__c = Integer.valueOf(String.valueOf(payload.get('Loyalty_Points__c')));
        if (payload.containsKey('Is_Active__c')) customer.Is_Active__c = (Boolean) payload.get('Is_Active__c');

        if (String.isBlank(customer.Name) && !String.isBlank(customer.First_Name__c) && !String.isBlank(customer.Last_Name__c)) {
            customer.Name = customer.First_Name__c + ' ' + customer.Last_Name__c;
        }

        // Validate email uniqueness
        if (!String.isBlank(customer.Email__c)) {
            String email = customer.Email__c.toLowerCase();
            List<Customer__c> existingCustomers = [
                SELECT Id FROM Customer__c 
                WHERE Email__c = :customer.Email__c
                AND Id != :customer.Id
                LIMIT 1
            ];
            if (!existingCustomers.isEmpty()) {
                throw new AuraHandledException('Email already exists. Please use a different email address.');
            }
        }

        upsert customer;
        return customer;
    }

    @AuraEnabled
    public static void deleteCustomer(Id customerId) {
        delete [SELECT Id FROM Customer__c WHERE Id = :customerId LIMIT 1];
    }

    @AuraEnabled
    public static Bike_Rental__c saveRental(Map<String, Object> payload) {
        if (payload == null) {
            payload = new Map<String, Object>();
        }

        Id recordId = payload.containsKey('Id') ? (Id) String.valueOf(payload.get('Id')) : null;
        Bike_Rental__c rental;

        if (recordId == null) {
            rental = new Bike_Rental__c();
        } else {
            rental = [
                SELECT Id, Bike__c, Customer__c, Start_Date__c,
                       End_Date__c, Daily_Price__c, Total_Amount__c,
                       Status__c, Paid__c
                FROM Bike_Rental__c
                WHERE Id = :recordId
                LIMIT 1
            ];
        }

        if (payload.containsKey('Bike__c')) rental.Bike__c = (Id) String.valueOf(payload.get('Bike__c'));
        if (payload.containsKey('Customer__c')) rental.Customer__c = (Id) String.valueOf(payload.get('Customer__c'));
        
        // Парсиране на дати - получаваме YYYY-MM-DDTHH:MM:SSZ от JavaScript
        if (payload.containsKey('Start_Date__c') && payload.get('Start_Date__c') != null) {
            String startDateStr = String.valueOf(payload.get('Start_Date__c')).trim();
            System.debug('DEBUG: Received Start Date String: ' + startDateStr);
            // Вземи само датата (YYYY-MM-DD) игнорирай време и Z
            if (startDateStr.contains('T')) {
                startDateStr = startDateStr.split('T')[0];
            }
            System.debug('DEBUG: Parsed Start Date String: ' + startDateStr);
            rental.Start_Date__c = Date.valueOf(startDateStr);
            System.debug('DEBUG: Converted Start Date: ' + rental.Start_Date__c);
        }
        if (payload.containsKey('End_Date__c') && payload.get('End_Date__c') != null) {
            String endDateStr = String.valueOf(payload.get('End_Date__c')).trim();
            System.debug('DEBUG: Received End Date String: ' + endDateStr);
            // Вземи само датата (YYYY-MM-DD) игнорирай време и Z
            if (endDateStr.contains('T')) {
                endDateStr = endDateStr.split('T')[0];
            }
            System.debug('DEBUG: Parsed End Date String: ' + endDateStr);
            rental.End_Date__c = Date.valueOf(endDateStr);
            System.debug('DEBUG: Converted End Date: ' + rental.End_Date__c);
        }
        
        if (payload.containsKey('Daily_Price__c') && payload.get('Daily_Price__c') != null) rental.Daily_Price__c = Decimal.valueOf(String.valueOf(payload.get('Daily_Price__c')));
        if (payload.containsKey('Status__c')) rental.Status__c = String.valueOf(payload.get('Status__c'));
        if (payload.containsKey('Paid__c')) rental.Paid__c = (Boolean) payload.get('Paid__c');

        if (rental.Start_Date__c != null && rental.End_Date__c != null && rental.Daily_Price__c != null) {
            Integer rentalDays = rental.Start_Date__c.daysBetween(rental.End_Date__c) + 1;
            rental.Total_Amount__c = rental.Daily_Price__c * rentalDays;
        }

        upsert rental;
        return rental;
    }

    @AuraEnabled
    public static void deleteRental(Id rentalId) {
        delete [SELECT Id FROM Bike_Rental__c WHERE Id = :rentalId LIMIT 1];
    }

    @AuraEnabled
    public static List<Map<String, String>> getBikeOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        List<Bike__c> bikes = [
            SELECT Id, Name, Daily_Rate__c 
            FROM Bike__c 
            WHERE Available__c = true
            ORDER BY Name ASC
        ];
        for (Bike__c bike : bikes) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', bike.Name);
            option.put('value', bike.Id);
            option.put('dailyRate', String.valueOf(bike.Daily_Rate__c));
            options.add(option);
        }
        return options;
    }

    @AuraEnabled
    public static List<Map<String, String>> getCustomerOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        List<Customer__c> customers = [
            SELECT Id, Name 
            FROM Customer__c 
            WHERE Is_Active__c = true
            ORDER BY Name ASC
        ];
        for (Customer__c customer : customers) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', customer.Name);
            option.put('value', customer.Id);
            options.add(option);
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> checkBikeAvailability(Id bikeId, Date startDate, Date endDate, Id excludeRentalId) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('isAvailable', true);
        result.put('conflictingRentals', new List<Map<String, Object>>());
        
        if (bikeId == null || startDate == null || endDate == null) {
            return result;
        }
        
        // Check for overlapping rentals with the same bike
        List<Bike_Rental__c> conflicts = [
            SELECT Id, Name, Start_Date__c, End_Date__c,
                   Customer__r.Name
            FROM Bike_Rental__c
            WHERE Bike__c = :bikeId
            AND Start_Date__c <= :endDate
            AND End_Date__c >= :startDate
            AND Status__c != 'Cancelled'
        ];
        
        // Filter out the excluded rental if provided
        if (excludeRentalId != null) {
            List<Bike_Rental__c> filteredConflicts = new List<Bike_Rental__c>();
            for (Bike_Rental__c rental : conflicts) {
                if (rental.Id != excludeRentalId) {
                    filteredConflicts.add(rental);
                }
            }
            conflicts = filteredConflicts;
        }
        
        if (!conflicts.isEmpty()) {
            result.put('isAvailable', false);
            List<Map<String, Object>> conflictList = new List<Map<String, Object>>();
            for (Bike_Rental__c rental : conflicts) {
                Map<String, Object> conflict = new Map<String, Object>();
                conflict.put('rentalId', rental.Id);
                conflict.put('rentalName', rental.Name);
                conflict.put('startDate', rental.Start_Date__c);
                conflict.put('endDate', rental.End_Date__c);
                conflict.put('customerName', rental.Customer__r.Name);
                conflictList.add(conflict);
            }
            result.put('conflictingRentals', conflictList);
        }
        
        return result;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getStatusOptions() {
        List<String> statusOptions = new List<String>();
        statusOptions.add('Draft');
        statusOptions.add('Active');
        statusOptions.add('Completed');
        statusOptions.add('Cancelled');
        return statusOptions;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getBikeCategoryOptions() {
        List<String> categoryOptions = new List<String>();
        // Get picklist values from the Bike Category field
        Schema.DescribeFieldResult fieldResult = Bike__c.Category__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistEntries) {
            categoryOptions.add(entry.getValue());
        }
        return categoryOptions;
    }
}

