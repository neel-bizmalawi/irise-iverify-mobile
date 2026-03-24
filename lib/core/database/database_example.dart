// Example usage of the database layer
// This file demonstrates how to use repositories and models

import 'package:irise/data/models/training_site.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/data/models/training.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/repositories/training_repository.dart';
import 'package:irise/data/services/sync_service.dart';

class DatabaseExamples {
  final _trainingSiteRepo = TrainingSiteRepository();
  final _beneficiaryRepo = BeneficiaryRepository();
  final _trainingRepo = TrainingRepository();
  final _syncService = SyncService();

  // Example 1: Create and save a training site
  Future<void> createTrainingSite() async {
    final site = TrainingSite(
      trainingSite: 'Village Community Center',
      district: 'Lilongwe',
      traditionalAuthority: 'Chief Malili',
      gvhName: 'GVH Banda',
      villageHeadName: 'John Phiri',
      latitude: -13.9626,
      longitude: 33.7741,
      roadAccess: 'yes',
      totalPeople: 500,
      houseHoldsCount: 100,
      cookstovesCount: 80,
      status: 'active',
      createdBy: 'user123',
      createdDate: DateTime.now().toIso8601String(),
    );

    final id = await _trainingSiteRepo.insert(site);
    print('Created training site with ID: $id');
  }

  // Example 2: Query training sites
  Future<void> queryTrainingSites() async {
    // Get all active sites
    final activeSites = await _trainingSiteRepo.getActive();
    print('Found ${activeSites.length} active sites');

    // Search for sites
    final searchResults = await _trainingSiteRepo.search('Lilongwe');
    print('Search found ${searchResults.length} sites');

    // Get unsynced sites
    final unsyncedSites = await _trainingSiteRepo.getUnsynced();
    print('${unsyncedSites.length} sites need syncing');
  }

  // Example 3: Create beneficiary
  Future<void> createBeneficiary(int trainingPointId) async {
    final beneficiary = Beneficiary(
      trainingPointId: trainingPointId,
      firstName: 'Mary',
      lastName: 'Banda',
      gender: 'female',
      age: 35,
      phoneNumber: '+265991234567',
      nationalId: 'MWI123456789',
      householdSize: 6,
      cookstovesReceived: 2,
      status: 'active',
      createdBy: 'user123',
      createdDate: DateTime.now().toIso8601String(),
    );

    final id = await _beneficiaryRepo.insert(beneficiary);
    print('Created beneficiary with ID: $id');
  }

  // Example 4: Get beneficiaries for a training site
  Future<void> getBeneficiariesForSite(int trainingPointId) async {
    final beneficiaries = await _beneficiaryRepo.getByTrainingSite(trainingPointId);
    print('Found ${beneficiaries.length} beneficiaries for site $trainingPointId');

    for (var beneficiary in beneficiaries) {
      print('${beneficiary.fullName} - ${beneficiary.phoneNumber}');
    }
  }

  // Example 5: Create training record
  Future<void> createTraining(int trainingPointId) async {
    final training = Training(
      trainingPointId: trainingPointId,
      trainingDate: DateTime.now().toIso8601String(),
      trainerName: 'Joseph Mwale',
      participantsCount: 45,
      malesCount: 20,
      femalesCount: 25,
      trainingType: 'Cookstove Installation',
      trainingNotes: 'Successful training session with high engagement',
      status: 'active',
      createdBy: 'user123',
      createdDate: DateTime.now().toIso8601String(),
    );

    final id = await _trainingRepo.insert(training);
    print('Created training record with ID: $id');
  }

  // Example 6: Sync data
  Future<void> syncData() async {
    // Sync from server
    print('Syncing from server...');
    final fromServerResult = await _syncService.syncFromServer();
    if (fromServerResult.success) {
      print('Downloaded ${fromServerResult.trainingSitesCount} sites');
      print('Downloaded ${fromServerResult.beneficiariesCount} beneficiaries');
      print('Downloaded ${fromServerResult.trainingsCount} trainings');
    }

    // Sync to server
    print('Syncing to server...');
    final toServerResult = await _syncService.syncToServer();
    if (toServerResult.success) {
      print('Uploaded ${toServerResult.syncedToServerCount} records');
    }

    // Check sync status
    final status = await _syncService.getSyncStatus();
    print('Pending operations: ${status.pendingOperations}');
    print('Unsynced sites: ${status.unsyncedSites}');
    print('Total unsynced: ${status.totalUnsynced}');
  }

  // Example 7: Bulk operations
  Future<void> bulkOperations() async {
    // Create multiple sites
    final sites = List.generate(
      10,
      (i) => TrainingSite(
        trainingSite: 'Site ${i + 1}',
        district: 'District ${(i % 3) + 1}',
        status: 'active',
        createdDate: DateTime.now().toIso8601String(),
      ),
    );

    await _trainingSiteRepo.insertBulk(sites);
    print('Bulk inserted ${sites.length} sites');
  }

  // Example 8: Update and delete
  Future<void> updateAndDelete() async {
    // Get a site
    final site = await _trainingSiteRepo.getById(1);
    if (site != null) {
      // Update it
      final updatedSite = site.copyWith(
        trainingSite: 'Updated Site Name',
        modifiedBy: 'user123',
        modifiedDate: DateTime.now().toIso8601String(),
      );
      await _trainingSiteRepo.update(updatedSite);
      print('Updated site');

      // Soft delete (mark as inactive)
      await _trainingSiteRepo.softDelete(1);
      print('Soft deleted site');
    }
  }
}
