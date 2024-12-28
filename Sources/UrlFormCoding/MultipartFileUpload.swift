//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import URLRouting
import Parsing
import Foundation

// A ParserPrinter for handling file uploads in multipart form data
public struct MultipartFileUpload: Conversion {
    private let boundary: String
    private let fieldName: String
    private let filename: String
    private let contentType: String
    
    public init(
        fieldName: String = "file",
        filename: String = "file.csv",
        contentType: String = "text/csv"
    ) {
        self.fieldName = fieldName
        self.filename = filename
        self.contentType = contentType
        self.boundary = "Boundary-\(UUID().uuidString)"
    }
    
    public var contentType2: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    public func apply(_ input: Data) throws -> Data {
        input // Parsing not needed for upload
    }
    
    public func unapply(_ data: Data) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(self.contentType)\r\n")
        body.append("\r\n")
        body.append(data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        return body
    }
}

// 3. Add convenience extensions for Data manipulation
private extension Data {
    mutating func appendMultipartFile(
        _ file: FileUpload,
        boundary: String
    ) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.filename)\"\r\n")
        append("Content-Type: \(file.contentType)\r\n")
        append("\r\n")
        append(file.data)
        append("\r\n")
        append("--\(boundary)--\r\n")
    }
    
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// 1. First, create a FileUpload type to encapsulate file metadata
public struct FileUpload {
    let fieldName: String
    let filename: String
    let contentType: String
    let data: Data
    
    public static func csv(
        named fieldName: String = "file",
        filename: String = "file.csv",
        data: Data
    ) -> FileUpload {
        FileUpload(
            fieldName: fieldName,
            filename: filename,
            contentType: "text/csv",
            data: data
        )
    }
}

// Convenience constructors
extension Conversion where Self == MultipartFileUpload {
    public static func csv(
        fieldName: String = "file",
        filename: String = "file.csv"
    ) -> Self {
        .init(
            fieldName: fieldName,
            filename: filename,
            contentType: "text/csv"
        )
    }
}
