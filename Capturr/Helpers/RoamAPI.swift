//
//  RoamAPI.swift
//  Capturr
//
//  Created by Paul Griffiths on 7/8/25.
//

import Foundation

struct RoamAPIError: LocalizedError {
    let message: String
    let statusCode: Int?
    var errorDescription: String? { message }
}

public enum RoamLocation {
    case dailyNote
    case page(String)
}

class RoamAPI {
    private let graphName: String
    private let apiToken: String
    private let session = URLSession.shared

    init(graphName: String, apiToken: String) {
        self.graphName = graphName
        self.apiToken = apiToken
    }

    func sendNoteBlock(_ content: String, _ location: RoamLocation, nestUnder: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let url = URL(string: "https://append-api.roamresearch.com/api/graph/\(graphName)/append-blocks") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }

        var locationPayload: [String: Any]
        switch location {
        case .dailyNote:
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.dateFormat = "MM-dd-yyyy"
            let dateKey = dateFormatter.string(from: Date())
            locationPayload = [
                "page": [
                    "title": ["daily-note-page": dateKey]
                ]
            ]
        case .page(let title):
            locationPayload = [
                "page": [
                    "title": title
                ]
            ]
        }
        // developer-documentation/page/NO5bYpywn
        if let nest = nestUnder?.trimmingCharacters(in: .whitespacesAndNewlines), !nest.isEmpty {
            locationPayload["nest-under"] = [
                "string": nest
            ]
        }

        let payload: [String: Any] = [
            "location": locationPayload,
            "append-data": [
                ["string": content]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "NoHTTPResponse", code: -2)))
                return
            }
            
            if httpResponse.statusCode == 200 {
                completion(.success(()))
            } else {
                var serverMessage: String? = nil
                if let data = data {
                    if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let msg = obj["message"] as? String, !msg.isEmpty {
                        serverMessage = msg
                    } else if let bodyString = String(data: data, encoding: .utf8), !bodyString.isEmpty {
                        serverMessage = bodyString
                    }
                }
                let message: String
                if let serverMessage = serverMessage {
                    message = "HTTP \(httpResponse.statusCode) - \(serverMessage)"
                } else {
                    message = "HTTP \(httpResponse.statusCode)"
                }
                completion(.failure(RoamAPIError(message: message, statusCode: httpResponse.statusCode)))
            }
        }

        task.resume()
    }

    func sendTodoBlock(_ content: String, _ location: RoamLocation, nestUnder: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        let formatted = "{{[[TODO]]}} \(content)"
        sendNoteBlock(formatted, location, nestUnder: nestUnder, completion: completion)
    }
}
