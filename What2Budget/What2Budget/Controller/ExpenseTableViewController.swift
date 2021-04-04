//
//  ExpenseTableViewController.swift
//  What2Budget
//
//  Created by Vinojen Gengatharan on 2021-03-06.
//

import Foundation
import UIKit
import CoreData
import PhotosUI
import Vision

class ExpenseTableViewController : UIViewController
{
    // variables
    var arrayOfExpenses : [ExpenseModel] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var startDateAsString : String = String()
    var endDateAsString : String = String()
    var typeOfExpense : String = String()
    
    // beta variables
    var defaults = UserDefaults.standard
    
    
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
    
    
    //MARK: - Functions
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
    
    private func notificationPosted()
    {
        var totalAmountSpent = Float()
        let totalAmountAllocated = defaults.float(forKey: typeOfExpense)
        print(totalAmountAllocated)
        // so the first step we need to do is calculate the total amount spent for the expenses.
        for expenseModel in arrayOfExpenses
        {
            totalAmountSpent += expenseModel.amountSpent
        }
        
        // now we need to compare the totalAmountSpent with the totalAmountAllocated
        if(totalAmountSpent >= 0.75*totalAmountAllocated)
        {
            postNotification(expenseTypeName: typeOfExpense)
        }
        else
        {
           print("Notification has not been posted.")
        }
        /*
        So here what we need to do is we need to create a method here that will do the calculations for us. So we will need a method that will retrieve the total amountSpent for that expense category and compare it to the total amount allocated. If this method does meet or exceed 75% of the total amount allocated we will post a notification and use the notification observer communcation pattern. Inside the observer this is where we will run the server code and get the server to send a push notification informing the user that they are about 75% of their allocated amount. So now we need to post the notification in the dataEditedInPersistedStore method. When the user deletes the data we do not want to post any notifications here.
         */
    }
    
    private func postNotification(expenseTypeName : String)
    {
        let name = Notification.Name("\(expenseTypeName)")
        let notificationToPost = Notification(name: name)
        print("\(expenseTypeName) notification has been posted.")
        NotificationCenter.default.post(notificationToPost)
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
                // beta code
                NotificationCenter.default.post(name: NotificationNames.expenseAddedNotificationName, object: self)
                // end of beta code
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if let safePersistedDidChangeDelegate = self.didPersistedChangeDelegate
                    {
                        safePersistedDidChangeDelegate.addToAmountSpentDict(amountFromNewExpenseObject: expenseObjToAdd.amountSpent, expenseName: expenseObjToAdd.typeOfExpense!)
                        safePersistedDidChangeDelegate.addToNumberOfEntriesDict(expenseKey: expenseObjToAdd.typeOfExpense!)
                        // call a method that will update the CKRecord in the cloudKitDataBase and we can pass in the expenseObjToAdd
                        safePersistedDidChangeDelegate.expenseModelObjectAdded(expenseModelObjectAdded: expenseObjToAdd)
                        // beta code
                        self.notificationPosted()
                        // end of beta code
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
        
    private func editExpenseEntry(indexPath : IndexPath)
    {        
        let mainAlertController = UIAlertController(title: "Edit Expense", message: "Please choose one of the options below", preferredStyle: .alert)
        let mainAlertActionEditAmount = UIAlertAction(title: "Edit Amount Spent", style: .destructive) { (editAmountHandler) in
            DispatchQueue.main.async {
                self.editAmountSpent(indexPath: indexPath)
                //self.tableView.reloadRows(at: [indexPath], with: .left)
            }
        }
        
        let mainAlertActionEditNote = UIAlertAction(title: "Edit Note", style: .destructive) { (editNoteHandler) in
            DispatchQueue.main.async {
                self.editNote(indexPath: indexPath)
                //self.tableView.reloadRows(at: [indexPath], with: .left)
            }
        }
        
        let mainAlertActionEditBoth = UIAlertAction(title: "Edit Both", style: .destructive) { (editBothHandler) in
            DispatchQueue.main.async {
                self.editAmountSpent(indexPath: indexPath)
                self.editNote(indexPath: indexPath)
                //self.tableView.reloadRows(at: [indexPath], with: .left)
            }
        }
        
        let mainAlertActionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        
        mainAlertController.addAction(mainAlertActionEditAmount)
        mainAlertController.addAction(mainAlertActionEditNote)
        mainAlertController.addAction(mainAlertActionEditBoth)
        mainAlertController.addAction(mainAlertActionCancel)
        self.present(mainAlertController, animated: true, completion: nil)
        
        /*
            So what we did here is we split the three buttons into their own functionalities rather than having them all in one functionality. So for editiing the amountSpent we have
            a funcion that deals only with that and for editing the note we have a function that deals only with that. When it comes to editing both we just called both methods. Only issue with efficiency here is that when we execute both methods we are also attempting to remove it from the context twice this could lead to an addtional O(N) search and this can be optimized.
         
            So there is an issue here that we need to fix. The issue is we are deleting the expenseModel from the correct indexpath and we are appending the new expenseModel to the end of the array. Yet when we call reloadRows we are reloading the row where we just deleted the expenseModel in the so it is loading the next avaialble one. Check the trello for more details.
         
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
                self.didPersistedChangeDelegate?.dataEditedInPersistedStore(indexPath: indexPath, newAmount: newAmountAsFloat, newNote: noteToPass, arrayOfExpenseModelObjectsToUse: &self.arrayOfExpenses)
                // beta code
                NotificationCenter.default.post(name: NotificationNames.expenseEditedNotificationName, object: self)
                // end of beta code
                self.tableView.reloadRows(at: [indexPath], with: .left)
                print("The index path we are working on is the following : \(indexPath.row)")
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
                self.didPersistedChangeDelegate?.dataEditedInPersistedStore(indexPath: indexPath, newAmount: newAmount, newNote: newNote, arrayOfExpenseModelObjectsToUse: &self.arrayOfExpenses)
                self.tableView.reloadRows(at: [indexPath], with: .left)
                print(indexPath.row)
            }
            else
            {
                let internalAlertController = UIAlertController(title: "Invalid Entry", message: "Entry is invalid please try again", preferredStyle: .alert)
                let interalAlertContAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                internalAlertController.addAction(interalAlertContAction)
                self.present(internalAlertController, animated: true, completion: nil)
            }
        }
        let alertControllerOneCancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (cancelActionHandler) in
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        alertControllerOne.addAction(alertControllerOneSaveAction)
        alertControllerOne.addAction(alertControllerOneCancelAction)
        present(alertControllerOne, animated: true, completion: nil)
    }
    
    private func deleteExpenseEntry(indexPath : IndexPath)
    {
        // first thing we need to do is remove the entry from the array
        // then we need to update the dictionaries in the previous method
        let expenseModelObjToDelete = arrayOfExpenses[indexPath.row]
        let expenseType = expenseModelObjToDelete.typeOfExpense
        let amountSpentToPass = expenseModelObjToDelete.amountSpent
        didPersistedChangeDelegate?.dataDeletedInPersistedStore(expenseName: expenseType!, amountSpent: amountSpentToPass)
        context.delete(expenseModelObjToDelete)
        arrayOfExpenses.remove(at: indexPath.row)
        saveContext()
        self.tableView.deleteRows(at: [indexPath], with: .left)
    }
    
    
    
    // MARK: - Initializing the PHPicker
    private func initializePHPicker()
    {
        var configuration = PHPickerConfiguration() // here we are creating a PHPickerConfiguration
        // configuration.selectionLimit = 1 we do not need to explicitly define this as the default value is 1
        configuration.filter = .any(of: [.images]) // here we are setting the filter of the PHPickerConfiguration and the filter is going to filter out only images.
        let picker = PHPickerViewController(configuration: configuration) // here we are creating a PHPickerViewController and assigning our configuration to it.
        picker.delegate = self  // setting the delegate of the picker to self as in this file we did implement the delegate methods.
        present(picker, animated: true, completion: nil) // here we are presenting the picker.
    }
    
    // MARK: - IBActions
    @IBAction func addExpense(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add \(typeOfExpense)", message: "Please select the photo option if you want us to auto populate the information for you. Please select the manual entry option if you would like to do this yourself.", preferredStyle: .alert)
        let alertActionOne = UIAlertAction(title: "Choose Photo", style: .default) { (alertActionOne) in
            // here is where we need to go to the next viewController
            //self.performSegue(withIdentifier: "ToPhotoPicker", sender: self)
            self.initializePHPicker()
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
    // so we want the edit option to be available on the trailing edge of the tableViewCell
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextualAction = UIContextualAction(style: .destructive, title: "Edit") { (contextualActionHandler, viewHandler, completionHandler) in
            DispatchQueue.main.async {
                self.editExpenseEntry(indexPath: indexPath)
            }
        }
        contextualAction.backgroundColor = .systemGreen
        contextualAction.image = UIImage(systemName: "pencil")
        let configuration : UISwipeActionsConfiguration = UISwipeActionsConfiguration(actions: [contextualAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
        /**
         So here we are calling the editExpenseEntry method from above which will take care of the editing process.
         */
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contextulAction = UIContextualAction(style: .destructive, title: "Delete") { (contextualActionHandler, view, completionHandler) in
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Delete Entry", message: "Please confirm if you would like to delete the entry.", preferredStyle: .alert)
                let alertActionOne = UIAlertAction(title: "Yes", style: .destructive) { (alertActionOneHandler) in
                    self.deleteExpenseEntry(indexPath: indexPath)
                }
                let alertActionTwo = UIAlertAction(title: "No", style: .cancel, handler: nil)
                alertController.addAction(alertActionOne)
                alertController.addAction(alertActionTwo)
                self.present(alertController, animated: true, completion: nil)
            }
        }
        contextulAction.backgroundColor = .systemRed
        contextulAction.image = UIImage(systemName: "trash.fill")
        let configuration : UISwipeActionsConfiguration = UISwipeActionsConfiguration(actions: [contextulAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
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
        // settings the cells value to nil due to how the recylcing works
        resetCell(cellToReuse: cell)
        // end of process
        cell.amountSpent.text = String(arrayOfExpenses[indexPath.row].amountSpent)
        cell.providerTitle.text = arrayOfExpenses[indexPath.row].companyName
        cell.notes.text = arrayOfExpenses[indexPath.row].notes
        return cell
    }
    
    private func resetCell(cellToReuse : expenseCell)
    {
        cellToReuse.amountSpent.text = " "
        cellToReuse.providerTitle.text = " "
        cellToReuse.notes.text = " "
    }
}


//MARK: - Conforming to Protocols






//MARK: - Protocols
protocol didPersistedDataChange {
    
    func addToAmountSpentDict(amountFromNewExpenseObject amountToAdd : Float, expenseName : String)
    
    func dataEditedInPersistedStore(indexPath : IndexPath, newAmount : Float?, newNote : String?, arrayOfExpenseModelObjectsToUse : inout [ExpenseModel])
    // so this method is for when a data entry has been changed in the persisted store so we only need to update the amountSpentDict as there is no need to udpate the other dictionatires and take up even more time. So what we want called here is when a data entry has been updated we want to not only update the amountSpent dictionaries but also sync it with the cloud as well.
    // will only be called when data in the persistent store is edited.
    // so we can access the specific object we want using the tableView indexPath.row and we can modify it there. Then we need to save this into the context. Rather we need to update the existing one in the context. So to be more specific we are going to find the object in the context and then delete it and the re add it so this is going to have a run time of O(2N).
    
    func addToNumberOfEntriesDict(expenseKey : String)
    // so here is where we are going to be adding to the numberOfEntriesDict and we can do this in constant time rather than having to reset everything and run the whole thing again
    
    func dataDeletedInPersistedStore(expenseName : String, amountSpent : Float)
    // removing the expenseModelObject and updating the CKRecord as a result. 
    
    func expenseModelObjectAdded(expenseModelObjectAdded expenseModelObj : ExpenseModel)
    // so here we are updating the CKRecord
    
    func createObserver(expenseType observerName : String)
}

//MARK: - Extensions
extension ExpenseTableViewController : PHPickerViewControllerDelegate
{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        print("Picker has finished selecting the results.")
        print(results)
        dismiss(animated: true, completion: nil)
        // here is where we want to process the image via OCR
        implementOCR(arrayOfSelectedAssets: results)
    }
    
    func implementOCR(arrayOfSelectedAssets : [PHPickerResult])
    {
        // step 1 we need to convert it to an image
        let image = arrayOfSelectedAssets[0]
        image.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            if let image = object as? UIImage
            {
                // here we are getting a cgiImage on which to perform requests
                let cgImageToUse = image.cgImage
                if let safeCgImageToUse = cgImageToUse
                {
                    self.recognizeText(cgImage: safeCgImageToUse)
                }
            }
        }
    }
    
    func recognizeText(cgImage : CGImage)
    {
        //here we are creating a new image-request handler
        let requestHandler = VNImageRequestHandler(cgImage : cgImage)
        // here we are creating a new request to recognize text
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHelper)
        do
        {
            // perform the text recognition request
            try requestHandler.perform([request])
        }catch
        {
            print("Unable to perform requests.")
            print(error.localizedDescription)
        }
    }
    
    
    func recognizeTextHelper(request : VNRequest, error : Error?)
    {
        guard let observations = request.results as? [VNRecognizedTextObservation] else{
            return
        }
        let recognizedStrings = observations.compactMap{observation in
            // return the text of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        print(recognizedStrings)
        
    }
}


//MARK: - Notes
/**
 
 
 
 */
