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
    collectionView.reloadData()
    collectionView.collectionViewLayout.invalidateLayout()
    
    // Eski subview'ları temizle
    for subview in collectionView.subviews where !(subview is UICollectionViewCell) {
        subview.removeFromSuperview()
    }
    
    let totalHours = 24 // 0..23
    let hourHeight = courseItemHeight
    let dayCount = dataSource?.numberOfDays(in: self) ?? 7
    let averageWidth = (collectionView.bounds.width - widthOfTimeAxis) / CGFloat(dayCount)
    
    // Saat çizgileri ve etiketler
    for hour in 0..<totalHours {
        let yPosition = heightOfDaySection + CGFloat(hour) * hourHeight
        let line = UIView(frame: CGRect(x: widthOfTimeAxis, y: yPosition, width: collectionView.bounds.width - widthOfTimeAxis, height: 0.5))
        line.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        collectionView.addSubview(line)
        
        let label = UILabel(frame: CGRect(x: 0, y: yPosition - 7, width: widthOfTimeAxis - 4, height: 14))
        label.text = String(format: "%02d:00", hour)
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .right
        label.textColor = .darkGray
        collectionView.addSubview(label)
    }
    
    // Courses ekleme
    let courseItems = self.dataSource?.courseItems(in: self) ?? []
    for (index, course) in courseItems.enumerated() {
        let weekdayIndex = (course.courseDay.rawValue - startDay.rawValue + dayCount) % dayCount
        
        let startHour = Int(course.startTime.split(separator: ":")[0]) ?? 0
        let startMin  = Int(course.startTime.split(separator: ":")[1]) ?? 0
        let endHour   = Int(course.endTime.split(separator: ":")[0]) ?? 0
        let endMin    = Int(course.endTime.split(separator: ":")[1]) ?? 0
        
        let posX = widthOfTimeAxis + CGFloat(weekdayIndex) * averageWidth
        let posY = heightOfDaySection + CGFloat(startHour) * hourHeight + (CGFloat(startMin)/60.0) * hourHeight
        let height = CGFloat(endHour - startHour) * hourHeight + (CGFloat(endMin - startMin)/60.0) * hourHeight
        
        let courseView = UIView(frame: CGRect(x: posX, y: posY, width: averageWidth, height: height))
        courseView.backgroundColor = course.backgroundColor
        courseView.layer.cornerRadius = borderCornerRadius
        courseView.clipsToBounds = true
        
        let label = PaddingLabel(frame: CGRect(x: textEdgeInsets.left, y: textEdgeInsets.top, width: courseView.frame.width - textEdgeInsets.left - textEdgeInsets.right, height: courseView.frame.height - textEdgeInsets.top))
        label.text = course.courseName
        label.textColor = course.textColor ?? .white
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: courseItemTextSize)
        label.textAlignment = courseTextAlignment
        label.sizeToFit()
        label.frame = CGRect(x: textEdgeInsets.left, y: textEdgeInsets.top, width: courseView.frame.width - textEdgeInsets.left - textEdgeInsets.right, height: label.bounds.height)
        courseView.addSubview(label)
        
        courseView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(lectureTapped)))
        courseView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(lectureLongPressed)))
        courseView.tag = index
        label.tag = index
        
        collectionView.addSubview(courseView)
    }
    
    // Sabit content size
    collectionView.contentSize = CGSize(width: collectionView.bounds.width, height: heightOfDaySection + CGFloat(totalHours) * hourHeight)
}

    
    @objc func lectureLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let course = courseItems[(sender.view!).tag]
            self.delegate?.elliotable(elliotable: self, didLongSelectCourse: course)
        }
    }
    
    @objc func lectureTapped(_ sender: UITapGestureRecognizer) {
        let course = courseItems[(sender.view!).tag]
        self.delegate?.elliotable(elliotable: self, didSelectCourse: course)
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
