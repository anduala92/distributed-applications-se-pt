@RestResource(urlMapping='/bikeshop/v1/rentals/*')
global with sharing class RentalRestService {
    @HttpGet
    global static RentalListResponseDto getRentals() {
        try {
            if (!Schema.sObjectType.Bike_Rental__c.isAccessible()) {
                throw new BikeShopApiUtil.ApiException('No read access to Rental.', 403);
            }

            Integer page = BikeShopApiUtil.getPage();
            Integer pageSize = BikeShopApiUtil.getPageSize();
            Integer offsetRows = (page - 1) * pageSize;
            String status = BikeShopApiUtil.getParam('status');
            String customerIdParam = BikeShopApiUtil.getParam('customerId');
            List<Bike_Rental__c> rows;
            Integer total;

            if (String.isBlank(status) && String.isBlank(customerIdParam)) {
                total = [SELECT COUNT() FROM Bike_Rental__c];
                rows = [
                    SELECT Id, Name, Bike__c, Bike__r.Name, Customer__c, Customer__r.Name, Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c
                    FROM Bike_Rental__c
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            } else if (!String.isBlank(status) && !String.isBlank(customerIdParam)) {
                Id customerId = (Id) customerIdParam;
                total = [SELECT COUNT() FROM Bike_Rental__c WHERE Status__c = :status AND Customer__c = :customerId];
                rows = [
                    SELECT Id, Name, Bike__c, Bike__r.Name, Customer__c, Customer__r.Name, Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c
                    FROM Bike_Rental__c
                    WHERE Status__c = :status AND Customer__c = :customerId
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            } else if (!String.isBlank(status)) {
                total = [SELECT COUNT() FROM Bike_Rental__c WHERE Status__c = :status];
                rows = [
                    SELECT Id, Name, Bike__c, Bike__r.Name, Customer__c, Customer__r.Name, Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c
                    FROM Bike_Rental__c
                    WHERE Status__c = :status
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            } else {
                Id customerId = (Id) customerIdParam;
                total = [SELECT COUNT() FROM Bike_Rental__c WHERE Customer__c = :customerId];
                rows = [
                    SELECT Id, Name, Bike__c, Bike__r.Name, Customer__c, Customer__r.Name, Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c
                    FROM Bike_Rental__c
                    WHERE Customer__c = :customerId
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            }

            List<RentalDto> rentalDtos = new List<RentalDto>();
            for (Bike_Rental__c rental : rows) {
                rentalDtos.add(new RentalDto(rental));
            }

            Map<String, Object> response = new Map<String, Object>{
                'page' => page,
                'pageSize' => pageSize,
                'total' => total,
                'records' => rentalDtos
            };
            RestContext.response.statusCode = 200;
            return (RentalListResponseDto) JSON.deserialize(JSON.serialize(response), RentalListResponseDto.class);
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpPost
    global static RentalDto createRental() {
        try {
            if (!Schema.sObjectType.Bike_Rental__c.isCreateable()) {
                throw new BikeShopApiUtil.ApiException('No create access to Rental.', 403);
            }

            Map<String, Object> body = BikeShopApiUtil.parseBody();
            Id bikeId = BikeShopApiUtil.getId(body, 'Bike__c');
            Id customerId = BikeShopApiUtil.getId(body, 'Customer__c');
            Date startDate = BikeShopApiUtil.getDate(body, 'Start_Date__c');
            Date endDate = BikeShopApiUtil.getDate(body, 'End_Date__c');
            Decimal dailyPrice = BikeShopApiUtil.getDecimal(body, 'Daily_Price__c');
            String status = BikeShopApiUtil.getString(body, 'Status__c');

            if (bikeId == null) {
                throw new BikeShopApiUtil.ApiException('Bike is required.', 400);
            }
            if (customerId == null) {
                throw new BikeShopApiUtil.ApiException('Customer is required.', 400);
            }
            if (startDate == null || endDate == null) {
                throw new BikeShopApiUtil.ApiException('Start and End dates are required.', 400);
            }
            if (endDate < startDate) {
                throw new BikeShopApiUtil.ApiException('End Date cannot be before Start Date.', 400);
            }
            BikeShopApiUtil.validatePositive(dailyPrice, 'Daily Price', true);
            BikeShopApiUtil.validateText(status, 40, 'Status', true);

            Integer rentalDays = startDate.daysBetween(endDate) + 1;
            Decimal totalAmount = dailyPrice * rentalDays;

            Bike_Rental__c rental = new Bike_Rental__c();
            rental.Bike__c = bikeId;
            rental.Customer__c = customerId;
            rental.Start_Date__c = startDate;
            rental.End_Date__c = endDate;
            rental.Daily_Price__c = dailyPrice;
            rental.Total_Amount__c = body.containsKey('Total_Amount__c') ? BikeShopApiUtil.getDecimal(body, 'Total_Amount__c') : totalAmount;
            rental.Status__c = status;
            rental.Paid__c = body.containsKey('Paid__c') ? BikeShopApiUtil.getBoolean(body, 'Paid__c') : false;

            insert rental;
            RestContext.response.statusCode = 201;
            rental = [SELECT Id, Bike__c, Bike__r.Name, Customer__c, Customer__r.Name, Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c FROM Bike_Rental__c WHERE Id = :rental.Id];
            return new RentalDto(rental);
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpPatch
    global static RentalDto updateRental() {
        try {
            if (!Schema.sObjectType.Bike_Rental__c.isUpdateable()) {
                throw new BikeShopApiUtil.ApiException('No update access to Rental.', 403);
            }

            Id rentalId = BikeShopApiUtil.getIdFromUri();
            Bike_Rental__c rental = [
                SELECT Id, Bike__c, Customer__c, Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c
                FROM Bike_Rental__c
                WHERE Id = :rentalId
                LIMIT 1
            ];

            Map<String, Object> body = BikeShopApiUtil.parseBody();
            if (body.containsKey('Bike__c')) {
                rental.Bike__c = BikeShopApiUtil.getId(body, 'Bike__c');
            }
            if (body.containsKey('Customer__c')) {
                rental.Customer__c = BikeShopApiUtil.getId(body, 'Customer__c');
            }
            if (body.containsKey('Start_Date__c')) {
                rental.Start_Date__c = BikeShopApiUtil.getDate(body, 'Start_Date__c');
            }
            if (body.containsKey('End_Date__c')) {
                rental.End_Date__c = BikeShopApiUtil.getDate(body, 'End_Date__c');
            }
            if (rental.End_Date__c < rental.Start_Date__c) {
                throw new BikeShopApiUtil.ApiException('End Date cannot be before Start Date.', 400);
            }
            if (body.containsKey('Daily_Price__c')) {
                Decimal dailyPrice = BikeShopApiUtil.getDecimal(body, 'Daily_Price__c');
                BikeShopApiUtil.validatePositive(dailyPrice, 'Daily Price', true);
                rental.Daily_Price__c = dailyPrice;
            }
            if (body.containsKey('Status__c')) {
                String status = BikeShopApiUtil.getString(body, 'Status__c');
                BikeShopApiUtil.validateText(status, 40, 'Status', true);
                rental.Status__c = status;
            }
            if (body.containsKey('Paid__c')) {
                rental.Paid__c = BikeShopApiUtil.getBoolean(body, 'Paid__c');
            }

            Integer rentalDays = rental.Start_Date__c.daysBetween(rental.End_Date__c) + 1;
            rental.Total_Amount__c = rental.Daily_Price__c * rentalDays;

            update rental;
            rental = [SELECT Id, Bike__c, Bike__r.Name, Customer__c, Customer__r.Name, Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c FROM Bike_Rental__c WHERE Id = :rental.Id];
            RestContext.response.statusCode = 200;
            return new RentalDto(rental);
        } catch (QueryException qex) {
            BikeShopApiUtil.handleException(new BikeShopApiUtil.ApiException('Rental not found.', 404));
            return null;
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpDelete
    global static void deleteRental() {
        try {
            if (!Schema.sObjectType.Bike_Rental__c.isDeletable()) {
                throw new BikeShopApiUtil.ApiException('No delete access to Rental.', 403);
            }

            Id rentalId = BikeShopApiUtil.getIdFromUri();
            delete [SELECT Id FROM Bike_Rental__c WHERE Id = :rentalId LIMIT 1];
            RestContext.response.statusCode = 204;
        } catch (QueryException qex) {
            BikeShopApiUtil.handleException(new BikeShopApiUtil.ApiException('Rental not found.', 404));
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
        }
    }
}