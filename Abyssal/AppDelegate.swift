//
//  AppDelegate.swift
//  Abyssal
//
//  Created by KrLite on 2023/6/13.
//

import Cocoa
import SwiftUI
import AppKit
import Defaults
import LaunchAtLogin

let repository = "NNN-Studio/Abyssal"//"Cement-Labs/Abyssal"

//@main
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate? {
        NSApplication.shared.delegate as? AppDelegate
    }
    
    let popover: NSPopover = NSPopover()
    
    let statusBarController = StatusBarController()
    
    // MARK: - Event Monitors
    
    var mouseEventMonitor: EventMonitor?
    
    // MARK: - Application Methods
    
    func applicationDidFinishLaunching(
        _ aNotification: Notification
    ) {
        // Deactivate app after launched
        ActivationPolicyManager.set(.prohibited, asFallback: true)
        
        let controller = SettingsViewController()
        controller.view = NSHostingView(rootView: SettingsView())
        popover.contentViewController = controller
        
        // Fetch latest version
        VersionManager.fetchLatest()
        
        // Pre-initialize view frame
        controller.initializeFrame()
        
        popover.behavior = .applicationDefined
        popover.delegate = self
        
        mouseEventMonitor = EventMonitor(
            mask: [.leftMouseDown,
                   .rightMouseDown]
        ) { [weak self] event in
            if let strongSelf = self {
                if strongSelf.popover.isShown {
                    strongSelf.closePopover(event)
                }
            }
        }
    }
    
    func applicationWillTerminate(
        _ aNotification: Notification
    ) {
    }
    
    func applicationSupportsSecureRestorableState(
        _ app: NSApplication
    ) -> Bool {
        true
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        true
    }
}

extension AppDelegate {
    @objc func quit(
        _ sender: Any?
    ) {
        NSApplication.shared.terminate(sender)
    }
    
    // MARK: - Toggles
    
    @objc func toggle(
        _ sender: Any?
    ) {
        guard sender as? NSStatusBarButton == AppDelegate.shared?.statusBarController.head.button else {
            toggleActive(sender)
            return
        }
        
        if KeyboardManager.option {
            togglePopover(sender)
        } else {
            if let event = NSApp.currentEvent, event.type == .rightMouseUp {
                togglePopover(sender)
            } else {
                toggleActive(sender)
            }
        }
    }
    
    @objc func toggleActive(
        _ sender: Any?
    ) {
        statusBarController.function()
        
        guard !(statusBarController.idling.hide || statusBarController.idling.alwaysHide) else {
            statusBarController.unidleHideArea()
            return
        }
        
        if Defaults[.isActive] {
            statusBarController.deactivate()
        } else {
            statusBarController.activate()
        }
    }
    
    @objc func togglePopover(
        _ sender: Any?
    ) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(
        _ sender: Any?
    ) {
        if let button = statusBarController.head.button ?? sender as? NSButton {
            let buttonRect = button.convert(button.bounds, to: nil)
            let screenRect = button.window!.convertToScreen(buttonRect)
            
            let invisiblePanel = NSPanel(
                contentRect: NSMakeRect(0, 0, 1, 5),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            invisiblePanel.isFloatingPanel = true
            invisiblePanel.alphaValue = 0

            invisiblePanel.setFrameOrigin(NSPoint(
                x: screenRect.maxX,
                y: screenRect.maxY
            ))
            invisiblePanel.makeKeyAndOrderFront(nil)
            
            popover.show(
                relativeTo: 	invisiblePanel.contentView!.frame,
                of: 			invisiblePanel.contentView!,
                preferredEdge: 	.maxY
            )
            
            // Activate app
            let overridesMenuBar = Defaults[.autoOverridesMenuBarEnabled]
            let activationPolicy: NSApplication.ActivationPolicy = overridesMenuBar ? .regular : .accessory
            
            if overridesMenuBar {
                Defaults[.menuBarOverride].setMenu()
            }
            
            ActivationPolicyManager.set(activationPolicy, asFallback: true)
            NSApp.activate()
            
            DispatchQueue.main.async {
                self.popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            }
        }
        
        mouseEventMonitor?.start()
    }
    
    func closePopover(
        _ sender: Any?
    ) {
        DispatchQueue.main.async {
            self.popover.close() // Force it to close, thus closing all nested popovers
        }
        
        // Deactivate app
        ActivationPolicyManager.set(.prohibited, asFallback: true, deadline: .now() + 0.2)
        
        mouseEventMonitor?.stop()
        statusBarController.function()
        AppDelegate.shared?.statusBarController.triggerIgnoring()
    }
}
