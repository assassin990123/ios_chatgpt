//
//  ViewController.swift
//  chatGPTDemo
//
//  Created by Nand  mistry on 17/01/23.
//

import UIKit
import SDWebImage
import AVFoundation

class ViewController: UIViewController, UITextViewDelegate {
        
    // MARK: - Chat GPT Helper Data
    enum FindType {
        case Text, Code
    }
    
    var isFind: FindType = .Text
    
    private var arrOfQuestionAnswerToDisplay = [ChatGPT]()
    private var arrOfQuestionAnswer = [ChatGPT]()
    
    private var arrOfQuestionAnswerImageToDisplay = [ChatGPTImage]()
    private var arrOfQuestionAnswerImage = [ChatGPTImage]()

    private struct ChatGPT {
        let questionAnswer: String
        let isSend: Bool
    }
    
    private struct ChatGPTImage {
        let questionAnswer: String
        let imgURL: String?
        let isSend: Bool
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak var lblLoader: UILabel!
    @IBOutlet weak var tblAns: UITableView!
    @IBOutlet weak var tblAnsWithImage: UITableView!

    @IBOutlet weak var cnstBottom: NSLayoutConstraint!
    @IBOutlet weak var lblAskme: UILabel!
    @IBOutlet weak var cnstQuestion: NSLayoutConstraint!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var txtQuestion: UITextView!
    @IBOutlet weak var lblPlaceHolder: UILabel!
    @IBOutlet weak var segmentOptions: UISegmentedControl!
    
    @IBOutlet weak var viewImgFullScreen: UIView!
    @IBOutlet weak var imgFullScreen: UIImageView!
    
    // MARK: - Global Variables
    var intSelectedSegment : Int = 0
    var arrOfImages = [ImageURL]()
    var selectedImageToViewInFullScreen : UIImage!
    
    // MARK: - Viewcontroller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setUpSegment()
    }
    
    //MARK: setupLayout
    func setupLayout() {
        self.showHideTbl()
        self.lblLoader.isHidden = true
        self.txtQuestion.layer.cornerRadius  = 8
        self.btnSubmit.layer.cornerRadius  = 8
        self.tblAns.delegate = self
        self.tblAns.dataSource = self
        
        self.tblAnsWithImage.delegate = self
        self.tblAnsWithImage.dataSource = self
        
        self.txtQuestion.delegate = self
        
        self.lblPlaceHolder.isHidden = false

        txtQuestion.addPadding(toTop: 10, toLeft: 6, toBottom: 10, toRight: 6)

        tblAns.transform = CGAffineTransform(rotationAngle: -(CGFloat)(Double.pi));
        tblAnsWithImage.transform = CGAffineTransform(rotationAngle: -(CGFloat)(Double.pi));
        observeKeyboardEvents()
    }
    
    //MARK: setUpSegment
    func setUpSegment(){
        let backgroundColor = UIColor.systemGreen
        let accentColor = UIColor.systemRed
        let textColor = UIColor.systemGreen

        segmentOptions.backgroundColor = backgroundColor
        segmentOptions.tintColor = accentColor

        let myAttribute = [ NSAttributedString.Key.foregroundColor: textColor]
        segmentOptions.setTitleTextAttributes(myAttribute, for: .selected)
        
    }
    
    //MARK: startBlink
    func startBlink() {
        self.lblLoader.isHidden = false
        UIView.animate(withDuration: 0.8,
              delay:0.0,
              options:[.allowUserInteraction, .curveEaseInOut, .autoreverse, .repeat],
                       animations: { self.lblLoader.alpha = 0 },
              completion: nil)
    }
    
    //MARK: stopBlink
    func stopBlink() {
        self.lblLoader.isHidden = true
    }

    @IBAction func segmentOptionChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            intSelectedSegment = 0
            print("option 0 clicked")
        }else if sender.selectedSegmentIndex == 1 {
            intSelectedSegment = 1
            print("option 1 clicked")
        }
        showHideTbl()
    }
    
    func showHideTbl(){
        if intSelectedSegment == 0 {
            self.tblAns.isHidden = false
            self.tblAnsWithImage.isHidden = true
        }else if intSelectedSegment == 1 {
            self.tblAns.isHidden = true
            self.tblAnsWithImage.isHidden = false
        }
    }
    
    //MARK: Search
    func search(){
        if intSelectedSegment == 0 {
            submitText()
        }else if intSelectedSegment == 1{
            submitTextForImage()
        }
    }
    
    //MARK: submitText
    func submitText() {
        self.view.endEditing(true)
        self.lblAskme.isHidden = true
        if txtQuestion.text != "" {
            let strQuestion : String = self.txtQuestion.text?.trime() ?? ""

            self.startBlink()
            self.sendMessage(question: strQuestion, isSend: true)
            self.lblPlaceHolder.isHidden = false
            self.lblAskme.isHidden = true
            self.txtQuestion.text = ""
            
            let isFind = isFind == .Text ? true:false
            OpenAIManager.shared.processPrompt(prompt: ("Human: \(strQuestion)\n"), isType: isFind) { [self] reponse in
                
                if reponse == "Error::nothing returned" {
                    appDelegate.showAlert(strMessage: "There is some problem. Please check your API Key", vc: self)
                }
                self.stopBlink()
                self.sendMessage(question: reponse.trime(), isSend: false)
            }
        } else {
            appDelegate.showAlert(strMessage: "Please enter something!", vc: self)
        }
    }
    
    //MARK: sendMessage
    func sendMessage(question: String, isSend: Bool) {
        self.arrOfQuestionAnswer.append(ChatGPT(questionAnswer: question, isSend: isSend))
        self.arrOfQuestionAnswerToDisplay = self.arrOfQuestionAnswer.reversed()
        reloadTbl()
    }
    
    //MARK: submitTextForImage
    func submitTextForImage() {
        self.view.endEditing(true)
        self.lblAskme.isHidden = true
        if txtQuestion.text != "" {
            let strQuestion : String = self.txtQuestion.text?.trime() ?? ""
            
            self.startBlink()

            self.arrOfQuestionAnswerImage.append(ChatGPTImage(questionAnswer: self.txtQuestion.text?.trime() ?? "", imgURL: "", isSend: true))
            self.arrOfQuestionAnswerImageToDisplay = self.arrOfQuestionAnswerImage.reversed()
            self.reloadTblWithImage()


            self.lblPlaceHolder.isHidden = false
            self.lblAskme.isHidden = true
            self.txtQuestion.text = ""

            
            OpenAIManager.shared.fetchImageForPrompt(prompt: ("Human: \(strQuestion)\n")) { [self] url in

                DispatchQueue.main.async {

                    self.arrOfImages = url
                    if url.count > 0 {
                        let imageURL : String = self.arrOfImages[0].url

                        self.arrOfQuestionAnswerImage.append(ChatGPTImage(questionAnswer: "", imgURL: imageURL, isSend: false))
                        
                        self.arrOfQuestionAnswerImageToDisplay = self.arrOfQuestionAnswerImage.reversed()

                        self.stopBlink()
                        self.reloadTblWithImage()
                    }else{
                        appDelegate.showAlert(strMessage: "There is some problem. Please check your API Key", vc: self)
                        stopBlink()
                    }
                }
            }
        } else {
            appDelegate.showAlert(strMessage: "Please enter something!", vc: self)
        }
    }
    
    //MARK: IB-Action Methods
    @IBAction func btnCloseFullScreenImageClicked(_ sender: UIButton) {
        self.viewImgFullScreen.isHidden = true
    }
    
    @IBAction func btnClearClick(_ sender: Any) {
        if intSelectedSegment == 0 {
            self.arrOfQuestionAnswer.removeAll()
            self.arrOfQuestionAnswerToDisplay.removeAll()
            
            reloadTbl()
            self.lblAskme.isHidden = false
        }else if intSelectedSegment == 1 {
            self.arrOfQuestionAnswerImage.removeAll()
            self.arrOfQuestionAnswerImageToDisplay.removeAll()
            
            self.reloadTblWithImage()
            self.lblAskme.isHidden = false
        }
    }
    @IBAction func btnSubmitClick(_ sender: Any) {
        search()
    }
        
    //MARK: TextView Delegate Methods
    func textViewDidChange(_ textView: UITextView) {
        print("text changing...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.txtQuestion.contentSize.height < 40 {
                self.cnstQuestion.constant = 40
            } else if self.txtQuestion.contentSize.height > 70 {
                self.cnstQuestion.constant = 70
            } else {
                self.cnstQuestion.constant = self.txtQuestion.contentSize.height
            }
        }
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.lblAskme.isHidden = true
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if txtQuestion.text.isEmpty {
            self.lblPlaceHolder.isHidden = false
        }
        
        if intSelectedSegment == 0 {
            if arrOfQuestionAnswerToDisplay.count == 0 {
                self.lblAskme.isHidden = false
            }else{
                self.lblAskme.isHidden = true
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.lblPlaceHolder.isHidden = true
        if !txtQuestion.text!.isEmpty {
            txtQuestion.text = ""
        }
    }
    
    //MARK: reload Table
    func reloadTbl(){
        
        self.tblAns.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.arrOfQuestionAnswerToDisplay.count > 0 {
                
                let indexPath = IndexPath(row: 0, section: 0)
                self.tblAns.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
    }

    //MARK: reload Table With Image
    func reloadTblWithImage(){
        
        self.tblAnsWithImage.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.arrOfQuestionAnswerImageToDisplay.count > 0 {
                let indexPath = IndexPath(row: 0, section: 0)
                self.tblAnsWithImage.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
    }
    
    //MARK: KeyboardEvents Observer
    func observeKeyboardEvents() {
       NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) in
           guard let keyboardHeight = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
           print("Keyboard height in KeyboardWillShow method: \(keyboardHeight.height)")
           self?.cnstBottom.constant = keyboardHeight.height - 10.0
           }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.cnstBottom.constant = 20.0
        }
   }
}

extension UITextView {
    func addPadding(toTop : CGFloat, toLeft : CGFloat, toBottom : CGFloat, toRight : CGFloat) {
        self.textContainerInset = UIEdgeInsets(top: toTop, left: toLeft, bottom: toBottom, right: toRight)
    }
}

//MARK: tableview delegate and datasource
extension ViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if intSelectedSegment == 0 {
            return self.arrOfQuestionAnswerToDisplay.count
        }else if intSelectedSegment == 1 {
            return arrOfQuestionAnswerImageToDisplay.count
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if intSelectedSegment == 0 && tableView == tblAns{
            if self.arrOfQuestionAnswerToDisplay[indexPath.row].isSend == true {
                let cell = tblAns.dequeueReusableCell(withIdentifier: "HumanCell") as! HumanCell
                cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
                let question = arrOfQuestionAnswerToDisplay[indexPath.row].questionAnswer

                cell.lblQuestion.text = question
                return cell
            }else{
                
                let cell = tblAns.dequeueReusableCell(withIdentifier: "BotCell") as! BotCell
                cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
                let answer = arrOfQuestionAnswerToDisplay[indexPath.row].questionAnswer
                cell.lblAnswer.text = answer
                return cell
            }
        }
        else if intSelectedSegment == 1 && tableView == tblAnsWithImage{
            if self.arrOfQuestionAnswerImageToDisplay[indexPath.row].isSend == true {
                let cell = tblAnsWithImage.dequeueReusableCell(withIdentifier: "HumanCellImage") as! HumanCellImage
                cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
                let question = arrOfQuestionAnswerImageToDisplay[indexPath.row].questionAnswer

                cell.lblQuestion.text = question
                return cell
            }else{
                
                let cell = tblAnsWithImage.dequeueReusableCell(withIdentifier: "BotCellImage") as! BotCellImage
                cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                
                cell.imgActivityIndicator.startAnimating()
                let imgURL = arrOfQuestionAnswerImageToDisplay[indexPath.row].imgURL

                cell.imgAnswer.sd_setImage(with: URL(string: imgURL!), placeholderImage: UIImage(named: "icChatGPT"), options: .refreshCached, progress: .none) { image, error, type, url in
                    if image != nil {
                        cell.imgAnswer.image = image
                        cell.imgAnswer.layer.borderColor = UIColor.orange.cgColor
                        cell.imgAnswer.layer.borderWidth = 2
                        cell.imgActivityIndicator.stopAnimating()
                        cell.imgActivityIndicator.isHidden = true
                    }else {
                        //Image Not found
                    }
                }
                cell.imgAnswer.layer.cornerRadius = 10
                cell.imgAnswer.layer.masksToBounds = true
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if intSelectedSegment == 1 && tableView == tblAnsWithImage{
            if self.arrOfQuestionAnswerImageToDisplay[indexPath.row].isSend == false {
                
                let imgURL = arrOfQuestionAnswerImageToDisplay[indexPath.row].imgURL

                self.imgFullScreen.sd_setImage(with: URL(string: imgURL!), placeholderImage: UIImage(named: "icChatGPT"), options: .refreshCached, progress: .none) { image, error, type, url in
                    if image != nil {
                        self.imgFullScreen.image = image
                        self.viewImgFullScreen.isHidden = false
                    }else {
                        //Image Not found
                        self.viewImgFullScreen.isHidden = true
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
//MARK: HumanCell
class HumanCell: UITableViewCell {
    @IBOutlet weak var lblQuestion: UILabel!
    override func awakeFromNib() {
        
    }
}
//MARK: BotCell
class BotCell: UITableViewCell {
    @IBOutlet weak var lblAnswer: UILabel!
    override func awakeFromNib() {
        
    }
}

//MARK: HumanCellImage
class HumanCellImage: UITableViewCell {
    @IBOutlet weak var lblQuestion: UILabel!
    override func awakeFromNib() {        
    }
}
//MARK: BotCellImage
class BotCellImage: UITableViewCell {
    @IBOutlet weak var imgAnswer: UIImageView!
    @IBOutlet weak var imgActivityIndicator: UIActivityIndicatorView!
    override func awakeFromNib() {
    }
}
