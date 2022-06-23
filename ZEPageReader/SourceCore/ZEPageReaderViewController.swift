import UIKit

class ZEPageReaderViewController: UIViewController {
    var index: Int = 1
    var backgroundImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        if backgroundImage != nil {
            let imageView = UIImageView.init(frame: self.view.frame)
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.image = backgroundImage
            self.view.insertSubview(imageView, at: 0)
        }
    }
}
