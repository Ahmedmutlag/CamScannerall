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
    'scanSubtitle': {'ar': 'مستند جديد بالكاميرا', 'en': 'New document with camera'},
    'importFile': {'ar': 'استيراد ملف', 'en': 'Import file'},
    'importFileSubtitle': {'ar': 'PDF أو صورة موجودة', 'en': 'An existing PDF or image'},

    // Print documents (section 2) — deliberately not persisted; see printDocsResetConfirm.
    'printDocuments': {'ar': 'طباعة المستمسكات', 'en': 'Print Documents'},
    'printOrSavePdf': {'ar': 'طباعة / حفظ PDF', 'en': 'Print / Save PDF'},
    'startNew': {'ar': 'بدء جديد', 'en': 'Start new'},
    'printDocsResetConfirm': {
      'ar': 'هذا يحذف كل الصور المضافة بالجلسة الحالية نهائياً. هذا القسم مؤقت بالتصميم — لا يحفظ مستندات الزبائن بعد الطباعة.',
      'en': 'This permanently deletes every image added in this session. This section is temporary by design — it never keeps a customer\'s documents after printing.',
    },
    'addPerson': {'ar': 'إضافة فرد', 'en': 'Add person'},
    'person': {'ar': 'الشخص', 'en': 'Person'},
    'maxPeopleReached': {'ar': 'الحد الأقصى 4 أفراد', 'en': 'Maximum of 4 people'},
    'nationalIdFront': {'ar': 'البطاقة الوطنية', 'en': 'National ID'},
    'nationalIdFrontSubtitle': {'ar': 'الوجه الأمامي', 'en': 'Front side'},
    'nationalIdBack': {'ar': 'البطاقة الوطنية', 'en': 'National ID'},
    'nationalIdBackSubtitle': {'ar': 'الوجه الخلفي', 'en': 'Back side'},
    'housingCardFront': {'ar': 'بطاقة السكن', 'en': 'Housing Card'},
    'housingCardFrontSubtitle': {'ar': 'الوجه الأمامي', 'en': 'Front side'},
    'housingCardBack': {'ar': 'بطاقة السكن', 'en': 'Housing Card'},
    'housingCardBackSubtitle': {'ar': 'الوجه الخلفي', 'en': 'Back side'},
    'foodRationCard': {'ar': 'البطاقة التموينية', 'en': 'Food Ration Card'},
    'foodRationCardSubtitle': {'ar': 'إضافة المستند', 'en': 'Add the document'},
    'passport': {'ar': 'جواز السفر', 'en': 'Passport'},
    'passportSubtitle': {'ar': 'صفحة البيانات', 'en': 'Data page'},
    'drivingLicense': {'ar': 'رخصة القيادة', 'en': 'Driving License'},
    'drivingLicenseSubtitle': {'ar': 'إضافة المستند', 'en': 'Add the document'},
    'noDocumentsToPrint': {'ar': 'أضف مستنداً واحداً على الأقل قبل الطباعة', 'en': 'Add at least one document before printing'},
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
    'cropPage': {'ar': 'قص الصفحة', 'en': 'Crop page'},
    'rotatePage': {'ar': 'تدوير الصفحة', 'en': 'Rotate page'},
    'duplicatePage': {'ar': 'تكرار الصفحة', 'en': 'Duplicate page'},
    'mergeToOnePdf': {'ar': 'دمج بملف واحد', 'en': 'Merge into one file'},
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
    'viewMode': {'ar': 'وضع العرض الافتراضي', 'en': 'Default view mode'},
    'grid': {'ar': 'شبكي', 'en': 'Grid'},
    'list': {'ar': 'قائمة', 'en': 'List'},
    'language': {'ar': 'اللغة', 'en': 'Language'},
    'storage': {'ar': 'التخزين', 'en': 'Storage'},
    'cleanUpFiles': {'ar': 'تنظيف الملفات القديمة', 'en': 'Clean up old files'},
    'cleanUpFilesTitle': {'ar': 'تنظيف الملفات القديمة؟', 'en': 'Clean up old files?'},
    'cleanUpFilesBody': {
      'ar': 'يحذف أي صورة غير مرتبطة بأي مستند محفوظ حالياً — عادة ملفات متراكمة من عمليات حذف سابقة. تنبيه: إذا كان عندك جلسة غير محفوظة بقسم "طباعة المستمسكات" حالياً، أنهها أو أعد ضبطها أولاً حتى لا تفقد صورها بالخطأ.',
      'en': 'Removes any image not linked to a currently saved document — usually leftovers from earlier deletes. Warning: if you have an unsaved session in Print Documents right now, finish or reset it first so its images aren\'t removed by mistake.',
    },
    'filesRemoved': {'ar': 'ملف تم حذفه', 'en': 'files removed'},
    'noFilesToClean': {'ar': 'لا توجد ملفات قديمة للتنظيف', 'en': 'No old files to clean up'},

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
    'viewExisting': {'ar': 'عرض المستند الموجود', 'en': 'View existing document'},
    'clearSearch': {'ar': 'مسح البحث', 'en': 'Clear search'},
    'importFace2': {'ar': 'تصوير الوجه الثاني؟', 'en': 'Scan the back side?'},
    'importFace2Body': {
      'ar': 'يبدو أنك تصور بطاقة أو هوية. هل تريد تصوير الوجه الثاني الآن؟',
      'en': 'This looks like an ID card. Do you want to scan the back side now?',
    },
    'yes': {'ar': 'نعم', 'en': 'Yes'},
    'no': {'ar': 'لا', 'en': 'No'},
    'ok': {'ar': 'موافق', 'en': 'OK'},
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},

    // Error dialogs / messages
    'scannerErrorTitle': {'ar': 'تعذر تشغيل الماسح', 'en': 'Scanner unavailable'},
    'scannerErrorPermission': {
      'ar': 'يحتاج التطبيق إذن الكاميرا لمسح المستندات — فعّله من إعدادات الجهاز ثم أعد المحاولة.',
      'en': 'The app needs camera permission to scan documents — enable it in device settings, then try again.',
    },
    'scannerErrorGeneric': {
      'ar': 'تعذر تشغيل الماسح الضوئي على هذا الجهاز — أعد المحاولة، وإن تكرر الخطأ جرّب إعادة تشغيل الجهاز.',
      'en': 'Could not start the scanner on this device — try again, and if it keeps happening, try restarting your device.',
    },
    'genericErrorTitle': {'ar': 'حدث خطأ', 'en': 'Something went wrong'},
    'imageProcessingError': {
      'ar': 'تعذّر معالجة الصورة. حاول مرة أخرى.',
      'en': 'Could not process the image. Please try again.',
    },
    'pdfBuildError': {
      'ar': 'تعذّر إنشاء ملف PDF. حاول مرة أخرى.',
      'en': 'Could not build the PDF. Please try again.',
    },
    'operationFailedGeneric': {
      'ar': 'تعذّر إتمام العملية. حاول مرة أخرى.',
      'en': 'Could not complete the operation. Please try again.',
    },
    'ocrExtractError': {
      'ar': 'تعذّر استخراج النص من الصفحات.',
      'en': 'Could not extract text from the pages.',
    },

    // Delete confirmations
    'deleteDocumentTitle': {'ar': 'حذف المستند؟', 'en': 'Delete document?'},
    'deleteDocumentBody': {
      'ar': 'سيُحذف هذا المستند وكل صفحاته نهائياً ولا يمكن التراجع عن هذا الإجراء.',
      'en': 'This document and all its pages will be permanently deleted. This cannot be undone.',
    },
    'deletePageTitle': {'ar': 'حذف الصفحة؟', 'en': 'Delete page?'},
    'deletePageBody': {
      'ar': 'ستُحذف هذه الصفحة نهائياً ولا يمكن التراجع عن هذا الإجراء.',
      'en': 'This page will be permanently deleted. This cannot be undone.',
    },
    'deleteDocumentsTitle': {'ar': 'حذف المستندات المحددة؟', 'en': 'Delete selected documents?'},
    'deleteDocumentsBody': {
      'ar': 'ستُحذف المستندات المحددة نهائياً ولا يمكن التراجع عن هذا الإجراء.',
      'en': 'The selected documents will be permanently deleted. This cannot be undone.',
    },
    'deleteFoldersTitle': {'ar': 'حذف المجلدات المحددة؟', 'en': 'Delete selected folders?'},
    'deleteFoldersBody': {
      'ar': 'سيُحذف كل مجلد محدد وجميع المستندات بداخله نهائياً ولا يمكن التراجع عن هذا الإجراء.',
      'en': 'Each selected folder and all documents inside it will be permanently deleted. This cannot be undone.',
    },

    // Exit-with-unsaved-data warning (Print Documents section)
    'exitWithUnsavedTitle': {'ar': 'صور غير محفوظة', 'en': 'Unsaved scans'},
    'exitWithUnsavedBody': {
      'ar': 'لديك مستندات مصوّرة بقسم "طباعة المستمسكات" لم تُحفظ بعد. الخروج الآن سيحذفها نهائياً، لأن هذا القسم لا يحفظ أي بيانات تلقائياً.',
      'en': "You have scanned documents in Print Documents that haven't been saved yet. Exiting now will permanently delete them, since this section never saves data automatically.",
    },
    'exitAnyway': {'ar': 'خروج على أي حال', 'en': 'Exit anyway'},

    'deletePersonTitle': {'ar': 'حذف هذا الشخص؟', 'en': 'Remove this person?'},
    'deletePersonBody': {
      'ar': 'سيُحذف كل ما تم تصويره لهذا الشخص نهائياً ولا يمكن التراجع عن هذا الإجراء.',
      'en': 'Everything scanned for this person will be permanently deleted. This cannot be undone.',
    },
  };

  String t(String key) => _table[key]?[languageCode] ?? _table[key]?['en'] ?? key;
}
