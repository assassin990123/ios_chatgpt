//
//  AppConstant.swift
//  chatGPTDemo
//
//  Created by Nand on 24/03/23.
//

import Foundation
//MARK:- Constant
struct Constant {
    
    public static let kAppName = "OpenAISwift"
}

//MARK:- OpenAISecretKey
struct OpenAISecretKey {
    public static let SECRETKEY = "ENTER-YOUR-SECRETE-KEY-HERE"
}

//MARK:- String Extension
extension String {
    
    func trime() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }    
}
