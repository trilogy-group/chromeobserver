#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "ApplicationObserver.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ApplicationObserver *observer = [[ApplicationObserver alloc] init];
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}
