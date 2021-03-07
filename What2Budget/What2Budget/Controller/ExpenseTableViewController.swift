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
                    if let safePersistedDidChangeDelegatre = self.didPersistedChangeDelegate
                    {
                        safePersistedDidChangeDelegatre.persistedDataChanged()
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
    func persistedDataChanged()
    // so what we want to do with this protocol is that whenver the persisted data has changed we want to call the function. However in order for the communication between the two viewControllers to properly work we need to implement in the HomeViewController. In the prepareForSegue method we then want to then set the delegate to the HomeViewController so when we call the method here the implementation in the HomeViewControler will be the one that is executed.
}

