import CoreML
import Foundation
import AppKit

class StableDiffusionModel {
    private var textEncoder: MLModel
    private var unet: MLModel
    private var vaeDecoder: MLModel
    
    init() {
        guard let textEncoderURL = Bundle.main.url(forResource: "stable_diffusion_text_encoder", withExtension: "mlmodelc"),
              let unetURL = Bundle.main.url(forResource: "stable_diffusion_unet", withExtension: "mlmodelc"),
              let vaeDecoderURL = Bundle.main.url(forResource: "stable_diffusion_vae_decoder", withExtension: "mlmodelc") else {
            fatalError("CoreML models could not be loaded.")
        }
        
        do {
            self.textEncoder = try MLModel(contentsOf: textEncoderURL)
            self.unet = try MLModel(contentsOf: unetURL)
            self.vaeDecoder = try MLModel(contentsOf: vaeDecoderURL)
        } catch {
            fatalError("Error loading CoreML models: \(error.localizedDescription)")
        }
    }
    
    func generateImage(prompt: String, completion: @escaping (NSImage?) -> Void) {
        let width = 512
        let height = 512
        
        guard let encodedText = encodeText(prompt: prompt) else {
            completion(nil)
            return
        }
        
        print("Encoded Text: \(encodedText)") // Debug print
        
        let latents = generateLatents(from: encodedText, width: width, height: height)
        
        print("Generated Latents: \(latents)") // Debug print
        
        let pixels = decodeLatentsToPixels(latents: latents, width: width, height: height)
        
        print("Decoded Pixels: \(pixels)") // Debug print
        
        do {
            let imageData = try createImage(from: pixels, width: width, height: height)
            let nsImage = NSImage(data: imageData)
            print("Image generation completed successfully.") // Console message
            completion(nsImage)
        } catch {
            print("Error generating the image: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    private func encodeText(prompt: String) -> MLMultiArray? {
        guard let textInput = try? MLMultiArray(shape: [1, 77], dataType: .float32) else {
            print("Error initializing MLMultiArray.")
            return nil
        }
        
        for i in 0..<textInput.count {
            textInput[i] = 0
        }
        
        guard let modelInput = try? MLDictionaryFeatureProvider(dictionary: ["text_input": textInput]) else {
            return nil
        }
        
        do {
            let modelOutput = try textEncoder.prediction(from: modelInput)
            if let encoderHiddenStates = modelOutput.featureValue(for: "last_hidden_state")?.multiArrayValue {
                return encoderHiddenStates
            } else {
                print("last_hidden_state is missing in the output.")
                return nil
            }
        } catch {
            print("Error encoding the text: \(error.localizedDescription)")
            return nil
        }
    }
    private func generateLatents(from encodedText: MLMultiArray, width: Int, height: Int) -> [Float] {
        var latents = [Float](repeating: 0.0, count: width * height * 3)

        // Maximized affine transformation
        let alpha: Float = 1.0
        let beta: Float = 1.0

        for i in 0..<latents.count {
            let encodedValue = encodedText[i % encodedText.count].floatValue
            latents[i] = alpha * encodedValue + beta
        }

        return latents
    }
    private func decodeLatentsToPixels(latents: [Float], width: Int, height: Int) -> [UInt8] {
        let pixelCount = width * height * 3
        var pixels = [UInt8](repeating: 0, count: pixelCount)
        
        for i in 0..<pixelCount {
            let normalizedValue = (latents[i] + 1.0) / 2.0
            let clampedValue = max(0.0, min(1.0, normalizedValue))
            pixels[i] = UInt8(clampedValue * 255)
        }
        
        return pixels
    }
    
    private func createImage(from pixels: [UInt8], width: Int, height: Int) throws -> Data {
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 3, // 3 channels for RGB
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 3,
            bitsPerPixel: 24
        ) else {
            throw NSError(domain: "StableDiffusion", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap representation"])
        }
        
        guard let pixelData = bitmapRep.bitmapData else {
            throw NSError(domain: "StableDiffusion", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Unable to get bitmap pixel data"])
        }
        
        for index in 0..<pixels.count {
            pixelData[index] = pixels[index]
        }
        
        guard let imageData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "StableDiffusion", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Unable to create image data"])
        }
        
        return imageData
    }
}
