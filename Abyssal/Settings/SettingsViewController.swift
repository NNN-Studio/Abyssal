//
//  SettingsViewController.swift
//  Abyssal
//
//  Created by KrLite on 2024/6/21.
//

import AppKit

class SettingsViewController: NSViewController {
    func initializeFrame() {
        DispatchQueue.main.async {
            AppDelegate.shared?.popover.contentSize = self.view.intrinsicContentSize
        }
    }
    
    override func viewWillAppear() {
        initializeFrame()
        
        DispatchQueue.main.async {
            AppDelegate.shared?.statusBarController.function()
        }
    }
    
    override func viewWillDisappear() {
        DispatchQueue.main.async {
            AppDelegate.shared?.statusBarController.function()
        }
    }
}
