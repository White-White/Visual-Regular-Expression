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


@end

@implementation MyMainController {
    NSTextField *regInpuArea;
    NSTextField *matchInputArea;
    NSButton *confirmButton;
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
    [confirmButton setTitle:@"Go"];
    confirmButton.target = self;
    confirmButton.action = @selector(didClickConfirm);
    [self.view addSubview:confirmButton];
    // Do view setup here.
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
    
    NSError *error;
    NSString *pngPath = [GraphHelper createPNGWithRegularExpression:rg error:&error];
    if (error) {
        [self.errorLabel setText:[error localizedDescription]];
        self.errorLabel.hidden = NO;
        return;
    } else {
        [self.imageView setImage:[[NSImage alloc] initWithContentsOfFile:pngPath]];
    }
}

- (NSLabel *)errorLabel {
    if (!_errorLabel) {
        _errorLabel = [[NSLabel alloc] initWithFrame:NSMakeRect(650, 5, 400, 50)];
        [_errorLabel.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_errorLabel setTextColor:[NSColor redColor]];
        _errorLabel.hidden = YES;
        [self.view addSubview:_errorLabel];
    }
    return _errorLabel;
}

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(12, 250, 1200, 600)];
        [_imageView setWantsLayer:YES];
        [_imageView.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [_imageView.layer setContentsGravity:kCAGravityResizeAspectFill];
        [self.view addSubview:_imageView];
    }
    return _imageView;
}


@end
