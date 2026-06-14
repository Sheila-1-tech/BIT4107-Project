class Prescription {
  const Prescription({
    required this.id,
    required this.customerName,
    required this.date,
    this.fileUrl,
    this.notes = '',
    this.status = 'pending',
    this.isDocument = false,
  });

  final String id;
  final String customerName;
  final String date;
  final String? fileUrl;
  final String notes;
  final String status;
  final bool isDocument;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'date': date,
      'fileUrl': fileUrl,
      'notes': notes,
      'status': status,
      'isDocument': isDocument,
    };
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      date: json['date'] as String,
      fileUrl: json['fileUrl'] as String?,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      isDocument: json['isDocument'] as bool? ?? false,
    );
  }
}
