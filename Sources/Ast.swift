//
//  Ast.swift
//
//
//  Created by John Mai on 2024/3/20.
//

import Foundation

protocol Statement {
    var type: String { get }
}

struct Program: Statement {
    let type: String = "Program"
    var body: [Statement] = []
}

protocol Expression: Statement {}

protocol Literal: Expression {
    associatedtype T
    var value: T { get set }
}

struct StringLiteral: Literal {
    let type: String = "StringLiteral"
    var value: String
}

struct NumericLiteral: Literal {
    let type: String = "NumericLiteral"
    var value: any Numeric
}

struct BoolLiteral: Literal {
    let type: String = "BoolLiteral"
    var value: Bool
}

struct ArrayLiteral: Literal {
    let type: String = "ArrayLiteral"
    var value: [Expression]
}

struct TupleLiteral: Literal {
    let type: String = "TupleLiteral"
    var value: [Expression]
}

struct ObjectLiteral: Literal {
    let type: String = "ObjectLiteral"
    var value: [(Expression, Expression)]
}

struct Set: Statement {
    let type: String = "Set"
    var assignee: Expression
    var value: Expression
}

struct If: Statement {
    let type: String = "If"
    var test: Expression
    var body: [Statement]
    var alternate: [Statement]
}

struct Identifier: Expression {
    let type: String = "Identifier"
    var value: String
}

protocol Loopvar {}
extension Identifier: Loopvar {}
extension TupleLiteral: Loopvar {}

struct For: Statement {
    let type: String = "For"
    var loopvar: Loopvar
    var iterable: Expression
    var body: [Statement]
}

struct MemberExpression: Expression {
    let type: String = "MemberExpression"
    var object: Expression
    var property: Expression
    var computed: Bool
}

struct CallExpression: Expression {
    let type: String = "CallExpression"
    var callee: Expression
    var args: [Expression]
}

struct BinaryExpression: Expression {
    let type: String = "BinaryExpression"
    var operation: Token
    var left: Expression
    var right: Expression
}

protocol Filter {}
extension Identifier: Filter {}
extension CallExpression: Filter {}

struct FilterExpression: Expression {
    let type: String = "FilterExpression"
    var operand: Expression
    var filter: Filter
}

struct TestExpression: Expression {
    let type: String = "TestExpression"
    var operand: Expression
    var negate: Bool
    var test: Identifier
}

struct UnaryExpression: Expression {
    let type: String = "UnaryExpression"
    var operation: Token
    var argument: Expression
}

struct LogicalNegationExpression: Expression {
    let type: String = "LogicalNegationExpression"
    var argument: Expression
}

struct SliceExpression: Expression {
    let type: String = "SliceExpression"
    var start: Expression?
    var stop: Expression?
    var step: Expression?
}

struct KeywordArgumentExpression: Expression {
    let type: String = "KeywordArgumentExpression"
    var key: Identifier
    var value: any Expression
}
