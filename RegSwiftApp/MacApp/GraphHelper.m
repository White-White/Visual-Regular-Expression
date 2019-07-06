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

@implementation GraphHelper {
    RegSwift *_regSwift;
}

- (instancetype)init {
    @throw @"Use initWithRegEx:error:";
}

- (instancetype)initWithRegEx:(NSString *)regEx error:(NSError *__autoreleasing  _Nullable *)error {
    self = [super init];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *librariesDirURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Frameworks/" isDirectory:YES];
        setenv("GVBINDIR", (char*)[[librariesDirURL path] UTF8String], 1);
    });
    
    _regSwift = [[RegSwift alloc] initWithPattern:regEx error:error];
    return self;
}

- (void)resetWithMatch:(NSString *)match {
    [_regSwift resetWithMatch:match];
}

- (NSImage *)createPNG {
    id<GraphNode> headNode = [_regSwift getStartNode];
    NSString *path = [self p_createPNGWithHeadNode:headNode];
    return [[NSImage alloc] initWithContentsOfFile:path];
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
    NSLog(@"Dot language representation is as follow：\n");
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
    Agnode_t *fromNode = agnode(g, (char *)[fromNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
    [self _addCommonAttriForNode:fromNode color:(char *)[[headNode nodeFillColorHex] cStringUsingEncoding:NSUTF8StringEncoding]];
    
    NSArray <id<GraphNode>>* normalNextNodes = [headNode normalNextNodes];
    for (id<GraphNode> oneNextNode in normalNextNodes) {
        NSString *toNodeName = [oneNextNode nodeName];
        NSString *pathDesp = [headNode pathDespForNextNode:oneNextNode];
        Agnode_t *secondNode;
        secondNode = agnode(g, (char *)[toNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agedge_t *edge_A_B = agedge(g, fromNode, secondNode, "bridge", TRUE);
        agset(edge_A_B, "label", (char *)[pathDesp cStringUsingEncoding:NSUTF8StringEncoding]);
        [self _addCommonAttriForEdge:edge_A_B fromNode:headNode toNode:oneNextNode];
        
        //recursive
        [self addNodesFor:g withHeadNode:oneNextNode];
    }
    
    for (id<GraphNode> extraNextNode in [headNode extraNextNodes]) {
        NSString *toNodeName = [extraNextNode nodeName];
        NSString *pathDesp = [headNode pathDespForNextNode:extraNextNode];
        Agnode_t *secondNode;
        secondNode = agnode(g, (char *)[toNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agedge_t *edge_A_B = agedge(g, fromNode, secondNode, "bridge", TRUE);
        agset(edge_A_B, "label", (char *)[pathDesp cStringUsingEncoding:NSUTF8StringEncoding]);
        [self _addCommonAttriForEdge:edge_A_B fromNode:headNode toNode:extraNextNode];
    }
}

- (void)_addCommonAttriForEdge: (Agedge_t *) edge fromNode: (id<GraphNode>)fromNode toNode: (id<GraphNode>) toNode {
    NSInteger pathWeight = [fromNode pathWeightForNextNode:toNode];
    char *weightC = (char *)[[NSString stringWithFormat:@"%ld", (long)pathWeight] cStringUsingEncoding:NSUTF8StringEncoding];
    agsafeset(edge, "weight", weightC, "1");
    agsafeset(edge, "arrowsize", "0.8", "1");
}

- (void)_addCommonAttriForNode: (Agnode_t *)node color: (char *)color {
    
    //Node fill color
    agsafeset(node, "style", "filled", "solid");
    agsafeset(node, "fillcolor", color, "lightgrey");
    
    //Node size
    agsafeset(node, "fixedsize", "true", "false");
    
    //font size
    agsafeset(node, "fontsize", "18", "14");
}

- (void)forward {
    [_regSwift forward];
}

- (MatchStatusDesp *)matchStatus {
    return _regSwift.matchStatusDesp;
}

@end
