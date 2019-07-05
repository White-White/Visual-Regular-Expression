//
//  GraphHelper.h
//  MacApp
//
//  Created by White on 2019/6/14.
//  Copyright © 2019 Whites. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RegExSwift/RegExSwift-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface GraphHelper : NSObject

+ (GraphHelper *)shared;

- (void)resetWithRegEx: (NSString *)regEx
                 match: (NSString *)match
                 error: (NSError * _Nullable __autoreleasing *)error;

- (NSImage *)createPNG;

- (void)forward;
- (MatchStatusDesp *)matchStatus;

@end

NS_ASSUME_NONNULL_END
