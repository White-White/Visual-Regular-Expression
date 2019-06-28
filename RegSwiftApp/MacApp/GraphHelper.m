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
#import "gvplugin.h"

@implementation GraphHelper

+ (NSString *)createPNGWithRegularExpression: (NSString *)regularExpression error: (NSError * _Nullable __autoreleasing *)error {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *librariesDirURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Frameworks/" isDirectory:YES];
        setenv("GVBINDIR", (char*)[[librariesDirURL path] UTF8String], 1);
    });
    
    [RegSwift reset];
    RegSwift *regSwift = [[RegSwift alloc] initWithPattern:regularExpression error:error];
    if (*error) { return nil; }
    id<GraphNode> headNode = [regSwift getStartNode];
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
    NSString *fromNodeName = [headNode nodeName];
    Agnode_t *fromNode;
    fromNode = agnode(g, (char *)[fromNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
    
    NSArray <id<GraphNode>>* normalNextNodes = [headNode normalNextNodes];
    for (id<GraphNode> oneNextNode in normalNextNodes) {
        NSString *toNodeName = [oneNextNode nodeName];
        NSString *pathDesp = [headNode pathDespForNextNode:oneNextNode];
#if DEBUG
        NSLog(@"从 %@ 连接到 %@，可接受的输入为%@", fromNodeName, toNodeName, pathDesp);
#endif
        Agnode_t *secondNode;
        secondNode = agnode(g, (char *)[toNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agedge_t *edge_A_B = agedge(g, fromNode, secondNode, "bridge", TRUE);
        agset(edge_A_B, "label", (char *)[pathDesp cStringUsingEncoding:NSUTF8StringEncoding]);
        
        //recursive
        [self addNodesFor:g withHeadNode:oneNextNode];
    }
    
    for (id<GraphNode> extraNextNode in [headNode extraNextNodes]) {
        NSString *toNodeName = [extraNextNode nodeName];
        NSString *pathDesp = [headNode pathDespForNextNode:extraNextNode];
#if DEBUG
        NSLog(@"从 %@ 连接到 %@，可接受的输入为%@", fromNodeName, toNodeName, pathDesp);
#endif
        Agnode_t *secondNode;
        secondNode = agnode(g, (char *)[toNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agedge_t *edge_A_B = agedge(g, fromNode, secondNode, "bridge", TRUE);
        agset(edge_A_B, "label", (char *)[pathDesp cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    agsafeset(fromNode, "style", "filled", "solid");
    agsafeset(fromNode, "fillcolor", (char *)[[headNode nodeFillColorHex] cStringUsingEncoding:NSUTF8StringEncoding], "lightgrey");
}

@end
