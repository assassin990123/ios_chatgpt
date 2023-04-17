//
//  AppConstant.swift
//  chatGPTDemo
//
//  Created by Nand on 24/03/23.
//

import Foundation
struct Constant {
    
    public static let kAppName = "OpenAISwift"
}

struct OpenAISecretKey {    
    public static let SECRETKEY = "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"
}
extension String {
    
    func trime() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }    
}
