/// Lightweight bundled string table for Arabic (default) and English.
/// The app is Arabic-first with full RTL support; English is a secondary
/// option toggled from Settings.
class AppStrings {
  AppStrings(this.languageCode);

  final String languageCode;

  static const Map<String, Map<String, String>> _table = {
    'appName': {'ar': 'سكانر المستندات', 'en': 'Doc Scanner'},

    // Home
    'home': {'ar': 'الرئيسية', 'en': 'Home'},
    'files': {'ar': 'الملفات', 'en': 'Files'},
    'recent': {'ar': 'الأخيرة', 'en': 'Recent'},
    'noRecent': {'ar': 'ابدأ بمسح أول مستند لك', 'en': 'Start by scanning your first document'},
    'scan': {'ar': 'مسح ضوئي', 'en': 'Scan'},
    'importFile': {'ar': 'استيراد ملف', 'en': 'Import file'},
    'view': {'ar': 'عرض', 'en': 'View'},
    'wordShort': {'ar': 'Word', 'en': 'Word'},

    // Folders / files
    'folders': {'ar': 'المجلدات', 'en': 'Folders'},
    'newFolder': {'ar': 'مجلد جديد', 'en': 'New Folder'},
    'folderName': {'ar': 'اسم المجلد', 'en': 'Folder name'},
    'create': {'ar': 'إنشاء', 'en': 'Create'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'save': {'ar': 'حفظ', 'en': 'Save'},
    'delete': {'ar': 'حذف', 'en': 'Delete'},
    'rename': {'ar': 'إعادة تسمية', 'en': 'Rename'},
    'move': {'ar': 'نقل', 'en': 'Move'},
    'copy': {'ar': 'نسخ', 'en': 'Copy'},
    'merge': {'ar': 'دمج', 'en': 'Merge'},
    'search': {'ar': 'بحث بالاسم أو النص...', 'en': 'Search name or text...'},
    'documents': {'ar': 'المستندات', 'en': 'Documents'},
    'noDocuments': {'ar': 'ابدأ بمسح أول مستند بهذا المجلد', 'en': 'Start by scanning your first document here'},
    'noFolders': {'ar': 'ابدأ بإنشاء أول مجلد لأرشفة مستنداتك', 'en': 'Start by creating your first folder'},
    'noSearchResults': {'ar': 'لا نتائج مطابقة', 'en': 'No matching results'},
    'addDocument': {'ar': 'إضافة مستند', 'en': 'Add Document'},

    // Camera / scan review
    'camera': {'ar': 'الكاميرا', 'en': 'Camera'},
    'retake': {'ar': 'إعادة التصوير', 'en': 'Retake'},
    'done': {'ar': 'تم', 'en': 'Done'},
    'addAnotherPage': {'ar': 'إضافة صفحة أخرى', 'en': 'Add another page'},
    'filterOriginal': {'ar': 'أصلي', 'en': 'Original'},
    'filterBW': {'ar': 'أبيض وأسود', 'en': 'B & W'},
    'filterColor': {'ar': 'ألوان', 'en': 'Color'},
    'filterAuto': {'ar': 'تلقائي', 'en': 'Auto'},

    // Document detail
    'documentDetails': {'ar': 'تفاصيل المستند', 'en': 'Document Details'},
    'share': {'ar': 'مشاركة', 'en': 'Share'},
    'print': {'ar': 'طباعة', 'en': 'Print'},
    'extractText': {'ar': 'استخراج النص', 'en': 'Extract Text'},
    'convertFormat': {'ar': 'تحويل الصيغة', 'en': 'Convert Format'},
    'splitPdf': {'ar': 'تقسيم PDF', 'en': 'Split PDF'},
    'compressPdf': {'ar': 'ضغط PDF', 'en': 'Compress PDF'},
    'pdfToImages': {'ar': 'PDF إلى صور', 'en': 'PDF to Images'},
    'toWord': {'ar': 'استخراج النص كملف Word', 'en': 'Extract text as Word file'},
    'toWordNote': {
      'ar': 'سيُنشأ ملف Word يحتوي على النص المستخرج بالـ OCR فقط، وليس نسخة طبق الأصل من تصميم الصفحة الأصلية.',
      'en': 'This creates a Word file with the OCR-extracted text only — not a pixel-perfect copy of the original page layout.',
    },
    'extractedText': {'ar': 'النص المستخرج', 'en': 'Extracted Text'},
    'copyText': {'ar': 'نسخ النص', 'en': 'Copy Text'},
    'textCopied': {'ar': 'تم نسخ النص', 'en': 'Text copied'},
    'saveToGallery': {'ar': 'حفظ بالمعرض', 'en': 'Save to gallery'},
    'savedToGallery': {'ar': 'تم الحفظ بمعرض الصور', 'en': 'Saved to your photo gallery'},
    'saveToGalleryError': {'ar': 'تعذّر الحفظ بالمعرض', 'en': 'Could not save to gallery'},
    'qualityHigh': {'ar': 'جودة عالية', 'en': 'High quality'},
    'qualityLight': {'ar': 'جودة خفيفة', 'en': 'Light quality'},

    // Settings
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
    'security': {'ar': 'الأمان', 'en': 'Security'},
    'changePin': {'ar': 'تغيير رمز القفل', 'en': 'Change PIN'},
    'enableBiometric': {'ar': 'تفعيل بصمة/وجه', 'en': 'Enable biometric'},
    'autoLockMinutes': {'ar': 'القفل التلقائي بعد (دقائق)', 'en': 'Auto-lock after (minutes)'},
    'backup': {'ar': 'النسخ الاحتياطي', 'en': 'Backup'},
    'createBackup': {'ar': 'إنشاء نسخة احتياطية', 'en': 'Create backup'},
    'restoreBackup': {'ar': 'استرجاع من نسخة احتياطية', 'en': 'Restore from backup'},
    'lastBackup': {'ar': 'آخر نسخة احتياطية', 'en': 'Last backup'},
    'never': {'ar': 'لم تتم بعد', 'en': 'Never'},
    'viewMode': {'ar': 'وضع العرض الافتراضي', 'en': 'Default view mode'},
    'grid': {'ar': 'شبكي', 'en': 'Grid'},
    'list': {'ar': 'قائمة', 'en': 'List'},
    'language': {'ar': 'اللغة', 'en': 'Language'},
    'autoBackup': {'ar': 'النسخ الاحتياطي التلقائي', 'en': 'Automatic backup'},
    'autoBackupFolder': {'ar': 'مجلد النسخ التلقائي', 'en': 'Auto-backup folder'},
    'autoBackupNotSet': {'ar': 'غير مُفعَّل', 'en': 'Not set up'},
    'chooseFolder': {'ar': 'اختيار مجلد', 'en': 'Choose folder'},
    'autoBackupExplain': {
      'ar': 'عند تحديد مجلد، ينشئ التطبيق نسخة احتياطية بصمت كل 60 يوماً بداخله تلقائياً، مشفّرة بمفتاح داخلي خاص بجهازك (بدون كلمة سر). ملاحظة مهمة: هذه النسخة تُستخدم فقط لاسترجاع بياناتك على نفس الجهاز — إن فقدت الجهاز فهي لا تُفتح من جهاز آخر. للنسخة القابلة للنقل بين الأجهزة استخدم "إنشاء نسخة احتياطية" بالأعلى.',
      'en': 'Once a folder is set, the app silently creates a backup inside it every 60 days, encrypted with a device-only internal key (no password). Important: this backup can only restore data on this same device — it cannot be opened on another device if you lose this one. For a portable backup, use "Create backup" above.',
    },
    'autoBackupWriteError': {
      'ar': 'تعذّر الكتابة بهذا المجلد. جرّب اختيار مجلد آخر (مثل مجلد التنزيلات).',
      'en': 'Could not write to this folder. Try choosing a different one (e.g. Downloads).',
    },

    // Lock
    'setPin': {'ar': 'تحديد رمز القفل', 'en': 'Set a lock PIN'},
    'enterPin': {'ar': 'أدخل رمز القفل', 'en': 'Enter PIN'},
    'confirmPin': {'ar': 'تأكيد رمز القفل', 'en': 'Confirm PIN'},
    'wrongPin': {'ar': 'رمز غير صحيح', 'en': 'Wrong PIN'},
    'pinMismatch': {'ar': 'الرمزان غير متطابقين', 'en': 'PINs do not match'},
    'unlockWithBiometric': {'ar': 'فتح بالبصمة', 'en': 'Unlock with biometric'},

    // Privacy / backup dialogs
    'privacyWarningTitle': {'ar': 'تنبيه هام حول الخصوصية', 'en': 'Important privacy notice'},
    'privacyWarningBody': {
      'ar':
          'كل بياناتك تُخزَّن على جهازك فقط ولا تُرفع لأي سيرفر. فقدان الجهاز أو نسيان رمز القفل بدون نسخة احتياطية يعني فقدان دائم لبياناتك. يُنصح بإنشاء نسخة احتياطية دورية من الإعدادات.',
      'en':
          'All your data is stored only on your device and never uploaded to any server. Losing your device or forgetting your PIN without a backup means permanent data loss. Please create backups regularly from Settings.',
    },
    'understood': {'ar': 'فهمت', 'en': 'Understood'},
    'backupPasswordHint': {'ar': 'كلمة سر النسخة الاحتياطية', 'en': 'Backup password'},
    'backupCreated': {'ar': 'تم إنشاء النسخة الاحتياطية بنجاح', 'en': 'Backup created successfully'},
    'backupReminderBody': {
      'ar': 'مر وقت طويل منذ آخر نسخة احتياطية. يُنصح بإنشاء واحدة جديدة من الإعدادات.',
      'en': "It's been a while since your last backup. Consider creating a new one from Settings.",
    },
    'restoreSuccess': {'ar': 'تم الاسترجاع بنجاح', 'en': 'Restored successfully'},
    'wrongPassword': {'ar': 'كلمة السر غير صحيحة أو الملف تالف', 'en': 'Wrong password or corrupted file'},

    // Selection / batch actions
    'selectMode': {'ar': 'تحديد', 'en': 'Select'},
    'selected': {'ar': 'محدد', 'en': 'selected'},
    'export': {'ar': 'تصدير', 'en': 'Export'},
    'exportIndex': {'ar': 'تصدير فهرس نصي', 'en': 'Export text index'},

    // Duplicate detection / ID back-side prompt
    'duplicateFound': {'ar': 'تم العثور على مستند مشابه', 'en': 'A similar document was found'},
    'duplicateBody': {
      'ar': 'يبدو أن هذا المستند مطابق لمحتوى مستند آخر موجود بنفس المجلد.',
      'en': 'This document appears to match the content of another document in the same folder.',
    },
    'importFace2': {'ar': 'تصوير الوجه الثاني؟', 'en': 'Scan the back side?'},
    'importFace2Body': {
      'ar': 'يبدو أنك تصور بطاقة أو هوية. هل تريد تصوير الوجه الثاني الآن؟',
      'en': 'This looks like an ID card. Do you want to scan the back side now?',
    },
    'yes': {'ar': 'نعم', 'en': 'Yes'},
    'no': {'ar': 'لا', 'en': 'No'},
    'ok': {'ar': 'موافق', 'en': 'OK'},
  };

  String t(String key) => _table[key]?[languageCode] ?? _table[key]?['en'] ?? key;
}
