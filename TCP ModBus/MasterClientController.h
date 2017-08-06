//
//  MasterClientController.h
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientThread.h"

@interface MasterClientController : UIViewController <UITextFieldDelegate>


- (IBAction)ConnectButton_Action:(id)sender;
- (IBAction)DisconnectButton_Action:(id)sender;

- (IBAction)CommandButton_Action:(id)sender;
- (IBAction)Command3_Button_Action:(id)sender;
- (IBAction)Command6_Button_Action:(id)sender;

- (IBAction)SendButton_Action:(id)sender;
- (IBAction)ClearButton_Action:(id)sender;

- (IBAction)InformButton_Action:(id)sender;

- (IBAction)TouchView_Action:(id)sender;

- (IBAction)InfView_Button_Action:(id)sender;

@end
