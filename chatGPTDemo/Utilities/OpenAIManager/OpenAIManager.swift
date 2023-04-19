//
//  OpenAIManager.swift
//  OpenAISwift
//
//  Created by Nand on 24/03/23. on 24/03/23.
//

import Foundation
import UIKit

//https://api.openai.com/v1/completions
//https://api.openai.com/v1/images/generations

struct Response: Decodable {
    
    let data: [ImageURL]
}

struct ImageURL: Decodable {
    
    let url: String
}

enum APIError: Error {
    
    case unableToCreateImageURL
    case unableToConvertDataIntoImage
    case unableToCreateURLForURLRequest
}

//MARK:- OpenAIManager
class OpenAIManager {
    
    static let shared = OpenAIManager()
    
    //MakeRequest
    func makeRequest(json: [String: Any], completion: @escaping (String)->()) {
        
        guard let url = URL(string: "https://api.openai.com/v1/completions"),
              let payload = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(OpenAISecretKey.SECRETKEY)", forHTTPHeaderField: "Authorization")
        request.httpBody = payload
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { completion("Error::\(String(describing: error?.localizedDescription))"); return }
            guard let data = data else { completion("Error::Empty data"); return }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            
            if let json = json,
               let choices = json["choices"] as? [[String: Any]],
               let str = choices.first?["text"] as? String {
                print("chioce data is \(choices)")
                completion(str)
            } else {
                completion("Error::nothing returned")
            }
            
        }.resume()
    }
    
    //This method will use to get response in text formate
    func processPrompt(prompt: String, isType: Bool = true, completion: @escaping ((_ reponse: String) -> Void)) {
        
        var jsonPayload = [String : Any]()
        
        if isType == true {
            jsonPayload = [
                "prompt": prompt,
                "model": "text-davinci-003",
                "max_tokens": 2048,
                "temperature": 0.9,
                "top_p" : 1.0,
                "frequency_penalty" : 1.0,
                "presence_penalty" : 1.0
            ] as [String : Any]
        } else {
            jsonPayload = [
                "prompt": prompt,
                "model": "code-davinci-002",
                "max_tokens": 2048
            ] as [String : Any]
        }
        
        print("Parameters: \(jsonPayload)")
        
        self.makeRequest(json: jsonPayload) { [weak self] (str) in
            DispatchQueue.main.async {
                
                print("===>", str.trime())
                completion(str)
            }
        }
    }
    
    //This method will use to get response in image formate
    func fetchImageForPrompt(prompt: String, completion: @escaping ([ImageURL])->()) {
        
        let jsonPayload = [
            "prompt": prompt,
            "n": 1,
            "size": "256x256", // "256x256", "512x512", "1024x1024"
            "response_format" : "url" // "b64_json"
        ] as [String : Any]
        
        print("Parameters: \(jsonPayload)")
        
        guard let url = URL(string: "https://api.openai.com/v1/images/generations"),
              let payload = try? JSONSerialization.data(withJSONObject: jsonPayload) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(OpenAISecretKey.SECRETKEY)", forHTTPHeaderField: "Authorization")
        request.httpBody = payload
        
        print("URL: \(request)")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            let decoder = JSONDecoder()
            let results = try? decoder.decode(Response.self, from: data ?? Data())
            
            print("Data:", results?.data)
            
            let imageURL = results?.data
            print("imageURL:", imageURL)
            completion(imageURL ?? [ImageURL]())
            
        }.resume()
    }
}
