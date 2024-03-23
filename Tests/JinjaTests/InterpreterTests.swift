//
//  InterpreterTests.swift
//
//
//  Created by John Mai on 2024/3/23.
//

@testable import Jinja
import XCTest

let exampleIfTemplate = "<div>\n    {% if True %}\n        yay\n    {% endif %}\n</div>"
let exampleForTemplate = "{% for item in seq %}\n    {{ item }}\n{% endfor %}"
let seq = [1, 2, 3, 4, 5, 6, 7, 8, 9]

final class InterpreterTests: XCTestCase {
    struct Test {
        let template: String
        let data: [String: Any]
        var options: PreprocessOptions = .init()
        let target: String
    }

    let tests: [Test] = [
        Test(
            template: exampleIfTemplate,
            data: [:],
            target: "<div>\n    \n        yay\n    \n</div>"
        ),
        Test(
            template: exampleIfTemplate,
            data: [:],
            options: .init(lstripBlocks: true),
            target: "<div>\n\n        yay\n\n</div>"
        ),
        Test(
            template: exampleIfTemplate,
            data: [:],
            options: .init(trimBlocks: true),
            target: "<div>\n            yay\n    </div>"
        ),
        Test(
            template: exampleIfTemplate,
            data: [:],
            options: .init(trimBlocks: true, lstripBlocks: true),
            target: "<div>\n        yay\n</div>"
        ),
        Test(
            template: exampleForTemplate,
            data: [
                "seq": seq
            ],
            target: "\n    1\n\n    2\n\n    3\n\n    4\n\n    5\n\n    6\n\n    7\n\n    8\n\n    9\n"
        )
    ]

    func testRender() throws {
        for test in tests {
            let env = Environment()
            _ = try env.set(name: "True", value: true)

            for (key, value) in test.data {
                _ = try env.set(name: key, value: value)
            }

            let tokens = try tokenize(test.template, options: test.options)
            let parsed = try parse(tokens: tokens)
            let interpreter = Interpreter(env: env)
            let result = try interpreter.run(program: parsed).value as! String

            print("template ->> \(test.template.debugDescription)")
            print("result ->> \(result.debugDescription) \n\n")

            XCTAssertEqual(result.debugDescription, test.target.debugDescription)
        }
    }
}
