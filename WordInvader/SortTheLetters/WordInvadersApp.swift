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
    // Container untuk model SwiftData
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WordItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Menambahkan data awal jika database kosong
            Task {
                // Panggil versi static dari fungsi ini
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

    // Fungsi untuk menambahkan kata-kata awal
    // DIUBAH: Tambahkan 'static' di sini
    // In WordInvadersApp.swift

    @MainActor
    private static func addInitialWords(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<WordItem>()
        let count = try? context.fetchCount(fetchDescriptor)

        if count == 0 {
            // DIUBAH: Perbanyak daftar kata di sini
            let initialWords = [
                // Buah
                "APEL", "ANGGUR", "PISANG", "JERUK", "NANAS", "MANGGA", "DURIAN", "RAMBUTAN",
                // Hewan
                "KUCING", "ANJING", "BURUNG", "IKAN", "GAJAH", "HARIMAU", "ULAR", "SEMUT", "KAMBING",
                // Benda
                "MEJA", "KURSI", "BUKU", "PENSIL", "PINTU", "JENDELA", "LAMPU", "KIPAS", "TAS",
                // Teknologi
                "KOMPUTER", "PONSEL", "Kamera", "TELEVISI", "ROBOT", "INTERNET", "KODING",
                // Alam
                "GUNUNG", "PANTAI", "SUNGAI", "LAUT", "HUTAN", "BULAN", "BINTANG", "AWAN",
                // Lain-lain
                "RUMAH", "SEKOLAH", "PASAR", "MOBIL", "MOTOR", "SEPEDA", "MUSIK", "WARNA"
            ].map { $0.uppercased() } // Pastikan semua huruf besar

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
