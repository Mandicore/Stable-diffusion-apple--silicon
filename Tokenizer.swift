//
//  Tokenizer.swift
//  aiproject
//
//  Created by Jossua Figueiras
//
import Foundation

struct Token: Decodable {
    let id: Int
    let content: String
}

class Tokenizer {
    private var vocab: [String: Int]
    private var merges: [String]
    private var specialTokens: [String: Token]
    
    init(vocab: [String: Int], merges: [String], specialTokens: [String: Token]) {
        self.vocab = vocab
        self.merges = merges
        self.specialTokens = specialTokens
    }
    
    func encode(_ text: String, addSpecialTokens: Bool = true) -> [Int] {
        // Basic tokenization logic
        var tokens = text.split(separator: " ").compactMap { vocab[String($0)] }
        
        // Optionally add special tokens
        if addSpecialTokens, let clsToken = specialTokens["cls"], let sepToken = specialTokens["sep"] {
            tokens.insert(clsToken.id, at: 0)
            tokens.append(sepToken.id)
        }
        
        return tokens
    }
}
