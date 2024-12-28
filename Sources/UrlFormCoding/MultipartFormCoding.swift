import URLRouting
import Parsing
import Foundation

public struct MultipartFormField {
    let name: String
    let filename: String?
    let contentType: String?
    let data: Data
    
    public init(
        name: String,
        filename: String? = nil,
        contentType: String? = nil,
        data: Data
    ) {
        self.name = name
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }
    
    public init(name: String, value: String) {
        self.name = name
        self.filename = nil
        self.contentType = nil
        self.data = value.data(using: .utf8) ?? Data()
    }
}

public struct MultipartFormCoding<Value: Codable>: Conversion {
    public let decoder: UrlFormDecoder
    private let boundary: String
    private let fields: [MultipartFormField]
    
    public init(
        _ type: Value.Type,
        fields: [MultipartFormField],
        decoder: UrlFormDecoder = .init()
    ) {
        self.decoder = decoder
        self.boundary = "Boundary-\(UUID().uuidString)"
        self.fields = fields
    }
    
    public var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    public func apply(_ input: Data) throws -> Value {
        // If Value is Data, return input directly
        if Value.self == Data.self {
            return input as! Value
        }
        
        // Otherwise try to decode using the provided decoder
        do {
            return try decoder.decode(Value.self, from: input)
        } catch {
            throw MultipartFormCodingError.decodingFailed(error)
        }
    }
    
    public func unapply(_ output: Value) -> Data {
        var body = Data()
        
        // Add each field to the multipart form data
        for field in fields {
            // Append boundary
            body.append("--\(boundary)\r\n")
            
            // Add Content-Disposition header
            var disposition = "Content-Disposition: form-data; name=\"\(field.name)\""
            if let filename = field.filename {
                disposition += "; filename=\"\(filename)\""
            }
            body.append("\(disposition)\r\n")
            
            // Add Content-Type if specified
            if let contentType = field.contentType {
                body.append("Content-Type: \(contentType)\r\n")
            }
            
            // Add empty line before content
            body.append("\r\n")
            
            // Add field data
            body.append(field.data)
            body.append("\r\n")
        }
        
        // Final boundary
        body.append("--\(boundary)--\r\n")
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

// MARK: - Conversion Extension
extension Conversion {
    @inlinable
    public static func multipart<Value>(
        _ type: Value.Type,
        fields: [MultipartFormField]
    ) -> MultipartFormCoding<Value> {
        MultipartFormCoding(type, fields: fields)
    }
}
