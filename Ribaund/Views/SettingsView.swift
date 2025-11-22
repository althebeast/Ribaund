//
//  SettingsView.swift
//  Ribaund
//
//  Created by Alperen Sarisan on 21/11/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    // Deep Orange color inspired by a basketball
    let primaryColor = Color(red: 0.9, green: 0.4, blue: 0.1)

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    
                    VStack {
                        Image(systemName: "basketball.fill")
                            .font(.system(size: 80))
                            .foregroundColor(primaryColor)
                            .shadow(color: primaryColor.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        Text("Ayarlar")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 40)

                    // Settings Card
                    VStack(spacing: 20) {
                        
                        // Theme Switch (Dark/Light Mode)
                        HStack {
                            let isDark = themeManager.isDarkModeEnabled ?? (UITraitCollection.current.userInterfaceStyle == .dark)
                            Label("Tema (\(isDark ? "Koyu" : "Açık"))", systemImage: isDark ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(primaryColor)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { themeManager.isDarkModeEnabled ?? false },
                                set: { themeManager.isDarkModeEnabled = $0 }
                            ))
                            .labelsHidden()
                            .tint(primaryColor)
                        }
                        
                        Divider().background(primaryColor.opacity(0.3))
                        
                        // App Version Info
                        HStack {
                            Label("Versiyon", systemImage: "info.circle.fill")
                                .foregroundColor(primaryColor)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().background(primaryColor.opacity(0.3))
                            
                        // Credits/About
                        HStack {
                            Label("Hakkında", systemImage: "figure.basketball")
                                .foregroundColor(primaryColor)
                            Spacer()
                            Text("Ribaund Haberler")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.primary.opacity(0.1), radius: 5)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    SettingsView()
}
