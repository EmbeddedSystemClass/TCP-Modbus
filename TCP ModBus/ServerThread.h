//
//  ServerThread.h
//  TCP ModBus
//
//  Created by Admin on 27.07.16.
//  Copyright © 2016 Ivan Elyoskin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "MasterServerController.h"
#import "SlaveServerController.h"

//#import <CoreFoundation/CoreFoundation.h>
//#import <CFNetwork/CFNetwork.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <ifaddrs.h>//чтобы ip-шник был
#include <arpa/inet.h>//чтобы ip-шник был

@interface ServerThread : NSThread <NSStreamDelegate>
/*{
@private
    CFReadStreamRef ReadStream;
    CFWriteStreamRef WriteStream;
    
    NSInputStream *InputStream;
    NSOutputStream *OutputStream;
}*/

-(void)StartListen:(UIViewController*)ViewController :(BOOL)master_slave;
-(void)SendData :(NSData*)DataSend;
-(void)StopListen;

- (NSString *)getIPAddress;

@end
