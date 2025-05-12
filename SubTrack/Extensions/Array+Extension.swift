//
//  Array+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/4/29.
//

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
