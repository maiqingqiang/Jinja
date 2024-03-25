//
//  Utilities.swift
//
//
//  Created by John Mai on 2024/3/20.
//

import Foundation

func range(start: Int, stop: Int? = nil, step: Int = 1) -> [Int] {
    let stopUnwrapped = stop ?? start
    let startValue = stop == nil ? 0 : start
    let stopValue = stop == nil ? start : stopUnwrapped

    return stride(from: startValue, to: stopValue, by: step).map { $0 }
}

func slice<T>(_ array: [T], start: Int? = nil, stop: Int? = nil, step: Int? = 1) -> [T] {
    let arrayCount = array.count
    let startValue = start ?? 0
    let stopValue = stop ?? arrayCount
    let step = step ?? 1
    var slicedArray = [T]()

    if step > 0 {
        let startIndex = startValue < 0 ? max(arrayCount + startValue, 0) : min(startValue, arrayCount)
        let stopIndex = stopValue < 0 ? max(arrayCount + stopValue, 0) : min(stopValue, arrayCount)
        for i in stride(from: startIndex, to: stopIndex, by: step) {
            slicedArray.append(array[i])
        }
    } else {
        let startIndex = startValue < 0 ? max(arrayCount + startValue, -1) : min(startValue, arrayCount - 1)
        let stopIndex = stopValue < -1 ? max(arrayCount + stopValue, -1) : min(stopValue, arrayCount - 1)
        for i in stride(from: startIndex, through: stopIndex, by: step) {
            slicedArray.append(array[i])
        }
    }

    return slicedArray
}
