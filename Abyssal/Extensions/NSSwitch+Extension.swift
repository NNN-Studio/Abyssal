//
//  NSSwitch+Extension.swift
//  Abyssal
//
//  Created by KrLite on 2023/6/14.
//

import AppKit

extension NSSwitch {
    var flag: Bool {
        get {
            self.state == .on
        }
        
        set(flag) {
            self.state = flag ? .on : .off
        }
    }
}
