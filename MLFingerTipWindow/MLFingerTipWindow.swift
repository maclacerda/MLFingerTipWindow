//
//  MLFingerTipWindow.swift
//  MLFingerTipWindow
//
//  Created by Marcos Lacerda on 04/02/19.
//  Copyright © 2019 Marcos Lacerda. All rights reserved.
//

import UIKit

class MLFingerTipWindow: UIWindow {

  // MARK: - Public properties
  
  public var touchAlpha: CGFloat = 0.5
  public var fadeDuration: TimeInterval = 0.3
  public var strokeColor: UIColor = .black
  public var fillColor: UIColor = .white
  public var alwaysShowTouches = false
  
  // MARK: - Private properties
  
  private var overlayWindow: UIWindow = {
    let _overlayWindow = MLFingerTipOverlayWindow()
    _overlayWindow.isUserInteractionEnabled = false
    _overlayWindow.windowLevel = .statusBar
    _overlayWindow.backgroundColor = .clear
    _overlayWindow.isHidden = false
    
    return _overlayWindow
  }()
  
  private var active: Bool = true
  private var fingerTipRemovalScheduled: Bool = false
  
  // MARK: - Life cycle
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.commomInit()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.commomInit()
  }
  
  fileprivate func commomInit() {
    NotificationCenter.default.addObserver(self, selector: #selector(screenConnect(_:)), name: UIScreen.didConnectNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(screenDisconnect(_:)), name: UIScreen.didDisconnectNotification, object: nil)
    
    self.updateFingertipsAreActive()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: UIScreen.didConnectNotification, object: nil)
    NotificationCenter.default.removeObserver(self, name: UIScreen.didDisconnectNotification, object: nil)
  }
  
  // MARK: - Getters
  
  func touchImage() -> UIImage? {
    let clipPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
    
    UIGraphicsBeginImageContextWithOptions(clipPath.bounds.size, false, 0)
    
    let drawPath = UIBezierPath(arcCenter: CGPoint(x: 25, y: 25), radius: 22, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
    drawPath.lineWidth = 2.0
    
    self.strokeColor.setStroke()
    self.fillColor.setFill()
    
    drawPath.stroke()
    drawPath.fill()
    
    clipPath.addClip()
    
    let _touchImage = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return _touchImage
  }
  
  // MARK: - Setters
  
  func setAlwaysShowTouches(_ flag: Bool) {
    if alwaysShowTouches != flag {
      self.alwaysShowTouches = flag
      self.updateFingertipsAreActive()
    }
  }
  
  // MARK: - Screen Notifications
  
  @objc func screenConnect(_ notification: Notification) {
    self.updateFingertipsAreActive()
  }
  
  @objc func screenDisconnect(_ notification: Notification) {
    self.updateFingertipsAreActive()
  }
  
  // MARK: - Other methods
  fileprivate func anyScreenIsMirrored() -> Bool {
    for screen in UIScreen.screens {
      if screen.mirrored != nil {
        return true
      }
    }
    
    return false
  }
  
  fileprivate func updateFingertipsAreActive() {
    if alwaysShowTouches || Bool(ProcessInfo.processInfo.environment["DEBUG_FINGERTIP_WINDOW"] ?? "false") ?? false {
      active = true
    } else {
      active = self.anyScreenIsMirrored()
    }
  }
  
  // MARK: - UIWindow overrides
  override func sendEvent(_ event: UIEvent) {
    if active {
      guard let allTouches = event.allTouches else { return }
      
      for touch in allTouches.enumerated() {
        switch touch.element.phase {
          
        case .began, .moved, .stationary:
          var touchView = self.overlayWindow.viewWithTag(touch.element.hash) as? MLFingerTipView
          
          if touch.element.phase != .stationary && touchView != nil && touchView!.fadingOut {
            touchView?.removeFromSuperview()
            touchView = nil
          }
          
          if touchView == nil && touch.element.phase != .stationary {
            touchView = MLFingerTipView(image: self.touchImage())
            self.overlayWindow.addSubview(touchView!)
          }
          
          if !(touchView?.fadingOut ?? true) {
            touchView?.alpha = self.touchAlpha
            touchView?.center = touch.element.location(in: self.overlayWindow)
            touchView?.tag = touch.element.hash
            touchView?.timestamp = touch.element.timestamp
            touchView?.shouldAutomaticallyRemoveAfterTimeout = self.shouldAutomaticallyRemoveFingerTipForTouch(touch.element)
          }
          
          break
        
        case .ended, .cancelled:
          self.removeFingerTipWithHash(hash: touch.element.hash)
          break
        }
      }
    }
    
    super.sendEvent(event)
    self.scheduleFingerTipRemoval()
  }
  
  fileprivate func scheduleFingerTipRemoval() {
    if self.fingerTipRemovalScheduled { return }
    
    self.fingerTipRemovalScheduled = true
    self.perform(#selector(removeInactiveFingerTips), with: nil, afterDelay: 0.1)
  }
  
  fileprivate func cancelScheduledFingerTipRemoval() {
    self.fingerTipRemovalScheduled = true
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(removeInactiveFingerTips), object: nil)
  }
  
  @objc fileprivate func removeInactiveFingerTips() {
    self.fingerTipRemovalScheduled = false
    
    let now = ProcessInfo.processInfo.systemUptime
    let removalDelay: Double = 0.2
    
    for subview in self.overlayWindow.subviews {
      guard let touchView = subview as? MLFingerTipView else { continue }
      
      if touchView.shouldAutomaticallyRemoveAfterTimeout && now > ((touchView.timestamp ?? 0.0) + removalDelay) {
        self.removeFingerTipWithHash(hash: touchView.tag)
      }
    }
    
    if self.overlayWindow.subviews.count > 0 {
      self.scheduleFingerTipRemoval()
    }
  }
  
  func removeFingerTipWithHash(hash: NSInteger, animated: Bool = true) {
    guard let touchView = self.overlayWindow.viewWithTag(hash) as? MLFingerTipView else { return }
    
    if touchView.fadingOut { return }
    
    let animationsWereEnabled = UIView.areAnimationsEnabled
    
    if animated {
      UIView.setAnimationsEnabled(true)
      UIView.beginAnimations(nil, context: nil)
      UIView.setAnimationDuration(self.fadeDuration)
    }
    
    touchView.frame = CGRect(x: touchView.center.x - touchView.frame.size.width,
                             y: touchView.center.y - touchView.frame.size.height,
                             width: touchView.frame.size.width  * 2,
                             height: touchView.frame.size.height * 2)
    
    touchView.alpha = 0.0
    
    if animated {
      UIView.commitAnimations()
      UIView.setAnimationsEnabled(animationsWereEnabled)
    }
    
    touchView.fadingOut = true
    touchView.perform(#selector(removeFromSuperview), with: nil, afterDelay: self.fadeDuration)
  }
  
  func shouldAutomaticallyRemoveFingerTipForTouch(_ touch: UITouch) -> Bool {
    var view = touch.view
    view = view?.hitTest(touch.location(in: view), with: nil)
    
    while view != nil {
      if view is UITableViewCell {
        if let gestureRecognizers = touch.gestureRecognizers {
          for recognizer in gestureRecognizers {
            if recognizer is UISwipeGestureRecognizer {
              return true
            }
          }
        }
      }
      
      if view is UITableView {
        if touch.gestureRecognizers?.count == 0 {
          return true
        }
      }
      
      view = view?.superview
    }
    
    return false
  }
  
}
