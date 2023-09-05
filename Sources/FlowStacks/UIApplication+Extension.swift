//
//  File.swift
//  
//
//  Created by 박연배 on 2023/09/05.
//

import SwiftUI

public extension UIApplication {
  var key: UIWindow? {
    self.connectedScenes
      .map({$0 as? UIWindowScene})
      .compactMap({$0})
      .first?
      .windows
      .filter({$0.isKeyWindow})
      .first
  }
  
  var navigationController: UINavigationController? {
    let key = self.connectedScenes
      .map({$0 as? UIWindowScene})
      .compactMap({$0})
      .first?
      .windows
      .filter({$0.isKeyWindow})
      .first
    
    return key?.rootViewController?.navigationController
  }
  
  func topMostController() -> UIViewController? {
    guard
      let window = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first,
      let rootViewController = window.rootViewController else {
      return nil
    }
    
    var topController = rootViewController
    
    while let newTopController = topController.presentedViewController {
      topController = newTopController
    }
    return topController
  }
}
