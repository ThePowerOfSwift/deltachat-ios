import UIKit

class SettingsAutodelSetController: UITableViewController {

    var dcContext: DcContext

    private struct Options {
        let value: Int
        let descr: String
    }

    private static let autodelDeviceOptions: [Options] = {
        return [
            Options(value: 0, descr: "off"),
            Options(value: 3600, descr: "autodel_after_1_hour"),
            Options(value: 86400, descr: "autodel_after_1_day"),
            Options(value: 604800, descr: "autodel_after_1_week"),
            Options(value: 2419200, descr: "autodel_after_4_weeks"),
        ]
    }()

    private static let autodelServerOptions: [Options] = {
        return [
            Options(value: 0, descr: "off"),
            Options(value: 1, descr: "autodel_at_once"),
            Options(value: 3600, descr: "autodel_after_1_hour"),
            Options(value: 86400, descr: "autodel_after_1_day"),
            Options(value: 604800, descr: "autodel_after_1_week"),
            Options(value: 2419200, descr: "autodel_after_4_weeks"),
        ]
    }()

    private lazy var autodelOptions: [Options] = {
        return fromServer ? SettingsAutodelSetController.autodelServerOptions : SettingsAutodelSetController.autodelDeviceOptions
    }()

    var fromServer: Bool
    var currVal: Int

    private var cancelButton: UIBarButtonItem {
        let button =  UIBarButtonItem(title: String.localized("cancel"), style: .plain, target: self, action: #selector(cancelButtonPressed))
        return button
    }

    private var okButton: UIBarButtonItem {
        let button =  UIBarButtonItem(title: String.localized("ok"), style: .done, target: self, action: #selector(okButtonPressed))
        return button
    }

    var staticCells: [UITableViewCell] {
        return autodelOptions.map({
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = String.localized($0.descr)
            cell.selectionStyle = .none
            cell.accessoryType = $0.value==currVal ? .checkmark : .none
            return cell
        })
    }

    init(dcContext: DcContext, fromServer: Bool) {
        self.dcContext = dcContext
        self.fromServer = fromServer
        self.currVal = dcContext.getConfigInt(fromServer ? "delete_server_after" :  "delete_device_after")
        super.init(style: .grouped)
        self.title = String.localized("autodel_title_short")
        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = okButton
    }

    static public func getSummary(_ dcContext: DcContext, fromServer: Bool) -> String {
        let val = dcContext.getConfigInt(fromServer ? "delete_server_after" :  "delete_device_after")
        let options = fromServer ? SettingsAutodelSetController.autodelServerOptions : SettingsAutodelSetController.autodelDeviceOptions
        for option in options {
            if option.value == val {
                return String.localized(option.descr)
            }
        }
        return "Err"
    }

    func valToIndex(val: Int) -> Int {
        var index = 0
        for option in autodelOptions {
            if option.value == val {
                return index
            }
            index += 1
        }
        return 0 // default to "off"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autodelOptions.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldSelectedCell = tableView.cellForRow(at: IndexPath.init(row: self.valToIndex(val: self.currVal), section: 0))
        let newSelectedCell = tableView.cellForRow(at: IndexPath.init(row: indexPath.row, section: 0))
        let newVal = self.autodelOptions[indexPath.row].value

        if newVal != currVal && newVal != 0 {
            let delCount = dcContext.estimateDeletionCnt(fromServer: fromServer, timeout: newVal)
            let newDescr = "\"" + String.localized(self.autodelOptions[indexPath.row].descr) + "\""
            let msg = String.localizedStringWithFormat(String.localized(fromServer ? "autodel_server_ask" : "autodel_device_ask"), delCount, newDescr)
            let alert = UIAlertController(
                title: String.localized(fromServer ? "autodel_server_title" : "autodel_device_title"),
                message: msg,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String.localized("autodel_confirm"), style: .destructive, handler: { _ in
                oldSelectedCell?.accessoryType = .none
                newSelectedCell?.accessoryType = .checkmark
                self.currVal = newVal
            }))
            alert.addAction(UIAlertAction(title: String.localized("cancel"), style: .cancel))
            present(alert, animated: true, completion: nil)
        } else {
            oldSelectedCell?.accessoryType = .none
            newSelectedCell?.accessoryType = .checkmark
            currVal = newVal
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return staticCells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String.localized(fromServer ? "autodel_server_title" : "autodel_device_title")
    }

    // MARK: - actions

    @objc private func cancelButtonPressed() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func okButtonPressed() {
        dcContext.setConfigInt(fromServer ? "delete_server_after" :  "delete_device_after", currVal)
        navigationController?.popViewController(animated: true)
    }
}