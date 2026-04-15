import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  static const String _databaseName = 'irise.db';
  static const int _databaseVersion = 18;

  DatabaseHelper._internal();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    developer.log('Initializing database at: $path', name: 'DatabaseHelper');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating database tables...', name: 'DatabaseHelper');

    // Create training_sites table with offline_id as auto-increment primary key
    await db.execute('''
      CREATE TABLE training_sites (
        offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
        training_point_id INTEGER UNIQUE,
        is_parent TEXT DEFAULT 'no',
        m_training_point_id INTEGER,
        training_site TEXT,
        road_access TEXT DEFAULT 'no',
        village_head_name TEXT,
        gvh_name TEXT,
        district INTEGER,
        traditional_authority INTEGER,
        total_people INTEGER,
        house_holds_count INTEGER,
        cookstoves_count INTEGER,
        house_hold_radius INTEGER,
        latitude REAL,
        longitude REAL,
        s_is_sync INTEGER DEFAULT 0,
        training_status TEXT,
        conduct_training_date TEXT,
        number_of_people_present INTEGER,
        created_by TEXT,
        modified_by TEXT,
        created_date TEXT,
        modified_date TEXT,
        status TEXT DEFAULT 'active',
        server_time TEXT
      )
    ''');

    // Create beneficiaries table with offline_id as auto-increment primary key
    await db.execute('''
      CREATE TABLE beneficiaries (
        offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
        beneficiary_id INTEGER UNIQUE,
        training_site INTEGER,
        m_user_id INTEGER,
        m_site_id INTEGER,
        first_name TEXT,
        last_name TEXT,
        mobile_no TEXT,
        other_cookstove TEXT DEFAULT 'no',
        females_below_18 INTEGER,
        females_above_18 INTEGER,
        males_below_18 INTEGER,
        males_above_18 INTEGER,
        cooking_method TEXT,
        district_name TEXT,
        national_id TEXT UNIQUE,
        national_id_attachment TEXT,
        house_pic TEXT,
        cookstove_pic TEXT,
        signature TEXT,
        emp_id INTEGER,
        language TEXT DEFAULT 'english',
        read_doc TEXT DEFAULT 'no',
        understood_doc TEXT DEFAULT 'no',
        emp_sign TEXT,
        read_to_you TEXT DEFAULT 'no',
        stove_status_delivery TEXT DEFAULT 'no',
        no_other_cook_stove_present TEXT DEFAULT 'no',
        primary_residence_confirmation TEXT DEFAULT 'no',
        cookstove_pic_timestamp TEXT,
        house_pic_timestamp TEXT,
        national_id_timestamp TEXT,
        signature_timestamp TEXT,
        device_serial_no TEXT,
        latitude REAL,
        longitude REAL,
        geo_address TEXT,
        created_date TEXT,
        created_by INTEGER,
        modified_date TEXT,
        modified_by INTEGER,
        status TEXT DEFAULT 'active',
        s_is_sync INTEGER DEFAULT 0,
        server_time TEXT,
        distribution_date TEXT
      )
    ''');

    // Create trainings table
    await db.execute('''
      CREATE TABLE trainings (
        training_id INTEGER PRIMARY KEY,
        training_point_id INTEGER,
        training_date TEXT,
        trainer_name TEXT,
        participants_count INTEGER,
        males_count INTEGER,
        females_count INTEGER,
        training_type TEXT,
        training_notes TEXT,
        s_is_sync INTEGER DEFAULT 0,
        created_by TEXT,
        modified_by TEXT,
        created_date TEXT,
        modified_date TEXT,
        status TEXT DEFAULT 'active',
        offline_id INTEGER,
        server_time TEXT,
        FOREIGN KEY (training_point_id) REFERENCES training_sites (training_point_id)
      )
    ''');

    // Create sync_queue table for offline operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data TEXT NOT NULL,
        created_date TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Create districts table
    await db.execute('''
      CREATE TABLE districts (
        id INTEGER PRIMARY KEY,
        district_id INTEGER UNIQUE,
        district_name TEXT,
        slug TEXT,
        region TEXT,
        status TEXT
      )
    ''');

    // Create authorities table
    await db.execute('''
      CREATE TABLE authorities (
        id INTEGER PRIMARY KEY,
        authority_id INTEGER UNIQUE,
        authority_name TEXT,
        slug TEXT,
        district_id INTEGER,
        status TEXT
      )
    ''');

    // Create languages table
    await db.execute('''
      CREATE TABLE languages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lang_name TEXT UNIQUE NOT NULL
      )
    ''');

    // Create cookstoves table
    await db.execute('''
      CREATE TABLE cookstoves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cookstove_name TEXT UNIQUE NOT NULL
      )
    ''');

    // Create training_sites_list table (for dropdown)
    await db.execute('''
      CREATE TABLE training_sites_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        training_site TEXT UNIQUE NOT NULL
      )
    ''');

    // Create monitoring_data table with offline_id as auto-increment primary key
    await db.execute('''
      CREATE TABLE monitoring_data (
        offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
        monitoring_id INTEGER UNIQUE,
        user_id INTEGER,
        beneficiary_id INTEGER,
        national_id TEXT,
        agent_name TEXT,
        visit_at TEXT,
        old_gps_lat REAL,
        old_gps_lng REAL,
        new_gps_lat REAL,
        new_gps_lng REAL,
        device_serial_no TEXT,
        new_device_serial_no TEXT,
        hh_name_same TEXT,
        stoves_present TEXT,
        stove_being_used TEXT,
        times_used_today INTEGER,
        stove_condition TEXT,
        photo_url TEXT,
        nfc_tag_status TEXT,
        user_satisfaction TEXT,
        fuel_type TEXT,
        daily_fuel_cost INTEGER,
        savings_3_months INTEGER,
        est_fuel_last3meals_kg INTEGER,
        needs_training TEXT,
        training_type TEXT,
        training_performed TEXT,
        training_not_done_reason TEXT,
        needs_more_visits TEXT,
        more_visits_reason TEXT,
        health_hospital_less TEXT,
        health_better_air TEXT,
        photo_path TEXT,
        s_is_sync INTEGER DEFAULT 0,
        created_date TEXT DEFAULT CURRENT_TIMESTAMP,
        created_by INTEGER,
        modified_date TEXT,
        modified_by INTEGER,
        server_time TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'active'
      )
    ''');

    // Create audit table with offline_id as auto-increment primary key
    await db.execute('''
      CREATE TABLE audit (
        offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
        audit_id INTEGER UNIQUE,
        household_name TEXT,
        national_id TEXT,
        phone_number TEXT,
        visit_date TEXT,
        females_below_18 INTEGER,
        females_above_18 INTEGER,
        males_below_18 INTEGER,
        males_above_18 INTEGER,
        has_cookstove_observe TEXT,
        cooking_method_before TEXT,
        fuel_used_before TEXT,
        other_cooking_device_before TEXT,
        payment_requested TEXT,
        payment_requested_by TEXT,
        training_before_receiving TEXT,
        read_conset TEXT,
        sign_consent TEXT,
        delivered_condition TEXT,
        date_of_cookstove_recieved TEXT,
        where_received TEXT,
        where_trained TEXT,
        latitude REAL,
        longitude REAL,
        photo_path_cook_stove TEXT,
        photo_path_cook_stove_area TEXT,
        remarks TEXT,
        s_is_sync INTEGER DEFAULT 0,
        created_date TEXT DEFAULT CURRENT_TIMESTAMP,
        created_by INTEGER,
        modified_date TEXT,
        modified_by INTEGER,
        server_time TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'active'
      )
    ''');

    developer.log('Database tables created successfully',
        name: 'DatabaseHelper');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log(
      'Upgrading database from version $oldVersion to $newVersion',
      name: 'DatabaseHelper',
    );

    // Handle database migrations here
    if (oldVersion < 2) {
      // Migration from version 1 to 2: Change offline_id from TEXT to INTEGER
      developer.log('Migrating offline_id columns to INTEGER',
          name: 'DatabaseHelper');

      // For training_sites table
      await db.execute('''
        CREATE TABLE training_sites_new (
          training_point_id INTEGER PRIMARY KEY,
          is_parent TEXT DEFAULT 'no',
          m_training_point_id INTEGER,
          training_site TEXT,
          road_access TEXT DEFAULT 'no',
          village_head_name TEXT,
          gvh_name TEXT,
          district TEXT,
          traditional_authority TEXT,
          total_people INTEGER,
          house_holds_count INTEGER,
          cookstoves_count INTEGER,
          house_hold_radius INTEGER,
          latitude REAL,
          longitude REAL,
          s_is_sync INTEGER DEFAULT 0,
          training_status TEXT,
          created_by TEXT,
          modified_by TEXT,
          created_date TEXT,
          modified_date TEXT,
          status TEXT DEFAULT 'active',
          offline_id INTEGER,
          server_time TEXT
        )
      ''');

      // Copy data, converting offline_id to INTEGER
      await db.execute('''
        INSERT INTO training_sites_new 
        SELECT 
          training_point_id, is_parent, m_training_point_id, training_site, 
          road_access, village_head_name, gvh_name, district, traditional_authority,
          total_people, house_holds_count, cookstoves_count, house_hold_radius,
          latitude, longitude, s_is_sync, training_status, created_by, modified_by,
          created_date, modified_date, status,
          CASE 
            WHEN offline_id IS NULL THEN NULL
            WHEN offline_id = '' THEN NULL
            ELSE CAST(offline_id AS INTEGER)
          END as offline_id,
          server_time
        FROM training_sites
      ''');

      // Drop old table and rename new one
      await db.execute('DROP TABLE training_sites');
      await db
          .execute('ALTER TABLE training_sites_new RENAME TO training_sites');

      // Update beneficiaries table
      await db.execute('''
        CREATE TABLE beneficiaries_new (
          beneficiary_id INTEGER PRIMARY KEY,
          training_point_id INTEGER,
          first_name TEXT,
          last_name TEXT,
          gender TEXT,
          age INTEGER,
          phone_number TEXT,
          national_id TEXT,
          household_size INTEGER,
          cookstoves_received INTEGER,
          s_is_sync INTEGER DEFAULT 0,
          created_by TEXT,
          modified_by TEXT,
          created_date TEXT,
          modified_date TEXT,
          status TEXT DEFAULT 'active',
          offline_id INTEGER,
          server_time TEXT,
          FOREIGN KEY (training_point_id) REFERENCES training_sites (training_point_id)
        )
      ''');

      await db.execute('''
        INSERT INTO beneficiaries_new 
        SELECT 
          beneficiary_id, training_point_id, first_name, last_name, gender, age, 
          phone_number, national_id, household_size, cookstoves_received, s_is_sync,
          created_by, modified_by, created_date, modified_date, status,
          CASE 
            WHEN offline_id IS NULL THEN NULL
            WHEN offline_id = '' THEN NULL
            ELSE CAST(offline_id AS INTEGER)
          END as offline_id,
          server_time
        FROM beneficiaries
      ''');

      await db.execute('DROP TABLE beneficiaries');
      await db.execute('ALTER TABLE beneficiaries_new RENAME TO beneficiaries');

      // Update trainings table
      await db.execute('''
        CREATE TABLE trainings_new (
          training_id INTEGER PRIMARY KEY,
          training_point_id INTEGER,
          training_date TEXT,
          trainer_name TEXT,
          participants_count INTEGER,
          males_count INTEGER,
          females_count INTEGER,
          training_type TEXT,
          training_notes TEXT,
          s_is_sync INTEGER DEFAULT 0,
          created_by TEXT,
          modified_by TEXT,
          created_date TEXT,
          modified_date TEXT,
          status TEXT DEFAULT 'active',
          offline_id INTEGER,
          server_time TEXT,
          FOREIGN KEY (training_point_id) REFERENCES training_sites (training_point_id)
        )
      ''');

      await db.execute('''
        INSERT INTO trainings_new 
        SELECT 
          training_id, training_point_id, training_date, trainer_name, participants_count, 
          males_count, females_count, training_type, training_notes, s_is_sync,
          created_by, modified_by, created_date, modified_date, status,
          CASE 
            WHEN offline_id IS NULL THEN NULL
            WHEN offline_id = '' THEN NULL
            ELSE CAST(offline_id AS INTEGER)
          END as offline_id,
          server_time
        FROM trainings
      ''');

      await db.execute('DROP TABLE trainings');
      await db.execute('ALTER TABLE trainings_new RENAME TO trainings');

      developer.log('Database migration to version 2 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 3) {
      // Migration from version 2 to 3: Fix any remaining schema issues
      developer.log('Applying version 3 migration fixes',
          name: 'DatabaseHelper');

      // This migration will recreate tables with correct schema if needed
      // The database will be recreated cleanly
      developer.log('Database migration to version 3 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 4) {
      // Migration from version 3 to 4: Add created_by_name and modified_by_name columns
      developer.log('Adding created_by_name and modified_by_name columns',
          name: 'DatabaseHelper');

      try {
        // Add new columns to training_sites table
        await db.execute(
            'ALTER TABLE training_sites ADD COLUMN created_by_name TEXT');
        await db.execute(
            'ALTER TABLE training_sites ADD COLUMN modified_by_name TEXT');

        developer.log('Successfully added name columns to training_sites table',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error adding columns (they might already exist): $e',
            name: 'DatabaseHelper');
        // Columns might already exist, continue
      }

      developer.log('Database migration to version 4 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 5) {
      // Migration from version 4 to 5: Add districts and authorities tables
      developer.log('Adding districts and authorities tables',
          name: 'DatabaseHelper');

      try {
        // Create districts table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS districts (
            id INTEGER PRIMARY KEY,
            district_name TEXT,
            slug TEXT,
            region TEXT,
            status TEXT
          )
        ''');

        // Create authorities table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS authorities (
            id INTEGER PRIMARY KEY,
            authority_name TEXT,
            slug TEXT,
            district_id INTEGER,
            status TEXT
          )
        ''');

        developer.log('Successfully added districts and authorities tables',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error adding tables (they might already exist): $e',
            name: 'DatabaseHelper');
      }

      developer.log('Database migration to version 5 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 6) {
      // Migration from version 5 to 6: Add auto-increment id column and make training_point_id unique
      developer.log('Migrating to version 6: Adding auto-increment id column',
          name: 'DatabaseHelper');

      try {
        // Create new training_sites table with proper schema
        await db.execute('''
          CREATE TABLE training_sites_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            training_point_id INTEGER UNIQUE,
            is_parent TEXT DEFAULT 'no',
            m_training_point_id INTEGER,
            training_site TEXT,
            road_access TEXT DEFAULT 'no',
            village_head_name TEXT,
            gvh_name TEXT,
            district TEXT,
            traditional_authority TEXT,
            total_people INTEGER,
            house_holds_count INTEGER,
            cookstoves_count INTEGER,
            house_hold_radius INTEGER,
            latitude REAL,
            longitude REAL,
            s_is_sync INTEGER DEFAULT 0,
            training_status TEXT,
            created_by TEXT,
            modified_by TEXT,
            created_by_name TEXT,
            modified_by_name TEXT,
            created_date TEXT,
            modified_date TEXT,
            status TEXT DEFAULT 'active',
            offline_id INTEGER UNIQUE,
            server_time TEXT
          )
        ''');

        // Copy data from old table to new table
        // The id column will be auto-generated
        await db.execute('''
          INSERT INTO training_sites_new (
            training_point_id, is_parent, m_training_point_id, training_site,
            road_access, village_head_name, gvh_name, district, traditional_authority,
            total_people, house_holds_count, cookstoves_count, house_hold_radius,
            latitude, longitude, s_is_sync, training_status, created_by, modified_by,
            created_by_name, modified_by_name, created_date, modified_date, status,
            offline_id, server_time
          )
          SELECT 
            training_point_id, is_parent, m_training_point_id, training_site,
            road_access, village_head_name, gvh_name, district, traditional_authority,
            total_people, house_holds_count, cookstoves_count, house_hold_radius,
            latitude, longitude, s_is_sync, training_status, created_by, modified_by,
            created_by_name, modified_by_name, created_date, modified_date, status,
            offline_id, server_time
          FROM training_sites
        ''');

        // Drop old table and rename new one
        await db.execute('DROP TABLE training_sites');
        await db
            .execute('ALTER TABLE training_sites_new RENAME TO training_sites');

        developer.log('Successfully migrated training_sites table to version 6',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 6 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 6 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 7) {
      // Migration from version 6 to 7: Add conduct_training_date and number_of_people_present, remove created_by_name and modified_by_name
      developer.log('Migrating to version 7: Updating training_sites schema',
          name: 'DatabaseHelper');

      try {
        // Create new training_sites table with updated schema
        await db.execute('''
          CREATE TABLE training_sites_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            training_point_id INTEGER UNIQUE,
            is_parent TEXT DEFAULT 'no',
            m_training_point_id INTEGER,
            training_site TEXT,
            road_access TEXT DEFAULT 'no',
            village_head_name TEXT,
            gvh_name TEXT,
            district TEXT,
            traditional_authority TEXT,
            total_people INTEGER,
            house_holds_count INTEGER,
            cookstoves_count INTEGER,
            house_hold_radius INTEGER,
            latitude REAL,
            longitude REAL,
            s_is_sync INTEGER DEFAULT 0,
            training_status TEXT,
            conduct_training_date TEXT,
            number_of_people_present INTEGER,
            created_by TEXT,
            modified_by TEXT,
            created_date TEXT,
            modified_date TEXT,
            status TEXT DEFAULT 'active',
            offline_id INTEGER UNIQUE,
            server_time TEXT
          )
        ''');

        // Copy data from old table to new table (excluding created_by_name and modified_by_name)
        // await db.execute('''
        //   INSERT INTO training_sites_new (
        //     training_point_id, is_parent, m_training_point_id, training_site,
        //     road_access, village_head_name, gvh_name, district, traditional_authority,
        //     total_people, house_holds_count, cookstoves_count, house_hold_radius,
        //     latitude, longitude, s_is_sync, training_status,
        //     created_by, modified_by, created_date, modified_date, status,
        //     offline_id, server_time
        //   )
        //   SELECT
        //     training_point_id, is_parent, m_training_point_id, training_site,
        //     road_access, village_head_name, gvh_name, district, traditional_authority,
        //     total_people, house_holds_count, cookstoves_count, house_hold_radius,
        //     latitude, longitude, s_is_sync, training_status,
        //     created_by, modified_by, created_date, modified_date, status,
        //     offline_id, server_time
        //   FROM training_sites
        // ''');

        // Drop old table and rename new one
        await db.execute('DROP TABLE training_sites');
        await db
            .execute('ALTER TABLE training_sites_new RENAME TO training_sites');

        developer.log('Successfully migrated training_sites table to version 7',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 7 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 7 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 8) {
      // Migration from version 7 to 8: Update beneficiaries table with complete schema
      developer.log(
          'Migrating to version 8: Updating beneficiaries table schema',
          name: 'DatabaseHelper');

      try {
        // Create new beneficiaries table with complete schema
        await db.execute('''
          CREATE TABLE beneficiaries_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            beneficiary_id INTEGER UNIQUE,
            training_site TEXT,
            m_user_id INTEGER,
            m_site_id INTEGER,
            first_name TEXT,
            last_name TEXT,
            mobile_no TEXT,
            other_cookstove TEXT DEFAULT 'no',
            females_below_18 INTEGER,
            females_above_18 INTEGER,
            males_below_18 INTEGER,
            males_above_18 INTEGER,
            cooking_method TEXT,
            district_name TEXT,
            national_id TEXT,
            national_id_attachment TEXT,
            house_pic TEXT,
            cookstove_pic TEXT,
            signature TEXT,
            emp_id INTEGER,
            language TEXT DEFAULT 'english',
            read_doc TEXT DEFAULT 'no',
            understood_doc TEXT DEFAULT 'no',
            emp_sign TEXT,
            read_to_you TEXT DEFAULT 'no',
            stove_status_delivery TEXT DEFAULT 'no',
            no_other_cook_stove_present TEXT DEFAULT 'no',
            primary_residence_confirmation TEXT DEFAULT 'no',
            cookstove_pic_timestamp TEXT,
            house_pic_timestamp TEXT,
            national_id_timestamp TEXT,
            signature_timestamp TEXT,
            device_serial_no TEXT,
            latitude REAL,
            longitude REAL,
            geo_address TEXT,
            created_date TEXT,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            status TEXT DEFAULT 'active',
            s_is_sync INTEGER DEFAULT 0,
            offline_id INTEGER UNIQUE,
            server_time TEXT
          )
        ''');

        // Try to copy existing data if the old table exists and has compatible columns
        try {
          await db.execute('''
            INSERT INTO beneficiaries_new (
              beneficiary_id, first_name, last_name, national_id,
              created_date, created_by, modified_date, modified_by,
              status, s_is_sync, offline_id, server_time
            )
            SELECT 
              beneficiary_id, first_name, last_name, national_id,
              created_date, created_by, modified_date, modified_by,
              status, s_is_sync, offline_id, server_time
            FROM beneficiaries
          ''');
          developer.log('Copied existing beneficiary data',
              name: 'DatabaseHelper');
        } catch (e) {
          developer.log(
              'No existing beneficiary data to copy or incompatible schema: $e',
              name: 'DatabaseHelper');
        }

        // Drop old table and rename new one
        await db.execute('DROP TABLE IF EXISTS beneficiaries');
        await db
            .execute('ALTER TABLE beneficiaries_new RENAME TO beneficiaries');

        developer.log('Successfully migrated beneficiaries table to version 8',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 8 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 8 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 9) {
      // Migration from version 8 to 9: Add languages, cookstoves, and training_sites_list tables
      developer.log('Migrating to version 9: Adding lookup tables',
          name: 'DatabaseHelper');

      try {
        // Create languages table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS languages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lang_name TEXT UNIQUE NOT NULL
          )
        ''');

        // Create cookstoves table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cookstoves (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cookstove_name TEXT UNIQUE NOT NULL
          )
        ''');

        // Create training_sites_list table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS training_sites_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            training_site TEXT UNIQUE NOT NULL
          )
        ''');

        developer.log('Successfully added lookup tables for version 9',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 9 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 9 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 10) {
      // Migration from version 9 to 10: Add UNIQUE constraint to national_id
      developer.log(
          'Migrating to version 10: Adding UNIQUE constraint to national_id',
          name: 'DatabaseHelper');

      try {
        // Check for duplicate national_ids before migration
        final duplicates = await db.rawQuery('''
          SELECT national_id, COUNT(*) as count 
          FROM beneficiaries 
          WHERE national_id IS NOT NULL AND national_id != ''
          GROUP BY national_id 
          HAVING COUNT(*) > 1
        ''');

        if (duplicates.isNotEmpty) {
          developer.log(
              '⚠️ WARNING: Found ${duplicates.length} duplicate national_id values!',
              name: 'DatabaseHelper');
          for (var dup in duplicates) {
            developer.log(
                '  - National ID: ${dup['national_id']} appears ${dup['count']} times',
                name: 'DatabaseHelper');
          }

          // Keep only the first occurrence of each duplicate, delete the rest
          for (var dup in duplicates) {
            final nationalId = dup['national_id'] as String;

            // Get all records with this national_id
            final records = await db.query(
              'beneficiaries',
              where: 'national_id = ?',
              whereArgs: [nationalId],
              orderBy: 'id ASC',
            );

            if (records.length > 1) {
              // Keep the first record, delete the rest
              for (int i = 1; i < records.length; i++) {
                final recordId = records[i]['id'];
                await db.delete(
                  'beneficiaries',
                  where: 'id = ?',
                  whereArgs: [recordId],
                );
                developer.log('  - Deleted duplicate record with id: $recordId',
                    name: 'DatabaseHelper');
              }
            }
          }

          developer.log('Cleaned up duplicate national_id records',
              name: 'DatabaseHelper');
        }

        // Create new beneficiaries table with UNIQUE constraint on national_id
        await db.execute('''
          CREATE TABLE beneficiaries_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            beneficiary_id INTEGER UNIQUE,
            training_site TEXT,
            m_user_id INTEGER,
            m_site_id INTEGER,
            first_name TEXT,
            last_name TEXT,
            mobile_no TEXT,
            other_cookstove TEXT DEFAULT 'no',
            females_below_18 INTEGER,
            females_above_18 INTEGER,
            males_below_18 INTEGER,
            males_above_18 INTEGER,
            cooking_method TEXT,
            district_name TEXT,
            national_id TEXT UNIQUE,
            national_id_attachment TEXT,
            house_pic TEXT,
            cookstove_pic TEXT,
            signature TEXT,
            emp_id INTEGER,
            language TEXT DEFAULT 'english',
            read_doc TEXT DEFAULT 'no',
            understood_doc TEXT DEFAULT 'no',
            emp_sign TEXT,
            read_to_you TEXT DEFAULT 'no',
            stove_status_delivery TEXT DEFAULT 'no',
            no_other_cook_stove_present TEXT DEFAULT 'no',
            primary_residence_confirmation TEXT DEFAULT 'no',
            cookstove_pic_timestamp TEXT,
            house_pic_timestamp TEXT,
            national_id_timestamp TEXT,
            signature_timestamp TEXT,
            device_serial_no TEXT,
            latitude REAL,
            longitude REAL,
            geo_address TEXT,
            created_date TEXT,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            status TEXT DEFAULT 'active',
            s_is_sync INTEGER DEFAULT 0,
            offline_id INTEGER UNIQUE,
            server_time TEXT
          )
        ''');

        // Copy all data from old table to new table
        await db.execute('''
          INSERT INTO beneficiaries_new 
          SELECT * FROM beneficiaries
        ''');

        // Drop old table and rename new one
        await db.execute('DROP TABLE beneficiaries');
        await db
            .execute('ALTER TABLE beneficiaries_new RENAME TO beneficiaries');

        developer.log('Successfully added UNIQUE constraint to national_id',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 10 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 10 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 11) {
      // Migration from version 10 to 11: Add distribution_date column
      developer.log('Migrating to version 11: Adding distribution_date column',
          name: 'DatabaseHelper');

      try {
        // Add distribution_date column to beneficiaries table
        await db.execute(
            'ALTER TABLE beneficiaries ADD COLUMN distribution_date TEXT');

        developer.log(
            'Successfully added distribution_date column to beneficiaries table',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 11 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 11 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 12) {
      // Migration from version 11 to 12: Add monitoring_data table
      developer.log('Migrating to version 12: Adding monitoring_data table',
          name: 'DatabaseHelper');

      try {
        // Create monitoring_data table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS monitoring_data (
            monitoring_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            national_id TEXT,
            agent_name TEXT,
            visit_at TEXT,
            old_gps_lat REAL,
            old_gps_lng REAL,
            new_gps_lat REAL,
            new_gps_lng REAL,
            device_serial_no TEXT,
            new_device_serial_no TEXT,
            hh_name_same TEXT,
            stoves_present TEXT,
            stove_being_used TEXT,
            times_used_today INTEGER,
            stove_condition TEXT,
            photo_url TEXT,
            nfc_tag_status TEXT,
            user_satisfaction TEXT,
            fuel_type TEXT,
            daily_fuel_cost INTEGER,
            savings_3_months INTEGER,
            est_fuel_last3meals_kg INTEGER,
            needs_training TEXT,
            training_type TEXT,
            training_performed TEXT,
            training_not_done_reason TEXT,
            needs_more_visits TEXT,
            more_visits_reason TEXT,
            health_hospital_less TEXT,
            health_better_air TEXT,
            photo_path TEXT,
            created_date TEXT DEFAULT CURRENT_TIMESTAMP,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            server_time TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'active'
          )
        ''');

        developer.log('Successfully added monitoring_data table',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 12 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 12 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 13) {
      // Migration from version 12 to 13: Add audit table
      developer.log('Migrating to version 13: Adding audit table',
          name: 'DatabaseHelper');

      try {
        // Create audit table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS audit (
            audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
            household_name TEXT,
            national_id TEXT,
            phone_number TEXT,
            visit_date TEXT,
            females_below_18 INTEGER,
            females_above_18 INTEGER,
            males_below_18 INTEGER,
            males_above_18 INTEGER,
            has_cookstove_observe TEXT,
            cooking_method_before TEXT,
            fuel_used_before TEXT,
            other_cooking_device_before TEXT,
            payment_requested TEXT,
            payment_requested_by TEXT,
            training_before_receiving TEXT,
            read_conset TEXT,
            sign_consent TEXT,
            delivered_condition TEXT,
            date_of_cookstove_recieved TEXT,
            where_received TEXT,
            where_trained TEXT,
            latitude REAL,
            longitude REAL,
            photo_path_cook_stove TEXT,
            photo_path_cook_stove_area TEXT,
            remarks TEXT,
            s_is_sync INTEGER DEFAULT 0,
            created_date TEXT DEFAULT CURRENT_TIMESTAMP,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            server_time TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'active'
          )
        ''');

        developer.log('Successfully added audit table', name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 13 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 13 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 14) {
      // Migration from version 13 to 14: Add s_is_sync column to monitoring_data table
      developer.log(
          'Migrating to version 14: Adding s_is_sync to monitoring_data',
          name: 'DatabaseHelper');

      try {
        // Add s_is_sync column to monitoring_data table
        await db.execute(
            'ALTER TABLE monitoring_data ADD COLUMN s_is_sync INTEGER DEFAULT 0');

        developer.log(
            'Successfully added s_is_sync column to monitoring_data table',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 14 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 14 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 15) {
      // Migration from version 14 to 15: Add beneficiary_id column to monitoring_data table
      developer.log(
          'Migrating to version 15: Adding beneficiary_id to monitoring_data',
          name: 'DatabaseHelper');

      try {
        // Add beneficiary_id column to monitoring_data table
        await db.execute(
            'ALTER TABLE monitoring_data ADD COLUMN beneficiary_id INTEGER');

        developer.log(
            'Successfully added beneficiary_id column to monitoring_data table',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 15 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 15 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 16) {
      // Migration from version 15 to 16: Make offline_id the primary key for all tables
      developer.log(
          'Migrating to version 16: Making offline_id the primary key',
          name: 'DatabaseHelper');

      try {
        // ========== TRAINING_SITES TABLE ==========
        developer.log('Migrating training_sites table...',
            name: 'DatabaseHelper');

        await db.execute('DROP TABLE IF EXISTS training_sites');

        // Recreate training_sites table using the original table name
        await db.execute('''
          CREATE TABLE training_sites (
            offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
            training_point_id INTEGER UNIQUE,
            is_parent TEXT DEFAULT 'no',
            m_training_point_id INTEGER,
            training_site TEXT,
            road_access TEXT DEFAULT 'no',
            village_head_name TEXT,
            gvh_name TEXT,
            district INTEGER,
            traditional_authority INTEGER,
            total_people INTEGER,
            house_holds_count INTEGER,
            cookstoves_count INTEGER,
            house_hold_radius INTEGER,
            latitude REAL,
            longitude REAL,
            s_is_sync INTEGER DEFAULT 0,
            training_status TEXT,
            conduct_training_date TEXT,
            number_of_people_present INTEGER,
            created_by TEXT,
            modified_by TEXT,
            created_date TEXT,
            modified_date TEXT,
            status TEXT DEFAULT 'active',
            server_time TEXT
          )
        ''');

        developer.log('training_sites table migrated successfully',
            name: 'DatabaseHelper');

        // ========== BENEFICIARIES TABLE ==========
        developer.log('Migrating beneficiaries table...',
            name: 'DatabaseHelper');

        await db.execute('DROP TABLE IF EXISTS beneficiaries');

        // Recreate beneficiaries table using the original table name
        await db.execute('''
          CREATE TABLE beneficiaries (
            offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
            beneficiary_id INTEGER UNIQUE,
            training_site INTEGER,
            m_user_id INTEGER,
            m_site_id INTEGER,
            first_name TEXT,
            last_name TEXT,
            mobile_no TEXT,
            other_cookstove TEXT DEFAULT 'no',
            females_below_18 INTEGER,
            females_above_18 INTEGER,
            males_below_18 INTEGER,
            males_above_18 INTEGER,
            cooking_method TEXT,
            district_name TEXT,
            national_id TEXT UNIQUE,
            national_id_attachment TEXT,
            house_pic TEXT,
            cookstove_pic TEXT,
            signature TEXT,
            emp_id INTEGER,
            language TEXT DEFAULT 'english',
            read_doc TEXT DEFAULT 'no',
            understood_doc TEXT DEFAULT 'no',
            emp_sign TEXT,
            read_to_you TEXT DEFAULT 'no',
            stove_status_delivery TEXT DEFAULT 'no',
            no_other_cook_stove_present TEXT DEFAULT 'no',
            primary_residence_confirmation TEXT DEFAULT 'no',
            cookstove_pic_timestamp TEXT,
            house_pic_timestamp TEXT,
            national_id_timestamp TEXT,
            signature_timestamp TEXT,
            device_serial_no TEXT,
            latitude REAL,
            longitude REAL,
            geo_address TEXT,
            created_date TEXT,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            status TEXT DEFAULT 'active',
            s_is_sync INTEGER DEFAULT 0,
            server_time TEXT,
            distribution_date TEXT
          )
        ''');

        developer.log('beneficiaries table migrated successfully',
            name: 'DatabaseHelper');

        // ========== MONITORING_DATA TABLE ==========
        developer.log('Migrating monitoring_data table...',
            name: 'DatabaseHelper');

        await db.execute('DROP TABLE IF EXISTS monitoring_data');

        // Recreate monitoring_data table using the original table name
        await db.execute('''
          CREATE TABLE monitoring_data (
            offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
            monitoring_id INTEGER UNIQUE,
            user_id INTEGER,
            beneficiary_id INTEGER,
            national_id TEXT,
            agent_name TEXT,
            visit_at TEXT,
            old_gps_lat REAL,
            old_gps_lng REAL,
            new_gps_lat REAL,
            new_gps_lng REAL,
            device_serial_no TEXT,
            new_device_serial_no TEXT,
            hh_name_same TEXT,
            stoves_present TEXT,
            stove_being_used TEXT,
            times_used_today INTEGER,
            stove_condition TEXT,
            photo_url TEXT,
            nfc_tag_status TEXT,
            user_satisfaction TEXT,
            fuel_type TEXT,
            daily_fuel_cost INTEGER,
            savings_3_months INTEGER,
            est_fuel_last3meals_kg INTEGER,
            needs_training TEXT,
            training_type TEXT,
            training_performed TEXT,
            training_not_done_reason TEXT,
            needs_more_visits TEXT,
            more_visits_reason TEXT,
            health_hospital_less TEXT,
            health_better_air TEXT,
            photo_path TEXT,
            s_is_sync INTEGER DEFAULT 0,
            created_date TEXT DEFAULT CURRENT_TIMESTAMP,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            server_time TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'active'
          )
        ''');

        developer.log('monitoring_data table migrated successfully',
            name: 'DatabaseHelper');

        // ========== AUDIT TABLE ==========
        developer.log('Migrating audit table...', name: 'DatabaseHelper');

        await db.execute('DROP TABLE IF EXISTS audit');

        // Recreate audit table using the original table name
        await db.execute('''
          CREATE TABLE audit (
            offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
            audit_id INTEGER UNIQUE,
            household_name TEXT,
            national_id TEXT,
            phone_number TEXT,
            visit_date TEXT,
            females_below_18 INTEGER,
            females_above_18 INTEGER,
            males_below_18 INTEGER,
            males_above_18 INTEGER,
            has_cookstove_observe TEXT,
            cooking_method_before TEXT,
            fuel_used_before TEXT,
            other_cooking_device_before TEXT,
            payment_requested TEXT,
            payment_requested_by TEXT,
            training_before_receiving TEXT,
            read_conset TEXT,
            sign_consent TEXT,
            delivered_condition TEXT,
            date_of_cookstove_recieved TEXT,
            where_received TEXT,
            where_trained TEXT,
            latitude REAL,
            longitude REAL,
            photo_path_cook_stove TEXT,
            photo_path_cook_stove_area TEXT,
            remarks TEXT,
            s_is_sync INTEGER DEFAULT 0,
            created_date TEXT DEFAULT CURRENT_TIMESTAMP,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            server_time TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'active'
          )
        ''');

        developer.log('audit table migrated successfully',
            name: 'DatabaseHelper');

        developer.log(
            'Successfully migrated all tables to use offline_id as primary key',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 16 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }

      developer.log('Database migration to version 16 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 17) {
      // Migration from version 16 to 17: Add district_id to districts and authority_id to authorities
      developer.log(
          'Migrating to version 17: Adding district_id and authority_id columns',
          name: 'DatabaseHelper');

      try {
        await db.execute(
            'ALTER TABLE districts ADD COLUMN district_id INTEGER UNIQUE');
        developer.log('Added district_id column to districts table',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('district_id column may already exist in districts: $e',
            name: 'DatabaseHelper');
      }

      try {
        await db.execute(
            'ALTER TABLE authorities ADD COLUMN authority_id INTEGER UNIQUE');
        developer.log('Added authority_id column to authorities table',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log(
            'authority_id column may already exist in authorities: $e',
            name: 'DatabaseHelper');
      }

      developer.log('Database migration to version 17 completed',
          name: 'DatabaseHelper');
    }

    if (oldVersion < 18) {
      developer.log(
          'Migrating to version 18: Converting beneficiaries.training_site to INTEGER',
          name: 'DatabaseHelper');

      try {
        await db.execute('''
          CREATE TABLE beneficiaries_new (
            offline_id INTEGER PRIMARY KEY AUTOINCREMENT,
            beneficiary_id INTEGER UNIQUE,
            training_site INTEGER,
            m_user_id INTEGER,
            m_site_id INTEGER,
            first_name TEXT,
            last_name TEXT,
            mobile_no TEXT,
            other_cookstove TEXT DEFAULT 'no',
            females_below_18 INTEGER,
            females_above_18 INTEGER,
            males_below_18 INTEGER,
            males_above_18 INTEGER,
            cooking_method TEXT,
            district_name TEXT,
            national_id TEXT UNIQUE,
            national_id_attachment TEXT,
            house_pic TEXT,
            cookstove_pic TEXT,
            signature TEXT,
            emp_id INTEGER,
            language TEXT DEFAULT 'english',
            read_doc TEXT DEFAULT 'no',
            understood_doc TEXT DEFAULT 'no',
            emp_sign TEXT,
            read_to_you TEXT DEFAULT 'no',
            stove_status_delivery TEXT DEFAULT 'no',
            no_other_cook_stove_present TEXT DEFAULT 'no',
            primary_residence_confirmation TEXT DEFAULT 'no',
            cookstove_pic_timestamp TEXT,
            house_pic_timestamp TEXT,
            national_id_timestamp TEXT,
            signature_timestamp TEXT,
            device_serial_no TEXT,
            latitude REAL,
            longitude REAL,
            geo_address TEXT,
            created_date TEXT,
            created_by INTEGER,
            modified_date TEXT,
            modified_by INTEGER,
            status TEXT DEFAULT 'active',
            s_is_sync INTEGER DEFAULT 0,
            server_time TEXT,
            distribution_date TEXT
          )
        ''');

        await db.execute('''
          INSERT INTO beneficiaries_new (
            offline_id, beneficiary_id, training_site, m_user_id, m_site_id,
            first_name, last_name, mobile_no, other_cookstove,
            females_below_18, females_above_18, males_below_18, males_above_18,
            cooking_method, district_name, national_id, national_id_attachment,
            house_pic, cookstove_pic, signature, emp_id, language, read_doc,
            understood_doc, emp_sign, read_to_you, stove_status_delivery,
            no_other_cook_stove_present, primary_residence_confirmation,
            cookstove_pic_timestamp, house_pic_timestamp, national_id_timestamp,
            signature_timestamp, device_serial_no, latitude, longitude,
            geo_address, created_date, created_by, modified_date, modified_by,
            status, s_is_sync, server_time, distribution_date
          )
          SELECT
            b.offline_id,
            b.beneficiary_id,
            CASE
              WHEN b.training_site IS NULL OR b.training_site = '' THEN NULL
              WHEN b.training_site GLOB '[0-9]*' THEN CAST(b.training_site AS INTEGER)
              ELSE (
                SELECT COALESCE(ts.training_point_id, ts.offline_id)
                FROM training_sites ts
                WHERE ts.training_site = b.training_site
                LIMIT 1
              )
            END,
            b.m_user_id,
            b.m_site_id,
            b.first_name,
            b.last_name,
            b.mobile_no,
            b.other_cookstove,
            b.females_below_18,
            b.females_above_18,
            b.males_below_18,
            b.males_above_18,
            b.cooking_method,
            b.district_name,
            b.national_id,
            b.national_id_attachment,
            b.house_pic,
            b.cookstove_pic,
            b.signature,
            b.emp_id,
            b.language,
            b.read_doc,
            b.understood_doc,
            b.emp_sign,
            b.read_to_you,
            b.stove_status_delivery,
            b.no_other_cook_stove_present,
            b.primary_residence_confirmation,
            b.cookstove_pic_timestamp,
            b.house_pic_timestamp,
            b.national_id_timestamp,
            b.signature_timestamp,
            b.device_serial_no,
            b.latitude,
            b.longitude,
            b.geo_address,
            b.created_date,
            b.created_by,
            b.modified_date,
            b.modified_by,
            b.status,
            b.s_is_sync,
            b.server_time,
            b.distribution_date
          FROM beneficiaries b
        ''');

        await db.execute('DROP TABLE beneficiaries');
        await db
            .execute('ALTER TABLE beneficiaries_new RENAME TO beneficiaries');

        developer.log('Database migration to version 18 completed',
            name: 'DatabaseHelper');
      } catch (e) {
        developer.log('Error during version 18 migration: $e',
            name: 'DatabaseHelper');
        rethrow;
      }
    }
  }

  // Clear all data (useful for logout or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('training_sites');
    await db.delete('beneficiaries');
    await db.delete('trainings');
    await db.delete('sync_queue');
    await db.delete('districts');
    await db.delete('authorities');
    developer.log('All data cleared from database', name: 'DatabaseHelper');
  }

  // Reset database completely (delete and recreate)
  Future<void> resetDatabase() async {
    try {
      // Close current database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete the database file
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, _databaseName);
      await deleteDatabase(path);

      developer.log('Database file deleted and will be recreated',
          name: 'DatabaseHelper');

      // The database will be recreated on next access
    } catch (e) {
      developer.log('Error resetting database: $e', name: 'DatabaseHelper');
      rethrow;
    }
  }

  // Clear only training sites table
  Future<void> clearTrainingSites() async {
    final db = await database;
    await db.delete('training_sites');
    developer.log('Training sites table cleared', name: 'DatabaseHelper');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Get database size
  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM training_sites) as training_sites_count,
        (SELECT COUNT(*) FROM beneficiaries) as beneficiaries_count,
        (SELECT COUNT(*) FROM trainings) as trainings_count,
        (SELECT COUNT(*) FROM sync_queue) as sync_queue_count
    ''');
    return result.length;
  }
}
