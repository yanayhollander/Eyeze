//
//  LanguageManager.swift
//  Eyeze
//
//  Created by Yanay Hollander on 15/09/2024.
//

import Foundation
import UIKit
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String
    private var bundle: Bundle?

    private init() {
        currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        loadBundle(for: currentLanguage)
    }

    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set(languageCode, forKey: "selectedLanguage")
        loadBundle(for: languageCode)
        
        // Notify views to update
        objectWillChange.send()
    }

    private func loadBundle(for languageCode: String) {
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = Bundle.main
        }
    }

    func localizedString(forKey key: String) -> String {
        bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}
