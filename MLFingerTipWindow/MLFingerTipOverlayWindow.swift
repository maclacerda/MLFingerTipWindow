//
//  MLFingerTipOverlayWindow.swift
//  MLFingerTipWindow
//
//  Created by Marcos Lacerda on 04/02/19.
//  Copyright © 2019 Marcos Lacerda. All rights reserved.
//

import UIKit

class MLFingerTipOverlayWindow: UIWindow {
  
  func rootViewController() -> UIViewController? {
    for window in UIApplication.shared.windows {
      if self == window {
        continue
      }
      
      if let realViewController = window.rootViewController {
        return realViewController
      }
    }
    
    return super.rootViewController
  }
  
}
