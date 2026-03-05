@RestResource(urlMapping='/bikeshop/v1/customers/*')
global with sharing class CustomerRestService {
    @HttpGet
    global static CustomerListResponseDto getCustomers() {
        try {
            if (!Schema.sObjectType.Customer__c.isAccessible()) {
                throw new BikeShopApiUtil.ApiException('No read access to Customer.', 403);
            }

            Integer page = BikeShopApiUtil.getPage();
            Integer pageSize = BikeShopApiUtil.getPageSize();
            Integer offsetRows = (page - 1) * pageSize;
            String search = BikeShopApiUtil.getParam('search');
            List<Customer__c> rows;
            Integer total;

            if (String.isBlank(search)) {
                total = [SELECT COUNT() FROM Customer__c];
                rows = [
                    SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Birth_Date__c, Loyalty_Points__c, Is_Active__c
                    FROM Customer__c
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            } else {
                String likeSearch = '%' + search + '%';
                total = [
                    SELECT COUNT()
                    FROM Customer__c
                    WHERE First_Name__c LIKE :likeSearch OR Last_Name__c LIKE :likeSearch OR Email__c LIKE :likeSearch
                ];
                rows = [
                    SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Birth_Date__c, Loyalty_Points__c, Is_Active__c
                    FROM Customer__c
                    WHERE First_Name__c LIKE :likeSearch OR Last_Name__c LIKE :likeSearch OR Email__c LIKE :likeSearch
                    ORDER BY CreatedDate DESC
                    LIMIT :pageSize
                    OFFSET :offsetRows
                ];
            }

            List<CustomerDto> customerDtos = new List<CustomerDto>();
            for (Customer__c customer : rows) {
                customerDtos.add(new CustomerDto(customer));
            }

            Map<String, Object> response = new Map<String, Object>{
                'page' => page,
                'pageSize' => pageSize,
                'total' => total,
                'records' => customerDtos
            };
            RestContext.response.statusCode = 200;
            return (CustomerListResponseDto) JSON.deserialize(JSON.serialize(response), CustomerListResponseDto.class);
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpPost
    global static CustomerDto createCustomer() {
        try {
            if (!Schema.sObjectType.Customer__c.isCreateable()) {
                throw new BikeShopApiUtil.ApiException('No create access to Customer.', 403);
            }

            Map<String, Object> body = BikeShopApiUtil.parseBody();
            String firstName = BikeShopApiUtil.getString(body, 'First_Name__c');
            String lastName = BikeShopApiUtil.getString(body, 'Last_Name__c');
            String email = BikeShopApiUtil.getString(body, 'Email__c');

            BikeShopApiUtil.validateText(firstName, 50, 'First Name', true);
            BikeShopApiUtil.validateText(lastName, 50, 'Last Name', true);
            BikeShopApiUtil.validateText(email, 80, 'Email', true);

            Customer__c customer = new Customer__c();
            customer.Name = String.isBlank(BikeShopApiUtil.getString(body, 'Name')) ? (firstName + ' ' + lastName) : BikeShopApiUtil.getString(body, 'Name');
            customer.First_Name__c = firstName;
            customer.Last_Name__c = lastName;
            customer.Email__c = email;
            customer.Phone__c = BikeShopApiUtil.getString(body, 'Phone__c');
            customer.Birth_Date__c = BikeShopApiUtil.getDate(body, 'Birth_Date__c');
            customer.Loyalty_Points__c = BikeShopApiUtil.getInteger(body, 'Loyalty_Points__c');
            customer.Is_Active__c = body.containsKey('Is_Active__c') ? BikeShopApiUtil.getBoolean(body, 'Is_Active__c') : true;

            insert customer;
            RestContext.response.statusCode = 201;
            return new CustomerDto(customer);
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpPatch
    global static CustomerDto updateCustomer() {
        try {
            if (!Schema.sObjectType.Customer__c.isUpdateable()) {
                throw new BikeShopApiUtil.ApiException('No update access to Customer.', 403);
            }

            Id customerId = BikeShopApiUtil.getIdFromUri();
            Customer__c customer = [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Birth_Date__c, Loyalty_Points__c, Is_Active__c
                FROM Customer__c
                WHERE Id = :customerId
                LIMIT 1
            ];

            Map<String, Object> body = BikeShopApiUtil.parseBody();
            if (body.containsKey('First_Name__c')) {
                String firstName = BikeShopApiUtil.getString(body, 'First_Name__c');
                BikeShopApiUtil.validateText(firstName, 50, 'First Name', true);
                customer.First_Name__c = firstName;
            }
            if (body.containsKey('Last_Name__c')) {
                String lastName = BikeShopApiUtil.getString(body, 'Last_Name__c');
                BikeShopApiUtil.validateText(lastName, 50, 'Last Name', true);
                customer.Last_Name__c = lastName;
            }
            if (body.containsKey('Email__c')) {
                String email = BikeShopApiUtil.getString(body, 'Email__c');
                BikeShopApiUtil.validateText(email, 80, 'Email', true);
                customer.Email__c = email;
            }
            if (body.containsKey('Phone__c')) {
                customer.Phone__c = BikeShopApiUtil.getString(body, 'Phone__c');
            }
            if (body.containsKey('Birth_Date__c')) {
                customer.Birth_Date__c = BikeShopApiUtil.getDate(body, 'Birth_Date__c');
            }
            if (body.containsKey('Loyalty_Points__c')) {
                customer.Loyalty_Points__c = BikeShopApiUtil.getInteger(body, 'Loyalty_Points__c');
            }
            if (body.containsKey('Is_Active__c')) {
                customer.Is_Active__c = BikeShopApiUtil.getBoolean(body, 'Is_Active__c');
            }
            if (body.containsKey('Name')) {
                String nameValue = BikeShopApiUtil.getString(body, 'Name');
                BikeShopApiUtil.validateText(nameValue, 80, 'Name', true);
                customer.Name = nameValue;
            }

            update customer;
            RestContext.response.statusCode = 200;
            return new CustomerDto(customer);
        } catch (QueryException qex) {
            BikeShopApiUtil.handleException(new BikeShopApiUtil.ApiException('Customer not found.', 404));
            return null;
        } catch (Exception ex) {
            BikeShopApiUtil.handleException(ex);
            return null;
        }
    }

    @HttpDelete
    global static void deleteCustomer() {
        try {
            if (!Schema.sObjectType.Customer__c.isDeletable()) {
                throw new BikeShopApiUtil.ApiException('No delete access to Customer.', 403);
            }

            Id customerId = BikeShopApiUtil.getIdFromUri();
            delete [SELECT Id FROM Customer__c WHERE Id = :customerId LIMIT 1];
            RestContext.response.statusCode = 204;
        } catch (QueryException qex) {
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(BikeShopApiUtil.errorResponse(new BikeShopApiUtil.ApiException('Customer not found.', 404))));
        } catch (Exception ex) {
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(BikeShopApiUtil.errorResponse(ex)));
        }
    }
}