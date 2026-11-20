// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get aboutTitle => 'من نحن؟';

  @override
  String get aboutHeroTitle => 'نخدم معًا';

  @override
  String get aboutHeroBody => 'مجتمع ملتزم بخدمة طوبى والطريقة المريدية.';

  @override
  String get aboutMissionTitle => 'رسالتنا';

  @override
  String get aboutMissionBody =>
      'يجمع أهل الخدمة من يرغبون في تسخير وقتهم ومهاراتهم ومواردهم لخدمة المجتمع. ونستند إلى العلم والعمل والتضامن لتنفيذ مشاريع نافعة ومستدامة.';

  @override
  String get aboutPillarsTitle => 'من الخدمة إلى العمل';

  @override
  String get aboutMobilize => 'حشد الطاقات';

  @override
  String get aboutMobilizeBody => 'جمع الراغبين في المساهمة في خدمة المجتمع.';

  @override
  String get aboutOrganize => 'التنظيم';

  @override
  String get aboutOrganizeBody => 'تنسيق المهارات والمبادرات.';

  @override
  String get aboutFund => 'التمويل';

  @override
  String get aboutFundBody => 'توفير الموارد اللازمة لتنفيذ المشاريع.';

  @override
  String get aboutImpact => 'الأثر المستدام';

  @override
  String get aboutImpactBody => 'دعم الأعمال النافعة للمجتمع.';

  @override
  String get aboutContacts => 'تواصل معنا';

  @override
  String get aboutLocation => 'طوبى، السنغال';

  @override
  String get aboutEmail => 'البريد الإلكتروني';

  @override
  String get aboutReadOfficial => 'اقرأ التعريف الرسمي';

  @override
  String get aboutWhatsApp => 'تواصل عبر واتساب';

  @override
  String get cardDetails => 'تفاصيل البطاقة';

  @override
  String get contributionsLabel => 'الاشتراكات';

  @override
  String get mediaLabel => 'المكتبة الإعلامية';

  @override
  String get assalamuAlaykum => 'السلام عليكم';

  @override
  String get welcomeTitle => 'مرحبًا بكم في أهل الخدمة';

  @override
  String get shopSubtitle => 'متجر أهل الخدمة التضامني';

  @override
  String get shopAll => 'كل المنتجات';

  @override
  String get loginTitle => 'مساحة الأعضاء';

  @override
  String get loginSubtitle => 'سجلوا دخولكم برقم هاتفكم ورمز PIN.';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneHint => '77 123 45 67';

  @override
  String get pinLabel => 'رمز PIN (٤ أرقام)';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get invalidCredentials =>
      'بيانات الدخول غير صحيحة. تحققوا من رقمكم ورمزكم.';

  @override
  String tooManyAttempts(int minutes) {
    return 'محاولات كثيرة. حاولوا بعد $minutes دقيقة.';
  }

  @override
  String get networkError =>
      'تعذّر الاتصال. تحققوا من الشبكة وأعيدوا المحاولة.';

  @override
  String get genericError => 'حدث خطأ. بياناتكم في أمان.';

  @override
  String get sessionExpired => 'انتهت الجلسة، سجلوا دخولكم من جديد.';

  @override
  String get pinSetupTitle => 'أنشئوا رمز PIN الخاص بكم';

  @override
  String get pinSetupBody =>
      'عند أول دخول، اختاروا ٤ أرقام لا يعرفها غيركم. لا تشاركوها مع أحد، حتى مع مسؤول.';

  @override
  String get newPinLabel => 'الرمز الجديد';

  @override
  String get confirmPinLabel => 'أكدوا الرمز';

  @override
  String get pinMismatch => 'الرمزان غير متطابقين.';

  @override
  String get pinSave => 'حفظ والمتابعة';

  @override
  String homeGreeting(String name) {
    return 'السلام عليكم، $name';
  }

  @override
  String get heroTitle => 'معاً نخدم المريدية';

  @override
  String get heroSubtitle => 'الإيمان · الانضباط · العلم · التميز';

  @override
  String dueCardTitle(String month) {
    return 'اشتراك $month';
  }

  @override
  String get statusUpToDate => 'مسدَّد';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusDue => 'مستحق';

  @override
  String get actionPay => 'ادفع اشتراكي';

  @override
  String get actionCard => 'بطاقة العضوية';

  @override
  String get actionContribute => 'مساهمة';

  @override
  String get actionBarkelu => 'Barkelu';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get versementsTitle => 'مدفوعاتي';

  @override
  String get noVersements => 'لا توجد مدفوعات بعد';

  @override
  String get noVersementsBody =>
      'لا توجد دفعات متاحة لهذا الحساب في التطبيق. يمكنك الاطلاع على سجل الدفعات الكامل على الموقع.';

  @override
  String get paidLabel => 'مسدَّد';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get memberActive => 'عضو نشط';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get appearanceLabel => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get langSystem => 'حسب النظام';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String versionLabel(String v) {
    return 'الإصدار $v';
  }

  @override
  String get barkeluSoonBody =>
      'متجر Barkelu يجهّز أولى منتجاته. عودوا قريباً.';

  @override
  String get maintenanceTitle => 'الصيانة جارية';

  @override
  String get maintenanceBody => 'ستعود الخدمة خلال دقائق. شكراً لصبركم.';

  @override
  String get retryButton => 'أعيدوا المحاولة';

  @override
  String get updateRequiredTitle => 'تحديث ضروري';

  @override
  String get updateRequiredBody =>
      'لم يعد هذا الإصدار من التطبيق مدعوماً. حدّثوه للمتابعة.';

  @override
  String get updateButton => 'تحديث';

  @override
  String get offlineTitle => 'أنتم غير متصلين بالإنترنت';

  @override
  String get offlineBody => 'اتصلوا بالإنترنت للمتابعة.';

  @override
  String get unknownScreenTitle => 'هذا القسم يتطلب تحديثاً';

  @override
  String get unknownScreenBody => 'حدّثوا التطبيق للوصول إليه.';

  @override
  String get loginRequiredTitle => 'تسجيل الدخول مطلوب';

  @override
  String get loginRequiredBody => 'سجلوا دخولكم للوصول إلى هذا القسم.';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get firstLoginLink => 'أول مرة تسجلون الدخول؟';

  @override
  String get firstLoginLabel => 'آخر ٤ أحرف من رقم عضويتكم';

  @override
  String get firstLoginHelp =>
      'تجدونها على بطاقة العضوية وفي رسالة واتساب المستلمة عند الانضمام.';

  @override
  String get havePinLink => 'لدي رمز PIN';

  @override
  String get firstLoginContinue => 'متابعة';

  @override
  String get payTitle => 'دفع الاشتراك';

  @override
  String get payChooseIntro =>
      'اختاروا عدد الأشهر المراد دفعها. تُدفع الأشهر الأحدث أولاً.';

  @override
  String get payMonthsMinus => 'إنقاص شهر';

  @override
  String get payMonthsPlus => 'إضافة شهر';

  @override
  String get payMonthsLabel => 'عدد الأشهر';

  @override
  String get payMonthLate => 'متأخر';

  @override
  String get payMonthCurrent => 'الشهر الحالي';

  @override
  String get payTotalLabel => 'المجموع';

  @override
  String get payContinue => 'متابعة';

  @override
  String get payMethodTitle => 'وسيلة الدفع';

  @override
  String get payMethodWave => 'Wave';

  @override
  String get payMethodWaveSub => 'تأكيد عبر تطبيق Wave';

  @override
  String get payMethodOrange => 'Orange Money';

  @override
  String get payMethodOrangeSub => 'تأكيد عبر تطبيق Orange';

  @override
  String get payMethodCard => 'بطاقة بنكية';

  @override
  String get payMethodCardSub => 'صفحة دفع آمنة';

  @override
  String get payPhoneLabel => 'الرقم المراد الخصم منه';

  @override
  String get payPhoneRequired => 'أدخلوا الرقم المراد الخصم منه.';

  @override
  String payWithMethod(String method) {
    return 'ادفع عبر $method';
  }

  @override
  String get payWaitingTitle => 'في انتظار التأكيد';

  @override
  String payWaitingBody(String method) {
    return 'أكدوا الدفع في $method. لا تغلقوا التطبيق: ننتظر التأكيد.';
  }

  @override
  String get payNotYetPaidTitle => 'لم يتم الدفع بعد';

  @override
  String get payNotYetPaidBody => 'لن يُسجَّل اشتراككم إلا بعد تأكيد الدفع.';

  @override
  String get payReopenButton => 'فتح مرة أخرى';

  @override
  String get payChangeMethod => 'تغيير وسيلة الدفع';

  @override
  String get payDoneTitle => 'تم تأكيد الدفع';

  @override
  String payDoneBody(String months, String amount) {
    return 'شكراً. تم تسجيل اشتراككم ($months): $amount.';
  }

  @override
  String get payReceipt => 'عرض إيصالي';

  @override
  String get payFinish => 'إنهاء';

  @override
  String get payFailedTitle => 'لم يكتمل الدفع';

  @override
  String get payFailedBody => 'تم إلغاء الدفع أو رفضه. لم يُسجَّل أي مبلغ.';

  @override
  String get payRetry => 'أعيدوا المحاولة';

  @override
  String get payTimeoutTitle => 'لم يصل التأكيد بعد';

  @override
  String get payTimeoutBody =>
      'إذا دفعتم، فقد يستغرق التأكيد بضع دقائق. سيتم تحديث اشتراككم فور وصوله.';

  @override
  String get payCheckNow => 'تحقق الآن';

  @override
  String get payCheckLater => 'تحقق لاحقاً';

  @override
  String get payUnavailableTitle => 'الدفع غير متاح';

  @override
  String get payUnavailableBody =>
      'الدفع عبر الإنترنت غير متاح حالياً. حاولوا لاحقاً.';

  @override
  String get payUpToDateTitle => 'اشتراككم مسدَّد';

  @override
  String get payUpToDateBody => 'لا يوجد اشتراك للدفع حالياً.';

  @override
  String get payOpenFailed =>
      'تعذّر فتح تطبيق الدفع. اختاروا البطاقة البنكية أو أعيدوا المحاولة.';

  @override
  String get payChangeMonths => 'تعديل عدد الأشهر';

  @override
  String get cardTitle => 'بطاقة العضوية';

  @override
  String get cardHint => 'اعرضوا رمز QR للتحقق من بطاقتكم.';

  @override
  String get cardShare => 'مشاركة';

  @override
  String get cardShareFailed => 'تعذّرت المشاركة. أعيدوا المحاولة.';

  @override
  String cardStaleBanner(String date) {
    return 'غير متصل: النسخة المحفوظة بتاريخ $date.';
  }

  @override
  String get cardUnavailableTitle => 'البطاقة غير متاحة';

  @override
  String get cardUnavailableBody => 'بطاقتكم غير متاحة حالياً.';

  @override
  String get cardLoadFailedBody =>
      'تعذّر تحميل البطاقة. تحققوا من الشبكة وأعيدوا المحاولة.';

  @override
  String cardImageLabel(String name) {
    return 'بطاقة العضوية الخاصة بـ $name';
  }

  @override
  String get joinTitle => 'الانضمام عضواً';

  @override
  String get joinIntro =>
      'انضموا إلى أهل الخدمة ببضع نقرات: الاسم والهاتف والبلد والمبلغ، ثم الدفع أونلاين.';

  @override
  String get joinIdentityTitle => 'تعرّفوا على أنفسكم';

  @override
  String get joinAmountTitle => 'اختيار المبلغ';

  @override
  String get joinAmountSubtitle => 'الاشتراك الشهري';

  @override
  String get joinNotMemberYet => 'تصبحون أعضاء فقط بعد تأكيد الدفع.';

  @override
  String get joinSubmit => 'انضم';

  @override
  String get joinNotYetPaidBody => 'سيُسجَّل انضمامكم فقط عند تأكيد الدفع.';

  @override
  String get joinEditInfo => 'تعديل معلوماتي';

  @override
  String get joinDoneTitle => 'تم تأكيد الدفع';

  @override
  String joinDoneBody(String amount) {
    return 'شكراً، تم تسجيل انضمامكم ($amount). تُرسل بطاقة العضوية إلى واتساب على الرقم المذكور.';
  }

  @override
  String get joinDoneLogin =>
      'بعد ذلك، سجلوا دخولكم إلى التطبيق: «أول مرة تسجلون الدخول؟» تطلب آخر ٤ أحرف من رقم بطاقتكم.';

  @override
  String get joinDuplicate =>
      'هذا الرقم مسجَّل من قبل. سجلوا دخولكم بحساب العضوية.';

  @override
  String get joinHaveAccount => 'عضو بالفعل؟ تسجيل الدخول';

  @override
  String get joinLink => 'لستم أعضاء بعد؟ انضموا';

  @override
  String get fieldLastName => 'الاسم العائلي';

  @override
  String get fieldFirstNames => 'الاسم الشخصي';

  @override
  String get fieldPhoneWhatsapp => 'الهاتف / واتساب';

  @override
  String get fieldDial => 'رمز الاتصال';

  @override
  String get fieldPhoneFull => 'الرقم كاملاً مع رمز الدولة';

  @override
  String get fieldCountryRegion => 'البلد أو المنطقة';

  @override
  String get fieldCountryRegionHint => 'مثال: السنغال، فرنسا، طوبى، داكار…';

  @override
  String get fieldEmailOptional => 'البريد (اختياري)';

  @override
  String get fieldAmountOther => 'المبلغ بالفرنك الأفريقي';

  @override
  String get amountPerMonth => 'شهرياً';

  @override
  String get amountOther => 'مبلغ آخر';

  @override
  String get errRequired => 'هذا الحقل مطلوب.';

  @override
  String get errTooShort => 'حرفان على الأقل.';

  @override
  String get errPhoneShort => 'الرقم ناقص.';

  @override
  String get errPhoneLong => 'الرقم أطول من المطلوب.';

  @override
  String get errPhoneSenegal =>
      'رقم سنغالي غير صحيح: 9 أرقام تبدأ بـ 70 أو 75 أو 76 أو 77 أو 78.';

  @override
  String get errEmail => 'بريد إلكتروني غير صحيح.';

  @override
  String errAmountMin(String amount) {
    return 'الحد الأدنى للمبلغ: $amount.';
  }

  @override
  String get errAmountMissing => 'حدّدوا المبلغ.';

  @override
  String get errServerInvalid => 'بعض المعلومات غير مقبولة. راجعوا الاستمارة.';

  @override
  String get donateIdentityTitle => 'بياناتكم';

  @override
  String get donateIdentitySubtitle => 'اختياري إن بقيتم مجهولين';

  @override
  String get donateAnonymous => 'أرغب في البقاء مجهولاً';

  @override
  String get donateMemberNote =>
      'إن ذكرتم هاتفكم، قد تُنشأ لكم بطاقة عضوية (دون اشتراك شهري) انطلاقاً من مساهمتكم.';

  @override
  String get donateAmountTitle => 'المبلغ';

  @override
  String get donateCampaign => 'الوجهة';

  @override
  String get campaignGeneral => 'دعم عام';

  @override
  String get campaignTouba => 'مشاريع في طوبى';

  @override
  String get campaignMagal => 'Magal / المناسبات الكبرى';

  @override
  String get campaignEducation => 'التعليم والكفاءات';

  @override
  String get campaignOther => 'أخرى';

  @override
  String get donateMessage => 'رسالة (اختياري)';

  @override
  String get donateMessageHint => 'نية أو إهداء أو كلمة للفريق.';

  @override
  String get donateSubmit => 'المتابعة إلى الدفع';

  @override
  String get donateNotYetPaidBody => 'ستُسجَّل مساهمتكم فقط عند تأكيد الدفع.';

  @override
  String get donateDoneTitle => 'شكراً لدعمكم';

  @override
  String donateDoneBody(String amount) {
    return 'تم تأكيد مساهمتكم بمبلغ $amount.';
  }

  @override
  String get donateEditInfo => 'تعديل مساهمتي';

  @override
  String get publicTimeoutBody =>
      'إن كنتم قد دفعتم، فقد يستغرق التأكيد بضع دقائق. لا يُسجَّل شيء قبل وصوله.';

  @override
  String get waveManualTitle => 'تم تسجيل الانضمام، والدفع ما زال مطلوباً';

  @override
  String waveManualBody(String amount, String number, String reference) {
    return 'الدفع أونلاين غير متاح. أرسلوا $amount عبر Wave إلى الرقم $number مع ذكر المرجع $reference.';
  }

  @override
  String get waveManualNotPaid => 'لم يصل دفعكم بعد: هذا الانضمام غير مدفوع.';

  @override
  String get homeJoin => 'الانضمام عضواً';

  @override
  String get homeContribute => 'تبرّع';

  @override
  String get officialPageError => 'تعذّر فتح الرابط. حاول مجددًا.';

  @override
  String get mediaOpen => 'تصفّح مكتبة الوسائط';

  @override
  String get shopOpenWeb => 'افتح المتجر';

  @override
  String get shopWebCheckout =>
      'اطّلع على الخيارات وسلّة التسوّق والتوصيل في المتجر الرسمي.';

  @override
  String get accountAccessHeading => 'الوصول إلى الحساب';

  @override
  String get accountWebHint =>
      'سجّل الدخول إلى حساب العضو على الموقع لإدارة رمز PIN.';

  @override
  String get accountOpenWeb => 'افتح حسابي على الموقع';

  @override
  String get accountForgotPin => 'هل نسيت رمز PIN؟';

  @override
  String get accountRecoveryHint =>
      'تواصل مع فريق أهل الخدمة إذا تعذّر تسجيل الدخول. حافظ على سرية رمز PIN.';

  @override
  String get accountContactSupport => 'تواصل مع الفريق عبر واتساب';

  @override
  String get pushUpdateError => 'تعذّر تحديث الإشعارات. حاول مجددًا.';

  @override
  String get pushSettingTitle => 'الإشعارات';

  @override
  String get pushSettingSubtitle => 'تلقّي تذكيرات الاشتراك وإعلانات الجمعية.';

  @override
  String get pushDenied => 'الإشعارات مرفوضة. فعّلها من إعدادات الهاتف.';

  @override
  String get pushOpen => 'فتح';

  @override
  String get cardMobileUnavailable =>
      'البطاقة غير متاحة في التطبيق حاليًا. يمكنك الاطلاع على حساب العضو على الموقع.';

  @override
  String get payMobileUnavailable =>
      'دفع الاشتراكات غير متاح في التطبيق حاليًا. افتح حساب العضو على الموقع للمتابعة.';

  @override
  String get historyOpenWeb => 'عرض سجل الدفعات الكامل على الموقع';

  @override
  String get onboardingMission => 'معًا في خدمة المريدية';

  @override
  String get onboardingMissionBody =>
      'يجمع أهل الخدمة الكفاءات والمواهب لخدمة طوبى.';

  @override
  String get onboardingCommunity => 'مجتمع ملتزم';

  @override
  String get onboardingCommunityBody =>
      'انضمّ إلى خلية محلية أو ادعم أعمال المجتمع بالتبرع.';

  @override
  String get onboardingServices => 'فضاء العضو';

  @override
  String get onboardingServicesBody =>
      'اعرض بطاقة عضويتك وتابع اشتراكاتك وتعرّف على Barkelu.';

  @override
  String onboardingStep(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get onboardingStart => 'ابدأ';

  @override
  String get onboardingNext => 'متابعة';

  @override
  String get onboardingBack => 'رجوع';

  @override
  String get onboardingSkip => 'تخطّي';

  @override
  String get galleryOpen => 'استكشف الصور';

  @override
  String get galleryTitle => 'صور الخدمة';

  @override
  String get galleryPhoto0 => 'المسجد الكبير في طوبى من الجو';

  @override
  String get galleryPhoto1 => 'طوبى من الجو';

  @override
  String get galleryPhoto2 => 'المجتمع والخدمة في طوبى';

  @override
  String get galleryPhoto3 => 'مشهد من مجتمع أهل الخدمة';

  @override
  String get galleryPhoto4 => 'الالتزام والخدمة';

  @override
  String get galleryPhoto5 => 'الثقافة المريدية';

  @override
  String get galleryPhoto6 => 'إرث الشيخ أحمد بمبا';

  @override
  String get cardFullScreen => 'تكبير البطاقة';

  @override
  String get shopSearch => 'ابحث عن منتج';

  @override
  String get shopNoMatches => 'لا توجد منتجات مطابقة لهذا البحث.';
}
