import UIKit
import SwiftUI

protocol ZEPageReaderDelegate: NSObjectProtocol {
    func pageReaderDidClick(pageReader: ZEPageReader, isMiddle: Bool)
    func pageReader(pageReader: ZEPageReader, viewFor index: Int) -> UIView
    func numberOf(pageReader: ZEPageReader) -> Int
}

extension ZEPageReaderDelegate{
    func pageReaderDidClick(pageReader: ZEPageReader, isMiddle: Bool) {}
}

class ZEPageReader: UIViewController,
              UIPageViewControllerDelegate,
              UIPageViewControllerDataSource,
              UIGestureRecognizerDelegate,
              UITableViewDataSource,
              UITableViewDelegate,
              ZEPageReaderTranslationProtocol
{
    
    enum ScrollType: Int {
        case curl = 0
        case horizontal
        case vertical
        case none
    }
    
    required init(config: ZEPageReaderConfiguration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 配置类
    public var config: ZEPageReaderConfiguration
    /// 代理
    public var delegate: ZEPageReaderDelegate?
    /// pageReader vc
    private var pageReaderVC: UIPageViewController?
    /// table view
    private var tableView: ZEPageReaderTableView?
    /// translation vc
    private var translationVC: ZEPageReaderAtranslationController?
    /// 是否重分页
    private var isReCutPage: Bool = false
    /// 当前页面
    private var currentPageIndex: Int = 0
    /// 首次进阅读器
    private var firstIntoReader = true
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK:--对外接口
    public func start(pageReaderIndex: Int) {
        processPageArray(pageReaderIndex: pageReaderIndex)
    }
    
    private func processPageArray(pageReaderIndex: Int) {
        if firstIntoReader {
            firstIntoReader = false
            currentPageIndex = pageReaderIndex <= 0 ? 0 : (pageReaderIndex - 1)
            self.loadPage(pageReaderIndex: currentPageIndex)
        }
        
        if isReCutPage {
            isReCutPage = false
            self.loadPage(pageReaderIndex: currentPageIndex)
        }
    }
    
    /// 弹出设置菜单
    ///
    /// - Parameter ges: 单击手势
    @objc private func pagingTap(ges: UITapGestureRecognizer) -> Void {
        let tapPoint = ges.location(in: self.view)
        let width = self.view.frame.width
        let rect = CGRect(x: width * 0.3333, y: 0, width: width * 0.3333, height: self.view.frame.height)
        self.delegate?.pageReaderDidClick(pageReader: self, isMiddle: rect.contains(tapPoint))
    }
    
    // MARK:--UI渲染
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(pagingTap(ges:)))
        self.view.addGestureRecognizer(tapGesture)
        self.addObserverForConfiguration()
        self.loadReaderView()
    }
    
    private func loadReaderView() -> Void {
        switch self.config.scrollType {
        case .curl:
            self.loadPageViewController()
        case .vertical:
            self.loadTableView()
        case .horizontal:
            self.loadTranslationVC(animating: true)
        case .none:
            self.loadTranslationVC(animating: false)
        }
        
        if self.config.backgroundImage != nil {
            self.loadBackgroundImage()
        }
    }
    
    private func loadPageViewController() {
        
        self.clearReaderViewIfNeed()
        let transtionStyle: UIPageViewController.TransitionStyle = (self.config.scrollType == .curl) ? .pageCurl : .scroll
        let pageReaderVC = UIPageViewController(transitionStyle: transtionStyle, navigationOrientation: .horizontal, options: nil)
        pageReaderVC.dataSource = self
        pageReaderVC.delegate = self
        pageReaderVC.view.backgroundColor = UIColor.clear
        pageReaderVC.isDoubleSided = (self.config.scrollType == .curl) ? true : false
        
        self.addChild(pageReaderVC)
        self.view.addSubview(pageReaderVC.view)
        pageReaderVC.didMove(toParent: self)
        pageReaderVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.pageReaderVC = pageReaderVC
    }
    
    private func loadTableView() -> Void {
        
        self.clearReaderViewIfNeed()
        let tableView = ZEPageReaderTableView(frame: CGRect.init(x: 0, y: config.contentFrame.origin.y, width: UIScreen.main.bounds.size.width, height: config.contentFrame.size.height), style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 0
        tableView.scrollsToTop = false
        tableView.backgroundColor = UIColor.clear
        self.view.addSubview(tableView)
        self.tableView = tableView
    }
    
    /// bool值意味着平移翻页还是无动画翻页
    ///
    /// - Parameter animating: none
    func loadTranslationVC(animating: Bool) -> Void {
        
        self.clearReaderViewIfNeed()
        let translationVC = ZEPageReaderAtranslationController()
        translationVC.delegate = self
        translationVC.allowAnimating = animating
        translationVC.isTapPageTurning = config.isTapPageTurning
        
        self.addChild(translationVC)
        translationVC.didMove(toParent: self)
        self.view.addSubview(translationVC.view)
        
        self.translationVC = translationVC
    }
    
    private func loadPage(pageReaderIndex: Int) {
        guard let delegate = delegate else {
            return
        }
                
        switch self.config.scrollType {
        case .curl:
            let pageReader = self.getPageVCWith(pageReaderIndex: pageReaderIndex)
            self.pageReaderVC?.setViewControllers([pageReader], direction: .forward, animated: false, completion: nil)
            
        case .vertical:
            let count = delegate.numberOf(pageReader: self)
            tableView?.count = count
            
            self.tableView?.cellIndex = pageReaderIndex
            if tableView?.count == nil {
                return
            }
            
            self.tableView?.isReloading = true
            self.tableView?.reloadData()
            self.tableView?.scrollToRow(at: IndexPath.init(row: tableView!.cellIndex, section: 0), at: UITableView.ScrollPosition.top, animated: false)
            self.tableView?.isReloading = false
            
        default :
            let pageReader = self.getPageVCWith(pageReaderIndex: pageReaderIndex)
            self.translationVC?.setViewController(viewController: pageReader, direction: .left, animated: false, completionHandler: nil)
        }
    }
    
    private func loadBackgroundImage() -> Void {
        var curPage: ZEPageReaderViewController? = nil
        
        if config.scrollType == .curl {
            if let _curPage = pageReaderVC?.viewControllers?.first as? ZEPageReaderViewController{
                curPage = _curPage
                
                let imageView = _curPage.view.subviews.first as? UIImageView
                imageView?.image = self.config.backgroundImage
            }
        }
        
        if config.scrollType == .horizontal || config.scrollType == .none {
            curPage = translationVC?.children.first as? ZEPageReaderViewController
            if curPage != nil {
                let imageView = curPage?.view.subviews.first as! UIImageView
                imageView.image = self.config.backgroundImage
            }
        }
        
        if let firstView = self.view.subviews.first as? UIImageView {
            firstView.image = self.config.backgroundImage
        }else {
            let imageView = UIImageView.init(frame: self.view.frame)
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.image = self.config.backgroundImage
            self.view.insertSubview(imageView, at: 0)
        }
    }
    
    func clearReaderViewIfNeed() -> Void {
        if let pageReaderVC = pageReaderVC {
            pageReaderVC.view.removeFromSuperview()
            pageReaderVC.willMove(toParent: nil)
            pageReaderVC.removeFromParent()
        }
        
        if tableView != nil {
            for item in self.view.subviews {
                item.removeFromSuperview()
            }
        }
        
        if let translationVC = translationVC {
            translationVC.view.removeFromSuperview()
            translationVC.willMove(toParent: nil)
            translationVC.removeFromParent()
        }
    }
    
    /// 仿真、平移、无动画翻页模式使用
    ///
    /// - Parameters:
    ///   - pageReaderIndex: 页面索引
    ///   - chapterIndex: 章节索引
    /// - Returns: 单个pageReader页面
    private func getPageVCWith(pageReaderIndex: Int) -> ZEPageReaderViewController {
        let pageReader = ZEPageReaderViewController()
        
        pageReader.index = pageReaderIndex
        
        if self.config.backgroundImage != nil {
            pageReader.backgroundImage = self.config.backgroundImage
        }
        
        let frame = CGRect(x: 0, y: config.contentFrame.origin.y, width: self.view.frame.width, height: config.contentFrame.height).inset(by: config.contentInsets)
        
        if Int(frame.width) * Int(frame.height) != .zero,
           let contentView = self.delegate?.pageReader(pageReader: self, viewFor: pageReaderIndex){
            contentView.frame = frame
            pageReader.view.addSubview(contentView)
        }
        
        return pageReader
    }
    
    // MARK:--属性观察器
    private func addObserverForConfiguration() {
        self.config.didContentFrameChanged = {
            [weak self]
            (String) in
            self?.reloadReader()
        }
        
        self.config.didTapPageTurningChanged = {
            [weak self]
            (isTapPageTurning) in
            guard let `self` = self else { return }
            self.translationVC?.isTapPageTurning = isTapPageTurning
        }
        
        self.config.didContentInsetsChanged = {
            [weak self]
            (scrollType) in
            self?.reloadReader()
        }
        
        self.config.didPageIndexChanged = {
            [weak self]
            (pageReaderIndex) in
            self?.reloadReader()
        }
        
        self.config.didBackgroundImageChanged = {
            [weak self]
            (UIImage) in
            self?.loadBackgroundImage()
        }
        
        self.config.didScrollTypeChanged = {
            [weak self]
            (scrollType) in
            self?.loadReaderView()
            self?.loadPage(pageReaderIndex: self!.currentPageIndex)
        }
        
    }
    
    private func reloadReader()  {
        isReCutPage = true
        self.start(pageReaderIndex: currentPageIndex)
    }
    
    // MARK:--PageVC Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard config.isTapPageTurning else {
            return nil
        }
        
        if let pageReader = viewController as? ZEPageReaderViewController {
            let backPage = ZEPageReaderBackViewController()
            let nextIndex = pageReader.index - 1
            
            if nextIndex < 0 {
                return nil
            }
            
            backPage.grabViewController(viewController: self.getPageVCWith(pageReaderIndex: nextIndex))
            return backPage
        }
        
        if let back = viewController as? ZEPageReaderBackViewController{
            return self.getPageVCWith(pageReaderIndex: back.index)
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let delegate = delegate, config.isTapPageTurning else {
            return nil
        }
        
        let count = delegate.numberOf(pageReader: self)
        
        if let pageReader = viewController as? ZEPageReaderViewController {
            let nextIndex = pageReader.index + 1
            if nextIndex >= count {
                return nil
            }
            
            let backPage = ZEPageReaderBackViewController()
            backPage.grabViewController(viewController: pageReader)
            return backPage
        }
        
        if let back = viewController as? ZEPageReaderBackViewController{
            return self.getPageVCWith(pageReaderIndex: back.index + 1)
        }
        
        return nil
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let controller = pageViewController.viewControllers?.first else { return }
        self.containerController(currentController: controller)
    }
    
    func containerController(currentController: UIViewController){
        if let curPage = currentController as? ZEPageReaderViewController{
            currentPageIndex = curPage.index
        }
    }
    
    
    // MARK:--Table View Delegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return config.contentFrame.height
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableView?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView?.dequeueReusableCell(withIdentifier: "dua.reader.cell")
        if let subviews = cell?.contentView.subviews {
            for item in subviews {
                item.removeFromSuperview()
            }
        }
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "dua.reader.cell")
            cell?.backgroundColor = .clear
            cell?.selectionStyle = .none
        }
        
        if let view = self.delegate?.pageReader(pageReader: self, viewFor: indexPath.row),
           let cell = cell{
            view.frame = cell.contentView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cell.contentView.addSubview(view)
        }
        
        return cell!
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = tableView else {
            return
        }
        
        if tableView.isReloading {
            return
        }
        
        var contentOffsetY = scrollView.contentOffset.y
        if scrollView.contentOffset.y <= 0 {
            contentOffsetY = 0
        }
        
        let basePoint = CGPoint(x: config.contentFrame.width * 0.5, y: contentOffsetY + config.contentFrame.height * 0.5)
        guard let majorIndexPath = tableView.indexPathForRow(at: basePoint) else { return }
        
        if majorIndexPath.row > tableView.cellIndex { // 向后翻页
            
            tableView.cellIndex = majorIndexPath.row
            currentPageIndex = tableView.cellIndex
        }else if majorIndexPath.row < tableView.cellIndex {     //向前翻页
            tableView.cellIndex = majorIndexPath.row
            currentPageIndex = tableView.cellIndex
        }
    }
    
    // MARK: DUATranslationController Delegate
    
    func translationController(translationController: ZEPageReaderAtranslationController, controllerAfter controller: UIViewController) -> UIViewController? {
        guard let delegate = delegate else {
            return nil
        }
        
        let count = delegate.numberOf(pageReader: self)
        
        let nextIndex: Int
        var nextPage: ZEPageReaderViewController? = nil
        
        if let pageReader = controller as? ZEPageReaderViewController {
            nextIndex = pageReader.index + 1
            if nextIndex >= count {
                return nil
            }
            
            nextPage = self.getPageVCWith(pageReaderIndex: nextIndex)
        }
        
        return nextPage
    }
    
    func translationController(translationController: ZEPageReaderAtranslationController, controllerBefore controller: UIViewController) -> UIViewController? {
        
        var nextPage: ZEPageReaderViewController? = nil
        if let pageReader = controller as? ZEPageReaderViewController {
            let nextIndex = pageReader.index - 1
            if nextIndex < 0 {
                return nil
            }else {
                nextPage = self.getPageVCWith(pageReaderIndex: nextIndex)
            }
        }
        
        return nextPage
    }
    
    func translationController(translationController: ZEPageReaderAtranslationController, willTransitionTo controller: UIViewController) {
    }
    
    func translationController(translationController: ZEPageReaderAtranslationController, didFinishAnimating finished: Bool, previousController: UIViewController, transitionCompleted completed: Bool)
    {
        guard let controller = previousController.children.first else { return }
        self.containerController(currentController: controller)
    }
    
}
