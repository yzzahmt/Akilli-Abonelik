import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class PrivacyAgreementScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const PrivacyAgreementScreen({super.key, required this.onAccepted});

  @override
  State<PrivacyAgreementScreen> createState() => _PrivacyAgreementScreenState();
}

class _PrivacyAgreementScreenState extends State<PrivacyAgreementScreen> {
  String _lang = 'TR'; // 'TR' or 'EN'
  bool _acceptedTerms = false;

  final Map<String, Map<String, String>> _text = {
    'TR': {
      'title': 'Kişisel Verilerin Korunması Kanunu (KVKK) Bilgilendirmesi',
      'body': '''Lütfen uygulamayı kullanmaya başlamadan önce aşağıdaki aydınlatma metnini dikkatlice okuyunuz.

1. Veri Sorumlusu
Bu uygulama aracılığıyla elde edilen kişisel verileriniz (abonelik bilgileri, harcama tutarları ve bildirim ayarları) KVKK kapsamında işlenmektedir.

2. Kişisel Verilerin İşlenme Amacı ve Hukuki Sebebi
Kişisel verileriniz, uygulama hizmetlerinin sunulması, harcamaların hesaplanması, yerel bildirimlerin planlanması ve uygulamanın geliştirilmesi amacıyla işlenmektedir. Bu veriler yalnızca cihazınız üzerinde saklanmakta olup, harici bir sunucuya aktarılmamaktadır.

3. İşlenen Kişisel Verileriniz
Uygulamada saklanan abonelik adı, fiyatı, para birimi ve yenileme tarihi gibi bilgileriniz tamamen yerel veri tabanında (SQLite) muhafaza edilmektedir.

4. Haklarınız
KVKK'nın 11. maddesi uyarınca; verilerinizin işlenip işlenmediğini öğrenme, işlenmişse bilgi talep etme, işlenme amacına uygun kullanılıp kullanılmadığını öğrenme gibi haklara sahipsiniz.

Onaylayarak, yukarıdaki KVKK Aydınlatma Metni'ni okuduğunuzu, anladığınızı ve kabul ettiğinizi beyan etmiş olursunuz.''',
      'checkbox': 'Okudum, anladım ve kabul ediyorum.',
      'btn': 'Devam Et',
    },
    'EN': {
      'title': 'Privacy Policy & Terms (KVKK)',
      'body': '''Please read the following information carefully before using the application.

1. Data Controller
Your personal data (subscription details, spending amounts, and notification preferences) collected via this application is processed under KVKK and applicable privacy regulations.

2. Purpose and Legal Ground for Data Processing
Your personal data is processed to provide core application features, calculate spending, set up local reminders, and improve app functionality. This data remains on your local device only and is not transmitted to external servers.

3. Processed Personal Data
Details such as subscription name, cost, currency, and renewal dates are exclusively stored in your local database (SQLite).

4. Your Rights
Under personal data protection laws, you have the right to learn whether your data is processed, request information if processed, and ensure it is handled according to its specified purposes.

By proceeding, you declare that you have read, understood, and accepted the Privacy Terms.''',
      'checkbox': 'I have read, understood, and accept the terms.',
      'btn': 'Proceed',
    }
  };

  Future<void> _saveAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_kvkk_accepted', true);
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final t = _text[_lang]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ChoiceChip(
                    label: const Text('Türkçe'),
                    selected: _lang == 'TR',
                    selectedColor: AppColors.accentPurple,
                    backgroundColor: AppColors.surface1,
                    onSelected: (selected) {
                      if (selected) setState(() => _lang = 'TR');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('English'),
                    selected: _lang == 'EN',
                    selectedColor: AppColors.accentPurple,
                    backgroundColor: AppColors.surface1,
                    onSelected: (selected) {
                      if (selected) setState(() => _lang = 'EN');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                t['title']!,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable legal text
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      t['body']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Acceptance Checkbox
              Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: AppColors.textSecondary,
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    t['checkbox']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  activeColor: AppColors.accentPurple,
                  value: _acceptedTerms,
                  onChanged: (val) {
                    if (val != null) setState(() => _acceptedTerms = val);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _acceptedTerms ? AppColors.accentPurple : AppColors.surface1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _acceptedTerms ? _saveAccepted : null,
                  child: Text(
                    t['btn']!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
