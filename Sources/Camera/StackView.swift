import UIKit
import Photos

class StackView: UIControl, CartDelegate {

  lazy var indicator: UIActivityIndicatorView = self.makeIndicator()
  lazy var imageViews: [UIImageView] = self.makeImageViews()
  lazy var countLabel: UILabel = self.makeCountLabel()
  lazy var tapGR: UITapGestureRecognizer = self.makeTapGR()

  struct Dimensions {
    static let imageSize: CGFloat = 58
  }

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  func setup() {
    addGestureRecognizer(tapGR)
    imageViews.forEach {
      addSubview($0)
    }

    [countLabel, indicator].forEach {
      self.addSubview($0)
    }

    imageViews.first?.alpha = 1
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    let step: CGFloat = 3.0
    let scale: CGFloat = 0.8
    let imageViewSize = CGSize(width: frame.width * scale,
                          height: frame.height * scale)

    for (index, imageView) in imageViews.enumerate() {
      let origin = CGPoint(x: CGFloat(index) * step,
                           y: CGFloat(imageViews.count - index) * step)
      imageView.frame = CGRect(origin: origin, size: imageViewSize)
    }
  }

  // MARK: - Action

  func viewTapped(gr: UITapGestureRecognizer) {
    sendActionsForControlEvents(.TouchUpInside)
  }

  // MARK: - Logic

  func startLoader() {
    if let firstVisibleView = imageViews.filter({ $0.alpha == 1.0 }).last {
      indicator.frame.origin.x = firstVisibleView.center.x
      indicator.frame.origin.y = firstVisibleView.center.y
    }

    indicator.startAnimating()
    UIView.animateWithDuration(0.3) {
      self.indicator.alpha = 1.0
    }
  }

  func imageDidPush(notification: NSNotification) {
    let emptyView = imageViews.filter { $0.image == nil }.first

    if let emptyView = emptyView {
      animateImageView(emptyView)
    }

    /*
    if let sender = notification.object as? ImageStack {
      renderViews(sender.assets)
      indicator.stopAnimating()
    }
     */
  }

  func imageStackDidChangeContent(notification: NSNotification) {
    /*
    if let sender = notification.object as? ImageStack {
      renderViews(sender.assets)
      indicator.stopAnimating()
    }
     */
  }

  func renderViews(assets: [PHAsset]) {
    if let firstView = imageViews.first where assets.isEmpty {
      imageViews.forEach{
        $0.image = nil
        $0.alpha = 0
      }

      firstView.alpha = 1
      return
    }

    let photos = Array(assets.suffix(4))

    for (index, view) in imageViews.enumerate() {
      if index <= photos.count - 1 {
        Fetcher.resolveAsset(photos[index], size: CGSize(width: Dimensions.imageSize, height: Dimensions.imageSize)) { image in
          view.image = image
        }
        view.alpha = 1
      } else {
        view.image = nil
        view.alpha = 0
      }

      if index == photos.count {
        UIView.animateWithDuration(0.3) {
          self.indicator.frame.origin = CGPoint(x: view.center.x + 3, y: view.center.x + 3)
        }
      }
    }
  }

  private func animateImageView(imageView: UIImageView) {
    imageView.transform = CGAffineTransformMakeScale(0, 0)

    UIView.animateWithDuration(0.3, animations: {
      imageView.transform = CGAffineTransformMakeScale(1.05, 1.05)
    }) { _ in
      UIView.animateWithDuration(0.2, animations: { () -> Void in
        self.indicator.alpha = 0.0
        imageView.transform = CGAffineTransformIdentity
        }, completion: { _ in
          self.indicator.stopAnimating()
      })
    }
  }

  // MARK: - CartDelegate

  func cart(cart: Cart, didAdd image: Image) {
    renderViews(cart.images.map { $0.asset })
  }

  func cart(cart: Cart, didRemove image: Image) {
    renderViews(cart.images.map { $0.asset })
  }

  func cartDidReload(cart: Cart) {
    renderViews(cart.images.map { $0.asset })
  }

  // MARK: - Controls

  func makeIndicator() -> UIActivityIndicatorView {
    let indicator = UIActivityIndicatorView()
    indicator.alpha = 0

    return indicator
  }

  func makeImageViews() -> [UIImageView] {
    return Array(0..<Config.Camera.StackView.imageCount).map { _ in
      let imageView = UIImageView()

      imageView.contentMode = .ScaleAspectFill
      imageView.alpha = 0
      Utils.addRoundBorder(imageView)

      return imageView
    }
  }

  func makeCountLabel() -> UILabel {
    let label = UILabel()
    label.textColor = UIColor.whiteColor()
    label.font = UIFont.systemFontOfSize(20)
    label.hidden = true

    return label
  }

  func makeTapGR() -> UITapGestureRecognizer {
    let gr = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))

    return gr
  }
}
