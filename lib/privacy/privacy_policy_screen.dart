import '../analytics/app_analytics_service.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حریم خصوصی')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const SingleChildScrollView(
              key: Key('privacy-policy-scroll'),
              padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PolicyHeading('حریم خصوصی گره‌راه'),
                    _PolicyParagraph(
                      'این متن توضیح می‌دهد گره‌راه و سازندهٔ آن، DaMo Studio، چه اطلاعاتی را نگه می‌دارند. بازی به ساخت حساب یا وارد کردن اطلاعات شخصی نیاز ندارد.',
                    ),
                    _PolicyHeading('پیشرفت بازی روی دستگاه'),
                    _PolicyParagraph(
                      'شناسهٔ مرحله‌های کامل‌شده، کمترین تعداد حرکت، بهترین زمان و وضعیت تکمیل آموزش روی دستگاه شما ذخیره می‌شوند. با حذف داده‌های برنامه یا پاک کردن بازی این داده‌ها حذف می‌شوند. پشتیبان‌گیری سیستم‌عامل ممکن است روی بازیابی آن‌ها اثر بگذارد.',
                    ),
                    _PolicyHeading('آمار استفاده و گزارش خطا'),
                    _PolicyParagraph(
                      firebaseEnabled
                          ? 'در این نسخه Firebase Analytics و Firebase Crashlytics با پیکربندی مستقل گره‌راه فعال هستند.'
                          : 'در این نسخه ارسال آمار و گزارش خطا با Firebase Analytics و Firebase Crashlytics غیرفعال است. فعال‌سازی در نسخه‌های بعدی فقط با پیکربندی مستقل گره‌راه انجام می‌شود.',
                    ),
                    _PolicyParagraph(
                      'اگر این خدمات فعال باشند، Firebase Analytics ممکن است نسخهٔ برنامه، نوع دستگاه، سیستم‌عامل، شناسهٔ نمونهٔ برنامه و اطلاعات تقریبی منطقه را از ارتباط شبکه پردازش کند. جمع‌آوری شناسهٔ تبلیغاتی (AD_ID) غیرفعال است و موقعیت دقیق GPS دریافت نمی‌شود.',
                    ),
                    _PolicyParagraph(
                      'رویدادهای استفاده شامل اشتراک‌گذاری (share_app_click)، نمایش و تکمیل آموزش (tutorial_view و tutorial_complete)، حرکت نامعتبر (invalid_move) و تکمیل مرحله (level_complete) هستند. اطلاعات تکمیل مرحله شامل شناسهٔ مرحله، شمارهٔ فصل و مرحله، تعداد حرکت و زمان حل است.',
                    ),
                    _PolicyParagraph(
                      'در صورت فعال بودن Firebase Crashlytics، گزارش‌ها می‌توانند شامل شرح خطا، مسیر اجرای کد، وضعیت مرتبط دستگاه یا برنامه، شناسهٔ نصب و اطلاعات تشخیصی نشست باشند. بازی برای گزارش خطا رمز عبور، پیام، عکس، صدای ضبط‌شده یا موقعیت دقیق دریافت نمی‌کند.',
                    ),
                    _PolicyHeading('خدمات دیگر و نگهداری اطلاعات'),
                    _PolicyParagraph(
                      'خدمات Firebase توسط Google ارائه می‌شوند. در صورت فعال‌سازی، داده‌ها طبق شرایط و سیاست‌های Google و Firebase پردازش و بر اساس تنظیمات آن خدمات نگهداری می‌شوند. گره‌راه و DaMo Studio اطلاعات شخصی را نمی‌فروشند. بازی فرم یا حسابی برای دریافت مستقیم اطلاعات شخصی، از جمله از کودکان، ندارد.',
                    ),
                    _PolicyHeading('اشتراک‌گذاری بازی'),
                    _PolicyParagraph(
                      'دکمهٔ اشتراک‌گذاری، پنجرهٔ اشتراک‌گذاری اندروید را باز می‌کند و متن معرفی بازی و پیوند کافه‌بازار را به برنامه‌ای که انتخاب می‌کنید می‌فرستد. گره‌راه مخاطب یا مقصد انتخابی شما را دریافت نمی‌کند. در صورت فعال بودن آمار، زدن این دکمه ثبت می‌شود.',
                    ),
                    _PolicyHeading('دسترسی‌ها'),
                    _PolicyParagraph(
                      'گره‌راه دسترسی به مخاطبان، دوربین، میکروفون، عکس‌ها یا موقعیت دقیق را درخواست نمی‌کند. در صورت فعال بودن خدمات آنلاین، ارتباط شبکه برای ارسال آمار و گزارش خطا استفاده می‌شود.',
                    ),
                    _PolicyHeading('تماس با سازنده'),
                    _PolicyParagraph(
                      'سازنده: DaMo Studio\nوب‌سایت: https://damo-studio.com\nایمیل: info@damo-studio.com',
                      key: Key('privacy-policy-contact'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyHeading extends StatelessWidget {
  const _PolicyHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: const Color(0xFFD2DCE9),
          height: 1.5,
        ),
      ),
    );
  }
}
