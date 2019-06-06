//
//  AppDelegate.m
//  TmpMacApp
//
//  Created by White on 2019/6/6.
//  Copyright © 2019 Whites. All rights reserved.
//

#import "AppDelegate.h"
#import "gvc.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    gvContext();
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
