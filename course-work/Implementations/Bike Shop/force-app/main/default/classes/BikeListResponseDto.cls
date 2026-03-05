global class BikeListResponseDto {
    global List<BikeDto> records;
    global Integer total;
    global Integer page;
    global Integer pageSize;

    global BikeListResponseDto(List<BikeDto> records, Integer total, Integer page, Integer pageSize) {
        this.records = records;
        this.total = total;
        this.page = page;
        this.pageSize = pageSize;
    }
}
