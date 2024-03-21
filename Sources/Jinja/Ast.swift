//
//  Ast.swift
//
//
//  Created by John Mai on 2024/3/20.
//

import Foundation

class Statement: Equatable {
    static func == (lhs: Statement, rhs: Statement) -> Bool {
        lhs.type == rhs.type
    }

    var type: String = "Statement"
}

class Program: Statement {
    static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.body == rhs.body && lhs.type == rhs.type
    }

    var body: [Statement]

    init(body: [Statement] = []) {
        self.body = body
        super.init()
        self.type = "Program"
    }
}

class Expression: Statement {
    override init() {
        super.init()
        self.type = "Expression"
    }
}

class Literal<T>: Expression {
    var value: T
    override init() {
        fatalError("Literal<T> is an abstract class and should not be instantiated directly.")
    }

    init(value: T) {
        self.value = value
        super.init()
        self.type = "Literal"
    }
}

class StringLiteral: Literal<String> {
    override init(value: String) {
        super.init(value: value)
        self.type = "StringLiteral"
    }
    
    static func == (lhs: StringLiteral, rhs: StringLiteral) -> Bool {
        lhs.value == rhs.value && lhs.type == rhs.type
    }
}

class NumericLiteral: Literal<Numeric> {
    override init(value: any Numeric) {
        super.init(value: value)
        self.type = "NumericLiteral"
    }
}

class BoolLiteral: Literal<Bool> {
    override init(value: Bool) {
        super.init(value: value)
        self.type = "BoolLiteral"
    }
}

class ArrayLiteral: Literal<[Expression]> {
    override init(value: [Expression]) {
        super.init(value: value)
        self.type = "ArrayLiteral"
    }
}

class TupleLiteral: Literal<[Expression]> {
    override init(value: [Expression]) {
        super.init(value: value)
        self.type = "TupleLiteral"
    }
}

class ObjectLiteral: Literal<[(Expression, Expression)]> {
    override init(value: [(Expression, Expression)]) {
        super.init(value: value)
        self.type = "TupleLiteral"
    }
}

class SetStatement: Statement {
    var assignee: Expression
    var value: Expression

    init(assignee: Expression, value: Expression) {
        self.assignee = assignee
        self.value = value
        super.init()
        self.type = "Set"
    }
}

class If: Statement {
    var test: Expression
    var body: [Statement]
    var alternate: [Statement]

    init(test: Expression, body: [Statement], alternate: [Statement]) {
        self.test = test
        self.body = body
        self.alternate = alternate
        super.init()
        self.type = "If"
    }
}

class Identifier: Expression {
    var value: String

    init(value: String) {
        self.value = value
        super.init()
        self.type = "Identifier"
    }
}

enum Loopvar {
    case identifier(Identifier)
    case tupleLiteral(TupleLiteral)
}

class For: Statement {
    var loopvar: Loopvar
    var iterable: Expression
    var body: [Statement]

    init(
        loopvar: Loopvar,
        iterable: Expression,
        body: [Statement]
    ) {
        self.loopvar = loopvar
        self.iterable = iterable
        self.body = body
        super.init()
        self.type = "For"
    }
}

class MemberExpression: Expression {
    var object: Expression
    var property: Expression
    var computed: Bool

    init(
        object: Expression,
        property: Expression,
        computed: Bool
    ) {
        self.object = object
        self.property = property
        self.computed = computed
        super.init()
        self.type = "MemberExpression"
    }
}

class CallExpression: Expression {
    var callee: Expression
    var args: [Expression]

    init(
        callee: Expression,
        args: [Expression]
    ) {
        self.callee = callee
        self.args = args
        super.init()
        self.type = "CallExpression"
    }
}

class BinaryExpression: Expression {
    var operation: Token
    var left: Expression
    var right: Expression

    init(
        operation: Token,
        left: Expression,
        right: Expression
    ) {
        self.operation = operation
        self.left = left
        self.right = right
        super.init()
        self.type = "BinaryExpression"
    }
}

enum Filter {
    case identifier(Identifier)
    case callExpression(CallExpression)
}

class FilterExpression: Expression {
    var operand: Expression
    var filter: Filter

    init(
        operand: Expression,
        filter: Filter
    ) {
        self.operand = operand
        self.filter = filter
        super.init()
        self.type = "FilterExpression"
    }
}

class TestExpression: Expression {
    var operand: Expression
    var negate: Bool
    var test: Identifier

    init(
        operand: Expression,
        negate: Bool,
        test: Identifier
    ) {
        self.operand = operand
        self.negate = negate
        self.test = test
        super.init()
        self.type = "TestExpression"
    }
}

class UnaryExpression: Expression {
    var operation: Token
    var argument: Expression

    init(
        operation: Token,
        argument: Expression
    ) {
        self.operation = operation
        self.argument = argument
        super.init()
        self.type = "UnaryExpression"
    }
}

class LogicalNegationExpression: Expression {
    var argument: Expression

    init(
        argument: Expression
    ) {
        self.argument = argument
        super.init()
        self.type = "LogicalNegationExpression"
    }
}

class SliceExpression: Expression {
    var start: Expression?
    var stop: Expression?
    var step: Expression?

    init(
        start: Expression?,
        stop: Expression?,
        step: Expression?
    ) {
        self.start = start
        self.stop = stop
        self.step = step
        super.init()
        self.type = "SliceExpression"
    }
}

class KeywordArgumentExpression: Expression {
    var key: Identifier
    var value: Expression

    init(
        key: Identifier,
        value: Expression
    ) {
        self.key = key
        self.value = value
        super.init()
        self.type = "KeywordArgumentExpression"
    }
}
