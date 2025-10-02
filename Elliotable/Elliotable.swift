//
//  Elliotable.swift
//  Elliotable
//
//  Copyright © 2019 TaeinKim. All rights reserved.
//

import Foundation
import UIKit

public protocol ElliotableDelegate {
    func elliotable(elliotable: Elliotable, didSelectCourse selectedCourse: ElliottEvent)
    
    func elliotable(elliotable: Elliotable, didLongSelectCourse longSelectedCourse : ElliottEvent)

    func elliotable(elliotable: Elliotable, didSelectDay dayIndex: Int, dayName: String)
}

public protocol ElliotableDataSource {
    func elliotable(elliotable: Elliotable, at dayPerIndex: Int) -> String
    
    func numberOfDays(in elliotable: Elliotable) -> Int
    
    func courseItems(in elliotable: Elliotable) -> [ElliottEvent]
}

public enum roundOption: Int {
    case none  = 0
    case left  = 1
    case right = 2
    case all   = 3
}

@IBDesignable public class Elliotable: UIView {
    private let controller     = ElliotableController()
    private let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    
// defaultMinHour ve defaultMaxEnd artık public, 0–24 aralığı için
    @IBInspectable public var defaultMinHour: Int = 0 {
    didSet { makeTimeTable() }
    }
    @IBInspectable public var defaultMaxEnd: Int = 24 {
    didSet { makeTimeTable() }
    }
    
    public var userDaySymbol: [String]?
    public var delegate: ElliotableDelegate?
    public var dataSource: ElliotableDataSource?
    
    public var courseCells = [ElliotableCell]()
    
    public var startDay = ElliotDay.monday {
        didSet {
            makeTimeTable()
        }
    }
    
    public var timeTableScrollEnabled: Bool = true {
        didSet {
            collectionView.isScrollEnabled = timeTableScrollEnabled
        }
    }
    
    public var isFullBorder: Bool = false {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var courseItemHeight : CGFloat = 60.0 {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var weekDayTextColor = UIColor.black {
        didSet {
            makeTimeTable()
        }
    }
    
    public var courseItems = [ElliottEvent]() {
        didSet {
            makeTimeTable()
        }
    }
    
    public var roundCorner: roundOption = roundOption.none {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var elliotBackgroundColor = UIColor.clear {
        didSet {
            collectionView.backgroundColor = backgroundColor
        }
    }
    
    @IBInspectable public var symbolBackgroundColor = UIColor.clear {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var symbolFontSize = CGFloat(10) {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var symbolTimeFontSize = CGFloat(10) {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var symbolFontColor = UIColor.black {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var symbolTimeFontColor = UIColor.black {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var heightOfDaySection = CGFloat(28) {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var widthOfTimeAxis = CGFloat(32) {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var borderWidth = CGFloat(0) {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var borderColor = UIColor.clear {
        didSet {
            makeTimeTable()
        }
    }
    
    @IBInspectable public var borderCornerRadius = CGFloat(0) {
        didSet {
            self.makeTimeTable()
        }
    }
    
    private var rectEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            self.makeTimeTable()
        }
    }
    
    @IBInspectable public var textEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            self.makeTimeTable()
        }
    }
    
    @IBInspectable public var courseItemTextSize = CGFloat(11) {
        didSet {
            self.makeTimeTable()
        }
    }
    
    @IBInspectable public var roomNameFontSize = CGFloat(9) {
        didSet {
            self.makeTimeTable()
        }
    }
    
    @IBInspectable public var courseTextAlignment = NSTextAlignment.center {
        didSet {
            self.makeTimeTable()
        }
    }
    
    @IBInspectable public var courseItemMaxNameLength = 0 {
        didSet {
            self.makeTimeTable()
        }
    }
    
    public var daySymbols: [String] {
        var daySymbolText = [String]()
        
        if let count = self.dataSource?.numberOfDays(in: self) {
            for index in 0..<count {
                let text = self.dataSource?.elliotable(elliotable: self, at: index) ?? Calendar.current.shortStandaloneWeekdaySymbols[index]
                daySymbolText.append(text)
            }
        }
        
        let startIndex = self.startDay.rawValue - 1
        daySymbolText.rotate(shiftingToStart: startIndex)
        return daySymbolText
    }
    
    public var minimumCourseStartTime: Int?
    
    var averageWidth: CGFloat {
        return (collectionView.frame.width - widthOfTimeAxis) / CGFloat(daySymbols.count)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        controller.elliotable = self
        controller.collectionView = collectionView
        
        collectionView.dataSource = controller
        collectionView.delegate = controller
        collectionView.backgroundColor = backgroundColor
        
        addSubview(collectionView)
        makeTimeTable()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        makeTimeTable()
    }
    
private func makeTimeTable() {
    collectionView.subviews.forEach { view in
        if !(view is UICollectionViewCell) {
            view.removeFromSuperview()
        }
    }
    
    guard let courseItems = self.dataSource?.courseItems(in: self), courseItems.count > 0 else {
        minimumCourseStartTime = defaultMinHour
        return
    }
    
    // Minimum ve maksimum saat
    let startHours = courseItems.compactMap { Int($0.startTime.split(separator: ":")[0]) }
    let endHours   = courseItems.compactMap { Int($0.endTime.split(separator: ":")[0]) }
    
    let minStart = startHours.min() ?? defaultMinHour
    let maxEnd   = (endHours.max() ?? defaultMaxEnd) + 1
    minimumCourseStartTime = minStart
    
    let dayCount = dataSource?.numberOfDays(in: self) ?? 7
    let averageHeight = courseItemHeight
    
    // Lecture’ları çiz
    for (index, courseItem) in courseItems.enumerated() {
        let weekdayIndex = (courseItem.courseDay.rawValue - startDay.rawValue + dayCount) % dayCount
        
        let startParts = courseItem.startTime.split(separator: ":").compactMap { Int($0) }
        let endParts   = courseItem.endTime.split(separator: ":").compactMap { Int($0) }
        
        guard startParts.count == 2, endParts.count == 2 else { continue }
        
        let startHour = startParts[0]
        let startMin  = startParts[1]
        let endHour   = endParts[0]
        let endMin    = endParts[1]
        
        let positionX = widthOfTimeAxis + averageWidth * CGFloat(weekdayIndex) + rectEdgeInsets.left
        let positionY = heightOfDaySection + averageHeight * CGFloat(startHour - minStart) +
                        (CGFloat(startMin) / 60.0) * averageHeight + rectEdgeInsets.top
        let width = averageWidth - rectEdgeInsets.left - rectEdgeInsets.right
        let height = averageHeight * CGFloat(endHour - startHour) +
                     (CGFloat(endMin - startMin) / 60.0) * averageHeight -
                     rectEdgeInsets.top - rectEdgeInsets.bottom
        
        let courseView = UIView(frame: CGRect(x: positionX, y: positionY, width: width, height: height))
        courseView.backgroundColor = courseItem.backgroundColor
        courseView.layer.cornerRadius = (roundCorner == .all) ? borderCornerRadius : 0
        courseView.tag = index
        
        // Label
        let label = PaddingLabel(frame: CGRect(x: textEdgeInsets.left, y: textEdgeInsets.top, width: width - textEdgeInsets.left - textEdgeInsets.right, height: height - textEdgeInsets.top))
        let name = courseItem.courseName
        let attrStr = NSMutableAttributedString(string: name + "\n" + courseItem.roomName,
                                                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: roomNameFontSize)])
        attrStr.setAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: courseItemTextSize)], range: NSRange(0..<name.count))
        label.attributedText = attrStr
        label.numberOfLines = 0
        label.textAlignment = courseTextAlignment
        label.textColor = courseItem.textColor ?? .white
        label.isUserInteractionEnabled = false
        courseView.addSubview(label)
        
        // Gesture
        courseView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(lectureTapped)))
        courseView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(lectureLongPressed)))
        
        self.addSubview(courseView)
    }
    
    // Gün başlıklarını çiz
    for (index, symbol) in daySymbols.enumerated() {
        let labelFrame = CGRect(
            x: widthOfTimeAxis + averageWidth * CGFloat(index),
            y: 0,
            width: averageWidth,
            height: heightOfDaySection
        )
        let label = UILabel(frame: labelFrame)
        label.text = symbol
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: symbolFontSize, weight: .medium)
        label.textColor = weekDayTextColor
        label.isUserInteractionEnabled = true
        label.tag = index
        
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dayTapped)))
        self.addSubview(label)
    }
}


    
    @objc func lectureLongPressed(_ sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
        guard let tag = sender.view?.tag,
              tag >= 0, tag < courseItems.count else { return }
        let course = courseItems[tag]
        delegate?.elliotable(elliotable: self, didLongSelectCourse: course)
    }
    }
    
    @objc func lectureTapped(_ sender: UITapGestureRecognizer) {
    guard let tag = sender.view?.tag,
          tag >= 0, tag < courseItems.count else { return }
    let course = courseItems[tag]
    delegate?.elliotable(elliotable: self, didSelectCourse: course)
    }

    @objc private func dayTapped(_ sender: UITapGestureRecognizer) {
    guard let label = sender.view as? UILabel else { return }
    let index = label.tag
    let symbol = daySymbols[index]
    delegate?.elliotable(elliotable: self, didSelectDay: index, dayName: symbol)
}
    
    public func reloadData() {
        courseItems = self.dataSource?.courseItems(in: self) ?? [ElliottEvent]()
    }
}

extension Array {
    func rotated(shiftingToStart middle: Index) -> Array {
        return Array(suffix(count - middle) + prefix(middle))
    }
    
    mutating func rotate(shiftingToStart middle: Index) {
        self = rotated(shiftingToStart: middle)
    }
}

extension String {
    func truncated(_ length: Int) -> String {
        let end = index(startIndex, offsetBy: length, limitedBy: endIndex) ?? endIndex
        return String(self[..<end])
    }
    
    mutating func truncate(_ length: Int) {
        self = truncated(length)
    }
}

extension UILabel {
    func textWidth() -> CGFloat {
        return UILabel.textWidth(label: self)
    }
    
    class func textWidth(label: UILabel) -> CGFloat {
        return textWidth(label: label, text: label.text!)
    }
    
    class func textWidth(label: UILabel, text: String) -> CGFloat {
        return textWidth(font: label.font, text: text)
    }
    
    class func textWidth(font: UIFont, text: String) -> CGFloat {
        let myText = text as NSString
        
        let rect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(labelSize.width)
    }
}
