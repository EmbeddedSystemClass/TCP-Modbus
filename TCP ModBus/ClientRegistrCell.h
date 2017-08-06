//
//  RegistrCell.h
//  TCP ModBus
//
//  Created by Admin on 28.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClientRegistrCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *CellLabel;
@property (strong, nonatomic) IBOutlet UITextField *CellTextField;

@end