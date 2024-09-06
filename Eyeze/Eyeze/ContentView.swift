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
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
