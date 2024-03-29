//
//  StateManager.swift
//  Abyssal
//
//  Created by KrLite on 2023/6/18.
//

import AppKit
import Defaults

extension StatusBarController {
    
    // MARK: - Icon Visibilities
    
    func untilHeadVisible(
        _ flag: Bool
    ) {
        untilSeparatorVisible(flag)
        head.isVisible = flag
    }
    
    func untilSeparatorVisible(
        _ flag: Bool
    ) {
        untilTailVisible(flag)
        body.isVisible = flag
    }
    
    func untilTailVisible(
        _ flag: Bool
    ) {
        tail.isVisible = flag
    }
    
}

extension StatusBarController {
    
    // MARK: - Enables
    
    func collapse() {
        unidleHideArea()
        Defaults[.isCollapsed] = true
    }
    
    func idleHideArea() {
        idling.hide = true
    }
    
    func idleAlwaysHideArea() {
        idling.alwaysHide = true
    }
    
    func startAnimationTimer() {
        if animationTimer == nil {
            animationTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0 / 60.0,
                repeats: true
            ) { [weak self] _ in
                guard let self else { return }
                
                self.update()
            }
        }
    }
    
    func startActionTimer() {
        if actionTimer == nil {
            actionTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0 / 6.0,
                repeats: true
            ) { [weak self] _ in
                guard let self else { return }
                
                self.sort()
                self.map()
            }
        }
    }
    
    func startFeedbackTimer() {
        if feedbackTimer == nil && shouldPresentFeedback {
            feedbackTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0 / 30.0,
                repeats: true
            ) { [weak self] _ in
                guard let self else { return }
                
                guard self.feedbackCount < Defaults[.feedback].pattern.count else {
                    self.feedbackCount = 0
                    self.stopTimer(&self.feedbackTimer)
                    
                    return
                }
                
                if let pattern = Defaults[.feedback].pattern[self.feedbackCount] {
                    NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
                }
                
                self.feedbackCount += 1
            }
        }
    }
    
    func startTriggerTimer() {
        if triggerTimer == nil {
            triggerTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0 / 6.0,
                repeats: true
            ) { [weak self] _ in
                guard let self else { return }
                
                self.checkIdleStates()
                
                // Update dragging state
                
                if self.draggedToUncollapse.dragging && !self.mouseDragging {
                    self.draggedToUncollapse.dragging = false
                    
                    if self.draggedToUncollapse.shouldCollapse {
                        self.collapse()
                    }
                    
                    if self.draggedToUncollapse.shouldEnableAnimation {
                        Defaults[.reduceAnimationEnabled] = false
                    }
                    
                    self.unidleAlwaysHideArea()
                    self.startAnimationTimer()
                }
                
                else if self.mouseDragging && !self.draggedToUncollapse.dragging {
                    if self.draggedToUncollapse.count < 3 {
                        self.draggedToUncollapse.count += 1
                    } else {
                        self.draggedToUncollapse.dragging = true
                        self.draggedToUncollapse.shouldCollapse = Defaults[.isCollapsed]
                        self.draggedToUncollapse.count = 0
                        
                        if Defaults[.isCollapsed] {
                            self.draggedToUncollapse.shouldCollapse = true
                            self.uncollapse()
                        } else {
                            self.draggedToUncollapse.shouldCollapse = false
                        }
                        
                        if !Defaults[.reduceAnimationEnabled] {
                            self.draggedToUncollapse.shouldEnableAnimation = true
                            Defaults[.reduceAnimationEnabled] = true
                        } else {
                            self.draggedToUncollapse.shouldEnableAnimation = false
                        }
                        
                        self.idleAlwaysHideArea()
                        self.startAnimationTimer()
                    }
                }
                
                // Update edge
                if self.shouldEdgeUpdate.will {
                    self.shouldEdgeUpdate.now = true
                } else {
                    self.shouldEdgeUpdate.now = false
                }
                
                if self.shouldEdgeUpdate.now {
                    self.updateEdge()
                }
                
                // Update mouse and key
                let mouseNeedsUpdate = self.was.mouseSpare != self.mouseSpare
                let keyNeedsUpdate = self.was.modifiers != KeyboardHelper.modifiers
                
                if !MouseHelper.dragging {
                    if mouseNeedsUpdate {
                        if self.mouseSpare {
                            // Mouse entered spare area
                            self.startMouseEventMonitor()
                        } else {
                            // Mouse left spare area
                            self.stopMonitor(&self.mouseEventMonitor)
                        }
                    }
                    
                    if mouseNeedsUpdate || keyNeedsUpdate {
                        // Resolve animation and function updates
                        self.startFunctionalTimers()
                    }
                }
                
                if keyNeedsUpdate || self.mouseDragging {
                    // Key pressed || mouse dragging -> sort separators and map appearances
                    self.sort()
                    self.map()
                }
                
                self.was = (
                    self.mouseSpare,
                    KeyboardHelper.modifiers
                )
            }
        }
    }
    
    func startTimeoutTimer() {
        let timeout = Defaults[.timeout]
        
        if timeoutTimer == nil && timeout.attribute != nil {
            timeoutTimer = Timer.scheduledTimer(
                withTimeInterval: Double(timeout.attribute!),
                repeats: false
            ) { [weak self] _ in
                guard let self else { return }
                
                self.unidleHideArea()
                self.stopTimer(&self.timeoutTimer) { self.timeout = true }
            }
        }
    }
    
    func startIgnoringTimer() {
        if ignoringTimer == nil && ignoring {
            ignoringTimer = Timer.scheduledTimer(
                withTimeInterval: 1,
                repeats: false
            ) { [weak self] _ in
                guard let self else { return }
                
                self.stopTimer(&self.ignoringTimer) { self.ignoring = false }
            }
        }
    }
    
    func startFunctionalTimers() {
        guard !MouseHelper.dragging else { return }
        startAnimationTimer()
        startActionTimer()
        
        shouldEdgeUpdate.will = false
        timeout = false
        
        if (idling.hide || idling.alwaysHide) {
            startTimeoutTimer()
        }
        
        if (!idling.hide && !idling.alwaysHide) {
            stopTimer(&timeoutTimer) { timeout = true }
        }
    }
    
    func startMouseEventMonitor() {
        if mouseEventMonitor == nil {
            mouseEventMonitor = EventMonitor(
                mask: [.leftMouseDown,
                       .rightMouseDown,]
            ) { [weak self] event in
                guard
                    let self,
                    self.mouseSpare
                else { return }
                
                if Defaults[.isCollapsed] && self.mouseInHideArea && !(KeyboardHelper.command && event?.type == .leftMouseDown) {
                    self.idleHideArea()
                }
                
                if self.mouseInAlwaysHideArea {
                    self.idleAlwaysHideArea()
                }
            }
            
            mouseEventMonitor?.start()
        }
    }
    
    // MARK: - Disables
    
    func uncollapse() {
        Defaults[.isCollapsed] = false
        unidleHideArea()
    }
    
    func unidleHideArea() {
        idling.hide = false
        unidleAlwaysHideArea()
    }
    
    func unidleAlwaysHideArea() {
        idling.alwaysHide = false
        startFunctionalTimers()
    }
    
    func stopTimer(_ timer: inout Timer?, afterStopped: () -> Void = {}) {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            
            afterStopped()
        }
    }
    
    func stopMonitor(_ monitor: inout EventMonitor?, afterStopped: () -> Void = {}) {
        if monitor != nil {
            monitor?.stop()
            monitor = nil
            
            afterStopped()
        }
    }
    
    func stopFunctionalTimers() {
        stopTimer(&animationTimer)
        stopTimer(&actionTimer)
        
        shouldEdgeUpdate.will = true
        timeout = false
    }
    
}
