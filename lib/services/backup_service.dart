import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class BackupService {
  static const String _backupFileName = 'shop_manager_backup.db';

  Future<String> get _backupPath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, _backupFileName);
  }

  Future<bool> createBackup() async {
    try {
      final dbPath = await DatabaseService.instance.databasePath;
      final backupPath = await _backupPath;

      // Copy the database file
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreBackup() async {
    try {
      final dbPath = await DatabaseService.instance.databasePath;
      final backupPath = await _backupPath;

      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return false;
      }

      // Close the current database
      await DatabaseService.instance.close();

      // Copy the backup file to the database location
      await backupFile.copy(dbPath);

      // Reinitialize the database service
      await DatabaseService.instance.initialize();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> backupExists() async {
    try {
      final backupPath = await _backupPath;
      final backupFile = File(backupPath);
      return await backupFile.exists();
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getBackupDate() async {
    try {
      final backupPath = await _backupPath;
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        return await backupFile.lastModified();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
