# PhotoRenamer

![Swift Version](https://img.shields.io/badge/Swift-5.7+-orange.svg)
![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)

PhotoRenamer, Google'ın Gemini AI teknolojisini kullanarak fotoğrafları analiz eden ve anlamlı dosya adları oluşturan bir macOS uygulamasıdır.

## Özellikler

- **Kolay Fotoğraf Yükleme**: Sürükle-bırak ve dosya seçici arayüzleri ile fotoğraflarınızı kolayca yükleyin.
- **Akıllı İsim Önerileri**: Gemini AI ile fotoğraflarınız analiz edilir ve içeriğine uygun akıllı dosya adları önerilir.
- **Özelleştirilebilir Adlandırma**: Önerilen dosya adını görmeden önce düzenleyebilirsiniz.
- **Güvenli API Anahtarı Yönetimi**: API anahtarınız Keychain'de güvenli bir şekilde saklanır.
- **Kullanıcı Dostu Arayüz**: Modern ve sezgisel bir kullanıcı arayüzü ile kolay kullanım.

## Gereksinimler

- macOS 12.0 veya daha yeni
- Swift 5.7 veya daha yeni
- Google Cloud Gemini API anahtarı

## Kurulum

1. Bu depoyu klonlayın:
   ```
   git clone https://github.com/username/PhotoRenamer.git
   cd PhotoRenamer
   ```

2. Swift Package Manager ile projeyi oluşturun:
   ```
   swift build
   ```
   
3. Veya Xcode ile açın:
   ```
   open Package.swift
   ```

## Gemini API Anahtarı Alınması

1. [Google AI Studio](https://makersuite.google.com/app/apikey) adresine gidin.
2. Google hesabınızla giriş yapın.
3. API anahtarı oluşturun veya mevcut bir anahtarı kullanın.
4. Oluşturulan API anahtarını PhotoRenamer uygulamasının ayarlar bölümüne girin.

## Kullanım

1. Uygulamayı başlatın.
2. Ayarlar bölümünden Gemini API anahtarınızı ekleyin.
3. Fotoğrafınızı sürükleyip bırakın veya dosya seçici ile yükleyin.
4. Fotoğraf yüklendikten sonra otomatik olarak analiz edilir ve bir dosya adı önerilir.
5. Önerilen dosya adını isteğinize göre düzenleyebilirsiniz.
6. "Yeniden Adlandır" düğmesine tıklayarak dosyayı yeni adıyla kaydedebilirsiniz.

## Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır. 