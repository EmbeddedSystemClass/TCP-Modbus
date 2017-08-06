//
//  MasterServerController.m
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import "MasterServerController.h"

@interface MasterServerController ()

@end

@implementation MasterServerController
{
    ServerThread *Server_Thread;
    
    IBOutlet UILabel *Version_Label;
    UInt16 id0;
    char func[12];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _Inf_View.hidden=YES;
    _Stop_Button.enabled=NO;
    _CommandView.hidden=YES;
    _Send_Button.enabled=NO;
    id0=0;
    
//Custom back button
    _Back_Button = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 60.0f, 30.0f)];
    [_Back_Button setTitle:@"Client" forState:UIControlStateNormal];
    [_Back_Button setTitleColor:[UIColor colorWithRed:0.12 green:0.53 blue:0.90 alpha:1.0] forState:UIControlStateNormal];
    [_Back_Button addTarget:self action:@selector(popBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_Back_Button];
    self.navigationItem.leftBarButtonItem = backButtonItem;
////////////////////
    
    Server_Thread=[[ServerThread alloc]init];
    NSString *string=[Server_Thread getIPAddress];
    self.ip_Label.text = string;
    
    if ([string isEqualToString:@"Need Wi-Fi connection"])
        _Listen_Button.enabled=NO;
    
    _Port_TextField.delegate=self;
    _DeviceID_TextField.delegate=self;
    _Adress_TextField.delegate=self;
    _Value_TextField.delegate=self;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _Port_TextField.text = [userDefaults objectForKey:@"Port_Server"];

    _DeviceID_TextField.text=@"1";
    _Adress_TextField.text=@"0";
    _Value_TextField.text=@"1";
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    Version_Label.text=[NSString stringWithFormat:@"Version: %@",version];
    
}

-(void)viewDidDisappear:(BOOL)animated{
    self.Log_TextView.text=@"";
}

-(void) popBack {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)ListenButton_Action:(id)sender {
    self.tabBarController.tabBar.userInteractionEnabled=NO;
    self.Listen_Button.enabled=NO;
    self.Back_Button.enabled=NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_Port_TextField.text forKey:@"Port_Server"];
    [userDefaults setObject:_DeviceID_TextField.text forKey:@"DeviceID"];
    
    [Server_Thread StartListen:self :1];
}

- (IBAction)StopButton_Action:(id)sender {
    [Server_Thread StopListen];
    //Server_Thread=NULL;
}


- (IBAction)CommandButton_Action:(id)sender {
    self.CommandView.hidden=NO;
}

- (IBAction)Command3_Button_Action:(id)sender {
    [self.Command_Button setTitle:@"3" forState:UIControlStateNormal];
    self.CommandView.hidden = YES;
    self.Value_Label.text = @"Registrs count";
}

- (IBAction)Command6_Button_Action:(id)sender {
    [self.Command_Button setTitle:@"6" forState:UIControlStateNormal];
    self.CommandView.hidden = YES;
    self.Value_Label.text = @"Value";
}

- (IBAction)SendButton_Action:(id)sender {
        [Server_Thread SendData:[self GetFunction:[_Command_Button.titleLabel.text intValue] :[_DeviceID_TextField.text intValue] :[_Adress_TextField.text intValue] :[_Value_TextField.text intValue]]];
}

- (IBAction)ClearButton_Action:(id)sender {
    _Log_TextView.text=@"";
}

- (IBAction)InformButton_Action:(id)sender {
    _Inf_View.hidden=NO;
}

- (IBAction)Inf_Button_Action:(id)sender {
    _Inf_View.hidden=YES;
}

- (IBAction)TouchView_Action:(id)sender {
    [_Port_TextField resignFirstResponder];
    [_DeviceID_TextField resignFirstResponder];
    [_Adress_TextField resignFirstResponder];
    [_Value_TextField resignFirstResponder];
    _CommandView.hidden = YES;
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
    NSString *text =[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n",func[0],func[1],func[2],func[3],func[4],func[5],func[6],func[7],func[8],func[9],func[10],func[11]];
    text = [dateString stringByAppendingString:text];
    
    _Log_TextView.text=[_Log_TextView.text stringByAppendingString:text];
    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
    NSLog(@"Byte message :%@\n",data);
    return data;
}


#pragma mark - DELEGATES

-(void)textFieldDidEndEditing:(UITextField *)textField{
    
    if(textField==_DeviceID_TextField)
    {
        if([_DeviceID_TextField.text intValue]>255)
        {
            _DeviceID_TextField.text = @"255";
        }
        else if ([_DeviceID_TextField.text isEqual:@""] | [_DeviceID_TextField.text isEqual:@"0"])
        {
            _DeviceID_TextField.text = @"1";
        }
    }
    else if (textField==_Adress_TextField)
    {
        if([_Command_Button.titleLabel.text isEqual:@"3"])
        {
            if(([_Adress_TextField.text intValue]+[_Value_TextField.text intValue])>65535)
            {
                UInt16 val=65535-[_Value_TextField.text intValue];
                _Adress_TextField.text =[NSString stringWithFormat:@"%d",val];
            }
        }
        else
        {
            if ([_Adress_TextField.text intValue]>65535)
            {
                _Adress_TextField.text = @"65535";
            }
            
        }
        if ([_Adress_TextField.text isEqual:@""])
        {
            _Adress_TextField.text = @"0";
        }
    }
    else if (textField==_Value_TextField)
    {
        if([_Command_Button.titleLabel.text isEqual:@"3"])
        {
            if ([_Value_TextField.text isEqual:@"0"])
            {
                _Value_TextField.text=@"1";
            }
            else if(([_Adress_TextField.text intValue]+[_Value_TextField.text intValue])>65535)
            {
                UInt16 val=65535-[_Adress_TextField.text intValue];
                _Value_TextField.text =[NSString stringWithFormat:@"%d",val];
            }
        }
        else
        {
            if ([_Value_TextField.text intValue]>65535)
            {
                _Value_TextField.text = @"65535";
            }
        }
        if ([_Value_TextField.text isEqual:@""])
        {
            _Value_TextField.text = @"0";
        }
    }
    else if (textField==_Port_TextField)
    {
        if ([_Port_TextField.text intValue]>65535)
        {
            _Port_TextField.text=@"65535";
        }
        else if ([_Port_TextField.text isEqual:@""])
        {
            _Port_TextField.text = @"0";
        }
    }
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(![string intValue] && ![string isEqualToString:@""] && ![string isEqualToString:@"0"]) { return NO; } else { return YES; }
}



@end
