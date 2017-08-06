//
//  SlaveServerController.h
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ServerThread.h"
#import "ServerRegistrCell.h"


@interface SlaveServerController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *ip_Label;
@property (strong, nonatomic) IBOutlet UIButton *Listen_Button;
@property (strong, nonatomic) IBOutlet UIButton *Stop_Button;
@property (strong, nonatomic) IBOutlet UITextField *Port_TextField;
@property (strong, nonatomic) IBOutlet UITextField *DeviceID_TextField;
@property (strong, nonatomic) IBOutlet UITableView *Registrs_TableView;
@property (strong, nonatomic) IBOutlet UITextView *Log_TextView;

@property (assign, nonatomic) UInt16* RegistrsValuePointer;
@property (strong, nonatomic) UIButton *Back_Button;

@property (strong, nonatomic) IBOutlet UIView *Inf_View;

- (IBAction)ListenButton_Action:(id)sender;
- (IBAction)StopButton_Action:(id)sender;
- (IBAction)ClearButton_Action:(id)sender;

- (IBAction)InformButton_Action:(id)sender;
- (IBAction)Inf_Button_Action:(id)sender;

- (IBAction)TouchView_Action:(id)sender;

@end
