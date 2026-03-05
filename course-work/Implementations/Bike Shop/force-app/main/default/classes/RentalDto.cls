global class RentalDto {
    global String id;
    global String bikeId;
    global String bikeName;
    global String customerId;
    global String customerName;
    global String startDate;
    global String endDate;
    global Decimal dailyPrice;
    global Decimal totalAmount;
    global String status;
    global Boolean paid;

    global RentalDto(Bike_Rental__c rental) {
        this.id = rental.Id;
        this.bikeId = rental.Bike__c;
        this.bikeName = rental.Bike__r == null ? null : rental.Bike__r.Name;
        this.customerId = rental.Customer__c;
        this.customerName = rental.Customer__r == null ? null : rental.Customer__r.Name;
        this.startDate = rental.Start_Date__c == null ? null : rental.Start_Date__c.format();
        this.endDate = rental.End_Date__c == null ? null : rental.End_Date__c.format();
        this.dailyPrice = rental.Daily_Price__c;
        this.totalAmount = rental.Total_Amount__c;
        this.status = rental.Status__c;
        this.paid = rental.Paid__c;
    }
}
