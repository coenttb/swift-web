//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 05/01/2025.
//

import Foundation
import Testing
@testable import UrlFormCoding

@Suite("URLFormCoding Tests")
struct URLFormCodingTests {
    // Test structures
    struct SimpleBooleanModel: Codable, Equatable {
        let isActive: Bool
        let isEnabled: Bool?
    }

    struct NestedBooleanModel: Codable, Equatable {
        let settings: Settings

        struct Settings: Codable, Equatable {
            let isEnabled: Bool
            let features: Features
        }

        struct Features: Codable, Equatable {
            let debug: Bool
            let beta: Bool?
        }
    }

    @Test("Simple boolean values encode correctly")
    func testSimpleBooleanEncoding() throws {
        // Given
        let model = SimpleBooleanModel(isActive: true, isEnabled: false)
        let coding = FormCoding(SimpleBooleanModel.self)

        // When
        let encodedData = try coding.unapply(model)
        let encodedString = String(data: encodedData, encoding: .utf8)

        // Then
        #expect(encodedString == "isActive=true&isEnabled=false")
    }

    @Test("Simple boolean values decode correctly")
    func testSimpleBooleanDecoding() throws {
        // Given
        let input = "isActive=true&isEnabled=false".data(using: .utf8)!
        let coding = FormCoding(SimpleBooleanModel.self)

        // When
        let decoded = try coding.apply(input)

        // Then
        #expect(decoded == SimpleBooleanModel(isActive: true, isEnabled: false))
    }

    @Test("Optional boolean values encode correctly")
    func testOptionalBooleanEncoding() throws {
        // Given
        let modelWithNil = SimpleBooleanModel(isActive: true, isEnabled: nil)
        let coding = FormCoding(SimpleBooleanModel.self)

        // When
        let encodedData = try coding.unapply(modelWithNil)
        let encodedString = String(data: encodedData, encoding: .utf8)

        // Then
        #expect(encodedString == "isActive=true")
    }

    @Test("Nested boolean values encode correctly (ignoring key order)")
    func testNestedBooleanEncoding() throws {
        // Given
        let model = NestedBooleanModel(
            settings: .init(
                isEnabled: true,
                features: .init(debug: true, beta: false)
            )
        )
        let coding = FormCoding(NestedBooleanModel.self)

        let encodedData = try coding.unapply(model)
        let encodedString = try #require(String(data: encodedData, encoding: .utf8))

        let actualParts = encodedString.split(separator: "&").sorted()
        let expectedParts = "settings[isEnabled]=true&settings[features][debug]=true&settings[features][beta]=false"
            .split(separator: "&")
            .sorted()

        #expect(
            actualParts == expectedParts,
            """
            The encoded string doesn't match (ignoring key order).
            Got:      \(encodedString)
            Expected: \(expectedParts.joined(separator: "&"))
            """
        )
    }

    @Test("Nested boolean values decode correctly (relaxed)")
    func testNestedBooleanDecoding() throws {
        // Given
        let inputString = "settings[isEnabled]=true&settings[features][debug]=true&settings[features][beta]=false"
        let inputData = try #require(inputString.data(using: .utf8))
        let coding = FormCoding(NestedBooleanModel.self)

        // When
        let decoded = try coding.apply(inputData)

        // Then
        #expect(decoded.settings.isEnabled == true, "Expected settings.isEnabled to decode as true.")
        #expect(decoded.settings.features.debug == true, "Expected settings.features.debug to decode as true.")
        #expect(decoded.settings.features.beta == false, "Expected settings.features.beta to decode as false.")
    }

    @Test("Various boolean representations decode correctly")
    func testBooleanEdgeCases() throws {
        struct BooleanEdgeCases: Codable, Equatable {
            let value: Bool
        }

        let coding = FormCoding(BooleanEdgeCases.self)

        // Test truthy values
        let truthyCases = ["true", "TRUE", "True", "1"]
        for truthyCase in truthyCases {
            let input = "value=\(truthyCase)".data(using: .utf8)!
            let decoded = try coding.apply(input)
            #expect(decoded.value == true, "Failed to decode truthy value: \(truthyCase)")
        }

        // Test falsy values
        let falsyCases = ["false", "FALSE", "False", "0"]
        for falsyCase in falsyCases {
            let input = "value=\(falsyCase)".data(using: .utf8)!
            let decoded = try coding.apply(input)
            #expect(decoded.value == false, "Failed to decode falsy value: \(falsyCase)")
        }
    }

    @Test("Invalid boolean values throw error")
    func testInvalidBooleanDecoding() throws {
        struct BooleanModel: Codable {
            let value: Bool
        }

        let coding = FormCoding(BooleanModel.self)
        let invalidInput = "value=invalid".data(using: .utf8)!

        #expect(throws: Error.self) {
            _ = try coding.apply(invalidInput)
        }
    }

    @Test("Array of boolean values encode and decode correctly")
    func testArrayOfBooleans() throws {
        struct BooleanArrayModel: Codable, Equatable {
            let flags: [Bool]
        }

        // Given
        let model = BooleanArrayModel(flags: [true, false, true])
        let coding = FormCoding(BooleanArrayModel.self)

        // When
        let encodedData = try coding.unapply(model)
        let encodedString = String(data: encodedData, encoding: .utf8)

        // Then
        #expect(encodedString == "flags[0]=true&flags[1]=false&flags[2]=true")

        // Test decoding
        let decoded = try coding.apply(encodedData)
        #expect(decoded == model)
    }
}
