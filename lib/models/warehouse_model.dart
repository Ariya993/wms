class Warehouse {
  final String warehouseCode;
  final String warehouseName;

  Warehouse({required this.warehouseCode, required this.warehouseName});

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      warehouseCode: json['WarehouseCode'] as String, // Sesuaikan dengan key JSON API Anda
      warehouseName: json['WarehouseName'] as String, // Sesuaikan dengan key JSON API Anda
    );
  }

  // Untuk ditampilkan di dropdown
  @override
  String toString() => '$warehouseCode - $warehouseName';
}