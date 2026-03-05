global class RentalListResponseDto {
    global List<RentalDto> records;
    global Integer total;
    global Integer page;
    global Integer pageSize;

    global RentalListResponseDto(List<RentalDto> records, Integer total, Integer page, Integer pageSize) {
        this.records = records;
        this.total = total;
        this.page = page;
        this.pageSize = pageSize;
    }
}
