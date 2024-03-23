//
//  Template.swift
//
//
//  Created by John Mai on 2024/3/23.
//

import Foundation

struct Template {
    var parsed: Program

    init(template: String) throws {
        let tokens = try tokenize(template, options: PreprocessOptions(trimBlocks: true, lstripBlocks: true))
        self.parsed = try parse(tokens: tokens)
    }

    func render(items: [String: Any]) throws -> String {
        var env = Environment()

        _ = try env.set(name: "false", value: false)
        _ = try env.set(name: "true", value: true)
        _ = try env.set(name: "raise_exception", value: { args in throw JinjaError.runtimeError("\(args)") })
        _ = try env.set(name: "range", value: range)

        let interpreter = Interpreter(env: env)
        let result = try interpreter.run(program: self.parsed) as! StringValue

        return result.value
    }
}
