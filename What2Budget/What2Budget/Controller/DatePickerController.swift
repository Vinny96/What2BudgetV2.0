//
//  DatePickerController.swift
//  What2Budget
//
//  Created by Vinojen Gengatharan on 2021-03-06.
//

import Foundation
import UIKit
import CoreData


class DatePickerController : UIViewController
{
    //variables
    internal var dateKey : String = String() // the date key is what determines where the date is for the starting date or for the ending date.
    private var dateKeyAsDate : String {
        if(dateKey == "Set Start Date")
        {
            let stringToReturn = "Start Date"
            return stringToReturn
        }
        else
        {
            let stringToReturn = "End Date"
            return stringToReturn
        }
    }
    private let defaults = UserDefaults.standard
    
    // Delegates
    internal var deletionCommunicatorDelegate : deletionCommunicator?
    
    //IB Outlets
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeVC()
        
    }
    
    //MARK: - Functions
    
    private func initializeVC()
    {
        title = dateKey
        initializeDatePicker()
        
    }
    
    private func initializeDatePicker()
    {
        let dateToDisplay = defaults.value(forKey: dateKeyAsDate) as! Date
        datePicker.date = dateToDisplay
    }
    
    private func dateHasChanged()
    {
        if(defaults.string(forKey: dateKey) == "")
        {
            saveDate()
        }
        else
        {
            let alertControllerOne = UIAlertController(title: "Important", message: "Please note that when you change the start date or end date that all of your data in the cloud and all of your expenses will be deleted.", preferredStyle: .alert)
            let alertActionOne = UIAlertAction(title: "Okay", style: .destructive) { (alertActionHandler) in
                self.deletionCommunicatorDelegate?.deletionHandler()
                self.saveDate()
            }
            let alertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertControllerOne.addAction(alertActionOne)
            alertControllerOne.addAction(alertActionTwo)
            present(alertControllerOne, animated: true, completion: nil)
        }
    }
    
    private func saveDate()
    {
        let date = datePicker.date
        defaults.setValue(date, forKey: dateKeyAsDate)
        let dateFormatted = date.returnDate()
        print(dateFormatted)
        defaults.setValue(dateFormatted, forKey: dateKey)
        let alertController = UIAlertController(title: "Saved", message: "The date has been saved!!", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Ok", style: .default) { (alertActionHandler) in
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - IB Actions
    @IBAction func saveDatePressed(_ sender: UIButton)
    {
        dateHasChanged()
    }
    
    
    
}
//MARK: - Date Extension
extension Formatter
{
    static let date = DateFormatter()
}

extension Date
{
    func returnDate(dateStyle : DateFormatter.Style = .short, timeStyle : DateFormatter.Style = .none, dateLocale : Locale = Locale.current) -> String
    {
        Formatter.date.locale = dateLocale
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.string(from: self)
    }
}

//MARK: - Communication Pattern
protocol deletionCommunicator {
    
    func deleteAllDictionaries()
    func deleteRecordsInCloud()
    func deleteExpenseModelArray()
    func deletionHandler() // method to call that will take call the other deletion methods
    func deleteContext()
    // testing this
    func printTesting()
}
