// SubsTrack yeni özellik — Yedekleme ve Geri Yükleme Servisi (Bölüm 11)
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';

class BackupService {
  // SubsTrack yeni özellik — JSON dışa aktarma (Bölüm 11)
  static Future<bool> export(BuildContext context) async {
    try {
      // Tüm veriyi çek
      final data = await DBService.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Dosya adını tarihe göre oluştur
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'substrack_backup_$dateStr.json';

      // Documents klasörüne kaydet
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Paylaş
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'SubsTrack Yedek Dosyası',
          text: 'SubsTrack uygulama yedeği — $dateStr',
        ),
      );

      return true;
    } catch (e) {
      debugPrint('BackupService export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedek alınırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // SubsTrack yeni özellik — JSON'dan geri yükleme (Bölüm 11)
  static Future<bool> import(BuildContext context) async {
    try {
      // Dosya seçici
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'SubsTrack Yedek Dosyası Seç',
      );

      if (result == null || result.files.isEmpty) return false;

      final filePath = result.files.first.path;
      if (filePath == null) return false;

      // Dosyayı oku
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Versiyon kontrolü
      final version = data['version'] as int? ?? 1;
      if (version > 4) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠️ Bu yedek dosyası daha yeni bir uygulama sürümüne ait.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Onay dialogu göster
      if (context.mounted) {
        final subsCount =
            (data['subscriptions'] as List<dynamic>?)?.length ?? 0;
        final invCount =
            (data['investments'] as List<dynamic>?)?.length ?? 0;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F1629),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Yedek Yükle',
                style: TextStyle(
                    color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold)),
            content: Text(
              '$subsCount abonelik ve $invCount yatırım mevcut verilere eklenecek. Devam et?',
              style: const TextStyle(
                  color: Color(0xFF8892A4), fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal',
                    style: TextStyle(color: Color(0xFF8892A4))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AF7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Yükle',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirm != true) return false;

        // Veriyi yükle
        await DBService.instance.importData(data);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ $subsCount abonelik ve $invCount yatırım yüklendi!'),
              backgroundColor: const Color(0xFF34D399),
            ),
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint('BackupService import error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedek yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return false;
  }
}
