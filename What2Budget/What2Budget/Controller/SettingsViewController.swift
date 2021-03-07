//
//  SettingsViewController.swift
//  What2Budget
//
//  Created by Vinojen Gengatharan on 2021-03-06.
//

import Foundation
import CoreData
import CloudKit
import UIKit

class SettingsViewController : UIViewController
{
    // variables
    let defaults = UserDefaults.standard
    internal var tableViewArray : [[String]] = [["Set Start Date","Set End Date", "Set Income"],[ExpenseNames.groceriesExpenseName,ExpenseNames.transportationExpenseName,ExpenseNames.carExpenseName,ExpenseNames.lifeStyleExpenseName,ExpenseNames.shoppingExpenseName,ExpenseNames.subscriptionsExpenseName]]
    
    //IB Outlets
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeVC()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toDatePicker")
        {
            let destinationVC = segue.destination as! DatePickerController
            let indexPath = tableView.indexPathForSelectedRow
            if let safeIndexPath = indexPath
            {
                destinationVC.dateKey = tableViewArray[safeIndexPath.section][safeIndexPath.row]
                let backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
                backBarButtonItem.tintColor = UIColor.black
                destinationVC.navigationItem.backBarButtonItem = backBarButtonItem
            }
        }
    }
    
    
    //MARK: - Functions
    private func initializeVC()
    {
        tableView.register(UINib(nibName: "settingTableViewCell", bundle: .main), forCellReuseIdentifier: "settingsCell")
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 50
        tableView.sectionIndexBackgroundColor = UIColor(named: "homeViewBackground")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func getLengthOfSubArray(section : Int) -> Int // O(1) runtime
    {
        let lengthToReturn = tableViewArray[section].count
        return lengthToReturn
    }
    
    private func cellSelected(indexPath : IndexPath)
    {
        if(indexPath.section == 0)
        {
            if(indexPath.row <= 1)
            {
                performSegue(withIdentifier: "toDatePicker", sender: self)
            }
            else
            {
                var textField = UITextField()
                let alertController = UIAlertController(title: "Set Income", message: "Please enter all anticipated income for the period and do not include the dollar sign.", preferredStyle: .alert)
                alertController.addTextField { (alertControllerTextField) in
                    textField = alertControllerTextField
                    textField.placeholder = String(self.defaults.float(forKey: "Set Income"))
                    textField.keyboardType = .decimalPad
                }
                let alertControllerActionOne = UIAlertAction(title: "Save Income", style: .default) { (alertControllerActionOne) in
                    let textFieldText = textField.text!
                    let textFieldAsFloat = (textFieldText as NSString).floatValue
                    self.defaults.set(textFieldAsFloat, forKey: "Set Income")
                }
                let alertControllerActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(alertControllerActionOne)
                alertController.addAction(alertControllerActionTwo)
                present(alertController, animated: true, completion: nil)
            }
        }
        else
        {
            // so here is where we are setting the allocated amount for the expenses
            var textField = UITextField()
            let alertTitle = ("Set amount for \(tableViewArray[indexPath.section][indexPath.row])")
            let alertMessage = ("Please exclude the dollar sign.")
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            alertController.addTextField { (alertControllerTextField) in
                textField = alertControllerTextField
                textField.placeholder = String(self.defaults.float(forKey: self.tableViewArray[indexPath.section][indexPath.row]))
                textField.keyboardType = .decimalPad
            }
            let alertActionOne = UIAlertAction(title: "Save Amount", style: .default) { (alertActionOne) in
                let textFieldText = textField.text!
                let textFieldTextAsFloat = Float(textFieldText)
                self.defaults.set(textFieldTextAsFloat, forKey: self.tableViewArray[indexPath.section][indexPath.row])
            }
            let alertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(alertActionOne)
            alertController.addAction(alertActionTwo)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    
}
//MARK: - TableView Extensions
extension SettingsViewController : UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cellSelected(indexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0)
        {
            return "Settings"
        }
        else
        {
            return "Expense Settings"
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(named: "HomeViewBackground")
    }
    
}

extension SettingsViewController : UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getLengthOfSubArray(section: section)
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! settingTableViewCell
        cell.cellTitle.text = tableViewArray[indexPath.section][indexPath.row]
        // we need to set the image literal once we make the images we need
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewArray.count
    }
    
    
    
    
}

