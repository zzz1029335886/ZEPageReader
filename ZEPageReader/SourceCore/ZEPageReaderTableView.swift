import UIKit


class ZEPageReaderTableView: UITableView {
    
    enum ScrollDirecton {
        case up
        case down
        case unknown
    }
    
    var count = 0
    var cellIndex: Int = 0
    var isReloading = false
    var scrollDirection = ZEPageReaderTableView.ScrollDirecton.unknown
}
