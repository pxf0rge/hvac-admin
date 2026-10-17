import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/core/utils/formatters.dart';

/// Stable UUIDs for mock data and mapper tests (aligned with seed migrations).
abstract final class MockSeedIds {
  static const customerId = '11111111-1111-4111-8111-111111111111';
  static const propertyId = '22222222-2222-4222-8222-222222222222';
  static const jobId = '33333333-3333-4333-8333-333333333333';
  static const equipmentId = '44444444-4444-4444-8444-444444444444';
  static const estimateId = '55555555-5555-4555-8555-555555555555';
  static const invoiceId = '66666666-6666-4666-8666-666666666666';
  static const technicianId = '77777777-7777-4777-8777-777777777777';
  static const messageId = '88888888-8888-4888-8888-888888888888';
  static const inboundMessageId = '10101010-1010-4101-8101-101010101010';
  static const jobOutboundMessageId = '20202020-2020-4202-8202-202020202020';
  static const inventoryItemId = '99999999-9999-4999-8999-999999999999';
  static const warehouseLocationId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  static const todayJobId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  static const unassignedJobId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  static const fleetTruckId = 'f1111111-1111-4111-8111-111111111111';
  static const fleetTruck2Id = 'f2222222-2222-4222-8222-222222222222';
  static const fleetDeviceId = 'f3333333-3333-4333-8333-333333333333';
  static const fleetDevice2Id = 'f4444444-4444-4444-8444-444444444444';
  static const fleetTruckLocationId = 'b1111111-1111-4111-8111-111111111111';
  static const fleetTruck2LocationId = 'b2222222-2222-4222-8222-222222222222';
  static const fleetDeviceLocationId = 'b3333333-3333-4333-8333-333333333333';
  static const fleetDevice2LocationId = 'b4444444-4444-4444-8444-444444444444';
  static const openEstimateId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  static const overdueInvoiceId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  static const paymentId = 'p1111111-1111-4111-8111-111111111111';
  static const maintenanceAgreementId = 'm1111111-1111-4111-8111-111111111111';
  static const maintenanceAgreementPausedId = 'm2222222-2222-4222-8222-222222222222';
}

class MockSeedData {
  MockSeedData() {
    final today = isoDate(DateTime.now());
    customers = [_patNguyen];
    properties = [_oakLane];
    technicians = [_carlosRodriguez, _jamesPatel];
    jobs = [
      _rlsJob,
      _todayJob(today),
      _unassignedJob(today),
    ];
    equipment = [_carrierSplit];
    estimates = [_approvedEstimate, _openEstimate];
    invoices = [_sentInvoice, _overdueInvoice];
    payments = [_pendingCheckout];
    messages = [_jobReminderSms, _inboundReply, _welcomeSms];
    inventoryItems = [_capacitor];
    inventoryLocations = [_mainWarehouse, _truck12];
    inventoryStocks = [_warehouseCapacitor, _truckCapacitor];
    inventoryMovements = [_initialReceive, _truckAssign];
    maintenanceAgreements = [_annualPlan, _pausedPlan];
    technicianActivity = {
      MockSeedIds.technicianId: technicianActivityCarlos,
    };
  }

  late final List<OfficeCustomer> customers;
  late final List<OfficeProperty> properties;
  late final List<OfficeTechnician> technicians;
  late final List<HistoryJob> jobs;
  late final List<PropertyEquipment> equipment;
  late final List<OfficeEstimate> estimates;
  late final List<OfficeInvoice> invoices;
  late final List<OfficePayment> payments;
  late final List<OfficeMessage> messages;
  late final List<InventoryItem> inventoryItems;
  late final List<InventoryLocation> inventoryLocations;
  late final List<LocationStock> inventoryStocks;
  late final List<StockMovement> inventoryMovements;
  late final List<MaintenanceAgreement> maintenanceAgreements;
  late final Map<String, List<TechnicianActivity>> technicianActivity;

  static const technicianActivityCarlos = [
    TechnicianActivity(
      at: '2026-08-28T14:00:00Z',
      title: 'Assigned',
      detail: 'JOB-TODAY-01 scheduled for today.',
    ),
    TechnicianActivity(
      at: '2026-08-28T09:00:00Z',
      title: 'Clocked in',
      detail: 'Available for dispatch.',
    ),
  ];

  static final _patNguyen = OfficeCustomer(
    id: MockSeedIds.customerId,
    firstName: 'Pat',
    lastName: 'Nguyen',
    phone: '2175550100',
    email: 'pat.rls@hvacpro.com',
    city: 'Springfield',
    state: 'IL',
    propertyIds: [MockSeedIds.propertyId],
  );

  static final _oakLane = OfficeProperty(
    id: MockSeedIds.propertyId,
    customerId: MockSeedIds.customerId,
    address: '77 Oak Lane',
    city: 'Springfield',
    state: 'IL',
    zip: '62704',
    type: PropertyType.multiFamily,
    label: 'Main home',
    latitude: 39.7817,
    longitude: -89.6501,
    equipmentIds: [MockSeedIds.equipmentId],
    jobIds: [MockSeedIds.jobId],
  );

  static final _carlosRodriguez = OfficeTechnician(
    id: MockSeedIds.technicianId,
    firstName: 'Carlos',
    lastName: 'Rodriguez',
    status: TechnicianStatus.assigned,
    latitude: 39.7817,
    longitude: -89.6501,
    lastAddress: 'Springfield, IL',
    lastUpdated: '2026-08-28T14:00:00Z',
    profileId: 'tech_profile_carlos',
    phone: '2175550142',
    email: 'carlos@hvacpro.com',
  );

  static final _jamesPatel = OfficeTechnician(
    id: '88888888-8888-4888-8888-888888888881',
    firstName: 'James',
    lastName: 'Patel',
    status: TechnicianStatus.available,
    latitude: 39.7684,
    longitude: -89.6542,
    lastAddress: 'Arctic HVAC Solutions shop, Springfield',
    lastUpdated: '2026-08-28T10:00:00Z',
    phone: '2175550199',
    email: 'james.patel@hvacpro.com',
    accountEnabled: true,
  );

  static final _rlsJob = HistoryJob(
    id: MockSeedIds.jobId,
    propertyId: MockSeedIds.propertyId,
    jobNumber: 'JOB-RLS-21',
    type: JobType.acNotCooling,
    status: JobStatus.inProgress,
    priority: JobPriority.high,
    date: '2026-08-28',
    startTime: '09:00',
    endTime: '11:00',
    technicianId: MockSeedIds.technicianId,
    technicianName: 'Carlos Rodriguez',
    description: 'RLS verification job',
  );

  static final _carrierSplit = PropertyEquipment(
    id: MockSeedIds.equipmentId,
    propertyId: MockSeedIds.propertyId,
    name: 'Carrier split',
    manufacturer: 'Carrier',
    model: '24ACC6',
    serial: 'SN-123',
    typeKey: 'central_ac',
    typeLabel: 'Central AC',
    capacity: '3 ton',
    installedOn: '2020-05-01',
    installer: 'Arctic HVAC Solutions',
    warranties: const [
      PropertyWarranty(title: 'Compressor', serial: 'W-1', expiresOn: '2027-06-01'),
    ],
    serviceJobIds: [MockSeedIds.jobId],
  );

  static final _approvedEstimate = OfficeEstimate(
    id: MockSeedIds.estimateId,
    number: 'EST-RLS-21',
    status: EstimateStatus.approved,
    date: '2026-08-28',
    propertyId: MockSeedIds.propertyId,
    jobId: MockSeedIds.jobId,
    notes: 'Financial row',
    items: const [BillingLineItem(description: 'Capacitor', quantity: 1, unitPrice: 185)],
  );

  static final _sentInvoice = OfficeInvoice(
    id: MockSeedIds.invoiceId,
    number: 'INV-RLS-21',
    status: InvoiceStatus.sent,
    date: '2026-08-28',
    dueDate: '2026-09-11',
    propertyId: MockSeedIds.propertyId,
    jobId: MockSeedIds.jobId,
    estimateId: MockSeedIds.estimateId,
    notes: 'Technician must not see this',
    items: const [BillingLineItem(description: 'Capacitor', quantity: 1, unitPrice: 185)],
  );

  static HistoryJob _todayJob(String today) => HistoryJob(
        id: MockSeedIds.todayJobId,
        propertyId: MockSeedIds.propertyId,
        jobNumber: 'JOB-TODAY-01',
        type: JobType.diagnostic,
        status: JobStatus.scheduled,
        priority: JobPriority.normal,
        date: today,
        startTime: '13:00',
        endTime: '15:00',
        technicianId: MockSeedIds.technicianId,
        technicianName: 'Carlos Rodriguez',
        description: 'Scheduled for today',
      );

  static HistoryJob _unassignedJob(String today) => HistoryJob(
        id: MockSeedIds.unassignedJobId,
        propertyId: MockSeedIds.propertyId,
        jobNumber: 'JOB-UNASSIGNED-01',
        type: JobType.furnaceRepair,
        status: JobStatus.unassigned,
        priority: JobPriority.high,
        date: today,
        startTime: '16:00',
        endTime: '18:00',
        technicianName: 'Unassigned',
        description: 'Needs dispatch assignment',
      );

  static final _openEstimate = OfficeEstimate(
    id: MockSeedIds.openEstimateId,
    number: 'EST-OPEN-01',
    status: EstimateStatus.sent,
    date: '2026-08-29',
    propertyId: MockSeedIds.propertyId,
    jobId: MockSeedIds.jobId,
    notes: 'Awaiting customer approval',
    items: const [BillingLineItem(description: 'Service call', quantity: 1, unitPrice: 95)],
  );

  static final _overdueInvoice = OfficeInvoice(
    id: MockSeedIds.overdueInvoiceId,
    number: 'INV-OVERDUE-01',
    status: InvoiceStatus.overdue,
    date: '2026-08-01',
    dueDate: '2026-08-15',
    propertyId: MockSeedIds.propertyId,
    jobId: MockSeedIds.jobId,
    notes: 'Past due balance',
    items: const [BillingLineItem(description: 'Compressor replacement', quantity: 1, unitPrice: 420)],
  );

  static final _pendingCheckout = OfficePayment(
    id: MockSeedIds.paymentId,
    invoiceId: MockSeedIds.overdueInvoiceId,
    jobId: MockSeedIds.jobId,
    propertyId: MockSeedIds.propertyId,
    amount: 420,
    status: PaymentStatus.requiresPayment,
    provider: 'mock',
    providerPaymentId: 'mock_pi_seed_01',
    checkoutUrl: 'https://pay.hvacpro.example/checkout/mock_pi_seed_01',
    createdAt: '2026-08-20T10:00:00Z',
  );

  static final _jobReminderSms = OfficeMessage(
    id: MockSeedIds.jobOutboundMessageId,
    at: '2026-08-29T08:00:00Z',
    channel: CommunicationChannel.sms,
    direction: MessageDirection.outbound,
    entityType: CommunicationEntityType.job,
    entityId: MockSeedIds.jobId,
    entityLabel: 'JOB-RLS-21',
    body: 'Arctic HVAC Solutions reminder: appointment for Pat Nguyen at 77 Oak Lane on Aug 28 (JOB-RLS-21).',
    templateKind: 'appointment_reminder',
    deliveryStatus: 'sent',
    toAddress: '2175550100',
  );

  static final _inboundReply = OfficeMessage(
    id: MockSeedIds.inboundMessageId,
    at: '2026-08-29T08:15:00Z',
    channel: CommunicationChannel.sms,
    direction: MessageDirection.inbound,
    entityType: CommunicationEntityType.customer,
    entityId: MockSeedIds.customerId,
    entityLabel: 'Pat Nguyen',
    body: 'Thanks! We will be home.',
    deliveryStatus: 'received',
    toAddress: '2175550100',
  );

  static final _welcomeSms = OfficeMessage(
    id: MockSeedIds.messageId,
    at: '2026-08-28T10:00:00Z',
    channel: CommunicationChannel.sms,
    direction: MessageDirection.outbound,
    entityType: CommunicationEntityType.customer,
    entityId: MockSeedIds.customerId,
    entityLabel: 'Pat Nguyen',
    body: 'Your service appointment is confirmed for tomorrow.',
    toAddress: '2175550100',
  );

  static final _capacitor = InventoryItem(
    id: MockSeedIds.inventoryItemId,
    sku: 'CAP-45-5',
    name: '45/5 Capacitor',
    category: 'Electrical',
    unit: 'ea',
    minQty: 5,
  );

  static final _mainWarehouse = InventoryLocation(
    id: MockSeedIds.warehouseLocationId,
    kind: StockLocationKind.warehouse,
    name: 'Main Warehouse',
  );

  static final _truck12 = InventoryLocation(
    id: MockSeedIds.fleetTruckLocationId,
    kind: StockLocationKind.truck,
    name: 'Truck 12',
  );

  static const _warehouseCapacitor = LocationStock(
    locationId: MockSeedIds.warehouseLocationId,
    itemId: MockSeedIds.inventoryItemId,
    quantity: 4,
  );

  static const _truckCapacitor = LocationStock(
    locationId: MockSeedIds.fleetTruckLocationId,
    itemId: MockSeedIds.inventoryItemId,
    quantity: 2,
  );

  static final _initialReceive = StockMovement(
    id: 'mv_seed_receive',
    at: '2026-08-20T09:00:00Z',
    itemId: MockSeedIds.inventoryItemId,
    kind: StockMovementKind.receive,
    quantity: 6,
    fromLocationId: MockSeedIds.warehouseLocationId,
    toLocationId: MockSeedIds.warehouseLocationId,
    reason: 'Vendor delivery',
  );

  static final _truckAssign = StockMovement(
    id: 'mv_seed_assign',
    at: '2026-08-23T07:30:00Z',
    itemId: MockSeedIds.inventoryItemId,
    kind: StockMovementKind.assign,
    quantity: 2,
    fromLocationId: MockSeedIds.warehouseLocationId,
    toLocationId: MockSeedIds.fleetTruckLocationId,
    reason: 'Load Truck 12 for route',
    jobId: MockSeedIds.jobId,
  );

  static final _annualPlan = MaintenanceAgreement(
    id: MockSeedIds.maintenanceAgreementId,
    customerId: MockSeedIds.customerId,
    propertyId: MockSeedIds.propertyId,
    title: 'Annual HVAC tune-up',
    status: MaintenanceAgreementStatus.active,
    frequency: MaintenanceAgreementFrequency.annual,
    startOn: '2025-09-01',
    endOn: '2026-08-31',
    nextServiceOn: '2026-09-15',
    renewalReminderOn: '2026-09-15',
    annualAmount: 389,
    notes: 'Includes spring PM and priority dispatch.',
  );

  static final _pausedPlan = MaintenanceAgreement(
    id: MockSeedIds.maintenanceAgreementPausedId,
    customerId: MockSeedIds.customerId,
    propertyId: MockSeedIds.propertyId,
    title: 'Quarterly filter service',
    status: MaintenanceAgreementStatus.paused,
    frequency: MaintenanceAgreementFrequency.quarterly,
    startOn: '2026-01-01',
    endOn: '2026-12-31',
    renewalReminderOn: '2026-11-15',
    annualAmount: 720,
    notes: 'Paused while tenant turnover completes.',
  );
}
