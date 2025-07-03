class PickList {
  final int absEntry;
  final String pickDate;
  final List<PickListLine> lines;

  PickList({required this.absEntry, required this.pickDate, required this.lines});

  factory PickList.fromJson(Map<String, dynamic> json) {
    return PickList(
      absEntry: json['AbsEntry'],
      pickDate: json['PickDate'],
      lines: (json['PickListsLines'] as List).map((e) => PickListLine.fromJson(e)).toList(),
    );
  }
}

class PickListLine {
  final String itemCode;
  final double plannedQty;

  PickListLine({required this.itemCode, required this.plannedQty});

  factory PickListLine.fromJson(Map<String, dynamic> json) {
    return PickListLine(
      itemCode: json['ItemCode'],
      plannedQty: json['PlannedQty'].toDouble(),
    );
  }
}
