//
//  ScalePicker.swift
//  Dmitry Klimkin
//
//  Created by Dmitry Klimkin on 12/11/15.
//  Copyright © 2016 Dmitry Klimkin. All rights reserved.
//

import Foundation
import UIKit

public typealias ValueFormatter = (CGFloat) -> NSAttributedString
public typealias ValueChangeHandler = (CGFloat) -> Void

public enum ScalePickerValuePosition {
    case top
    case left
}

public protocol ScalePickerDelegate {
    func didChangeScaleValue(_ picker: ScalePicker, value: CGFloat)
    func willChangeScaleValue(_ picker: ScalePicker, value: CGFloat)
}

@IBDesignable
open class ScalePicker: UIView, SlidePickerDelegate {

    open var delegate: ScalePickerDelegate?

    open var valueChangeHandler: ValueChangeHandler = {(value: CGFloat) in

    }

    open var valuePosition = ScalePickerValuePosition.top {
        didSet {
            layoutSubviews()
        }
    }

    @IBInspectable
    open var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    @IBInspectable
    open var gradientMaskEnabled: Bool = false {
        didSet {
            picker.gradientMaskEnabled = gradientMaskEnabled
        }
    }

    @IBInspectable
    open var invertValues: Bool = false {
        didSet {
            picker.invertValues = invertValues
        }
    }

    @IBInspectable
    open var trackProgress: Bool = false {
        didSet {
            progressView.alpha = trackProgress ? 1.0 : 0.0
        }
    }

    @IBInspectable
    open var invertProgress: Bool = false {
        didSet {
            layoutProgressView(currentProgress)
        }
    }

    @IBInspectable
    open var fillSides: Bool = false {
        didSet {
            picker.fillSides = fillSides
        }
    }

    @IBInspectable
    open var elasticCurrentValue: Bool = false

    @IBInspectable
    open var highlightCenterTick: Bool = true {
        didSet {
            picker.highlightCenterTick = highlightCenterTick
        }
    }

    @IBInspectable
    open var allTicksWithSameSize: Bool = false {
        didSet {
            picker.allTicksWithSameSize = allTicksWithSameSize
        }
    }

    @IBInspectable
    open var showCurrentValue: Bool = false {
        didSet {
            valueLabel.alpha = showCurrentValue ? 1.0 : 0.0

            showTickLabels = !showTickLabels
            showTickLabels = !showTickLabels
        }
    }

    @IBInspectable
    open var blockedUI: Bool = false {
        didSet {
            picker.blockedUI = blockedUI
        }
    }

    @IBInspectable
    open var numberOfTicksBetweenValues: UInt = 4 {
        didSet {
            picker.numberOfTicksBetweenValues = numberOfTicksBetweenValues
            reset()
        }
    }

    @IBInspectable
    open var minValue: CGFloat = -3.0 {
        didSet {
            picker.minValue = minValue
            reset()
        }
    }

    @IBInspectable
    open var maxValue: CGFloat = 3.0 {
        didSet {
            picker.maxValue = maxValue
            reset()
        }
    }

    @IBInspectable
    open var spaceBetweenTicks: CGFloat = 10.0 {
        didSet {
            picker.spaceBetweenTicks = spaceBetweenTicks
            reset()
        }
    }

    @IBInspectable
    open var centerViewWithLabelsYOffset: CGFloat = 15.0 {
        didSet {
            updateCenterViewOffset()
        }
    }

    @IBInspectable
    open var centerViewWithoutLabelsYOffset: CGFloat = 15.0 {
        didSet {
            updateCenterViewOffset()
        }
    }

    @IBInspectable
    open var pickerOffset: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
        }
    }

    @IBInspectable
    open var tickColor: UIColor = UIColor.white {
        didSet {
            picker.tickColor = tickColor
            centerImageView.image = centerArrowImage?.tintImage(tickColor)
            titleLabel.textColor = tickColor
        }
    }

    @IBInspectable
    open var progressColor: UIColor = UIColor.white {
        didSet {
            progressView.backgroundColor = progressColor
        }
    }

    @IBInspectable
    open var progressViewSize: CGFloat = 3.0 {
        didSet {
            progressView.frame = CGRect(x: 0, y: 0, width: progressViewSize, height: progressViewSize)
            progressView.layer.cornerRadius = progressViewSize / 2

            layoutProgressView(currentProgress)
        }
    }

    @IBInspectable
    open var centerArrowImage: UIImage? {
        didSet {
            centerImageView.image = centerArrowImage
            reset()
        }
    }

    @IBInspectable
    open var showTickLabels: Bool = true {
        didSet {
            picker.showTickLabels = showTickLabels

            updateCenterViewOffset()

            layoutSubviews()
        }
    }

    @IBInspectable
    open var snapEnabled: Bool = false {
        didSet {
            picker.snapEnabled = snapEnabled
        }
    }

    @IBInspectable
    open var showPlusForPositiveValues: Bool = true {
        didSet {
            picker.showPlusForPositiveValues = showPlusForPositiveValues
        }
    }

    @IBInspectable
    open var fireValuesOnScrollEnabled: Bool = true {
        didSet {
            picker.fireValuesOnScrollEnabled = fireValuesOnScrollEnabled
        }
    }

    @IBInspectable
    open var bounces: Bool = false {
        didSet {
            picker.bounces = bounces
        }
    }

    @IBInspectable
    open var sidePadding: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
        }
    }

    open var currentTransform: CGAffineTransform = CGAffineTransform.identity {
        didSet {
            applyCurrentTransform()
        }
    }

    open func applyCurrentTransform() {
        picker.currentTransform = currentTransform

        if valuePosition == .left {
            valueLabel.transform = currentTransform
        }
    }

    open var values: [CGFloat]? {
        didSet {
            guard let values = values, values.count > 1 else { return; }

            picker.values = values

            maxValue = values[values.count - 1]
            minValue = values[0]
            initialValue = values[0]
        }
    }

    open var valueFormatter: ValueFormatter = {(value: CGFloat) -> NSAttributedString in
        let attrs = [NSForegroundColorAttributeName: UIColor.white,
                     NSFontAttributeName: UIFont.systemFont(ofSize: 15.0)]

        return NSMutableAttributedString(string: value.format(".2"), attributes: attrs)
    }

    open var rightView: UIView? {
        willSet(newRightView) {
            if let view = rightView {
                view.removeFromSuperview()
            }
        }

        didSet {
            if let view = rightView {
                addSubview(view)
            }

            layoutSubviews()
        }
    }

    open var leftView: UIView? {
        willSet(newLeftView) {
            if let view = leftView {
                view.removeFromSuperview()
            }
        }

        didSet {
            if let view = leftView {
                addSubview(view)
            }

            layoutSubviews()
        }
    }

    fileprivate let centerImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    fileprivate let centerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    fileprivate let titleLabel = UILabel()
    fileprivate let valueLabel = UILabel()
    fileprivate var currentProgress: CGFloat = 0.5
    fileprivate var progressView = UIView()
    fileprivate var initialValue: CGFloat = 0.0
    fileprivate var picker: SlidePicker!
    fileprivate var shouldUpdatePicker = true

    open var currentValue: CGFloat = 0.0 {
        didSet {
            if shouldUpdatePicker {
                picker.scrollToValue(currentValue, animated: true)
            }

            valueLabel.attributedText = valueFormatter(currentValue)
            layoutValueLabel()
            updateProgressAsync()
        }
    }

    fileprivate func updateProgressAsync() {
        let popTime = DispatchTime.now() + Double(Int64(1.0 * CGFloat(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

        DispatchQueue.main.asyncAfter(deadline: popTime) {
            self.picker.updateCurrentProgress()

            if self.trackProgress {
                UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in

                    self.progressView.alpha = 1.0
                    }, completion: nil)
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    open func commonInit() {
        isUserInteractionEnabled = true

        titleLabel.textColor = tickColor
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 13.0)

        addSubview(titleLabel)

        valueLabel.textColor = tickColor
        valueLabel.textAlignment = .center
        valueLabel.font = UIFont.systemFont(ofSize: 13.0)

        addSubview(valueLabel)

        centerImageView.contentMode = .center
        centerImageView.center = CGPoint(x: centerView.frame.size.width / 2, y: centerView.frame.size.height / 2 + 5)

        centerView.addSubview(centerImageView)

        picker = SlidePicker(frame: CGRect(x: sidePadding, y: 0, width: frame.size.width - sidePadding * 2, height: frame.size.height))

        picker.numberOfTicksBetweenValues = numberOfTicksBetweenValues
        picker.minValue = minValue
        picker.maxValue = maxValue
        picker.delegate = self
        picker.snapEnabled = snapEnabled
        picker.showTickLabels = showTickLabels
        picker.highlightCenterTick = highlightCenterTick
        picker.bounces = bounces
        picker.tickColor = tickColor
        picker.centerView = centerView
        picker.spaceBetweenTicks = spaceBetweenTicks

        updateCenterViewOffset()

        addSubview(picker)

        progressView.frame = CGRect(x: 0, y: 0, width: progressViewSize, height: progressViewSize)
        progressView.backgroundColor = UIColor.white
        progressView.alpha = 0.0
        progressView.layer.masksToBounds = true
        progressView.layer.cornerRadius = progressViewSize / 2

        addSubview(progressView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ScalePicker.onDoubleTap(_:)))

        tapGesture.numberOfTapsRequired = 2

        addGestureRecognizer(tapGesture)
    }

    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        layoutSubviews()
        reset()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        picker.frame = CGRect(x: sidePadding, y: pickerOffset,
                                  width: frame.size.width - sidePadding * 2, height: frame.size.height)
        picker.layoutSubviews()

        let xOffset = gradientMaskEnabled ? picker.frame.size.width * 0.05 : 0.0

        if let view = rightView {
            view.center = CGPoint(x: frame.size.width - xOffset - sidePadding / 2, y: picker.center.y + 5)
        }

        if let view = leftView {
            if valuePosition == .left {
                view.center = CGPoint(x: xOffset + sidePadding / 2, y: ((frame.size.height / 2) - view.frame.height / 4) + 5)
            } else {
                view.center = CGPoint(x: xOffset + sidePadding / 2, y: picker.center.y + 5)
            }
        }

        titleLabel.frame = CGRect(x: xOffset, y: 5, width: sidePadding, height: frame.size.height)

        if valuePosition == .top {
            valueLabel.frame = CGRect(x: sidePadding, y: 5,
                                          width: frame.width - sidePadding * 2, height: frame.size.height / 4.0)
        } else {
            layoutValueLabel()
        }
    }

    open func onDoubleTap(_ recognizer: UITapGestureRecognizer) {
        reset()
    }

    open func onValueChangeAndPropagateToDelegate(_ newValue: CGFloat) {
        if currentValue != newValue {
            delegate?.willChangeScaleValue(self, value: newValue)
            currentValue = newValue
            delegate?.didChangeScaleValue(self, value: currentValue)
            valueChangeHandler(currentValue)
        }
    }

    open func reset() {
        onValueChangeAndPropagateToDelegate(initialValue)

        progressView.alpha = 0.0
        updateProgressAsync()
    }

    open func increaseValue() {
        picker.increaseValue()
    }

    open func decreaseValue() {
        picker.decreaseValue()
    }

    open func setInitialCurrentValue(_ value: CGFloat) {
        shouldUpdatePicker = false

        currentValue = value
        initialValue = value

        picker.scrollToValue(value, animated: false)

        shouldUpdatePicker = true

        progressView.alpha = 0.0
    }

    open func didSelectValue(_ value: CGFloat) {
        shouldUpdatePicker = false

        onValueChangeAndPropagateToDelegate(value)

        shouldUpdatePicker = true
    }

    open func didChangeContentOffset(_ offset: CGFloat, progress: CGFloat) {
        layoutProgressView(progress)

        guard elasticCurrentValue else { return }

        let minScale: CGFloat    = 0.0
        let maxScale: CGFloat    = 0.25
        let maxOffset: CGFloat   = 50.0
        var offsetShift: CGFloat = 0.0
        var scaleShift: CGFloat  = 1.0
        var offsetValue          = offset

        if offset < 0 {
            scaleShift = -maxScale
            offsetShift = 50.0
            offsetValue = offset + offsetShift
        }

        var value = min(maxScale, max(minScale, offsetValue * (maxScale / maxOffset)))

        value += scaleShift

        if offset < 0 {
            if value < 0 {
                if invertValues {
                    value = fabs(value) + 1
                } else {
                    value += 1
                }
            }
        } else {
            if invertValues {
                value = 1 - (value - scaleShift)
            }
        }

        valueLabel.transform = currentTransform.scaledBy(x: value, y: value)
    }

    fileprivate func updateCenterViewOffset() {
        picker.centerViewOffsetY = showTickLabels ? centerViewWithLabelsYOffset : centerViewWithoutLabelsYOffset
    }

    fileprivate func layoutProgressView(_ progress: CGFloat) {
        currentProgress = progress

        let updatedProgress = invertProgress ? 1.0 - progress : progress
        let xOffset = gradientMaskEnabled ? picker.frame.origin.x + (picker.frame.size.width * 0.1) : picker.frame.origin.x
        let progressWidth = gradientMaskEnabled ? picker.frame.size.width * 0.8 : picker.frame.size.width
        let scaledValue = progressWidth * updatedProgress
        var yOffset = pickerOffset + 4 + frame.size.height / 3

        if title.isEmpty && valuePosition == .left  {
            yOffset -= 6
        }

        progressView.center = CGPoint(x: xOffset + scaledValue, y: yOffset)
    }

    fileprivate func layoutValueLabel() {
        let text = valueLabel.attributedText

        guard let textValue = text else { return }

        let textWidth = valueWidth(textValue)
        var signOffset: CGFloat = 0

        if textValue.string.contains("+") || textValue.string.contains("-") {
            signOffset = 2
        }

        let xOffset = gradientMaskEnabled ? picker.frame.size.width * 0.05 : 0.0

        if valuePosition == .left {
            if let view = leftView {
                valueLabel.frame = CGRect(x: view.center.x - signOffset - textWidth / 2, y: 5 + frame.size.height / 2, width: textWidth, height: 16)
            } else {
                valueLabel.frame = CGRect(x: sidePadding, y: 5, width: textWidth, height: frame.size.height)
                valueLabel.center = CGPoint(x: xOffset + sidePadding / 2, y: frame.size.height / 2 + 5)
            }
        } else {
            valueLabel.frame = CGRect(x: 0, y: 5, width: textWidth, height: frame.size.height - 10)
            valueLabel.center = CGPoint(x: xOffset + sidePadding / 2, y: frame.size.height / 2 - 5)
        }
    }

    fileprivate func valueWidth(_ text: NSAttributedString) -> CGFloat {
        let rect = text.boundingRect(with: CGSize(width: 1024, height: frame.size.width), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)

        return rect.width + 10
    }
}

private extension Double {
    func format(_ f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

private extension Float {
    func format(_ f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

private extension CGFloat {
    func format(_ f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
