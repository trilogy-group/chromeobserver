//
//  ApplicationObserver.m
//  chromeobserver
//
//  Created by Raul Guerrero on 10/07/23.
//

#import "ApplicationObserver.h"

static void windowCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    ApplicationObserver *appObserver = (__bridge ApplicationObserver *)refcon;
    AXUIElementRef chromeElement = appObserver.chromeElement;
    AXUIElementRef windowElement = NULL;
    AXUIElementCopyAttributeValue(chromeElement, (__bridge CFStringRef)NSAccessibilityFocusedWindowAttribute, (CFTypeRef *)&windowElement);
    NSString *value = NULL;
    AXUIElementCopyAttributeValue(windowElement, (__bridge CFStringRef)NSAccessibilityTitleAttribute, (void *)&value);
    appObserver.capturedTitle = value;
    [appObserver findToolbarInGroup:windowElement];
}

@implementation ApplicationObserver

- (void)applicationDidActivate:(NSNotification *)notification {
    NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    if ([[app localizedName] isEqualToString:@"Google Chrome"]) {
        // add observer
        pid_t pid = [app processIdentifier];
        self.chromeElement = AXUIElementCreateApplication(pid);

        // Create AXObservers for the application windows and tabs.
        AXObserverCreate(pid, windowCallback, &_windowObserver);
        AXObserverAddNotification(self.windowObserver, self.chromeElement, (__bridge CFStringRef)NSAccessibilityFocusedUIElementChangedNotification, (__bridge_retained void *)self);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(self.windowObserver), kCFRunLoopDefaultMode);
    } else {
        // remove observer
        AXObserverRemoveNotification(self.windowObserver, self.chromeElement, (__bridge CFStringRef)NSAccessibilityFocusedUIElementChangedNotification);
        self.chromeElement = nil;
        self.windowObserver = nil;
        self.capturedURL = nil;
    }
}

- (void)findToolbarInGroup:(AXUIElementRef)element {
    // Check if the element is an AXGroup or an AXToolbar
    CFStringRef role = NULL;
    AXUIElementCopyAttributeValue(element, kAXRoleAttribute, (CFTypeRef *)&role);
    
    if (role) {
        if (CFStringCompare(role, kAXToolbarRole, 0) == kCFCompareEqualTo) {
            // Found the toolbar, now find the next group with the AXTextField
            [self findTextFieldInToolbar:element];
            CFRelease(role);
            return;
        } else if (CFStringCompare(role, kAXGroupRole, 0) == kCFCompareEqualTo) {
            //NSLog(@"Found an AXGroup");
        }
        CFRelease(role);
    }

    // Recursively search in children
    CFArrayRef children = NULL;
    AXError error = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, (CFTypeRef *)&children);
    
    if (error == kAXErrorSuccess && children) {
        CFIndex count = CFArrayGetCount(children);
        for (CFIndex i = 0; i < count; i++) {
            AXUIElementRef childElement = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
            [self findToolbarInGroup:childElement];
        }
        CFRelease(children);
    }
}

- (void)findTextFieldInToolbar:(AXUIElementRef)element {
    // Check if the element is an AXGroup or an AXTextField
    CFStringRef role = NULL;
    AXUIElementCopyAttributeValue(element, kAXRoleAttribute, (CFTypeRef *)&role);
    
    if (role) {
        if (CFStringCompare(role, kAXTextFieldRole, 0) == kCFCompareEqualTo) {
            // Found a text field, the omnibox is usually a text field
            CFTypeRef value;
            AXUIElementCopyAttributeValue(element, kAXValueAttribute, &value);
            if (value) {
                self.capturedURL = [CFBridgingRelease(value) copy];
                [self getURLTriggered];
            }
            CFRelease(role);
            return;
        } else if (CFStringCompare(role, kAXGroupRole, 0) == kCFCompareEqualTo) {
            //NSLog(@"Found an AXGroup");
        }
        CFRelease(role);
    }

    // Recursively search in children
    CFArrayRef children = NULL;
    AXError error = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, (CFTypeRef *)&children);
    
    if (error == kAXErrorSuccess && children) {
        CFIndex count = CFArrayGetCount(children);
        for (CFIndex i = 0; i < count; i++) {
            AXUIElementRef childElement = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
            [self findTextFieldInToolbar:childElement];
        }
        CFRelease(children);
    }
}

- (void)getURLTriggered {
    // this is called once an UIElement even was triggered and a URL was obtained
    NSLog(@"Tab title: %@", self.capturedTitle);
    NSLog(@"Omnibox text: %@", self.capturedURL);
}

- (instancetype)init {
    self = [super init];
    self.windowObserver = nil;
    self.chromeElement = nil;
    self.capturedURL = nil;
    if (self) {
        // enable app notification
        NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
        [notificationCenter addObserver:self selector:@selector(applicationDidActivate:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    }
    return self;
}

@end
