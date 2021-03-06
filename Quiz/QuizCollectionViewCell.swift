//
//  QuizCollectionViewCell.swift
//  Quiz
//
//  Created by Chinsyo on 2017/6/22.
//  Copyright © 2017年 chinsyo. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher

class QuizCollectionViewCell: UICollectionViewCell {
    
    weak var question: Question! {
        
        didSet {
            guard let question = question, question.options.count >= 4 else {
                return
            }
            contentLabel.text = question.content
            
            let resources = question.options.map { URL(string: $0.image)! }
            let processor = TintImageProcessor(tint: Constant.Color.blue.withAlphaComponent(0.3))
            
            for (index, button) in [topLeftButton, topRightButton, bottomLeftButton, bottomRightButton].enumerated() {
                
                button?.kf.setImage(with: resources[index], for: .normal)
                button?.kf.setImage(with: resources[index], for: .selected, options: [.processor(processor)])
            }
        }
    }
    
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBOutlet weak var topLeftButton: UIButton! 
    @IBOutlet weak var topRightButton: UIButton!
    @IBOutlet weak var bottomLeftButton: UIButton!
    @IBOutlet weak var bottomRightButton: UIButton!
    
    override func prepareForReuse() {
        
        for (index, button) in [topLeftButton, topRightButton, bottomLeftButton, bottomRightButton].enumerated() {

            button?.isSelected = question.choice == question.options[index]
        }
    }
    
    @IBAction func didTappedOptionButton(_ sender: UIButton) {
        
        if sender.isSelected {
            sender.isSelected = false
        } else {
            [topLeftButton, topRightButton, bottomLeftButton, bottomRightButton].forEach { button in
                button?.isSelected = false
            }
            sender.isSelected = true
        }
        
        guard question.options.count >= 4 else {
            return
        }
        
        switch sender {
        case topLeftButton:
            question.choice = question.options[0]
            
        case topRightButton:
            question.choice = question.options[1]
            
        case bottomLeftButton:
            question.choice = question.options[2]
            
        case bottomRightButton:
            question.choice = question.options[3]
            
        default:
            break
        }
    }
}
