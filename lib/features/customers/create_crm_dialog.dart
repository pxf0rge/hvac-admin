import 'package:flutter/material.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/maps/map_coordinates.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/form_error_banner.dart';
import 'package:hvac_admin/features/shared/widgets/map_address_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

Future<OfficeCustomer?> showCreateCustomerDialog(BuildContext context) {
  return showDialog<OfficeCustomer>(
    context: context,
    builder: (_) => const _CustomerDialog(),
  );
}

Future<OfficeCustomer?> showEditCustomerDialog(BuildContext context, OfficeCustomer customer) {
  return showDialog<OfficeCustomer>(
    context: context,
    builder: (_) => _CustomerDialog(customer: customer),
  );
}

class _CustomerDialog extends StatefulWidget {
  const _CustomerDialog({this.customer});

  final OfficeCustomer? customer;

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _city;
  late final TextEditingController _state;
  PreferredLanguage _preferredLanguage = PreferredLanguage.english;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _firstName = TextEditingController(text: customer?.firstName ?? '');
    _lastName = TextEditingController(text: customer?.lastName ?? '');
    _phone = TextEditingController(text: customer?.phone ?? '');
    _email = TextEditingController(text: customer?.email ?? '');
    _city = TextEditingController(text: customer?.city ?? '');
    _state = TextEditingController(text: customer?.state ?? 'IL');
    _preferredLanguage = customer?.preferredLanguage ?? PreferredLanguage.english;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = FieldValidators.requiredText(_firstName.text, label: 'First name') ??
        FieldValidators.requiredText(_lastName.text, label: 'Last name') ??
        FieldValidators.email(_email.text) ??
        FieldValidators.phone(_phone.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await context.read<CustomerController>().saveCustomer(
            OfficeCustomer(
              id: widget.customer?.id ?? '',
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim().toLowerCase(),
              city: _city.text.trim(),
              state: _state.text.trim(),
              preferredLanguage: _preferredLanguage,
            ),
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = FailureMapper.messageFor(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(isEdit ? 'Edit customer' : 'New customer'),
      content: SizedBox(
        width: 420,
        // Scrollable so the validation banner can grow the form without
        // overflowing the dialog's bottom edge on short viewports.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: _firstName, label: 'First name'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _lastName, label: 'Last name'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _phone, label: 'Phone', keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _city, label: 'City'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _state, label: 'State'),
              const SizedBox(height: AppSpacing.sm),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Preferred language (SMS/email)'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PreferredLanguage>(
                    key: const Key('customer-preferred-language'),
                    value: _preferredLanguage,
                    isExpanded: true,
                    items: [
                      for (final locale in PreferredLanguage.values)
                        DropdownMenuItem(value: locale, child: Text(locale.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _preferredLanguage = value);
                    },
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                FormErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppPrimaryButton(label: 'Save', onPressed: _saving ? null : _submit, isLoading: _saving),
      ],
    );
  }
}

Future<OfficeProperty?> showCreatePropertyDialog(BuildContext context, {required String customerId}) {
  return showDialog<OfficeProperty>(
    context: context,
    builder: (_) => _PropertyDialog(customerId: customerId),
  );
}

Future<OfficeProperty?> showEditPropertyDialog(BuildContext context, OfficeProperty property) {
  return showDialog<OfficeProperty>(
    context: context,
    builder: (_) => _PropertyDialog(customerId: property.customerId, property: property),
  );
}

class _PropertyDialog extends StatefulWidget {
  const _PropertyDialog({required this.customerId, this.property});

  final String customerId;
  final OfficeProperty? property;

  @override
  State<_PropertyDialog> createState() => _PropertyDialogState();
}

class _PropertyDialogState extends State<_PropertyDialog> {
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;
  late final TextEditingController _label;
  late PropertyType _type;
  LatLng? _point;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final property = widget.property;
    _address = TextEditingController(text: property?.address ?? '');
    _city = TextEditingController(text: property?.city ?? '');
    _state = TextEditingController(text: property?.state ?? 'IL');
    _zip = TextEditingController(text: property?.zip ?? '');
    _label = TextEditingController(text: property?.label ?? '');
    _type = property?.type ?? PropertyType.residential;
    final lat = property?.latitude;
    final lng = property?.longitude;
    if (lat != null && lng != null) {
      _point = MapCoordinates.fromNullable(lat, lng);
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final point = _point;
    final error = FieldValidators.requiredText(_address.text, label: 'Address') ??
        FieldValidators.requiredText(_city.text, label: 'City') ??
        FieldValidators.zipCode(_zip.text) ??
        (point == null || !MapCoordinates.isValid(point.latitude, point.longitude)
            ? 'Tap the map to set the property location.'
            : null);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await context.read<CustomerController>().saveProperty(
            OfficeProperty(
              id: widget.property?.id ?? '',
              customerId: widget.customerId,
              address: _address.text.trim(),
              city: _city.text.trim(),
              state: _state.text.trim(),
              zip: _zip.text.trim(),
              type: _type,
              label: _label.text.trim().isEmpty ? null : _label.text.trim(),
              latitude: point!.latitude,
              longitude: point.longitude,
            ),
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = FailureMapper.messageFor(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.property != null;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(isEdit ? 'Edit property' : 'New property'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapAddressPicker(
                initialPoint: _point,
                onChanged: ({required point, address}) {
                  setState(() => _point = point);
                  final resolved = address;
                  if (resolved == null) return;
                  if (resolved.address.isNotEmpty) _address.text = resolved.address;
                  if (resolved.city.isNotEmpty) _city.text = resolved.city;
                  if (resolved.state.isNotEmpty) _state.text = resolved.state;
                  if (resolved.zip.isNotEmpty) _zip.text = resolved.zip;
                },
                onSearchAddress: () async {
                  final parts = [
                    _address.text.trim(),
                    _city.text.trim(),
                    _state.text.trim(),
                    _zip.text.trim(),
                  ].where((part) => part.isNotEmpty);
                  return parts.join(', ');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _address, label: 'Street address'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _label, label: 'Label / access notes (optional)'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _city, label: 'City'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _state, label: 'State'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _zip, label: 'ZIP'),
              const SizedBox(height: AppSpacing.sm),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Property type'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PropertyType>(
                    value: _type,
                    isExpanded: true,
                    items: [
                      for (final type in PropertyType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                FormErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppPrimaryButton(label: 'Save', onPressed: _saving ? null : _submit, isLoading: _saving),
      ],
    );
  }
}
