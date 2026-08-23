# RecyTech Mobile Integration Contracts

Phase 5 status: this document separates actual mobile API usage from recommended backend work that is not yet implemented in the Flutter app.

## Actual Existing API Usage

| Module | Mobile code | Operation |
| --- | --- | --- |
| Auth | `AuthApi`, `AuthRepository` | login, household registration, logout, forgot password, PIN verification, password reset |
| Collector jobs | `CollectorApi`, `CollectorRepository` | fetch requests/jobs, update request status and assigned collector fields |
| Contributions | `ContributionApi`, `ContributionRepository` | fetch contribution records |

Household pickup/request submission is no longer exposed in the mobile Household UI. Legacy request API classes remain in code only so shared Collector/Admin/LGU-related backend workflows are not broken during migration.

API base URL is centralized in `Env.baseUrl` and can be overridden with:

```sh
flutter run --dart-define=RECYTECH_API_BASE_URL=http://<host>:5000/api
```

## Missing Backend Contracts

### Public Bin Locator

| Field | Requirement |
| --- | --- |
| Module | Household public/designated drop-off bins |
| Current repository | `PublicBinRepository.fetchPublicBins()` |
| Current implementation | `MockPublicBinRepository` |
| Recommended request | `GET /api/public/bins` |
| Recommended response | `[{ "id": "...", "name": "...", "address": "...", "publicStatus": "Open", "latitude": 14.0, "longitude": 121.0 }]` |
| Images/multipart | None required |
| Auth required | No, unless bins are municipality-specific |
| Status | Waiting for backend |

### HOUSEHOLD QR DROP-OFF / REWARD

PROPOSED / REQUIRED BACKEND CONTRACT. The current Flutter implementation uses `DropOffRepository` with `MockDropOffRepository` for development.

#### QR Validation

| Field | Requirement |
| --- | --- |
| Purpose | Validate that a scanned QR identifies a designated RecyTech bin |
| Recommended request | `POST /api/household/drop-offs/validate-bin-qr` |
| Auth required | Yes, Household |
| Request data | `{ "version": 1, "publicBinCode": "opaque-public-code" }` |
| Response data | `{ "binId": "...", "binName": "...", "building": "...", "locationDescription": "...", "address": "...", "active": true, "publicStatus": "Open" }` |
| Validation | Reject malformed payloads, non-RecyTech QR values, unknown public codes, inactive bins, and expired sessions |
| Duplicate protection | No reward or drop-off record should be created by validation alone |

#### Drop-Off Registration

| Field | Requirement |
| --- | --- |
| Purpose | Record an authenticated account-to-bin drop-off/check-in after the user confirms the scanned bin |
| Recommended request | `POST /api/household/drop-offs` |
| Auth required | Yes, Household |
| Request data | `{ "version": 1, "publicBinCode": "opaque-public-code", "idempotencyKey": "client-generated-uuid" }` |
| Response data | `{ "id": "...", "binId": "...", "binName": "...", "createdAt": "...", "status": "Recorded", "rewardEligible": true, "rewardValue": "...", "rewardPoints": 10, "rewardStatus": "Credited" }` |
| Validation | User identity comes from auth token/session, never from the QR payload; backend validates bin active status |
| Duplicate protection | Backend must enforce idempotency, duplicate request handling, configured reward window/cooldown, server timestamp, and unique drop-off records |

#### Reward Eligibility

| Field | Requirement |
| --- | --- |
| Purpose | Determine whether a drop-off check-in earns a reward |
| Auth required | Yes, Household |
| Input source | Backend-owned drop-off record and reward rules |
| Output source | Backend-generated reward value/points and status |
| Validation | Mobile must not compute reward value, exchange rates, categories, quantities, or weights |
| Duplicate protection | Backend must be authoritative for one eligible reward per configured window |

#### Drop-Off History

| Field | Requirement |
| --- | --- |
| Purpose | Show Household designated-bin check-ins |
| Recommended request | `GET /api/household/drop-offs` |
| Auth required | Yes, Household |
| Response data | `[{ "id": "...", "binId": "...", "binName": "...", "building": "...", "locationDescription": "...", "createdAt": "...", "status": "Recorded", "rewardEligible": true, "rewardValue": "...", "rewardPoints": 10, "rewardStatus": "Credited" }]` |
| Validation | Return only the authenticated user's records |
| Duplicate protection | History is read-only; duplicate prevention belongs to registration |

#### Reward History

| Field | Requirement |
| --- | --- |
| Purpose | Show rewards generated from eligible QR drop-off records |
| Recommended request | `GET /api/household/rewards` |
| Auth required | Yes, Household |
| Response data | `[{ "id": "...", "dropOffId": "...", "createdAt": "...", "status": "Credited", "rewardValue": "...", "rewardPoints": 10, "binName": "...", "locationDescription": "..." }]` |
| Validation | Return backend-created transactions only |
| Duplicate protection | Backend must not create duplicate reward transactions for duplicate scans |

QR payload format currently parsed by mobile:

```text
recytech://bin/<opaque-public-code>
```

The QR payload must not contain user IDs, reward values, e-waste categories, quantities, weights, private backend IDs, or secrets. A static printed QR establishes an authenticated account-to-bin check-in only. It is not cryptographic proof that physical e-waste was deposited. For the capstone prototype, use server-side validation, idempotency, and duplicate/cooldown controls. Do not add NFC, weighing hardware, bin cameras, dynamic QR displays, or biometric verification unless requested in a future scope.

### LGU Bins and ToF Readings

| Field | Requirement |
| --- | --- |
| Module | LGU assigned bins and monitoring |
| Current repository | `LguBinRepository.fetchAssignedBins()`, `fetchBin()`, `fetchMonitoring()` |
| Current implementation | `MockBinMonitoringService` |
| Recommended requests | `GET /api/lgu/bins`, `GET /api/lgu/bins/:binId`, `GET /api/lgu/bins/:binId/monitoring` |
| Recommended response | `{ "binId": "...", "binName": "...", "location": "...", "latitude": 14.0, "longitude": 121.0, "distanceCm": 8.5, "fillPercentage": 92, "fullnessStatus": "full", "sensorStatus": "online", "controllerStatus": "online", "lastUpdatedAt": "..." }` |
| Images/multipart | None required for ToF |
| Auth required | Yes, LGU |
| Status | Waiting for backend |

### ESP32 / ToF Ingestion

| Field | Requirement |
| --- | --- |
| Module | Hardware ingestion into backend |
| Current mobile repository | None. Mobile only reads backend data. |
| Recommended request | ESP32 posts to backend-owned ingestion endpoint, not Flutter |
| Recommended payload | `{ "binId": "...", "distanceCm": 8.5, "fillPercentage": 92, "sensorStatus": "online", "controllerStatus": "online", "capturedAt": "..." }` |
| Images/multipart | None |
| Auth required | Device credential/API key handled by backend |
| Status | Hardware/backend work |

### LGU Collection Requests

| Field | Requirement |
| --- | --- |
| Module | LGU request creation/list/tracking |
| Current repository | `CollectionRequestRepository.fetchCollectionRequests()`, `createCollectionRequest()` |
| Current implementation | `MockCollectionRequestRepository` |
| Recommended requests | `GET /api/lgu/collection-requests`, `POST /api/lgu/collection-requests` |
| Recommended request body | `{ "lguId": "...", "binId": "...", "binLocation": "...", "fillPercentage": 92, "fullnessStatus": "full", "requestedAt": "...", "remarks": "..." }` |
| Recommended response | Collection request id, status, timestamps, bin snapshot, assigned collector when available |
| Images/multipart | None |
| Auth required | Yes, LGU |
| Status | Waiting for backend |

### Collector Completion Report

| Field | Requirement |
| --- | --- |
| Module | Final batch collection report |
| Current repository | `CollectionCompletionRepository.submitCollectionReport()` |
| Current implementation | `MockCollectionCompletionRepository` |
| Recommended request | `POST /api/collector/collection-reports` |
| Recommended body | `requestId`, `collectorId`, optional `binId`/`lguId`, before/after evidence references, `items`, `confirmedCategorySummary`, `totalCategories`, `totalQuantity`, conditions/remarks, `startedAt`, `completedAt` |
| Item body | `id`, `aiPredictedClass`, `aiConfidence`, `confirmedClass`, `mappedCategory`, `quantity`, `condition`, `remarks`, `capturedAt` |
| Images/multipart | Use multipart upload or prior image-upload endpoint. Do not persist Android/Windows local file paths as production evidence. |
| Auth required | Yes, Collector |
| Status | Waiting for backend |

### Collector Report History

| Field | Requirement |
| --- | --- |
| Module | Collector completed report history |
| Current repository | `CollectionCompletionRepository.fetchCompletedReports()` |
| Current implementation | `MockCollectionCompletionRepository` |
| Recommended request | `GET /api/collector/collection-reports?collectorId=:id` |
| Recommended response | List of submitted collection reports, sorted by completion time |
| Images/multipart | Return URLs or backend file identifiers |
| Auth required | Yes, Collector |
| Status | Waiting for backend |

### Notifications

| Field | Requirement |
| --- | --- |
| Module | Shared role-filtered notifications |
| Current repository | `NotificationRepository.fetchNotifications()`, `markAsRead()`, `markAllAsRead()` |
| Current implementation | In-memory mock |
| Recommended requests | `GET /api/notifications?role=:role`, `PATCH /api/notifications/:id/read`, `PATCH /api/notifications/read-all?role=:role` |
| Recommended response | `{ "id": "...", "title": "...", "message": "...", "timestamp": "...", "isRead": false, "role": "collector", "type": "...", "relatedEntityId": "...", "destination": { "kind": "...", "entityId": "..." } }` |
| Images/multipart | None |
| Auth required | Yes |
| Status | Waiting for backend; no fake push delivery in mobile |

## Image Upload Readiness

Current image handling:

- Household has no e-waste image capture, upload, AI identification, category claim, quantity claim, weight claim, pickup address, or pickup request workflow.
- Collector before evidence, item scan images, and after evidence are local file paths inside the mock completion report.
- Collector YOLO item images are local runtime evidence for the active workflow.

Production requirement:

- Add a backend-supported upload mechanism before persisting collector reports.
- Prefer multipart/form-data fields such as `beforeImage`, `afterImage`, and `itemImages[]`, or a separate upload endpoint returning stable file IDs/URLs.
- Mobile should submit backend image references in final report payloads, not permanent local file paths.

## Analytics Separation

Household QR data:

- authenticated user/account
- designated bin
- drop-off/check-in timestamp
- backend reward/check-in result

Collector verified collection data:

- confirmed e-waste category
- quantity
- bin/LGU/Collector context
- completion timestamp

Official e-waste category and quantity analytics must use Collector-confirmed collection reports, not Household QR check-in data.
