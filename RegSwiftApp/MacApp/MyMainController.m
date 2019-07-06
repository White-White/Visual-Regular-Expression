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

@interface MyMainController () <NSTextFieldDelegate>

@end

@implementation MyMainController {
    NSLabel *_errorLabel;
    NSImageView *_imageView;;
    NSLabel *_evolvingStringLabel;
    NSTextField *_regInpuArea;
    NSTextField *_matchInputArea;
    NSButton *_evolveButton;
    
    GraphHelper *_graphHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = NSMakeSize(1200, 800);
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
    
    NSLabel *matchedLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 22, 40, 20)];
    matchedLabel.maximumNumberOfLines = 1;
    [matchedLabel setText:@"Content matched: "];
    [matchedLabel sizeToFit];
    [self.view addSubview:matchedLabel];
    
    _errorLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(550, 90, 400, 18)];
    [_errorLabel.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
    [_errorLabel setTextColor:[NSColor redColor]];
    _errorLabel.hidden = YES;
    [self.view addSubview:_errorLabel];
    
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
}

- (void)viewDidAppear {
    [super viewDidAppear];
}

- (void)didClickEvolveButton {
    if (!_graphHelper) {
        [self showError:@"Please create one NFA first."];
        return;
    }
    
    //forward
    [_graphHelper forward];
    
    //check status
    MatchStatusDesp *matchStatus = [_graphHelper matchStatus];
    [self showError:matchStatus.log];
    
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
        [self showError:@"Rg cant be nil"];
        return;
    }
    
    NSError *error;
    _graphHelper = [[GraphHelper alloc] initWithRegEx:rg error:&error];
    if (error) {
        _graphHelper = nil;
        _matchInputArea.enabled = NO;
        [self showError:[error localizedDescription]];
        return;
    } else {
        _matchInputArea.enabled = YES;
        [self updateImage];
    }
}

- (void)updateMatch {
    NSString *match = _matchInputArea.stringValue;
    if (!match) {
        [self showError:@"Target match string can't be EMPTYYYY!"];
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

- (void)showError: (NSString *)error {
    [_errorLabel setText:error];
    _errorLabel.hidden = NO;
}

@end
