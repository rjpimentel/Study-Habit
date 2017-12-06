//
//  QuizSetModel.swift
//  Alarm-ios-swift
//
//  Created by RJ Pimentel on 11/26/17.
//

import Foundation
class QuizSet {
    var cards: [QuizCard]
    var id: Int
    var creator: String
    var title: String
    var enabled: Bool
    var count: Int = 0
    
    init(title: String, id: Int, creator: String, cards: [QuizCard], enabled: Bool) {
        self.title = title
        self.id = id
        self.creator = creator
        self.cards = cards
        self.enabled = enabled
    }
    
    func addCard(card: QuizCard) {
        cards.append(card)
        count += 1
    }
}

class QuizCard {
    var question: String
    var answer: String
    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}
