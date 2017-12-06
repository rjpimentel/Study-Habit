//
//  ChooseSetsViewController.swift
//  Alarm-ios-swift
//
//  Created by RJ Pimentel on 11/26/17.
//  Copyright © 2017 LongGames. All rights reserved.
//

import UIKit
import CoreData

class MySetsViewController: UITableViewController {
    //Todo: Initialize QuizSets instance and pull stored data from user defaults
    var mySets: [QuizSet] = []
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mySets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Id.quizSetCellIdentifier)
        let set = mySets[indexPath.row]
        let sw = UISwitch(frame: CGRect())
        cell?.textLabel?.text = set.title
        cell?.detailTextLabel?.text = String(set.count) + " cards"
        sw.transform = CGAffineTransform(scaleX: 0.9, y: 0.9);
        //tag is used to indicate which row had been touched
        sw.tag = indexPath.row
        sw.addTarget(self, action: #selector(MySetsViewController.switchTapped(_:)), for: UIControlEvents.valueChanged)
        if set.enabled {
            cell!.backgroundColor = UIColor.white
            cell!.textLabel?.alpha = 1.0
            cell!.detailTextLabel?.alpha = 1.0
            sw.setOn(true, animated: false)
        } else {
            cell!.backgroundColor = UIColor.groupTableViewBackground
            cell!.textLabel?.alpha = 0.5
            cell!.detailTextLabel?.alpha = 0.5
            sw.setOn(false, animated: false)
        }
        cell!.accessoryView = sw
        //delete empty seperator line
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.row
            let cells = tableView.visibleCells
            for cell in cells {
                let sw = cell.accessoryView as! UISwitch
                //adjust saved index when row deleted
                if sw.tag > index {
                    sw.tag -= 1
                }
            }
            if mySets.count == 0 {
                self.navigationItem.leftBarButtonItem = nil
            }
            
            // Delete the row from the data source
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let setRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuizSets")
            let cardRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cards")
            do {
                let setResult = try context.fetch(setRequest)
                let cardResult = try context.fetch(cardRequest)
                for data in setResult as! [NSManagedObject] {
                    if data.value(forKey: "id") as! Int == mySets[indexPath.row].id {
                        context.delete(data)
                    }
                }
                for data in cardResult as! [NSManagedObject] {
                    if data.value(forKey: "setId") as! Int == mySets[indexPath.row].id {
                        context.delete(data)
                    }
                }
                mySets.remove(at: indexPath.row)
                try context.save()
            } catch {
                print("Failed deleting data")
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    //Called when set is activated
    @IBAction func switchTapped(_ sender: UISwitch) {
        let index = sender.tag
        mySets[index].enabled = !mySets[index].enabled
        print(mySets[index].enabled)
        enable(set: mySets[index])
        tableView.reloadData()
    }
    
    //Stores new enable state in CoreData
    func enable(set: QuizSet) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let setRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuizSets")
        do {
            let result = try context.fetch(setRequest)
            for data in result as! [NSManagedObject] {
                if data.value(forKey: "title") as! String == set.title {
                    data.setValue(set.enabled, forKey: "enabled")
                    try context.save()
                }
            }
        } catch {
            print("Fetching dind't work")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //fetch data and store in mySets
        fetchData()
        
        // Reload table view after fetching data
        tableView.reloadData()
    }
    
    //pulls data from CoreData and sets mySets array
    func fetchData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        var sets: [Int:QuizSet] = [:]
        let setRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuizSets")
        let cardRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cards")
        setRequest.returnsObjectsAsFaults = false
        cardRequest.returnsObjectsAsFaults = false
        
        
        //iterate through sets, iterate through cards and match them with each set
        
        do {
            let result = try context.fetch(setRequest)
            for data in result as! [NSManagedObject] {
                let title = data.value(forKey: "title") as! String
                let creator = data.value(forKey: "creator") as! String
                let id = data.value(forKey: "id") as! Int
                let enabled = data.value(forKey: "enabled") as! Bool
                sets[id] = QuizSet(title: title, id: id, creator: creator, cards: [], enabled: enabled)
            }
            
        } catch {
            print("Failed to fetch QuizSets")
        }
        
        do {
            let result = try context.fetch(cardRequest)
            for data in result as! [NSManagedObject] {
                let setId = data.value(forKey: "setId") as! Int
                let card = QuizCard(question: data.value(forKey: "question") as! String, answer: data.value(forKey: "answer") as! String)
                sets[setId]!.addCard(card: card)
            }
        } catch {
            print("Failed to fetch cards")
        }

        for id in sets.keys {
            mySets.append(sets[id]!)
        }
        
        if mySets.count == 0 {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        else {
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mySets = []
        fetchData()
        if mySets.count != 0 {
            self.navigationItem.leftBarButtonItem = editButtonItem
        }
        tableView.reloadData()
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
