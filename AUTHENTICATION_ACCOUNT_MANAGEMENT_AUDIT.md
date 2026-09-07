# Authentication & Account Management Audit

Date: 2026-08-29

Scope reviewed:

- Mobile Flutter app: `recytecmobproj/lib`
- Mobile integration/mock API backend: `recytecmobproj/backend/server.js`
- Web admin frontend: `recytech-web/recytechfrontend/src`
- Web admin/backend API: `recytech-web/recytechbackend`

## Executive Summary

The current implementation partially satisfies the household-user registration and email-verification requirements in the mobile-side backend and Flutter app. It does not yet satisfy the full required model for all three mobile actors.

Major gaps:

- Partner Organization and Collector cannot self-register through the mobile registration UI.
- The mobile-side registration backend explicitly permits only household/registered-user registration.
- The web backend has a public `/api/auth/register` route that accepts caller-supplied roles and immediately returns a JWT, which is a role-escalation and verification-bypass risk.
- Email verification exists in the mobile-side backend only. The web admin/backend `User` and `Resident` schemas do not include email-verification fields.
- Partner Organization accounts are not represented as a distinct web-admin-managed account/profile type. Existing mobile code normalizes LGU/partner roles, but no mobile partner registration flow exists.
- Account status and email verification are not consistently separated. The mobile backend has `emailVerified`, but not `accountStatus`; the web backend has `status`, but not email verification.
- Web admin can manage collectors and residents, but cannot display or manage email-verification state because the web schemas and tables do not expose it.

## Authentication & Account Management Audit

| Requirement | Household | Partner Org | Collector | Web Admin | Status | Evidence/File | Required Fix |
| ----------- | --------- | ----------- | --------- | --------- | ------ | ------------- | ------------ |
| Mobile registration | Partial | Missing | Missing | N/A | Fail | Mobile register form submits only `fullName`, `email`, `password`; login link says "Create Household Account" in `recytecmobproj/lib/presentation/auth/register_screen.dart:41` and `recytecmobproj/lib/presentation/auth/login_screen.dart:195`. Backend registration rejects non-household roles in `recytecmobproj/backend/server.js:80` and `recytecmobproj/backend/server.js:413`. | Add role selection/role-specific forms for Household, Partner Organization, and Collector. Backend must map allowed public registration roles to safe roles and profile records. |
| Correct role stored | Partial | Missing | Missing | Partial | Fail | Mobile API defaults role to `Staff` in `recytecmobproj/lib/data/datasources/auth_api.dart:88`; mobile constants normalize `Staff` as household in `recytecmobproj/lib/core/constants/app_constants.dart:24`. Web collector creation sets role `Collector` in `recytech-web/recytechbackend/routes/collectorRoutes.js:35`. | Use canonical roles such as `household`, `partner_org`, `collector`, `admin`. Avoid using `Staff` as household identity. |
| Role protection during registration | Pass in mobile backend, fail in web backend | Missing | Missing | Risk | Fail | Mobile backend only allows registered users in `recytecmobproj/backend/server.js:413`. Web public registration accepts `role` and saves `role: role || 'Staff'` in `recytech-web/recytechbackend/routes/authRoutes.js:131` and `recytech-web/recytechbackend/routes/authRoutes.js:155`. | Remove public caller-controlled admin/staff role assignment. Only admin APIs should create privileged accounts. Public registration must whitelist mobile roles only. |
| Email verification | Partial | Missing | Missing | Missing | Fail | Mobile backend creates `emailVerified: false` and `emailVerification` state in `recytecmobproj/backend/server.js:428`; mobile screen verifies PIN in `recytecmobproj/lib/presentation/auth/verify_email_screen.dart:40`. Web `User` model has no verification fields in `recytech-web/recytechbackend/models/User.js:1`. | Add verification fields and flows to the authoritative backend for all three mobile roles. Ensure web admin can see verification state. |
| Resend verification | Partial | Missing | Missing | Missing | Fail | Mobile endpoint exists in `recytecmobproj/backend/server.js:486`; Flutter calls it in `recytecmobproj/lib/presentation/auth/verify_email_screen.dart:64`. | Extend resend support to partner and collector registrations. Add abuse protections beyond simple cooldown if exposed publicly. |
| Verification token expiration | Partial | Missing | Missing | Missing | Fail | Mobile OTP TTL is configured with `OTP_TTL_MINUTES` in `recytecmobproj/backend/server.js:19`; validation checks expiry in `recytecmobproj/backend/server.js:465`. | Apply the same expiration logic to the production/authoritative auth backend and all roles. |
| Verification token one-time use | Partial | Missing | Missing | Missing | Fail | Mobile backend unsets `emailVerification` after success in `recytecmobproj/backend/server.js:475`. | Keep token/PIN state server-side, hashed, expiring, and consumed on success for all roles. |
| Verification success/invalid/expired handling | Partial | Missing | Missing | Missing | Fail | Flutter success path returns to login in `recytecmobproj/lib/presentation/auth/verify_email_screen.dart:40`; backend returns invalid/expired responses from `assertValidPinState` used by `recytecmobproj/backend/server.js:465`. | Ensure all mobile role flows use the same screen or role-aware variant; add tests for invalid, expired, reused, and resend cases. |
| Login after verification | Partial | Missing | Missing | Missing | Fail | Mobile backend denies unverified login in `recytecmobproj/backend/server.js:515` and `recytecmobproj/backend/server.js:536`. Web backend login checks role/status only, not verification, in `recytech-web/recytechbackend/routes/authRoutes.js:68`. | Enforce `emailVerified` before normal login in the authoritative login route. |
| Admin activation if applicable | Missing | Missing | Missing | Partial | Fail | Mobile backend lacks `accountStatus`. Web `User.status` defaults `Active` in `recytech-web/recytechbackend/models/User.js:25`; collector creation defaults active in `recytech-web/recytechbackend/routes/collectorRoutes.js:35`. | Add `accountStatus: pending/active/disabled/rejected`. Partner org and collector public registrations should start pending until web admin activates them. |
| Account status | Missing in mobile backend | Missing | Missing | Partial | Fail | Web login blocks `Inactive` users in `recytech-web/recytechbackend/routes/authRoutes.js:83`; mobile backend login does not check account status in `recytecmobproj/backend/server.js:515`. | Separate `emailVerified` from `accountStatus` and check both during login/session use. |
| Forgot password | Present | Policy undecided | Policy undecided | Present for web users | Partial | Mobile forgot/reset UI exists in `recytecmobproj/lib/presentation/auth/forgot_password_screen.dart:55`; mobile backend routes exist in `recytecmobproj/backend/server.js:561`. Web reset routes exist in `recytech-web/recytechbackend/routes/authRoutes.js:176`. | Decide whether partner org and collector may self-reset passwords. If yes, enforce the same email/status rules and rate limits. |
| Reset password | Present | Policy undecided | Policy undecided | Present for web users | Partial | Mobile reset calls `resetPassword` in `recytecmobproj/lib/data/repositories/auth_repository.dart:135`; mobile backend clears reset state in `recytecmobproj/backend/server.js:620`. Web backend uses reset PIN fields in `recytech-web/recytechbackend/routes/authRoutes.js:198`. | Hash reset PINs in web backend or consolidate on the mobile backend's hashed state approach. Add rate limiting. |
| Profile viewing | Present | Present read-only LGU profile | Present read-only collector profile | Present | Pass/Partial | Household profile reads current user in `recytecmobproj/lib/presentation/user/profile/profile_screen.dart:16`; LGU profile read-only rows in `recytecmobproj/lib/presentation/lgu/profile/lgu_profile_screen.dart:76`; collector read-only rows in `recytecmobproj/lib/presentation/collector/profile/collector_profile_screen.dart:102`. | Keep partner and collector mobile profiles read-only except explicitly approved operational fields. |
| Profile editing | Missing/limited | Not provided | Not provided | Present | Partial | Household profile only supports local image selection in `recytecmobproj/lib/presentation/user/profile/profile_screen.dart:34`; `edit_profile_screen.dart` is empty. Collector/LGU profile screens show no edit controls. | Add household-only profile update API with ownership checks. Do not add partner/collector self-service admin edits. |
| Role protection after login | Partial | Partial | Partial | Partial | Partial | Mobile routes role by normalized backend role in `recytecmobproj/lib/core/constants/app_constants.dart:57`; web protected routes are frontend-gated in `recytech-web/recytechfrontend/src/App.jsx:35`. Backend admin middleware exists in `recytech-web/recytechbackend/middleware/authMiddleware.js:45`. | Ensure every role-sensitive backend endpoint checks role/ownership; do not rely on Flutter/React route hiding. |
| Admin account management | N/A | Missing as partner org | Present for collector | Present for web users/residents | Partial | User admin routes are Super Admin only in `recytech-web/recytechbackend/routes/userRoutes.js:10`; collector admin routes are Admin/Super Admin in `recytech-web/recytechbackend/routes/collectorRoutes.js:10`. No partner organization route/model found. | Add Partner Organization model/routes/admin UI. Show email verification, account status, creation date, and registration details. |
| Account disable/deactivate | Missing in mobile backend | Missing | Partial via web | Present in web | Partial | Web user update can set `status` in `recytech-web/recytechbackend/routes/userRoutes.js:100`; collector update syncs status to linked user in `recytech-web/recytechbackend/routes/collectorRoutes.js:76`. | Enforce disabled status across all auth/session middleware and mobile APIs. Add partner org disable/activate. |
| JWT/session restoration | Partial | Partial if account can log in | Partial | Partial | Partial | Mobile stores token/user and restores local user only in `recytecmobproj/lib/data/repositories/auth_repository.dart:81`; no `/auth/me` validation exists. Web middleware validates JWT in `recytech-web/recytechbackend/middleware/authMiddleware.js:14`. | Add `/auth/me` or session validation to refresh current account, verification, status, and role after app restart. |

## Role-by-Role Findings

### Household User

Current status: Partially implemented.

- Mobile household registration exists through the Flutter register screen and mobile backend.
- Registration creates an unverified account and sends a PIN email when SMTP is configured.
- Login is denied until email verification succeeds.
- Forgot/reset password exists in the Flutter app and mobile backend.
- Full self-service account management is not complete. The visible profile screen displays account fields and logout, but the edit-profile file is empty and no protected profile update endpoint was found.
- Backend ownership enforcement for household profile update cannot be confirmed because the update API is missing.

Required fixes:

- Keep household registration and verification, but store the canonical role as `household` or equivalent instead of overloading `Staff`.
- Add household-only profile update endpoints for allowed fields.
- Block role, points, reward balance, account status, and admin-field updates at the backend.
- Add session restoration through a server-validated `/auth/me` endpoint.

### Partner Organization

Current status: Not implemented as required.

- The mobile app can route an LGU/partner role after login, but there is no partner organization registration screen or role-specific registration payload.
- The mobile backend rejects non-household registration roles.
- The web backend has no Partner Organization model/profile or admin management route in the reviewed files.
- The LGU profile screen is read-only, which aligns with the no-self-service-management rule.

Required fixes:

- Add mobile partner organization registration with organization-specific fields.
- Backend should create an unverified partner account plus a partner organization profile.
- After email verification, keep `accountStatus` as `pending` until web admin activation if approval is required.
- Add web admin list/detail/update/activate/disable/reject APIs and UI.
- Keep mobile partner profile read-only except operational features such as bins, requests, tracking, and rewards.

### Collector

Current status: Partially implemented for web-admin-created collectors; missing mobile self-registration.

- Web admin can create, view, update, and delete collectors.
- Collector creation creates a linked `User` with role `Collector`.
- Mobile collector profile is read-only plus logout, which matches the requirement.
- Mobile collector registration and email verification are missing.
- Web collector records do not show email verification status, and the `Collector` model has no direct account verification state.

Required fixes:

- Add collector mobile registration with required identity/contact/vehicle fields.
- Backend should create an unverified collector account and linked collector profile.
- After verification, keep collector `accountStatus` pending until admin activation if that is the policy.
- Web admin collector table/detail must display email verification status, account status, and creation date.
- Do not add collector self-service account edit/delete/role/status controls in mobile.

### Web Admin

Current status: Partial.

- Super Admin can manage general users.
- Admin/Super Admin can manage collectors.
- Admin/Super Admin can manage mobile residents, but this appears to be simulation/linking-oriented rather than authoritative household account management.
- Web admin cannot view or manage partner organization accounts because no partner account surface was found.
- Web admin cannot view email verification state because web `User`, `Resident`, and `Collector` schemas do not expose it.

Required fixes:

- Add unified admin account-management surfaces for Partner Organizations and Collectors.
- Display `emailVerified`, `accountStatus`, `role`, `createdAt`, and `updatedAt`.
- Restrict account status transitions to admin APIs.
- Prevent public registration endpoints from creating privileged internal roles.

## Email Service Audit

Mobile-side backend:

- Uses `nodemailer` when available and configured.
- Requires SMTP settings through environment variables: `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, optional `SMTP_PORT`, `SMTP_SECURE`, and `EMAIL_FROM`.
- Sends email-verification and password-reset PINs.
- Stores hashed PIN state using HMAC, expiration, resend cooldown, attempt count, and one-time clearing.
- Does not hardcode SMTP credentials.

Web backend:

- Uses MailerSend through `axios`.
- Uses `MAILERSEND_API_KEY` and `MAILERSEND_FROM_EMAIL`, but has a hardcoded default sender domain in source.
- Sends password-reset PINs only, not email-verification messages.
- Stores reset PINs in plaintext fields `resetPin` and `resetPinExpiry`.
- Does not rate-limit password reset requests in code reviewed.

Required fixes:

- Choose one authoritative backend email service, or share a common email service module.
- Do not introduce another provider unless replacing/consolidating the existing providers.
- Remove hardcoded sender defaults from source and require environment configuration.
- Store verification and reset tokens/PINs hashed server-side.
- Add resend throttling/rate limiting and audit logging.

## Database Model Audit

Current mobile-side backend user document supports:

- `role`
- `email`
- `passwordHash`
- `emailVerified`
- `emailVerification` with hashed PIN state
- `createdAt`
- `updatedAt`
- `passwordReset` with hashed PIN state

Missing from mobile-side backend:

- `accountStatus`
- partner organization profile data
- collector profile data

Current web backend `User` model supports:

- `role`
- `email`
- `password`
- `status`
- `createdAt`
- `updatedAt`
- reset PIN fields

Missing from web backend `User` model:

- `emailVerified`
- `emailVerificationToken` or hashed verification state
- `emailVerificationExpiresAt`
- explicit `accountStatus` enum distinct from general `status`

Recommended architecture:

- Keep identity/authentication fields in one authoritative account model: email, password hash, role, email verification, account status, timestamps.
- Store Partner Organization-specific data in a separate `PartnerOrganization` profile linked to the account.
- Store Collector-specific data in the existing `Collector` profile linked to the account, but add account status/verification display through population or aggregation.
- Do not duplicate password/email verification fields in role profile models.

## Obsolete or Conflicting Functionality

Flagged:

- Public web `/api/auth/register` allows caller-supplied roles and immediate token issuance. This conflicts with the requirement that registration must not imply verification or full approval.
- Web User Management can update roles and statuses, which is acceptable only for Super Admin, but it lacks email-verification visibility.
- Web Collector Management creates collector accounts directly with a password and active status. This is useful for admin-created accounts but does not satisfy mobile collector registration and admin approval.
- No partner organization admin-management surface was found.

Not flagged:

- Collector mobile profile is read-only and logout-only.
- LGU/partner mobile profile is read-only and logout-only.
- Household profile does not expose role/status/points/reward-balance editing.

## Backend Enforcement Rules Required

Recommended login/session logic:

1. Find account by normalized email.
2. Verify password hash.
3. Reject if `emailVerified` is false.
4. Reject if `accountStatus` is `pending`, `disabled`, `inactive`, or `rejected`, with distinct messages.
5. Issue JWT only after verification and status checks pass.
6. On `/auth/me` and protected API access, re-check current account status so disabled accounts cannot continue using old tokens.

Recommended registration rules:

1. Public mobile registration accepts only `household`, `partner_org`, and `collector`.
2. Backend maps request roles from a whitelist; it ignores or rejects admin/staff/super-admin roles.
3. Household accounts start as `emailVerified: false`, `accountStatus: active` or `pending` depending on policy.
4. Partner Organization and Collector accounts start as `emailVerified: false`, `accountStatus: pending`.
5. Verification changes only `emailVerified`, not `accountStatus`.
6. Web Admin changes only `accountStatus` and allowed profile fields, not password/email verification by default.

## Priority Fix List

1. Remove public role escalation from `recytech-web/recytechbackend/routes/authRoutes.js`.
2. Decide which backend is authoritative for mobile auth, then consolidate verification/status fields there.
3. Add `emailVerified` and hashed verification state to the authoritative account model.
4. Add `accountStatus` separate from `emailVerified`.
5. Add Partner Organization registration/profile/admin management.
6. Add Collector mobile registration that creates a pending, unverified account.
7. Add web admin visibility/actions for verification state and account status.
8. Add household profile update API with ownership enforcement.
9. Add `/auth/me` session validation and backend status checks on protected routes.
10. Add tests for role tampering, duplicate email, unverified login, pending approval login, disabled login, token reuse, expired verification, and resend throttling.
