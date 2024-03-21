//
//  File.swift
//
//
//  Created by John Mai on 2024/3/21.
//

@testable import Jinja
import XCTest

final class ParseTests: XCTestCase {
    let testStrings: [String: String] = [
        // Text nodes
        "NO_TEMPLATE": "Hello world!"
    ]

    let testParsed: [String: Program] = [
        "NO_TEMPLATE": Program(body: [
            StringLiteral(value: "Hello world!")
        ])
    ]
    func testParse() throws {
        let tokens = try tokenize("Hello world!")
        try print(parse(tokens: tokens))

        for (name, text) in testStrings {
            let tokens = try tokenize(text)
            let parsed = try parse(tokens: tokens)

            XCTAssertNotNil(testParsed[name], "Test case \(name) not found")
            XCTAssertEqual(parsed, testParsed[name], "Test case \(name) failed")
        }
    }
}
