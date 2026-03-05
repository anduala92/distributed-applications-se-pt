global class CustomerDto {
    global String id;
    global String name;
    global String firstName;
    global String lastName;
    global String email;
    global String phone;
    global String birthDate;
    global Integer loyaltyPoints;
    global Boolean isActive;

    global CustomerDto(Customer__c customer) {
        this.id = customer.Id;
        this.name = customer.Name;
        this.firstName = customer.First_Name__c;
        this.lastName = customer.Last_Name__c;
        this.email = customer.Email__c;
        this.phone = customer.Phone__c;
        this.birthDate = customer.Birth_Date__c == null ? null : customer.Birth_Date__c.format();
        this.loyaltyPoints = customer.Loyalty_Points__c == null ? 0 : Integer.valueOf(customer.Loyalty_Points__c);
        this.isActive = customer.Is_Active__c;
    }
}
