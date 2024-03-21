//
//  Parser.swift
//
//
//  Created by John Mai on 2024/3/21.
//

import Foundation

func parse(tokens: [Token]) throws -> Program {
    var program = Program()
    var current = 0

    func expect(type: TokenType, error: String) throws -> Token {
        let prev = tokens[current]
        current += 1
        if prev.type != type {
            throw JinjaError.parserError("Parser Error: \(error). \(prev.type) != \(type).")
        }

        return prev
    }

    func parseArgumentsList() throws -> [Statement] {
        var args: [Expression] = []

        while !isMatch(.closeParen) {
            var argument = try parseExpression()

            if isMatch(.equals) {
                current += 1

                if argument as? Identifier == nil {
                    throw JinjaError.syntaxError("Expected identifier for keyword argument")
                }

                let value = try parseExpression()

                argument = KeywordArgumentExpression(key: argument as! Identifier, value: value as! Expression)
            }

            args.append(argument as! Expression)

            if isMatch(.comma) {
                current += 1
            }
        }

        return args
    }

    func parseArgs() throws -> [Statement] {
        _ = try expect(type: .openParen, error: "Expected opening parenthesis for arguments list")

        let args = try parseArgumentsList()

        _ = try expect(type: .closeParen, error: "Expected closing parenthesis for arguments list")

        return args
    }

    func parseText() throws -> StringLiteral {
        try StringLiteral(value: expect(type: .text, error: "Expected text token").value)
    }

    func parseCallExpression(callee: Statement) throws -> CallExpression {
        var args: [Expression] = []

        for arg in try parseArgs() {
            args.append(arg as! Expression)
        }

        var callExpression = CallExpression(callee: callee as! Expression, args: args)

        if isMatch(.openParen) {
            callExpression = try parseCallExpression(callee: callExpression)
        }

        return callExpression
    }

    func parseMemberExpressionArgumentsList() throws -> Statement {
        var slices: [Statement?] = []
        var isSlice = false

        while !isMatch(.closeSquareBracket) {
            if isMatch(.colon) {
                slices.append(nil)
                current += 1
                isSlice = true
            } else {
                try slices.append(parseExpression())
                if isMatch(.colon) {
                    current += 1
                    isSlice = true
                }
            }
        }

        if slices.isEmpty {
            throw JinjaError.syntaxError("Expected at least one argument for member/slice expression")
        }

        if isSlice {
            if slices.count > 3 {
                throw JinjaError.syntaxError("Expected 0-3 arguments for slice expression")
            }

            return SliceExpression(start: slices[0] as? Expression, stop: slices[1] as? Expression, step: slices[2] as? Expression)
        }

        return slices[0]!
    }

    func parseMemberExpression() throws -> Statement {
        var object = try parsePrimaryExpression()

        while isMatch(.dot) || isMatch(.openSquareBracket) {
            let operation = tokens[current]
            current += 1
            var property: Statement

            let computed = operation.type != .dot

            if computed {
                property = try parseMemberExpressionArgumentsList()
                _ = try expect(type: .closeSquareBracket, error: "Expected closing square bracket")
            } else {
                property = try parsePrimaryExpression()
                if property.type != "Identifier" {
                    throw JinjaError.syntaxError("Expected identifier following dot operator")
                }
            }

            object = MemberExpression(object: object as! Expression, property: property as! Expression, computed: computed)
        }

        return object
    }

    func parseCallMemberExpression() throws -> Statement {
        let member = try parseMemberExpression()

        if isMatch(.openParen) {
            return try parseCallExpression(callee: member)
        }

        return member
    }

    func parseFilterExpression() throws -> Statement {
        var operand = try parseCallMemberExpression()

        while isMatch(.pipe) {
            current += 1
            var filter = try parsePrimaryExpression()
            if filter as? Identifier == nil {
                throw JinjaError.syntaxError("Expected identifier for the test")
            }

            if isMatch(.openParen) {
                filter = try parseCallExpression(callee: filter)
            }

            if let filter = filter as? Identifier {
                operand = FilterExpression(operand: operand as! Expression, filter: .identifier(filter))
            } else if let filter = filter as? CallExpression {
                operand = FilterExpression(operand: operand as! Expression, filter: .callExpression(filter))
            }
        }

        return operand
    }

    func parseTestExpression() throws -> Statement {
        var operand = try parseFilterExpression()

        while isMatch(.is) {
            current += 1
            let negate = isMatch(.not)

            if negate {
                current += 1
            }

            var filter = try parsePrimaryExpression()

            if let boolLiteralFlter = filter as? BoolLiteral {
                filter = Identifier(value: String(boolLiteralFlter.value))
            }

            if filter as? Identifier == nil {
                throw JinjaError.syntaxError("Expected identifier for the test")
            }

            operand = TestExpression(operand: operand as! Expression, negate: negate, test: filter as! Identifier)
        }
        return operand
    }

    func parseMultiplicativeExpression() throws -> Statement {
        var left = try parseTestExpression()

        while isMatch(.multiplicativeBinaryOperator) {
            let operation = tokens[current]
            current += 1
            var right = try parseTestExpression()
            left = BinaryExpression(operation: operation, left: left as! Expression, right: right as! Expression)
        }
        return left
    }

    func parseAdditiveExpression() throws -> Statement {
        var left = try parseMultiplicativeExpression()
        while isMatch(.additiveBinaryOperator) {
            let operation = tokens[current]
            current += 1
            var right = try parseMultiplicativeExpression()
            left = BinaryExpression(operation: operation, left: left as! Expression, right: right as! Expression)
        }
        return left
    }

    func parseComparisonExpression() throws -> Statement {
        var left = try parseAdditiveExpression()
        while isMatch(.comparisonBinaryOperator) || isMatch(.in) || isMatch(.notIn) {
            let operation = tokens[current]
            current += 1
            var right = try parseAdditiveExpression()
            left = BinaryExpression(operation: operation, left: left as! Expression, right: right as! Expression)
        }

        return left
    }

    func parseLogicalNegationExpression() throws -> Statement {
        var right: UnaryExpression?

        while isMatch(.not) {
            let operation = tokens[current]
            current += 1
            let argument = try parseLogicalNegationExpression()
            right = UnaryExpression(operation: operation, argument: argument as! Expression)
        }

        let expression = try parseComparisonExpression()

        return right ?? expression
    }

    func parseLogicalAndExpression() throws -> Statement {
        var left = try parseLogicalNegationExpression()
        while isMatch(.and) {
            let operation = tokens[current]
            current += 1
            let right = try parseLogicalNegationExpression()
            left = BinaryExpression(operation: operation, left: left as! Expression, right: right as! Expression)
        }

        return left
    }

    func parseLogicalOrExpression() throws -> Statement {
        var left = try parseLogicalAndExpression()

        while isMatch(.or) {
            let operation = tokens[current]
            current += 1
            let right = try parseLogicalAndExpression()
            left = BinaryExpression(operation: operation, left: left as! Expression, right: right as! Expression)
        }
        return left
    }

    func parseTernaryExpression() throws -> Statement {
        let a = try parseLogicalOrExpression()
        if isMatch(.if) {
            current += 1
            let test = try parseLogicalOrExpression()
            _ = try expect(type: .else, error: "Expected else token")
            let b = try parseLogicalOrExpression()
            return If(test: test as! Expression, body: [a], alternate: [b])
        }

        return a
    }

    func parseExpression() throws -> Statement {
        Statement()
    }

    func isMatch(_ types: TokenType...) -> Bool {
        guard current+types.count <= tokens.count else {
            return false
        }

        for (index, type) in types.enumerated() {
            if type != tokens[current+index].type {
                return false
            }
        }

        return true
    }

    func parseSetStatement() throws -> Statement {
        let left = try parseExpression()

        if isMatch(.equals) {
            current += 1
            let value = try parseSetStatement()

            return SetStatement(assignee: left as! Expression, value: value as! Expression)
        }

        return left
    }

    func parseIfStatement() throws -> Statement {
        let test = try parseExpression()

        _ = try expect(type: .closeStatement, error: "Expected closing statement token")

        var body: [Statement] = []
        var alternate: [Statement] = []

        while !(tokens[current].type == .openStatement && (
            tokens[current+1].type == .elseIf || tokens[current+1].type == .else || tokens[current+1].type == .endIf))
        {
            try body.append(parseAny())
        }
        if tokens[current].type == .openStatement, tokens[current+1].type != .endIf {
            current += 1
            if isMatch(.elseIf) {
                _ = try expect(type: .elseIf, error: "Expected elseif token")
                try alternate.append(parseIfStatement())
            } else {
                _ = try expect(type: .else, error: "Expected else token")
                _ = try expect(type: .closeStatement, error: "Expected closing statement token")

                while !(tokens[current].type == .openStatement && tokens[current+1].type == .endIf) {
                    try alternate.append(parseAny())
                }
            }
        }
        return If(test: test as! Expression, body: body, alternate: alternate)
    }

    func parsePrimaryExpression() throws -> Statement {
        let token = tokens[current]
        switch token.type {
        case .numericLiteral:
            current += 1
            return NumericLiteral(value: token.value as! (any Numeric))
        case .stringLiteral:
            current += 1
            return StringLiteral(value: token.value)
        case .booleanLiteral:
            current += 1
            return BoolLiteral(value: token.value == "true")
        case .identifier:
            current += 1
            return Identifier(value: token.value)
        case .openParen:
            current += 1
            let expression = try parseExpressionSequence()
            if tokens[current].type != .closeParen {
                throw JinjaError.syntaxError("Expected closing parenthesis, got \(tokens[current].type) instead")
            }
            current += 1
            return expression
        case .openSquareBracket:
            current += 1
            var values: [Expression] = []
            while !isMatch(.closeSquareBracket) {
                try values.append(parseExpression() as! Expression)

                if isMatch(.comma) {
                    current += 1
                }
            }
            current += 1

            return ArrayLiteral(value: values)
        case .openCurlyBracket:
            current += 1
            var values: [(Expression, Expression)] = []
            while !isMatch(.closeCurlyBracket) {
                let key = try parseExpression()
                _ = try expect(type: .colon, error: "Expected colon between key and value in object literal")
                let value = try parseExpression()

                values.append((key as! Expression, value as! Expression))

                if isMatch(.comma) {
                    current += 1
                }
            }

            current += 1

            return ObjectLiteral(value: values)
        default:
            throw JinjaError.syntaxError("Unexpected token: \(token.type)")
        }
    }

    func parseExpressionSequence(primary: Bool = false) throws -> Statement {
        let fn = primary ? parsePrimaryExpression : parseExpression
        var expressions: [Expression] = try [fn() as! Expression]
        let isTuple = isMatch(.comma)
        while isTuple {
            current += 1
            try expressions.append(fn() as! Expression)
            if !isMatch(.comma) {
                break
            }
        }

        return isTuple ? TupleLiteral(value: expressions) : expressions[0]
    }

    func not(_ types: TokenType...) -> Bool {
        guard current+types.count <= tokens.count else {
            return false
        }

        return types.enumerated().contains { i, type -> Bool in
            type != tokens[current+i].type
        }
    }

    func parseForStatement() throws -> Statement {
        let loopVariable = try parseExpressionSequence(primary: true)

        if !(loopVariable as? Identifier != nil || loopVariable as? TupleLiteral != nil) {
            throw JinjaError.syntaxError("Expected identifier/tuple for the loop variable, got \(loopVariable.type) instead")
        }

        _ = try expect(type: .in, error: "Expected `in` keyword following loop variable")

        let iterable = try parseExpression()
        var body: [Statement] = []
        while not(.openStatement, .endFor) {
            try body.append(parseAny())
        }

        if let loopVariable = loopVariable as? Identifier {
            return For(loopvar: .identifier(loopVariable), iterable: iterable as! Expression, body: body)
        } else if let loopVariable = loopVariable as? TupleLiteral {
            return For(loopvar: .tupleLiteral(loopVariable), iterable: iterable as! Expression, body: body)
        }

        throw JinjaError.syntaxError("Expected identifier/tuple for the loop variable, got \(loopVariable.type) instead")
    }

    func parseJinjaStatement() throws -> Statement {
        _ = try expect(type: .openStatement, error: "Expected opening statement token")
        var result: Statement

        switch tokens[current].type {
        case .set:
            current += 1
            result = try parseSetStatement()
            _ = try expect(type: .closeStatement, error: "Expected closing statement token")
        case .if:
            current += 1
            result = try parseIfStatement()
            _ = try expect(type: .openStatement, error: "Expected {% token")
            _ = try expect(type: .endIf, error: "Expected endif token")
            _ = try expect(type: .closeStatement, error: "Expected %} token")
        case .for:
            current += 1
            result = try parseForStatement()
            _ = try expect(type: .openStatement, error: "Expected {% token")
            _ = try expect(type: .endFor, error: "Expected endfor token")
            _ = try expect(type: .closeStatement, error: "Expected %} token")
        default:
            throw JinjaError.syntaxError("Unknown statement type: \(tokens[current].type)")
        }

        return result
    }

    func parseJinjaExpression() throws -> Statement {
        _ = try expect(type: .openExpression, error: "Expected opening expression token")

        let result = try parseExpression()

        _ = try expect(type: .closeExpression, error: "Expected closing expression token")

        return result
    }

    func parseAny() throws -> Statement {
        switch tokens[current].type {
        case .text:
            return try parseText()
        case .openStatement:
            return try parseJinjaStatement()
        case .openExpression:
            return try parseJinjaExpression()
        default:
            throw JinjaError.syntaxError("Unexpected token type: \(tokens[current].type)")
        }
    }

    while current < tokens.count {
        try program.body.append(parseAny())
    }

    return program
}
