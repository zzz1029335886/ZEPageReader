import UIKit


protocol ZEPageReaderTranslationProtocol: NSObjectProtocol {
    func translationController(translationController: ZEPageReaderAtranslationController, controllerAfter controller: UIViewController) -> UIViewController?
    func translationController(translationController: ZEPageReaderAtranslationController, controllerBefore controller: UIViewController) -> UIViewController?
    func translationController(translationController: ZEPageReaderAtranslationController, willTransitionTo controller: UIViewController) -> Void
    func translationController(translationController: ZEPageReaderAtranslationController, didFinishAnimating finished: Bool, previousController: UIViewController, transitionCompleted completed: Bool) -> Void
}

class ZEPageReaderAtranslationController: UIViewController, UIGestureRecognizerDelegate {
    
    static let animationDuration = 0.2
    static let limitRate: CGFloat = 0.05
    
    enum Direction {
        case left
        case right
    }

    var delegate: ZEPageReaderTranslationProtocol?
    
    var pendingController: UIViewController?
    
    var currentController: UIViewController?
    
    var startPoint: CGPoint = .zero
    
    var scrollDirection = 0 // 0 is unknown, 1 is right, -1 is left
    
    var allowRequestNewController = true
    
    var isPanning = false
    
    var allowAnimating = true // true 平移效果，false 无效果
    
    var screenWidth: CGFloat{ self.view.frame.width }
    
    //    MARK: 对外方法
    func setViewController(
        viewController: UIViewController,
        direction: ZEPageReaderAtranslationController.Direction,
        animated: Bool,
        completionHandler: ((Bool) -> Void)?)
    {
        if animated == false {
            for controller in self.children {
                self.removeController(controller: controller)
            }
            self.addController(controller: viewController)
            if completionHandler != nil {
                completionHandler!(true)
            }
        }else {
            let oldController = self.children.first
            self.addController(controller: viewController)
            
            var newVCEndTransform: CGAffineTransform
            var oldVCEndTransform: CGAffineTransform
            viewController.view.transform = .identity
            if direction == .left {
                viewController.view.transform = CGAffineTransform(translationX: screenWidth, y: 0)
                newVCEndTransform = .identity
                oldController?.view.transform = .identity
                oldVCEndTransform = CGAffineTransform(translationX: -screenWidth, y: 0)
            }else {
                viewController.view.transform = CGAffineTransform(translationX: -screenWidth, y: 0)
                newVCEndTransform = .identity
                oldController?.view.transform = .identity
                oldVCEndTransform = CGAffineTransform(translationX: screenWidth, y: 0)
            }
            
            UIView.animate(withDuration: ZEPageReaderAtranslationController.animationDuration, animations: {
                oldController?.view.transform = oldVCEndTransform
                viewController.view.transform = newVCEndTransform
            }, completion: { (complete) in
                if complete {
                    self.removeController(controller: oldController!)
                }
                if completionHandler != nil {
                    completionHandler!(complete)
                }
                
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if allowAnimating {
            let panGes = UIPanGestureRecognizer.init(target: self, action: #selector(handlePanGes(gesture:)))
            self.view.addGestureRecognizer(panGes)
        }
        
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(handleTapGes(gesture:)))
        self.view.addGestureRecognizer(tapGes)
        tapGes.delegate = self
    }
    
    //    MARK: 手势处理
    
    /// 处理拖动手势
    ///
    /// - Parameter gesture: 拖动手势识别器
    @objc func handlePanGes(gesture: UIPanGestureRecognizer) -> Void {
        
        let basePoint = gesture.translation(in: gesture.view)
        
        if gesture.state == .began {
            
            currentController = self.children.first
            startPoint = gesture.location(in: gesture.view)
            isPanning = true
            allowRequestNewController = true
        }
        else if gesture.state == .changed {
            
            if basePoint.x > 0 {
                if scrollDirection == 0 {
                    scrollDirection = 1
                }  else if scrollDirection == -1 {
                    scrollDirection = 1
                    self.removeController(controller: pendingController)
                    allowRequestNewController = true
                }
                // go to right
                if allowRequestNewController {
                    allowRequestNewController = false
                    
                    if let currentController = currentController {
                        pendingController = self.delegate?.translationController(translationController: self, controllerBefore: currentController)
                    }
                    
                    pendingController?.view.transform = CGAffineTransform(translationX: -screenWidth, y: 0)
                    
                    if let pendingController = pendingController {
                        self.delegate?.translationController(translationController: self, willTransitionTo: pendingController)
                        self.addController(controller: pendingController)
                    }
                }
                
            } else if basePoint.x < 0 {
                if scrollDirection == 0 {
                    scrollDirection = -1
                } else if scrollDirection == 1 {
                    scrollDirection = -1
                    self.removeController(controller: pendingController)
                    allowRequestNewController = true
                }
                // go to left
                if allowRequestNewController {
                    allowRequestNewController = false
                    if let currentController = currentController {
                        pendingController = self.delegate?.translationController(translationController: self, controllerAfter: currentController)
                    }
                    
                    pendingController?.view.transform = CGAffineTransform(translationX: screenWidth, y: 0)
                    if let pendingController = pendingController {
                        self.delegate?.translationController(translationController: self, willTransitionTo: pendingController)
                        self.addController(controller: pendingController)
                    }
                }
            }else{
                return
            }
            
            if pendingController == nil {
                return
            }
            
            
            let walkingPoint = gesture.location(in: gesture.view)
            let offsetX = walkingPoint.x - startPoint.x
            currentController?.view.transform = CGAffineTransform(translationX: offsetX, y: 0)
            pendingController?.view.transform = offsetX < 0 ? CGAffineTransform(translationX: screenWidth + offsetX, y: 0) : CGAffineTransform(translationX: -screenWidth + offsetX, y: 0)
        } else{
            
            isPanning = false
            allowRequestNewController = true
            scrollDirection = 0
            if pendingController == nil {
                return
            }
            
            let endPoint = gesture.location(in: gesture.view)
            let finalOffsetRate = (endPoint.x - startPoint.x)/screenWidth
            var currentEndTransform: CGAffineTransform = .identity
            var pendingEndTransform: CGAffineTransform = .identity
            var removeController: UIViewController? = nil
            var transitionFinished = false
            
            if finalOffsetRate >= ZEPageReaderAtranslationController.limitRate {
                transitionFinished = true
                currentEndTransform = CGAffineTransform(translationX: screenWidth, y: 0)
                removeController = self.currentController
            }
            else if finalOffsetRate < ZEPageReaderAtranslationController.limitRate && finalOffsetRate >= 0 {
                pendingEndTransform = CGAffineTransform(translationX: -screenWidth, y: 0)
                removeController = pendingController
            }
            else if finalOffsetRate < 0 && finalOffsetRate > -ZEPageReaderAtranslationController.limitRate {
                pendingEndTransform = CGAffineTransform(translationX: screenWidth, y: 0)
                removeController = pendingController
            }
            else {
                transitionFinished = true
                currentEndTransform = CGAffineTransform(translationX: -screenWidth, y: 0)
                removeController = self.currentController
            }
            
            UIView.animate(withDuration: ZEPageReaderAtranslationController.animationDuration, animations: {
                self.pendingController?.view.transform = pendingEndTransform
                self.currentController?.view.transform = currentEndTransform
            }, completion: { (complete) in
                if complete, let removeController = removeController {
                    self.removeController(controller: removeController)
                }
                
                if let currentController = self.currentController {
                    self.delegate?.translationController(translationController: self, didFinishAnimating: complete, previousController: currentController, transitionCompleted: transitionFinished)
                }
            })
            
        }
    }
    
    /// 处理点击手势
    ///
    /// - Parameter gesture: 点击手势识别器
    @objc func handleTapGes(gesture: UITapGestureRecognizer) -> Void {
        let hitPoint = gesture.location(in: gesture.view)
        guard let curController = self.children.first else { return }
        guard let gestureView = gesture.view else { return }
        
        if hitPoint.x < gestureView.frame.size.width * 0.3333 {
            //            滑向上一个controller
            if let lastController = self.delegate?.translationController(translationController: self, controllerBefore: curController) {
                
                self.delegate?.translationController(translationController: self, willTransitionTo: lastController)
                
                self.setViewController(viewController: lastController, direction: .right, animated: allowAnimating, completionHandler: {
                    [weak self]
                    (complete) in
                    guard let `self` = self else { return }
                    self.delegate?.translationController(translationController: self, didFinishAnimating: complete, previousController: curController, transitionCompleted: complete)
                })
            }
        }
        
        if hitPoint.x > gestureView.frame.size.width * 0.6666 {
            //            滑向下一个controller
            if let nextController = self.delegate?.translationController(translationController: self, controllerAfter: curController) {
                self.delegate?.translationController(translationController: self, willTransitionTo: nextController)
                self.setViewController(viewController: nextController, direction: .left, animated: allowAnimating, completionHandler: {
                    [weak self]
                    (complete) in
                    guard let `self` = self else { return }
                    self.delegate?.translationController(translationController: self, didFinishAnimating: complete, previousController: curController, transitionCompleted: complete)
                })
            }
        }
    }
    
    //    MAEK: 添加删除controller
    func addController(controller: UIViewController?) {
        guard let controller = controller else {
            return
        }

        self.addChild(controller)
        controller.didMove(toParent: self)
        self.view.addSubview(controller.view)
    }
    
    func removeController(controller: UIViewController?) {
        guard let controller = controller else {
            return
        }

        controller.view.removeFromSuperview()
        controller.willMove(toParent: nil)
        controller.removeFromParent()
    }
    
    
    //    MARK: gesture delegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            let tempWidth = screenWidth * 0.3333
            let hitPoint = gestureRecognizer.location(in: gestureRecognizer.view)
            if hitPoint.x > tempWidth && hitPoint.x < (screenWidth - tempWidth) {
                return true
            }
        }
        
        return false
    }
}
