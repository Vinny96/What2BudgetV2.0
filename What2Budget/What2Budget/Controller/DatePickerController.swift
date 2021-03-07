//
//  DatePickerController.swift
//  What2Budget
//
//  Created by Vinojen Gengatharan on 2021-03-06.
//

import Foundation
import UIKit

class DatePickerController : UIViewController
{
    //variables
    internal var dateKey : String = String()
    private let defaults = UserDefaults.standard
    
    //IB Outlets
    @IBOutlet weak var datePicker: UIDatePicker!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = dateKey
    }
    
    //MARK: - Functions
    private func initializeDatePicker()
    {
        
    }
    
    
    // MARK: - IB Actions
    @IBAction func saveDate(_ sender: UIButton)
    {
        let date = datePicker.date
        let dateFormatted = date.returnDate()
        print(dateFormatted)
        defaults.setValue(dateFormatted, forKey: dateKey)
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
