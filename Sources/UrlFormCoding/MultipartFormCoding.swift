import URLRouting
import Parsing
import Foundation

public struct MultipartFormCoding<Value: Codable>: Conversion {
    public let decoder: UrlFormDecoder
    private let boundary: String

    public init(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init()
    ) {
        self.decoder = decoder
        self.boundary = "Boundary-\(UUID().uuidString)"
    }

    public func apply(_ input: Data) throws -> Value {
        // Decode input using the provided decoder
        do {
            return try decoder.decode(Value.self, from: input)
        } catch {
            throw MultipartFormCodingError.decodingFailed(error)
        }
    }

    public func unapply(_ output: Value) -> Data {
        // Convert output to JSON, then to a dictionary
        guard let jsonData = try? JSONEncoder().encode(output),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any?] else {
            return Data()
        }

        var body = Data()
        for (key, value) in dict {
            guard let value = value else { continue }

            // Append boundary
            body.append("--\(boundary)\r\n".data(using: .utf8)!)

            // Handle different value types
            if let stringValue = value as? String {
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(stringValue)\r\n".data(using: .utf8)!)
            } else if let fileData = value as? Data {
                // Example for handling file uploads (extendable as needed)
                body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key).dat\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
                body.append(fileData)
                body.append("\r\n".data(using: .utf8)!)
            } else {
                // Unsupported type handling
                assertionFailure("Unsupported value type for key: \(key)")
            }
        }

        // Final boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

// MARK: - Custom Error Handling
public enum MultipartFormCodingError: Error {
    case decodingFailed(Error)
    case unsupportedValueType(String)
}

// MARK: - Data Extension for Easier Handling
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

extension Conversion {
    @inlinable
    public static func multipart<Value>(
        _ type: Value.Type,
        decoder: UrlFormDecoder = .init()
    ) -> Self where Self == MultipartFormCoding<Value> {
        .init(type, decoder: decoder)
    }
}
