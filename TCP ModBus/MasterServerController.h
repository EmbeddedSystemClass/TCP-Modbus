//
//  MasterServerController.h
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerThread.h"

@interface MasterServerController : UIViewController <UITextFieldDelegate>


@property (strong, nonatomic) IBOutlet UILabel *ip_Label;
@property (strong, nonatomic) IBOutlet UILabel *Value_Label;
@property (strong, nonatomic) IBOutlet UITextField *Port_TextField;
@property (strong, nonatomic) IBOutlet UIButton *Listen_Button;
@property (strong, nonatomic) IBOutlet UIButton *Stop_Button;
@property (strong, nonatomic) IBOutlet UIButton *Command_Button;
@property (strong, nonatomic) IBOutlet UIButton *Send_Button;
@property (strong, nonatomic) IBOutlet UIView *CommandView;
@property (strong, nonatomic) IBOutlet UITextField *DeviceID_TextField;
@property (strong, nonatomic) IBOutlet UITextField *Adress_TextField;
@property (strong, nonatomic) IBOutlet UITextField *Value_TextField;
@property (strong, nonatomic) IBOutlet UITextView *Log_TextView;

@property (strong, nonatomic) IBOutlet UIView *Inf_View;

@property (strong, nonatomic) UIButton *Back_Button;



- (IBAction)ListenButton_Action:(id)sender;
- (IBAction)StopButton_Action:(id)sender;
- (IBAction)CommandButton_Action:(id)sender;
- (IBAction)Command3_Button_Action:(id)sender;
- (IBAction)Command6_Button_Action:(id)sender;
- (IBAction)SendButton_Action:(id)sender;
- (IBAction)ClearButton_Action:(id)sender;

- (IBAction)InformButton_Action:(id)sender;
- (IBAction)Inf_Button_Action:(id)sender;

- (IBAction)TouchView_Action:(id)sender;

@end
