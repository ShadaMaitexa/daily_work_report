class ReportModel {
  final String reportId;
  final String workerId;
  final String date;
  final String workDescription;
  final String hoursWorked;
  final String status;

  ReportModel({
    required this.reportId,
    required this.workerId,
    required this.date,
    required this.workDescription,
    required this.hoursWorked,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'workerId': workerId,
      'date': date,
      'workDescription': workDescription,
      'hoursWorked': hoursWorked,
      'status': status,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId'] ?? '',
      workerId: json['workerId'] ?? '',
      date: json['date'] ?? '',
      workDescription: json['workDescription'] ?? '',
      hoursWorked: json['hoursWorked'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

