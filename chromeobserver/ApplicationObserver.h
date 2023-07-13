//
//  ApplicationObserver.h
//  chromeobserver
//
//  Created by Raul Guerrero on 10/07/23.
//

#ifndef ApplicationObserver_h
#define ApplicationObserver_h

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@interface ApplicationObserver : NSObject

@property (nonatomic) NSNotificationCenter* notificationCenter;
@property (nonatomic) AXObserverRef windowObserver;
@property (nonatomic) AXUIElementRef chromeElement;
@property (nonatomic) NSString* capturedURL;
@property (nonatomic) NSString* capturedTitle;

- (void)applicationDidActivate:(NSNotification *)notification;
- (void)findToolbarInGroup:(AXUIElementRef)element;
- (void)findTextFieldInToolbar:(AXUIElementRef)element;
- (void)getURLTriggered;
- (instancetype)init;
- (void)stop;

@end

#endif /* ApplicationObserver_h */
