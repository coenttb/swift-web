import Foundation
import Testing
@testable import UrlFormCoding
import URLRouting

@Suite("MultipartFileUpload Tests")
struct MultipartFileUploadTests {

    @Test("Should correctly initialize with default CSV settings")
    func testDefaultCSVInitialization() throws {
        let upload = MultipartFileUpload.csv()

        #expect(upload.contentType.hasPrefix("multipart/form-data; boundary="))
        #expect(upload.contentType.contains("Boundary-"))
    }

    @Test("Should initialize with custom field name and filename")
    func testCustomFieldNameAndFilename() throws {
        let upload = MultipartFileUpload.csv(
            fieldName: "customField",
            filename: "custom.csv"
        )

        let formattedString = try! upload.unapply("test".data(using: .utf8)!)
        let content = String(data: formattedString, encoding: .utf8)!

        #expect(content.contains("name=\"customField\""))
        #expect(content.contains("filename=\"custom.csv\""))
    }

    @Test("Should validate all supported image types")
    func testImageTypeValidation() throws {
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let jpegUpload = MultipartFileUpload.jpeg()
        #expect(try! jpegUpload.apply(jpegData) == jpegData)

        let pngData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        let pngUpload = MultipartFileUpload(
            fieldName: "file",
            filename: "test.png",
            fileType: .image(.png)
        )
        #expect(try! pngUpload.apply(pngData) == pngData)

        let gifData = "GIF89a".data(using: .ascii)!
        let gifUpload = MultipartFileUpload(
            fieldName: "file",
            filename: "test.gif",
            fileType: .image(.gif)
        )
        #expect(try! gifUpload.apply(gifData) == gifData)
    }

    @Test("Should validate PDF format with correct magic numbers")
    func testPDFValidation() throws {
        let validPDFData = "%PDF-1.5".data(using: .utf8)!
        let upload = MultipartFileUpload.pdf()

        #expect(try! upload.apply(validPDFData) == validPDFData)

        let invalidPDFData = "Not a PDF".data(using: .utf8)!
        #expect(throws: MultipartFileUpload.MultipartError.contentMismatch(
            expected: "application/pdf",
            detected: nil
        )) {
            try upload.apply(invalidPDFData)
        }
    }

    @Test("Should handle various error conditions")
    func testErrorHandling() throws {
        let upload = MultipartFileUpload.csv()

        #expect(throws: MultipartFileUpload.MultipartError.emptyData) {
            try upload.apply(Data())
        }

        let largeData = Data(repeating: 0, count: MultipartFileUpload.maxFileSize + 1)
        #expect(throws: MultipartFileUpload.MultipartError.fileTooLarge(
            size: MultipartFileUpload.maxFileSize + 1,
            maxSize: MultipartFileUpload.maxFileSize
        )) {
            try upload.apply(largeData)
        }

        let customSizeUpload = MultipartFileUpload.csv(maxSize: 100)
        let oversizedData = Data(repeating: 0, count: 101)
        #expect(throws: MultipartFileUpload.MultipartError.fileTooLarge(
            size: 101,
            maxSize: 100
        )) {
            try customSizeUpload.apply(oversizedData)
        }
    }

    @Test("Should generate valid and unique boundaries")
    func testBoundaryGeneration() throws {
        let uploads = (0..<10).map { _ in MultipartFileUpload.csv() }
        let boundaries = uploads.map { upload in
            upload.contentType.split(separator: "=").last!
        }

        let uniqueBoundaries = Set(boundaries)
        #expect(boundaries.count == uniqueBoundaries.count)

        for boundary in boundaries {
            #expect(boundary.hasPrefix("Boundary-"))
            #expect(boundary.count == 24)
        }
    }

    @Test("Should correctly process and preserve UTF-8 content")
    func testUTF8ContentPreservation() throws {
        let specialChars = "Hello, 世界! 🌍"
        let data = specialChars.data(using: .utf8)!
        let upload = MultipartFileUpload.csv()

        let processed = try upload.unapply(data)
        let result = String(data: processed, encoding: .utf8)!

        #expect(result.contains(specialChars))
    }

    @Test("Should handle multiple file types with correct content types")
    func testMultipleFileTypes() throws {
        let testCases: [(MultipartFileUpload, String, Data)] = [
            (MultipartFileUpload.csv(), "text/csv", "test,data".data(using: .utf8)!),
            (MultipartFileUpload.pdf(), "application/pdf", "%PDF-1.5\ntest".data(using: .utf8)!),
            (MultipartFileUpload.excel(), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "test".data(using: .utf8)!),
            (MultipartFileUpload.jpeg(), "image/jpeg", Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]))
        ]

        for (upload, expectedContentType, testData) in testCases {
            let formattedData = try upload.unapply(testData)

            let headerData = formattedData.prefix(while: { $0 != 0xFF })

            guard let headerString = String(data: headerData, encoding: .utf8) else {
                throw MultipartFileUpload.MultipartError.encodingError
            }

            #expect(headerString.contains("Content-Type: \(expectedContentType)"))
        }
    }

    @Test("Should correctly initialize FileUpload struct")
    func testFileUploadStruct() throws {
        let testData = "test,data".data(using: .utf8)!

        let csvUpload = FileUpload.csv(
            named: "csvFile",
            filename: "test.csv",
            data: testData
        )

        #expect(csvUpload.fieldName == "csvFile")
        #expect(csvUpload.filename == "test.csv")
        #expect(csvUpload.data == testData)
        #expect(csvUpload.maxSize == MultipartFileUpload.maxFileSize)

        let pdfUpload = FileUpload.pdf(
            named: "pdfFile",
            filename: "test.pdf",
            data: testData
        )

        #expect(pdfUpload.fieldName == "pdfFile")
        #expect(pdfUpload.filename == "test.pdf")
        #expect(pdfUpload.data == testData)
    }
}
