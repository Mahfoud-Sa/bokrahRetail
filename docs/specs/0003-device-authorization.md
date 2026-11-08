# Device Authorization and Device Limit

Status: Draft — indefinite offline use after device approval confirmed; sync integration, replacement policy and deployment scope pending.

## Contents

- [Purpose](#purpose)
- [Current project](#current-project)
- [Rules](#rules)
- [Admin experience](#admin-experience)
- [Device activation and runtime access](#device-activation-and-runtime-access)
- [Offline operation](#offline-operation)
- [Enforcement boundary](#enforcement-boundary)
- [Acceptance criteria](#acceptance-criteria)
- [Decisions before implementation](#decisions-before-implementation)
- [العربية](#العربية)

## Purpose

Allow an authorized administrator to control which computers may run Bokrah and
the maximum number of authorized devices. The minimum permitted device limit is
**one**; the default limit is **one**.

This counts approved device activations, not logged-in users, app windows, or
simultaneous sessions. Two staff members sharing an approved computer consume
one device slot. An approved device retains its slot when offline or shut down.

Approved devices may operate offline indefinitely. The limit is enforced on
approvals in the authoritative registry. Immediate revocation of a disconnected
device cannot be guaranteed; its authorization status is reconciled on reconnect.
Strict limits on the number of computers actually able to run at every instant
are incompatible with indefinite offline access and immediate slot replacement.

Draft scope assumption: one shared policy per restaurant installation/organization,
covering all of its branches. Changing that scope requires an explicit decision.

## Current project

- Flutter app using Cubit, GetIt and GoRouter; preserve these conventions.
- `AuthService` abstracts authentication, but dependency registration currently
  supplies `MockAuthService`. It cannot serve as a production authorization authority.
- The roles specification defines Admin, Cashier and Accountant and requires
  offline access. Admin-only UI does not replace authoritative permission checks.
- Local preferences and a separate database on each computer cannot establish
  a reliable shared device count across independent installations.
- The user confirms an asynchronous sync feature. Inspect and reuse its existing
  authority, identity, retry and conflict-handling boundaries before implementation;
  this specification does not assume a second independent synchronization system.
- There are existing uncommitted restaurant-feature changes. This specification
  does not alter those files or introduce a runtime access gate.

## Rules

1. `deviceLimit` must be an integer greater than or equal to 1. Reject zero,
   negative values, fractions and invalid text; never silently coerce them.
2. Only an authenticated, authorized Admin may change the policy, approve,
   revoke or replace devices. The authority verifies these permissions.
3. Current approved count in the authority must never exceed the limit. Pending requests
   do not consume slots; approved devices do, even while offline.
   A pending local approval is not permission to run. Revocation delivery status
   is tracked separately; see the replacement-policy decision below.
4. Raising the limit does not automatically approve pending devices.
5. Lowering the limit below the current approved count is rejected until the
   admin chooses devices to revoke, or submits an atomic policy-and-revocation
   change. Never silently select devices to block.
6. Approval and slot allocation must be atomic and idempotent. Concurrent
   requests for the final slot cannot both succeed; retrying a successful
   request cannot consume another slot.
7. Revoking a device removes its authorization at the authority immediately,
   not its accounting data. Its local app blocks after receiving and persisting
   the authenticated revocation. Reauthorization requires a new approved grant.
8. A limit of one means one device may be authorized. It does not mean a lost
   or compromised last device must remain authorized. Allow revocation with a
   clear confirmation and an owner recovery/activation path.
9. Replacing a device swaps old and new authorizations atomically. At a limit
   of one, do not require approving two devices before revoking the old one.
   If the old device cannot acknowledge revocation, clearly show that it may keep
   operating offline indefinitely. Whether to reserve its slot until acknowledgment
   or release it for replacement is an explicit remaining policy decision. Never
   imply that swapping registry records remotely stopped the old installation.
10. Sign-out, app updates and normal restarts do not consume new slots. A
    reinstall or material hardware change uses the defined recovery process;
    copying app files or a local database does not authorize another computer.
11. Device authorization and user authentication are separate requirements:
    an approved device does not grant Admin access to its operator.

## Admin experience

Add **Settings → Devices / الإعدادات ← الأجهزة**, visible to Admins.

Show the configured limit and usage, for example **2 of 3 devices authorized**,
plus pending activation requests. Each record displays its friendly name,
masked identifier, platform, app version, approval time, last verification,
status and approving administrator. Mark the current device distinctly.
Distinguish last sync from current reachability: an old last-seen timestamp does
not prove a device stopped running. Show **revocation pending delivery** until
the device acknowledges it, even if the authority already rejects its access.

Actions: change limit, inspect a device, approve a request, revoke access,
replace a device and inspect the audit history. Confirm revocation, especially
for the current or final authorized device. Unavailable actions explain why.
Both Arabic RTL and English LTR use existing design-system components.

Example: limit = 2, and devices A and B are approved. Device C can open only
the activation screen. An Admin can raise the limit and approve C, or replace B
with C. Starting a second window on A consumes no extra slot.

## Device activation and runtime access

1. A new installation establishes its device identity and requests activation
   for the intended restaurant organization. Do not collect raw hardware serials
   unnecessarily or use a display name/MAC address as the sole proof of identity.
2. The Admin verifies the request and approves it if a slot is available.
   Approval returns a verifiable grant bound to that organization and device.
3. At startup/resume, locally verify the persisted device-bound approval and any
   known revocation in addition to the operator's applicable session policy.
   A valid local approval permits offline entry without a network check. Do not
   briefly expose protected pages while local authorization is unknown.
4. Unauthorized, revoked or invalid-grant installations show a restricted
   activation screen, not POS/accounting pages. Include retry, activation status,
   and instructions for contacting the Admin. Do not delete stored records.
5. Apply the gate to direct routes and service operations as well as navigation
   visibility. Restrict shared backend requests at their authority too.
6. On known revocation or invalid local approval, block new operations and preserve drafts. Let
   already accepted atomic writes finish safely; never interrupt a database
   transaction midway. Transition to the restricted screen afterward.
7. First-device approval requires verified owner provisioning. A fresh install
   must not bypass the shared count by seeding its own unrestricted Admin.
8. Recovery must work when the only approved computer is unavailable. It cannot
   depend solely on opening Settings on that same computer.

State examples: checking local approval, pending approval, authorized online,
authorized offline, limit reached, revocation pending delivery, revoked locally,
invalid grant, sync unavailable.
Network failure is not evidence that a device was revoked.

## Offline operation

Approved user policy: **once a device is approved, it can operate offline for an
unlimited duration**. This supersedes the previously selected 7-day allowance.
There is no authorization TTL, renewal deadline, daily check requirement or
forced internet connection based solely on elapsed offline time.

- Initial approval must be confirmed by the shared authority and persisted as
  a verifiable, organization/device-bound grant before offline use is permitted.
  A first-time unapproved installation cannot self-approve while disconnected.
- Integrate status reconciliation with the existing asynchronous sync lifecycle:
  on reconnect and before protected business sync, confirm device status with the
  authority. While connected, receive changes using the existing sync transport
  and its bounded retry/backoff policy. Do not block local work on a transient
  timeout, network outage or time since last sync.
- An authenticated control exchange may deliver a revocation even when business
  sync is disallowed. A network connection or successful operator login alone
  does not prove device approval.
- An explicit authenticated revocation blocks protected access once received.
  Persist that decision so going offline again or restarting cannot restore the
  old approval. Only a later authorized, verifiable reapproval can restore it.
- Use ordered policy/device revisions to reject stale approval messages after
  revocation. Serialize approval, revocation and replacement decisions at the
  authority; do not resolve authorization conflicts with client timestamps.
- Preserve queued financial records and drafts if the device is revoked before
  syncing. Normal protected business sync must not bypass revocation. Provide a
  separately authorized admin recovery/reconciliation path; do not silently delete
  records, accept revoked-device uploads, or classify a timeout as revocation.
- Indefinite offline work also requires the existing operator/session policy to
  support offline use. Audit and reconcile any session-expiry behavior separately;
  a device grant is not a substitute for operator authentication or permissions.
- Approval must survive normal restarts and updates. Missing, corrupt, forged or
  wrong-device approvals remain invalid; indefinite duration is not a signature
  or identity bypass. Do not use local-clock aging as an authorization condition.
- A revoked device that never reconnects may keep working locally indefinitely.
  Display this limitation explicitly. The replacement-policy choice determines
  whether an unacknowledged old device continues reserving a slot.

## Enforcement boundary

Maintain a shared authoritative device registry and policy, accessible over the
selected deployment network. Backend hosting and identity integration are not
yet chosen. Production authorization cannot be implemented by the current mock
authentication service or a locally editable boolean.

The registry records organization, device identity, approval status, policy
version, revocation-delivery acknowledgment and audit events. Grants are signed by the authority; signing secrets
never ship inside the desktop application. Specify platform-backed device-key
storage and reinstall/recovery behavior before implementing identity binding.

Client-side controls cannot guarantee protection against a determined machine
owner modifying a fully local executable. State this trust boundary clearly;
protect shared services with server-side authorization wherever they exist.

Use a separate device-authorization service/repository abstraction and Cubit,
registered with existing GetIt. Add runtime routing enforcement through the
existing GoRouter setup. Keep mock/demo behavior explicitly separate from the
production authorization implementation.

## Acceptance criteria

- Default limit is 1; all values below 1 and all nonintegers are rejected.
- An Admin can inspect, approve, revoke, replace and set the device limit.
- A Cashier/Accountant cannot perform those actions through UI or direct requests.
- Approving at capacity fails without changing the registry; racing approvals
  for the final slot yield exactly one success.
- Repeated activation of the same approved identity consumes no extra slot.
- Lowering a limit cannot silently revoke devices or leave count above the limit.
- A new unapproved machine cannot enter protected routes or execute operations.
- Direct navigation does not bypass authorization; an update keeps valid identity.
- Replacing the only approved computer is supported without exceeding allocation.
- Known revocation blocks new operations safely without deleting financial data.
- An approved device continues working after 7, 30 or 365 days offline without
  a device-authorization expiry prompt or mandatory network check.
- Restarts, updates, clock changes and sync failures do not impose an offline
  duration limit. Invalid signatures or device binding still prevent access.
- Reconnect reconciles authorization before protected business sync. Authenticated
  revocation is persisted and enforced without waiting for an app restart.
- After receiving revocation, going offline or replaying an older approval does
  not restore access. Transient failures are not interpreted as revoked status.
- Queued accounting data survives revocation and remains available through an
  explicitly authorized recovery process rather than an unauthorized sync bypass.
- The Admin can distinguish registry approval from revocation delivered to the
  device. Replacement behavior follows the explicitly selected slot-release policy.
- Copying local app files/database does not by itself approve another machine.
- Owner recovery works after loss of the last approved device.
- Changes are audited; Arabic and English screens show clear localized reasons.

## Decisions before implementation

Confirmed: approved devices work offline indefinitely and authorization changes
are reconciled through sync when connectivity is available. The prior 7-day policy
and expiry-based slot reservation have been superseded.

1. Which shared authority will store approvals, verify Admin permissions and
   provide owner provisioning/recovery? Cloud or a shared on-premises deployment?
2. Confirm organization-wide versus per-branch device limits.
3. For an offline revoked/lost device, reserve its slot until revocation is
   acknowledged (possibly indefinitely), or permit explicit Admin replacement
   while acknowledging that the old offline copy may still operate? Do not promise
   both immediate replacement and a strict cap on actually runnable offline copies.
4. Audit the existing sync and operator-session behavior so neither introduces
   a hidden offline timeout or grants permissions through an authorization bypass.
5. If this later becomes paid licensing, distinguish a vendor entitlement ceiling
   from the restaurant Admin's configurable limit. No paid-license ceiling is
   assumed in this feature.

## العربية

**الميزة: اعتماد الأجهزة والحد الأقصى للأجهزة.** يحدد المدير عدد الأجهزة المسموح
بها، بحد أدنى جهاز واحد وقيمة افتراضية جهاز واحد. يعتمد المدير أجهزة محددة؛ لا
يكفي أن يمتلك المستخدم نسخة من البرنامج أو بيانات الدخول.

عند امتلاء العدد، يبقى الجهاز الجديد في شاشة التفعيل إلى أن يرفع المدير الحد
ويعتمده، أو يستبدل جهازاً معتمداً به. إيقاف الجهاز أو تسجيل الخروج لا يحرر مكانه.
إلغاء الاعتماد لا يحذف البيانات المحاسبية. يُسمح للجهاز المعتمد بالعمل دون إنترنت
لمدة غير محدودة بعد اعتماده، وتُحدّث حالة اعتماده عند عودة الاتصال عبر المزامنة.
لا توجد مهلة ٧ أيام أو مطالبة دورية إجبارية بالاتصال. إذا ألغى المدير اعتماد جهاز
غير متصل، فقد يستمر بالعمل محلياً حتى يستقبل الإلغاء. تُحفظ البيانات غير المزامنة
ولا تُحذف. يلزم تحديد سياسة استبدال جهاز مفقود غير متصل: حجز مكانه حتى يؤكد الإلغاء،
أو السماح باستبداله مع توضيح احتمال استمرار النسخة القديمة بالعمل دون اتصال.
