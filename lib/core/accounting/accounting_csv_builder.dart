import 'package:hvac_admin/core/accounting/accounting_export_schema.dart';

/// Escapes a CSV field per RFC 4180-ish rules (quotes, commas, newlines).
String escapeCsvField(String value) {
  if (value.contains('"') || value.contains(',') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String buildAccountingCsv(List<AccountingExportRow> rows) {
  final buffer = StringBuffer()
    ..writeln(AccountingExportColumns.headers.map(escapeCsvField).join(','));
  for (final row in rows) {
    buffer.writeln(row.toCsvCells().map(escapeCsvField).join(','));
  }
  return buffer.toString();
}
