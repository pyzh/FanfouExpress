//
//  ImageScrollView.swift
//  FanfouExpress
//
//  Created by Cencen Zheng on 4/20/17.
//  Copyright © 2017 Cencen Zheng. All rights reserved.
//

import UIKit
import FLAnimatedImage

class ImageScrollView: UIScrollView {

    var imageView: UIImageView {
        return zoomView
    }
    
    fileprivate var zoomView: UIImageView
    fileprivate var imageSize: CGSize = CGSize.zero
    fileprivate var pointToCenterAfterResize: CGPoint = CGPoint.zero
    fileprivate var scaleToRestoreAfterResize: CGFloat = 0
    
    fileprivate var maximumContentOffset: CGPoint {
        return CGPoint(x: contentSize.width - bounds.width, y: contentSize.height - bounds.height)
    }
    
    fileprivate var minimumContentOffset: CGPoint {
        return CGPoint.zero
    }
    
    override var frame: CGRect {
        didSet {
            prepareToResize()
            super.frame = frame
            recoverFromResizing()
        }
    }
    
    override init(frame: CGRect) {
        zoomView = UIImageView()
        super.init(frame: frame)
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.bouncesZoom = true
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        centerImage()
    }

    func display(_ image: AnyObject) {
        // clear the previous image
        if zoomView.superview != nil {
            zoomView.removeFromSuperview()
        }
        
        // reset our zoomScale to 1.0 before doing any further calculations
        zoomScale = 1.0
        minimumZoomScale = 1.0
        maximumZoomScale = 1.0
        
        // make a new UIImageView for the new image
        switch image {
        case let staticImage as UIImage:
            zoomView = UIImageView(image: staticImage)
            configureForImageSize(staticImage.size)
        case let animatedImage as FLAnimatedImage:
            zoomView = FLAnimatedImageView(frame: CGRect(origin: CGPoint.zero, size: animatedImage.size))
            guard let zoomView = zoomView as? FLAnimatedImageView else { return }
            zoomView.animatedImage = animatedImage
            configureForImageSize(animatedImage.size)
        default:
            print("Unsupport image type \(image.self)")
            return
        }
        
        addSubview(zoomView)
    }
    
    func zoomRect(forPoint point: CGPoint, withScale scale: CGFloat) -> CGRect {
        let w = frame.width / scale
        let h = frame.height / scale
        let center = imageView.convert(point, from: self)
        let x = center.x - w / 2.0
        let y = center.y - h / 2.0
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    class func scale(forBounds bounds: CGRect, _ imageSize: CGSize) -> (minScale: CGFloat, maxScale: CGFloat) {
        // calculate min/max zoomscale
        let xScale: CGFloat = bounds.width / imageSize.width // the scale needed to perfectly fit the image width-wise
        let yScale: CGFloat = bounds.height / imageSize.height  // the scale needed to perfectly fit the image height-wise
        
        // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
        let imagePortrait = imageSize.height > imageSize.width
        let phonePortrait = bounds.height > bounds.width
        var minScale: CGFloat = imagePortrait == phonePortrait ? xScale : fmin(xScale, yScale)
        
        let maxScale: CGFloat = 1.0
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }
        // An error may happen with affine transformations when scaling UIScrollView instance to 0
        // See: http://stackoverflow.com/a/38502345
        else if minScale < 0.01 {
            minScale = 0.01
        }
        
        return (minScale, maxScale)
    }
}

extension ImageScrollView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}

private extension ImageScrollView {
    
    func centerImage() {        
        // center the zoom view as it becomes smaller than the size of the screen
        let boundsSize = bounds.size
        var frameToCenter = zoomView.frame
        
        // center horizontally
        if frameToCenter.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.width) / 2.0
        } else {
            frameToCenter.origin.x = 0
        }
        
        // center vertically
        if frameToCenter.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.height) / 2.0
        } else {
            frameToCenter.origin.y = 0
        }
        
        zoomView.frame = frameToCenter
    }
    
    func configureForImageSize(_ size: CGSize) {
        imageSize = size
        contentSize = size
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale
    }
    
    func setMaxMinZoomScalesForCurrentBounds() {
        let scaleMinMax = ImageScrollView.scale(forBounds: bounds, imageSize)
        
        minimumZoomScale = scaleMinMax.minScale
        maximumZoomScale = scaleMinMax.maxScale
    }
    
    func prepareToResize() {
        let boundsCenter: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize  = convert(boundsCenter, to: zoomView)
        scaleToRestoreAfterResize = zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        
        // Step 1: restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale: CGFloat = fmax(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = fmax(maximumZoomScale, maxZoomScale)
        
        // Step 2: restore center point, first making sure it is within the allowable range.
        
        // 2a: convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, to: zoomView)
        
        // 2b: calculate the content offset that would yield that center point
        var offset: CGPoint = CGPoint(x: boundsCenter.x - bounds.width / 2.0, y: boundsCenter.y - bounds.height / 2.0)
        
        // 2c: restore offset, adjusted to be within the allowable range
        let maxOffset: CGPoint = maximumContentOffset
        let minOffset: CGPoint = minimumContentOffset
        
        var realMaxOffset: CGFloat = fmin(maxOffset.x, offset.x)
        offset.x = fmax(minOffset.x, realMaxOffset)
        
        realMaxOffset = fmin(maxOffset.y, offset.y)
        offset.y = fmax(minOffset.y, realMaxOffset)
        
        contentOffset = offset
    }
}
