# Simple Role-Based Access Control and Navigation Filtering

The application previously stored user records as unstructured JSON with loose string roles in `SharedPreferences` without role-based navigation or screen access controls. We decided to standardize on a simple, straightforward Role-Based Access Control model with three primary roles (`Admin`, `Cashier`, `Accountant`). Each role maps directly to allowed application areas (e.g., POS, Inventory, Accounting, Users/Settings), enforced via dynamic sidebar filtering. This avoids unnecessary complexity (such as permission matrices, custom capability overrides, or PIN-switching layers) while ensuring clean operational separation between staff duties.

