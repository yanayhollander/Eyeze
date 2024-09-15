//
//  ContentView.swift
//  ContentView
//
//  Created by Omer Zukerman on 03/09/2024.
//

import SwiftUI
import ARKit
import UIKit


struct ContentView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(languageManager.localizedString(forKey: "Home"), systemImage: "house.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label(languageManager.localizedString(forKey: "Settings"), systemImage: "gearshape.fill")
                }
        }
    }
}
