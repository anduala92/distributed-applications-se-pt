import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getBikes from '@salesforce/apex/BikeShopLwcController.getBikes';
import saveBikeRecord from '@salesforce/apex/BikeShopLwcController.saveBike';
import deleteBikeRecord from '@salesforce/apex/BikeShopLwcController.deleteBike';
import getCustomers from '@salesforce/apex/BikeShopLwcController.getCustomers';
import saveCustomerRecord from '@salesforce/apex/BikeShopLwcController.saveCustomer';
import deleteCustomerRecord from '@salesforce/apex/BikeShopLwcController.deleteCustomer';
import getRentals from '@salesforce/apex/BikeShopLwcController.getRentals';
import searchRentals from '@salesforce/apex/BikeShopLwcController.searchRentals';
import saveRentalRecord from '@salesforce/apex/BikeShopLwcController.saveRental';
import deleteRentalRecord from '@salesforce/apex/BikeShopLwcController.deleteRental';
import getBikeOptions from '@salesforce/apex/BikeShopLwcController.getBikeOptions';
import getCustomerOptions from '@salesforce/apex/BikeShopLwcController.getCustomerOptions';
import getStatusOptions from '@salesforce/apex/BikeShopLwcController.getStatusOptions';
import checkBikeAvailability from '@salesforce/apex/BikeShopLwcController.checkBikeAvailability';
import getBikeCategoryOptions from '@salesforce/apex/BikeShopLwcController.getBikeCategoryOptions';

const PAGE_SIZE = 5;

export default class BikeShopApp extends LightningElement {
    errorMessage;
    pageSize = PAGE_SIZE;
    todayDate;

    connectedCallback() {
        const today = new Date();
        this.todayDate = today.toISOString().split('T')[0];
        this.loadRentalOptions();
        this.loadBikeCategoryOptions();
    }

    /**
     * Преобразува UTC дата от Salesforce към браузърния timezone
     * Salesforce връща YYYY-MM-DD което е дата в UTC
     * Нужно е да преобразува към браузърния timezone за показване
     * @param {string} dateStr - YYYY-MM-DD дата от Salesforce (UTC)
     * @returns {string} - YYYY-MM-DD дата в браузърния timezone
     */
    convertUTCToLocalDate(dateStr) {
        if (!dateStr) return dateStr;
        
        // Парсирай датата като UTC
        const [year, month, day] = dateStr.split('-').map(Number);
        
        // Създай Date обект като UTC 00:00:00
        const utcDate = new Date(Date.UTC(year, month - 1, day, 0, 0, 0));
        
        // Браузърът ще го интерпретира като локален timezone
        // getTimezoneOffset() връща ОТРИЦАТЕЛЕН брой минути за offset
        // Например за +2:00 връща -120 (минус 120 минути)
        // За да преобразувам UTC към локален, трябва да добавя offset
        const offsetMs = utcDate.getTimezoneOffset() * 60 * 1000;
        const localDate = new Date(utcDate.getTime() - offsetMs);
        
        // Върни в YYYY-MM-DD формат
        const localYear = localDate.getUTCFullYear();
        const localMonth = String(localDate.getUTCMonth() + 1).padStart(2, '0');
        const localDay = String(localDate.getUTCDate()).padStart(2, '0');
        
        const result = `${localYear}-${localMonth}-${localDay}`;
        console.log(`Converting UTC date: ${dateStr} (offset: ${utcDate.getTimezoneOffset()} min) → Local: ${result}`);
        return result;
    }

    bikeColumns = [
        { label: 'Id', fieldName: 'Id' },
        { label: 'Model - Brand', fieldName: 'bikeDisplayName' },
        { label: 'Category', fieldName: 'Category__c' },
        { label: 'Rate', fieldName: 'Daily_Rate__c', type: 'currency' },
        { label: 'Available', fieldName: 'Available__c', type: 'boolean' }
    ];

    customerColumns = [
        { label: 'Id', fieldName: 'Id' },
        { label: 'Name', fieldName: 'Name' },
        { label: 'First Name', fieldName: 'First_Name__c' },
        { label: 'Last Name', fieldName: 'Last_Name__c' },
        { label: 'Email', fieldName: 'Email__c' },
        { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean' }
    ];

    rentalColumns = [
        { label: 'Id', fieldName: 'Id' },
        { label: 'Number', fieldName: 'Name' },
        { label: 'Bike', fieldName: 'BikeName' },
        { label: 'Customer', fieldName: 'CustomerName' },
        { label: 'Start', fieldName: 'Start_Date__c', type: 'date' },
        { label: 'End', fieldName: 'End_Date__c', type: 'date' },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'Total', fieldName: 'Total_Amount__c', type: 'currency' }
    ];

    bikes = [];
    customers = [];
    rentals = [];

    bikeSearch = '';
    customerSearch = '';
    rentalSearch = '';
    rentalStatusFilter = '';

    bikeSelectedId;
    bikeSelectedIds = [];
    customerSelectedIds = [];
    rentalSelectedId;
    rentalSelectedIds = [];

    bikePage = 1;
    bikeTotal = 0;
    customerPage = 1;
    customerTotal = 0;
    rentalPage = 1;
    rentalTotal = 0;

    bikeForm = { 'Available__c': true };
    customerForm = { 'Is_Active__c': true };
    rentalForm = { 'Paid__c': false, 'Status__c': 'Draft' };

    bikeOptions = [];
    bikeCategoryOptions = [];
    customerOptions = [];
    statusOptions = [];
    statusFilterOptions = [];
    rentalTotalDays = 0;

    get bikeName() {
        const model = this.bikeForm.Model__c || '';
        const brand = this.bikeForm.Brand__c || '';
        if (model && brand) {
            return `${brand} - ${model}`;
        }
        return this.bikeForm.Name || '';
    }

    get rentalTotalAmount() {
        const dailyPrice = Number(this.rentalForm.Daily_Price__c) || 0;
        if (this.rentalTotalDays > 0 && dailyPrice > 0) {
            return (this.rentalTotalDays * dailyPrice).toFixed(2);
        }
        return '0.00';
    }

    get bikeTotalPages() {
        return Math.max(1, Math.ceil(this.bikeTotal / PAGE_SIZE));
    }

    get customerTotalPages() {
        return Math.max(1, Math.ceil(this.customerTotal / PAGE_SIZE));
    }

    get rentalTotalPages() {
        return Math.max(1, Math.ceil(this.rentalTotal / PAGE_SIZE));
    }

    wiredBikesResult;
    wiredCustomersResult;
    wiredRentalsResult;

    @wire(getBikes, { pageNumber: '$bikePage', pageSize: '$pageSize', search: '$bikeSearch' })
    wiredBikes(result) {
        this.wiredBikesResult = result;
        const { data, error } = result;
        if (data) {
            this.bikes = (data.records || []).map((record) => ({
                ...record,
                bikeDisplayName: record.Brand__c && record.Model__c 
                    ? `${record.Brand__c} - ${record.Model__c}` 
                    : record.Name
            }));
            this.bikeTotal = data.total || 0;
            this.errorMessage = null;
        } else if (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    @wire(getCustomers, { pageNumber: '$customerPage', pageSize: '$pageSize', search: '$customerSearch' })
    wiredCustomers(result) {
        this.wiredCustomersResult = result;
        const { data, error } = result;
        if (data) {
            this.customers = data.records || [];
            this.customerTotal = data.total || 0;
            this.errorMessage = null;
        } else if (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    @wire(searchRentals, { pageNumber: '$rentalPage', pageSize: '$pageSize', searchText: '$rentalSearch', status: '$rentalStatusFilter' })
    wiredRentals(result) {
        this.wiredRentalsResult = result;
        const { data, error } = result;
        if (data) {
            this.rentals = (data.records || []).map((record) => {
                // Salesforce връща датите като YYYY-MM-DD в UTC
                // Браузърът ги интерпретира като локален timezone и ги мести
                // Трябва да парсирам като UTC и преобразувам към браузърния timezone
                const transformedRecord = {
                    ...record,
                    BikeName: record.Bike__r ? record.Bike__r.Name : '',
                    CustomerName: record.Customer__r ? record.Customer__r.Name : '',
                    // Преобразува UTC датите към браузърния timezone за показване
                    Start_Date__c: record.Start_Date__c 
                        ? this.convertUTCToLocalDate(record.Start_Date__c)
                        : null,
                    End_Date__c: record.End_Date__c 
                        ? this.convertUTCToLocalDate(record.End_Date__c)
                        : null
                };
                console.log('Read rental dates:', {
                    received_start: record.Start_Date__c,
                    converted_start: transformedRecord.Start_Date__c,
                    received_end: record.End_Date__c,
                    converted_end: transformedRecord.End_Date__c
                });
                return transformedRecord;
            });
            this.rentalTotal = data.total || 0;
            this.errorMessage = null;
        } else if (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    handleSearchChange(event) {
        const key = event.target.dataset.search;
        if (key === 'bike') {
            this.bikeSearch = event.target.value;
            this.bikePage = 1;
        } else if (key === 'customer') {
            this.customerSearch = event.target.value;
            this.customerPage = 1;
        }
    }

    handleStatusFilterChange(event) {
        this.rentalStatusFilter = event.detail.value;
        this.rentalPage = 1;
    }

    handleRentalSearchChange(event) {
        this.rentalSearch = event.target.value;
        this.rentalPage = 1;
    }

    handleFormInput(event) {
        const entity = event.target.dataset.entity;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.updateForm(entity, field, value);
        
        // Trigger rental summary update for date changes
        if (entity === 'rental' && (field === 'Start_Date__c' || field === 'End_Date__c')) {
            this.updateRentalSummary();
        }
    }

    handleFormCheckbox(event) {
        const entity = event.target.dataset.entity;
        const field = event.target.dataset.field;
        const value = event.target.checked;
        this.updateForm(entity, field, value);
    }

    updateForm(entity, field, value) {
        if (entity === 'bike') {
            this.bikeForm = { ...this.bikeForm, [field]: value };
        } else if (entity === 'customer') {
            this.customerForm = { ...this.customerForm, [field]: value };
        } else {
            this.rentalForm = { ...this.rentalForm, [field]: value };
        }
    }

    clearEntityValidation(entity) {
        const inputs = this.template.querySelectorAll(`lightning-input[data-entity="${entity}"]`);
        inputs.forEach((input) => {
            input.setCustomValidity('');
            input.reportValidity();
        });
    }

    validateBikeForm() {
        this.clearEntityValidation('bike');
        let valid = true;

        const model = (this.bikeForm.Model__c || '').trim();
        const brand = (this.bikeForm.Brand__c || '').trim();
        const category = (this.bikeForm.Category__c || '').trim();
        const dailyRateRaw = this.bikeForm.Daily_Rate__c;
        const dailyRate = Number(dailyRateRaw);
        const lastServiceDate = this.bikeForm.Last_Service_Date__c;

        const modelInput = this.template.querySelector('lightning-input[data-entity="bike"][data-field="Model__c"]');
        const brandInput = this.template.querySelector('lightning-input[data-entity="bike"][data-field="Brand__c"]');
        const categoryInput = this.template.querySelector('lightning-input[data-entity="bike"][data-field="Category__c"]');
        const rateInput = this.template.querySelector('lightning-input[data-entity="bike"][data-field="Daily_Rate__c"]');
        const lastServiceInput = this.template.querySelector('lightning-input[data-entity="bike"][data-field="Last_Service_Date__c"]');

        if (!model && modelInput) {
            modelInput.setCustomValidity('Model is required.');
            modelInput.reportValidity();
            valid = false;
        }
        if (!brand && brandInput) {
            brandInput.setCustomValidity('Brand is required.');
            brandInput.reportValidity();
            valid = false;
        }
        if (!category && categoryInput) {
            categoryInput.setCustomValidity('Category is required.');
            categoryInput.reportValidity();
            valid = false;
        }
        if (!dailyRateRaw && dailyRateRaw !== 0 && rateInput) {
            rateInput.setCustomValidity('Daily Rate is required.');
            rateInput.reportValidity();
            valid = false;
        } else if ((Number.isNaN(dailyRate) || dailyRate <= 0) && rateInput) {
            rateInput.setCustomValidity('Daily Rate must be greater than 0.');
            rateInput.reportValidity();
            valid = false;
        }
        if (lastServiceDate && lastServiceDate > this.todayDate && lastServiceInput) {
            lastServiceInput.setCustomValidity('Last Service Date cannot be in the future.');
            lastServiceInput.reportValidity();
            valid = false;
        }

        if (!valid) {
            this.errorMessage = 'Please fill all required Bike fields correctly.';
        }
        return valid;
    }

    validateCustomerForm() {
        this.clearEntityValidation('customer');
        let valid = true;

        const firstName = (this.customerForm.First_Name__c || '').trim();
        const lastName = (this.customerForm.Last_Name__c || '').trim();
        const email = (this.customerForm.Email__c || '').trim();
        const phone = (this.customerForm.Phone__c || '').trim();
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const phoneRegex = /^[\+]?[0-9]{10,15}$/;

        const firstNameInput = this.template.querySelector('lightning-input[data-entity="customer"][data-field="First_Name__c"]');
        const lastNameInput = this.template.querySelector('lightning-input[data-entity="customer"][data-field="Last_Name__c"]');
        const emailInput = this.template.querySelector('lightning-input[data-entity="customer"][data-field="Email__c"]');
        const phoneInput = this.template.querySelector('lightning-input[data-entity="customer"][data-field="Phone__c"]');

        if (!firstName && firstNameInput) {
            firstNameInput.setCustomValidity('First Name is required.');
            firstNameInput.reportValidity();
            valid = false;
        }
        if (!lastName && lastNameInput) {
            lastNameInput.setCustomValidity('Last Name is required.');
            lastNameInput.reportValidity();
            valid = false;
        }
        if (!email && emailInput) {
            emailInput.setCustomValidity('Email is required.');
            emailInput.reportValidity();
            valid = false;
        } else if (email && !emailRegex.test(email) && emailInput) {
            emailInput.setCustomValidity('Please enter a valid email address.');
            emailInput.reportValidity();
            valid = false;
        }
        
        if (phone && !phoneRegex.test(phone) && phoneInput) {
            phoneInput.setCustomValidity('Phone must be 10-15 digits, optionally starting with +');
            phoneInput.reportValidity();
            valid = false;
        }

        if (!valid) {
            this.errorMessage = 'Please fill all required Customer fields correctly.';
        }
        return valid;
    }

    validateRentalForm() {
        this.clearEntityValidation('rental');
        let valid = true;

        const bikeId = (this.rentalForm.Bike__c || '').trim();
        const customerId = (this.rentalForm.Customer__c || '').trim();
        const startDate = this.rentalForm.Start_Date__c;
        const endDate = this.rentalForm.End_Date__c;
        const dailyPriceRaw = this.rentalForm.Daily_Price__c;
        const dailyPrice = Number(dailyPriceRaw);
        const status = (this.rentalForm.Status__c || '').trim();

        const bikeIdInput = this.template.querySelector('lightning-input[data-entity="rental"][data-field="Bike__c"]');
        const customerIdInput = this.template.querySelector('lightning-input[data-entity="rental"][data-field="Customer__c"]');
        const startDateInput = this.template.querySelector('lightning-input[data-entity="rental"][data-field="Start_Date__c"]');
        const endDateInput = this.template.querySelector('lightning-input[data-entity="rental"][data-field="End_Date__c"]');
        const dailyPriceInput = this.template.querySelector('lightning-input[data-entity="rental"][data-field="Daily_Price__c"]');
        const statusInput = this.template.querySelector('lightning-input[data-entity="rental"][data-field="Status__c"]');

        if (!bikeId && bikeIdInput) {
            bikeIdInput.setCustomValidity('Bike is required.');
            bikeIdInput.reportValidity();
            valid = false;
        }
        if (!customerId && customerIdInput) {
            customerIdInput.setCustomValidity('Customer is required.');
            customerIdInput.reportValidity();
            valid = false;
        }
        if (!startDate && startDateInput) {
            startDateInput.setCustomValidity('Start Date is required.');
            startDateInput.reportValidity();
            valid = false;
        } else if (startDate && startDate < this.todayDate && startDateInput) {
            startDateInput.setCustomValidity('Start Date cannot be in the past.');
            startDateInput.reportValidity();
            valid = false;
        }
        if (!endDate && endDateInput) {
            endDateInput.setCustomValidity('End Date is required.');
            endDateInput.reportValidity();
            valid = false;
        } else if (endDate && endDate < this.todayDate && endDateInput) {
            endDateInput.setCustomValidity('End Date cannot be in the past.');
            endDateInput.reportValidity();
            valid = false;
        }
        if (startDate && endDate && endDate < startDate && endDateInput) {
            endDateInput.setCustomValidity('End Date must be equal to or after Start Date.');
            endDateInput.reportValidity();
            valid = false;
        }
        if (!dailyPriceRaw && dailyPriceRaw !== 0 && dailyPriceInput) {
            dailyPriceInput.setCustomValidity('Daily Price is required.');
            dailyPriceInput.reportValidity();
            valid = false;
        } else if ((Number.isNaN(dailyPrice) || dailyPrice <= 0) && dailyPriceInput) {
            dailyPriceInput.setCustomValidity('Daily Price must be greater than 0.');
            dailyPriceInput.reportValidity();
            valid = false;
        }
        if (!status && statusInput) {
            statusInput.setCustomValidity('Status is required.');
            statusInput.reportValidity();
            valid = false;
        }

        if (!valid) {
            this.errorMessage = 'Please fill all required Rental fields correctly.';
        }
        return valid;
    }

    async validateRentalAvailability() {
        const bikeId = this.rentalForm.Bike__c;
        const startDate = this.rentalForm.Start_Date__c;
        const endDate = this.rentalForm.End_Date__c;
        const rentalId = this.rentalForm.Id;
        
        if (!bikeId || !startDate || !endDate) {
            return true; // Skip availability check if not all fields are filled
        }
        
        try {
            const result = await checkBikeAvailability({
                bikeId,
                startDate,
                endDate,
                excludeRentalId: rentalId || null
            });
            
            if (!result.isAvailable && result.conflictingRentals.length > 0) {
                const conflicts = result.conflictingRentals;
                let errorMsg = 'Bike is not available for the selected dates due to the following conflicts:\n';
                conflicts.forEach(conflict => {
                    errorMsg += `- Rental ${conflict.rentalName} (${conflict.customerName}): ${conflict.startDate} to ${conflict.endDate}\n`;
                });
                
                const startDateInput = this.template.querySelector('lightning-input[data-entity="rental"][data-field="Start_Date__c"]');
                if (startDateInput) {
                    startDateInput.setCustomValidity(errorMsg);
                    startDateInput.reportValidity();
                }
                return false;
            }
            return true;
        } catch (error) {
            console.error('Error checking bike availability:', error);
            this.errorMessage = 'Error checking bike availability: ' + (error.body?.message || error.message);
            return false;
        }
    }

    async loadBikes() {
        if (this.wiredBikesResult) {
            await refreshApex(this.wiredBikesResult);
        }
    }

    handleBikeSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.bikeSelectedIds = selectedRows.map(row => row.Id);
            if (selectedRows.length === 1) {
                this.bikeForm = { ...selectedRows[0] };
            }
        }
    }

    async saveBike() {
        if (!this.validateBikeForm()) {
            return;
        }
        try {
            this.errorMessage = null;
            await saveBikeRecord({ payload: this.bikeForm });
            this.resetBikeForm();
            await this.loadBikes();
            await this.loadRentalOptions();
        } catch (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    async deleteBike() {
        if (!this.bikeSelectedIds || this.bikeSelectedIds.length === 0) {
            return;
        }
        try {
            this.errorMessage = null;
            for (const bikeId of this.bikeSelectedIds) {
                await deleteBikeRecord({ bikeId });
            }
            this.resetBikeForm();
            await this.loadBikes();
            await this.loadRentalOptions();
        } catch (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    resetBikeForm() {
        this.bikeForm = { 'Available__c': true, Name: null };
        this.bikeSelectedIds = [];
    }

    async loadCustomers() {
        if (this.wiredCustomersResult) {
            await refreshApex(this.wiredCustomersResult);
        }
    }

    handleCustomerSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.customerSelectedIds = selectedRows.map(row => row.Id);
            if (selectedRows.length === 1) {
                this.customerForm = { ...selectedRows[0] };
            }
        }
    }

    async saveCustomer() {
        if (!this.validateCustomerForm()) {
            return;
        }
        try {
            this.errorMessage = null;
            await saveCustomerRecord({ payload: this.customerForm });
            this.resetCustomerForm();
            await this.loadCustomers();
            await this.loadRentalOptions();
        } catch (error) {
            const message = error.body?.message || error.message || 'Error saving customer';
            this.errorMessage = message;
            console.error('Save Customer Error:', message);
        }
    }

    async deleteCustomer() {
        if (!this.customerSelectedIds || this.customerSelectedIds.length === 0) {
            return;
        }
        try {
            this.errorMessage = null;
            for (const customerId of this.customerSelectedIds) {
                await deleteCustomerRecord({ customerId });
            }
            this.resetCustomerForm();
            await this.loadCustomers();
            await this.loadRentalOptions();
        } catch (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    resetCustomerForm() {
        this.customerForm = { 'Is_Active__c': true };
        this.customerSelectedIds = [];
    }

    async loadRentals() {
        if (this.wiredRentalsResult) {
            await refreshApex(this.wiredRentalsResult);
        }
    }

    connectedCallbackForRentals() {
        this.loadRentalOptions();
    }

    async loadRentalOptions() {
        try {
            const bikes = await getBikeOptions();
            const customers = await getCustomerOptions();
            const statuses = await getStatusOptions();
            
            this.bikeOptions = bikes || [];
            this.customerOptions = customers || [];
            this.statusOptions = (statuses || []).map(status => ({ label: status, value: status }));
            
            // Create filter options with empty option at the top
            this.statusFilterOptions = [
                { label: 'All Statuses', value: '' },
                ...this.statusOptions
            ];
        } catch (error) {
            console.error('Error loading rental options:', error);
            this.errorMessage = 'Error loading rental options: ' + (error.body?.message || error.message);
        }
    }

    async loadBikeCategoryOptions() {
        try {
            const categories = await getBikeCategoryOptions();
            this.bikeCategoryOptions = (categories || []).map(category => ({ 
                label: category, 
                value: category 
            }));
        } catch (error) {
            console.error('Error loading bike category options:', error);
        }
    }

    handleRentalSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.rentalSelectedIds = selectedRows.map(row => row.Id);
            this.rentalSelectedId = selectedRows[0].Id;
            this.rentalForm = { ...selectedRows[0] };
        }
    }

    handleBikeChange(event) {
        const selectedBikeId = event.detail.value;
        const selectedBike = this.bikeOptions.find(bike => bike.value === selectedBikeId);
        if (selectedBike) {
            this.rentalForm = { 
                ...this.rentalForm, 
                Bike__c: selectedBikeId,
                Daily_Price__c: Number(selectedBike.dailyRate)
            };
            this.updateRentalSummary();
        }
    }

    handleCustomerChange(event) {
        const selectedCustomerId = event.detail.value;
        this.rentalForm = { 
            ...this.rentalForm, 
            Customer__c: selectedCustomerId
        };
    }

    handleStatusChange(event) {
        const selectedStatus = event.detail.value;
        this.rentalForm = { 
            ...this.rentalForm, 
            Status__c: selectedStatus
        };
        this.updateRentalSummary();
    }

    updateRentalSummary() {
        const startDate = this.rentalForm.Start_Date__c;
        const endDate = this.rentalForm.End_Date__c;
        const dailyPrice = Number(this.rentalForm.Daily_Price__c) || 0;

        if (startDate && endDate && dailyPrice > 0) {
            // Преобразуване на дати без timezone конверсии
            // Формат: YYYY-MM-DD
            const startParts = startDate.split('-');
            const endParts = endDate.split('-');
            
            const startDateObj = new Date(parseInt(startParts[0]), parseInt(startParts[1]) - 1, parseInt(startParts[2]), 12, 0, 0);
            const endDateObj = new Date(parseInt(endParts[0]), parseInt(endParts[1]) - 1, parseInt(endParts[2]), 12, 0, 0);
            
            // Брой дни включително двата края
            const timeDiff = endDateObj - startDateObj;
            const days = Math.round(timeDiff / (1000 * 60 * 60 * 24)) + 1;
            this.rentalTotalDays = days > 0 ? days : 0;
        } else {
            this.rentalTotalDays = 0;
        }
    }

    async saveRental() {
        if (!this.validateRentalForm()) {
            return;
        }
        
        // Check bike availability before saving
        const isAvailable = await this.validateRentalAvailability();
        if (!isAvailable) {
            return;
        }
        
        try {
            this.errorMessage = null;
            const payload = { ...this.rentalForm };
            delete payload.BikeName;
            delete payload.CustomerName;
            delete payload.Bike__r;
            delete payload.Customer__r;
            payload.Total_Amount__c = Number(this.rentalTotalAmount);
            
            // НЕ конвертирай датите - пращай точно което user избра
            // Input field дава YYYY-MM-DD което user вижда
            // Salesforce ще го парсира като YYYY-MM-DD без timezone смяна
            if (payload.Start_Date__c) {
                payload.Start_Date__c = String(payload.Start_Date__c);
                console.log('Saving Start Date as-is:', payload.Start_Date__c);
            }
            if (payload.End_Date__c) {
                payload.End_Date__c = String(payload.End_Date__c);
                console.log('Saving End Date as-is:', payload.End_Date__c);
            }
            
            await saveRentalRecord({ payload });
            this.resetRentalForm();
            await this.loadRentals();
        } catch (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    async deleteRental() {
        if (!this.rentalSelectedIds || this.rentalSelectedIds.length === 0) {
            return;
        }
        try {
            this.errorMessage = null;
            // Delete multiple selected rentals
            for (const rentalId of this.rentalSelectedIds) {
                await deleteRentalRecord({ rentalId });
            }
            this.resetRentalForm();
            await this.loadRentals();
        } catch (error) {
            this.errorMessage = error.body?.message || error.message;
        }
    }

    resetRentalForm() {
        this.rentalForm = { 'Paid__c': false, 'Status__c': 'Draft' };
        this.rentalSelectedId = null;
        this.rentalSelectedIds = [];
        this.rentalTotalDays = 0;
    }

    prevBikePage() {
        if (this.bikePage > 1) {
            this.bikePage -= 1;
            this.loadBikes();
        }
    }

    nextBikePage() {
        if (this.bikePage < this.bikeTotalPages) {
            this.bikePage += 1;
            this.loadBikes();
        }
    }

    prevCustomerPage() {
        if (this.customerPage > 1) {
            this.customerPage -= 1;
            this.loadCustomers();
        }
    }

    nextCustomerPage() {
        if (this.customerPage < this.customerTotalPages) {
            this.customerPage += 1;
            this.loadCustomers();
        }
    }

    prevRentalPage() {
        if (this.rentalPage > 1) {
            this.rentalPage -= 1;
            this.loadRentals();
        }
    }

    nextRentalPage() {
        if (this.rentalPage < this.rentalTotalPages) {
            this.rentalPage += 1;
            this.loadRentals();
        }
    }
}