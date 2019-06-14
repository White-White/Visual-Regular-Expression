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

+ (NSString *)createPNGWithRegularExpression: (NSString *)regularExpression error: (NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
