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
        })
    ]

    var tests: [String: (any RuntimeValue...) throws -> Bool] = [
        "boolean": {
            args in
            args[0] is BooleanValue
        },

        "callable": {
            args in
            args[0] is FunctionValue
        },

        "odd": {
            args in
            if let arg = args.first as? NumericValue {
                return arg.value as! Int % 2 != 0
            }
            else {
                throw JinjaError.runtimeError("Cannot apply test 'odd' to type: \(type(of:args.first))")
            }
        },
        "even": { args in
            if let arg = args.first as? NumericValue {
                return arg.value as! Int % 2 == 0
            }
            else {
                throw JinjaError.runtimeError("Cannot apply test 'even' to type: \(type(of:args.first))")
            }
        },
        "false": { args in
            if let arg = args[0] as? BooleanValue {
                return !arg.value
            }
            return false
        },
        "true": { args in
            if let arg = args[0] as? BooleanValue {
                return arg.value
            }
            return false
        },
        "number": { args in
            args[0] is NumericValue
        },
        "integer": { args in
            if let arg = args[0] as? NumericValue {
                return arg.value is Int
            }

            return false
        },
        "iterable": { args in
            args[0] is ArrayValue || args[0] is StringValue
        },
        "lower": { args in
            if let arg = args[0] as? StringValue {
                return arg.value == arg.value.lowercased()
            }

            return false
        },
        "upper": { args in
            if let arg = args[0] as? StringValue {
                return arg.value == arg.value.uppercased()
            }
            return false
        },
        "none": { args in
            args[0] is NullValue
        },
        "defined": { args in
            !(args[0] is UndefinedValue)
        },
        "undefined": { args in
            args[0] is UndefinedValue
        },
        "equalto": { _ in
            throw JinjaError.notSupportError
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

    @discardableResult
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

    @discardableResult
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
            }
            else {
                return UndefinedValue()
            }
        }
        catch {
            return UndefinedValue()
        }
    }
}
