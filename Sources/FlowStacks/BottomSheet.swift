//
//  File.swift
//  
//
//  Created by 박연배 on 2023/09/05.
//

import Combine
import SwiftUI

public class NavigationUtil {
  public let shared: NavigationUtil = .init()
  
  private init() {}
  
  public static func presentBottomSheet<Content: View>(view: Content, animated: Bool = false) {
    //MARK: 이미 올라와 있는 바텀시트가 있는지 확인합니다.
    guard
      let topController = UIApplication.shared.topMostController(),
      !(topController is FPBottomSheetController<Content>) else { return }
    
    //MARK: 없을 경우 바텀시트를 올려줍니다.
    let hosting = UIHostingController(rootView: view)
    let bottomSheet = FPBottomSheetController(
      hosting: hosting,
      onDismiss: {}
    )
    topController.present(bottomSheet, animated: animated)
  }

  public static func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
    guard let viewController = viewController else {
      return nil
    }
    
    if let navigationController = viewController as? UINavigationController {
      return navigationController
    }
    
    for childViewController in viewController.children {
      return findNavigationController(viewController: childViewController)
    }
    return nil
  }
}

final public class FPBottomSheetController<Content: View>: ViewControllerPannable {
  private var hosting: UIHostingController<Content>? = nil
  private var onDismiss: (() -> ())?
  private var tapGesture: UITapGestureRecognizer? = nil
  private var cancellables: Set<AnyCancellable> = []
  
  public convenience init(
    hosting: UIHostingController<Content>,
    modalPresentationStyle: UIModalPresentationStyle = .overFullScreen,
    onDismiss: @escaping () -> ()
  ) {
    self.init(nibName: nil, bundle: nil)
    self.hosting = hosting
    self.onDismiss = onDismiss
    self.modalPresentationStyle = modalPresentationStyle
  }
  
  required public init?(coder: NSCoder) {
    fatalError()
  }
  
  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  public override func loadView() {
    self.view = UIView()
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    guard let hosting = hosting else { return }
    self.addView(hosting: hosting)
  }
  
  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    onDismiss?()
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
}

extension FPBottomSheetController {
  public func addView(hosting: UIHostingController<Content>) {
    addChild(hosting)
    hosting.didMove(toParent: self)
    hosting.view.layer.cornerRadius = 20
    self.view.addSubview(hosting.view)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//    hosting.view.snp.makeConstraints { make in
//      make.leading.trailing.bottom.equalToSuperview()
//    }
    hosting.view.tag = 1
  }
}

//MARK: 모달 제스처
public class ViewControllerPannable: UIViewController {
  var panGestureRecognizer: UIPanGestureRecognizer?
  var originalPosition: CGPoint?
  var currentPositionTouched: CGPoint?
  lazy var modalView = view.subviews.first { view in
    view.tag == 1
  }
  lazy var dimmedView: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    view.tag = 2
    return view
  }()
  
  public func dismissAnimation(onDismiss: @escaping () -> ()) {
    guard let modalView = self.view.subviews.first(where: { view in
      view.tag == 1
    }) else { return }
    self.view.layoutIfNeeded()
    modalView.translatesAutoresizingMaskIntoConstraints = false
    modalView.removeConstraints(modalView.constraints)
    modalView.topAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//    modalView.snp.remakeConstraints { make in
//      make.top.equalTo(self.view.snp.bottom)
//      make.leading.trailing.equalToSuperview()
//    }
    UIView.animate(
      withDuration: 0.2,
      animations: {
        self.dimmedView.backgroundColor = .clear
        self.view.layoutIfNeeded()
      },
      completion: { isComplete in
        if isComplete {
          self.dismiss(animated: false) {
            onDismiss()
          }
        }
      }
    )
  }
  
  private func presentAnimation() {
    guard let dimmedView = self.view.subviews.first(where: { view in view.tag == 2 }) else { return }
    self.view.layoutIfNeeded()
    modalView?.translatesAutoresizingMaskIntoConstraints = false
    modalView?.removeConstraints(modalView?.constraints ?? [])
    modalView?.topAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    modalView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    modalView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//    modalView?.snp.remakeConstraints { make in
//      make.top.equalTo(self.view.snp.bottom)
//      make.leading.trailing.equalToSuperview()
//    }
    self.view.layoutIfNeeded()
    modalView?.removeConstraints(modalView?.constraints ?? [])
    modalView?.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    modalView?.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    modalView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//    modalView?.snp.remakeConstraints { make in
//      make.leading.trailing.bottom.equalToSuperview()
//    }
    UIView.animate(withDuration: 0.2) {
      dimmedView.backgroundColor = UIColor(white: 0, alpha: 0.38)
      self.view.layoutIfNeeded()
    }
  }
  
  @objc
  public func dimmDidTap() {
    dismissAnimation() {}
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
    view.addGestureRecognizer(panGestureRecognizer!)
    let gesture = UITapGestureRecognizer(target: self, action: #selector(dimmDidTap))
    dimmedView.addGestureRecognizer(gesture)
    self.view.addSubview(dimmedView)
    self.view.sendSubviewToBack(dimmedView)
    
    dimmedView.translatesAutoresizingMaskIntoConstraints = false
    dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    dimmedView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//    dimmedView.snp.makeConstraints { make in
//      make.edges.equalToSuperview()
//    }
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    presentAnimation()
  }
  
  @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
    guard let modalView = modalView else { return }
    guard let dimmedView = self.view.subviews.first(where: { view in
      view.tag == 2
    }) else { return }
    
    let translation = panGesture.translation(in: view)
    if panGesture.state == .began {
      originalPosition = view.center
      currentPositionTouched = panGesture.location(in: view)
    } else if panGesture.state == .changed {
      if translation.y < 0 { return } // 모달창을 위로 올려주는 것을 방지
      let offset = modalView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: translation.y)
      offset.isActive = true
      offset.constant = translation.y
//      modalView.snp.updateConstraints { make in
//        make.bottom.equalTo(self.view.snp.bottom).offset(translation.y)
//      }
    } else if panGesture.state == .ended {
      let velocity = panGesture.velocity(in: view)
      if velocity.y >= 1200 || translation.y >= modalView.intrinsicContentSize.height / 2 { // 가속도 >= 1200 혹은 모달 뷰 사이즈 / 2일 경우 dismiss
        self.view.layoutIfNeeded()
        modalView.removeConstraints(modalView.constraints)
        modalView.topAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = modalPresentationCapturesStatusBarAppearance
        modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        modalView.snp.remakeConstraints { make in
//          make.top.equalTo(self.view.snp.bottom)
//          make.leading.trailing.equalToSuperview()
//        }
        UIView.animate(
          withDuration: 0.2,
          animations: {
            dimmedView.backgroundColor = .clear
            self.view.layoutIfNeeded()
          },
          completion: { (isCompleted) in
            if isCompleted {
              self.dismiss(animated: false, completion: nil)
            }
          }
        )
      } else {
        self.view.layoutIfNeeded()
        let layout = modalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        layout.isActive = true
//        modalView.snp.updateConstraints { make in
//          make.bottom.equalTo(self.view.snp.bottom)
//        }
        UIView.animate(withDuration: 0.2, animations: {
          self.view.layoutIfNeeded()
        })
      }
    }
  }
}
