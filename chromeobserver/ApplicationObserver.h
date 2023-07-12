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

@property (nonatomic) AXObserverRef windowObserver;
@property (nonatomic) AXUIElementRef chromeElement;
@property (nonatomic) NSString* capturedURL;

- (void)applicationDidActivate:(NSNotification *)notification;
- (void)findToolbarInGroup:(AXUIElementRef)element;
- (void)findTextFieldInToolbar:(AXUIElementRef)element;
- (NSString*)getURLTriggered;
- (instancetype)init;

@end

#endif /* ApplicationObserver_h */
