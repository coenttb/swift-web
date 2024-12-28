import Foundation
import UrlFormEncoding
import URLRouting

extension UrlFormDecoder {
  @MainActor public static let `default`: UrlFormDecoder = {
        let decoder = UrlFormDecoder()
        decoder.parsingStrategy = .bracketsWithIndices
        return decoder
    }()
}

extension DateFormatter {
  @MainActor public static let form: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension URLRouting.Field {
    public static func contentType(_ type: () -> Value) -> Self {
        Field("Content-Type") {
            type()
        }
    }
}
