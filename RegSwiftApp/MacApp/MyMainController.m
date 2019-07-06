//
//  MyMainController.m
//  MacApp
//
//  Created by White on 2019/6/14.
//  Copyright © 2019 Whites. All rights reserved.
//

#import "MyMainController.h"
#import "NSLabel.h"
#import "GraphHelper.h"

@interface MyMainController () <NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@end

@implementation MyMainController {
    NSMutableArray *_logs;
    NSImageView *_imageView;;
    NSLabel *_evolvingStringLabel;
    NSTextField *_regInpuArea;
    NSTextField *_matchInputArea;
    NSButton *_evolveButton;
    NSTableView *_logsTableView;
    
    GraphHelper *_graphHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = NSMakeSize(1200, 800);
    _logs = [NSMutableArray array];
    
    NSLabel *regLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 100, 40, 20)];
    regLabel.maximumNumberOfLines = 1;
    [regLabel setText:@"Regular expression: "];
    [regLabel sizeToFit];
    [self.view addSubview:regLabel];
    
    _regInpuArea = [[NSTextField alloc] initWithFrame:NSMakeRect(regLabel.frame.size.width + 12, 100, 200, 20)];
    _regInpuArea.delegate = self;
    [self.view addSubview:_regInpuArea];
    
    NSLabel *regLabelE = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 62, 40, 20)];
    regLabelE.maximumNumberOfLines = 1;
    [regLabelE setText:@"Content to match: "];
    [regLabelE sizeToFit];
    [self.view addSubview:regLabelE];
    
    _matchInputArea = [[NSTextField alloc] initWithFrame:NSMakeRect(regLabel.frame.size.width + 12, 60, 200, 20)];
    _matchInputArea.delegate = self;
    _matchInputArea.enabled = NO;
    [self.view addSubview:_matchInputArea];
    
    _evolveButton = [[NSButton alloc] initWithFrame:NSMakeRect(350, 18, 80, 30)];
    [_evolveButton setTitle:@"Evolve"];
    _evolveButton.target = self;
    _evolveButton.action = @selector(didClickEvolveButton);
    _evolveButton.enabled = NO;
    [self.view addSubview:_evolveButton];
    
    NSButton *resetButton = [[NSButton alloc] initWithFrame:NSMakeRect(442, 18, 80, 30)];
    [resetButton setTitle:@"Reset"];
    resetButton.target = self;
    resetButton.action = @selector(reset);
    [self.view addSubview:resetButton];
    
    NSLabel *matchedLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 22, 40, 20)];
    matchedLabel.maximumNumberOfLines = 1;
    [matchedLabel setText:@"Content matched: "];
    [matchedLabel sizeToFit];
    [self.view addSubview:matchedLabel];
    
    _evolvingStringLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(regLabel.frame.size.width + 12, 20, 200, 20)];
    [_evolvingStringLabel.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
    [_evolvingStringLabel setTextColor:[NSColor blackColor]];
    [_evolvingStringLabel setFontSize:18];
    [self.view addSubview:_evolvingStringLabel];
    
    _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(12, 140, self.view.bounds.size.width - 24, self.view.bounds.size.height - 150)];
    [_imageView setWantsLayer:YES];
    [_imageView.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
    [_imageView.layer setContentsGravity:kCAGravityResizeAspectFill];
    [self.view addSubview:_imageView];
    
    NSScrollView * scrollView = [[NSScrollView alloc] init];
    scrollView.frame = CGRectMake(350, 60, 800, 70);
    [self.view addSubview:scrollView];
    _logsTableView = [[NSTableView alloc] initWithFrame:scrollView.bounds];
    _logsTableView.dataSource = self;
    _logsTableView.delegate = self;
    [_logsTableView setHeaderView:nil];
    NSTableColumn * column = [[NSTableColumn alloc]initWithIdentifier:@"OK"];
    [column setWidth:scrollView.frame.size.width];
    [_logsTableView addTableColumn:column];
    scrollView.documentView = _logsTableView;
}

- (void)reset {
    _graphHelper = nil;
    _regInpuArea.stringValue = @"";
    _matchInputArea.stringValue = @"";
    _matchInputArea.enabled = NO;
    _evolveButton.enabled = NO;
    _evolvingStringLabel.stringValue = @"";
    [_logs removeAllObjects];
    [_logsTableView reloadData];
    [_imageView setImage:nil];
}

- (void)didClickEvolveButton {
    if (!_graphHelper) {
        [self addErrorLog:@"Please create one NFA first."];
        return;
    }
    
    //forward
    [_graphHelper forward];
    
    //check status
    MatchStatusDesp *matchStatus = [_graphHelper matchStatus];
    NSArray *logs = [matchStatus extractLogsAndClear];
    NSEnumerator *logEnume = logs.objectEnumerator;
    NSString *firstLog = logEnume.nextObject;
    if (firstLog) { [self addLog:firstLog]; }
    
    NSColor *nextLogColor;
    switch (matchStatus.matchStatus) {
        case MatchStatusMatchEnd:
            _evolveButton.enabled = NO;
            nextLogColor = [NSColor orangeColor];
            break;
        case MatchStatusMatchFail:
            _evolveButton.enabled = NO;
            nextLogColor = [NSColor redColor];
            break;
        case MatchStatusMatchStart:
            nextLogColor = [NSColor blackColor];
            break;
        case MatchStatusMatchNormal:
            nextLogColor = [NSColor blackColor];
            break;
        case MatchStatusMatchSuccess:
            nextLogColor = [NSColor orangeColor];
            break;
        default:
            break;
    }
    
    NSString *nexgLog = [logEnume nextObject];
    while (nexgLog) {
        [self addLog:nexgLog color:nextLogColor];
        nexgLog = [logEnume nextObject];
    }

    //show result
    NSMutableAttributedString *evolvingAttriString = [[NSMutableAttributedString alloc] initWithString:_evolvingStringLabel.text];
    [evolvingAttriString setAttributes:@{NSBackgroundColorAttributeName: [NSColor greenColor]} range:NSMakeRange(0, [matchStatus indexForNextInput])];
    [_evolvingStringLabel setAttributedStringValue:evolvingAttriString];
    
    //update image
    [self updateImage];   
}

- (void)updateImage {
    NSImage *png = [_graphHelper createPNG];
    [_imageView setImage:png];
}

//MARK: - Auto create regular expression png.

- (void)controlTextDidChange:(NSNotification *)obj {
    NSTextField *textField = [obj object];
    if (textField == _regInpuArea) {
        [self updateRegGraph];
    } else if (textField == _matchInputArea) {
        [self updateMatch];
    }
}

- (void)updateRegGraph {
    NSString *rg = _regInpuArea.stringValue;
    if (!rg || rg.length == 0) {
        _graphHelper = nil;
        _matchInputArea.enabled = NO;
        [self addErrorLog:@"Regular expression cant be empty"];
        return;
    }
    
    NSError *error = nil;
    _graphHelper = [[GraphHelper alloc] initWithRegEx:rg error:&error];
    if (error) {
        _graphHelper = nil;
        _matchInputArea.enabled = NO;
        [self addErrorLog:[error localizedDescription]];
        return;
    } else {
        _matchInputArea.enabled = YES;
        [self addLog:[@"Valid regular expression. " stringByAppendingString:rg]];
        [self updateImage];
    }
    
    _matchInputArea.stringValue = @"";
    _evolveButton.enabled = NO;
}

- (void)updateMatch {
    NSString *match = _matchInputArea.stringValue;
    if (!match) {
        [self addErrorLog:@"Target match string can't be EMPTYYYY!"];
        _evolveButton.enabled = NO;
        return;
    }
    
    [_evolvingStringLabel setAttributedStringValue:[[NSAttributedString alloc] initWithString:match]];
    _evolvingStringLabel.frame = CGRectMake(_evolvingStringLabel.frame.origin.x,
                                            _evolvingStringLabel.frame.origin.y,
                                            [_evolvingStringLabel sizeThatFits:NSMakeSize(CGFLOAT_MAX, 20)].width, 20);
    _evolvingStringLabel.backgroundColor = [NSColor redColor];
    
    CGFloat eButtonX = MAX(350, _evolvingStringLabel.frame.origin.x +_evolvingStringLabel.frame.size.width + 12);
    _evolveButton.frame = CGRectMake(eButtonX,
                                     _evolveButton.frame.origin.y,
                                     _evolveButton.frame.size.width,
                                     _evolveButton.frame.size.height);
    _evolveButton.enabled = YES;
    
    [_graphHelper resetWithMatch:match];
}

- (void)addErrorLog: (NSString *)error {
    [self addLog:error color:[NSColor redColor]];
}

- (void)addLog: (NSString *)log {
    [self addLog:log color:[NSColor blackColor]];
}

- (void)addSuccessLog: (NSString *)log {
    [self addLog:log color:[NSColor orangeColor]];
}

- (void)addLog: (NSString *)log color: (NSColor *)color {
    [_logs addObject:@{@"content": log, @"color": color}];
    [_logsTableView reloadData];
    [_logsTableView scrollToEndOfDocument:nil];
}

//MARK: - tableview datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _logs.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return [NSString stringWithFormat:@"[log:%ld] -- %@", (long)row, [_logs[row] objectForKey:@"content"]];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    [cell setTextColor: [_logs[row] objectForKey:@"color"]];
}

@end
