//
//  GraphHelper.m
//  MacApp
//
//  Created by White on 2019/6/14.
//  Copyright © 2019 Whites. All rights reserved.
//

#import "GraphHelper.h"
#import "cgraph.h"
#import "gvc.h"

@implementation GraphHelper

+ (NSString *)createPNGWithRegularExpression: (NSString *)regularExpression error: (NSError * _Nullable __autoreleasing *)error {
    RegSwift *regSwift = [[RegSwift alloc] initWithPattern:regularExpression error:error];
    if (*error) { return nil; }
    id<GraphNode> headNode = [regSwift getNodeHead];
    NSString *path = [[[self alloc] init] p_createPNGWithHeadNode:headNode];
    return path;
}

- (NSString *)p_createPNGWithHeadNode: (id<GraphNode>)headNode {
    NSURL *tempFolder = [NSFileManager.defaultManager temporaryDirectory];
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *uuid = (__bridge NSString *)string;
    NSString *path = [[tempFolder URLByAppendingPathComponent:uuid] path];
    [self createPNGAtPath:path headNode:headNode];
    return path;
}

- (void)createPNGAtPath: (NSString *)path headNode: (id<GraphNode>)headNode {
    Agraph_t *g;
    g = agopen("G", Agdirected, NULL);
    agattr(g, AGNODE, "shape", "circle");
    agattr(g, AGRAPH, "rankdir", "LR");
    agattr(g, AGEDGE, "label", "temp");
    [self addNodesFor:g withHeadNode:headNode];
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

@end
