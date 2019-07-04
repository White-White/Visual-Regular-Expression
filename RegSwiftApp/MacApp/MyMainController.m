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
@property (strong, nonatomic) NSLabel *evolvingString;
@property (strong, nonatomic) NSLabel *evolvedString;

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
    
    NSLabel *regLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 12, 40, 20)];
    regLabel.maximumNumberOfLines = 1;
    [regLabel setText:@"Regular expression: "];
    [regLabel sizeToFit];
    [self.view addSubview:regLabel];
    
    regInpuArea = [[NSTextField alloc] initWithFrame:NSMakeRect(regLabel.frame.size.width + 12, 10, 400, 20)];
    regInpuArea.delegate = self;
    [self.view addSubview:regInpuArea];
    
    NSLabel *regLabelE = [[NSLabel alloc] initWithFrame:NSMakeRect(12, 40, 40, 20)];
    regLabelE.maximumNumberOfLines = 1;
    [regLabelE setText:@"Content to match: "];
    [regLabelE sizeToFit];
    [self.view addSubview:regLabelE];
    
    matchInputArea = [[NSTextField alloc] initWithFrame:NSMakeRect(regLabel.frame.size.width + 12, 38, 400, 20)];
    matchInputArea.delegate = self;
    [self.view addSubview:matchInputArea];
    
    confirmButton = [[NSButton alloc] initWithFrame:NSMakeRect(550, 12, 80, 30)];
    [confirmButton setTitle:@"Create NFA"];
    confirmButton.target = self;
    confirmButton.action = @selector(didClickConfirm);
    [self.view addSubview:confirmButton];
    
    evolveButton = [[NSButton alloc] initWithFrame:NSMakeRect(642, 12, 80, 30)];
    [evolveButton setTitle:@"Evolve"];
    evolveButton.target = self;
    evolveButton.action = @selector(didClickEolveButton);
    [self.view addSubview:evolveButton];
    
    NSLabel *matchedLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(740, 12, 100, 20)];
    matchedLabel.maximumNumberOfLines = 1;
    [matchedLabel setText:@"Content matched: "];
    [matchedLabel sizeToFit];
    [self.view addSubview:matchedLabel];
    
    NSLabel *tomatchLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(740, 40, 100, 20)];
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
    
    [self.evolvingString setAttributedStringValue:[[NSAttributedString alloc] initWithString:_match]];
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
    
    switch ([[GraphHelper shared] matchStatus]) {
        case RegSwiftMatchSuccess: {
            NSMutableAttributedString *attri = [[NSMutableAttributedString alloc] initWithString:_match];
            [attri setAttributes:@{NSForegroundColorAttributeName: [NSColor greenColor]}
                           range:NSMakeRange(0, [[GraphHelper shared] indexForNextInput])];
            [self.evolvingString setAttributedStringValue:attri];
            
            [self.errorLabel setText:@"Match success!"];
            self.errorLabel.hidden = NO;
        }
            break;
        case RegSwiftMatchFail: {
            [self.errorLabel setText:@"Match fail!"];
            self.errorLabel.hidden = NO;
        }
            break;
        case RegSwiftMatchNormal: {
            NSMutableAttributedString *attri = [[NSMutableAttributedString alloc] initWithString:_match];
//            [attri setAttributes:@{NSForegroundColorAttributeName: [NSColor greenColor]}
//                           range:NSMakeRange(0, [[GraphHelper shared] indexForNextInput])];
//            [attri setAttributes:@{NSForegroundColorAttributeName: [NSColor orangeColor]}
//                           range:NSMakeRange([[GraphHelper shared] indexForNextInput], 1)];
            [self.evolvingString setAttributedStringValue:attri];
            
            NSUInteger index = [[GraphHelper shared] indexForNextInput];
            NSString *evolved = [_match substringToIndex:index];
            [self.evolvedString setText:evolved];
        }
            break;
    }
    
    [self updateImage];   
}

- (NSLabel *)errorLabel {
    if (!_errorLabel) {
        _errorLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(550, 50, 400, 18)];
        [_errorLabel.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_errorLabel setTextColor:[NSColor redColor]];
        _errorLabel.hidden = YES;
        [self.view addSubview:_errorLabel];
    }
    return _errorLabel;
}

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(12, 72, self.view.bounds.size.width - 24, self.view.bounds.size.height - 12 - 72)];
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

- (NSLabel *)evolvingString {
    if (!_evolvingString) {
        _evolvingString = [[NSLabel alloc] initWithFrame:NSMakeRect(860, 30, 400, 30)];
        [_evolvingString.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_evolvingString setTextColor:[NSColor blackColor]];
        [_evolvingString setFontSize:20];
        [self.view addSubview:_evolvingString];
    }
    return _evolvingString;
}

- (NSLabel *)evolvedString {
    if (!_evolvedString) {
        _evolvedString = [[NSLabel alloc] initWithFrame:NSMakeRect(860, 10, 400, 30)];
        [_evolvedString.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_evolvedString setTextColor:[NSColor blackColor]];
        [_evolvedString setFontSize:20];
        [self.view addSubview:_evolvedString];
    }
    return _evolvedString;
}


@end
