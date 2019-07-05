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

@property (strong, nonatomic) NSLabel *errorLabel;
@property (strong, nonatomic) NSImageView *imageView;;
@property (strong, nonatomic) NSLabel *evolvingStringLabel;
@property (strong, nonatomic) NSLabel *evolvedStringLabel;

@end

@implementation MyMainController {
    NSTextField *regInpuArea;
    NSTextField *matchInputArea;
    NSButton *confirmButton;
    NSButton *evolveButton;
    
    NSString *_re;
    NSString *_match;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLabel *regLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 212, 40, 20)];
    regLabel.maximumNumberOfLines = 1;
    [regLabel setText:@"Regular expression: "];
    [regLabel sizeToFit];
    [self.view addSubview:regLabel];
    
    regInpuArea = [[NSTextField alloc] initWithFrame:NSMakeRect(regLabel.frame.size.width + 12, 210, 400, 20)];
    regInpuArea.delegate = self;
    [self.view addSubview:regInpuArea];
    
    NSLabel *regLabelE = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 240, 40, 20)];
    regLabelE.maximumNumberOfLines = 1;
    [regLabelE setText:@"Content to match: "];
    [regLabelE sizeToFit];
    [self.view addSubview:regLabelE];
    
    matchInputArea = [[NSTextField alloc] initWithFrame:NSMakeRect(regLabel.frame.size.width + 12, 238, 400, 20)];
    matchInputArea.delegate = self;
    [self.view addSubview:matchInputArea];
    
    confirmButton = [[NSButton alloc] initWithFrame:NSMakeRect(550, 212, 80, 30)];
    [confirmButton setTitle:@"Create NFA"];
    confirmButton.target = self;
    confirmButton.action = @selector(didClickConfirm);
    [self.view addSubview:confirmButton];
    
    evolveButton = [[NSButton alloc] initWithFrame:NSMakeRect(642, 212, 80, 30)];
    [evolveButton setTitle:@"Evolve"];
    evolveButton.target = self;
    evolveButton.action = @selector(didClickEolveButton);
    [self.view addSubview:evolveButton];
    
    NSLabel *matchedLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(740, 212, 100, 20)];
    matchedLabel.maximumNumberOfLines = 1;
    [matchedLabel setText:@"Content matched: "];
    [matchedLabel sizeToFit];
    [self.view addSubview:matchedLabel];
    
    NSLabel *tomatchLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(740, 240, 100, 20)];
    tomatchLabel.maximumNumberOfLines = 1;
    [tomatchLabel setText:@"To be matched: "];
    [tomatchLabel sizeToFit];
    [self.view addSubview:tomatchLabel];
}

- (void)didClickConfirm {
    self.errorLabel.hidden = YES;
    
    NSString *rg = regInpuArea.stringValue;
    if (!rg || rg.length == 0) {
        [self.errorLabel setText:@"Regular expression can't be EMPTYYYY!"];
        self.errorLabel.hidden = NO;
        return;
    }
    
    NSString *match = matchInputArea.stringValue;
    if (!match || match.length == 0) {
        [self.errorLabel setText:@"Target match string can't be EMPTYYYY!"];
        self.errorLabel.hidden = NO;
        return;
    }
    
    _re = rg;
    _match = match;
    
    NSError *error;
    [[GraphHelper shared] resetWithRegEx:_re match:_match error:&error];
    if (error) {
        [self.errorLabel setText:[error localizedDescription]];
        self.errorLabel.hidden = NO;
        return;
    } else {
        [self updateImage];
    }
    
    [self.evolvingStringLabel setAttributedStringValue:[[NSAttributedString alloc] initWithString:_match]];
}

- (void)didClickEolveButton {
    self.errorLabel.hidden = YES;
    
    NSString *rg = _re;
    if (!rg || rg.length == 0) {
        [self.errorLabel setText:@"Please create one NFA first."];
        self.errorLabel.hidden = NO;
        return;
    }
    
    [[GraphHelper shared] forward];
    
    MatchStatusDesp *matchStatus = [[GraphHelper shared] matchStatus];
    [self.errorLabel setText: matchStatus.log];
    self.errorLabel.hidden = NO;
    
    NSUInteger index = [matchStatus indexForNextInput];
    NSString *evolved = [_match substringToIndex:index];
    [self.evolvedStringLabel setText:evolved];
    
    
    NSMutableAttributedString *evolvingAttriString = [[NSMutableAttributedString alloc] initWithString:_match];
    [evolvingAttriString setAttributes:@{NSForegroundColorAttributeName: [NSColor whiteColor]} range:NSMakeRange(0, [matchStatus indexForNextInput])];
    [self.evolvingStringLabel setAttributedStringValue:evolvingAttriString];
    
//    switch (matchStatus.matchStatus) {
//        case MatchStatusMatchSuccess: {
//            [self.errorLabel setText: matchStatus.log];
//            self.errorLabel.hidden = NO;
//        }
//            break;
//        case MatchStatusMatchFail: {
//            [self.errorLabel setText: matchStatus.log];
//            self.errorLabel.hidden = NO;
//        }
//            break;
//        case MatchStatusMatchNormal: {
//            NSUInteger index = [matchStatus indexForNextInput];
//            NSString *evolved = [_match substringToIndex:index];
//            [self.evolvedStringLabel setText:evolved];
//        }
//            break;
//        case MatchStatusMatchStart: {
//            break;
//        }
//    }
    
    [self updateImage];   
}

- (NSLabel *)errorLabel {
    if (!_errorLabel) {
        _errorLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(550, 250, 400, 18)];
        [_errorLabel.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_errorLabel setTextColor:[NSColor redColor]];
        _errorLabel.hidden = YES;
        [self.view addSubview:_errorLabel];
    }
    return _errorLabel;
}

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(12, 72 + 300, self.view.bounds.size.width - 24, self.view.bounds.size.height - 12 - 72 - 300)];
        [_imageView setWantsLayer:YES];
        [_imageView.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_imageView.layer setContentsGravity:kCAGravityResizeAspectFill];
        [self.view addSubview:_imageView];
    }
    return _imageView;
}

- (void)updateImage {
    NSImage *png = [[GraphHelper shared] createPNG];
    [self.imageView setImage:png];
}

- (NSLabel *)evolvingStringLabel {
    if (!_evolvingStringLabel) {
        _evolvingStringLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(860, 230, 400, 30)];
        [_evolvingStringLabel.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_evolvingStringLabel setTextColor:[NSColor blackColor]];
        [_evolvingStringLabel setFontSize:20];
        [self.view addSubview:_evolvingStringLabel];
    }
    return _evolvingStringLabel;
}

- (NSLabel *)evolvedStringLabel {
    if (!_evolvedStringLabel) {
        _evolvedStringLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(860, 210, 400, 30)];
        [_evolvedStringLabel.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_evolvedStringLabel setTextColor:[NSColor blackColor]];
        [_evolvedStringLabel setFontSize:20];
        [self.view addSubview:_evolvedStringLabel];
    }
    return _evolvedStringLabel;
}


@end
