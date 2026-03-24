# Local Database Documentation

## Overview
This project uses SQLite (via sqflite) for local data persistence with offline-first capabilities.

## Database Structure

### Tables

#### 1. training_sites
Stores training site information with location and metadata.

**Key Fields:**
- `training_point_id` - Primary key
- `is_parent` - Whether this is a parent site (yes/no)
- `training_site` - Site name
- `latitude`, `longitude` - GPS coordinates
- `s_is_sync` - Sync status (0 = not synced, 1 = synced)
- `status` - Record status (active/inactive)
- `offline_id` - UUID for offline-created records

#### 2. beneficiaries
Stores beneficiary information linked to training sites.

**Key Fields:**
- `beneficiary_id` - Primary key
- `training_point_id` - Foreign key to training_sites
- `first_name`, `last_name` - Beneficiary name
- `gender`, `age` - Demographics
- `household_size`, `cookstoves_received` - Program data
- `s_is_sync` - Sync status

#### 3. trainings
Stores training session records.

**Key Fields:**
- `training_id` - Primary key
- `training_point_id` - Foreign key to training_sites
- `training_date` - When training occurred
- `participants_count`, `males_count`, `females_count` - Attendance
- `training_type`, `training_notes` - Training details
- `s_is_sync` - Sync status

#### 4. sync_queue
Tracks offline operations for later synchronization.

**Key Fields:**
- `id` - Auto-increment primary key
- `table_name` - Which table the operation affects
- `operation` - Type of operation (insert/update/delete)
- `record_id` - ID of the affected record
- `data` - JSON-encoded operation data
- `retry_count` - Number of sync attempts
- `last_error` - Last sync error message

## Architecture

```
lib/
├── core/
│   └── database/
│       ├── database_helper.dart    # Database initialization & migrations
│       └── README.md               # This file
├── data/
│   ├── models/
│   │   ├── training_site.dart      # TrainingSite model
│   │   ├── beneficiary.dart        # Beneficiary model
│   │   └── training.dart           # Training model
│   └── repositories/
│       ├── training_site_repository.dart
│       ├── beneficiary_repository.dart
│       ├── training_repository.dart
│       └── sync_queue_repository.dart
```

## Usage Examples

### Initialize Database
```dart
final dbHelper = DatabaseHelper.instance;
final db = await dbHelper.database; // Auto-initializes on first call
```

### Insert Data
```dart
final repo = TrainingSiteRepository();
final site = TrainingSite(
  trainingSite: 'Village A',
  district: 'District 1',
  latitude: -15.123456,
  longitude: 35.123456,
);
final id = await repo.insert(site);
```

### Query Data
```dart
// Get all active sites
final sites = await repo.getActive();

// Search sites
final results = await repo.search('Village');

// Get unsynced records
final unsynced = await repo.getUnsynced();
```

### Bulk Operations
```dart
// Bulk insert for API sync
await repo.insertBulk(listOfSites);
```

### Sync Queue
```dart
final syncRepo = SyncQueueRepository();

// Add operation to queue
await syncRepo.addToQueue(
  tableName: 'training_sites',
  operation: 'insert',
  recordId: '123',
  data: site.toMap(),
);

// Get pending operations
final pending = await syncRepo.getPendingItems();

// Remove after successful sync
await syncRepo.removeFromQueue(queueId);
```

## Offline-First Strategy

1. All create/update/delete operations work offline
2. Records created offline get a UUID in `offline_id`
3. `s_is_sync` flag tracks sync status (0 = pending, 1 = synced)
4. Sync queue tracks operations for batch sync
5. On sync success, update `s_is_sync` and clear from queue

## Best Practices

1. Always use repositories, never query database directly
2. Use bulk operations for API data sync
3. Handle sync conflicts with server timestamps
4. Clear sensitive data on logout
5. Use transactions for related operations
6. Log all database operations for debugging

## Database Maintenance

```dart
// Get database statistics
final count = await repo.getCount();

// Clear all data (logout)
await DatabaseHelper.instance.clearAllData();

// Close database connection
await DatabaseHelper.instance.close();
```
