import Foundation
import UIKit

class UpdateDriverInfoTableView: UITableView {
    
    var tableData = [AssetModel]()
    let reuseIdentifier = "UpdateDriverInfoTableViewCell"
    let nibName = "UpdateDriverInfoTableView"
    let cellSpacingHeight:CGFloat = 2
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
        self.backgroundColor = UIColor.clear

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

}

// UITableViewDelegate
extension UpdateDriverInfoTableView: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if parentVC is ViewControllerWaitingResult {
//            (parentVC as! ViewControllerWaitingResult).setResult(self.tableData[indexPath.section], from: "UpdateDriverInfoTableView-selectedItem")
//        }
//    }
    
}

// UITableViewDataSource
extension UpdateDriverInfoTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! UpdateDriverInfoTableViewCell
        
        cell.setCellData(tableData[indexPath.section], TableView: self, Row: indexPath.section)
       
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

class UpdateDriverInfoTableViewCell : UITableViewCell {

    var cellData: AssetModel!
    var tableView: UpdateDriverInfoTableView!

    @IBOutlet var wrapperView: UIView!
    
    @IBOutlet var txtDriverName: UITextField!
    @IBOutlet var txtDriverPhone: UITextField!
    @IBOutlet var txtVehicleName: UITextField!

    var contentViewMainConstraints = [NSLayoutConstraint]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
         self.updateSnapWrapper2ContentViewConstraints(UILayoutPriority(rawValue: 999))
    }
    
    func updateSnapWrapper2ContentViewConstraints(_ priority: UILayoutPriority) {
        
        if(!contentViewMainConstraints.isEmpty){
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
    
    func setCellData(_ data: AssetModel, TableView tableView: UpdateDriverInfoTableView, Row row: Int) {
        self.tableView = tableView
        self.cellData = data
        
        txtDriverName.text = self.cellData.driverName
        txtDriverPhone.text = self.cellData.driverPhoneNumber
        txtVehicleName.text = self.cellData.name
        
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
    
    @IBAction func onUpdate(_ sender: Any) {
        
        let driverName = txtDriverName.text ?? ""
        let driverPhone = txtDriverPhone.text ?? ""
        let vehicleName = txtVehicleName.text ?? ""
        
        if self.tableView.parentVC is ViewControllerWaitingResult {
            (self.tableView.parentVC as! ViewControllerWaitingResult).setResult((driverName, driverPhone, vehicleName, self.cellData._id), from: "UpdateDriverInfoTableView-updateDriverItem")
        }
    }
}
