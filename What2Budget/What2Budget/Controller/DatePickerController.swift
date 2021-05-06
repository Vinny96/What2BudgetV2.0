//
//  DatePickerController.swift
//  What2Budget
//
//  Created by Vinojen Gengatharan on 2021-03-06.
//

import Foundation
import UIKit
import CoreData
import CloudKit


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
    private let userPrivateCloudDataBase = CKContainer(identifier: "iCloud.vinnyMadeApps.What2Budget").privateCloudDatabase
    internal var expenseNameRecordDict : [String : CKRecord] = [:]
    var arrayOfExpenseNames : [String] = [ExpenseNames.groceriesExpenseName,ExpenseNames.transportationExpenseName,ExpenseNames.carExpenseName,ExpenseNames.lifeStyleExpenseName,ExpenseNames.shoppingExpenseName,ExpenseNames.subscriptionsExpenseName]
    
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
        let dateToDisplay = defaults.value(forKey: dateKeyAsDate)
        if(dateToDisplay == nil)
        {
            datePicker.setDate(Date(), animated: true)
            // this displays the current date as the default date for the datePicker. 
            
        }
    }
    
    private func dateHasChanged()
    {
        if(defaults.string(forKey: dateKey) == "")
        {
            // this code runs during initial setup and only runs during initial setup.
            saveDate()
        }
        else
        {
            let alertControllerOne = UIAlertController(title: "Important", message: "Please note that when you change the start date or end date that all of your data in the cloud and all of your expenses will be moved.", preferredStyle: .alert)
            let alertActionOne = UIAlertAction(title: "Okay", style: .destructive) { (alertActionHandler) in
                self.saveRecordsToOldRecordsZoneHandler()
                self.deletionCommunicatorDelegate?.deletionHandler()
                self.saveDate()
            }
            let alertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertControllerOne.addAction(alertActionOne)
            alertControllerOne.addAction(alertActionTwo)
            present(alertControllerOne, animated: true, completion: nil)
        }
    }
    
    private func saveRecordsToOldRecordsZoneHandler()
    {
        // so basically here what we need to do is fetch all of the records from the default zone of cloud kit database
        // then we have to make a copy of each record we fetch. Save that copy to the zone that is going to hold all of the old records.
        // We then have to delete that record from the default zone and make sure we also empty all the dictionaries in the home view controller as well.
        if(expenseNameRecordDict.isEmpty == false)
        {
            fetchCurrentRecordsAndCreateNewRecords()
        }
        /**
         So what we are doing here is this if statement is whats going to determine whether the fetchCurrentRecords code should run. So when the user changes the start date or the end date and presses save this usually means they are moving onto a new pay period. So what we are doing here is if the dictionary is not empty that means we have to run the code and if it is empty this means the code has already run so there is no need to run it again.
         */
    }
    
    private func fetchCurrentRecordsAndCreateNewRecords()
    {
       for expenseName in expenseNameRecordDict
       {
            let recordID = expenseName.value.recordID
        userPrivateCloudDataBase.fetch(withRecordID: recordID) { (ckRecordRetrieved, error) in
            if(ckRecordRetrieved != nil && error == nil)
            {
                //let newCKRecord = CKRecord(recordType: "Expense")
                let newCKRecordZoneID = CKRecordZone.ID(zoneName: "Old Records Zone", ownerName: CKCurrentUserDefaultName)
                let uniqueRecordName = UUID().uuidString
                let newCKRecordID = CKRecord.ID(recordName: uniqueRecordName, zoneID: newCKRecordZoneID)
                let newCKRecord = CKRecord(recordType: "Expense", recordID: newCKRecordID)
                /**
                 What we are doing above is creating our record and setting the zone of that record to be our Old Records Zone
                 */
                
                
                let expenseType = ckRecordRetrieved?.value(forKey: "expenseType")
                let amountAllocated = ckRecordRetrieved?.value(forKey: "amountAllocated")
                let amountSpent = ckRecordRetrieved?.value(forKey: "amountSpent")
                let startingTimePeriod = ckRecordRetrieved?.value(forKey: "startingTimePeriod")
                let endingTimePeriod = ckRecordRetrieved?.value(forKey: "endingTimePeriod")
                
                newCKRecord.setValue(expenseType, forKey: "expenseType")
                newCKRecord.setValue(amountAllocated, forKey: "amountAllocated")
                newCKRecord.setValue(amountSpent, forKey: "amountSpent")
                newCKRecord.setValue(startingTimePeriod, forKey: "startingTimePeriod")
                newCKRecord.setValue(endingTimePeriod, forKey: "endingTimePeriod")
                
                self.userPrivateCloudDataBase.save(newCKRecord) { (ckRecord, error) in
                    if(ckRecord != nil && error == nil)
                    {
                        print("Record was saved to the Old Records Zone of the database successfully.")
                    }
                    else
                    {
                        print("There was an error in saving the record to the old records zone.")
                    }
                }
                
            }
        }
    }
    expenseNameRecordDict.removeAll()
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
