global class CustomerListResponseDto {
    global List<CustomerDto> records;
    global Integer total;
    global Integer page;
    global Integer pageSize;

    global CustomerListResponseDto(List<CustomerDto> records, Integer total, Integer page, Integer pageSize) {
        this.records = records;
        this.total = total;
        this.page = page;
        this.pageSize = pageSize;
    }
}
