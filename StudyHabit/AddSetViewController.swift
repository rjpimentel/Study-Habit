//
//  AddSetViewController.swift
//  StudyHabit
//
//  Created by RJ Pimentel on 11/29/17.

import UIKit
import Alamofire
import CoreData

class AddSetViewController: UITableViewController, UISearchBarDelegate {

    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchResults: [QuizSet] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.returnKeyType = UIReturnKeyType.search
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResults.count == 0 {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        else {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        }
        
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "result")
        if let cell = cell {
            let set = searchResults[indexPath.row]
            cell.textLabel?.text = set.title + " (\(set.count) terms)"
            cell.detailTextLabel?.text = "Created by: " + set.creator
            return cell
        }
         return UITableViewCell()
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Add set?", message: "Do you want to add set " + searchResults[indexPath.row].title, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.default, handler: {_ in self.storeSet(set: self.searchResults[indexPath.row])}))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func storeSet(set: QuizSet) {
        print("adding set")
        
        //Setup CoreData save state
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let setEntity = NSEntityDescription.entity(forEntityName: "QuizSets", in: context)
        let newSet = NSManagedObject(entity: setEntity!, insertInto: context)
        
        //Set values for the set
        newSet.setValue(set.title, forKey: "title")
        newSet.setValue(set.enabled, forKey: "enabled")
        newSet.setValue(set.creator, forKey: "creator")
        newSet.setValue(set.id, forKey: "id")
        
        do {
            try context.save()
        } catch {
            print("Failed saving set :(")
        }
        addCards(set: set)
    }
    
    //Gets cards from server based on QuizSet id and adds to given QuizSet
    func addCards(set: QuizSet) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let cardEntity = NSEntityDescription.entity(forEntityName: "Cards", in: context)
        let requestURL = URL(string: "https://api.quizlet.com/2.0/sets/\(set.id)?client_id=ffgsm2Fb8G")!
        Alamofire.request(requestURL).responseJSON(completionHandler: { (response) in
            if let result = response.result.value {
                let data = result as! [String:AnyObject]
                let terms = data["terms"] as! [[String:AnyObject]]
                for term in terms {
                    let newCard = NSManagedObject(entity: cardEntity!, insertInto: context)
                    let question = term["term"] as! String
                    let answer = term["definition"] as! String
                    newCard.setValue(question, forKey: "question")
                    newCard.setValue(answer, forKey: "answer")
                    newCard.setValue(set.id, forKey: "setId")
                }
                do {
                    try context.save()
                } catch {
                    print("Failed saving cards :(")
                }
            }
        })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchResults = []
        if var query = searchBar.text {
            query = query.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
            let requestURL = URL(string: "https://api.quizlet.com/2.0/search/sets/?client_id=ffgsm2Fb8G&q=" + query)!
            Alamofire.request(requestURL).responseJSON(completionHandler: { (response) in
                if let result = response.result.value {
                    let allSets = result as! [String:AnyObject]
                    let sets = allSets["sets"] as! [[String:AnyObject]]
                    for dict in sets {
                        let title = dict["title"] as! String
                        let id = dict["id"] as! Int
                        let creator = dict["created_by"] as! String
                        let count = dict["term_count"] as! Int
                        let set = QuizSet(title: title, id: id, creator: creator, cards: [], enabled: true)
                        set.count = count
                        self.searchResults.append(set)
                    }
                    self.tableView.reloadData()
                }
            })
        }
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
