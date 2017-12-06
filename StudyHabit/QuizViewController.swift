//
//  QuizViewController.swift
//  StudyHabit
//
//  Created by RJ Pimentel on 12/5/17.
//  Copyright © 2017 RJ Pimentel. All rights reserved.
//

import UIKit
import CoreData

class QuizViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var termLabel: UILabel!
    
    @IBOutlet weak var definitionField: UITextField!
    
    var cards: [QuizCard] = []
    var currCard: QuizCard = QuizCard(question: "", answer: "")
    var progress: Int = 0 {
        didSet {
            if progress == 3 {
                self.performSegue(withIdentifier: "toMain", sender: nil)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        attempt(text: textField.text!)
        textField.text! = ""
        return true
    }

    func attempt(text: String) {
        if currCard.answer == text {
            progress += 1
            progressLabel.textColor = UIColor.green
        } else {
            progressLabel.textColor = UIColor.red
        }
        nextCard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let setRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuizSets")
        let cardRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cards")
        setRequest.returnsObjectsAsFaults = false
        cardRequest.returnsObjectsAsFaults = false
        
        do {
            let setResult = try context.fetch(setRequest)
            let cardResult = try context.fetch(cardRequest)
            var enabledIds: [Int] = []
            for set in setResult as! [NSManagedObject] {
                let enabled = set.value(forKey: "enabled") as! Bool
                if enabled {
                    let id = set.value(forKey: "id") as! Int
                    enabledIds.append(id)
                }
            }
            for card in cardResult as! [NSManagedObject] {
                let setId = card.value(forKey: "setId") as! Int
                if enabledIds.contains(setId) {
                    let question = card.value(forKey: "question") as! String
                    let answer = card.value(forKey: "answer") as! String
                    cards.append(QuizCard(question: question, answer: answer))
                }
            }
            
        } catch {
            print("Fetching data failed :(")
        }
        nextCard()
    }

    func nextCard() {
        let index = Int(arc4random_uniform(UInt32(cards.count)))
        if cards.count == 0 {
            self.performSegue(withIdentifier: "toMain", sender: nil)
        }
        currCard = cards[index]
        updateUI()
        
    }
    
    func updateUI() {
        termLabel.text! = currCard.question
        progressLabel.text! = "\(progress)/3"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
