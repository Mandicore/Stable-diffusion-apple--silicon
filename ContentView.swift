import SwiftUI

struct ContentView: View {
    @State private var generatedImage: NSImage?
    @State private var errorMessage: String?
    
    let stableDiffusionModel = StableDiffusionModel() // Instancier le modèle
    
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
                stableDiffusionModel.generateImage(prompt: "Un paysage magnifique") { image in
                    if let image = image {
                        self.generatedImage = image
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = "Échec de la génération de l'image."
                    }
                }
            }
        }
        .padding()
    }
}
