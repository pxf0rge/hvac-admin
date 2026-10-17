import 'package:hvac_admin/core/config/portal_config.dart';
import 'package:hvac_admin/data/repositories/portal_repository.dart';

enum PortalResourceType { estimate, invoice, document }

class PortalLinkService {
  PortalLinkService(this._repository);

  final PortalRepository _repository;

  Future<String> mintEstimateUrl(String estimateId, {int ttlHours = 720}) async {
    final token = await _repository.createAccessToken(
      resourceType: PortalResourceType.estimate,
      resourceId: estimateId,
      ttlHours: ttlHours,
    );
    return PortalConfig.estimateUrl(token);
  }

  Future<String> mintInvoiceUrl(String invoiceId, {int ttlHours = 720}) async {
    final token = await _repository.createAccessToken(
      resourceType: PortalResourceType.invoice,
      resourceId: invoiceId,
      ttlHours: ttlHours,
    );
    return PortalConfig.invoiceUrl(token);
  }

  Future<String> mintDocumentUrl(String documentId, {int ttlHours = 720}) async {
    final token = await _repository.createAccessToken(
      resourceType: PortalResourceType.document,
      resourceId: documentId,
      ttlHours: ttlHours,
    );
    return PortalConfig.documentUrl(token);
  }

  Future<Map<String, dynamic>> resolve(String token) => _repository.resolveToken(token);
}
