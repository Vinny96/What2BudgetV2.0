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
        let mainAlertController = UIAlertController(title: "Edit Expense", message: "Please choose one of the options below", preferredStyle: .alert)
        let mainAlertActionEditAmount = UIAlertAction(title: "Edit Amount Spent", style: .destructive) { (editAmountHandler) in
            DispatchQueue.main.async {
                self.editAmountSpent(indexPath: indexPath)
            }
        }
        
        let mainAlertActionEditNote = UIAlertAction(title: "Edit Note", style: .destructive) { (editNoteHandler) in
            DispatchQueue.main.async {
                self.editNote(indexPath: indexPath)
            }
        }
        
        let mainAlertActionEditBoth = UIAlertAction(title: "Edit Both", style: .destructive) { (editBothHandler) in
            DispatchQueue.main.async {
                self.editAmountSpent(indexPath: indexPath)
                self.editNote(indexPath: indexPath)
            }
        }
        mainAlertController.addAction(mainAlertActionEditAmount)
        mainAlertController.addAction(mainAlertActionEditNote)
        mainAlertController.addAction(mainAlertActionEditBoth)
        self.present(mainAlertController, animated: true, completion: nil)
        
        /*
            So what we did here is we split the three buttons into their own functionalities rather than having them all in one functionality. So for editiing the amountSpent we have
            a funcion that deals only with that and for editing the note we have a function that deals only with that. When it comes to editing both we just called both methods. Only issue with efficiency here is that when we execute both methods we are also attempting to remove it from the context twice this could lead to an addtional O(N) search and this can be optimized. 
         
         */
    }
    
    // editExpenseEntry Function Helpers
    private func editAmountSpent(indexPath : IndexPath)
    {
        var textField = UITextField()
        let alertController = UIAlertController(title: "Edit Amount Spent", message: "Please enter the new amount below", preferredStyle: .alert)
        alertController.addTextField { (textFieldToAdd) in
            textField = textFieldToAdd
            textField.placeholder = "Please enter new amount here"
            textField.keyboardType = .decimalPad
        }
        let alertControllerActionOne = UIAlertAction(title: "Save", style: .destructive) { (actionOneHandler) in
            if(textField.hasText == true)
            {
                let newAmountAsFloat = (textField.text! as NSString).floatValue
                let noteToPass : String? = nil
                self.didPersistedChangeDelegate?.dataEditedInPersistedStore(indexPath: indexPath, newAmount: newAmountAsFloat, newNote: noteToPass)
            }
            else
            {
                let internalAlertController = UIAlertController(title: "Invalid Entry", message: "Entry is invalid please try again", preferredStyle: .alert)
                let internalAlertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                internalAlertController.addAction(internalAlertAction)
                DispatchQueue.main.async {
                    self.present(internalAlertController, animated: true, completion: nil)
                }
            }
        }
        let alertControllerActionTwo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(alertControllerActionOne)
        alertController.addAction(alertControllerActionTwo)
        present(alertController, animated: true, completion: nil)
    }
    
    private func editNote(indexPath : IndexPath)
    {
        var textField = UITextField()
        let alertControllerOne = UIAlertController(title: "Edit Note", message: "Please enter the new note below", preferredStyle: .alert)
        alertControllerOne.addTextField { (textFieldToAdd) in
            textField = textFieldToAdd
            textField.placeholder = "Please enter your new note here"
            textField.keyboardType = .emailAddress
        }
        let alertControllerOneSaveAction = UIAlertAction(title: "Save", style: .destructive) { (saveActionHandler) in
            if(textField.hasText == true)
            {
                let newNote = textField.text!
                let newAmount : Float? = nil
                self.didPersistedChangeDelegate?.dataEditedInPersistedStore(indexPath: indexPath, newAmount: newAmount, newNote: newNote)
            }
            else
            {
                let internalAlertController = UIAlertController(title: "Invalid Entry", message: "Entry is invalid please try again", preferredStyle: .alert)
                let interalAlertContAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                internalAlertController.addAction(interalAlertContAction)
                self.present(internalAlertController, animated: true, completion: nil)
            }
        }
        let alertControllerOneCancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertControllerOne.addAction(alertControllerOneSaveAction)
        alertControllerOne.addAction(alertControllerOneCancelAction)
        present(alertControllerOne, animated: true, completion: nil)
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
    
    func dataEditedInPersistedStore(indexPath : IndexPath, newAmount : Float?, newNote : String?)
    // so this method is for when a data entry has been changed in the persisted store so we only need to update the amountSpentDict as there is no need to udpate the other dictionatires and take up even more time. So what we want called here is when a data entry has been updated we want to not only update the amountSpent dictionaries but also sync it with the cloud as well.
    // will only be called when data in the persistent store is edited.
    // so we can access the specific object we want using the tableView indexPath.row and we can modify it there. Then we need to save this into the context. Rather we need to update the existing one in the context. So to be more specific we are going to find the object in the context and then delete it and the re add it so this is going to have a run time of O(2N). 
    
    func addToNumberOfEntriesDict(expenseKey : String)
    // so here is where we are going to be adding to the numberOfEntriesDict and we can do this in constant time rather than having to reset everything and run the whole thing again
    
    func dataDeletedInPersistedStore(expenseName : String, objectToDelete amountSpent : Float)
}

