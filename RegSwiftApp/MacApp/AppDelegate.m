//
//  AppDelegate.m
//  TmpMacApp
//
//  Created by White on 2019/6/6.
//  Copyright © 2019 Whites. All rights reserved.
//

#import "AppDelegate.h"
#import "cgraph.h"
#import "gvc.h"
#import <RegExSwift/RegExSwift-Swift.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    RegSwift *regSwift = [[RegSwift alloc] initWithPattern:@"a|b*cdq" error:nil];
    id<GraphNode> headNode = [regSwift getNodeHead];
    [self createPNGAtPath:@"/Users/white/Desktop/tmp.png" headNode:headNode];
}

- (void)createPNGAtPath: (NSString *)path headNode: (id<GraphNode>)headHead {
    Agraph_t *g;
    g = agopen("G", Agdirected, NULL);
    agattr(g, AGNODE, "shape", "circle");
    agattr(g, AGRAPH, "rankdir", "LR");
    agattr(g, AGEDGE, "label", "temp");
    [self addNodesFor:g withHeadNode:headHead];
#if DEBUG
    NSLog(@"图输出如下：\n");
    agwrite(g, stdout);
    NSLog(@"\n");
#endif
    GVC_t *gvc = gvContext();
    gvLayout(gvc, g, "dot");
    FILE *thePNG = fopen([path cStringUsingEncoding:NSUTF8StringEncoding], "w+");
    gvRender(gvc, g, "png", thePNG);
    fclose(thePNG);
    gvFreeLayout(gvc, g);
    agclose(g);
}

- (void)addNodesFor: (graph_t *)g withHeadNode: (id<GraphNode>)headNode {
    NSArray <id<GraphNode>>* nextNodes = [headNode nextNodes];
    
    for (id<GraphNode> oneNextNode in nextNodes) {
        Agnode_t *firstNode;
        firstNode = agnode(g, (char *)[[headNode nodeName] cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agnode_t *secondNode;
        secondNode = agnode(g, (char *)[[oneNextNode nodeName] cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agedge_t *edge_A_B = agedge(g, firstNode, secondNode, "bridge", TRUE);
        agset(edge_A_B, "label", (char *)[headNode.inputCharactersDescription cStringUsingEncoding:NSUTF8StringEncoding]);
        
        //recursive
        [self addNodesFor:g withHeadNode:oneNextNode];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
