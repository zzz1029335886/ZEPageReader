import UIKit

class ZEPageReaderConfiguration: NSObject {
    var contentInsets: UIEdgeInsets = .zero{
        didSet{
            if contentInsets == oldValue {
                return
            }
            
            self.didContentInsetsChanged?(contentInsets)
        }
    }
    
    var contentFrame: CGRect = UIScreen.main.bounds{
        didSet{
            if contentFrame.equalTo(oldValue) {
                return
            }
            
            self.didContentFrameChanged?(contentFrame)
        }
    }
    
    var backgroundImage: UIImage? {
        didSet {
            if backgroundImage == oldValue {
                return
            }
            self.didBackgroundImageChanged?(backgroundImage)
        }
    }
    
    var scrollType = ZEPageReader.ScrollType.curl {
        didSet {
            if scrollType == oldValue {
                return
            }
            self.didScrollTypeChanged?(scrollType)
        }
    }
    
    var index: Int = -1{
        didSet{
            if index == oldValue{
                return
            }
            
            self.didPageIndexChanged?(index)
        }
    }
    
    /// 是否点击两边翻页
    var isTapPageTurning = true{
        didSet{
            self.didTapPageTurningChanged?(isTapPageTurning)
        }
    }
            
    var didTapPageTurningChanged: ((Bool) -> Void)?
    
    var didContentFrameChanged: ((CGRect) -> Void)?
    var didBackgroundImageChanged: ((UIImage?) -> Void)?
    var didContentInsetsChanged: ((UIEdgeInsets) -> Void)?
    var didPageIndexChanged: ((Int) -> Void)?
    var didScrollTypeChanged: ((ZEPageReader.ScrollType) -> Void)?
    
    override init() {
        super.init()
        self.contentFrame = UIScreen.main.bounds
    }
    
}
