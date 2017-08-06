//
//  ServerThread.m
//  TCP ModBus
//
//  Created by Admin on 27.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import "ServerThread.h"

@implementation ServerThread
{
    MasterServerController *MasterController;
    SlaveServerController *SlaveController;
    BOOL M_S; //M=1, S=0

    CFSocketRef myipv4cfsock;
    CFSocketNativeHandle socket_inController;
    
    char func[256];
    UInt16 cell_num;
    
    NSMutableArray *FuncArray;
}

//глобалки
NSInputStream *inputStream;
NSOutputStream *outputStream;
CFSocketNativeHandle socket_inController;
ServerThread *SelfDelegate;
//MasterServerController *MasterController;



#pragma mark METHODS

-(void)StartListen:(UIViewController*)ViewController :(BOOL)master_slave{
    SelfDelegate=self;
    M_S=master_slave;
    if (M_S){
        MasterController=(MasterServerController*)ViewController;
        MasterController.Listen_Button.enabled=NO;
        MasterController.Stop_Button.enabled=YES;
        MasterController.Port_TextField.enabled=NO;
        NSLog(@"M");
    }
    else{
        SlaveController=(SlaveServerController*)ViewController;
        SlaveController.Listen_Button.enabled=NO;
        SlaveController.Stop_Button.enabled=YES;
        MasterController.Port_TextField.enabled=NO;
        MasterController.DeviceID_TextField.enabled=NO;
        cell_num=256;
        NSLog(@"S");
    }
        
    myipv4cfsock = CFSocketCreate(kCFAllocatorDefault ,PF_INET ,SOCK_STREAM ,IPPROTO_TCP,
                                  kCFSocketAcceptCallBack, (CFSocketCallBack)SocketEvent, NULL);
    struct sockaddr_in sin;
    
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    if(M_S==1)
        sin.sin_port = htons([MasterController.Port_TextField.text intValue]);
    else
        sin.sin_port = htons([SlaveController.Port_TextField.text intValue]);
    sin.sin_addr.s_addr= INADDR_ANY;
        
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault ,(UInt8 *)&sin ,sizeof(sin));
        
    CFSocketError err;
    err = CFSocketSetAddress(myipv4cfsock, sincfd);
    if(err==0){
        NSLog(@"Success");
    }
    else if(err==-1){
        NSLog(@"Error");
        [self StopListen];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Listen error" message:@"Wait, or choose anoter port." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        if (M_S==1){
            [MasterController presentViewController:alert animated:YES completion:nil];
            [self DisconnectEvent];
        }
        else
        {
            [SlaveController presentViewController:alert animated:YES completion:nil];
            [self DisconnectEvent];
        }
        return;
        }
    else if(err==-2){
        NSLog(@"Timeout");
        return;
    }
        
    CFRelease(sincfd);
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault ,myipv4cfsock ,0);
    CFRunLoopAddSource(CFRunLoopGetCurrent() ,socketsource ,kCFRunLoopDefaultMode);
    CFRelease(socketsource);
    
    NSLog(@"Start listen");
    [self write_log:@"Start listen"];
        
    CFRunLoopRun();
    
    NSLog(@"Stop listennnnnn");
    //CFRelease(myipv4cfsock);????????
    
}

////////////
-(void)SendData :(NSData*)DataSend{
    [outputStream write:[DataSend bytes] maxLength:[DataSend length]];
}

/////////
-(void)StopListen{
    [self write_log:@"Stop listen"];
    [self DisconnectEvent];
    [inputStream close];
    [outputStream close];
    //close(socket_inController);
    CFSocketInvalidate(myipv4cfsock);
    CFRelease(myipv4cfsock);
    CFRunLoopStop(CFRunLoopGetCurrent());
}


#pragma mark - DELEGATES

void SocketEvent(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info){
    NSLog(@"event");
    switch (type) {
        case kCFSocketAcceptCallBack:
        {
            NSLog(@"Accept");
            CFReadStreamRef readStream;
            CFWriteStreamRef writeStream;
            socket_inController = *(CFSocketNativeHandle *) data;
            
            CFStreamCreatePairWithSocket(kCFAllocatorDefault, socket_inController, &readStream, &writeStream);
            
            if (!readStream || !writeStream) {
                close(socket_inController);
                NSLog(@"CFStreamCreatePairWithSocket() failed\n");
                return;
            }
            outputStream = (__bridge NSOutputStream*)writeStream;
            inputStream=(__bridge NSInputStream*)readStream;
            
            inputStream.delegate=SelfDelegate;
            outputStream.delegate=SelfDelegate;
            NSLog(@"");
            
            //чтобы зациклить получение (отправление) вне заваисимости от наличия данных о Потоках чтения (записи)
            [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            //коннектимся
            NSLog(@"open");
            [inputStream open];
            [outputStream open];
        }
            break;
            
            
        case kCFSocketConnectCallBack:
            NSLog(@"Connect");
            break;
        
        case kCFSocketNoCallBack:
            NSLog(@"NO call back");
            break;
            
        case kCFSocketDataCallBack:
            NSLog(@"Data call");
            break;
        
        case kCFSocketReadCallBack:
            NSLog(@"Read");
            break;
            
        case kCFSocketWriteCallBack:
            NSLog(@"Write");
            break;
            
        default:
            break;
    }
}


//события с соединением
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            
            [self write_log:@"Stream open!"];
            if(M_S==1){
                MasterController.Send_Button.enabled=YES;
                MasterController.Stop_Button.enabled=YES;
            }
            else{
                SlaveController.Stop_Button.enabled=YES;
            }
            break;
            
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"Input Bytes1");
            
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                //int len;
                NSInteger len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
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
                            
                            if(M_S)
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
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Disconnected!(Off/Time out)");
            [self write_log:@"Disconected!(Off/Time out)"];
            break;
            
        default:
            NSLog(@"Unknown event");
    }
}


#pragma mark FUCTIONS


-(void)ReadMasterData:(uint8_t*)data{
    
}


-(void)ReadSlaveData:(uint8_t*)buffer :(NSInteger)len{
    if (buffer[6]==[SlaveController.DeviceID_TextField.text intValue]) {
        
        NSString *text_to_view=@"";
        for (int i=0;i<len;i++)
            text_to_view=[text_to_view stringByAppendingString:[NSString stringWithFormat:@"0x%x ",(buffer[i]&0xFF)]];
        
        text_to_view=[@"R: " stringByAppendingString:text_to_view];
        [self write_log:text_to_view];
        
        if ((buffer[8]*16*16+buffer[9])<cell_num)
        {
            if (buffer[7]==6)
            {
                NSUInteger msg_size=12;
                if((buffer[10]*16*16+buffer[11])<=65535){
                    SlaveController.RegistrsValuePointer[buffer[8]*16*16+buffer[9]]=buffer[10]*16*16+buffer[11];
                    [SlaveController.Registrs_TableView reloadData];// обновление таблицы, новым значением
                    
                    [self getAnswer6:buffer[0] :buffer[1] :buffer[8] :buffer[9]];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [outputStream write:[data bytes] maxLength:[data length]];
                }
                else{
                    NSUInteger msg_size=9;
                    [self write_log:@"Value to big for function 6"];
                    [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 3];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [outputStream write:[data bytes] maxLength:[data length]];
                }
            }
            else if(buffer[7]==3)
            {
                if(((buffer[8]*16*16+buffer[9])+(buffer[10]*16*16+buffer[11]))<cell_num)
                {
                    NSUInteger msg_size=9+(buffer[10]*16*16+buffer[11])*2;
                    [self getAnswer3:buffer[0] :buffer[1] :buffer[8] :buffer[9] :buffer[10] :buffer[11]];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [outputStream write:[data bytes] maxLength:[data length]];
                }
                else{
                    NSUInteger msg_size=9;
                    [self write_log:@"Value to big for function 3"];
                    [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 3];
                    NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                    NSLog(@"Byte message :%@\n",data);
                    [outputStream write:[data bytes] maxLength:[data length]];
                }
            }
            else{
                NSUInteger msg_size=9;
                [self write_log:@"Unknown command"];
                [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 1];
                NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
                NSLog(@"Byte message :%@\n",data);
                [outputStream write:[data bytes] maxLength:[data length]];
            }
        }
        else{
            NSUInteger msg_size=9;
            [self write_log:@"Adress to big"];
            [self Modbus_Error:buffer[0] :buffer[1] :buffer[7] :buffer[8] :buffer[9]: 2];
            NSData *data = [NSData dataWithBytes:(const void *) func length:sizeof(char)*msg_size];
            NSLog(@"Byte message :%@\n",data);
            [outputStream write:[data bytes] maxLength:[data length]];
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
    func[6] = [SlaveController.DeviceID_TextField.text intValue]; //DEVICE_ID
    func[7] = 3;
    func[8] = reg_count*2;
    
    NSString *text_to_view=@"";
    
    //PDU:
    for(int i=9;i<(9+reg_count*2);i=i+2){
        func[i]=(SlaveController.RegistrsValuePointer[adress] >> 8) & 0xFF;
        func[i+1]=SlaveController.RegistrsValuePointer[adress] & 0xFF;
        adress++;
        text_to_view=[text_to_view stringByAppendingString:[NSString stringWithFormat:@"0x%x 0x%x ",(func[i]&0xFF),(func[i+1]&0xFF)]];
    }
    
    text_to_view=[[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x ",func[0],func[1],func[2],func[3],func[4],func[5],func[6],func[7],func[8]] stringByAppendingString:text_to_view];
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
    func[6] = [SlaveController.DeviceID_TextField.text intValue];; //DEVICE_ID
    func[7]=6;
    
    //PDU:
    func[8] = (AdressH & 0xFF);
    func[9] = (AdressL & 0xFF);
    func[10] = ((SlaveController.RegistrsValuePointer[AdressH*16*16+AdressL] >> 8) & 0xFF);
    func[11] = (SlaveController.RegistrsValuePointer[AdressH*16*16+AdressL] & 0xFF);
    
    [self saveNewData:func[8]*16*16+func[9] :func[10]*16*16+func[11]];
    
    NSString *text_to_view=[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n",(func[0]&0xFF),(func[1]&0xFF),(func[2]&0xFF),(func[3]&0xFF),(func[4]&0xFF),(func[5]&0xFF),(func[6]&0xFF),(func[7]&0xFF),(func[8]&0xFF),(func[9]&0xFF),(func[10]&0xFF),(func[11]&0xFF)];
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
    func[6] = [SlaveController.DeviceID_TextField.text intValue]; //DEVICE_ID
    func[7]=Function+0x80;
    func[8] = Error;
    
    
    NSString *text_to_view=[NSString stringWithFormat:@"S: 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n",func[0],func[1],func[2],func[3],func[4],func[5],func[6],func[7],func[8]];
    NSLog(@"%@",text_to_view);
    [self write_log:text_to_view];
}


//обработка интерфеса при отключении
-(void)DisconnectEvent{
    if(M_S==1){
        MasterController.tabBarController.tabBar.userInteractionEnabled=YES;
        MasterController.Send_Button.enabled=NO;
        MasterController.Listen_Button.enabled=YES;
        MasterController.Stop_Button.enabled=NO;
        MasterController.Back_Button.enabled=YES;
        MasterController.Port_TextField.enabled=YES;
    }
    else{
        SlaveController.tabBarController.tabBar.userInteractionEnabled=YES;
        SlaveController.Listen_Button.enabled=YES;
        SlaveController.Stop_Button.enabled=NO;
        SlaveController.Back_Button.enabled=YES;
        SlaveController.Port_TextField.enabled=YES;
        SlaveController.DeviceID_TextField.enabled=YES;
    }
}



///////////
-(void)write_log:(NSString*)text{
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"[HH:mm:ss] "];
    NSString *dateString = [formatter stringFromDate:now];
    text = [dateString stringByAppendingString:text];
    text = [text stringByAppendingString:@"\n"];
    if(M_S==1){
        MasterController.Log_TextView.text=[MasterController.Log_TextView.text stringByAppendingString:text];
        [MasterController.Log_TextView scrollRangeToVisible:NSMakeRange(MasterController.Log_TextView.text.length, 0)];
        [MasterController.Log_TextView setScrollEnabled:NO];
        [MasterController.Log_TextView setScrollEnabled:YES];
    }
    else{
        SlaveController.Log_TextView.text=[SlaveController.Log_TextView.text stringByAppendingString:text];
        [SlaveController.Log_TextView scrollRangeToVisible:NSMakeRange(SlaveController.Log_TextView.text.length, 0)];
        [SlaveController.Log_TextView setScrollEnabled:NO];
        [SlaveController.Log_TextView setScrollEnabled:YES];
    }
}


- (NSString *)getIPAddress {
    NSString *address = @"Need Wi-Fi connection";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}


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


