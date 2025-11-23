//
//  WordPressService.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 20/11/25.
//
import SwiftUI
import Combine

class WordPressService: ObservableObject {
    private let baseURL = "https://ribaund.com/wp-json/wp/v2"
    private let postsPerPage = 10 // Sayfada gösterilecek post sayısı (Sayfalama için)

    @Published var posts: [Post] = []
    @Published var categories: [Category] = [Category(id: 0, name: "All News")]
    @Published var isLoading: Bool = false
    @Published var lastFetchError: String? = nil
    @Published var isCategoriesLoaded: Bool = false
    
    @Published var comments: [Int: [Comment]] = [:] // [PostID: [Comments]]
    @Published var currentLoadedCategoryId: Int = 0
    
    // MARK: - V1.1.0 Yeni Özellikler için Durumlar
    @Published var searchText: String = "" // Arama çubuğundan gelen metin
    @Published var currentPage: Int = 1
    @Published var canLoadMore: Bool = true // Daha fazla sayfa olup olmadığını kontrol eder
    @Published var isSearching: Bool = false // Arama modunda olup olmadığını kontrol eder
    @Published var lastLoadedSearchText: String = "" // Sayfalama için arama metnini saklar

    
    /// Helper functions (date formatting, HTML stripping, content formatting)
    func formatDate(_ dateString: String) -> String {
        // 1. Try ISO8601 with flexible options (Standard WordPress format)
        let isoFormatter = ISO8601DateFormatter()
        // Removed .withFractionalSeconds to handle dates without milliseconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        // 2. Fallback for potential alternative formats (if ISO8601 fails)
        let dateFormatter = DateFormatter()
        // Example fallback format: "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        return "Unknown Date"
    }
    
    func stripHTML(from text: String) -> String {
            var cleanedText = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            
            // V1.1.1: HTML varlıklarını temizle
            cleanedText = cleanedText.replacingOccurrences(of: "&amp;", with: "&")
            cleanedText = cleanedText.replacingOccurrences(of: "&nbsp;", with: " ")
            cleanedText = cleanedText.replacingOccurrences(of: "&#8216;", with: "'") // Sol tek tırnak (Open single quote)
            cleanedText = cleanedText.replacingOccurrences(of: "&#8217;", with: "'") // Sağ tek tırnak / Kesme işareti (Apostrophe / Close single quote)
            cleanedText = cleanedText.replacingOccurrences(of: "&#8220;", with: "\"") // Sol çift tırnak (Open double quote)
            cleanedText = cleanedText.replacingOccurrences(of: "&#8221;", with: "\"") // Sağ çift tırnak (Close double quote)
            cleanedText = cleanedText.replacingOccurrences(of: "&#8230;", with: "...") // Üç nokta (Ellipsis)
            cleanedText = cleanedText.replacingOccurrences(of: "&quot;", with: "\"") // Tırnak işareti (Quote)
            
            return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        /// Ana içerik için HTML etiketlerini temizler ve temel biçimlendirmeyi (yeni satırlar) ekler.
        func formatContentText(from html: String) -> String {
            var formattedText = html
            
            // Temel etiketleri yeni satır/boşluklarla değiştirme
            formattedText = formattedText.replacingOccurrences(of: "</?p.*?>", with: "\n\n", options: .regularExpression, range: nil)
            formattedText = formattedText.replacingOccurrences(of: "</?h[1-6].*?>", with: "\n", options: .regularExpression, range: nil)
            formattedText = formattedText.replacingOccurrences(of: "<br\\s*?/?>", with: "\n", options: .regularExpression, range: nil)
            formattedText = formattedText.replacingOccurrences(of: "</?div.*?>|</?span.*?>|</?figure.*?>", with: "\n", options: .regularExpression, range: nil)
            formattedText = formattedText.replacingOccurrences(of: "<li.*?>", with: "\n• ", options: .regularExpression, range: nil)
            formattedText = formattedText.replacingOccurrences(of: "</?ul.*?>|</?ol.*?>|</?li>", with: "", options: .regularExpression, range: nil)
            
            // Kalan tüm HTML etiketlerini temizle
            formattedText = formattedText.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            
            // V1.1.1: HTML varlıklarını temizle (tekrar kontrol)
            formattedText = formattedText.replacingOccurrences(of: "&nbsp;", with: " ")
            formattedText = formattedText.replacingOccurrences(of: "&amp;", with: "&")
            formattedText = formattedText.replacingOccurrences(of: "&gt;", with: ">")
            formattedText = formattedText.replacingOccurrences(of: "&lt;", with: "<")
            formattedText = formattedText.replacingOccurrences(of: "&#8216;", with: "'") // Sol tek tırnak
            formattedText = formattedText.replacingOccurrences(of: "&#8217;", with: "'") // Kesme işareti/Sağ tek tırnak
            formattedText = formattedText.replacingOccurrences(of: "&#8220;", with: "\"") // Sol çift tırnak
            formattedText = formattedText.replacingOccurrences(of: "&#8221;", with: "\"") // Sağ çift tırnak
            formattedText = formattedText.replacingOccurrences(of: "&#8230;", with: "...") // Üç nokta
            formattedText = formattedText.replacingOccurrences(of: "&quot;", with: "\"") // Tırnak işareti
            
            // Birden fazla yeni satırı tek bir paragrafla sınırla
            formattedText = formattedText.trimmingCharacters(in: .whitespacesAndNewlines)
            formattedText = formattedText.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression, range: nil)
            return formattedText
        }
    
    func fetchCategories() async {
            let urlString = "\(baseURL)/categories?per_page=100"
            guard let url = URL(string: urlString) else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decodedCategories = try JSONDecoder().decode([Category].self, from: data)
                await MainActor.run {
                    // 💡 CHANGE HERE: Updated the default hardcoded category name
                    self.categories = [Category(id: 0, name: "Haberler")]
                    self.categories.append(contentsOf: decodedCategories.filter { $0.id != 1 })
                    self.isCategoriesLoaded = true
                }
            } catch {
                let errorDescription = error.localizedDescription.lowercased()
                // 💡 Robust check for cancellation to prevent spurious errors
                if errorDescription.contains("cancelled") || errorDescription.contains("cancellation") || error is CancellationError {
                    await MainActor.run { self.isCategoriesLoaded = true }
                    return
                }
                await MainActor.run { self.isCategoriesLoaded = true }
            }
        }

    /// Haberleri çeker. 'forceRefresh' false ise ve veriler zaten yüklüyse tekrar çekmez.
    func fetchPosts(for categoryId: Int? = nil, searchQuery: String? = nil, page: Int = 1, isPaginating: Bool = false, forceRefresh: Bool = false) async {
            let categoryToLoad = categoryId ?? 0
            let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            // Önbellekleme Kontrolü: Aynı kategori/arama ve ilk sayfa ise tekrar çekme
            if !isPaginating && !posts.isEmpty && !forceRefresh && currentLoadedCategoryId == categoryToLoad && lastLoadedSearchText == query {
                return
            }
            
            // Sayfalama yapıyorsak ve daha fazla yüklenemiyorsa dur
            if isPaginating && !canLoadMore { return }
            
            await MainActor.run {
                // Sadece ilk yüklemede veya arama/kategori değişiminde true yapılır, sonsuz kaydırmada false kalır
                if !isPaginating {
                    self.isLoading = true
                }
                self.lastFetchError = nil
            }
            
            // URL Oluşturma
            var urlString = "\(baseURL)/posts?per_page=\(postsPerPage)&page=\(page)&_embed=true&_fields=id,date,title,content,featured_media,_links,_embedded"
            
            if categoryToLoad != 0 { urlString += "&categories=\(categoryToLoad)" }
            if !query.isEmpty { urlString += "&search=\(query)" } // Arama parametresi eklendi
            
            guard let url = URL(string: urlString) else {
                await MainActor.run { self.isLoading = false; self.lastFetchError = "Geçersiz API URL'si." }
                return
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    await MainActor.run { self.isLoading = false; self.lastFetchError = "Sunucu Hatası. Kod: \((response as? HTTPURLResponse)?.statusCode ?? 0)." }
                    return
                }
                
                // X-WP-TotalPages başlığını okuyoruz, ancak artık sadece kontrol amaçlı kullanacağız.
                let totalPagesHeader = httpResponse.allHeaderFields["X-WP-TotalPages"] as? String
                let totalPages = Int(totalPagesHeader ?? "1") ?? 1

                let decodedPosts = try JSONDecoder().decode([Post].self, from: data)
                
                await MainActor.run {
                    if isPaginating {
                        self.posts.append(contentsOf: decodedPosts)
                        self.currentPage = page
                    } else {
                        self.posts = decodedPosts
                        self.currentPage = 1
                        self.currentLoadedCategoryId = categoryToLoad
                        self.lastLoadedSearchText = query
                    }
                    
                    // MARK: - SAYFALAMA MANTIĞI DÜZELTME (V1.1.3)
                    // Dönen post sayısı istenen (postsPerPage) ile aynıysa, muhtemelen daha fazla sayfa vardır.
                    self.canLoadMore = decodedPosts.count == self.postsPerPage
                    
                    if !isPaginating { self.isLoading = false }
                }
            } catch {
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("cancelled") || error is CancellationError {
                    await MainActor.run { if !isPaginating { self.isLoading = false } }
                    return
                }
                
                await MainActor.run { if !isPaginating { self.isLoading = false }; self.lastFetchError = "Veri Çözme Hatası: \(error.localizedDescription)" }
            }
        }
    
    func loadNextPage() async {
            guard canLoadMore && !isLoading else { return }
            
            // Bu fonksiyonda loading durumunu false olarak tutuyoruz ki UI'da büyük bir yükleyici görünmesin
            // Ancak API çağrısını başlatmadan önce bir kontrol mekanizması ekliyoruz.
            let next = currentPage + 1
            // Mevcut kategori ve arama metniyle bir sonraki sayfayı yükle
            await fetchPosts(for: currentLoadedCategoryId, searchQuery: lastLoadedSearchText, page: next, isPaginating: true)
        }
        
        // MARK: - Arama Başlatma Fonksiyonu
        func startSearch() async {
            guard !isLoading else { return } // Halihazırda yükleme yapıyorsak bekle
            
            // Arama yapıldığında kategori filtresini sıfırla (Kategori seçiminin aramayla çakışmasını önlemek için)
            await fetchPosts(for: 0, searchQuery: searchText, page: 1, isPaginating: false, forceRefresh: true)
        }
        
        // MARK: - Yorum Fonksiyonları (401 Hata İşleme Düzeltildi)
        
        func fetchComments(forPostId postId: Int) async {
            let urlString = "\(baseURL)/comments?post=\(postId)&per_page=100&orderby=date&order=asc"
            guard let url = URL(string: urlString) else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decodedComments = try JSONDecoder().decode([Comment].self, from: data)
                
                await MainActor.run {
                    self.comments[postId] = decodedComments
                }
            } catch {
                print("Yorumlar çekilemedi: \(error.localizedDescription)")
            }
        }
        
    func postComment(postId: Int, authorName: String, authorEmail: String, content: String) async -> (success: Bool, message: String) {
            let urlString = "\(baseURL)/comments"
            guard let url = URL(string: urlString) else {
                return (false, "Geçersiz API adresi.")
            }

            let body: [String: Any] = [
                "post": postId,
                "author_name": authorName,
                "author_email": authorEmail,
                "content": content
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                return (false, "Yorum verisi hazırlanırken hata oluştu.")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Sunucu ve Güvenlik Duvarı Engellerini Aşmak İçin User-Agent Ekleme
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
            
            request.httpBody = jsonData
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return (false, "Sunucudan geçerli yanıt alınamadı.")
                }
                
                if httpResponse.statusCode == 201 {
                    await fetchComments(forPostId: postId)
                    return (true, "Yorumunuz başarıyla gönderildi. Onaylandıktan sonra yayınlanacaktır.")
                } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    // Ayrıntılı hata mesajı almak için yanıt gövdesini çözmeyi dene
                    let responseBodyString = String(data: data, encoding: .utf8) ?? "Bilinmeyen sunucu yanıtı."
                    
                    // CRITICAL: 401/403 için çok spesifik, eyleme geçirilebilir hata mesajı.
                    let specificErrorMessage = """
                    Yorum gönderme yetkiniz yok (\(httpResponse.statusCode) Hata Kodu). Bu, anonim yorumlara izin verilmesine rağmen sunucunuzun (web sitenizin) mobil uygulamadan gelen bu isteği engellediği anlamına gelir.

                    LÜTFEN WEB SİTENİZDE ŞU ADIMLARI KONTROL EDİN:
                    
                    1. Yorum Eklentisi: wpDiscuz (veya benzeri bir eklenti) kullanıyorsanız, LÜTFEN EKLENTİYİ GEÇİCİ OLARAK DEVRE DIŞI BIRAKIN ve tekrar deneyin. Bu eklentiler standart API'yi engeller.
                    
                    2. Güvenlik Eklentileri: Wordfence, iThemes Security, Sucuri gibi güvenlik eklentilerinin "API koruması" ayarlarını ve "Canlı Trafik" loglarını kontrol edin. İstek muhtemelen bu eklentiler tarafından "kötü amaçlı" (bot) olarak engelleniyor.
                    
                    3. Hosting Güvenliği (WAF): Hosting panelinizdeki (cPanel, Plesk vb.) ModSecurity veya WAF (Web Application Firewall) ayarlarında `POST /wp-json/wp/v2/comments` yolunun engellenip engellenmediğini kontrol edin veya hosting firmanızdan mobil istekleri beyaz listeye almalarını isteyin.
                    
                    """
                    
                     return (false, specificErrorMessage)

                } else if httpResponse.statusCode == 400 {
                    // 400 hatalarını (örneğin spam, eksik alanlar, geçersiz e-posta) ele almak
                    // Tekrar denemeye gerek yok, data zaten üstte alınmış olmalı.
                    let data = data
                    if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data), let errorMessage = errorResponse["message"] {
                        return (false, "Yorum gönderilemedi: \(errorMessage)")
                    }
                    return (false, "Yorum gönderilirken bir hata oluştu. Sunucu kodu: \(httpResponse.statusCode)")
                } else {
                    return (false, "Yorum gönderilirken bir hata oluştu. Sunucu kodu: \(httpResponse.statusCode)")
                }

            } catch {
                return (false, "Ağ hatası: \(error.localizedDescription)")
            }
        }
    }
