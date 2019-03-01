import Foundation
import UIKit
import DropDown
import MapboxGeocoder

class VelocityTableView: UITableView {
    
    var tableData = [AssetModel: TrackerModel]()
    var cellHeight:CGFloat = 0;
    let reuseIdentifier = "VelocityTableViewCell"
    let nibName = "VelocityTableView"
    let cellSpacingHeight:CGFloat = 0
    private var cellHeights: [IndexPath: CGFloat?] = [:]
    
    var parentVC: UIViewController?
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        
        self.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        
        self.rowHeight = UITableViewAutomaticDimension
        self.estimatedRowHeight = 0

        self.separatorStyle = .none
        self.backgroundView = nil
        self.backgroundColor = UIColor(hexInt: 0xffffff)

        self.delegate = self
        self.dataSource = self
        
    }
    
    func setData(_ data: [AssetModel: TrackerModel]) {
        self.tableData = data
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.keys.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.height
        cellHeight = cell.frame.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeights[indexPath] {
            return height ?? UITableViewAutomaticDimension
        }
        return UITableViewAutomaticDimension
    }

    
    // for this table view only to calculate table height
    func getHeight() -> CGFloat {
        return CGFloat(CGFloat(tableData.keys.count) * 108.5)
    }
    
}

// UITableViewDelegate
extension VelocityTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "UpdateDriverInfoTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension VelocityTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! VelocityTableViewCell
        
        
        let key = tableData.keys[tableData.keys.index(tableData.keys.startIndex, offsetBy: indexPath.section)]
        let value = tableData[key]
        
        cell.setCellData((key, value!), TableView: self, Row: indexPath.section)
       
        return cell
    }
    
    override func numberOfRows(inSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear

        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
}

class VelocityTableViewCell : UITableViewCell {

    var cellData: (AssetModel, TrackerModel)!
    var tableView: VelocityTableView!

    @IBOutlet var wrapperView: UIStackView!
    @IBOutlet var labelName: UILabel!
    @IBOutlet var labelSpeed: UILabel!
    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var labelVoltage: UILabel!
    @IBOutlet var labelLastStart: UILabel!
    @IBOutlet var labelLastStartAddress: UILabel!
    @IBOutlet var labelLastStop: UILabel!
    @IBOutlet var labelLastStopAddress: UILabel!
    @IBOutlet var labelAlert: UILabel!
    @IBOutlet var labelSpeeding: UILabel!
    @IBOutlet var labelDayTrip: UILabel!
    @IBOutlet var labelHashAcce: UILabel!
    @IBOutlet var labelHashDece: UILabel!
    @IBOutlet var labelMonthTrip: UILabel!
    @IBOutlet var labelYearTrip: UILabel!
    var geocoder: Geocoder!
    var geocodingDataTask1: URLSessionDataTask?
    var geocodingDataTask2: URLSessionDataTask?
    var vehicleExist: Bool = false
    var accOnChanged: Bool = true
    var accOffChanged: Bool = true
    var contentViewMainConstraints = [NSLayoutConstraint]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
         self.updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    
    func updateSnapWrapper2ContentViewConstraints(_ priority: UILayoutPriority) {
        
        if(!contentViewMainConstraints.isEmpty) {
            for constraint in contentViewMainConstraints {
                constraint.isActive = false
            }
        }
        contentViewMainConstraints.removeAll()
        
        let leadingAnchor = wrapperView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let traillingAnchor = wrapperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        let topAnchor = wrapperView.topAnchor.constraint(equalTo: contentView.topAnchor)
        let bottomAnchor = wrapperView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        
        leadingAnchor.priority = priority
        traillingAnchor.priority = priority
        topAnchor.priority = priority
        bottomAnchor.priority = priority
        
        contentViewMainConstraints = [
            leadingAnchor,
            traillingAnchor,
            topAnchor,
            bottomAnchor
        ]
        
        NSLayoutConstraint.activate(contentViewMainConstraints)
    }
    
    func setCellData(_ data: (AssetModel, TrackerModel), TableView tableView: VelocityTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
       /* print("\(self.labelName.text):\(self.cellData.0.name)")
        if(self.labelName.text != "--") {
            self.vehicleExist = true
        }
        else {
            self.vehicleExist = false
        }*/
        self.labelName.text = self.cellData.0.name
        self.labelSpeed.text = self.cellData.1.speedInMph.priceString() + " mph"
        if(self.cellData.1.accStatus == 0) {
            self.labelStatus.text = "Park"
            self.labelSpeed.text = "0 mph"
        }
        else {
            self.labelStatus.text = "Drive"
        }
        if(self.cellData.1.trackerModel.lowercased() == "huaheng") {
            self.labelVoltage.text = String(self.cellData.1.voltage)
            if(Float(self.cellData.1.tankVolume * 100) > 100) {
               // self.labelFuel.text = "100"
            }
            else {
               // self.labelFuel.text = String(Float(self.cellData.1.tankVolume * 100))
            }
        }
        else {
            self.labelVoltage.text = "N/A"
         //   self.labelFuel.text = "N/A"
        }
        if self.cellData.1.lastACCOntime != nil {
            self.labelLastStart.text = self.cellData.1.lastACCOntime.toString("MM/dd HH:mm")
        }
        else {
            self.labelLastStart.text = "N/A"
        }
        if self.cellData.1.lastACCOfftime != nil {
            self.labelLastStop.text = self.cellData.1.lastACCOfftime.toString("MM/dd HH:mm")
        }
        else {
            self.labelLastStop.text = "N/A"
        }
        self.labelVoltage.text = self.cellData.1.expirationDate.toString("YYYY/MM/dd")
        //self.labelThisTrip.text = String(format:"%.1f",self.cellData.1.weekMile)
        self.labelDayTrip.text = String(format:"%.1f",self.cellData.1.dayMile)
        self.labelMonthTrip.text = String(format:"%.1f",self.cellData.1.monthMile)
        self.labelYearTrip.text = String(format:"%.1f",self.cellData.1.yearMile)
        self.labelLastStartAddress.text = self.cellData.1.lastStartAddress
        self.labelLastStopAddress.text = self.cellData.1.lastStopAddress
        self.labelSpeeding.text = String(self.cellData.1.speeding)
        self.labelHashAcce.text = String(self.cellData.1.harshAcce)
        self.labelHashDece.text = String(self.cellData.1.harshDece)
        self.labelAlert.text = String(self.cellData.1.alert)
        updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    
//    func UTCToLocal(date:String, fromFormat: String, toFormat: String) -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = fromFormat
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        
//        let dt = dateFormatter.date(from: date)
//        dateFormatter.timeZone = TimeZone.current
//        dateFormatter.dateFormat = toFormat
//        
//        return dateFormatter.string(from: dt!)
//    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        let clearView = UIView()
        clearView.backgroundColor = UIColor.clear
        self.selectedBackgroundView = clearView
        
        self.backgroundView = clearView
        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        
        self.selectionStyle = .none
    }
    
}
