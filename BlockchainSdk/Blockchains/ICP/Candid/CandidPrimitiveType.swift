//
//  CandidPrimitiveType.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 27.04.23.
//

import Foundation

public enum CandidPrimitiveType: Int, Equatable {
    case null       = -1
    case bool       = -2
    case natural    = -3
    case integer    = -4
    case natural8   = -5
    case natural16  = -6
    case natural32  = -7
    case natural64  = -8
    case integer8   = -9
    case integer16  = -10
    case integer32  = -11
    case integer64  = -12
    case float32    = -13
    case float64    = -14
    case text       = -15
    case reserved   = -16
    case empty      = -17
    case option     = -18
    case vector     = -19
    case record     = -20
    case variant    = -21
    case function   = -22
    //case service    = -23
}
