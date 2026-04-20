# Photo4K iPhone App (SwiftUI)

تطبيق كاميرا للآيفون يدعم تصوير الصور والفيديو بدقة 4K باستخدام `AVFoundation`.

## المميزات المنفذة
- معاينة مباشرة للكاميرا داخل SwiftUI.
- تشغيل إعداد 4K عبر `sessionPreset = .hd4K3840x2160`.
- تصوير صور عالية الجودة وحفظها في ألبوم الصور.
- تسجيل فيديو وحفظه في ألبوم الصور.
- التبديل بين الكاميرا الأمامية والخلفية.
- تشغيل/إيقاف الفلاش للصور.
- تكبير (Zoom) عبر حركة القرص (Pinch).
- تحديد نقطة التركيز/التعريض باللمس.

## الملفات
- `App/Photo4KApp.swift`: نقطة دخول التطبيق.
- `App/ContentView.swift`: واجهة المستخدم وأزرار التحكم.
- `App/Camera/CameraPreview.swift`: جسر عرض كاميرا UIKit إلى SwiftUI.
- `App/Camera/CameraManager.swift`: إدارة `AVCaptureSession` والالتقاط/التسجيل.
- `App/Camera/CameraViewModel.swift`: منطق العرض وربط الواجهة مع المدير.

## خطوات التشغيل في Xcode
1. أنشئ مشروع iOS (App) جديد في Xcode باستخدام SwiftUI.
2. استبدل ملفات المشروع بالملفات الموجودة هنا.
3. أضف صلاحيات الخصوصية في `Info.plist`:
   - `NSCameraUsageDescription`
   - `NSMicrophoneUsageDescription`
   - `NSPhotoLibraryAddUsageDescription`
4. شغّل التطبيق على جهاز iPhone حقيقي (المحاكي لا يوفّر كاميرا كاملة).

## ملاحظات
- تفعيل 4K يعتمد على دعم الجهاز والكاميرا الحالية.
- بعض الأجهزة قد لا تدعم 4K على الكاميرا الأمامية.
