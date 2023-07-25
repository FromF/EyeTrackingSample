//
//  debug.swift
//  EyeTracking
//
//  Created by 藤治仁 on 2023/02/18.
//

import Foundation

import UIKit

///デバックモード設定
func debugLog(_ obj: Any?,
              file: String = #fileID,
              function: String = #function,
              line: Int = #line) {
    #if DEBUG
        if let obj = obj {
            print("[\(file) \(function):\(line)] : \(obj)")
        } else {
            print("[\(file) \(function):\(line)]")
        }
    #endif
}

func errorLog(_ obj: Any?,
              file: String = #fileID,
              function: String = #function,
              line: Int = #line) {
    #if DEBUG
        if let obj = obj {
            print("ERROR [\(file) \(function):\(line)] : \(obj)")
        } else {
            print("ERROR [\(file) \(function):\(line)]")
        }
    #endif
}

var isSimulator:Bool {
    get {
        #if targetEnvironment(simulator)
        // iOS simulator code
        return true
        #else
        return false
        #endif
    }
}

//デバイス判定マクロ
//https://qiita.com/hituziando/items/8350828b235852e1240f
/// iPadかデバイス判定
var isPad:Bool {
    get {
        return UIDevice.current.userInterfaceIdiom == .pad ? true : false
    }
}

/// iPhoneかデバイス判定
var isPhone:Bool {
    get {
        return UIDevice.current.userInterfaceIdiom == .phone ? true : false
    }
}
