//
//  QuizCollectionViewController.swift
//  Quiz
//
//  Created by Chinsyo on 2017/6/22.
//  Copyright © 2017年 chinsyo. All rights reserved.
//

import UIKit
import Kingfisher

private let reuseIdentifier = "QuizCollectionViewCell"

class QuizCollectionViewController: UICollectionViewController {

    // MARK: - Property
    weak var timer = Timer()
    
    var remain: TimeInterval = 120

    var questions = JSONFactory.questions(with: "zquestions")
    
    lazy var progressLabel: UILabel = {
        $0.font = UIFont(name: "Avenir-Black", size: 36)
        $0.text = "02:00"
        $0.textColor = Constant.Color.black
        $0.textAlignment = .center
        return $0
    }(UILabel())

    lazy var submitButton: UIButton = {
        $0.backgroundColor = Constant.Color.white
        $0.titleLabel?.font = UIFont(name: "Avenir", size: 24)
        $0.setTitle("Submit", for: .normal)
        $0.setTitleColor(Constant.Color.blue, for: .normal)
        $0.setTitleColor(Constant.Color.gray, for: .disabled)
        $0.addTarget(self, action: #selector(didTappedSubmitButton), for: .touchUpInside)
        $0.isEnabled = false
        return $0
    }(UIButton(type: .custom))

    // MARK: - Life Cycle
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        timer?.invalidate()
        timer = nil
        print("deinit vc")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.collectionView?.backgroundColor = Constant.Color.blue
        self.collectionView?.isPagingEnabled = true
        self.definesPresentationContext = true
        
        for question in questions.shuffled() {
            question.options.shuffle()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] notify in
            guard let strongSelf = self else {
                return
            }
            strongSelf.timer?.fireDate = .distantFuture
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] notify in
            
            guard let strongSelf = self else {
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let modal = storyboard.instantiateViewController(withIdentifier: "modal") as! ModalViewController
            modal.modalPresentationStyle = .custom
            modal.transitioningDelegate = self
            
            if strongSelf.remain >= 120 {
                modal.content = "You have 2 minutes to finish the quiz."
                modal.action = "Start"
            } else {
                modal.content = "Continue the quiz?"
                modal.action = "Continue"
            }
            
            modal.buttonHandler = { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.runTimer()
            }
            strongSelf.present(modal, animated: true, completion: nil)
        }
    }
    
    override func viewWillLayoutSubviews() {
        
        view.addSubview(progressLabel)
        view.bringSubview(toFront: progressLabel)
        progressLabel.snp.makeConstraints { maker in
            maker.height.equalTo(40)
            maker.left.top.right.equalToSuperview().inset(20)
        }
        
        view.addSubview(submitButton)
        view.bringSubview(toFront: submitButton)
        submitButton.snp.makeConstraints { maker in
            maker.height.equalTo(40)
            maker.left.bottom.right.equalToSuperview().inset(20)
        }
        submitButton.layer.masksToBounds = true
        submitButton.layer.cornerRadius = 20
    }
    
    // MARK: - Action
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    func updateTimer() {
        
        if remain < 1 {
            submitAnswer()
            submitButton.isEnabled = false
        } else {
            remain -= 1
            progressLabel.text = formatTimeString(seconds: remain)
            updateButtonState()
        }
    }
    
    func updateButtonState() {
        submitButton.isEnabled = self.questions.map { $0.choice != nil }.reduce(true, { $0 && $1 })
    }
    
    func caculateScore() -> Int {
        var score = 0
        for question in questions {
            if let choice = question.choice, choice == question.answer {
                score += 1
            }
        }
        return score
    }
    
    func formatTimeString(seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02i:%02i", m, s)
    }
    
    func submitAnswer() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let modal = storyboard.instantiateViewController(withIdentifier: "modal") as! ModalViewController
        modal.modalPresentationStyle = .custom
        modal.transitioningDelegate = self
        modal.content = "Your score is \(self.caculateScore()) / \(self.questions.count), retake?"
        modal.action = "Retake"
        modal.buttonHandler = { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.remain = 120
            strongSelf.progressLabel.text = strongSelf.formatTimeString(seconds: strongSelf.remain)
            
            for question in strongSelf.questions {
                question.choice = nil
            }
            strongSelf.collectionView?.reloadData()
            strongSelf.collectionView?.setContentOffset(.zero, animated: true)
            strongSelf.timer?.fireDate = .distantPast
        }
        
        timer?.fireDate = .distantFuture
        present(modal, animated: true, completion: nil)
    }
    
    func didTappedSubmitButton(_ sender: UIButton) {
        submitAnswer()
    }
}

extension QuizCollectionViewController {
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return questions.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! QuizCollectionViewCell
    
        cell.question = questions[indexPath.row]
        cell.backgroundColor = Constant.Color.white
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 5
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

// MARK: - Animator
extension QuizCollectionViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentingAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissingAnimator()
    }
}
