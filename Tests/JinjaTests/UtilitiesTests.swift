//
//  File.swift
//  
//
//  Created by John Mai on 2024/3/20.
//

import XCTest
@testable import Jinja

final class UtilitiesTests: XCTestCase {
    func testExample() throws {
        // 示例用法
        let rangeExample = range(start: 1, stop: 10, step: 2)
        print("Range Example: \(rangeExample)")

        let sliceExample = slice([1, 2, 3, 4, 5], start: 1, stop: 4, step: 1)
        print("Slice Example: \(sliceExample)")
    }
}
