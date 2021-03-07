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
    
    var expenseNameRecordDict : [String : CKRecord] = [:]
    
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
    private func saveRecordToDataBase()
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
                            self.expenseNameRecordDict.updateValue(safeRecord, forKey: expenseName)
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
    }
    
    
    private func updateRecordFromDataBase(expenseName : String)
    {
        // we have to make sure that the  expense name recrod dict is not empty before we proceed
        // so we know that if the expenseNameRecordDict is not empty then our cloudDataBase has data inside.
        if(expenseNameRecordDict.isEmpty == false)
        {
            let recordToModify = expenseNameRecordDict[expenseName]!
            
            
        }
        
    }
   
    
  
    
    private func saveAndUpdateToCloudHandler() // this is the function that we want to be either saving to the cloud or updating to the cloud
    {
        // how is this going to work
        // so this is going to be the function that will be called when it comes to saving or updating to the cloud. We then want this function to check the cloudDB and see if any records exist and if they do we then rpoceed to call the updateRecord function. However if no records exists that match the dateEndingPeriod then we save them to the cloudDB.
        // So to check to see if any records exist in the DB that end with the current endingPeriod we can do a simple query and if any recrods are fetched we can assign a boolean to true. This means that we have to update the records instead and if no records exist the boolean will be false so this means we have to save the records instead.
        // to check if the database has any records we can simply just pull one random record using any expenseName and the current endingDatePeriod because if this does not exist then there are no records at all. If they do exist then there are records
        
        
        
        
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
    
    @IBAction func cloudPressed(_ sender: UIBarButtonItem) {
        let alertControllerOne = UIAlertController(title: "Save To iCloud", message: "This will save all the expense categories and the amount spent for each category to your iCloud and to our private database. ", preferredStyle: .alert)
        let alertActionOne = UIAlertAction(title: "Save", style: .default) { (alertActionHandler) in
            self.saveRecordToDataBase()
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
        cell.expenseTitle.text = arrayOfExpenseNames[indexPath.row]
        cell.amountAllocated.text = String(defaults.float(forKey: arrayOfExpenseNames[indexPath.row]))
        cell.numberOfEntries.text = String(numberOfEntriesDict[arrayOfExpenseNames[indexPath.row]] ?? 0)
        cell.amountSpent.text = String(amountSpentDict[arrayOfExpenseNames[indexPath.row]] ?? 0)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

//MARK: - Protocol implementaiton
extension HomeViewController : didPersistedDataChange
{
    func dataEditedInPersistedStore(expenseName: String, indexPath: IndexPath, newAmount: Float, arrayOfExpenseModelObject: [ExpenseModel], newNote : String) {
        let expenseObjectToEdit = arrayOExpenseModelObjects[indexPath.row]
        let originalAmountSpent = expenseObjectToEdit.amountSpent
        let newValue = abs(originalAmountSpent - newAmount)
        amountSpentDict.updateValue(newValue, forKey: expenseName)
        
        // now we are creating the new expense model object to add
        let newExpenseModelObject = ExpenseModel(context: context)
        newExpenseModelObject.companyName = expenseObjectToEdit.companyName
        newExpenseModelObject.notes = newNote
        newExpenseModelObject.amountSpent = newAmount
        newExpenseModelObject.receipt = expenseObjectToEdit.receipt
        
        // we now have to remove the old one from both the array and the context
        arrayOExpenseModelObjects.remove(at: indexPath.row)
        context.delete(expenseObjectToEdit)
        arrayOExpenseModelObjects.append(newExpenseModelObject)
        saveContext()
    }
    
   
    

    func addedToPersistedStore() {
        loadContext()
        resetAllDictionaries()
        initializeAmountSpentDic()
        initializeNumberOfEntriesSpentDict()
        tableView.reloadData()
        print("Running from inside the persistedDataChange method in HomeViewController")
    }
    
    
}

//MARK: - Explanation
/*
 So with the three dictionary methods in the viewWillAppear method this is the explanation behind them. Anytime we add a new expense object in the expenseTableView we want these changes to be reflected in our HomeViewController. HomeViewController is only loaded in once so we cannot pass these methods into viewDidLoad as it will only get called the first time and will not get called again. So in order for the changes to be relfected in this view controller the methods have to be called in the viewWillAppear method. Now one issue that arose is when we switched back and forth from the two viewControllers the values for both dictionaries kept doubling and did not reflect the true value of the total expenseModelObjects nor the number of expenseModelObjects for the entries. So what we did to fix this is we did a reset method. So anytime we come back from expenseTableViewController we would reset both dictionaries to have a value of zero for all keys. Then we call the initialize dictionaries methods to get the appropriate values for the keys and this way we can avoid the doubling. It would be ideal if there was a way to check if the data was changed in the expenseTableViewController and we can maybe some kind of variable down from that view controller to the homeViewController. If this variable indicates that changes have happened then we can do the reset and initialize method.We also have to call load context in the viewWillAppear everytime as we have to take into account the new expenseModel object we have added in the expenseTableView controller. Run time is linear and it would help if this is opitimized. Run time is O(3N) which is O(N).
 
 
 the varible currentRecord refers to records whose endingTimePeriod is the exact same as the endingDate as our DataBase will also contain older recrods that we want to have so the user can compare any of the older records with the newer ones.
 
 We do not need a read operation for our cloud kit database here as we do not to read the data at any point. 
 
 
 
 
 
 
 
 
 */

