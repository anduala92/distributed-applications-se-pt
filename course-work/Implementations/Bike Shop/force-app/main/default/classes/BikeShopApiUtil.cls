public with sharing class BikeShopApiUtil {
    public class ApiException extends Exception {
        public Integer statusCode;

        public ApiException(String message, Integer statusCode) {
            super.setMessage(message);
            this.statusCode = statusCode;
        }
    }

    public static Integer getPage() {
        String rawPage = RestContext.request.params.get('page');
        if (String.isBlank(rawPage)) {
            return 1;
        }
        Integer parsed = Integer.valueOf(rawPage);
        return parsed < 1 ? 1 : parsed;
    }

    public static Integer getPageSize() {
        String rawPageSize = RestContext.request.params.get('pageSize');
        if (String.isBlank(rawPageSize)) {
            return 10;
        }
        Integer parsed = Integer.valueOf(rawPageSize);
        if (parsed < 1) {
            return 10;
        }
        return parsed > 100 ? 100 : parsed;
    }

    public static String getParam(String key) {
        return RestContext.request.params.get(key);
    }

    public static Id getIdFromUri() {
        String uri = RestContext.request.requestURI;
        List<String> parts = uri.split('/');
        if (parts.isEmpty()) {
            throw new ApiException('Missing resource id in URI.', 400);
        }
        String lastPart = parts[parts.size() - 1];
        if (String.isBlank(lastPart)) {
            throw new ApiException('Missing resource id in URI.', 400);
        }
        try {
            return (Id) lastPart;
        } catch (Exception ex) {
            throw new ApiException('Invalid Salesforce Id in URI.', 400);
        }
    }

    public static Map<String, Object> parseBody() {
        if (RestContext.request.requestBody == null) {
            return new Map<String, Object>();
        }
        String body = RestContext.request.requestBody.toString();
        if (String.isBlank(body)) {
            return new Map<String, Object>();
        }
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    public static String getString(Map<String, Object> body, String key) {
        if (!body.containsKey(key) || body.get(key) == null) {
            return null;
        }
        return String.valueOf(body.get(key));
    }

    public static Decimal getDecimal(Map<String, Object> body, String key) {
        if (!body.containsKey(key) || body.get(key) == null) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(body.get(key)));
    }

    public static Integer getInteger(Map<String, Object> body, String key) {
        if (!body.containsKey(key) || body.get(key) == null) {
            return null;
        }
        return Integer.valueOf(String.valueOf(body.get(key)));
    }

    public static Boolean getBoolean(Map<String, Object> body, String key) {
        if (!body.containsKey(key) || body.get(key) == null) {
            return null;
        }
        return String.valueOf(body.get(key)).toLowerCase() == 'true';
    }

    public static Date getDate(Map<String, Object> body, String key) {
        if (!body.containsKey(key) || body.get(key) == null) {
            return null;
        }
        return Date.valueOf(String.valueOf(body.get(key)));
    }

    public static Id getId(Map<String, Object> body, String key) {
        if (!body.containsKey(key) || body.get(key) == null) {
            return null;
        }
        try {
            return (Id) String.valueOf(body.get(key));
        } catch (Exception ex) {
            throw new ApiException('Invalid Id for field ' + key + '.', 400);
        }
    }

    public static void validateText(String value, Integer maxLength, String fieldLabel, Boolean required) {
        if (required && String.isBlank(value)) {
            throw new ApiException(fieldLabel + ' is required.', 400);
        }
        if (!String.isBlank(value) && value.length() > maxLength) {
            throw new ApiException(fieldLabel + ' max length is ' + maxLength + '.', 400);
        }
    }

    public static void validatePositive(Decimal value, String fieldLabel, Boolean required) {
        if (required && value == null) {
            throw new ApiException(fieldLabel + ' is required.', 400);
        }
        if (value != null && value < 0) {
            throw new ApiException(fieldLabel + ' cannot be negative.', 400);
        }
    }

    public static Map<String, Object> listResponse(List<SObject> records, Integer total, Integer page, Integer pageSize) {
        return new Map<String, Object>{
            'page' => page,
            'pageSize' => pageSize,
            'total' => total,
            'records' => records
        };
    }

    public static Map<String, Object> listResponseWithDtos(List<Object> dtos, Integer total, Integer page, Integer pageSize) {
        return new Map<String, Object>{
            'page' => page,
            'pageSize' => pageSize,
            'total' => total,
            'records' => dtos
        };
    }

    public static String formatJsonResponse(Object data) {
        return JSON.serialize(data);
    }

    public static Map<String, Object> errorResponse(Exception ex) {
        Integer status = 500;
        String message = ex.getMessage();
        if (ex instanceof ApiException) {
            status = ((ApiException) ex).statusCode;
        }
        RestContext.response.statusCode = status;
        return new Map<String, Object>{
            'error' => message,
            'statusCode' => status
        };
    }

    public static void handleException(Exception ex) {
        Integer status = 500;
        String message = ex.getMessage();
        if (ex instanceof ApiException) {
            status = ((ApiException) ex).statusCode;
        }
        RestContext.response.statusCode = status;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'error' => message,
            'statusCode' => status
        }));
    }
}