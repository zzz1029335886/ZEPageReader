//
//  ViewController.swift
//  ZEPageReader
//
//  Created by zerry on 2022/6/23.
//

import UIKit

class ViewController: UIViewController, ZEPageReaderDelegate {
    func pageReaderDidClick(pageReader: ZEPageReader, isMiddle: Bool) {
        print(isMiddle)
    }
    
    func pageReader(pageReader: ZEPageReader, viewFor index: Int) -> UIView {
        views[index]
    }
    
    func numberOf(pageReader: ZEPageReader) -> Int {
        views.count
    }
    
    var views: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view0 = UIView.init()
        view0.backgroundColor = .red
        let view1 = UIView.init()
        view1.backgroundColor = .blue
        let view2 = UIView.init()
        view2.backgroundColor = .green
        let view3 = UIView.init()
        view3.backgroundColor = .gray
        
        views = [view0, view1, view2, view3]
        
        view.backgroundColor = .white
        
        let config = ZEPageReaderConfiguration.init()
        config.scrollType = .none
        
        let pageReader = ZEPageReader.init(config: config)
        pageReader.delegate = self
        
        pageReader.view.frame = self.view.bounds
        pageReader.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(pageReader.view)
        self.addChild(pageReader)
        
        pageReader.start(pageReaderIndex: 0)
    }


}

