//
//  Error.swift
//
//
//  Created by John Mai on 2024/3/20.
//

import Foundation

enum JinjaError: Error {
    case syntaxError(String)
    case parserError(String)
    case runtimeError(String)
    case notSupportError
}
