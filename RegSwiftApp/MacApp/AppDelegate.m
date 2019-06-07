//
//  AppDelegate.m
//  TmpMacApp
//
//  Created by White on 2019/6/6.
//  Copyright © 2019 Whites. All rights reserved.
//

#import "AppDelegate.h"
#import "cgraph.h"
#import <RegExSwift/RegExSwift-Swift.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSError *error = nil;
    
    
    Agraph_t *g;
    g = agopen("G", Agdirected, NULL);
    
    Agnode_t *firstNode;
    firstNode = agnode(g, "NodeA", TRUE);
    
    Agnode_t *secondNode;
    secondNode = agnode(g, "NodeB", TRUE);
    
    Agedge_t *edge_A_B = agedge(g, firstNode, secondNode, "bridge", TRUE);
    
    agattr(g, AGNODE, "shape", "box");
    
    agwrite(g, stdout);
    agclose(g);
    
//    agsafeset(<#void *obj#>, <#char *name#>, <#char *value#>, <#char *def#>)
    
    NSLog(@"1");
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
