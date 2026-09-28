# سياسة الخصوصية — سكانر المستندات (CamScannerAll)

**آخر تحديث:** 2026-09-28

هذا التطبيق **مجاني بالكامل**، ومصمم من الأساس بدون أي خادم (Backend) خاص
بنا، وبدون حساب مستخدم، وبدون رفع أي من بياناتك لأي مكان، وبدون أي اتصال
بالإنترنت لأي غرض. هذه الصفحة تشرح بالتفصيل ماذا يحدث لبياناتك بالضبط.

## 1. البيانات التي لا نجمعها إطلاقاً

المطوّر **لا يملك أي خادم**، وبالتالي لا نستطيع ولا نقوم بجمع أو
استقبال أو تخزين أي من التالي:

- صور أو ملفات المستندات التي تمسحها
- النص المستخرج من مستنداتك (OCR)
- اسمك أو بريدك الإلكتروني أو أي معرّف شخصي آخر
- موقعك الجغرافي

كل هذه البيانات تبقى **على جهازك فقط**، داخل مساحة التخزين الخاصة بالتطبيق
(App Sandbox) التي لا يمكن لأي تطبيق آخر الوصول إليها.

## 2. أين تُخزَّن بياناتك فعلياً

| نوع البيانات | مكان التخزين |
|---|---|
| صور الصفحات الممسوحة | مجلد خاص بالتطبيق داخل جهازك (`scans/`) |
| بيانات المجلدات والمستندات والفهرسة | قاعدة بيانات محلية (Hive) على جهازك |

## 3. استخراج النص (OCR)

يستخدم التطبيق مكتبة **Google ML Kit** للتعرف على النص، وتعمل بالكامل
**على جهازك (on-device)**. الصور لا تُرسَل لأي خادم لمعالجتها.

## 4. الأذونات التي يطلبها التطبيق ولماذا

| الإذن | لماذا نحتاجه |
|---|---|
| الكاميرا | لمسح المستندات فقط — لا تصوير أو تسجيل لأي غرض آخر |
| الوصول لملف عند الاستيراد | لقراءة الملف الذي تختاره أنت يدوياً (مستند PDF أو صورة تستورده) |

## 5. المشاركة مع أطراف ثالثة

**لا نشارك أي بيانات مع أي طرف ثالث**، لأننا أصلاً لا نملك أي بيانات نشاركها.
الاستثناء الوحيد هو ما تفعله أنت بنفسك: إذا اخترت مشاركة مستند عبر واتساب
أو البريد أو أي تطبيق آخر من داخل التطبيق، فهذا إجراء تتحكم فيه أنت
بالكامل (نافذة المشاركة القياسية لنظام التشغيل)، وليس التطبيق من يرسله.

كذلك زر "حفظ بالمعرض": هذا إجراء اختياري بالكامل لا يحدث أبداً تلقائياً؛
فقط عند ضغطك عليه صراحة، تُنسخ صور المستند لمعرض الصور العام بجهازك. بعد
هذه اللحظة تصبح هذه النسخة صورة عادية يمكن لتطبيقاتك الأخرى (مثل تطبيقات
النسخ الاحتياطي للصور) الوصول لها، تماماً كأي صورة تلتقطها بكاميرا
هاتفك — النسخة الأصلية داخل مساحة التطبيق الخاصة تبقى محمية كما هي.

## 6. حذف بياناتك

بما أن كل بياناتك محلية على جهازك فقط:

- حذف مستند أو مجلد من داخل التطبيق يحذفه نهائياً من جهازك
- حذف التطبيق نفسه من جهازك يحذف كل بياناته معه بالكامل
- لا توجد نسخة "على السيرفر" تبقى بعد الحذف، لأنه لا يوجد سيرفر أصلاً

**تنبيه:** فقدان جهازك، إعادة ضبطه للمصنع، أو حذف التطبيق منه يعني
**فقدان دائم لبياناتك** — لا توجد أي نسخة أخرى منها بأي مكان (لا على
جهازك ولا على أي سيرفر)، وهذا مقصود لحماية خصوصيتك الكاملة. التطبيق لا
يوفّر حالياً ميزة نسخ احتياطي — إذا كان عندك مستندات مهمة، احتفظ بنسخة
منها بطريقتك الخاصة (مشاركتها لنفسك، حفظها بمعرض الصور، إلخ).

## 7. خصوصية الأطفال

هذا التطبيق غير موجّه للأطفال دون سن 13 عاماً، ولا يجمع بياناتهم عمداً (ولا
بيانات أي أحد أصلاً، كما هو موضح أعلاه).

## 8. التواصل معنا

لأي استفسار حول هذه السياسة، يمكن التواصل عبر:
**ahmed.alabdan2@gmail.com**

---

# Privacy Policy — Document Scanner (CamScannerAll) [English]

**Last updated:** 2026-09-28

This app is **completely free**, and built from the ground up with no
backend server of our own, no user account, no upload of your data
anywhere, and no internet connection for any purpose. This page explains
exactly what happens to your data.

## 1. Data we never collect

We (the developer) do not operate any server, so we cannot and do not
collect, receive, or store any of the following:

- Your scanned document images or files
- OCR-extracted text from your documents
- Your name, email, or any other personal identifier
- Your geographic location

All of this stays **on your device only**, inside the app's private
sandbox storage, which no other app can access.

## 2. Where your data actually lives

| Data | Where it's stored |
|---|---|
| Scanned page images | A private folder inside the app on your device (`scans/`) |
| Folder/document metadata & index | A local database (Hive) on your device |

## 3. Text recognition (OCR)

The app uses **Google ML Kit** for text recognition, running entirely
**on-device**. Images are never sent to any server for processing.

## 4. Permissions requested and why

| Permission | Why we need it |
|---|---|
| Camera | Only to scan documents — never for any other recording |
| File access on import | To read a file you manually choose (a PDF or image you import) |

## 5. Third-party sharing

**We share no data with any third party**, because we don't hold any data
to share in the first place. The one exception is your own action: if you
choose to share a document via WhatsApp, email, or another app from within
the app, that's the OS's standard share sheet, fully under your control —
not something the app sends on its own.

The same applies to the "Save to gallery" button: this is entirely
optional and never happens automatically; only when you explicitly tap it
are the document's images copied into your device's public photo gallery.
From that moment, that copy is an ordinary photo your other apps (like a
photo backup app) can access, just like any picture taken with your
camera — the original inside the app's private storage stays protected as
before.

## 6. Deleting your data

Since all your data is local to your device only:

- Deleting a document or folder in the app deletes it permanently from your device
- Uninstalling the app deletes all its data with it
- There is no "server copy" left behind, because there is no server

**Note:** losing your device, factory-resetting it, or uninstalling the app
means **permanent data loss** — no other copy exists anywhere (not on your
device, not on any server), and this is intentional, to protect your
complete privacy. The app does not currently offer a backup feature — if
you have documents worth keeping, save a copy yourself however you prefer
(share it to yourself, save it to your photo gallery, etc.).

## 7. Children's privacy

This app is not directed at children under 13 and does not knowingly
collect their data (or anyone's data, as explained above).

## 8. Contact us

For any question about this policy, contact:
**ahmed.alabdan2@gmail.com**
