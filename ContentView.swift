import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var generatedImage: NSImage?  // Use NSImage for macOS
    @State private var isGenerating = false
    
    let stableDiffusionModel = StableDiffusionModel() // Instantiate the model
    
    // Function to generate an image with a prompt
    func generateImage() {
        isGenerating = true
        let prompt = "A futuristic cityscape at sunset"  // Example prompt
        
        // Pass 'prompt' directly to the model for image generation
        stableDiffusionModel.generateImage(prompt: prompt) { image in
            if let image = image {
                // Display the generated image
                self.generatedImage = image
            } else {
                print("Error generating the image.")
            }
            isGenerating = false
        }
    }
    
    // Function to save the image
    func saveImage() {
        guard let image = generatedImage else {
            print("No image to save.")
            return
        }
        
        // Ensure the following code runs on the main thread
        DispatchQueue.main.async {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.png]  // Use allowedContentTypes with UTType
            savePanel.nameFieldStringValue = "generated_image.png"
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    // Save the image to the file chosen by the user
                    do {
                        let imageData = image.tiffRepresentation
                        if let bitmapRep = NSBitmapImageRep(data: imageData!) {
                            let imageData = bitmapRep.representation(using: .png, properties: [:])
                            try imageData?.write(to: url)
                            print("Image saved to \(url.path)")
                        }
                    } catch {
                        print("Error saving the image: \(error.localizedDescription)")
                    }
                } else {
                    print("User cancelled the save operation.")
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            if let generatedImage = generatedImage {
                Image(nsImage: generatedImage)  // Display the image with Image from SwiftUI for macOS
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("No image generated.")
                    .padding()
            }
            
            if isGenerating {
                ProgressView("Generating the image...")
                    .padding()
            }
            
            HStack {
                Button(action: {
                    generateImage()
                }) {
                    Text("Generate Image")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    saveImage()
                }) {
                    Text("Save Image")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
