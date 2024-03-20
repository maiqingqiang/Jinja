//
//  StringExtension.swift
//
//
//  Created by John Mai on 2024/3/20.
//

import Foundation

extension String {
    subscript(i: Int) -> Character {
        self[index(startIndex, offsetBy: i)]
    }

    func slice(start: Int, end: Int) -> Self {
        let startPosition = index(startIndex, offsetBy: start)
        let endPosition = index(startPosition, offsetBy: end)
        return String(self[startPosition ..< endPosition])
    }
}
