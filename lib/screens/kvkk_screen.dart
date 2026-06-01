import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class KvkkScreen extends StatefulWidget {
  final bool isReadOnly;

  const KvkkScreen({super.key, this.isReadOnly = false});

  @override
  State<KvkkScreen> createState() => _KvkkScreenState();
}

class _KvkkScreenState extends State<KvkkScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isBottomReached = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (_scrollController.position.maxScrollExtent <= 0) {
          setState(() {
            _isBottomReached = true;
          });
        }
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 20) {
      if (!_isBottomReached) {
        setState(() {
          _isBottomReached = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _acceptAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kvkk_accepted', true);
    if (!mounted) return;

    final bool onboarding = prefs.getBool('onboarding_done') ?? false;
    if (!onboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (navContext) => OnboardingScreen(
            onComplete: () {
              Navigator.pushReplacement(
                navContext,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _rejectAndExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161925),
        title: Text(
          "Uyarı",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Uygulamayı kullanmak için KVKK'yı onaylamanız gerekmektedir.",
          style: GoogleFonts.inter(color: const Color(0xFFB0B3BE)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Geri Dön",
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: Text(
              "Çıkış Yap",
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isReadOnly,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || widget.isReadOnly) return;
        _rejectAndExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0D1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0D1A),
          elevation: 0,
          automaticallyImplyLeading: widget.isReadOnly,
          title: Text(
            "Gizlilik Politikası ve KVKK",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161925),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    _kvkkText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: const Color(0xFFB0B3BE),
                    ),
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: widget.isReadOnly ? const SizedBox() : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBottomReached
                            ? const Color(0xFF6C5CE7)
                            : Colors.grey.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isBottomReached ? _acceptAndProceed : null,
                      child: Text(
                        "Okudum, Onaylıyorum",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _rejectAndExit,
                      child: Text(
                        "Reddet ve Çık",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _kvkkText =
    '''KİŞİSEL VERİLERİN KORUNMASI KANUNU KAPSAMINDA AYDINLATMA METNİ VE KULLANICI RIZASI

Sürüm: 4.0 | Yürürlük Tarihi: [01.06.2026] | Hazırlayan: YAZIFY

MADDE 1 — VERİ SORUMLUSUNUN KİMLİĞİ VE İLETİŞİM BİLGİLERİ

6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") ve yürürlükteki ikincil mevzuat uyarınca veri sorumlusu sıfatıyla hareket eden taraf; "SubsTrack - Abonelik Takip Uygulaması" ("Uygulama") yazılımının geliştiricisi olan YAZIFY'dir ("Yazify.net"). İletişim: [yzz_software@hotmail.com]

MADDE 2 — UYGULAMANIN TEMEL NİTELİĞİ VE VERİ İŞLEME MİMARİSİ

2.1. SubsTrack Uygulaması, kullanıcıların dijital aboneliklerini, yatırım portföylerini ve ilgili mali bilgilerini takip etmelerine imkân tanıyan bir mobil yazılım uygulamasıdır.

2.2. MİMARİ GÜVENCE: Uygulama, "yerel veri işleme" ("local-first") mimarisi üzerine inşa edilmiştir. Bu mimari uyarınca kullanıcılar tarafından Uygulama içinde girilen tüm kişisel ve mali veriler (abonelik bilgileri, ödeme tarihleri, yatırım miktarları, portföy verileri ve benzeri bilgiler) münhasıran kullanıcının kendi mobil cihazında bulunan yerel SQLite veritabanında ("cihaz içi depolama") saklanmakta olup bu veriler hiçbir surette Şirket'e ait veya üçüncü taraflara ait uzak sunuculara iletilmemekte, aktarılmamakta veya depolanmamaktadır.

2.3. Şirket, kullanıcıların cihaz içi veritabanına teknik veya idari herhangi bir yolla erişim imkânına sahip değildir.

MADDE 3 — İŞLENEN VERİ KATEGORİLERİ VE İŞLEME AMAÇLARI

3.1. Kullanıcı Tarafından Girilen Veriler (Cihaz İçi İşleme):
   a) Abonelik bilgileri: Hizmet adı, aylık/yıllık ödeme tutarı, para birimi, yenileme tarihi, kategori bilgisi
   b) Yatırım bilgileri: Finansal araç adı, sembolü, alış fiyatı, alış tarihi, adet bilgisi, not alanı
   c) Uygulama tercihleri: Bildirim zamanlaması, bütçe limiti, dil/tema tercihi

   Bu veriler; abonelik takibi, harcama analizi, yatırım performans hesaplama ve kullanıcıya özelleştirilmiş bildirim gönderme amaçlarıyla cihaz içinde işlenmektedir.

3.2. Otomatik Olarak İşlenen Teknik Veriler:
   a) Çökme ve hata raporları: Uygulama çökmesi durumunda Google Play Services aracılığıyla anonim hata logu iletilebilir. Bu veriler kişisel bilgi içermez.
   b) Uygulama açılış istatistikleri: Google Firebase Analytics aracılığıyla anonim kullanım istatistiği toplanabilir (hangi ekranın ne kadar süre kullanıldığı). Bu veriler kişisel tanımlayıcı içermez.

3.3. Reklam Amacıyla İşlenen Veriler:
   Google AdMob reklam hizmeti, uygulama içinde reklam gösterimi amacıyla kullanılmaktadır. AdMob, reklam kişiselleştirme amacıyla cihaz tanımlayıcısı (Advertising ID) ve konum verisi (yaklaşık) kullanabilir. Bu işleme Google LLC'nin gizlilik politikası kapsamında yürütülmekte olup Şirket söz konusu veri işleme faaliyetinin veri sorumlusu değil, veri işleyen konumundadır. Kullanıcılar, cihaz ayarlarından reklam kişiselleştirmeyi devre dışı bırakabilir.
3.4. Yapay Zeka için işlenen veriler:
   Uygulamada yapmış olduğunuz işlemler uygulama içerisine entegreli kendi yapay zekası ile geçici süreliğinde hafızada tutularak size daha iyi bir hizmet vermek için işlenir. Bu veriler hiçbir şekilde sunucularımıza aktarılmaz ve depolanmaz. 
MADDE 4 — TALEP EDİLEN İZİNLER VE HUKUKİ GEREKÇELERİ

Uygulama aşağıdaki sistem izinlerini talep etmektedir:

4.1. BİLDİRİM GÖNDERİMİ:
   - Amaç: Abonelik yenileme tarihlerinden önce kullanıcıya hatırlatma bildirimi göndermek
   - Hukuki Dayanak: KVKK Madde 5/1 - Açık rıza; kullanıcının talebi ve ilgili kişinin açık rızası
   - Zorunluluk: Bu izin verilmezse bildirim özelliği çalışmaz; diğer özellikler etkilenmez

4.2. ZAMANLANMIŞ ALARM:
   - Amaç: Android 12 ve üzeri sürümlerde tam zamanlı (dakika hassasiyetinde) bildirim planlaması
   - Hukuki Dayanak: Meşru menfaat; kullanıcının talep ettiği hizmetin eksiksiz sunulması
   - Zorunluluk: Bu izin olmadan bildirimler belirsiz zamanlarda veya hiç gelmeyebilir

4.3. ÖNYÜKLEME TAMAMLANDI:
   - Amaç: Cihaz yeniden başlatıldığında önceden planlanmış bildirimlerin yeniden zamanlanması
   - Hukuki Dayanak: Meşru menfaat; kullanıcının talep ettiği hizmetin sürekliliği
   - Zorunluluk: Bu izin olmadan cihaz yeniden başlatıldıktan sonra bildirimler silinir

4.4. İNTERNET ERİŞİMİ :
   - Amaç: (a) Google AdMob reklam gösterimi; (b) Borsa/kripto/emtia anlık fiyat verisi çekimi (Yahoo Finance API - anonim); (c) Döviz kuru güncelleme
   - Hukuki Dayanak: Sözleşmenin ifası ve meşru menfaat
   - Aktarılan Veri: Kişisel veri içermeyen HTTP GET istekleri

MADDE 5 — VERİLERİN AKTARILMASI

5.1. Şirket, kullanıcıların cihaz içi verilerini hiçbir üçüncü tarafa aktarmaz.

5.2. Aşağıdaki üçüncü taraf hizmetler kendi gizlilik politikaları kapsamında sınırlı veri işleyebilir:
   - Google LLC (AdMob, Firebase Analytics, Play Services): Google Gizlilik Politikası
   - Yahoo Finance (fiyat API'si): Anonim HTTP isteği, kişisel veri aktarımı yoktur

5.3. Yurt dışı aktarım: Google LLC bünyesindeki hizmetler, ABD ve Avrupa Birliği'ndeki sunucularda işlenebilir. KVKK Madde 9 uyarınca açık rızanız bu aktarımı kapsamaktadır.

MADDE 6 — VERİLERİN SAKLANMA SÜRESİ VE SİLİNMESİ

6.1. Cihaz içi veriler, kullanıcı tarafından silinene veya uygulama kaldırılana kadar saklanır. Uygulama kaldırıldığında tüm veriler kalıcı olarak silinir.

6.2. Google Analytics anonim verileri Google'ın veri saklama politikası uyarınca saklanır.

MADDE 7 — VERİ KORUMA TEDBİRLERİ

7.1. Şirket aşağıdaki teknik tedbirleri almıştır:
   - Cihaz içi SQLite veritabanı işletim sistemi sandbox koruması altındadır
   - Uygulama, başka uygulamaların veritabanına erişimine izin vermez
   - Ağ iletişimleri TLS/HTTPS üzerinden yürütülür
   - Kaynak kod yetkisiz erişime karşı korunmaktadır

MADDE 8 — İLGİLİ KİŞİ HAKLARI (KVKK MADDE 11)

KVKK'nın 11. maddesi uyarınca aşağıdaki haklara sahipsiniz:
   a) Kişisel verilerinizin işlenip işlenmediğini öğrenme
   b) İşlenmişse buna ilişkin bilgi talep etme
   c) İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme
   d) Yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme
   e) Eksik veya yanlış işlenmiş ise düzeltilmesini isteme
   f) KVKK Madde 7'de öngörülen şartlar çerçevesinde silinmesini veya yok edilmesini isteme
   g) (e) ve (f) bentleri uyarınca yapılan işlemlerin aktarıldığı üçüncü kişilere bildirilmesini isteme
   h) İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme
   i) Kanuna aykırı işlenmesi sebebiyle zarara uğramanız halinde zararın giderilmesini talep etme

Haklarınızı kullanmak için: [EMAIL_ADRESI] adresine yazılı başvurabilirsiniz.

MADDE 9 — AÇIK RIZA BEYANI

İşbu metni okuduğunuzu, anladığınızı ve aşağıdaki hususlara açık rıza verdiğinizi beyan etmektesiniz:
   (i) Google AdMob tarafından reklam kişiselleştirme amacıyla cihaz tanımlayıcısının işlenmesi
   (ii) Kişisel veri içermeyen anonim analitik verinin Firebase Analytics üzerinden işlenmesi
   (iii) Yurt dışı (Google LLC, ABD) veri aktarımı

Bu metni onaylamak, uygulamanın kullanım koşullarını da kabul ettiğiniz anlamına gelir.

---

MADDE 10 — POLİTİKA GÜNCELLEMELERİ

Şirket, bu metni önceden bildirmeksizin güncelleyebilir. Önemli değişiklikler uygulama içi bildirimle duyurulacaktır. Güncel metin her zaman Ayarlar > KVKK/Gizlilik bölümünden erişilebilir.''';
