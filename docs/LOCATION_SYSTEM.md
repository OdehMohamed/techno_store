# Location Data System

## 📂 البنية (Clean Architecture)

```
techno_store/
├── assets/
│   └── data/
│       └── locations.json          # بيانات المواقع (JSON)
├── lib/
│   └── core/
│       ├── models/
│       │   └── location_data.dart  # Model للبيانات
│       └── services/
│           └── location_service.dart # Service للتعامل مع البيانات
```

## 🎯 المميزات

✅ **Clean Code** - فصل البيانات عن المنطق
✅ **Singleton Pattern** - instance واحدة من الـ Service  
✅ **Caching** - تحميل البيانات مرة واحدة فقط
✅ **Type Safety** - استخدام Models مع Type Checking
✅ **Easy Maintenance** - تعديل البيانات من JSON مباشرة
✅ **Scalable** - سهولة إضافة دول/محافظات/مدن جديدة

## 📝 كيفية الاستخدام

### 1. إضافة دولة جديدة في `locations.json`:

```json
{
  "name": "الأردن",
  "name_en": "Jordan",
  "states": [
    {
      "name": "عمان",
      "name_en": "Amman",
      "cities": ["عمان", "الزرقاء", "إربد"]
    }
  ]
}
```

### 2. استخدام الـ Service:

```dart
// تحميل البيانات (مرة واحدة فقط)
await LocationService.instance.loadLocations();

// الحصول على البلدان
List<String> countries = LocationService.instance.getCountries();

// الحصول على المحافظات لبلد معين
List<String> states = LocationService.instance.getStates('فلسطين');

// الحصول على المدن لمحافظة معينة
List<String> cities = LocationService.instance.getCities('فلسطين', 'القدس');
```

## 🗂️ البيانات الحالية

### فلسطين 🇵🇸

- **16 محافظة** (القدس، الخليل، بيت لحم، رام الله والبيرة، نابلس، جنين، طولكرم، قلقيلية، سلفيت، أريحا والأغوار، طوباس، غزة، خان يونس، رفح، دير البلح، شمال غزة)
- **100+ مدينة وبلدة**

## 🔄 التحديثات المستقبلية

يمكن بسهولة إضافة:

- دول عربية أخرى
- المزيد من المحافظات والمدن
- بيانات إضافية (رموز بريدية، إحداثيات، إلخ)
- دعم لغات متعددة

## 🧹 مبادئ Clean Code المُطبقة

1. **Single Responsibility** - كل class له مسؤولية واحدة
2. **Separation of Concerns** - فصل البيانات عن UI
3. **DRY** - لا تكرار في الكود
4. **Singleton Pattern** - instance واحدة من الـ Service
5. **Error Handling** - معالجة الأخطاء بشكل صحيح
6. **Null Safety** - استخدام Null Safety
