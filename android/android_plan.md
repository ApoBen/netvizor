# Hedef: NetVizör'ü Bağımsız Bir Android Uygulamasına (APK) Dönüştürmek

Bu belge, NetVizör projesini Python tabanlı bir terminal betiğinden çıkarıp **kendi web arayüzünü barındıran (WebView), başlangıçta kullanıcıya Root veya VPN seçenekleri sunan bağımsız bir Android uygulamasına (APK)** dönüştürmek için gereken teknik gereksinimleri ve planı içermektedir.

> [!WARNING]
> **Termux APK'sını Düzenlemek Hakkında**
> Mevcut `com.termux_1022.apk` dosyasını (`apktool` gibi araçlarla) parçalayıp içine WebView ve VPN servisi enjekte etmek teknik olarak sürdürülebilir veya sağlıklı bir yöntem değildir. Termux kapalı bir terminal emülatörüdür ve Android'in `VpnService` gibi sistem bileşenleriyle çalışacak şekilde tasarlanmamıştır. Gerçek, performanslı ve güvenli bir Android uygulaması oluşturmak için **yeni bir Native (Yerel) Android projesi** kurulması şarttır.

## User Review Required

Lütfen aşağıdaki kısıtlamaları ve önerilen teknik mimariyi inceleyerek hangi yoldan ilerlemek istediğinize karar verin:

1. **Python ve VPN Kısıtlaması**: Android sistemlerinde `VpnService` (Rootsuz ağ izleme için gereken servis) sadece yerel Android dilleriyle (Java/Kotlin) yazılabilir. Python kodlarımız (`psutil`, `scapy`) doğrudan bir VPN servisi olarak **çalışamaz**.
2. **Mimari Değişikliği**: VPN üzerinden rootsuz trafik izleme özelliği isteniyorsa, uygulamanın arka plan veri toplama (Backend) mantığını tamamen **Kotlin/Java** kullanarak yeniden yazmamız gerekecektir.

## Open Questions

> [!IMPORTANT]
> **Uygulama Geliştirme Yaklaşımı İçin Kararınız Nedir?**
>
> Önümüzde iki temel yol bulunuyor:
> 
> **Seçenek A (Sadece Root ile Çalışan Python APK - Hızlı Yol):**
> Bilgisayarınıza `Buildozer` veya `Flet` kurarak mevcut Python kodumuzu bir APK'ya çevirebiliriz. Uygulama içine bir tarayıcı (WebView) ekleriz. Ancak bu uygulama sadece **Root'lu** cihazlarda çalışabilir. VPN seçeneği olmaz.
>
> **Seçenek B (Gerçek Android Uygulaması - VPN ve Root Destekli - Zor ve Uzun Yol):**
> Python backend'i tamamen iptal edilir. Bilgisayarınıza Android SDK ve Gradle kurarız. Tamamen **Kotlin** dilinde yeni bir Android projesi başlatırız. Uygulama, ağ paketlerini Android `VpnService` üzerinden yakalar ve mevcut HTML/JS arayüzünüzü uygulamanın içindeki bir Web Görünümünde (WebView) gösterir.
>
> Hangi seçenek sizin hedeflerinize daha uygun? 

## Proposed Changes (Seçenek B Seçilirse)

Eğer gerçek bir Android uygulaması (Kotlin) geliştirmeye karar verirsek, yapılacak temel değişiklikler şunlar olacaktır:

### 1. Ortam Kurulumu
- Arch Linux bilgisayarınıza `android-studio`, `android-sdk`, `gradle` ve `jdk` araçları kurulacaktır.
- Sudo şifreniz kullanılarak `pacman -S ...` üzerinden gerekli geliştirme paketleri eklenecektir.

### 2. Android Projesinin Oluşturulması
- Yeni bir Android Studio (Kotlin) projesi oluşturulacak.
- Uygulama ilk açıldığında kullanıcıya **"Root Modu"** veya **"VPN Modu"** seçeneklerini sunan bir başlangıç ekranı (Activity) tasarlanacak.
- Seçim `SharedPreferences` (veya DataStore) ile cihaz hafızasına kaydedilecek.

### 3. VpnService Entegrasyonu (Rootsuz Kullanım İçin)
- Kullanıcı VPN modunu seçerse, Android OS'den VPN kurma izni istenecek.
- Uygulama yerel bir VPN tüneli (TUN interface) oluşturup cihazdaki tüm paketleri üzerine çekecek ve boyutlarını/kaynaklarını hesaplayarak istatistik oluşturacak.

### 4. WebView Entegrasyonu (Arayüz)
- Mevcut `frontend/` (HTML/CSS/JS) dosyaları Android uygulamasının `assets` klasörüne kopyalanacak.
- Ekrana tam boy bir `WebView` eklenecek ve yerel dosyalar (`file:///android_asset/index.html`) üzerinden görselleştirme sağlanacak.
- Kotlin'de toplanan ağ verileri, bir `JavascriptInterface` veya yerel WebSockets üzerinden web arayüzüne canlı olarak iletilecek.

## Verification Plan

### Manual Verification
- Arch Linux üzerinde APK başarıyla derlenebiliyor mu kontrol edilecek (`./gradlew assembleDebug`).
- Derlenen APK bir Android cihaza veya emülatöre aktarılıp:
  1. Başlangıçtaki Root / VPN seçim ekranının çalıştığı doğrulanacak.
  2. Seçimin kaydedildiği ve bir sonraki açılışta sorulmadığı teyit edilecek.
  3. WebView arayüzünün sorunsuz yüklendiği ve verilerin aktığı görülecek.
