# Items Feature

This feature provides unified item management functionality for the Bokrah app.

## Features

### Items Page (`/items`)
A single page that handles all item operations:

**Add Items:**
- Click the + button in the app bar or floating action button
- Opens a dialog with form fields:
  - **Name**: Required field for item name
  - **Purchase Price**: Required field for the buying price (سعر الشراء)
  - **Sell Price**: Required field for the selling price (سعر البيع)
  - **Quantity**: Required integer field for stock quantity
  - **QR Code**: Optional field with scanner button (scanner functionality to be implemented)
  - **Description**: Optional multi-line text field

**Edit Items:**
- Click the edit option in the item's popup menu
- Same form as add, but pre-filled with existing data
- Updates the item when saved

**View Items:**
- All items displayed in a card-based layout
- Shows name, purchase price, sell price, quantity, profit margin, QR code (if available), and description
- Profit calculation displayed with color coding (green for profit, red for loss)
- Pull-to-refresh functionality
- Empty state with call-to-action

**Delete Items:**
- Click delete option in the item's popup menu
- Confirmation dialog before deletion

## Navigation

The items feature is accessible through:
- **Drawer Menu**: "العناصر" (Items)
- **Desktop Sidebar**: Same option available for desktop users
- **Direct URL**: `/items`

## Data Storage

Uses `SharedPreferences` for simple local storage. Items are stored as JSON strings with the following structure:

```dart
{
  'id': int,
  'name': String,
  'sellPrice': double,
  'purchasePrice': double,
  'quantity': int,
  'qrCode': String?, // optional
  'description': String?, // optional
  'createdAt': String, // ISO8601 format
}
```

## Business Logic

The ItemEntity includes built-in profit calculations:
- **Profit Margin**: `sellPrice - purchasePrice`
- **Profit Percentage**: `((sellPrice - purchasePrice) / purchasePrice) * 100`

These calculations help users understand their profit margins at a glance.

## CRUD Operations

- **Create**: Add new items via dialog form
- **Read**: View all items in the main list
- **Update**: Edit existing items via dialog form
- **Delete**: Remove items with confirmation

## Future Enhancements

- QR code scanner integration
- Image upload for items
- Categories and tags
- Barcode generation
- Export/import functionality
- Database migration from SharedPreferences to SQLite
- Bulk operations (select multiple items)
- Search and filter functionality