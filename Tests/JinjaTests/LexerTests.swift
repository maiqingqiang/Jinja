//
//  LexerTests.swift
//
//
//  Created by John Mai on 2024/3/20.
//

@testable import Jinja
import XCTest
final class LexerTests: XCTestCase {
    let testStrings: [String: String] = [
        "NO_TEMPLATE": "Hello world!",
        "TEXT_NODES": "0{{ 'A' }}1{{ 'B' }}{{ 'C' }}2{{ 'D' }}3",
        "LOGICAL_AND": "{{ true and true }}{{ true and false }}{{ false and true }}{{ false and false }}",
    ]

    let testParsed: [String: [Token]] = [
        "NO_TEMPLATE": [Token(value: "Hello world!", type: .text)],
        "TEXT_NODES": [
            Token(value: "0", type: .text),
            Token(value: "{{", type: .openExpression),
            Token(value: "A", type: .stringLiteral),
            Token(value: "}}", type: .closeExpression),
            Token(value: "1", type: .text),
            Token(value: "{{", type: .openExpression),
            Token(value: "B", type: .stringLiteral),
            Token(value: "}}", type: .closeExpression),
            Token(value: "{{", type: .openExpression),
            Token(value: "C", type: .stringLiteral),
            Token(value: "}}", type: .closeExpression),
            Token(value: "2", type: .text),
            Token(value: "{{", type: .openExpression),
            Token(value: "D", type: .stringLiteral),
            Token(value: "}}", type: .closeExpression),
            Token(value: "3", type: .text),
        ],
        "LOGICAL_AND": [
            Token(value: "{{", type: .openExpression),
            Token(value: "true", type: .booleanLiteral),
            Token(value: "and", type: .and),
            Token(value: "true", type: .booleanLiteral),
            Token(value: "}}", type: .closeExpression),
            Token(value: "{{", type: .openExpression),
            Token(value: "true", type: .booleanLiteral),
            Token(value: "and", type: .and),
            Token(value: "false", type: .booleanLiteral),
            Token(value: "}}", type: .closeExpression),
            Token(value: "{{", type: .openExpression),
            Token(value: "false", type: .booleanLiteral),
            Token(value: "and", type: .and),
            Token(value: "true", type: .booleanLiteral),
            Token(value: "}}", type: .closeExpression),
            Token(value: "{{", type: .openExpression),
            Token(value: "false", type: .booleanLiteral),
            Token(value: "and", type: .and),
            Token(value: "false", type: .booleanLiteral),
            Token(value: "}}", type: .closeExpression),
        ],
    ]

    func testTokenize() throws {
        for (name, text) in testStrings {
            let tokens = try tokenize(text)
            XCTAssertNotNil(testParsed[name], "Test case \(name) not found")
            XCTAssertEqual(tokens, testParsed[name])
            for token in tokens {
                print("type: \(token.type.rawValue), value: \(token.value)")
            }
        }
    }

    func testIsWhile() {
        XCTAssertTrue(isWhile(char: " "))
        XCTAssertFalse(isWhile(char: "a"))
    }
}
