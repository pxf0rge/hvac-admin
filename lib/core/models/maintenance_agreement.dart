import 'package:hvac_admin/core/enums/domain_enums.dart';

class MaintenanceAgreement {
  const MaintenanceAgreement({
    required this.id,
    required this.customerId,
    required this.propertyId,
    required this.title,
    required this.status,
    required this.frequency,
    required this.startOn,
    required this.endOn,
    required this.renewalReminderOn,
    this.nextServiceOn,
    this.annualAmount,
    this.notes = '',
  });

  final String id;
  final String customerId;
  final String propertyId;
  final String title;
  final MaintenanceAgreementStatus status;
  final MaintenanceAgreementFrequency frequency;
  final String startOn;
  final String endOn;
  final String? nextServiceOn;
  final String renewalReminderOn;
  final double? annualAmount;
  final String notes;

  bool isRenewalDueWithinDays(int days, {DateTime? now}) {
    final anchor = now ?? DateTime.now();
    final reminder = DateTime.tryParse(renewalReminderOn);
    if (reminder == null) return false;
    final deadline = DateTime(anchor.year, anchor.month, anchor.day).add(Duration(days: days));
    final reminderDay = DateTime(reminder.year, reminder.month, reminder.day);
    return !reminderDay.isAfter(deadline) && status == MaintenanceAgreementStatus.active;
  }

  MaintenanceAgreement copyWith({
    MaintenanceAgreementStatus? status,
    String? nextServiceOn,
    String? renewalReminderOn,
    double? annualAmount,
    String? notes,
  }) {
    return MaintenanceAgreement(
      id: id,
      customerId: customerId,
      propertyId: propertyId,
      title: title,
      status: status ?? this.status,
      frequency: frequency,
      startOn: startOn,
      endOn: endOn,
      nextServiceOn: nextServiceOn ?? this.nextServiceOn,
      renewalReminderOn: renewalReminderOn ?? this.renewalReminderOn,
      annualAmount: annualAmount ?? this.annualAmount,
      notes: notes ?? this.notes,
    );
  }
}
