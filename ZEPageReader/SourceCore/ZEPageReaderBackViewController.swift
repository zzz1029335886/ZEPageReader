
import UIKit

class ZEPageReaderBackViewController: UIViewController {

    var index: Int = 1
    var backImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        imageView.image = self.backImage
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(imageView)
    }
    
    func grabViewController(viewController: ZEPageReaderViewController) -> Void {
        self.index = viewController.index
        let rect = viewController.view.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let transform = CGAffineTransform(a: -1.0, b: 0.0, c: 0.0, d: 1.0, tx: rect.size.width, ty: 0.0)
        context.concatenate(transform)
        viewController.view.layer.render(in: context)
        self.backImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

}
