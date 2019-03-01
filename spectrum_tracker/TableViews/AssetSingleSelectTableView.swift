import Foundation
import UIKit
import DropDown
//import DLRadioButton

class AssetSingleSelectTableView: UITableView {
    
    var tableData = [AssetModel]()
    let reuseIdentifier = "AssetSingleSelectTableViewCell"
    let nibName = "AssetSingleSelectTableView"
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
    
    func setData(_ data: [AssetModel]) {
        self.tableData = data
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeights[indexPath] {
            return height ?? UITableViewAutomaticDimension
        }
        return UITableViewAutomaticDimension
    }
    
    // for this table view only to calculate table height
    func getHeight() -> CGFloat {
        return CGFloat(tableData.count * 41)
    }
    
    
}

// UITableViewDelegate
extension AssetSingleSelectTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "UpdateDriverInfoTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension AssetSingleSelectTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! AssetSingleSelectTableViewCell
        
        cell.setCellData(self.tableData[indexPath.section], TableView: self, Row: indexPath.section)
       
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

class AssetSingleSelectTableViewCell : UITableViewCell {

    var cellData: AssetModel!
    var tableView: AssetSingleSelectTableView!

    var row: Int!
    
    @IBOutlet var wrapperView: UIView!
    
    @IBOutlet var btnSelect: UIButton!
    
    @IBOutlet var labelVehicleName: UILabel!
    @IBOutlet var labelDriverName: UILabel!
    

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
    
    func setCellData(_ data: AssetModel, TableView tableView: AssetSingleSelectTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data

        self.btnSelect.isSelected = self.cellData.isSelected
        self.labelVehicleName.text = self.cellData.name
        self.labelDriverName.text = self.cellData.driverName

        self.row = row
        
        updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    
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
    
    @IBAction func onSelectChange(_ sender: Any) {


        for item in tableView.tableData {
            item.isSelected = false
        }
        
        self.tableView.tableData[row].isSelected = true

        self.tableView.reloadData()

        if tableView.parentVC is ViewControllerWaitingResult {
            (tableView.parentVC as! ViewControllerWaitingResult).setResult(self.cellData, from: "AssetSingleSelectTableViewCell-selectedItem")
        }
    }
}
