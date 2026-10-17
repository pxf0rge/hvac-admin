import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';
import 'package:hvac_admin/design_system/widgets/surface_card.dart';

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headingRowHeight = 44,
    this.dataRowMinHeight = 44,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double headingRowHeight;
  final double dataRowMinHeight;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadii.lgAll,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: headingRowHeight,
            dataRowMinHeight: dataRowMinHeight,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}
