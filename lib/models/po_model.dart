// lib/models/purchase_order_model.dart
class PurchaseOrderItem {
  final String itemCode;
  final String itemName;
  final double orderedQuantity;
  final double receivedQuantity; // Kuantitas yang sudah diterima
  final double openQuantity; // Kuantitas sisa yang belum diterima
  double currentReceivedQuantity; // Kuantitas yang akan diterima di GR ini

  PurchaseOrderItem({
    required this.itemCode,
    required this.itemName,
    required this.orderedQuantity,
    this.receivedQuantity = 0.0,
    this.openQuantity = 0.0,
    this.currentReceivedQuantity = 0.0,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      itemCode: json['ItemCode'] ?? '',
      itemName: json['ItemDescription'] ?? '',
      orderedQuantity: (json['Quantity'] ?? 0.0).toDouble(),
      // Asumsi API Anda menyediakan ReceivedQuantity dan OpenQuantity
      receivedQuantity: (json['ReceivedQuantity'] ?? 0.0).toDouble(),
      openQuantity: (json['OpenQuantity'] ?? (json['Quantity'] ?? 0.0) - (json['ReceivedQuantity'] ?? 0.0)).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ItemCode': itemCode,
      'ItemDescription': itemName,
      'Quantity': orderedQuantity,
      'CurrentReceivedQuantity': currentReceivedQuantity, // Untuk payload GR
    };
  }
}

class PurchaseOrder {
  final String docNum;
  final String cardCode;
  final String cardName;
  final DateTime docDate;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    required this.docNum,
    required this.cardCode,
    required this.cardName,
    required this.docDate,
    required this.items,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    var itemsList = json['DocumentLines'] as List; // Atau nama key yang sesuai dari API Anda, misal 'Items'
    List<PurchaseOrderItem> items =
        itemsList.map((i) => PurchaseOrderItem.fromJson(i)).toList();

    return PurchaseOrder(
      docNum: json['DocNum']?.toString() ?? '',
      cardCode: json['CardCode'] ?? '',
      cardName: json['CardName'] ?? '',
      docDate: DateTime.parse(json['DocDate']),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DocNum': docNum,
      'CardCode': cardCode,
      'CardName': cardName,
      'DocDate': docDate.toIso8601String(),
      'DocumentLines': items.map((i) => i.toJson()).toList(),
    };
  }
}