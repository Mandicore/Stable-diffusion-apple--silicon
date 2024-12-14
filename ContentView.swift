import SwiftUI

struct ContentView: View {
    @State private var generatedImage: NSImage?
    @State private var errorMessage: String?

    let stableDiffusionModel = StableDiffusionModel() // Instancier le modèle
    let tokenizer: Tokenizer

    init() {
        // Chemins vers les fichiers du tokenizer dans le sous-dossier `tokenizer`
        guard let vocabFilePath = Bundle.main.path(forResource: "vocab", ofType: "json"/*, inDirectory: "tokenizer"*/),
              let mergesFilePath = Bundle.main.path(forResource: "merges", ofType: "txt"/*, inDirectory: "tokenizer"*/),
              let specialTokensFilePath = Bundle.main.path(forResource: "special_tokens_map", ofType: "json"/*, inDirectory: "tokenizer"*/) else {
            fatalError("Erreur : Fichiers du tokenizer introuvables dans le répertoire 'tokenizer'.")
        }

        // Charger les fichiers du tokenizer
        let vocab: [String: Int] = loadJSON(from: vocabFilePath) ?? [:]
        let merges = (try? String(contentsOfFile: mergesFilePath, encoding: .utf8).components(separatedBy: "\n")) ?? []
        let specialTokens: [String: Token] = loadJSON(from: specialTokensFilePath) ?? [:]

        // Initialiser le tokenizer
        self.tokenizer = Tokenizer(vocab: vocab, merges: merges, specialTokens: specialTokens)
    }

    var body: some View {
        VStack {
            if let generatedImage = generatedImage {
                Image(nsImage: generatedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 512, height: 512)
            } else if let errorMessage = errorMessage {
                Text("Erreur : \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Text("Cliquez pour générer une image.")
            }

            Button("Générer une image") {
                let prompt = "Un paysage magnifique"
                let tokenizedPrompt = tokenizePrompt(prompt: prompt)

                stableDiffusionModel.generateImage(tokenizedPrompt) { image in
                    if let image = image {
                        self.generatedImage = image
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = "ERROR : échec lors de la génération de l'image."
                        print("ERROR : échec lors de la génération de l'image.")
                    }
                }
            }
        }
        .padding()
    }

    // Fonction pour tokenizer le prompt
    func tokenizePrompt(prompt: String) -> [Int] {
        let tokens = tokenizer.encode(prompt, addSpecialTokens: true)
        return tokens
    }
}

// Fonction pour charger les fichiers JSON
func loadJSON<T: Decodable>(from filePath: String) -> T? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}
