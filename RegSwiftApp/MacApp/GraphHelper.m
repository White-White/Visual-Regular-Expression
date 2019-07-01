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

+ (GraphHelper *)shared {
    static GraphHelper* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *librariesDirURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Frameworks/" isDirectory:YES];
        setenv("GVBINDIR", (char*)[[librariesDirURL path] UTF8String], 1);
        instance = [[GraphHelper alloc] initPrivate];
    });
    
    return instance;
}

- (instancetype)init {
    @throw @"User [GraphHelper shared]";
}

- (instancetype)initPrivate {
    self = [super init];
    return self;
}


- (void)resetWithRegEx:(NSString *)regEx match:(NSString *)match error:(NSError *__autoreleasing  _Nullable *)error {
    _regSwift = [[RegSwift alloc] initWithPattern:regEx match:match error:error];
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
    NSString *fromNodeName = [_regSwift nameFor:headNode];
    Agnode_t *fromNode;
    fromNode = agnode(g, (char *)[fromNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
    
    NSArray <id<GraphNode>>* normalNextNodes = [headNode normalNextNodes];
    for (id<GraphNode> oneNextNode in normalNextNodes) {
        NSString *toNodeName = [_regSwift nameFor:oneNextNode];
        NSString *pathDesp = [headNode pathDespForNextNode:oneNextNode];
        Agnode_t *secondNode;
        secondNode = agnode(g, (char *)[toNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agedge_t *edge_A_B = agedge(g, fromNode, secondNode, "bridge", TRUE);
        agset(edge_A_B, "label", (char *)[pathDesp cStringUsingEncoding:NSUTF8StringEncoding]);
        
        //recursive
        [self addNodesFor:g withHeadNode:oneNextNode];
    }
    
    for (id<GraphNode> extraNextNode in [headNode extraNextNodes]) {
        NSString *toNodeName = [_regSwift nameFor:extraNextNode];
        NSString *pathDesp = [headNode pathDespForNextNode:extraNextNode];
        Agnode_t *secondNode;
        secondNode = agnode(g, (char *)[toNodeName cStringUsingEncoding:NSUTF8StringEncoding], TRUE);
        
        Agedge_t *edge_A_B = agedge(g, fromNode, secondNode, "bridge", TRUE);
        agset(edge_A_B, "label", (char *)[pathDesp cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    
    //Node fill color
    agsafeset(fromNode, "style", "filled", "solid");
    agsafeset(fromNode, "fillcolor", (char *)[[headNode nodeFillColorHex] cStringUsingEncoding:NSUTF8StringEncoding], "lightgrey");
    
    //Node size
    agsafeset(fromNode, "fixedsize", "true", "false");
    agsafeset(fromNode, "width", "0.8", "0.75");
    agsafeset(fromNode, "height", "0.8", "0.75");
    
    //font size
    agsafeset(fromNode, "fontsize", "20", "14");
}

- (void)forward {
    [_regSwift forward];
}

- (NSInteger)currentMatchIndex {
    return [_regSwift currentMatchIndex];
}

- (RegSwiftMatchStatus)matchStatus {
    if ([_regSwift matchEnd]) {
        return [_regSwift didFindMatch] ? RegSwiftMatchSuccess : RegSwiftMatchNormal;
    } else {
        return RegSwiftMatchNormal;
    }
}

@end
