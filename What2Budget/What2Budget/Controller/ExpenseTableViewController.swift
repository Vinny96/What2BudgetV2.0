//
//  ExpenseTableViewController.swift
//  What2Budget
//
//  Created by Vinojen Gengatharan on 2021-03-06.
//

import Foundation
import UIKit
import CoreData

class ExpenseTableViewController : UIViewController
{
    // variables
    var arrayOfExpenses : [ExpenseModel] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var startDateAsString : String = String()
    var endDateAsString : String = String()
    var typeOfExpense : String = String()
    

    
    
    // IB Outlets
    @IBOutlet weak var startDate: UILabel!
    @IBOutlet weak var endDate: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    // Delegates
    var didPersistedChangeDelegate : didPersistedDataChange?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    
    //MARK: - Functions and IB Actions
    private func initialize()
    {
        title = typeOfExpense
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "expenseCell", bundle: .main), forCellReuseIdentifier: "expenseCellToUse")
        tableView.rowHeight = 94
        startDate.text = startDateAsString
        endDate.text = endDateAsString
        loadContext()
    }
    
    private func createManualEntry()
    {
        // remember that we have to update the providerTitle, the amountSpent and the notes. We also have to persist this to coreData.
        var textFieldOne = UITextField()
        var textFieldTwo = UITextField()
        var textFieldThree = UITextField()
        let expenseObjToAdd = ExpenseModel(context: context)
        
        
        let alertControllerThree = UIAlertController(title: "Please enter any notes regarding the purchase.", message: nil, preferredStyle: .alert)
        alertControllerThree.addTextField { (thirdTextField) in
            textFieldThree = thirdTextField
            textFieldThree.placeholder = "notes"
        }
        let alertActionFive = UIAlertAction(title: "Save", style: .default) { (fourthAlertAction) in
            if(textFieldThree.hasText == true)
            {
                expenseObjToAdd.notes = textFieldThree.text!
                
                self.arrayOfExpenses.append(expenseObjToAdd)
                self.saveContext()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if let safePersistedDidChangeDelegate = self.didPersistedChangeDelegate
                    {
                        safePersistedDidChangeDelegate.addToAmountSpentDict(amountFromNewExpenseObject: expenseObjToAdd.amountSpent, expenseName: expenseObjToAdd.typeOfExpense!)
                        safePersistedDidChangeDelegate.addToNumberOfEntriesDict(expenseKey: expenseObjToAdd.typeOfExpense!)
                        print("Delegate methods should be getting called by now.")
                    }
                }
            }
            else
            {
                let internalAlertController = UIAlertController(title: "Invalid entry please start over.", message: "", preferredStyle: .alert)
                let internalAlertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                internalAlertController.addAction(internalAlertAction)
            }
        }
        let alertActionSix = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertControllerThree.addAction(alertActionFive)
        alertControllerThree.addAction(alertActionSix)
        
        
        let alertControllerTwo = UIAlertController(title: "Please type how much you spent.", message: "Please exclude the dollar sign", preferredStyle: .alert)
        alertControllerTwo.addTextField { (secondTextField) in
            textFieldTwo = secondTextField
            textFieldTwo.keyboardType = .decimalPad
            textFieldTwo.placeholder = "150.75"
        }
        let alertActionThree = UIAlertAction(title: "Save & Continue", style: .default) { (alertActionThreeHandler) in
            if(textFieldTwo.hasText == true)
            {
                expenseObjToAdd.amountSpent = (textFieldTwo.text! as NSString).floatValue
                self.present(alertControllerThree, animated: true, completion: nil)
            }
            else
            {
                let internalAlertController = UIAlertController(title: "Invalid entry please start over.", message: "", preferredStyle: .alert)
                let internalAlertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                internalAlertController.addAction(internalAlertAction)
            }
        }
        
        let alertActionFour = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertControllerTwo.addAction(alertActionThree)
        alertControllerTwo.addAction(alertActionFour)
        
        
        let alertControllerOne = UIAlertController(title: "Please type the name of the company.", message: "For example if you paid $10 to apple write type Apple", preferredStyle: .alert)
        alertControllerOne.addTextField { (firstTextField) in
            textFieldOne = firstTextField
            textFieldOne.keyboardType = .default
            textFieldOne.placeholder = "Type name of company."
        }
        let alertActionOne = UIAlertAction(title: "Save & Continue", style: .default) { (alertActionOne) in
            if(textFieldOne.hasText == true)
            {
                expenseObjToAdd.companyName = textFieldOne.text!
                expenseObjToAdd.typeOfExpense = self.typeOfExpense
                self.present(alertControllerTwo, animated: true, completion: nil)
            }
            else
            {
                let internalAlertController = UIAlertController(title: "Invalid entry please start over.", message: "", preferredStyle: .alert)
                let internalAlertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                internalAlertController.addAction(internalAlertAction)
            }
        }
       // let alertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let alertActionTwo = UIAlertAction(title: "Cancel", style: .cancel) { (alertActionTwoHandler) in
            print(self.arrayOfExpenses)
        }
        alertControllerOne.addAction(alertActionOne)
        alertControllerOne.addAction(alertActionTwo)
      
        present(alertControllerOne, animated: true, completion: nil)
    }
    
    private func useOCR()
    {
        // to be implemented
    }
    
    private func editExpenseEntry(indexPath : IndexPath)
    {
        let alertControllerOne = UIAlertController(title: "Edit Expense Entry", message: "Please do not use this to delete the expense, use the options only for editing.", preferredStyle: .alert)
        let alertActionOne = UIAlertAction(title: "Edit Amount Spent", style: .destructive) { (alertActionOneHandler) in
            // here is where we are editing ONLY the edit amount spent
            var internalTextField = UITextField()
            let internalAlertController = UIAlertController(title: "Edit Amount Spent", message: "Please enter your new amount below", preferredStyle: .alert)
            internalAlertController.addTextField { (textFieldToAdd) in
                internalTextField = textFieldToAdd
                internalTextField.placeholder = "Please enter new amount here"
                internalTextField.keyboardType = .decimalPad
            }
            
            let internalActionOne = UIAlertAction(title: "Save New Amount", style: .default) { (internalActionOneHandler) in
                if(internalTextField.hasText == true)
                {
                    let newAmountSpent = (internalTextField.text! as NSString).floatValue
                    let newNote : String? = nil
                    self.didPersistedChangeDelegate?.dataEditedInPersistedStore(expenseName: self.typeOfExpense, indexPath: indexPath, newAmount: newAmountSpent, newNote: newNote)
                }
                else
                {
                    let alertControllerForInvalid = UIAlertController(title: "Invalid Entry", message: "Please try again", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertControllerForInvalid.addAction(alertAction)
                    DispatchQueue.main.async {
                        self.present(alertControllerForInvalid, animated: true, completion: nil)
                    }
                }
            }
            
            let internalActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            internalAlertController.addAction(internalActionOne)
            internalAlertController.addAction(internalActionTwo)
            DispatchQueue.main.async {
                self.present(internalAlertController, animated: true, completion: nil)
            }
        }
        //Alert Action Two Code
        
        let alertActionTwo = UIAlertAction(title: "Edit Notes", style: .destructive) { (alertActionTwoHandler) in
            // here is where we are editing ONLY the notes
            var internalTextField = UITextField()
            let internalAlertController = UIAlertController(title: "Edit Notes", message: "Type your new note below", preferredStyle: .alert)
            internalAlertController.addTextField { (textField) in
                internalTextField = textField
                internalTextField.placeholder = "Type note here"
                internalTextField.keyboardType = .emailAddress
            }
            let internalAlertAction = UIAlertAction(title: "Save", style: .default) { (saveAlertActionHandler) in
                if(internalTextField.hasText == true)
                {
                    let newNoteToPass = internalTextField.text!
                    self.didPersistedChangeDelegate?.dataEditedInPersistedStore(expenseName: self.typeOfExpense, indexPath: indexPath, newAmount: 0, newNote: newNoteToPass)
                }
                else
                {
                    let alertControllerForInvalidEntry = UIAlertController(title: "Invalid Entry", message: "Entry was invalid please try again", preferredStyle: .alert)
                    let alertActionForInvalidEntry = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertControllerForInvalidEntry.addAction(alertActionForInvalidEntry)
                    DispatchQueue.main.async {
                        self.present(alertControllerForInvalidEntry, animated: true, completion: nil)
                    }
                }
            }
            let internalAlertActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            internalAlertController.addAction(internalAlertAction)
            internalAlertController.addAction(internalAlertActionTwo)
        }
        
        
        let alertActionThree = UIAlertAction(title: "Edit Both", style: .destructive) { (alertActionHandler) in
            // here we are editing the AmountSpent and editing the Notes
            
        }
        
        let alertActionFour = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertControllerOne.addAction(alertActionOne)
        alertControllerOne.addAction(alertActionTwo)
        alertControllerOne.addAction(alertActionThree)
        alertControllerOne.addAction(alertActionFour)
    }
    
    @IBAction func addExpense(_ sender: Any) {
        let alertController = UIAlertController(title: "Add \(typeOfExpense)", message: "Please select the photo option if you want us to auto populate the information for you. Please select the manual entry option if you would like to do this yourself.", preferredStyle: .alert)
        let alertActionOne = UIAlertAction(title: "Take Photo", style: .default) { (alertActionOne) in
            print("The take photo option was pressed.")
        }
        let alertActionTwo = UIAlertAction(title: "Manual Entry", style: .default) { (alertActionTwo) in
            print("The manual entry option was pressed.")
            self.createManualEntry()
        }
        
        let alertActionThree = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(alertActionOne)
        alertController.addAction(alertActionTwo)
        alertController.addAction(alertActionThree)
        present(alertController, animated: true, completion: nil)
    }
    
    
 // MARK: - CRUD Functionality
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
    
    private func loadContext(request : NSFetchRequest<ExpenseModel> = ExpenseModel.fetchRequest())
    {
        request.predicate = NSPredicate(format: "typeOfExpense MATCHES %@", typeOfExpense)
        do
        {
            try arrayOfExpenses = context.fetch(request)
        }
        catch
        {
            print("There was an error in loading the items from the context.")
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: - Protocol creations
}
//MARK: - TableView Extensions
extension ExpenseTableViewController : UITableViewDelegate
{
    
}

extension ExpenseTableViewController : UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfExpenses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "expenseCellToUse", for: indexPath) as! expenseCell
        cell.amountSpent.text = String(arrayOfExpenses[indexPath.row].amountSpent)
        cell.providerTitle.text = arrayOfExpenses[indexPath.row].companyName
        cell.notes.text = arrayOfExpenses[indexPath.row].notes
        return cell
    }
    
}

//MARK: - Protocols
protocol didPersistedDataChange {
    func addToAmountSpentDict(amountFromNewExpenseObject amountToAdd : Float, expenseName : String)
    
    func dataEditedInPersistedStore(expenseName : String, indexPath : IndexPath, newAmount : Float?, newNote : String?)
    // so this method is for when a data entry has been changed in the persisted store so we only need to update the amountSpentDict as there is no need to udpate the other dictionatires and take up even more time. So what we want called here is when a data entry has been updated we want to not only update the amountSpent dictionaries but also sync it with the cloud as well.
    // will only be called when data in the persistent store is edited.
    // so we can access the specific object we want using the tableView indexPath.row and we can modify it there. Then we need to save this into the context. Rather we need to update the existing one in the context. So to be more specific we are going to find the object in the context and then delete it and the re add it so this is going to have a run time of O(2N). 
    
    func addToNumberOfEntriesDict(expenseKey : String)
    // so here is where we are going to be adding to the numberOfEntriesDict and we can do this in constant time rather than having to reset everything and run the whole thing again
    
    func dataDeletedInPersistedStore(expenseName : String, objectToDelete amountSpent : Float)
}

