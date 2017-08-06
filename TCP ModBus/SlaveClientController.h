//
//  SlaveClientController.h
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>///////

#import "ClientThread.h"
#import "ClientRegistrCell.h"

@interface SlaveClientController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>


- (IBAction)ConnectButton_Action:(id)sender;
- (IBAction)DisconnectButton_Action:(id)sender;
- (IBAction)ClearButton_Action:(id)sender;

- (IBAction)InformButton_Action:(id)sender;
- (IBAction)Inf_Button_Action:(id)sender;

- (IBAction)TouchView_Action:(id)sender;

@end
