/**
 * Unit tests for BikeShopApiUtil utility class
 * Tests parsing, validation, and data type conversion methods
 */
@IsTest
private class BikeShopApiUtilTest {
    
    @IsTest
    static void testGetPageWithValidPage() {
        RestRequest req = new RestRequest();
        req.addParameter('page', '5');
        RestContext.request = req;
        
        Integer page = BikeShopApiUtil.getPage();
        System.assertEquals(5, page);
    }
    
    @IsTest
    static void testGetPageWithNegativePage() {
        RestRequest req = new RestRequest();
        req.addParameter('page', '-1');
        RestContext.request = req;
        
        Integer page = BikeShopApiUtil.getPage();
        System.assertEquals(1, page, 'Negative pages should default to 1');
    }
    
    @IsTest
    static void testGetPageWithZeroPage() {
        RestRequest req = new RestRequest();
        req.addParameter('page', '0');
        RestContext.request = req;
        
        Integer page = BikeShopApiUtil.getPage();
        System.assertEquals(1, page, 'Zero page should default to 1');
    }
    
    @IsTest
    static void testGetPageWithoutParameter() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        Integer page = BikeShopApiUtil.getPage();
        System.assertEquals(1, page, 'Missing page should default to 1');
    }
    
    @IsTest
    static void testGetPageSizeWithValidSize() {
        RestRequest req = new RestRequest();
        req.addParameter('pageSize', '25');
        RestContext.request = req;
        
        Integer pageSize = BikeShopApiUtil.getPageSize();
        System.assertEquals(25, pageSize);
    }
    
    @IsTest
    static void testGetPageSizeWithSizeExceedingMax() {
        RestRequest req = new RestRequest();
        req.addParameter('pageSize', '150');
        RestContext.request = req;
        
        Integer pageSize = BikeShopApiUtil.getPageSize();
        System.assertEquals(100, pageSize, 'Max page size should be 100');
    }
    
    @IsTest
    static void testGetPageSizeWithNegativeSize() {
        RestRequest req = new RestRequest();
        req.addParameter('pageSize', '-5');
        RestContext.request = req;
        
        Integer pageSize = BikeShopApiUtil.getPageSize();
        System.assertEquals(10, pageSize, 'Negative size should default to 10');
    }
    
    @IsTest
    static void testGetPageSizeWithoutParameter() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        Integer pageSize = BikeShopApiUtil.getPageSize();
        System.assertEquals(10, pageSize, 'Missing pageSize should default to 10');
    }
    
    @IsTest
    static void testGetParam() {
        RestRequest req = new RestRequest();
        req.addParameter('search', 'test value');
        RestContext.request = req;
        
        String param = BikeShopApiUtil.getParam('search');
        System.assertEquals('test value', param);
    }
    
    @IsTest
    static void testGetParamMissing() {
        RestRequest req = new RestRequest();
        RestContext.request = req;
        
        String param = BikeShopApiUtil.getParam('nonexistent');
        System.assertEquals(null, param);
    }
    
    @IsTest
    static void testGetIdFromUriValid() {
        Id testId = Schema.getGlobalDescribe().get('Account').getDescribe().getKeyPrefix() + '000000000000';
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bikeshop/v1/bikes/' + testId;
        RestContext.request = req;
        
        Id resultId = BikeShopApiUtil.getIdFromUri();
        System.assertEquals(testId, resultId);
    }
    
    @IsTest
    static void testGetIdFromUriInvalid() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bikeshop/v1/bikes/invalid-id';
        RestContext.request = req;
        
        try {
            BikeShopApiUtil.getIdFromUri();
            System.assert(false, 'Should throw exception for invalid ID');
        } catch (BikeShopApiUtil.ApiException ex) {
            System.assertEquals('Invalid Salesforce Id in URI.', ex.getMessage());
            System.assertEquals(400, ex.statusCode);
        }
    }
    
    @IsTest
    static void testGetIdFromUriMissing() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bikeshop/v1/bikes/';
        RestContext.request = req;
        
        try {
            BikeShopApiUtil.getIdFromUri();
            System.assert(false, 'Should throw exception for missing ID');
        } catch (BikeShopApiUtil.ApiException ex) {
            System.assertEquals('Invalid Salesforce Id in URI.', ex.getMessage());
            System.assertEquals(400, ex.statusCode);
        }
    }
    
    @IsTest
    static void testParseBodyWithValidJson() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"name":"Test","value":42}');
        RestContext.request = req;
        
        Map<String, Object> body = BikeShopApiUtil.parseBody();
        System.assertEquals('Test', body.get('name'));
        System.assertEquals(42.0, body.get('value'));
    }
    
    @IsTest
    static void testParseBodyWithEmptyBody() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('');
        RestContext.request = req;
        
        Map<String, Object> body = BikeShopApiUtil.parseBody();
        System.assertEquals(0, body.size());
    }
    
    @IsTest
    static void testParseBodyWithNullBody() {
        RestRequest req = new RestRequest();
        req.requestBody = null;
        RestContext.request = req;
        
        Map<String, Object> body = BikeShopApiUtil.parseBody();
        System.assertEquals(0, body.size());
    }
    
    @IsTest
    static void testGetString() {
        Map<String, Object> body = new Map<String, Object>();
        body.put('test', 'value');
        
        String result = BikeShopApiUtil.getString(body, 'test');
        System.assertEquals('value', result);
    }
    
    @IsTest
    static void testGetStringMissing() {
        Map<String, Object> body = new Map<String, Object>();
        
        String result = BikeShopApiUtil.getString(body, 'missing');
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testGetStringNull() {
        Map<String, Object> body = new Map<String, Object>();
        body.put('test', null);
        
        String result = BikeShopApiUtil.getString(body, 'test');
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testGetDecimal() {
        Map<String, Object> body = new Map<String, Object>();
        body.put('price', 99.99);
        
        Decimal result = BikeShopApiUtil.getDecimal(body, 'price');
        System.assertEquals(99.99, result);
    }
    
    @IsTest
    static void testGetDecimalMissing() {
        Map<String, Object> body = new Map<String, Object>();
        
        Decimal result = BikeShopApiUtil.getDecimal(body, 'missing');
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testGetInteger() {
        Map<String, Object> body = new Map<String, Object>();
        body.put('count', 42);
        
        Integer result = BikeShopApiUtil.getInteger(body, 'count');
        System.assertEquals(42, result);
    }
    
    @IsTest
    static void testGetIntegerMissing() {
        Map<String, Object> body = new Map<String, Object>();
        
        Integer result = BikeShopApiUtil.getInteger(body, 'missing');
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testGetBooleanTrue() {
        Map<String, Object> body = new Map<String, Object>();
        body.put('active', 'true');
        
        Boolean result = BikeShopApiUtil.getBoolean(body, 'active');
        System.assertEquals(true, result);
    }
    
    @IsTest
    static void testGetBooleanFalse() {
        Map<String, Object> body = new Map<String, Object>();
        body.put('active', 'false');
        
        Boolean result = BikeShopApiUtil.getBoolean(body, 'active');
        System.assertEquals(false, result);
    }
    
    @IsTest
    static void testGetBooleanMissing() {
        Map<String, Object> body = new Map<String, Object>();
        
        Boolean result = BikeShopApiUtil.getBoolean(body, 'missing');
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testGetDate() {
        Map<String, Object> body = new Map<String, Object>();
        body.put('startDate', '2026-03-05');
        
        Date result = BikeShopApiUtil.getDate(body, 'startDate');
        System.assertEquals(Date.newInstance(2026, 3, 5), result);
    }
    
    @IsTest
    static void testGetDateMissing() {
        Map<String, Object> body = new Map<String, Object>();
        
        Date result = BikeShopApiUtil.getDate(body, 'missing');
        System.assertEquals(null, result);
    }
    
    @IsTest
    static void testValidateTextValid() {
        // Should not throw exception
        BikeShopApiUtil.validateText('Valid text', 20, 'Field', true);
        System.assert(true, 'Valid text passes validation');
    }
    
    @IsTest
    static void testValidateTextBlank() {
        try {
            BikeShopApiUtil.validateText('', 20, 'Field', true);
            System.assert(false, 'Should throw exception for blank text');
        } catch (BikeShopApiUtil.ApiException ex) {
            System.assert(ex.getMessage().contains('Field is required'));
        }
    }
    
    @IsTest
    static void testValidateTextTooLong() {
        try {
            BikeShopApiUtil.validateText('This is a very long text that exceeds the max length', 10, 'Field', false);
            System.assert(false, 'Should throw exception for text exceeding max length');
        } catch (BikeShopApiUtil.ApiException ex) {
            System.assert(ex.getMessage().contains('max length is'));
        }
    }
    
    @IsTest
    static void testValidatePositiveValid() {
        // Should not throw exception
        BikeShopApiUtil.validatePositive(99.99, 'Price', true);
        System.assert(true, 'Positive value passes validation');
    }
    
    @IsTest
    static void testValidatePositiveNegative() {
        try {
            BikeShopApiUtil.validatePositive(-10, 'Price', true);
            System.assert(false, 'Should throw exception for negative value');
        } catch (BikeShopApiUtil.ApiException ex) {
            System.assert(ex.getMessage().contains('cannot be negative'));
        }
    }
    
    @IsTest
    static void testValidatePositiveZero() {
        // Zero should be allowed (only negative values are rejected)
        BikeShopApiUtil.validatePositive(0, 'Price', true);
        System.assert(true, 'Zero value is allowed');
    }
    
    @IsTest
    static void testErrorResponse() {
        RestContext.response = new RestResponse();
        Exception baseEx = new DmlException('Test error');
        Map<String, Object> response = BikeShopApiUtil.errorResponse(baseEx);
        
        System.assert(response.containsKey('error'));
        System.assert(response.containsKey('statusCode'));
    }
    
    @IsTest
    static void testErrorResponseWithApiException() {
        RestContext.response = new RestResponse();
        BikeShopApiUtil.ApiException ex = new BikeShopApiUtil.ApiException('Custom error', 400);
        Map<String, Object> response = BikeShopApiUtil.errorResponse(ex);
        
        System.assertEquals('Custom error', response.get('error'));
        System.assertEquals(400, response.get('statusCode'));
    }
    
    @IsTest
    static void testListResponse() {
        List<Account> accounts = new List<Account>();
        Map<String, Object> response = BikeShopApiUtil.listResponse(accounts, 5, 1, 10);
        
        System.assertEquals(5, response.get('total'));
        System.assertEquals(1, response.get('page'));
        System.assertEquals(10, response.get('pageSize'));
        System.assert(response.containsKey('records'));
    }
}
