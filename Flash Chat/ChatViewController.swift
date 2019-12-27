//
//  ViewController.swift
//  Flash Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework
//needs this delegate so we can make use of the iOS keyboard
//so that whenever a message occurs in the UITextViewDelegate, it knows to send the message to the ChatViewController
class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // Declare instance variables here
    //[Message] is our object datatype:model name
    var messageArray : [Message] = [Message]() // use empty parathensis to create a brand new array object
    
    // We've pre-linked the IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTableView.delegate = self
        messageTableView.dataSource = self
        
        //TODO: Set yourself as the delegate and datasource here:
        
        
        
        //TODO: Set yourself as the delegate of the text field here:
        messageTextfield.delegate = self
        
        
        //TODO: Set the tapGesture here:
        //self in this case is our current class
        //Register a new tap gesture
        //        the target parameter is where we want to receive the tap gesture which is the current VIEWcONTROLLER (use self to access this)
        //and the action takes a selector which is a custom function that gets triggrered when the user taps anywhere in the table view apart from the text box
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        //Add the tap gesture to the message table view
        messageTableView.addGestureRecognizer(tapGesture)
        

        //TODO: Register your MessageCell.xib file here:
        //nip is just thesame with xib file
        messageTableView.register(UINib(nibName : "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")

        //this is neccessary so as to make each user message fit in the messageCell container (for the sake of responsiveness)
        configureTableView()
        
        retrieveMessage()
        
        messageTableView.separatorStyle = .none
        
    }

    ///////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods
    
    
    
    //TODO: Declare cellForRowAtIndexPath here:
    //this method is responsible for handling the cells thats going to be displayed in our table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //we have to specify the class of the custom cell we are using which is the CutomMessageCell
        //we need to create our blank cell here!
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for : indexPath) as! CustomMessageCell //the class the message cell is linked with )//index path refers to the location of this cell that we are initializing
        
//        let messageArray = ["First Message", "Second Message", "Third Message", "The standard chunk of Lorem Ipsum used since the 1500s is reproduced below for those interested. Sections 1.10.32 and 1.10.33 from de Finibus Bonorum et Malorum by Cicero are also reproduced in their exact original form, accompanied by English versions from the 1914 translation by H. Rackham."]
//        //indexPath because everytime this function called tableView gets executed, it comes with unique row by default in form of integer
        cell.messageBody.text = messageArray[indexPath.row].messageBody
        cell.senderUsername.text = messageArray[indexPath.row].sender
        cell.avatarImageView.image = UIImage(named : "egg")
        
        if cell.senderUsername.text == Auth.auth().currentUser?.email as String! {
            //messages the current user sends
            cell.avatarImageView.backgroundColor = UIColor.flatMint()
            cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
        } else {
            cell.avatarImageView.backgroundColor = UIColor.flatWatermelon()
            cell.messageBackground.backgroundColor = UIColor.flatGray()
        }
        
        
        return cell
            // so that our compiler knows that this cell is an object type of CustomMessageCell
    }
    
    
    //TODO: Declare numberOfRowsInSection here:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    
    //TODO: Declare tableViewTapped here:
    @objc func tableViewTapped(){
        
        //this tableViewTapped methos is called above in the view did load by UITapGestureRecognizer
        //and then this method also calls another method in this class called textFieldDidEndEditing 
        messageTextfield.endEditing(true)
    }
    
    
    //TODO: Declare configureTableView here:
    func configureTableView(){
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.estimatedRowHeight = 120.0
    }
    
    
    ///////////////////////////////////////////
    
    //MARK:- TextField Delegate Methods
    
    

    //when a user starts typing into the textfield
    //TODO: Declare textFieldDidBeginEditing here:
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //once user starts typing, increase the height of where the text box is located
        //so that the input field would adjust from its initial position.. we do this by adding
        //50 to the initial position of the keyboard height which is 258.0 height
        //formular = height of the text box (50) + height of the keyboard (258)
        //we want all of the below codes happens animatedly thats why its been wrapped in the UIView.animate
        UIView.animate(withDuration: 0.5, animations : {
            self.heightConstraint.constant = 358
            //we need this method to check if something in the view has changed, then redraw everything on the screen
            self.view.layoutIfNeeded()
        })
        
    }
    
    
    
    
    //TODO: Declare textFieldDidEndEditing here:
    func textFieldDidEndEditing(_ textField: UITextField) {
        //once the user finish editing or typing, then change the textbox back to the initial
        //height it was before
        //and then reload the view because weve manipulated somehting on the view
        UIView.animate(withDuration: 0.5, animations: {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        })
    }
    
    ///////////////////////////////////////////
    
    
    //MARK: - Send & Recieve from Firebase
    
    func toggleMessageUIComponent(state : Bool) {
        messageTextfield.isEnabled = state
        sendButton.isEnabled = state
    }
    
    
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        
        
        //TODO: Send the message to Firebase and save it in our database
        //C ollapses down the keyboard and reset the input field size to default wich is 50
        messageTextfield.endEditing(true)
        //disable the send button and input field UI Components while sending data to remote cloud firebase dataabase
        toggleMessageUIComponent(state : false)
        //create a dedicated database table for our user messages inside the database
        let messageDB = Database.database().reference().child("Messages")
        //        format user messages to be inform of dictionary
        let messageDictionary = [
            "Sender" : Auth.auth().currentUser?.email,
            "MessageBody" : messageTextfield.text!
        ]
        
        //this creates a custom random key for every record in our DB for each message so each message
        //        would have its own unique id
        //and finally saving our message dictionary to the messages table
        messageDB.childByAutoId().setValue(messageDictionary) {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                print("Message saved successfully!")
                //after persisting the message to the database, then re-activate the message input field and then the send button so that the user would have the ability to send another message
                self.toggleMessageUIComponent(state : true)
                //clear the previously sent message
                self.messageTextfield.text = ""
            }
        }
        
        
    }
    
    //TODO: Create the retrieveMessages method here:
    
    func retrieveMessage() {
        //retrieve message from the messages table
        let messageDB = Database.database().reference().child("Messages")
        
        // when there is a new message in the database lets find a way to retrieve it instantly below
        // the .childAdded means whenever a new message is added to the messages db by observing it
        //second parameter of the .observe method takes a closure
        messageDB.observe(.childAdded) { (snapshot) in
            //so this closure would get called/returned whenever a new message is added to our message db
            //we represent the response gotten back from the firebas Message DB in format Dictionary
            //with its key value pair as String String as we have already set above while saving it in such format
            let snapshotValue = snapshot.value as! Dictionary<String,String>
            
            let messageText = snapshotValue["MessageBody"]!
            let sender = snapshotValue["Sender"]!
            
            //persist retrieved data from FireBase to our Model class
            let message = Message()
            message.messageBody = messageText
            message.sender = sender
            
            //append message object to the message array instantiated up there
            self.messageArray.append(message)
            self.configureTableView()
            //we would need to reload the message table view with the new data so it can reflect the data that gets added
            self.messageTableView.reloadData()
        }
    }
    
    
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        
        //TODO: Log out the user and send them back to WelcomeViewController
        do {
            try Auth.auth().signOut()
            //after signout return user back to the home or welcome page
            //this is how to take the user back from the chat view controller to the welcome view controller
            navigationController?.popToRootViewController(animated: true)
        }
        catch {
            print("Error : there was a problem signing out");
        }
        
    }
    


}
