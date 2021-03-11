//
//  HomeViewController.swift
//  What2Budget
//
//  Created by Vinojen Gengatharan on 2021-03-06.
//

import Foundation
import UIKit
import CoreData
import CloudKit

class HomeViewController : UIViewController
{
    // variables
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let defaults = UserDefaults.standard
    var arrayOExpenseModelObjects : [ExpenseModel] = []
    
    var amountSpentDict : [String : Float] = [ExpenseNames.groceriesExpenseName : 0,ExpenseNames.transportationExpenseName : 0,ExpenseNames.carExpenseName: 0,ExpenseNames.lifeStyleExpenseName : 0,ExpenseNames.shoppingExpenseName : 0,ExpenseNames.subscriptionsExpenseName : 0,]
    
    var numberOfEntriesDict : [String : Int] = [ExpenseNames.groceriesExpenseName : 0,ExpenseNames.transportationExpenseName : 0,ExpenseNames.carExpenseName: 0,ExpenseNames.lifeStyleExpenseName : 0,ExpenseNames.shoppingExpenseName : 0,ExpenseNames.subscriptionsExpenseName : 0,]
    
    var expenseTypeRecordDict : [String : CKRecord] = [:]
    
    var arrayOfExpenseNames : [String] = [ExpenseNames.groceriesExpenseName,ExpenseNames.transportationExpenseName,ExpenseNames.carExpenseName,ExpenseNames.lifeStyleExpenseName,ExpenseNames.shoppingExpenseName,ExpenseNames.subscriptionsExpenseName]
    
    
    // CloudKit Variables
    private let privateUserCloudDataBase = CKContainer(identifier: "iCloud.vinnyMadeApps.What2Budget").privateCloudDatabase
    
    // IB Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var incomeForPeriod: UILabel!
    @IBOutlet weak var startDate: UILabel!
    @IBOutlet weak var endDate: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        runOnViewWillLoad()
    }
    
    //MARK: - CloudKit Functions
    private func saveAllRecordsToDataBase()
    {
        // so what we want to do here is we want to get the amountSpent and amountAllocated for each expense and that is what we want to send to the cloud. By doing this we can also get push notifications working where if the user's amountSpent is getting a little bit high we can tell them to rein in the spending.
        let endPeriodAsString = String(defaults.string(forKey: "Set End Date") ?? "00/00/00")
        if(endPeriodAsString == "00/00/00")
        {
            let alertControllerToPresent = UIAlertController(title: "Please set valid date", message: "Please go to settings and set a valid date and fill all of the info before saving to the cloud.", preferredStyle: .alert)
            let alertActionOne = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let alertActionTwo = UIAlertAction(title: "Go To Settings", style: .default) { (alertActionTwo) in
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "toSettings", sender: self)
                }
            }
            alertControllerToPresent.addAction(alertActionOne)
            alertControllerToPresent.addAction(alertActionTwo)
            present(alertControllerToPresent, animated: true, completion: nil)
        }
        else
        {
            var amountSpent : Float = Float()
            var amountAllocated : Float = Float()
            var noError : Bool = true
            var isRecordValid : Bool = true
            for expenseName in arrayOfExpenseNames
            {
                amountSpent = amountSpentDict[expenseName] ?? 0
                amountAllocated = defaults.float(forKey: expenseName)
                //let record = CKRecord(recordType: "Expense")
                let record = CKRecord(recordType: "Expense")
                record.setValue(amountSpent, forKey: "amountSpent")
                record.setValue(amountAllocated, forKey: "amountAllocated")
                record.setValue(expenseName, forKey: "expenseType")
                record.setValue(endPeriodAsString, forKey: "endingTimePeriod")
                privateUserCloudDataBase.save(record) { (record, error) in
                    if(record != nil && error == nil)
                    {
                        print("Saved the record successfully")
                        if let safeRecord = record
                        {
                            print(safeRecord)
                            self.expenseTypeRecordDict.updateValue(safeRecord, forKey: expenseName)
                        }
                    }
                    else
                    {
                        isRecordValid = false
                        noError = false
                        print("There was an error in saving the record.")
                    }
                }
            }
            if(isRecordValid == true && noError == true)
            {
                let alertController = UIAlertController(title: "Success", message: "Saved the amount spent and amount allocated for each expense.", preferredStyle: .alert)
                let alertActionOne = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(alertActionOne)
                present(alertController, animated: true, completion: nil)
            }
        }
        /**
         So what we are first checking for here is we are making sure that the user has set a proper date value and the reason for this is we dont want data in the cloud with the default date value as this is going to impact our future queries and functionalties we want to use. So when the use has set a proper date this is where we then run a for loop and create a CKRecord for each expenseName, fill in the appropriate fields and save it to the cloud. 
         
         
         
         */
    }
    
    
    private func updateCKRecord(expenseType : String, amountSpent : Float?)
    {
        // we have to make sure that the  expense name recrod dict is not empty before we proceed
        // so we know that if the expenseNameRecordDict is not empty then our cloudDataBase has data inside.
        // this can also account for the situation in which the user just created an entry and then wants to edit it
        
        // debugging
        print(expenseTypeRecordDict)
        // end of debugging 
        if(expenseTypeRecordDict.isEmpty == false)
        {
            print("expenseNameRecordDict is not empty!!!")
            let recordToModify = expenseTypeRecordDict[expenseType]!
            let recordID = recordToModify.recordID
            privateUserCloudDataBase.fetch(withRecordID: recordID) { (recordFetched, error) in
                if(recordFetched != nil && error == nil)
                {
                    if let safeAmountSpent = amountSpent
                    {
                        recordFetched?.setValue(safeAmountSpent, forKey: "amountSpent")
                        self.privateUserCloudDataBase.save(recordFetched!) { (record, error) in
                            if(record != nil && error == nil)
                            {
                                print("Record has been successfully updated in the users private cloud database.")
                            }
                        }
                    }
                }
            }
        }
    }
   
    
    // MARK: - Functions
    private func initializeVC()
    {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 158
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! as String)
        tableView.register(UINib(nibName: "mainTableViewCell", bundle: .main), forCellReuseIdentifier: "mainCellToUse")
        loadContext()
        resetAllDictionaries()
        initializeAmountSpentDic()
        initializeNumberOfEntriesSpentDict()
        initializeExpenseNameRecordDict()
        print("View Controller is being initialized.")
    }
    
    private func runOnViewWillLoad()
    {
        incomeForPeriod.text = String(defaults.float(forKey: "Set Income"))
        startDate.text = defaults.string(forKey: "Set Start Date")
        endDate.text = defaults.string(forKey: "Set End Date")
    }
        
    private func initializeAmountSpentDic() // O(N) Time and O(1) Space
    {
        for expenseModelObject in arrayOExpenseModelObjects
        {
            let amountSpentToAdd = expenseModelObject.amountSpent
            let typeOfExpense = expenseModelObject.typeOfExpense
            var originalAmountSpent = amountSpentDict[typeOfExpense!]
            originalAmountSpent?.round(.up)
            amountSpentDict.updateValue(originalAmountSpent! + amountSpentToAdd, forKey: typeOfExpense!)
        }
        print(amountSpentDict)
    }
    
    private func initializeNumberOfEntriesSpentDict() // O(N) time and O(1) Space
    {
        for expenseModelObj in arrayOExpenseModelObjects
        {
            let typeOfExpense = expenseModelObj.typeOfExpense
            let originalValue = numberOfEntriesDict[typeOfExpense!]
            let newValue = originalValue! + 1
            numberOfEntriesDict.updateValue(newValue, forKey: typeOfExpense!)
        }
        print(numberOfEntriesDict)
    }
    
    private func initializeExpenseNameRecordDict()
    {
        // this needs to be run on viewDidLoad
        // so easiest way to do this is to run a for loop for each expenseName search the cloudDataBase to see if it exists if not this means the user has not uploaded anything to the cloud yet
        for expenseName in arrayOfExpenseNames
        {
            let predicate = NSPredicate(format: "expenseType == %@", expenseName)
            let query = CKQuery(recordType: "Expense", predicate: predicate)
            let queryOperation = CKQueryOperation(query: query)
            queryOperation.recordFetchedBlock = { record in
                print(record)
                self.expenseTypeRecordDict.updateValue(record, forKey: expenseName)
            }
            privateUserCloudDataBase.add(queryOperation)
        }
        /*
         So reason why we are creating this method is that we need to have our dictionary match the CKRecords in the cloud. So everytime the app is loaded we are going to run
         this query operation and see if the record exists in the cloud. Now if one record does not exist all of them do not exist as when we run the cloud IBAction records for
         all of the expenses will be created. So the moment one does not exist we can break out of the loop and this means the user has to create entries first. However if the user
         does have entries then the loop will continue populating our dictionary with the records from the cloud. This method is only run on load.
         
         This does have a runtime of N*M N being the number of expenseNames in arrayOfExpenseNames and M being the number of elements in the cloud database as it needs to go through M elementa in the worst case. 
         
         */
    }
    
    
    
    private func resetAllDictionaries() // this method is called everytime the view will appear. Does not reset the expenseRecordName dictionary
    {
        // reseting all dictionaries
        for expenseName in arrayOfExpenseNames
        {
            numberOfEntriesDict.updateValue(0, forKey: expenseName)
            amountSpentDict.updateValue(0, forKey: expenseName)
        }
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toSettings")
        {
            print("Going to settings")
        }
        if(segue.identifier == "toExpenseTableView")
        {
            let destinationVC = segue.destination as! ExpenseTableViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow
            if let safeIndexPath = selectedIndexPath
            {
                destinationVC.typeOfExpense = arrayOfExpenseNames[safeIndexPath.row]
                if let safeStartDate = startDate.text
                {
                    destinationVC.startDateAsString = safeStartDate
                }
                if let safeEndDate = endDate.text
                {
                    destinationVC.endDateAsString = safeEndDate
                }
            }
            destinationVC.didPersistedChangeDelegate = self
        }
    }
    
    
    // MARK: - IBActions
    @IBAction func settingsPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "toSettings", sender: self)
    }
    
    @IBAction func syncPressed(_ sender: UIBarButtonItem) {
        let alertControllerOne = UIAlertController(title: "Save To iCloud", message: "This will save all the expense categories and the amount spent for each category to your iCloud and to our private database. ", preferredStyle: .alert)
        let alertActionOne = UIAlertAction(title: "Save", style: .default) { (alertActionHandler) in
            self.saveAllRecordsToDataBase()
            // call a helper method that will determine which method to call helper method will check to see if any recrods do exist and if they do we can proceed from there
        }
        let alertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertControllerOne.addAction(alertActionOne)
        alertControllerOne.addAction(alertActionTwo)
        
        present(alertControllerOne, animated: true, completion: nil)
    }
    
    
    
    // MARK: - CRUD Functionality
    private func loadContext(request : NSFetchRequest<ExpenseModel> = ExpenseModel.fetchRequest())
    {
        do
        {
            try arrayOExpenseModelObjects = context.fetch(request)
        }catch
        {
            print("There was an error in reading from the context.")
            print(error.localizedDescription)
        }
    }
    
    private func saveContext()
    {
        do
        {
            try context.save()
        }
        catch
        {
            print("There was an error in saving to the context.")
            print(error.localizedDescription)
        }
    }
    
    
}

//MARK: - TableView delegate and TableView DataSource extension
extension HomeViewController : UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toExpenseTableView", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
}


extension HomeViewController : UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfExpenseNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainCellToUse", for: indexPath) as! mainTableViewCell
        // setting the cells IBOutlets to nil due to the recycling process
        resetCell(cellToReuse: cell)
        // end of setting the cells IBOutlets to nil
        cell.expenseTitle.text = arrayOfExpenseNames[indexPath.row]
        cell.amountAllocated.text = String(defaults.float(forKey: arrayOfExpenseNames[indexPath.row]))
        cell.numberOfEntries.text = String(numberOfEntriesDict[arrayOfExpenseNames[indexPath.row]] ?? 0)
        cell.amountSpent.text = String(amountSpentDict[arrayOfExpenseNames[indexPath.row]] ?? 0)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    private func resetCell(cellToReuse : mainTableViewCell)
    {
        cellToReuse.amountAllocated.text = ""
        cellToReuse.amountSpent.text = ""
        cellToReuse.expenseTitle.text = ""
        cellToReuse.numberOfEntries.text = ""
    }
}

//MARK: - Protocol implementaiton
extension HomeViewController : didPersistedDataChange
{
    func dataEditedInPersistedStore(indexPath: IndexPath, newAmount: Float?, newNote: String?, arrayOfExpenseModelObjectsToUse: inout [ExpenseModel]) {
        let expenseObjectToEdit = arrayOfExpenseModelObjectsToUse[indexPath.row]
        
        // now we are creating the new expense model object to add
        let newExpenseModelObject = ExpenseModel(context: context)
        newExpenseModelObject.companyName = expenseObjectToEdit.companyName
        newExpenseModelObject.typeOfExpense = expenseObjectToEdit.typeOfExpense
        newExpenseModelObject.notes = expenseObjectToEdit.notes
        
        // here we are taking care of the newAmount
        if let safeNewAmount = newAmount
        {
            let oldAmount = expenseObjectToEdit.amountSpent
            let expenseTypeTotalAmountSpent = amountSpentDict[expenseObjectToEdit.typeOfExpense!]
            var differenceToAdd = Float()
            if let safeExpenseTypeTotal = expenseTypeTotalAmountSpent
            {
                differenceToAdd = safeExpenseTypeTotal - oldAmount
                let newAmountToAdd = differenceToAdd + safeNewAmount
                newExpenseModelObject.amountSpent = safeNewAmount
                print(safeNewAmount)
                amountSpentDict.updateValue(newAmountToAdd, forKey: newExpenseModelObject.typeOfExpense!)
                
                // we also need to change the value in the context and arrayOfExpenseModelObj
                arrayOfExpenseModelObjectsToUse.remove(at: indexPath.row)
                context.delete(expenseObjectToEdit)
                arrayOfExpenseModelObjectsToUse.append(newExpenseModelObject)
                saveContext()
                // so here we also need to update the CKRecord
                updateCKRecord(expenseType: newExpenseModelObject.typeOfExpense!, amountSpent: newAmountToAdd)
                // continue working on getting the update method working tableView does not seem to be reloading either
            }
        }
        else
        {
            newExpenseModelObject.amountSpent = expenseObjectToEdit.amountSpent
        }
        // here we are taking care of the new note
        if let safeNewNote = newNote
        {
            // so at this point we are just working the persistent store in core data
            print("running from inside here")
            newExpenseModelObject.notes = safeNewNote
            arrayOfExpenseModelObjectsToUse.remove(at: indexPath.row)
            context.delete(expenseObjectToEdit)
            arrayOfExpenseModelObjectsToUse.append(newExpenseModelObject)
            saveContext()
        }
        
        //tableView.reloadRows(at: [indexPath], with: .left)
        /**
         So for this function we have two optional paramters and they are newAmount and newNote. The reason why we made these two as optional is becaus we want to be able to use this method for both editing the note and editing the amount spent. So when the user only wants to edit the note they would pass in a nil into the newAmount parameter.
         
         There is functionality in the code that checks if the newAmount is nil we simply use the old amount spent. However since we are dealing with a database and a persistent store there are some differences that need to be pointed out. When we edit the amount spent for any expense entry whether the user puts in a higher amount or a lower amount we now have to make changes to the CKRecord and to the amountSpent dictionary. However because we edited the amountSpent for an expense entry we also have to edit the persistent store as well.
         
         When we edit the note we have to make sure that we edit the note in the persistent store as well. So we do the same thing here in which we get assign the new note to the newExpenseModelObject,we remove the oldExpenseModelObject both from the context and the array and we append the new one to the array and save it to the context.
         */
    }
    
    func addToAmountSpentDict(amountFromNewExpenseObject amountToAdd: Float, expenseName: String) {
        let originalAmount = amountSpentDict[expenseName]
        if let safeOriginalAmount = originalAmount
        {
            let newAmount = safeOriginalAmount + amountToAdd
            amountSpentDict.updateValue(newAmount, forKey: expenseName)
            print(amountSpentDict)
        }
        // we should also find out which row to specifically reload to be more efficient
        tableView.reloadData()
    }
    
    func addToNumberOfEntriesDict(expenseKey : String)
    {
        let originalValue = numberOfEntriesDict[expenseKey]
        if let safeOriginalValue = originalValue
        {
            let newValue = safeOriginalValue + 1
            numberOfEntriesDict.updateValue(newValue, forKey: expenseKey)
            print(numberOfEntriesDict)
        }
        tableView.reloadData()
    }
    
    
    
    func dataDeletedInPersistedStore(expenseName: String, amountSpent: Float) {
        let originalAmountSpent = amountSpentDict[expenseName]
        let originalNumberOfEntires = numberOfEntriesDict[expenseName]
        if let safeOriginalAmountSpent = originalAmountSpent, let safeOriginalNumberOfEntries = originalNumberOfEntires
        {
            let newAmountSpent = safeOriginalAmountSpent - amountSpent
            let newNumberOfEntries = safeOriginalNumberOfEntries - 1
            amountSpentDict.updateValue(newAmountSpent, forKey: expenseName)
            numberOfEntriesDict.updateValue(newNumberOfEntries, forKey: expenseName)
            // we also have to update the CK Record here.
            updateCKRecord(expenseType: expenseName, amountSpent: newAmountSpent)
        }
    }
    
    
    func expenseModelObjectAdded(expenseModelObjectAdded expenseModelObj: ExpenseModel) {
        let expenseType = expenseModelObj.typeOfExpense!
        let expenseTotalAmount = amountSpentDict[expenseType]!
        updateCKRecord(expenseType: expenseType, amountSpent: expenseTotalAmount)
    }
    
}



//MARK: - Notes
/*
 the varible currentRecord refers to records whose endingTimePeriod is the exact same as the endingDate as our DataBase will also contain older recrods that we want to have so the user can compare any of the older records with the newer ones.
 
 We do not need a read operation for our cloud kit database here as we do not to read the data at any point.
 
 So we want to add a button that is disabled when changes have been synched with the cloud and and enabled when changes have been synched with the cloud. So when the changes have bnot been synched idelaly we want the user to press the button and it will tell them that their most recent changes have not been synced with the cloud.

 
 
 
 
 
 */

