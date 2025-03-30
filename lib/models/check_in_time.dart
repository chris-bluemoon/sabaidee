class CheckInTime {
  final DateTime dateTime;
  String status;
  final Duration duration; // Add duration field
  String? emoji; // Add emoji field

  CheckInTime({required this.dateTime, required this.status, required this.duration, this.emoji});

  factory CheckInTime.fromMap(Map<String, dynamic> map) {
    return CheckInTime(
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'],
      duration: Duration(minutes: map['duration']), // Parse duration from minutes
      emoji: map['emoji'], // Parse emoji field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'duration': duration.inMinutes, // Store duration in minutes
      'emoji': emoji, // Add emoji field to map
    };
  }
}
