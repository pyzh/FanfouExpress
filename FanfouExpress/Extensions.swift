//
//  Extensions.swift
//  FanfouExpress
//
//  Created by Cencen Zheng on 3/26/17.
//  Copyright © 2017 Cencen Zheng. All rights reserved.
//

import UIKit
import Alamofire
import DTCoreText
import SVProgressHUD

extension String {
    
    func height(forFont font: UIFont, forWidth width: CGFloat) -> CGFloat {
        let boundingBox = (self as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                                                          options: .usesLineFragmentOrigin,
                                                          attributes: [NSAttributedStringKey.font: font], context: nil) as CGRect
        return CGFloat(ceilf(Float(boundingBox.height)))
    }
}

extension NSAttributedString {
    
    func height(forOrigin origin: CGPoint, forWidth width: CGFloat) -> CGFloat {
        guard let layouter = DTCoreTextLayouter(attributedString: self) else {
            print("Failed to init layouter with \(self)")
            return 0
        }
        // swiftlint:disable legacy_constructor
        let layoutFrame: DTCoreTextLayoutFrame = layouter.layoutFrame(with: CGRect(origin: origin, size: CGSize(width: width, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))),
                                                                      range: NSMakeRange(0, self.length))
        return layoutFrame.frame.height
    }
}

extension UIDevice {
    
    class var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
}

extension UIFont {
    
    class func defaultFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: Constants.DefaultFontName, size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        return font
    }
}

extension UIImage {
    
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}

extension Data {
    
    func isGifData() -> Bool {
        let ext = [UInt8](self)[0]
        return ext == 0x47
    }
}

extension UITableView {
    
    private func reuseIdentifier(ofClass aClass: AnyClass) -> String {
         return String(describing: aClass)
    }
    
    func register<T: UITableViewCell>(_ : T.Type) {
        register(T.self, forCellReuseIdentifier: reuseIdentifier(ofClass: T.self))
    }
    
    func dequeue<T: UITableViewCell>(indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: reuseIdentifier(ofClass: T.self), for: indexPath) as? T else {
            print("Failed to find \(reuseIdentifier(ofClass: T.self)) for \(T.self)")
            return T.init()
        }
        return cell
    }
}

extension UIViewController {
    
    func startLoading() {
        startLoading(withStatus: "加载中...")
    }
    
    func startLoading(withStatus status: String) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: status)
    }
    
    func stopLoading() {
        SVProgressHUD.setMaximumDismissTimeInterval(0.5)
        SVProgressHUD.dismiss()
    }
    
    func showSuccessMsg(withStatus status: String) {
        SVProgressHUD.showSuccess(withStatus: status)
    }
    
    func showErrorMsg(withStatus status: String) {
        SVProgressHUD.showError(withStatus: status)
    }
    
    /// if viewController is UINavigationController, return its topViewController
    func unwrapNavigationControllerIfNeeded() -> UIViewController {
        guard self is UINavigationController  else { return self }
        guard let naviVC = self as? UINavigationController else { return self }
        guard let top = naviVC.topViewController else { return self }
        return top
    }
}

extension UINavigationController {
        
    func removeBorder() {
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), for: .default)
    }
}
