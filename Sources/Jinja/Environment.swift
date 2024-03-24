//
//  Environment.swift
//
//
//  Created by John Mai on 2024/3/23.
//

import Foundation

class Environment {
    var parent: Environment?

    var variables: [String: any RuntimeValue] = [
        "namespace": FunctionValue(value: { args, _ in
            if args.count == 0 {
                return ObjectValue(value: [:])
            }

            if args.count != 1 || !(args[0] is ObjectValue) {
                throw JinjaError.runtimeError("`namespace` expects either zero arguments or a single object argument")
            }

            return args[0]
        }),
    ]

    var tests: [String: (any RuntimeValue...) throws -> Bool] = [
        "boolean": {
            args in
            args[0].type == "BooleanValue"
        },

        "callable": {
            args in
            args[0] is FunctionValue
        },

        "odd": {
            args in
            if args[0].type == "NumericValue" {
                throw JinjaError.runtimeError("Cannot apply test 'odd' to type: \(args.first!.type)")
            }

            return (args[0] as! NumericValue).value as! Int % 2 != 0
        },
        "even": { args in
            if args[0].type == "NumericValue" {
                throw JinjaError.runtimeError("Cannot apply test 'even' to type: \(args.first!.type)")
            }
            return (args[0] as! NumericValue).value as! Int % 2 == 0
        },
        "false": { args in
            args[0].type == "BooleanValue" && !(args[0] as! BooleanValue).value
        },
        "true": { args in
            args[0].type == "BooleanValue" && (args[0] as! BooleanValue).value
        },
        "number": { args in
            args[0].type == "NumericValue"
        },
        "integer": { args in
            args[0].type == "NumericValue" && (args[0] as! NumericValue).value is Int
        },
        "iterable": { args in
            args[0] is ArrayValue || args[0] is StringValue
        },
        "lower": { args in
            let str = (args[0] as! StringValue).value
            return args[0].type == "StringValue" && str == str.lowercased()
        },
        "upper": { args in
            let str = (args[0] as! StringValue).value
            return args[0].type == "StringValue" && str == str.uppercased()
        },
        "none": { args in
            args[0].type == "NullValue"
        },
        "defined": { args in
            args[0].type != "UndefinedValue"
        },
        "undefined": { args in
            args[0].type != "UndefinedValue"
        },
        "equalto": { _ in
//            args[0].value == args[1].value
            false
        },
    ]

    init(parent: Environment? = nil) {
        self.parent = parent
    }

    func isFunction<T>(_ value: Any, functionType: T.Type) -> Bool {
        value is T
    }

    func convertToRuntimeValues(input: Any) throws -> any RuntimeValue {
        switch input {
        case let value as Bool:
            return BooleanValue(value: value)
        case let values as [any Numeric]:
            var items: [any RuntimeValue] = []
            for value in values {
                try items.append(self.convertToRuntimeValues(input: value))
            }
            return ArrayValue(value: items)
        case let value as any Numeric:
            return NumericValue(value: value)
        case let value as String:
            return StringValue(value: value)
        case let fn as (String) throws -> Void:
            return FunctionValue { args, _ in
                var arg = ""
                switch args[0].value {
                case let value as String:
                    arg = value
                case let value as Bool:
                    arg = String(value)
                default:
                    throw JinjaError.runtimeError("Unknown arg type:\(type(of: args[0].value))")
                }

                try fn(arg)
                return NullValue()
            }
        case let fn as (Bool) throws -> Void:
            return FunctionValue { args, _ in
                try fn(args[0].value as! Bool)
                return NullValue()
            }
        case let fn as (Int, Int?, Int) -> [Int]:
            return FunctionValue { args, _ in
                let result = fn(args[0].value as! Int, args[1].value as? Int, args[2].value as! Int)
                return try self.convertToRuntimeValues(input: result)
            }
        case let values as [Any]:
            var items: [any RuntimeValue] = []
            for value in values {
                try items.append(self.convertToRuntimeValues(input: value))
            }
            return ArrayValue(value: items)
        case let dictionary as [String: String]:
            var object: [String: any RuntimeValue] = [:]

            for (key, value) in dictionary {
                object[key] = StringValue(value: value)
            }

            return ObjectValue(value: object)
        default:
            throw JinjaError.runtimeError("Cannot convert to runtime value: \(input) type:\(type(of: input))")
        }
    }

    func set(name: String, value: Any) throws -> any RuntimeValue {
        try self.declareVariable(name: name, value: self.convertToRuntimeValues(input: value))
    }

    func declareVariable(name: String, value: any RuntimeValue) throws -> any RuntimeValue {
        if self.variables.contains(where: { $0.0 == name }) {
            throw JinjaError.syntaxError("Variable already declared: \(name)")
        }

        self.variables[name] = value

        return value
    }

    func setVariable(name: String, value: any RuntimeValue) throws -> any RuntimeValue {
        self.variables[name] = value
        return value
    }

    func resolve(name: String) throws -> Self {
        if self.variables.contains(where: { $0.0 == name }) {
            return self
        }

        if let parent {
            return try parent.resolve(name: name) as! Self
        }

        throw JinjaError.runtimeError("Unknown variable: \(name)")
    }

    func lookupVariable(name: String) -> any RuntimeValue {
        do {
            if let value = try self.resolve(name: name).variables[name] {
                return value
            } else {
                return UndefinedValue()
            }
        } catch {
            return UndefinedValue()
        }
    }
}
