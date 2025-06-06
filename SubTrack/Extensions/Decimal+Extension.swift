//
//  Decimal+Extension.swift
//  SubTrack
//
//  Created by Sam on 2025/6/6.
//
import SwiftUI


extension Decimal {
    func rounding(to scale: Int, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var result = self
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, mode)
        return result
    }
}
