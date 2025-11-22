//
//  CommentFormvIEW.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 21/11/25.
//

import SwiftUI

struct CommentFormView: View {
    let postId: Int
    @ObservedObject var service: WordPressService
    @Binding var isPresented: Bool
    
    @State private var authorName: String = ""
    @State private var authorEmail: String = ""
    @State private var commentContent: String = ""
    @State private var isPosting = false
    @State private var statusMessage: (message: String, isSuccess: Bool)? = nil
    
    let primaryColor = Color(red: 0.9, green: 0.4, blue: 0.1)
    
    var isFormValid: Bool {
        !authorName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(authorEmail) &&
        !commentContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }

    private func submitComment() {
        guard isFormValid else {
            statusMessage = (message: "Lütfen tüm alanları (geçerli e-posta dahil) doldurun.", isSuccess: false)
            return
        }
        
        isPosting = true
        Task {
            let result = await service.postComment(
                postId: postId,
                authorName: authorName,
                authorEmail: authorEmail,
                content: commentContent
            )
            
            await MainActor.run {
                isPosting = false
                statusMessage = (message: result.message, isSuccess: result.success)
                
                if result.success {
                    authorName = ""
                    authorEmail = ""
                    commentContent = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Lütfen Unutmayın: Yorumunuz yayınlanmadan önce web sitesi yöneticisi tarafından onaylanacaktır.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Form {
                    Section(header: Text("Kişisel Bilgiler")) {
                        TextField("Adınız ve Soyadınız", text: $authorName)
                            .textContentType(.name)
                        TextField("E-posta Adresiniz (Yayınlanmayacaktır)", text: $authorEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    Section(header: Text("Yorumunuz")) {
                        TextEditor(text: $commentContent)
                            .frame(height: 150)
                    }
                    
                    if let status = statusMessage {
                        HStack {
                            Image(systemName: status.isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                .foregroundColor(status.isSuccess ? .green : .red)
                            Text(status.message)
                                .foregroundColor(.primary)
                                .font(.subheadline)
                        }
                    }
                    
                    Button {
                        submitComment()
                    } label: {
                        HStack {
                            if isPosting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isPosting ? "Gönderiliyor..." : "Yorumu Gönder")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
                    .disabled(isPosting || !isFormValid)
                    .buttonStyle(.borderedProminent)
                    .tint(primaryColor)
                }
                .navigationTitle("Yorum Ekle")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Kapat") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
