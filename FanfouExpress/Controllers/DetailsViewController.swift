//
//  DetailsViewController.swift
//  FanfouExpress
//
//  Created by Cencen Zheng on 3/30/17.
//  Copyright © 2017 Cencen Zheng. All rights reserved.
//

import UIKit
import DTCoreText
import SafariServices

class DetailsViewController: UITableViewController, PhotoBrowserTransitionSupport {
    
    enum RowType: Int {
        case header  = 0
        case content
        case unknown
    }
    
    var msg: Message?
    var transitionImage: UIImage
    var transitionImageView: UIImageView
    
    fileprivate var dataArray: [UITableViewCell]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override init(style: UITableViewStyle) {
        self.msg = nil
        self.transitionImage = UIImage()
        self.transitionImageView = UIImageView()
        self.dataArray = [UITableViewCell]()
        super.init(style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()

        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        
        setupDataArray()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
}

// MARK: - TableView Delegate

extension DetailsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let msg = msg else {
            return 0
        }
        
        switch indexPath.row {
        case RowType.header.rawValue:
            return DetailHeaderCell.height(forWidth: view.bounds.width)
        case RowType.content.rawValue:
            let width = view.bounds.width - DetailCellStyle.ContentInsets.left - DetailCellStyle.ContentInsets.right
            return TimelineTableViewCell.height(forMessage: msg, forWidth: width, forContentInsets: DetailCellStyle.ContentInsets)
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dataArray[indexPath.row]
    }
}

// MARK: - Transition delegate

extension DetailsViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is PhotoBrowserController {
            return PhotoBrowserAnimator()
        }
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is PhotoBrowserController {
            return PhotoBrowserAnimator()
        }
        return nil
    }
    
}

// MARK: - DTAttributedTextContentViewDelegate

extension DetailsViewController: DTAttributedTextContentViewDelegate {
    
    func attributedTextContentView(_ attributedTextContentView: DTAttributedTextContentView!, viewForLink url: URL!, identifier: String!, frame: CGRect) -> UIView! {
        let linkButton = DTLinkButton(frame: frame)
        linkButton.url = url
        linkButton.addTarget(self, action: #selector(pressedLinkButton), for: .touchUpInside)
        return linkButton
    }
}

// MARK: - SFSafariViewControllerDelegate

extension DetailsViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Private methods

private extension DetailsViewController {
    
    func setupDataArray() {
        guard let msg = msg else {
            return
        }
        
        let headerCell = DetailHeaderCell(style: .default, reuseIdentifier: nil)
        headerCell.updateCell(withAvatar: msg.avatarURL)
        
        let contentCell = TimelineTableViewCell(style: .default, reuseIdentifier: nil)
        contentCell.textDelegate = self
        contentCell.contentInsets = DetailCellStyle.ContentInsets
        contentCell.updateCell(msg)
        
        if let url = msg.image?.previewURL {
            contentCell.tapPreviewImageBlock = { (tappedImageView) in
                self.transitionImageView = tappedImageView
                self.transitionImage = tappedImageView.image ?? UIImage.imageWithColor(color: .lightGray)
                
                let controller = PhotoBrowserController(withURL: url, TLCell.PlaceholderImage)
                controller.modalPresentationStyle = .custom
                controller.transitioningDelegate = self
                self.present(controller, animated: true, completion: nil)
            }
        }
        
        dataArray = [headerCell, contentCell]
    }
    
    func setupNavigationBar() {
        navigationController?.removeBorder()
        navigationController?.hidesBarsOnSwipe = true
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 5
        
        let dismissButton = UIBarButtonItem(image: #imageLiteral(resourceName: "navi-down"), style: .plain, target: self, action: #selector(pressedDismissButton))
        dismissButton.tintColor = FFEColor.AccentColor
        navigationItem.leftBarButtonItems = [spacer, dismissButton]
        
        let shareButton = UIBarButtonItem(image: #imageLiteral(resourceName: "navi-share"), style: .plain, target: self, action: #selector(pressedShareButton))
        shareButton.tintColor = FFEColor.AccentColor
        navigationItem.rightBarButtonItems = [spacer, shareButton]
    }
    
    @objc func pressedDismissButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func pressedShareButton() {
        guard let msg = msg else { return }
        guard let contentCell = dataArray[RowType.content.rawValue] as? TimelineTableViewCell else { return }
        
        var activityItems:[Any] = [contentCell.parsedContent]
        
        if let statusURL = msg.statusURL {
            activityItems.append(statusURL)
        }
        if  let image = contentCell.imageView?.image {
            activityItems.append(image)
        }
        
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.modalPresentationStyle = .custom
        controller.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
            if completed {
                print("[UIActivityViewController]: Succeed")
            } else {
                print(activityError?.localizedDescription ?? "[UIActivityViewController]: Failed")
            }
        }
        present(controller, animated: true, completion: nil)
    }
    
    @objc func pressedLinkButton(sender: DTLinkButton) {
        guard let url = sender.url else { return }
        
        if url.scheme == Constants.HTTPScheme || url.scheme == Constants.HTTPSScheme {
            let safariController = SFSafariViewController(url: url)
            safariController.delegate = self
            safariController.modalPresentationStyle = .custom
            safariController.preferredControlTintColor = FFEColor.AccentColor
            present(safariController, animated: true, completion: nil)
        }
    }
}

