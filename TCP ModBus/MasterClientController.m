//
//  MasterClientController.m
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import "MasterClientController.h"

@interface MasterClientController ()

@end

@implementation MasterClientController
{
    UInt16 id0;
    char func[12];
    
    IBOutlet UINavigationItem *NavigationBar;
    IBOutlet UITextField *ip_TextField;
    IBOutlet UITextField *port_TextField;
    IBOutlet UITextField *DeviceID_TextField;
    IBOutlet UITextField *Adress_TextField;
    IBOutlet UITextField *Value_TextField;
    IBOutlet UIView *Command_View;
    IBOutlet UIButton *ConnectButton;
    IBOutlet UIButton *DisconnectButton;
    IBOutlet UIButton *Command_Button;
    IBOutlet UIButton *SendButton;
    
    IBOutlet UILabel *Value_Label;
    IBOutlet UITextView *Log_TextView;
    
    IBOutlet UIView *InfView;
    IBOutlet UILabel *Version_Label;
    
    ClientThread *Client_Thread;
    NSData *Data_to_send;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    port_TextField.delegate=self;
    DeviceID_TextField.delegate=self;
    Adress_TextField.delegate=self;
    Value_TextField.delegate=self;
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    Version_Label.text=[NSString stringWithFormat:@"Version: %@",version];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated{
    DisconnectButton.hidden=YES;
    Command_View.hidden=YES;
    SendButton.enabled=NO;
    NavigationBar.rightBarButtonItem.enabled=YES;
    id0=0;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    ip_TextField.text = [userDefaults objectForKey:@"IP"];
    port_TextField.text = [userDefaults objectForKey:@"Port_Client"];
    
    DeviceID_TextField.text=@"1";
    Adress_TextField.text=@"0";
    Value_TextField.text=@"1";
    
    InfView.hidden=YES;
}

-(void)viewDidDisappear:(BOOL)animated{
    InfView.hidden=YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)ConnectButton_Action:(id)sender {
    ConnectButton.enabled=NO;
    self.tabBarController.tabBar.userInteractionEnabled=NO;
    NavigationBar.rightBarButtonItem.enabled=NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:ip_TextField.text forKey:@"IP"];
    [userDefaults setObject:port_TextField.text forKey:@"Port_Client"];
    [userDefaults setObject:DeviceID_TextField.text forKey:@"DeviceID"];
    
    Client_Thread=[[ClientThread alloc]init];
    [Client_Thread initialyzeConnection:ip_TextField.text :[port_TextField.text intValue] :NavigationBar :self.tabBarController.tabBar :ConnectButton :DisconnectButton :SendButton :NULL :Log_TextView :NULL : NULL:1];
}

- (IBAction)DisconnectButton_Action:(id)sender {
    [Client_Thread CloseConnection];
}

- (IBAction)CommandButton_Action:(id)sender {
    Command_View.hidden=NO;
}

- (IBAction)Command3_Button_Action:(id)sender {
    [Command_Button setTitle:@"3" forState:UIControlStateNormal];
    Command_View.hidden = YES;
    Value_Label.text = @"Registers count";
}

- (IBAction)Command6_Button_Action:(id)sender {
    [Command_Button setTitle:@"6" forState:UIControlStateNormal];
    Command_View.hidden = YES;
    Value_Label.text = @"Value";
}

- (IBAction)SendButton_Action:(id)sender {
    [Client_Thread WriteData:[self GetFunction:[Command_Button.titleLabel.text intValue] :[DeviceID_TextField.text intValue] :[Adress_TextField.text intValue] :[Value_TextField.text intValue]]];
}

- (IBAction)ClearButton_Action:(id)sender {
    Log_TextView.text=@"";
}

- (IBAction)InformButton_Action:(id)sender {
    InfView.hidden=NO;
}

- (IBAction)TouchView_Action:(id)sender {
    [ip_TextField resignFirstResponder];
    [port_TextField resignFirstResponder];
    [DeviceID_TextField resignFirstResponder];
    [Adress_TextField resignFirstResponder];
    [Value_TextField resignFirstResponder];
    Command_View.hidden = YES;

}

- (IBAction)InfView_Button_Action:(id)sender {
    InfView.hidden=YES;
}

#pragma mark - FUNCTIONS
- (NSData*)GetFunction :(UInt8)Function :(UInt8)DeviceID : (UInt16)Adress : (UInt16)Value
{
    NSUInteger msg_size=12;
    
    id0++;
    func[0] = ((id0 >> 8) & 0xFF);
    func[1] = (id0 & 0xFF);
    func[2] = 0;
    func[3] = 0;
    func[4] = 0;//число байт после HIGH
    func[5] = 6;//число байт после LOW
    func[6] = DeviceID; //DEVICE_ID
    func[7] = Function;
    
    //PDU:
    func[8] = ((Adress >> 8) & 0xFF);
    func[9] = (Adress & 0xFF);
    func[10] = ((Value >> 8) & 0xFF);
    func[11] = (Value & 0xFF);
    
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"[HH:mm:ss] "];
    NSString *dateString = [formatter stringFromDate:now];
    NSString *text =[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n",func[0]&0xff,func[1]&0xff,func[2]&0xff,func[3]&0xff,func[4]&0xff,func[5]&0xff,func[6]&0xff,func[7]&0xff,func[8]&0xff,func[9]&0xff,func[10]&0xff,func[11]&0xff];
    text = [dateString stringByAppendingString:text];
    
    Log_TextView.text=[Log_TextView.text stringByAppendingString:text];
    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
    NSLog(@"Byte message :%@\n",data);
    return data;
}


#pragma mark - DELEGATES

-(void)textFieldDidEndEditing:(UITextField *)textField{
    
    if(textField==DeviceID_TextField)
    {
        if([DeviceID_TextField.text intValue]>255)
        {
            DeviceID_TextField.text = @"255";
        }
        else if ([DeviceID_TextField.text isEqual:@""] | [DeviceID_TextField.text isEqual:@"0"])
        {
            DeviceID_TextField.text = @"1";
        }
    }
    else if (textField==Adress_TextField)
    {
        if([Command_Button.titleLabel.text isEqual:@"3"])
        {
            if(([Adress_TextField.text intValue]+[Value_TextField.text intValue])>65535)
            {
                UInt16 val=65535-[Value_TextField.text intValue];
                Adress_TextField.text =[NSString stringWithFormat:@"%d",val];
            }
        }
        else
        {
            if ([Adress_TextField.text intValue]>65535)
            {
                Adress_TextField.text = @"65535";
            }
            
        }
        if ([Adress_TextField.text isEqual:@""])
        {
            Adress_TextField.text = @"0";
        }
    }
    else if (textField==Value_TextField)
    {
        if([Command_Button.titleLabel.text isEqual:@"3"])
        {
            if ([Value_TextField.text isEqual:@"0"])
            {
                Value_TextField.text=@"1";
            }
            else if(([Adress_TextField.text intValue]+[Value_TextField.text intValue])>65535)
            {
                UInt16 val=65535-[Adress_TextField.text intValue];
                Value_TextField.text =[NSString stringWithFormat:@"%d",val];
            }
        }
        else
        {
            if ([Value_TextField.text intValue]>65535)
            {
                Value_TextField.text = @"65535";
            }
        }
        if ([Value_TextField.text isEqual:@""])
        {
            Value_TextField.text = @"0";
        }
    }
    else if (textField==port_TextField)
    {
        if ([port_TextField.text intValue]>65535)
        {
            port_TextField.text=@"65535";
        }
        else if ([port_TextField.text isEqual:@""])
        {
            port_TextField.text = @"0";
        }
    }
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(![string intValue] && ![string isEqualToString:@""] && ![string isEqualToString:@"0"]) { return NO; } else { return YES; }
}

@end
