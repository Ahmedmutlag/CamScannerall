# سياسة الخصوصية — سكانر المستندات (CamScannerAll)

**آخر تحديث:** 2026-09-12

هذا التطبيق مصمم من الأساس بدون أي خادم (Backend) خاص بنا، وبدون حساب
مستخدم، وبدون رفع أي من بياناتك لأي مكان. هذه الصفحة تشرح بالتفصيل ماذا
يحدث لبياناتك بالضبط.

## 1. البيانات التي لا نجمعها إطلاقاً

المطوّر **لا يملك أي خادم**، وبالتالي لا نستطيع ولا نقوم بجمع أو
استقبال أو تخزين أي من التالي:

- صور أو ملفات المستندات التي تمسحها
- النص المستخرج من مستنداتك (OCR)
- رمز القفل (PIN) أو بيانات البصمة/الوجه
- ملفات النسخ الاحتياطي أو كلمة سرها
- اسمك أو بريدك الإلكتروني أو أي معرّف شخصي آخر
- موقعك الجغرافي

كل هذه البيانات تبقى **على جهازك فقط**، داخل مساحة التخزين الخاصة بالتطبيق
(App Sandbox) التي لا يمكن لأي تطبيق آخر الوصول إليها.

## 2. أين تُخزَّن بياناتك فعلياً

| نوع البيانات | مكان التخزين |
|---|---|
| صور الصفحات الممسوحة | مجلد خاص بالتطبيق داخل جهازك (`scans/`) |
| بيانات المجلدات والمستندات والفهرسة | قاعدة بيانات محلية (Hive) على جهازك |
| رمز القفل (PIN) | مُشفَّر (hash) ومخزَّن محلياً؛ لا يُخزَّن كنص صريح |
| بصمة الإصبع / الوجه | تُدار بالكامل عبر نظام التشغيل (Android/iOS)، ولا يصل التطبيق لبيانات البصمة نفسها إطلاقاً — فقط نتيجة "نجح/فشل" |
| ملفات النسخ الاحتياطي | تُنشأ محلياً، مشفّرة بكلمة سر تحددها أنت، وتُحفظ حيث تختار أنت (تخزينك الشخصي بغوغل درايف، إيميلك، فلاش ميموري...) — التطبيق لا يرفعها لأي مكان بنفسه |

## 3. استخراج النص (OCR)

يستخدم التطبيق مكتبة **Google ML Kit** للتعرف على النص، وتعمل بالكامل
**على جهازك (on-device)**. الصور لا تُرسَل لأي خادم لمعالجتها.

## 4. الشراء داخل التطبيق (استثناء الشبكة الوحيد)

المكان الوحيد الذي يتصل فيه التطبيق بالإنترنت هو عملية الشراء نفسها، عبر
**Google Play Billing** مباشرة. هذا يعني:

- عند الشراء، جوجل (وليس نحن) يتولى معالجة الدفع والتحقق منه
- نحن لا نرى ولا نخزّن بيانات بطاقتك أو دفعتك إطلاقاً
- تخضع هذه العملية لسياسة خصوصية جوجل بلاي الخاصة بها

## 5. الأذونات التي يطلبها التطبيق ولماذا

| الإذن | لماذا نحتاجه |
|---|---|
| الكاميرا | لمسح المستندات فقط — لا تصوير أو تسجيل لأي غرض آخر |
| الإشعارات | تذكير دوري محلي بعمل نسخة احتياطية (لا يحتوي أي بيانات شخصية) |
| البصمة/التعرف على الوجه (اختياري) | فتح قفل التطبيق فقط، إن فعّلته أنت بنفسه من الإعدادات |
| الوصول لملف عند الاسترجاع | لقراءة ملف النسخة الاحتياطية الذي تختاره أنت يدوياً |

## 6. المشاركة مع أطراف ثالثة

**لا نشارك أي بيانات مع أي طرف ثالث**، لأننا أصلاً لا نملك أي بيانات نشاركها.
الاستثناء الوحيد هو ما تفعله أنت بنفسك: إذا اخترت مشاركة مستند عبر واتساب
أو البريد أو أي تطبيق آخر من داخل التطبيق، فهذا إجراء تتحكم فيه أنت
بالكامل (نافذة المشاركة القياسية لنظام التشغيل)، وليس التطبيق من يرسله.

كذلك زر "حفظ بالمعرض": هذا إجراء اختياري بالكامل لا يحدث أبداً تلقائياً؛
فقط عند ضغطك عليه صراحة، تُنسخ صور المستند لمعرض الصور العام بجهازك. بعد
هذه اللحظة تصبح هذه النسخة صورة عادية يمكن لتطبيقاتك الأخرى (مثل تطبيقات
النسخ الاحتياطي للصور) الوصول لها، تماماً كأي صورة تلتقطها بكاميرا
هاتفك — النسخة الأصلية داخل مساحة التطبيق الخاصة تبقى محمية كما هي.

## 7. حذف بياناتك

بما أن كل بياناتك محلية على جهازك فقط:

- حذف مستند أو مجلد من داخل التطبيق يحذفه نهائياً من جهازك
- حذف التطبيق نفسه من جهازك يحذف كل بياناته معه بالكامل
- لا توجد نسخة "على السيرفر" تبقى بعد الحذف، لأنه لا يوجد سيرفر أصلاً

**تنبيه:** فقدان جهازك أو حذف التطبيق بدون عمل نسخة احتياطية يدوية مسبقاً
يعني **فقدان دائم لبياناتك** — هذا مقصود لحماية خصوصيتك الكاملة، ولا يمكننا
استرجاعها لك لأننا لا نملك نسخة منها أصلاً.

## 8. خصوصية الأطفال

هذا التطبيق غير موجّه للأطفال دون سن 13 عاماً، ولا يجمع بياناتهم عمداً (ولا
بيانات أي أحد أصلاً، كما هو موضح أعلاه).

## 9. التواصل معنا

لأي استفسار حول هذه السياسة، يمكن التواصل عبر:
**ahmed.alabdan2@gmail.com**

---

# Privacy Policy — Document Scanner (CamScannerAll) [English]

**Last updated:** 2026-09-12

This app is built from the ground up with no backend server of our own, no
user account, and no upload of your data anywhere. This page explains
exactly what happens to your data.

## 1. Data we never collect

We (the developer) do not operate any server, so we cannot and do not
collect, receive, or store any of the following:

- Your scanned document images or files
- OCR-extracted text from your documents
- Your lock PIN or biometric data
- Your backup files or their password
- Your name, email, or any other personal identifier
- Your geographic location

All of this stays **on your device only**, inside the app's private
sandbox storage, which no other app can access.

## 2. Where your data actually lives

| Data | Where it's stored |
|---|---|
| Scanned page images | A private folder inside the app on your device (`scans/`) |
| Folder/document metadata & index | A local database (Hive) on your device |
| Lock PIN | Stored locally as a salted hash, never as plain text |
| Fingerprint / Face data | Handled entirely by your OS (Android/iOS); the app never receives the biometric data itself, only a pass/fail result |
| Backup files | Generated locally, encrypted with a password you choose, and saved wherever you pick (your personal Google Drive, email, USB drive...) — the app never uploads them itself |

## 3. Text recognition (OCR)

The app uses **Google ML Kit** for text recognition, running entirely
**on-device**. Images are never sent to any server for processing.

## 4. In-app purchase (the one network exception)

The only place this app talks to the internet is the purchase flow itself,
via **Google Play Billing** directly:

- Google (not us) handles and verifies the payment
- We never see or store your card or payment details
- This flow is covered by Google Play's own privacy policy

## 5. Permissions requested and why

| Permission | Why we need it |
|---|---|
| Camera | Only to scan documents — never for any other recording |
| Notifications | A local, periodic reminder to back up your data (contains no personal information) |
| Biometrics (optional) | Only to unlock the app, if you enable it yourself in Settings |
| File access on restore | To read the backup file you manually choose |

## 6. Third-party sharing

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

## 7. Deleting your data

Since all your data is local to your device only:

- Deleting a document or folder in the app deletes it permanently from your device
- Uninstalling the app deletes all its data with it
- There is no "server copy" left behind, because there is no server

**Note:** losing your device or deleting the app without having made a
manual backup first means **permanent data loss** — this is intentional,
to protect your complete privacy, and we cannot recover it for you since we
never held a copy.

## 8. Children's privacy

This app is not directed at children under 13 and does not knowingly
collect their data (or anyone's data, as explained above).

## 9. Contact us

For any question about this policy, contact:
**ahmed.alabdan2@gmail.com**
