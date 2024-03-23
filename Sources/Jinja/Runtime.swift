//
//  Runtime.swift
//
//
//  Created by John Mai on 2024/3/22.
//

import Foundation

protocol RuntimeValue {
    associatedtype T
    var type: String { get }
    var value: T { get set }

    var builtins: [(String, any RuntimeValue)] { get set }
}

extension RuntimeValue {
    func bool() -> BooleanValue {
        BooleanValue(value: true)
    }
}

struct NumericValue: RuntimeValue {
    let type: String = "NumericValue"
    var value: any Numeric
    var builtins: [(String, any RuntimeValue)] = []
}

struct BooleanValue: RuntimeValue {
    let type: String = "BooleanValue"
    var value: Bool
    var builtins: [(String, any RuntimeValue)] = []
}

struct NullValue: RuntimeValue {
    let type: String = "NullValue"
    var value: (any RuntimeValue)?
    var builtins: [(String, any RuntimeValue)] = []
}

struct UndefinedValue: RuntimeValue {
    let type: String = "UndefinedValue"
    var value: (any RuntimeValue)?
    var builtins: [(String, any RuntimeValue)] = []
}

struct ArrayValue: RuntimeValue {
    let type: String = "ArrayValue"
    var value: [any RuntimeValue]
    var builtins: [(String, any RuntimeValue)] = []

    init(value: [any RuntimeValue]) {
        self.value = value
        self.builtins = [
            (
                "length",
                FunctionValue(value: { _, _ in
                    NumericValue(value: value.count)
                })
            ),
        ]
    }
}

struct TupleValue: RuntimeValue {
    let type: String = "TupleValue"
    var value: ArrayValue
    var builtins: [(String, any RuntimeValue)] = []
}

struct ObjectValue: RuntimeValue {
    let type: String = "BooleanValue"
    var value: [String: any RuntimeValue]
    var builtins: [(String, any RuntimeValue)]

    init(value: [String: any RuntimeValue]) {
        self.value = value
        self.builtins = [
            (
                "get",
                FunctionValue(value: { args, _ in
                    if let key = args[0] as? StringValue {
                        if let value = value.first(where: { $0.0 == key.value }) {
                            return value
                        } else if args.count > 1 {
                            return args[1]
                        } else {
                            return NullValue()
                        }
                    } else {
                        throw JinjaError.runtimeError("Object key must be a string: got \(args[0].type)")
                    }
                })
            ),
            (
                "items",
                FunctionValue(value: { _, _ in
                    var items: [ArrayValue] = []
                    for (k, v) in value {
                        items.append(ArrayValue(value: [
                            StringValue(value: k),
                            v,
                        ]))
                    }
                    return items
                })
            ),
        ]
    }
}

struct FunctionValue: RuntimeValue {
    let type: String = "FunctionValue"
    var value: ([any RuntimeValue], Environment) throws -> Any
    var builtins: [(String, any RuntimeValue)] = []
}

struct StringValue: RuntimeValue {
    let type: String = "StringValue"
    var value: String
    var builtins: [(String, any RuntimeValue)]

    init(value: String) {
        self.value = value
        self.builtins = [
            (
                "upper",
                FunctionValue(value: { _, _ in
                    StringValue(value: value.uppercased())
                })
            ),
            (
                "lower",
                FunctionValue(value: { _, _ in
                    StringValue(value: value.lowercased())
                })
            ),
            (
                "strip",
                FunctionValue(value: { _, _ in
                    StringValue(value: value.trimmingCharacters(in: .whitespacesAndNewlines))
                })
            ),
            (
                "title",
                FunctionValue(value: { _, _ in
                    StringValue(value: value.capitalized)
                })
            ),
            (
                "length",
                FunctionValue(value: { _, _ in
                    NumericValue(value: value.count)
                })
            ),
        ]
    }
}

struct Interpreter {
    var global: Environment

    init(env: Environment?) {
        self.global = env ?? Environment()
    }

    func run(program: Program) throws -> any RuntimeValue {
        try self.evaluate(statement: program, environment: self.global)
    }

    func evaluateBlock(statements: [Statement], environment: Environment) throws -> StringValue {
        var result = ""
        for statement in statements {
            let lastEvaluated = try self.evaluate(statement: statement, environment: environment)

            if lastEvaluated.type != "NullValue", lastEvaluated.type != "UndefinedValue" {
                if let value = lastEvaluated.value as? String {
                    result += value
                } else {
                    switch lastEvaluated.value {
                    case let value as Int:
                        result += String(value)
                    default: break
                    }
                }
            }
        }

        return StringValue(value: result)
    }

    func evalProgram(program: Program, environment: Environment) throws -> StringValue {
        try self.evaluateBlock(statements: program.body, environment: environment)
    }

    func evaluateSet(node: Set, environment: Environment) throws -> NullValue {
        let rhs = try self.evaluate(statement: node.value, environment: environment)
        if node.assignee.type == "Identifier" {
            let identifier = node.assignee as! Identifier
//            environment.variables.append((identifier.name, rhs))
        } else {
            throw JinjaError.runtimeError("Invalid assignee type: \(node.assignee.type)")
        }

        return NullValue()
    }

    func evaluateIf(node: If, environment: Environment) throws -> StringValue {
        let test = try self.evaluate(statement: node.test, environment: environment)

        return try self.evaluateBlock(statements: test.bool().value ? node.body : node.alternate, environment: environment)
    }

    func evaluateIdentifier(node: Identifier, environment: Environment) throws -> any RuntimeValue {
        environment.lookupVariable(name: node.value)
    }

    func evaluateFor(node: For, environment: Environment) throws -> any RuntimeValue {
        let scope = Environment(parent: environment)

        let iterable = try self.evaluate(statement: node.iterable, environment: scope)
        var result = ""
        if let iterable = iterable as? ArrayValue {
            for i in 0 ..< iterable.value.count {
                let loop: [String: any RuntimeValue] = [
                    "index": NumericValue(value: i + 1),
                    "index0": NumericValue(value: i),
                    "revindex": NumericValue(value: iterable.value.count - i),
                    "revindex0": NumericValue(value: iterable.value.count - i - 1),
                    "first": BooleanValue(value: i == 0),
                    "last": BooleanValue(value: i == iterable.value.count - 1),
                    "length": NumericValue(value: iterable.value.count),
                    "previtem": i > 0 ? iterable.value[i - 1] : UndefinedValue(),
                    "nextitem": i < iterable.value.count - 1 ? iterable.value[i + 1] : UndefinedValue(),
                ]

                _ = try scope.setVariable(name: "loop", value: ObjectValue(value: loop))

                let current = iterable.value[i]

                switch node.loopvar {
                case .identifier(let identifier):
                    _ = try scope.setVariable(name: identifier.value, value: current)
                case .tupleLiteral(let tupleLiteral):
                    // TODO:
                    if current.type != "ArrayValue" {
                        throw JinjaError.runtimeError("Cannot unpack non-iterable type: \(current.type)")
                    }

                    let c = current as! ArrayValue

                    if tupleLiteral.value.count != c.value.count {
                        throw JinjaError.runtimeError("Too \(tupleLiteral.value.count > c.value.count ? "few" : "many") items to unpack")
                    }

                    for j in 0 ..< tupleLiteral.value.count {
                        if tupleLiteral.value[j].type != "Identifier" {
                            throw JinjaError.runtimeError("Cannot unpack non-identifier type: \(tupleLiteral.value[j].type)")
                        }
                        _ = try scope.setVariable(name: (tupleLiteral.value[j] as! Identifier).value, value: c.value[j])
                    }
                }

                let evaluated = try self.evaluateBlock(statements: node.body, environment: scope)
                result += evaluated.value
            }
        } else {
            throw JinjaError.runtimeError("Expected iterable type in for loop: got \(iterable.type)")
        }

        return StringValue(value: result)
    }

    func evaluate(statement: Statement?, environment: Environment) throws -> any RuntimeValue {
        if let statement {
            switch statement.type {
            case "Program":
                return try self.evalProgram(program: statement as! Program, environment: environment)
            case "If":
                return try self.evaluateIf(node: statement as! If, environment: environment)
            case "StringLiteral":
                return StringValue(value: (statement as! StringLiteral).value)
//            case "Set":
//                return try self.evaluateSet(set: statement as! Set, environment: environment)
            case "For":
                return try self.evaluateFor(node: statement as! For, environment: environment)
            case "Identifier":
                return try self.evaluateIdentifier(node: statement as! Identifier, environment: environment)
            default:
                throw JinjaError.runtimeError("Unknown node type: \(statement.type)")
            }
        } else {
            return UndefinedValue()
        }
    }
}
