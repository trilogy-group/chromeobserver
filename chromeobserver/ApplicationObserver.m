//
//  ApplicationObserver.m
//  chromeobserver
//
//  Created by Raul Guerrero on 10/07/23.
//

#import "ApplicationObserver.h"

static void findTextFieldInToolbar(AXUIElementRef element) {
    // Check if the element is an AXGroup or an AXTextField
    CFStringRef role = NULL;
    AXUIElementCopyAttributeValue(element, kAXRoleAttribute, (CFTypeRef *)&role);
    
    if (role) {
        if (CFStringCompare(role, kAXTextFieldRole, 0) == kCFCompareEqualTo) {
            // Found the text field.
            //NSLog(@"Found an AXTextField");
            // The omnibox is usually a text field
            CFTypeRef value;
            AXUIElementCopyAttributeValue(element, kAXValueAttribute, &value);
            if (value) {
                NSLog(@"Omnibox text: %@", value);
                CFRelease(value);
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
            findTextFieldInToolbar(childElement);
        }
        CFRelease(children);
    }
}

static void findToolbarInGroup(AXUIElementRef element) {
    // Check if the element is an AXGroup or an AXToolbar
    CFStringRef role = NULL;
    AXUIElementCopyAttributeValue(element, kAXRoleAttribute, (CFTypeRef *)&role);
    
    if (role) {
        if (CFStringCompare(role, kAXToolbarRole, 0) == kCFCompareEqualTo) {
            // Found the toolbar.
            //NSLog(@"Found an AXToolbar");
            //now find the next group with the AXTextField
            findTextFieldInToolbar(element);
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
            findToolbarInGroup(childElement);
        }
        CFRelease(children);
    }
}

static void windowCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    AXUIElementRef chromeElement = (AXUIElementRef)refcon;
    AXUIElementRef windowElement = NULL;
    AXUIElementCopyAttributeValue(chromeElement, (__bridge CFStringRef)NSAccessibilityFocusedWindowAttribute, (CFTypeRef *)&windowElement);
    NSString *value = NULL;
    AXUIElementCopyAttributeValue(windowElement, (__bridge CFStringRef)NSAccessibilityTitleAttribute, (void *)&value);
    findToolbarInGroup(windowElement);
}

@implementation ApplicationObserver

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.google.Chrome"];
        NSRunningApplication *chromeApp = runningApplications.firstObject;
        if (!chromeApp) {
            return nil;
        }

        pid_t pid = [chromeApp processIdentifier];
        AXUIElementRef chromeElement = AXUIElementCreateApplication(pid);

        // Create AXObservers for the application windows and tabs.
        AXObserverCreate(pid, windowCallback, &_windowObserver);

        AXObserverAddNotification(self.windowObserver, chromeElement, (__bridge CFStringRef)NSAccessibilityFocusedUIElementChangedNotification, (void *)chromeElement);

        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(self.windowObserver), kCFRunLoopDefaultMode);
    }
    return self;
}

@end
