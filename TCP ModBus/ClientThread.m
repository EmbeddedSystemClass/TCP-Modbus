//
//  ClientThread.m
//  TCP ModBus
//
//  Created by Admin on 27.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//


#import "ClientThread.h"

@implementation ClientThread
{
    //для работы с отобржениями
    UINavigationItem *LocalNavigationBar;
    UITabBar *Tab;
    UIButton *LocalConnectButton;
    UIButton *LocalDisconnectButton;
    UIButton *LocalSendButton;
    UITextField *LocalDeviceidTextField;
    UITextView *LocalLogView;
    UITableView *LocalSlaveTable;
    UInt16* LocalRegistrsValue;
    BOOL Local_m_s;//m-1, s-0
    
    char func[256];
    UInt16 cell_num;
    
    NSMutableArray *FuncArray;
}

#pragma mark - FUNCTIONS
//установка соединения
-(void)initialyzeConnection:(NSString*)ip_adress :(UInt16)port :(UINavigationItem*)NavigationBar :(UITabBar*)TabBar :(UIButton*)ConnectButton :(UIButton*)DisconnectButton :(UIButton*)SendButton :(UITextField*)DeviceID_TextField :(UITextView*)LogView :(UITableView*)SlaveTable :(UInt16*)RegistersValue :(BOOL)master_slave{
    
    NSLog(@"ip = %@ \n port=%d ",ip_adress,port);
    
    cell_num=256;
    LocalNavigationBar=NavigationBar;
    Tab=TabBar;
    LocalConnectButton=ConnectButton;
    LocalDisconnectButton=DisconnectButton;
    LocalSendButton=SendButton;
    LocalDeviceidTextField=DeviceID_TextField;
    LocalLogView=LogView;
    LocalSlaveTable=SlaveTable;
    LocalRegistrsValue=RegistersValue;
    Local_m_s=master_slave;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip_adress, port, &ReadStream, &WriteStream);   // подключает к нужному адресу
    InputStream = (__bridge NSInputStream *)ReadStream;
    OutputStream = (__bridge NSOutputStream *)WriteStream;
    //Delegate потоков
    [InputStream setDelegate:self];
    [OutputStream setDelegate:self];
    //чтобы зациклить получение (отправление) вне заваисимости от наличия данных о Потоках чтения (записи)
    [InputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [OutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    //коннектимся
    [InputStream open];
    [OutputStream open];
}


-(void)ReadMasterData:(uint8_t*)data{
    
}


-(void)ReadSlaveData:(uint8_t*)buffer :(NSInteger)len{
    if (buffer[6]==[LocalDeviceidTextField.text intValue]) {
        
        NSString *text_to_view=@"";
        for (int i=0;i<len;i++)
            text_to_view=[text_to_view stringByAppendingString:[NSString stringWithFormat:@" 0x%x",buffer[i]]];
        
        NSLog(@"%@",text_to_view);
        text_to_view=[@"R:" stringByAppendingString:text_to_view];
        [self write_log:text_to_view];
        if ((buffer[8]*16*16+buffer[9])<cell_num)
        {
            //ответ записи
            if (buffer[7]==6)
            {
                NSUInteger msg_size=12;
                if((buffer[10]*16*16+buffer[11])<65535){
                    
                    LocalRegistrsValue[buffer[8]*16*16+buffer[9]]=buffer[10]*16*16+buffer[11];
                    [LocalSlaveTable reloadData];// обновление таблицы, новым значением
                    
                    [self getAnswer6:buffer[0] :buffer[1] :buffer[8] :buffer[9]];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [OutputStream write:[data bytes] maxLength:[data length]];
                }
                else{
                    NSUInteger msg_size=9;
                    [self write_log:@"Value to big for function 6"];
                    [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 3];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [OutputStream write:[data bytes] maxLength:[data length]];
                }
            }
            //ответ чтения
            else if(buffer[7]==3)
            {
                if(((buffer[8]*16*16+buffer[9])+(buffer[10]*16*16+buffer[11]))<cell_num)
                {
                    NSUInteger msg_size=9+(buffer[10]*16*16+buffer[11])*2;
                    [self getAnswer3:buffer[0] :buffer[1] :buffer[8] :buffer[9] :buffer[10] :buffer[11]];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [OutputStream write:[data bytes] maxLength:[data length]];
                }
                else{
                    NSUInteger msg_size=9;
                    [self write_log:@"Value to big for function 3"];
                    [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 3];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [OutputStream write:[data bytes] maxLength:[data length]];
                }
            }
            else{
                NSUInteger msg_size=9;
                [self write_log:@"Unknown command"];
                [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 1];
                NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                NSLog(@"Byte message :%@\n",data);
                [OutputStream write:[data bytes] maxLength:[data length]];
            }
        }
        else{
            NSUInteger msg_size=9;
            [self write_log:@"Adress to big"];
            [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 2];
            NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
            NSLog(@"Byte message :%@\n",data);
            [OutputStream write:[data bytes] maxLength:[data length]];
        }
    }
    else if(len==12 & buffer[2]==0 &  buffer[3]==0 & buffer[4]==0 & buffer[5]==6 )
    {
        [self write_log:@"Not this device"];
    }
    else
    {
        [self write_log:@"False message"];
    }
}

- (char*)getAnswer3 :(UInt8)idH :(UInt8)idL :(UInt8)AdressH :(UInt8)AdressL :(UInt8)ValueH :(UInt8)ValueL
{
    UInt16 reg_count=ValueH*16*16+ValueL;
    UInt16 adress=AdressH*16*16+AdressL;
    
    func[0] = (idH & 0xFF);
    func[1] = (idL & 0xFF);
    func[2] = 0;
    func[3] = 0;
    func[4] = 0;//число байт после HIGH
    func[5] = 3+reg_count*2;//число байт после LOW
    func[6] = [LocalDeviceidTextField.text intValue]; //DEVICE_ID
    func[7] = 3;
    func[8] = reg_count*2;
    
    NSString *text_to_view=@"";
    
    //PDU:
    for(int i=9;i<(9+reg_count*2);i=i+2){
        func[i]=(LocalRegistrsValue[adress] >> 8) & 0xFF;
        func[i+1]=LocalRegistrsValue[adress] & 0xFF;
        adress++;
        text_to_view=[text_to_view stringByAppendingString:[NSString stringWithFormat:@"0x%x 0x%x ",(func[i])&0xff,(func[i+1])&0xff]];
    }
    
    text_to_view=[[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x",func[0],func[1],func[2],func[3],func[4],func[5],func[6],func[7],func[8]] stringByAppendingString:text_to_view];
    NSLog(@"%@",text_to_view);
    [self write_log:text_to_view];
    
    return func;
}

- (char*)getAnswer6 :(UInt8)idH :(UInt8)idL :(UInt8)AdressH :(UInt8)AdressL
{
    func[0] = (idH & 0xFF);
    func[1] = (idL & 0xFF);
    func[2] = 0;
    func[3] = 0;
    func[4] = 0;//число байт после HIGH
    func[5] = 6;//число байт после LOW
    func[6] = [LocalDeviceidTextField.text intValue];; //DEVICE_ID
    func[7]=6;
    
    //PDU:
    func[8] = (AdressH & 0xFF);
    func[9] = (AdressL & 0xFF);
    func[10] = ((LocalRegistrsValue[AdressH*16*16+AdressL] >> 8) & 0xFF);
    func[11] = (LocalRegistrsValue[AdressH*16*16+AdressL] & 0xFF);
    
    [self saveNewData:func[8]*16*16+func[9] :func[10]*16*16+func[11]];
    
    NSString *text_to_view=[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n",func[0]&0xff,func[1]&0xff,func[2]&0xff,func[3]&0xff,func[4]&0xff,func[5]&0xff,func[6]&0xff,func[7]&0xff,(func[8]),(func[9])&0xff,(func[10])&0xff,(func[11])&0xff];
    NSLog(@"%@",text_to_view);
    [self write_log:text_to_view];
    
    return func;
}


-(void)Modbus_Error:(UInt8)idH :(UInt8)idL :(UInt8)Function :(UInt8)AdressH :(UInt8)AdressL :(UInt8)Error {
    func[0] = (idH & 0xFF);
    func[1] = (idL & 0xFF);
    func[2] = 0;
    func[3] = 0;
    func[4] = 0;//число байт после HIGH
    func[5] = 3;//число байт после LOW
    func[6] = [LocalDeviceidTextField.text intValue]; //DEVICE_ID
    func[7]=Function+0x80;
    func[8] = Error;

    
    NSString *text_to_view=[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n",func[0],func[1],func[2],func[3],func[4],func[5],func[6],func[7],func[8]];
    NSLog(@"%@",text_to_view);
    [self write_log:text_to_view];
}





-(void)WriteData :(NSData*)DataSend{
    [OutputStream write:[DataSend bytes] maxLength:[DataSend length]];
}


//отключаемся
-(void)CloseConnection{
    NSLog(@"Close");
    [InputStream close];
    [OutputStream close];
    [self DisconnectEvent];}


//обработка интерфеса при отключении
-(void)DisconnectEvent{
    Tab.userInteractionEnabled=YES;
    LocalSendButton.enabled = NO;
    LocalDisconnectButton.hidden = YES;
    LocalConnectButton.hidden = NO;
    LocalConnectButton.enabled=YES;
    LocalNavigationBar.rightBarButtonItem.enabled=YES;
}


-(void)write_log:(NSString*)text{
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"[HH:mm:ss] "];
    NSString *dateString = [formatter stringFromDate:now];
    text = [dateString stringByAppendingString:text];
    text = [text stringByAppendingString:@"\n"];
    LocalLogView.text=[LocalLogView.text stringByAppendingString:text];
    [LocalLogView scrollRangeToVisible:NSMakeRange(LocalLogView.text.length, 0)];
    [LocalLogView setScrollEnabled:NO];
    [LocalLogView setScrollEnabled:YES];
}


#pragma mark - DELEGATES
//события с соединением
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
           
            [self write_log:@"Connected!"];
            
            LocalSendButton.enabled = YES;
            LocalDisconnectButton.hidden = NO;
            LocalConnectButton.hidden = YES;
            break;
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"Input Bytes2");
            
            if (theStream == InputStream) {
                
                uint8_t buffer[1024];
                //int len;
                NSInteger len;
                
                while ([InputStream hasBytesAvailable]) {
                    len = [InputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        if (0 != buffer[6]) {
                            NSString *text_to_view=@"";
                            for (int i=0;i<len;i++)
                            {       text_to_view=[text_to_view stringByAppendingString:[NSString stringWithFormat:@" 0x%x",(buffer[i]&0xFF)]];
                                NSLog(@"%@",text_to_view);
                            }

                            text_to_view=[@"R:" stringByAppendingString:text_to_view];
                            text_to_view=[text_to_view stringByAppendingString:@"\n"];
                            [self write_log:text_to_view];
                            
                            if(Local_m_s)
                                [self ReadMasterData:buffer];
                            else
                                [self ReadSlaveData:buffer:len];
                        }
                        else
                            [self write_log:@"False input package!"];
                    }
                }
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"HasSpase Availiable\n!");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Error disconnect!\n");
            [self write_log:@"Error Disconnect!"];
            [self DisconnectEvent];
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Disconnected!(Off/Time out)");
            [self write_log:@"Disconected!(Off/Time out)"];
            [self DisconnectEvent];
            break;
            
        default:
            NSLog(@"Unknown event");
    }
}


//CORE DATA/////////////////////////////////
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
