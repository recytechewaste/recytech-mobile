# RecyTech Full Requirements Audit

Date: 2026-08-29

This is the continuation of the accepted `AUTHENTICATION_ACCOUNT_MANAGEMENT_AUDIT.md`. It does not replace that audit. Authentication recovery clarification: Partner Organization and Collector may use Forgot Password and email-based password reset; those are auth recovery features, not prohibited self-service account management.

## Overall Status

The mobile app has substantial UI coverage for the desired final flows, but many areas are still mock/local implementations. The web backend remains centered on pickup requests, residents, collectors, exchange rates, and admin request management. It does not yet provide authoritative backend support for partner-owned bins, sensor readings, partner collection requests, household QR drop-offs, partner rewards, notifications, collector reports, FIFO queue claiming, or QR ownership validation.

## Household User Audit

| Requirement | Status | Evidence/File | Required Fix |
| --- | --- | --- | --- |
| Static Bin Locator | Partial | `BinLocatorScreen` uses `ApiPublicBinRepository` in `recytecmobproj/lib/presentation/user/bins/bin_locator_screen.dart:21`; mobile backend exposes `GET /api/bins/public` and `/api/public/bins` in `recytecmobproj/backend/server.js:631` and `recytecmobproj/backend/server.js:640`. | Promote public bin data to authoritative backend model/API with ownership, active status, coordinates, and partner reward metadata. |
| Bin details/location | Partial | Bottom sheet shows building/location/address/access/status in `bin_locator_screen.dart:80`; OpenStreetMap preview exists in `bin_locator_screen.dart:374`; map directions at `bin_locator_screen.dart:115`. | Add backend bin detail endpoint and ensure inactive/private bins are never returned to households. |
| No household waste routing | Pass for active mobile UI | Dashboard routes to bin locator, QR, rewards, history, education only in `recytecmobproj/lib/presentation/user/dashboard/dashboard_screen.dart:139`. Integration docs state household pickup/request submission is no longer exposed in `recytecmobproj/docs/MOBILE_INTEGRATION_CONTRACTS.md:13`. | Keep legacy pickup screens/data classes unrouted or remove after migration. |
| No post-drop-off waste tracking | Pass for active mobile UI | Household history is titled Drop-Off History and shows check-ins/rewards, not collection tracking, in `recytecmobproj/lib/presentation/user/history/history_screen.dart:43`. | Ensure no route links legacy pickup tracking from household shell. |
| Manual drop-off submission form | Missing | Active household flow only uses QR confirmation. Legacy pasted `submission_form_code.txt` is pickup-style and navigates to `TrackingScreen` in `recytecmobproj/submission_form_code.txt:8` and `recytecmobproj/submission_form_code.txt:136`, but it is not in active `lib`. | Add an authenticated household manual bin-code/drop-off form, or explicitly declare QR-only. Backend must validate bin and create drop-off record. |
| QR-based bin submission | Partial | QR screen parses and validates QR, then confirms drop-off in `bin_qr_scanner_screen.dart:65` and `bin_qr_scanner_screen.dart:127`; parser accepts `recytech://bin/<code>` in `bin_qr_payload_model.dart:34`. | Replace `MockDropOffRepository` with backend `POST /household/drop-offs/validate-bin-qr` and `POST /household/drop-offs`. |
| Points | Mock only | `DropOffRecord` supports `rewardPoints` in `drop_off_record_model.dart:16`; mock grants 10 points in `drop_off_repository.dart:108`. | Add backend points ledger or reward transaction model. Points must be generated server-side. |
| Points + Rewards/Exchange | Partial/mock | Rewards screen reads `getMyRewards()` from `MockDropOffRepository` in `rewards_screen.dart:28` and `rewards_screen.dart:34`. | Add reward catalog/ledger/redemption APIs. Current web `Transaction` is monetary payout, not household reward exchange. |
| Partner Organization rewards visible from associated bins | Missing | `PublicBin` has no partner reward fields in `public_bin_model.dart:1`; mobile backend only emits optional `partnerOrganizationName` in `server.js:315`. | Add partner reward metadata to bin detail/list responses, and show associated rewards in household bin details before scan/submission. |

## Partner Organization Audit

| Requirement | Status | Evidence/File | Required Fix |
| --- | --- | --- | --- |
| Replace LGU terminology/functionality | Partial | `AppRoles.displayName` returns Partner Organization for `UserRole.lgu` in `app_constants.dart:74`; many files/routes still use LGU naming. | Rename user-facing LGU labels and migrate code/domain names to Partner Organization, keeping compatibility aliases temporarily. |
| My Bins | Mock only | `AssignedBinsScreen` uses `MockBinMonitoringService` in `assigned_bins_screen.dart:21`. | Add authenticated partner bins API scoped by partner account. |
| Bin Details | Mock only | `BinDetailsScreen` loads `fetchBin` and `fetchMonitoring` from mock repository in `bin_details_screen.dart:27` and `bin_details_screen.dart:40`. | Add backend bin detail and monitoring endpoints with ownership checks. |
| Bin status | Mock only | `RecyTechBin` models `fillPercentage`, `fullnessStatus`, `sensorStatus`, `controllerStatus` in `bin_monitoring_models.dart:1`; UI renders badges in `assigned_bins_screen.dart:138`. | Persist latest bin status in backend. |
| Fill/sensor information | Mock only | `MockBinMonitoringService` stores ToF-derived fields and statuses in `bin_monitoring_repository.dart:47`. | Add sensor ingestion and latest-reading storage. |
| Last Updated timestamp | Mock only | `AssignedBinsScreen` shows `Updated: ...` in `assigned_bins_screen.dart:209`; stale logic starts at `bin_monitoring_models.dart:197`. | Store `lastUpdatedAt` from latest sensor reading; use backend clock/capturedAt policy. |
| Manual Refresh button | Present in UI | Refresh actions exist on dashboard, bins, details, and tracking in `lgu_dashboard_screen.dart:82`, `assigned_bins_screen.dart:63`, `bin_details_screen.dart:90`, and `collection_request_tracking_screen.dart:58`. | Wire refresh to real APIs. |
| Non-realtime sensor architecture | Partial | UI uses manual refresh/FutureBuilder, not continuous polling; docs describe ESP32 posting readings to backend in `MOBILE_INTEGRATION_CONTRACTS.md:118`. | Implement backend ingestion and stored latest-read endpoint. |
| Collection Request | Mock only | Form calls `MockCollectionRequestRepository.createCollectionRequest` in `collection_request_form_screen.dart:49`. | Add partner collection request endpoint and database model fields for bin snapshot. |
| Duplicate active request prevention | UI-only/mock | Button disables when `bin.hasActiveCollectionRequest` in `bin_details_screen.dart:123`; mock checks active request in memory via `activeRequestForBin` in `collection_request_repository.dart:105`. | Backend must enforce one active request per bin with atomic check/unique partial index or transaction. |
| Collection Request Tracking | Mock only | Tracking screen uses `MockCollectionRequestRepository` in `collection_request_tracking_screen.dart:22`. | Add partner-scoped list/detail tracking API. |
| Rewards offered by Partner Organization | Missing | No Partner Organization reward model/API found. | Add reward offer model linked to partner and bins; expose read-only to households and management to web admin/partner policy. |
| Required forms/submission functionality | Partial/mock | Request form supports remarks plus bin reading snapshot fields in `collection_request_form_screen.dart:83`. | Persist partner request submissions and validate ownership/status server-side. |

## Collector Audit

| Requirement | Status | Evidence/File | Required Fix |
| --- | --- | --- | --- |
| Bin visibility | Partial | Job details show bin/location fields from request model in `job_detail_screen.dart:194`; no dedicated collector bin endpoint. | Include partner org, bin ID, bin location, sensor snapshot, and map coordinates in queue/detail API. |
| Collection Request queue | Partial | Collector fetches all `/requests` through `CollectorApi.fetchJobs()` in `collector_api.dart:11`; available jobs are filtered client-side in `collector_repository.dart:9`. | Add collector-specific queue endpoint. |
| FIFO ordering | UI-only | Available jobs are sorted oldest-first in `collector_repository.dart:12`. | Backend queue endpoint must sort FIFO by request creation/requested timestamp. |
| Backend-enforced queue ordering | Missing | Web backend `GET /api/requests` sorts newest-first in `requestRoutes.js:202`; no FIFO claim endpoint. | Implement backend FIFO queue and claim/start transitions. |
| Automatic request acceptance/assignment | Missing/partial | Collector opening next request does not atomically claim it; `acceptJob` exists but is not used by current UI and updates status to In-Transit in `collector_repository.dart:69`. | Add backend atomic "start next" or "claim next FIFO" operation that assigns the current collector. |
| NO Accept/Reject workflow | Partial | Collector UI actions are status progression only in `job_detail_screen.dart:271`; no collector reject button found. `acceptJob` method remains as obsolete/compatibility in `collector_repository.dart:69`. | Remove/rename `acceptJob` after backend claim flow exists. Ensure collectors cannot reject/skip assigned queue items. |
| Request details | Partial | `JobDetailScreen` displays resident, bin/item, location, quantity, rates, contact, status in `job_detail_screen.dart:165`. | Add authoritative partner/bin details and reduce household pickup fields if final flow is bin collection only. |
| Partner Organization details | Missing/mislabelled | Detail row labels `LGU` but displays `job.assignedCollector` in `job_detail_screen.dart:190`, which appears incorrect. | Add partner organization fields to request/job payload and render as Partner Organization. |
| Bin location | Present/partial | Location row and Google Maps button exist in `job_detail_screen.dart:194` and `job_detail_screen.dart:227`. | Include coordinates when available, not only address strings. |
| Map/location access | Present in UI | `MapLauncher` is used by collector details in `job_detail_screen.dart:109`. | Confirm mobile platform permissions and backend coordinate payloads. |
| Collection workflow | Partial/mock | Workflow captures before condition/image, items, after image/status, remarks, and completion in `collection_workflow_screen.dart:117`. | Persist report, evidence uploads, and status transitions server-side. |
| Existing YOLO/TFLite functionality | Present locally | `EWasteDetectionService` loads `assets/models/recytech_yolov8.tflite` in `ewaste_detection_service.dart:11`; capture screen calls detection in `collector_ewaste_capture_screen.dart:130`. | Keep local inference; submit confirmed results and evidence to backend. |
| Quantity/weight/photos/report/completion/history | Partial | Quantity/photos/report exist in workflow; completion report repository is mock in `collection_completion_repository.dart:17`; contract says weight intentionally omitted from Phase 3 in `collection_completion_repository.dart:13`. | Add collector reports backend and decide whether weight is required. Current implementation has quantity but not collector-entered weight. |
| Concurrency protection | Missing | General `PUT /api/requests/:id` updates status/assignment with no atomic ownership/FIFO guard in `requestRoutes.js:283`. | Use atomic conditional updates for claim/start/complete and reject stale transitions. |

## IoT / Sensor Audit

| Requirement | Status | Evidence/File | Required Fix |
| --- | --- | --- | --- |
| Current sensor implementation | Mock only | Repository comment documents intended `VL53L1X ToF sensor -> XIAO ESP32-S3 -> Wi-Fi -> backend -> Flutter` in `bin_monitoring_repository.dart:46`. | Implement device ingestion endpoint and bin reading persistence. |
| Stored latest reading | Mock only | `BinMonitoringData` models latest fields in `bin_monitoring_models.dart:112`; mock returns static latest readings. | Store latest reading per bin and optionally historical readings. |
| Manual refresh behavior | Present in UI | Refresh actions use Future reloads; no polling found in active partner bin screens. | Wire to latest-reading endpoint. |
| Offline/no-new-reading handling | Partial/mock | `SensorStatuses` includes offline/delayed/unknown in `app_constants.dart:130`; stale warning exists in `bin_details_screen.dart:311`. | Backend must calculate or return stale/offline state based on last reading. |
| Last sensor update | Partial/mock | Last update displayed in `assigned_bins_screen.dart:209` and `bin_details_screen.dart:198`. | Persist and expose `lastUpdatedAt/capturedAt`. |
| No unnecessary continuous polling | Pass in current UI | Screens use refresh buttons/RefreshIndicator, not timers/streams. | Preserve manual-refresh model unless realtime is later required. |
| No misleading realtime/live UI | Mostly pass | Copy says "temporary mock repository" in `lgu_dashboard_screen.dart:203`; labels say updated/reading rather than live. | Rename LGU copy and ensure production UI says latest stored reading, not live. |

## QR Audit

| Requirement | Status | Evidence/File | Required Fix |
| --- | --- | --- | --- |
| Bin QR generation/ownership | Missing | No backend QR generation or bin ownership model found; QR parser only reads public code in `bin_qr_payload_model.dart:12`. | Add backend-generated opaque public QR codes linked to bins and partner organization ownership. |
| QR lookup | Partial/mock | Mobile validates via mock `validateBinQr` in `drop_off_repository.dart:68`; public bin list can be fetched from mobile backend. | Add protected lookup/validation endpoint. |
| Household scan | Present UI/mock | `BinQrScannerScreen` uses camera scanner in `bin_qr_scanner_screen.dart:151`. | Use backend validation and record creation. |
| Bin preselection | Present UI | Bin locator passes `expectedBin` to scanner in `bin_locator_screen.dart:52`; scanner warns if QR differs in `bin_qr_scanner_screen.dart:271`. | Backend should still trust scanned QR, not selected UI state. |
| Invalid/inactive QR handling | Partial/mock | Parser rejects malformed QR; mock rejects unknown/inactive bins in `drop_off_repository.dart:68`. | Backend must reject malformed, unknown, inactive, private, or wrong-owner QR codes. |
| Backend validation | Missing for drop-off | Mobile backend only lists bins; no `POST /drop-offs` routes in `server.js`. | Add authoritative validation and idempotent drop-off submission. |

## API Audit

| Feature | Existing API/Client | Status | Evidence/File | Required Fix |
| --- | --- | --- | --- | --- |
| Public/designated bin list | `GET /api/bins/public`, `GET /api/public/bins`; mobile `ApiPublicBinRepository` | Partial | `server.js:631`; `public_bin_repository.dart:16` | Back with real Bin model, ownership, active filters, reward metadata. |
| Household QR validation | None; mock only | Missing | `drop_off_repository.dart:31` | Add `POST /api/household/drop-offs/validate-bin-qr`. |
| Household drop-off submission | None; mock only | Missing | `drop_off_repository.dart:89` | Add `POST /api/household/drop-offs` with idempotency and reward calculation. |
| Household drop-off history | None; mock only | Missing | `drop_off_repository.dart:119` | Add `GET /api/household/drop-offs`. |
| Household rewards | None; mock only | Missing | `drop_off_repository.dart:127` | Add `GET /api/household/rewards`, reward ledger/redemptions. |
| Legacy household pickup request | `POST /api/requests`, `GET /api/requests/me` | Compatibility/obsolete for household flow | `requestRoutes.js:214`; `requestRoutes.js:268`; docs at `MOBILE_INTEGRATION_CONTRACTS.md:13` | Keep only if needed by web/admin migration, or restrict from household final flow. |
| Partner bins | Mock proposed `GET /api/lgu/bins` | Missing | `bin_monitoring_repository.dart:40` | Add `/api/partner/bins`. |
| Partner bin detail | Mock proposed `GET /api/lgu/bins/:binId` | Missing | `MOBILE_INTEGRATION_CONTRACTS.md:105` | Add ownership-checked detail API. |
| Partner bin monitoring | Mock proposed `GET /api/lgu/bins/:binId/monitoring` | Missing | `bin_monitoring_repository.dart:40` | Add latest stored reading API. |
| Sensor ingestion | None | Missing | `MOBILE_INTEGRATION_CONTRACTS.md:118` | Add device-authenticated ingestion endpoint. |
| Partner collection request creation | Mock proposed `POST /api/lgu/collection-requests` | Missing | `collection_request_repository.dart:20` | Add `/api/partner/collection-requests` with duplicate active request prevention. |
| Partner collection request tracking | Mock proposed `GET /api/lgu/collection-requests` | Missing | `collection_request_tracking_screen.dart:22` | Add partner-scoped list/detail endpoints. |
| Collector available queue | Uses `GET /api/requests` then client filters | Partial/unsafe | `collector_api.dart:11`; `requestRoutes.js:202` | Add `GET /api/collector/queue` FIFO sorted and role-scoped. |
| Collector claim/start next | Uses broad `PUT /api/requests/:id` | Missing/unsafe | `requestRoutes.js:283` | Add atomic claim/start endpoint with status and assigned collector checks. |
| Collector status transitions | `PUT /api/requests/:id` | Partial/unsafe | `job_detail_screen.dart:65`; `requestRoutes.js:283` | Restrict backend transition rules by role and current assignment. |
| Collector report submit | None; mock proposed `POST /api/collector/collection-reports` | Missing | `collection_completion_repository.dart:11` | Add report and upload endpoints. |
| Collector report history | None; mock proposed `GET /api/collector/collection-reports` | Missing | `collection_completion_repository.dart:29` | Add collector-scoped history endpoint. |
| Admin request approve/reject | `PUT /api/requests/:id`; React approve/reject | Present but pickup-centric | `RequestManagement.jsx:172`; `RequestManagement.jsx:190` | Decide whether admin approval/rejection remains for partner bin collection requests. |
| Admin collector management | `/api/collectors` CRUD | Present | `collectorRoutes.js:10` | Add email verification/account status fields from auth audit. |
| Admin user/resident management | `/api/users`, `/api/residents` | Present/partial | `userRoutes.js:10`; `residentRoutes.js:10` | Align with final account model; avoid wallet edits except controlled admin actions. |
| Notifications | Mobile mock proposed `/api/notifications` | Missing | `notification_repository.dart:66` | Add notification model/API or remove notification UI until backed. |
| Exchange/reward rates | `/api/exchange-rates` | Partial | `exchangeRateRoutes.js:16`; `ExchangeRate.js:3` | Current model is payout rate, not partner household reward offer/exchange catalog. |
| Transactions/payouts | `/api/transactions`, `/api/transactions/me` | Present for monetary payouts | `transactionRoutes.js:40`; `transactionRoutes.js:103` | Separate household points/rewards/redemptions from monetary payout if both remain. |

Route-ordering caution: `GET /api/requests/pending-payouts` is declared after parameterized request routes, but there is no current plain `GET /:id` route shadowing it. Future literal request routes should be placed before parameter routes to avoid accidental shadowing.

## Database / Model Audit

| Model/Relationship | Status | Evidence/File | Required Fix |
| --- | --- | --- | --- |
| User | Partial | Web `User` supports first/last/email/password/role/status/reset PIN in `models/User.js:3`; mobile backend has schemaless users collection in `server.js:51`. | See accepted auth audit: add canonical roles, verification, account status, timestamps, ownership. |
| Partner Organization | Missing | No partner organization model found; LGU is represented in mobile constants/screens only. | Add PartnerOrganization profile linked to account. |
| Collector | Partial | `Collector` links to `User` in `models/Collector.js:3`; admin CRUD exists. | Add account verification/status visibility, profile/account separation, pending approval flow. |
| Bin | Missing/partial | No web Mongoose Bin model found; mobile `PublicBin` and `RecyTechBin` are Dart models/mocks. Mobile backend scans configured collection names dynamically in `server.js:351`. | Add authoritative Bin model with partner owner, public QR code, location, active status, sensor status, reward associations. |
| Sensor reading/status | Missing/mock | Dart `BinMonitoringData` exists in `bin_monitoring_models.dart:112`; no backend model found. | Add latest reading and optional SensorReading history collection. |
| Collection Request | Partial but pickup-centric | Web `Request` model stores resident, waste type, location, status, assignedCollector in `models/Request.js:3`. | Add partner/bin request fields, FIFO timestamp, active per bin constraint, queue claim metadata. |
| Household Submission/Drop-Off | Missing/mock | Dart `DropOffRecord` exists in `drop_off_record_model.dart:1`; no backend model found. | Add HouseholdDropOff model with account, bin, timestamp, idempotency key, reward status. |
| Points | Missing/mock | Points only appear as `rewardPoints` in Dart drop-off record. | Add points ledger model or integrate with rewards ledger. |
| Rewards | Missing/mock | Dart `RewardTransaction` model exists but backend reward model not found. | Add PartnerRewardOffer and HouseholdRewardTransaction models. |
| Redemptions | Missing | No redemption model/API found. | Add redemption model if exchange/redeem flow is required. |
| Notifications | Missing/mock | Dart notification model/repository is in-memory only. | Add Notification model with recipient role/account, type, read state, destination. |
| Collector Reports | Missing/mock | Dart `CollectionReportDraft` exists in `collected_item_model.dart:39`; no backend model found. | Add CollectorReport model with evidence refs, confirmed items, totals, request link, timestamps. |
| Monetary payouts | Present | `Transaction` model exists in `models/Transaction.js:3`; `releasePayoutForRequest` updates resident wallet and request in `requestRoutes.js:124`. | Keep separate from household partner reward points unless product intentionally merges them. |

## LGU to Partner Organization Migration

| Location | Category | Notes |
| --- | --- | --- |
| `recytecmobproj/lib/core/constants/app_constants.dart` | Keep temporarily for compatibility, then rename | `UserRole.lgu` and `AppShellTarget.lgu` normalize partner aliases and display Partner Organization. Internal enum names should become partner once backend roles are canonical. |
| `recytecmobproj/lib/presentation/lgu/**` | Rename/migrate | Active partner-facing mobile UI lives under `lgu` folders. Rename folders/classes/routes to partner organization after backend compatibility aliases are ready. |
| `recytecmobproj/lib/data/repositories/bin_monitoring_repository.dart` | Migrate | `LguBinRepository`, comments, demo IDs, and proposed `/api/lgu/bins` contracts should become Partner/Organization equivalents. |
| `recytecmobproj/lib/data/repositories/collection_request_repository.dart` | Migrate | Uses `lguId` and proposed `/api/lgu/collection-requests`; convert to `partnerOrganizationId`. |
| `recytecmobproj/lib/data/models/bin_monitoring_models.dart` | Migrate | Fields `assignedLguId`, `lguId`, legacy comments. Keep JSON aliases while backend transitions. |
| `recytecmobproj/lib/data/models/collected_item_model.dart` | Migrate | Collector reports contain `lguId`/`lguName`; rename to partner fields with compatibility parsing. |
| `recytecmobproj/lib/data/models/notification_model.dart` | Migrate | Destination kinds `lguRequest` and `lguBin` should become partner request/bin. |
| `recytecmobproj/lib/presentation/notifications/notification_center_screen.dart` | Rename/migrate | User-facing message says LGU collection request; replace with Partner Organization terminology. |
| `recytecmobproj/lib/presentation/shell/access_denied_screen.dart` | Rename | Copy says mobile app supports LGU and Collector. |
| `recytecmobproj/test/*` | Rename/migrate | Tests still say LGU. Keep role alias tests but update expected user-facing terminology. |
| `recytecmobproj/docs/MOBILE_INTEGRATION_CONTRACTS.md` | Migrate | Existing contract should be updated to partner organization endpoints and fields. |
| `recytecmobproj/backend/server.js` | Keep temporarily for compatibility | `normalizeAuthRole` maps partner aliases to `LGU`; replace canonical output with partner role once clients are migrated. |
| `recytecmobproj/lib/presentation/lgu/deposits/**` | Obsolete/remove or keep detached | Legacy camera/deposit screens are explicitly deprecated/unrouted according to comments in `bin_monitoring_models.dart:275`. |

## Obsolete Functionality Audit

| Functionality | Status | Evidence/File | Recommendation |
| --- | --- | --- | --- |
| Household waste tracking | Mostly removed from active UI | Active dashboard has Drop-Off History only; legacy `submission_form_code.txt` navigates to `TrackingScreen`. | Keep out of active routes; delete old pasted/generated files when no longer needed. |
| Household routing/pickup request | Compatibility leftover | `RequestRepository.submitRequest` still posts pickup requests in `request_repository.dart:44`; docs say no longer exposed in mobile UI. | Mark as legacy and remove after collector/admin migration no longer depends on it. |
| Household collection tracking | Not active in current `lib` | `submission_form_code.txt` imports tracking screen, but active dashboard does not. | Ensure no active route/menu points to household collection tracking. |
| Collector Accept | Obsolete compatibility method | `CollectorRepository.acceptJob` exists in `collector_repository.dart:69`; current UI progresses statuses rather than showing Accept. | Remove/replace with backend FIFO claim/start endpoint. |
| Collector Reject | Not found in collector mobile UI | Search found no collector reject action. | Keep collectors unable to reject. |
| Manual collector approval/decline | Present in web admin request management | React request management has approve/reject in `RequestManagement.jsx:172` and `RequestManagement.jsx:190`. | Decide if web admin approval/rejection remains for partner requests; keep out of collector app. |
| Obsolete LGU workflows | Present | LGU folders, models, docs, notification kinds, and demo IDs remain. | Rename/migrate to Partner Organization; remove deprecated deposit/camera screens if not required. |
| Legacy camera/deposit detection | Deprecated/unrouted | `BinMonitoringService` methods are marked deprecated in `bin_monitoring_repository.dart:11`; model comment says detached in `bin_monitoring_models.dart:275`. | Remove once new ToF/partner-bin workflow is stable. |

## Notifications Audit

Current notification logic is mock-only:

- `NotificationRepository` stores in-memory role-filtered notifications in `notification_repository.dart:4`.
- Backend contract comments list `GET /api/notifications?role=:role`, `PATCH /api/notifications/:id/read`, and `PATCH /api/notifications/read-all?role=:role` in `notification_repository.dart:66`.
- Notification destinations include household drop-off, LGU request, LGU bin, and collector assignment in `notification_model.dart:41`.
- UI enforces role checks before opening household/LGU destinations in `notification_center_screen.dart:83`.

Required fixes:

- Add backend Notification model/API or remove notification UI from production.
- Rename LGU notification kinds/copy to Partner Organization.
- Ensure backend filters by authenticated account/role, not caller-supplied role alone.
- Generate notifications from backend events: drop-off recorded, reward credited, sensor alert, partner request queued, collector assignment, collection completed.

## Final Workflow Validation

| Flow | Validation | Missing/Gaps |
| --- | --- | --- |
| Household: Register -> Verify Email -> Login -> Bin Locator -> Select Bin -> View Partner Rewards -> Manual Form OR Scan QR -> Submit Drop-Off -> Earn Points -> View Points & Rewards | Partially valid through Register/Verify/Login/Bin Locator/Scan QR/Mock Drop-Off/Mock Rewards. | Partner rewards not visible from bins; manual drop-off form missing; drop-off, points, and rewards are not backend-authoritative. |
| Partner Organization: Register -> Verify Email -> Pending Admin Approval -> Web Admin Activates -> Login -> My Bins -> Select Bin -> View Latest Stored Status -> Refresh Status Manually -> Needs Collection? -> Submit Collection Request -> Request enters queue -> Track Request -> Completed | UI shape exists after login under LGU/partner shell for bins, status, refresh, request submission, and tracking. | Registration/verification/admin approval covered as missing in auth audit; partner bins/requests/sensor are mocks; web admin partner management missing; request completion is not linked to backend partner request lifecycle. |
| Collector: Register -> Verify Email -> Pending Admin Approval -> Web Admin Activates -> Login -> View FIFO Collection Queue -> Open next request -> View Partner Organization + Bin + Location -> Start Collection -> Perform collection/documentation -> Submit Collector Report -> Complete Request -> Next FIFO Request | Mobile collector UI supports login, available requests, details, map, status progression, local YOLO capture, documentation, and local completion. | Registration/approval missing from auth audit; queue is client-filtered from all requests; FIFO and assignment are not backend-enforced; partner/bin detail is incomplete; report is mock-only; concurrency protection missing. |
| Web Admin: Manage Partner Organization Accounts, Manage Collector Accounts, Approve/Activate/Disable accounts, View email verification status, Manage appropriate system/admin functions | Collector/user/resident management exists partially. | Partner Organization management missing; email verification visibility missing; account approval/status model incomplete; admin request management is still pickup-centric and includes approve/reject flows that may not match final partner bin request queue. |

## Priority Continuation Fix List

1. Decide and document canonical role/domain naming: `partnerOrganization` should replace LGU in user-facing code, routes, and models, with compatibility aliases during migration.
2. Add authoritative Bin and PartnerOrganization models and ownership links.
3. Add sensor ingestion/latest-reading APIs and replace `MockBinMonitoringService`.
4. Add partner collection request model/API with one-active-request-per-bin enforcement.
5. Add collector FIFO queue and atomic claim/start/complete endpoints.
6. Add CollectorReport model/API and evidence upload handling.
7. Add household QR validation/drop-off/reward APIs and replace `MockDropOffRepository`.
8. Add partner reward offer and household reward/points ledger/redemption models if exchange is in scope.
9. Add notifications backend or explicitly keep notifications prototype-only.
10. Remove or quarantine obsolete household pickup/tracking, collector `acceptJob`, and deprecated LGU camera/deposit workflow after replacement APIs are available.
