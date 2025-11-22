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

    @Published var posts: [Post] = []
    @Published var categories: [Category] = [Category(id: 0, name: "All News")]
    @Published var isLoading: Bool = false
    @Published var lastFetchError: String? = nil
    @Published var isCategoriesLoaded: Bool = false
    
    @Published var comments: [Int: [Comment]] = [:] // [PostID: [Comments]]
    @Published var currentLoadedCategoryId: Int = 0 

    
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
        cleanedText = cleanedText.replacingOccurrences(of: "&amp;", with: "&")
        cleanedText = cleanedText.replacingOccurrences(of: "&#8217;", with: "'")
        cleanedText = cleanedText.replacingOccurrences(of: "&#8220;", with: "\"")
        cleanedText = cleanedText.replacingOccurrences(of: "&#8221;", with: "\"")
        
        // Explicitly handle common entities like Non-Breaking Space
        cleanedText = cleanedText.replacingOccurrences(of: "&nbsp;", with: " ")
        
        return cleanedText
    }
    
    func formatContentText(from html: String) -> String {
        var formattedText = html
        
        // 1. Replace block elements with newlines/separators
        formattedText = formattedText.replacingOccurrences(of: "</?p.*?>", with: "\n\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "</?h[1-6].*?>", with: "\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "<br\\s*?/?>", with: "\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "</?div.*?>|</?span.*?>|</?figure.*?>", with: "\n", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "<li.*?>", with: "\n• ", options: .regularExpression, range: nil)
        formattedText = formattedText.replacingOccurrences(of: "</?ul.*?>|</?ol.*?>|</?li>", with: "", options: .regularExpression, range: nil)
        
        // 2. Remove all remaining HTML tags
        formattedText = formattedText.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        
        // 3. Decode common HTML entities (including &nbsp; fix)
        formattedText = formattedText.replacingOccurrences(of: "&nbsp;", with: " ") // 💡 The new fix for &nbsp;
        formattedText = formattedText.replacingOccurrences(of: "&amp;", with: "&")
        formattedText = formattedText.replacingOccurrences(of: "&gt;", with: ">")
        formattedText = formattedText.replacingOccurrences(of: "&lt;", with: "<")
        formattedText = formattedText.replacingOccurrences(of: "&#8217;", with: "'")
        formattedText = formattedText.replacingOccurrences(of: "&#8220;", with: "\"")
        formattedText = formattedText.replacingOccurrences(of: "&#8221;", with: "\"")
        
        // 4. Clean up spacing and newlines
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
        func fetchPosts(for categoryId: Int? = nil, forceRefresh: Bool = false) async {
            let categoryToLoad = categoryId ?? 0
            
            // Önbellekleme Kontrolü: Eğer veriler boş değilse VE Yenileme zorlanmadıysa VE doğru kategori yüklüyse, çık.
            if !posts.isEmpty && !forceRefresh && currentLoadedCategoryId == categoryToLoad {
                return
            }
            
            await MainActor.run {
                self.isLoading = true
                self.lastFetchError = nil
            }
            
            // _links verisine ihtiyacımız olduğu için API çağrısında bunu belirtiyoruz.
            var urlString = "\(baseURL)/posts?per_page=15&_embed=true&_fields=id,date,title,content,featured_media,_links,_embedded"
            if categoryToLoad != 0 { urlString += "&categories=\(categoryToLoad)" }
            
            guard let url = URL(string: urlString) else {
                await MainActor.run { self.isLoading = false; self.lastFetchError = "Invalid API URL." }
                return
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    await MainActor.run { self.isLoading = false; self.lastFetchError = "Server error. Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)." }
                    return
                }
                let decodedPosts = try JSONDecoder().decode([Post].self, from: data)
                await MainActor.run {
                    self.posts = decodedPosts
                    self.isLoading = false
                    self.currentLoadedCategoryId = categoryToLoad // Yüklü kategoriyi güncelle
                }
            } catch {
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("cancelled") || errorDescription.contains("cancellation") || error is CancellationError {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                
                await MainActor.run { self.isLoading = false; self.lastFetchError = "Decoding failed: \(error.localizedDescription)" }
            }
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
