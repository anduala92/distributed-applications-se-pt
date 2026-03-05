@RestResource(urlMapping='/bikeshop/v1/bikes/*')
global with sharing class BikeRestService {
    @HttpGet
    global static BikeListResponseDto getBikes() {
        try {
            if (!Schema.sObjectType.Bike__c.isAccessible()) {
                throw new BikeShopApiUtil.ApiException('No read access to Bike.', 403);
            }

            Integer page = BikeShopApiUtil.getPage();
            Integer pageSize = BikeShopApiUtil.getPageSize();
            Integer offsetRows = (page - 1) * pageSize;
            String search = BikeShopApiUtil.getParam('search');

            List<Bike__c> rows;
            Integer total;

            if (String.isBlank(search)) {
                total = [SELECT COUNT() FROM Bike__c];
                rows = [
                    SELECT Id, Name, Model__c, Brand__c, Category__c, Daily_Rate__c, Available__c, Mileage__c, Last_Service_Date__c
                    FROM Bike__c
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            } else {
                String likeSearch = '%' + search + '%';
                total = [SELECT COUNT() FROM Bike__c WHERE Model__c LIKE :likeSearch OR Brand__c LIKE :likeSearch OR Name LIKE :likeSearch];
                rows = [
                    SELECT Id, Name, Model__c, Brand__c, Category__c, Daily_Rate__c, Available__c, Mileage__c, Last_Service_Date__c
                    FROM Bike__c
                    WHERE Model__c LIKE :likeSearch OR Brand__c LIKE :likeSearch OR Name LIKE :likeSearch
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            }

            List<BikeDto> bikeDtos = new List<BikeDto>();
            for (Bike__c bike : rows) {
                bikeDtos.add(new BikeDto(bike));
            }

            Map<String, Object> response = new Map<String, Object>{
                'page' => page,
                'pageSize' => pageSize,
                'total' => total,
                'records' => bikeDtos
            };
            RestContext.response.statusCode = 200;
            return (BikeListResponseDto) JSON.deserialize(JSON.serialize(response), BikeListResponseDto.class);
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpPost
    global static BikeDto createBike() {
        try {
            if (!Schema.sObjectType.Bike__c.isCreateable()) {
                throw new BikeShopApiUtil.ApiException('No create access to Bike.', 403);
            }

            Map<String, Object> body = BikeShopApiUtil.parseBody();
            String model = BikeShopApiUtil.getString(body, 'Model__c');
            String brand = BikeShopApiUtil.getString(body, 'Brand__c');
            String category = BikeShopApiUtil.getString(body, 'Category__c');
            Decimal dailyRate = BikeShopApiUtil.getDecimal(body, 'Daily_Rate__c');

            BikeShopApiUtil.validateText(model, 80, 'Model', true);
            BikeShopApiUtil.validateText(brand, 80, 'Brand', true);
            BikeShopApiUtil.validateText(category, 40, 'Category', true);
            BikeShopApiUtil.validatePositive(dailyRate, 'Daily Rate', true);

            Bike__c bike = new Bike__c();
            bike.Name = String.isBlank(BikeShopApiUtil.getString(body, 'Name')) ? brand + ' ' + model : BikeShopApiUtil.getString(body, 'Name');
            bike.Model__c = model;
            bike.Brand__c = brand;
            bike.Category__c = category;
            bike.Daily_Rate__c = dailyRate;
            bike.Available__c = body.containsKey('Available__c') ? BikeShopApiUtil.getBoolean(body, 'Available__c') : true;
            bike.Mileage__c = BikeShopApiUtil.getInteger(body, 'Mileage__c');
            bike.Last_Service_Date__c = BikeShopApiUtil.getDate(body, 'Last_Service_Date__c');

            insert bike;
            RestContext.response.statusCode = 201;
            return new BikeDto(bike);
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpPatch
    global static BikeDto updateBike() {
        try {
            if (!Schema.sObjectType.Bike__c.isUpdateable()) {
                throw new BikeShopApiUtil.ApiException('No update access to Bike.', 403);
            }

            Id bikeId = BikeShopApiUtil.getIdFromUri();
            Bike__c bike = [SELECT Id, Name, Model__c, Brand__c, Category__c, Daily_Rate__c, Available__c, Mileage__c, Last_Service_Date__c FROM Bike__c WHERE Id = :bikeId LIMIT 1];

            Map<String, Object> body = BikeShopApiUtil.parseBody();
            if (body.containsKey('Name')) {
                String nameValue = BikeShopApiUtil.getString(body, 'Name');
                BikeShopApiUtil.validateText(nameValue, 80, 'Name', true);
                bike.Name = nameValue;
            }
            if (body.containsKey('Model__c')) {
                String modelValue = BikeShopApiUtil.getString(body, 'Model__c');
                BikeShopApiUtil.validateText(modelValue, 80, 'Model', true);
                bike.Model__c = modelValue;
            }
            if (body.containsKey('Brand__c')) {
                String brandValue = BikeShopApiUtil.getString(body, 'Brand__c');
                BikeShopApiUtil.validateText(brandValue, 80, 'Brand', true);
                bike.Brand__c = brandValue;
            }
            if (body.containsKey('Category__c')) {
                String categoryValue = BikeShopApiUtil.getString(body, 'Category__c');
                BikeShopApiUtil.validateText(categoryValue, 40, 'Category', true);
                bike.Category__c = categoryValue;
            }
            if (body.containsKey('Daily_Rate__c')) {
                Decimal rateValue = BikeShopApiUtil.getDecimal(body, 'Daily_Rate__c');
                BikeShopApiUtil.validatePositive(rateValue, 'Daily Rate', true);
                bike.Daily_Rate__c = rateValue;
            }
            if (body.containsKey('Available__c')) {
                bike.Available__c = BikeShopApiUtil.getBoolean(body, 'Available__c');
            }
            if (body.containsKey('Mileage__c')) {
                bike.Mileage__c = BikeShopApiUtil.getInteger(body, 'Mileage__c');
            }
            if (body.containsKey('Last_Service_Date__c')) {
                bike.Last_Service_Date__c = BikeShopApiUtil.getDate(body, 'Last_Service_Date__c');
            }

            update bike;
            RestContext.response.statusCode = 200;
            return new BikeDto(bike);
        } catch (QueryException qex) {
            BikeShopApiUtil.handleException(new BikeShopApiUtil.ApiException('Bike not found.', 404));
            return null;
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpDelete
    global static void deleteBike() {
        try {
            if (!Schema.sObjectType.Bike__c.isDeletable()) {
                throw new BikeShopApiUtil.ApiException('No delete access to Bike.', 403);
            }

            Id bikeId = BikeShopApiUtil.getIdFromUri();
            delete [SELECT Id FROM Bike__c WHERE Id = :bikeId LIMIT 1];
            RestContext.response.statusCode = 204;
        } catch (QueryException qex) {
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(BikeShopApiUtil.errorResponse(new BikeShopApiUtil.ApiException('Bike not found.', 404))));
        } catch (Exception ex) {
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(BikeShopApiUtil.errorResponse(ex)));
        }
    }
}