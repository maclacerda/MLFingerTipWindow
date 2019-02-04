//
//  MLFingerTipView.swift
//  MLFingerTipWindow
//
//  Created by Marcos Lacerda on 04/02/19.
//  Copyright © 2019 Marcos Lacerda. All rights reserved.
//

import UIKit

class MLFingerTipView : UIImageView {
  
  var timestamp: TimeInterval?
  var shouldAutomaticallyRemoveAfterTimeout: Bool = false
  var fadingOut: Bool = false
  
}
