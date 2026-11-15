# Bokrah Retail

Point-of-sale, inventory, and retail management system tailored for shops, consumer electronics, and general retail businesses.

## Retail Store & Entity Management

**Store (`المتجر`)**:
The commercial enterprise or retail shop entity managing products, points of sale, staff, tax identification, and warranties.
_Avoid_: Restaurant, kitchen, dining outlet

**Store Profile (`ملف المتجر`)**:
The business profile encompassing Commercial Registration (CR), Tax/VAT identification, business category (e.g., Electronics & Smart Devices), warranty policy, return window, and branch address.
_Avoid_: Restaurant profile, cuisine type, menu setup

**Business Category (`نوع النشاط / التخصص`)**:
The commercial classification of the retail store (e.g., Electronics & Mobile, Computer Hardware, Gadgets & Accessories, General Retail).
_Avoid_: Cuisine type, food category

**Retail Tax Receipt (`فاتورة مبيعات التجزئة المبسطة`)**:
A point-of-sale tax invoice compliant with electronic invoicing standards (e.g. ZATCA), featuring store tax numbers, item serials, warranty statements, and return conditions.
_Avoid_: Kitchen order ticket, dining receipt, meal ticket

**Warranty Policy (`سياسة الضمان`)**:
The documented terms specifying guarantee periods and repair/replacement coverage for sold electronics, hardware, or appliances.
_Avoid_: Food expiry, cooking guarantee

**Return & Exchange Policy (`سياسة الاسترجاع والاستبدال`)**:
The store policy governing eligible return and exchange timeframes and required packaging/invoice conditions.

**Store Onboarding (`تهيئة المتجر`)**:
The initial setup workflow where an authenticated operator registers their store profile, business classification, and legal tax identifiers before unlocking commercial retail operations.
_Avoid_: Restaurant onboarding, restaurant registration, restaurant setup

## Application Updates

**App Update**:
The procedure of comparing the installed client build against published releases, notifying the user, and delivering the new platform binary.
_Avoid_: Upgrade, patch

**Release**:
A versioned distribution package published to GitHub containing changelogs and platform installer assets.
_Avoid_: Build artifact, tag

**Installer Asset**:
A platform-targeted executable or archive package (e.g., `.exe` for Windows, `.apk` for Android) attached to a Release.
_Avoid_: Download file, payload

**Skipped Version**:
A Release version explicitly dismissed by the user to suppress automated startup update prompts until a higher version is published.
_Avoid_: Ignored update, muted version

## Users & Access Control

**Operator**:
An authenticated staff member actively interacting with the client application or terminal.
_Avoid_: Active user, waiter, chef, cashier (when referring generically to any staff member operating the system)

**Guest**:
An unauthenticated user permitted to browse catalog and system screens in read-only mode without mutating business data or accounting records.
_Avoid_: Anonymous user, visitor, public user

**Role**:
A named level of access assigned to an operator (`Admin`, `Cashier`, `Accountant`) determining which application areas and pages are accessible.
_Avoid_: Group, profile, user type

**Access Level**:
The scope of screens and operations an operator is authorized to access based on their assigned role.
_Avoid_: Entitlement, privilege, permission matrix

## Navigation & Redirection

**Public Auth Route**:
A client route (`/login`, `/register`) dedicated exclusively to unauthenticated visitors and guests; authenticated operators navigating here are automatically redirected away.
_Avoid_: Login screen, sign-in url

**Store Onboarding Route**:
A designated route (`/store-info`, `/create-store`) for authenticated operators to establish their store profile; accessed post-registration or when onboarding is incomplete.
_Avoid_: Store wizard, setup link

**Guarded Route**:
An application route whose access is restricted based on user tier (`Guest`, `Authenticated Without Store`, `Authenticated With Store`) or role entitlement.
_Avoid_: Protected page, locked url
