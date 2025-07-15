//
//  WordInvadersApp.swift
//  WordInvaders
//
//  Created by Louis Fernando on 09/07/25.
//

import SwiftUI
import SwiftData

@main
struct WordInvadersApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WordItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            Task {
                WordInvadersApp.addInitialWords(context: container.mainContext)
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    @MainActor
    private static func addInitialWords(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<WordItem>()
        let count = try? context.fetchCount(fetchDescriptor)
        
        if count == 0 {
            let initialWords = [
                "APEL", "ANGGUR", "PISANG", "JERUK", "NANAS", "MANGGA", "DURIAN", "RAMBUTAN",
                "KUCING", "ANJING", "BURUNG", "IKAN", "GAJAH", "HARIMAU", "ULAR", "SEMUT", "KAMBING",
                "MEJA", "KURSI", "BUKU", "PENSIL", "PINTU", "JENDELA", "LAMPU", "KIPAS", "TAS",
                "KOMPUTER", "PONSEL", "Kamera", "TELEVISI", "ROBOT", "INTERNET", "KODING",
                "GUNUNG", "PANTAI", "SUNGAI", "LAUT", "HUTAN", "BULAN", "BINTANG", "AWAN",
                "RUMAH", "SEKOLAH", "PASAR", "MOBIL", "MOTOR", "SEPEDA", "MUSIK", "WARNA"
            ].map { $0.uppercased() }
            for wordText in initialWords {
                let newWord = WordItem(text: wordText)
                context.insert(newWord)
            }
            try? context.save()
            print("Initial words added to SwiftData.")
        } else {
            print("Database already contains words.")
        }
    }
}
