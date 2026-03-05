# Bike Shop - Salesforce Coursework

**Студент**: Aleksandar Aleksandrov (Факултетен номер: `2401322033`)

## 📋 Кратко

REST API за управление на велосипеди, клиенти и наемания. Реализирано в Salesforce с:
- ✅ **3 Custom Objects**: Bike__c, Customer__c, Bike_Rental__c (с връзки и валидация)
- ✅ **3 REST Services**: GET/POST/PATCH/DELETE операции + search + pagination
- ✅ **OpenAPI документация**: `docs/openapi.yaml` (Swagger)
- ✅ **Postman колекция**: `docs/postman-collection.json` (15 готови заявки)
- ✅ **LWC UI**: `bikeShopApp` компонент
- ✅ **Unit тестове**: 115/115 тестове преминават

## ⚡ Бързо начало (5 минути)

### 1️⃣ Свържи се с Salesforce org
```bash
sf org login web --alias "Bike Shop" --set-default
```

### 2️⃣ Деплой в org
```bash
sf project deploy start --source-dir force-app --wait 10
```

### 3️⃣ Присвой разрешения
```bash
sf org assign permset --name Bike_Shop_App_Access
```

### 4️⃣ Импортирай Postman колекция
1. Отвори **Postman** → **Import** → `docs/postman-collection.json`
2. Влизе в колекцията → **Variables** → `SALESFORCE_TOKEN` = `sf org display | grep "Access Token"`
3. **Send** на всяка заявка

## 📚 REST Endpoints

| Метод | Path | Описание |
|-------|------|---------|
| GET | `/bikeshop/v1/bikes?page=1&pageSize=10` | Вземи всички мотоциклети |
| POST | `/bikeshop/v1/bikes` | Създай мотоциклета |
| PATCH | `/bikeshop/v1/bikes/{id}` | Обнови мотоциклета |
| DELETE | `/bikeshop/v1/bikes/{id}` | Изтрий мотоциклета |
| | | |
| GET | `/bikeshop/v1/customers?page=1&pageSize=10` | Вземи всички клиенти |
| POST | `/bikeshop/v1/customers` | Създай клиент |
| PATCH | `/bikeshop/v1/customers/{id}` | Обнови клиент |
| DELETE | `/bikeshop/v1/customers/{id}` | Изтрий клиент |
| | | |
| GET | `/bikeshop/v1/rentals?page=1&pageSize=10` | Вземи всички наемания |
| POST | `/bikeshop/v1/rentals` | Създай наемание |
| PATCH | `/bikeshop/v1/rentals/{id}` | Обнови наемание |
| DELETE | `/bikeshop/v1/rentals/{id}` | Изтрий наемание |

**Full URL**: `https://stu2401322033.c9195e8f6294.develop.my.salesforce.com/services/apexrest{path}`

## 📖 Документация

| Файл | Как да го използваш |
|------|-------------------|
| `docs/openapi.yaml` | Отвори в [Swagger Editor](https://editor.swagger.io/) за интерактивен преглед |
| `docs/postman-collection.json` | Import в Postman за директно тестване |
| Този README | Преглед на всичко |

## 🧪 Пускане на тестовете

```bash
sf apex run test --tests BikeShopApiTest --result-format human --code-coverage
```

Резултат: **115/115 ✅ преминават**

## 🏗️ Архитектура

### Модели (DTOs)
```
BikeDto        → Bike__c
CustomerDto    → Customer__c
RentalDto      → Bike_Rental__c (с връзки)
```

### Класове
- **BikeRestService** / **CustomerRestService** / **RentalRestService** - CRUD & REST endpoints
- **BikeShopApiUtil** - Общи функции, валидация, форматиране на отговори
- **BikeShopLwcController** - LWC логика
- Всички са `with sharing` + проверка на CRUD достъпа

### Database
| Таблица | Колони | Връзки | Задължителни |
|---------|--------|--------|--------------|
| `Bike__c` | Id, Name, Model__c, Brand__c, Category__c, Daily_Rate__c, Available__c, Mileage__c, Last_Service_Date__c | - | Name, Model__c, Brand__c, Daily_Rate__c |
| `Customer__c` | Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Birth_Date__c, Loyalty_Points__c, Is_Active__c | - | First_Name__c, Last_Name__c, Email__c |
| `Bike_Rental__c` | Id, Bike__c (FK), Customer__c (FK), Start_Date__c, End_Date__c, Daily_Price__c, Total_Amount__c, Status__c, Paid__c | Bike__c, Customer__c | Bike__c, Customer__c, Start_Date__c, End_Date__c |

## 🔐 Защита

- ✅ OAuth 2.0 Bearer Token автентикация
- ✅ CRUD проверки на ниво обект (`isAccessible`, `isCreateable`, `isUpdateable`, `isDeletable`)
- ✅ Row-level security чрез `with sharing`
- ✅ Валидация на входни данни (телефонни номера, формати на дати, и т.н.)

## 💡 Примери за заявки

### Получи всички мотоциклети
```bash
curl -X GET "https://stu2401322033.c9195e8f6294.develop.my.salesforce.com/services/apexrest/bikeshop/v1/bikes?page=1&pageSize=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Създай нова мотоциклета
```bash
curl -X POST "https://stu2401322033.c9195e8f6294.develop.my.salesforce.com/services/apexrest/bikeshop/v1/bikes" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mountain Bike Pro",
    "model": "MTB-2024",
    "brand": "Trek",
    "category": "Mountain",
    "dailyRate": 25.00,
    "available": true,
    "mileage": 0
  }'
```

## ❓ FAQ

**Q: Как да получа токена?**
```bash
sf org display | grep "Access Token"
```

**Q: Какво е разликата между минаване през LWC и Postman?**
- LWC: За ежедневна работа с UI
- Postman: За тестване на API-то директно

**Q: Могу ли да използвам SOQL вместо REST API?**
Да, но този проект е специално за REST API, затова използвай REST endpoints.

**Q: Тестовете работят ли и на други orgs?**
Да, просто деплой и присвой permission set-а.

## 📞 Още информация

- **OpenAPI спецификация**: `docs/openapi.yaml` (всички детайли)
- **Тест код**: `force-app/main/default/classes/*Test.cls`
- **LWC компонент**: `force-app/main/default/lwc/bikeShopApp/`

Ако преминаваш към нова Salesforce среда и искаш да тестваш REST API през Postman с OAuth 2.0 аутентикация, следвай тази инструкция:

### FASE 1: Подготовка на новата среда

#### **Стъпка 1.1: Свържи се с новата org**
```bash
sf org login web --alias "PU Bike" --set-default
```
- Ще се отвори браузър
- Логирай се със своя Salesforce акаунт в новата среда
- Одобри достъпа
- Алиасът се запазва локално

#### **Стъпка 1.2: Провери текущия org**
```bash
sf org display
```
Трябва да видиш:
- `Alias: PU Bike`
- `Instance URL: https://...develop.my.salesforce.com`
- `Access Token: 00D...` (дълъг token)

### FASE 2: Премахване на namespace префикса (ВАЖНО!)

Ако проектът идва от среда със **namespace префикс** (например `aiops_education__`), трябва да го премахнеш:

#### **Стъпка 2.1: Automատична замяна на префикса**
```bash
cd "/Users/aleksandar.aleksandrov/Desktop/PU Bike/Salesforce-Bike-Shop"
find . -type f \( -name "*.cls" -o -name "*.js" -o -name "*.html" -o -name "*.json" -o -name "*.xml" \) \
  -not -path "*/node_modules/*" \
  -exec sed -i '' 's/aiops_education__//g' {} \;
```

Това премахва префикса от:
- ✅ Apex класове (`.cls`)
- ✅ JavaScript файлове (`.js`)
- ✅ HTML шаблони (`.html`)
- ✅ Metadata XML файлове (`.xml`)
- ✅ JSON конфигурации (`.json`)

#### **Стъпка 2.2: Проверка на премахването**
```bash
grep -r "aiops_education__" . --include="*.cls" --include="*.js" --include="*.html" | wc -l
```
Трябва да връща `0` (нулеви съвпадения)

### FASE 3: Деплой на проекта

#### **Стъпка 3.1: Полен деплой**
```bash
sf project deploy start --wait 10
```

Очакуван резултат:
```
Status: Succeeded
Components: 41/41 (100%)
```

#### **Стъпка 3.2: Проверка за грешки**
Ако имаш грешки като:
```
We couldn't retrieve the design time component information for component aiops_education:bikeShopApp.
In field: object - no CustomObject named aiops_education__Bike__c found
```

Това означава, че **префиксът не е премахнат напълно**. Повтори Стъпка 2.1.

### FASE 4: Присвояване на разрешения

#### **Стъпка 4.1: Присвой Permission Set на потребителя**
```bash
sf org assign permset --name Bike_Shop_App_Access
```

Резултат:
```
Permission Set Assignment
✔ Bike_Shop_App_Access assigned to stu2401322033.c9195e8f6294@agentforce.com
```

Това дава достъп до:
- ✅ Bike Shop приложението
- ✅ CRUD операции на Bike, Customer, Bike_Rental обекти
- ✅ API разрешения

### FASE 5: Създаване на Connected App за OAuth

Този процес **трябва да се направи ръчно през UI**, защото metadata деплоя има ограничения.

#### **Стъпка 5.1: Отвори App Manager**
1. В Salesforce, натисни **Ctrl+K** (или кликни иконката за търсене)
2. Търси: `App Manager`
3. Кликни на първия резултат

#### **Стъпка 5.2: Създай нова Connected App**
1. Кликни **"New Connected App"** (горе вдясно)
2. Попълни формата:
   - **Connected App Name**: `BikeShop Postman App`
   - **API Name**: `BikeShop_Postman_App` (автоматично)
   - **Contact Email**: `твоя-почта@example.com`
   - **Description**: `OAuth app for Bike Shop REST API testing via Postman`

#### **Стъпка 5.3: Включи OAuth настройки**
1. Марки чекбокса: **"Enable OAuth Settings"**
2. **Callback URL**: `https://oauth.pstmn.io/v1/callback`
3. **Selected OAuth Scopes** - Добави тези три:
   - ✅ `Access the Identity URL service`
   - ✅ `Perform requests on your behalf at any time`
   - ✅ `Access your basic information`
4. Кликни **Save**

#### **Стъпка 5.4: Генерирай Consumer Key и Secret**
1. После refresh на страницата, намери секцията **"OAuth 2.0 Credential ID:"**
2. До Consumer Secret има бутон **"Click to reveal"**
3. Копирай двете стойности и ги запази в сигурно място:
   ```
   Consumer Key: 3MVG9...XHoU...TXwwHz...
   Consumer Secret: 1234567890ABC...XYZ...
   ```

### FASE 6: Конфигурация на Postman

#### **Стъпка 6.1: Импортирай Postman колекция**
1. Отвори Postman
2. Кликни **Import** (горе вляво)
3. Избери файла: `BikeShop_API_Collection_No_Namespace.postman_collection.json`
4. Кликни **Import**

#### **Стъпка 6.2: Обнови променливите на колекцията**
1. В Postman, под колекцията `Bike Shop SOQL REST API Collection`, кликни **Variables** таб
2. Обнови следните **CURRENT VALUE** стойности:
   ```
   baseUrl = https://твоя-org.develop.my.salesforce.com
   clientId = (Consumer Key от Стъпка 5.4)
   clientSecret = (Consumer Secret от Стъпка 5.4)
   tokenUrl = https://твоя-org.develop.my.salesforce.com/services/oauth2/token
   authorizationUrl = https://твоя-org.develop.my.salesforce.com/services/oauth2/authorize
   ```
3. Кликни **Save** (Ctrl+S)

Пример как да видиш твоя URL:
```bash
sf org display | grep "Instance URL"
# Резултат: Instance URL: https://stu2401322033.c9195e8f6294.develop.my.salesforce.com
```

#### **Стъпка 6.3: Настрой OAuth 2.0 в Postman**
1. В Postman колекцията, отвори **Authorization** таб (в корена на колекцията)
2. Избери **Type**: `OAuth 2.0`
3. Кликни **Get New Access Token**
4. Попълни формата:
   ```
   Token Name = BikeShop OAuth Token
   Grant Type = Authorization Code
   Callback URL = https://oauth.pstmn.io/v1/callback
   Authorize using browser = ✅ (checked)
   Auth URL = {{authorizationUrl}}
   Access Token URL = {{tokenUrl}}
   Client ID = {{clientId}}
   Client Secret = {{clientSecret}}
   Scope = api refresh_token web
   Client Authentication = Send as Basic Auth header
   ```
5. Кликни **Get New Access Token**

#### **Стъпка 6.4: Одобри достъпа в браузър**
1. Ще се отвори нов браузър с Salesforce login страница
2. Логирай се със своя Salesforce учетна запис
3. Прочети разрешенията и кликни **Allow** / **Approve**
4. Ще видиш: "Authorization successful" или подобно съобщение
5. Вълнизъ се връщаш в Postman

#### **Стъпка 6.5: Проверка на токена**
Постман трябва да покажа:
```
✅ Token: 00DgK000006i5Gf!AQEAQCf3VfaYKW53xG...
✅ Token expires in: 7200 (2 часа)
```

Кликни **Use Token** или **Proceed**

### FASE 7: ВАЖНО - Настройка на Token Expiration

Ако получиш грешка как `Invalid Session ID` или `unauthorized` със списък URL-и, това означава че **токенът е изтекъл**.

**Решение: Включи Auto Refresh на токена**

1. В Postman, отвори колекцията → **Authorization** таб
2. Прокручи надолу до **Advanced Options**
3. Включи: ✅ `Automatically refresh access token`
4. Save

Това гарантира, че Postman автоматично ще обновява токена преди той да изтече.

### FASE 8: Тестване на REST API

#### **Стъпка 8.1: Направи първия тест**
1. В колекцията, отвори фолдера **BIKES API**
2. Избери request-а: **Get All Bikes**
3. Кликни **Send** (синия бутон)

#### **Стъпка 8.2: Проверка на резултата**
Ако е успешно, трябва да видиш:
```json
{
  "totalSize": 2,
  "done": true,
  "records": [
    {
      "attributes": {
        "type": "Bike__c",
        "url": "/services/data/v66.0/sobjects/Bike__c/a03gK00000SeTUcQAN"
      },
      "Id": "a03gK00000SeTUcQAN",
      "Name": "Gambler Scott",
      "Model__c": "Gambler",
      "Brand__c": "Scott",
      ...
    }
  ]
}
```

Status трябва да е **200 OK** или **201 Created** (не 401, 403, 404)

---

## REST ендпойнти

### Bikes
- `GET /services/apexrest/bikeshop/v1/bikes?page=1&pageSize=10` - Вземи всички велосипеди
- `GET /services/apexrest/bikeshop/v1/bikes/{id}` - Вземи един велосипед
- `POST /services/apexrest/bikeshop/v1/bikes` - Създай нов велосипед
- `PATCH /services/apexrest/bikeshop/v1/bikes/{id}` - Обнови велосипед
- `DELETE /services/apexrest/bikeshop/v1/bikes/{id}` - Изтрий велосипед

### Customers
- `GET /services/apexrest/bikeshop/v1/customers?page=1&pageSize=10` - Вземи всички клиенти
- `POST /services/apexrest/bikeshop/v1/customers` - Създай нов клиент
- `PATCH /services/apexrest/bikeshop/v1/customers/{id}` - Обнови клиент
- `DELETE /services/apexrest/bikeshop/v1/customers/{id}` - Изтрий клиент

### Rentals
- `GET /services/apexrest/bikeshop/v1/rentals?page=1&pageSize=10` - Вземи всички наеми
- `POST /services/apexrest/bikeshop/v1/rentals` - Създай нов наем
- `PATCH /services/apexrest/bikeshop/v1/rentals/{id}` - Обнови наем
- `DELETE /services/apexrest/bikeshop/v1/rentals/{id}` - Изтрий наем

---

## 🔧 Отстраняване на проблеми

### Проблем: `We couldn't retrieve the design time component information`
**Причина**: Namespace префиксът не е премахнат
**Решение**: Повтори Fase 2 (sed замяна)

### Проблем: `No CustomObject named Bike__c found`
**Причина**: Обектите още имат стар префикс в permissionset
**Решение**: Провери `force-app/main/default/permissionsets/*.xml` и премахни префиксите

### Проблем: `Invalid Session ID` / `unauthorized` в Postman
**Причина**: Токенът е изтекъл (стандартно - 2 часа)
**Решение**: 
1. Включи auto-refresh на токена (Fase 7)
2. ИЛИ ръчно генерирай нов токен (Fase 6.3-6.5)

### Проблем: `404 Not Found` на REST endpoints
**Причина**: Apex REST Services са отключени в org
**Решение**: 
1. Отвори Setup → Развернат търсачка → `REST API`
2. Убедис се, че е включено
3. Алтернатива: Използвай SOQL REST API вместо Apex REST (`/services/data/v66.0/query`)

---
