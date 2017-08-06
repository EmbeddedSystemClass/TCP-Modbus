//
//  SlaveClientController.m
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import "SlaveClientController.h"

@interface SlaveClientController ()

@end

@implementation SlaveClientController
{
    IBOutlet UINavigationItem *NavigationBar;
    
    IBOutlet UITextField *ip_TextField;
    IBOutlet UITextField *port_TextField;
    IBOutlet UITextField *DeviceID_TextField;
    
    IBOutlet UIButton *Connect_Button;
    IBOutlet UIButton *Disconnect_Button;
    
    IBOutlet UITableView *Registrs_TableView;
    IBOutlet UITextView *Log_TextView;
    
    IBOutlet UIView *Inf_View;
    IBOutlet UILabel *Version_Label;
    
    ClientThread *Client_Thread;
    
    NSInteger cell_num;
    UInt16 Registr_Value[65535];
    UITextField *activeTextField;
    UInt8 visible_registr;
    char func[65535]; //отправляемый пакет
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    for(int i=0;i<16;i++)
        Registr_Value[i]=0;
    
    cell_num = 65535;
    port_TextField.delegate=self;
    DeviceID_TextField.delegate=self;
    Registrs_TableView.delegate=self;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    ip_TextField.text = [userDefaults objectForKey:@"IP"];
    port_TextField.text = [userDefaults objectForKey:@"Port_Client"];
    DeviceID_TextField.text = [userDefaults objectForKey:@"DeviceID"];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    Version_Label.text=[NSString stringWithFormat:@"Version: %@",version];
    
    [self readData];
}


-(void)viewDidAppear:(BOOL)animated{
    [Registrs_TableView reloadData];
    Disconnect_Button.hidden=YES;
    Inf_View.hidden=YES;
}

-(void)viewDidDisappear:(BOOL)animated{
    Inf_View.hidden=YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)ConnectButton_Action:(id)sender {
    Connect_Button.enabled=NO;
    self.tabBarController.tabBar.userInteractionEnabled=NO;
    NavigationBar.rightBarButtonItem.enabled=NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:ip_TextField.text forKey:@"IP"];
    [userDefaults setObject:port_TextField.text forKey:@"Port_Client"];
    [userDefaults setObject:DeviceID_TextField.text forKey:@"DeviceID"];
    
    Client_Thread=[[ClientThread alloc]init];
    [Client_Thread initialyzeConnection:ip_TextField.text :[port_TextField.text intValue] :NavigationBar :self.tabBarController.tabBar :Connect_Button :Disconnect_Button :NULL :DeviceID_TextField :Log_TextView :Registrs_TableView :Registr_Value :0];
}


- (IBAction)DisconnectButton_Action:(id)sender {
    [Client_Thread CloseConnection];
}


- (IBAction)ClearButton_Action:(id)sender {
    Log_TextView.text=@"";
}

- (IBAction)InformButton_Action:(id)sender {
    Inf_View.hidden=NO;
}

- (IBAction)Inf_Button_Action:(id)sender {
    Inf_View.hidden=YES;
}

- (IBAction)TouchView_Action:(id)sender {
    [ip_TextField resignFirstResponder];
    [port_TextField resignFirstResponder];
    [DeviceID_TextField resignFirstResponder];
    [activeTextField resignFirstResponder];
}

#pragma mark - DELEGATES

//TableView delegate
//возвращает число ячеек таблицы
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   return cell_num;}

// возвращает указатель на ячейку которая появляется на экране, заполняет эту ячейку
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Create cell");
    static NSString *const CellID=@"Cell";
    ClientRegistrCell *cell=[tableView dequeueReusableCellWithIdentifier:CellID];
    cell.CellLabel.text=[NSString stringWithFormat:@"Registr %ld",(long)indexPath.row];
    cell.CellTextField.text=[NSString stringWithFormat:@"%d",Registr_Value[indexPath.row]];
    
    cell.CellTextField.delegate=self;//установка делегата для TextField в создаваемой ячейке
    cell.CellTextField.returnKeyType = UIReturnKeyDone;// замена кнопки return на done
    
    
    return cell;
}


///// TextField Delegates
//Начало редактирования, указатель активного textfield
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    NSLog(@"Begin editing");
    activeTextField=textField;
}

//действие (сохранение) по завершению изменения textField
-(void)textFieldDidEndEditing:(UITextField *)textField{
    
    NSLog(@"End editing");
    if (textField!=port_TextField & textField!=DeviceID_TextField)
    {
        UILabel *label = (UILabel*)[textField.superview viewWithTag:100];
        NSLog(@"%@",label);
        NSString *labelString = label.text;
        const char *ch_reg_num=[labelString UTF8String];
        
        NSUInteger reg_num=0;
        for (int i=8;i<labelString.length;i++)
            reg_num =(ch_reg_num[i]-48)*pow(10,labelString.length-i-1)+reg_num;//адрес регистра из label в cell
        
        UInt64 value =[textField.text intValue];
        
        Registr_Value[reg_num]=[textField.text intValue];
        if (value>65535)
        {
            value=65535;
            Registr_Value[reg_num]=value;
            [Registrs_TableView reloadData];
        }
        
        [self saveNewData:reg_num :value];
        NSLog(@"%d",(int)reg_num);
        NSLog(@"reg[%d]=%d",(int)reg_num,Registr_Value[reg_num]);
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
    else if (textField==DeviceID_TextField)
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
}

//убрать клавиатуру кнопкой return
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(![string intValue] && ![string isEqualToString:@""] && ![string isEqualToString:@"0"]) { return NO; } else { return YES; }
}

//Scrolls Delegate////////
//убрать клавиатуру и вызвать делегат TextField окончания редактирования, при скроле
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [activeTextField resignFirstResponder];
}

//CORE DATA/////////////////////
#pragma mark - Core Data

-(NSManagedObjectContext *)managedObjectContext{
    NSManagedObjectContext *context=nil;
    id delegate =[[UIApplication sharedApplication] delegate];
    if([delegate performSelector:@selector(managedObjectContext)])
    {
        context = [delegate managedObjectContext];
    }
    return context;
}



-(void)readData{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Registers"];
    
    NSMutableArray *FuncArray=[[context executeFetchRequest:fetchRequest error:nil]mutableCopy];
    
    NSEnumerator *it = [FuncArray objectEnumerator];
    while ((FuncArray = [it nextObject]) != nil)
    {
        Registr_Value[[[FuncArray valueForKey:@"ident"] integerValue]]=[[FuncArray valueForKey:@"value"] integerValue];
    }
}


-(void)saveNewData :(int16_t)ident :(int16_t)value{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Registers" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSNumber *ide = [NSNumber numberWithInt:ident];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ident == %@",ide];
    [request setPredicate:predicate];
    
    NSManagedObject *obj = [[context executeFetchRequest:request error:nil] firstObject];
    
    
    if ([[context executeFetchRequest:request error:nil] firstObject]!=NULL)
    {
        if (value!=0)
        {
            NSNumber *val = [NSNumber numberWithInt:value];
            [obj setValue:val forKey:@"value"];
        }
        else {
            [context deleteObject:obj];
        }
    }
    else {
        if (value!=0){
            obj = [NSEntityDescription insertNewObjectForEntityForName:@"Registers" inManagedObjectContext:context];
            
            NSNumber *val = [NSNumber numberWithInt:value];
            NSNumber *ide = [NSNumber numberWithInt:ident];
            
            [obj setValue:val forKey:@"value"];
            [obj setValue:ide forKey:@"ident"];
            
            NSError *error = nil;
            if(![context save:&error]){
                NSLog(@"Value save error: %@ %@", error, [error localizedDescription]);
            }
        }
    }
    
    //save changes
    NSError *error=nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error localizedDescription]);
    }
}


@end
