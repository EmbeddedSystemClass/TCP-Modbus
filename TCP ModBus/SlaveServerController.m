//
//  SlaveServerController.m
//  TCP ModBus
//
//  Created by Admin on 26.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import "SlaveServerController.h"

@interface SlaveServerController ()

@end

@implementation SlaveServerController
{
    ServerThread *Server_Thread;
    IBOutlet UILabel *Version_Label;
    
    NSInteger cell_num;
    UInt16 Registr_Value[65535];
    UITextField *activeTextField;
    UInt8 visible_registr;
    char func[65535]; //отправляемый пакет
    
    NSMutableArray *FuncArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _Inf_View.hidden=YES;
    
    for(int i=0;i<16;i++)
        Registr_Value[i]=0;
    
    _RegistrsValuePointer=Registr_Value;
    
    _Stop_Button.enabled=NO;
    _Port_TextField.delegate=self;
    _DeviceID_TextField.delegate=self;
    _Registrs_TableView.delegate=self;
    cell_num=65535;
    
    Server_Thread=[[ServerThread alloc]init];
    NSString *string=[Server_Thread getIPAddress];
    self.ip_Label.text = string;
    
    if ([string isEqualToString:@"Need Wi-Fi connection"])
        _Listen_Button.enabled=NO;
    
    _Back_Button = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 60.0f, 30.0f)];
    [_Back_Button setTitle:@"Client" forState:UIControlStateNormal];
    [_Back_Button setTitleColor:[UIColor colorWithRed:0.12 green:0.53 blue:0.90 alpha:1.0] forState:UIControlStateNormal];
    [_Back_Button addTarget:self action:@selector(popBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_Back_Button];
    self.navigationItem.leftBarButtonItem = backButtonItem;
    ////////////////////
    
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _Port_TextField.text = [userDefaults objectForKey:@"Port_Server"];
    _DeviceID_TextField.text = [userDefaults objectForKey:@"DeviceID"];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    Version_Label.text=[NSString stringWithFormat:@"Version: %@",version];
    
    [self readData];
    
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
    
    [Server_Thread StartListen:self :0];
}

- (IBAction)StopButton_Action:(id)sender {
    [Server_Thread StopListen];
    //Server_Thread=NULL;
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
    [activeTextField resignFirstResponder];
}






//TableView delegate
//возвращает число ячеек таблицы
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{   return cell_num;}

// возвращает указатель на ячейку которая появляется на экране, заполняет эту ячейку
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Create cell");
    static NSString *const CellID=@"Cell";
    ServerRegistrCell *cell=[tableView dequeueReusableCellWithIdentifier:CellID];
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
    
    if (textField!=_Port_TextField & textField!=_DeviceID_TextField)
    {
        NSLog(@"End editing");
        UILabel *label = (UILabel*)[textField.superview viewWithTag:100];
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
            [_Registrs_TableView reloadData];
        }
        
        [self saveNewData:reg_num :value];
        
        NSLog(@"reg[%lu]=%d",(unsigned long)reg_num,Registr_Value[reg_num]);
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
    else if (textField==_DeviceID_TextField)
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
    
    FuncArray=[[context executeFetchRequest:fetchRequest error:nil]mutableCopy];
    
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
