//
//  ClientThread.h
//  TCP ModBus
//
//  Created by Admin on 27.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ClientThread : NSThread <NSStreamDelegate>
{
@private
    CFReadStreamRef ReadStream;
    CFWriteStreamRef WriteStream;
    
    NSInputStream *InputStream;
    NSOutputStream *OutputStream;
}

-(void)initialyzeConnection:(NSString*)ip_adress :(UInt16)port :(UINavigationItem*)NavigationBar :(UITabBar*)Bar :(UIButton*)ConnectButton :(UIButton*)DisconnectButton :(UIButton*)SendButton :(UITextField*)DeviceID_TextField :(UITextView*)LogView :(UITableView*)SlaveTable :(UInt16*)RegistersValue :(BOOL)master_slave;/// можно было вместсо этого сам view передать и задать ему свойства, а не переменные

-(void)WriteData :(NSData*)DataSend;
-(void)CloseConnection;

@end
