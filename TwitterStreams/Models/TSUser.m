//
//  TSUser.m
//  TwitterStreams
//
//  Created by Stuart Hall on 6/03/12.
//  Copyright (c) 2012 Stuart Hall. All rights reserved.
//

#import "TSUser.h"

@implementation TSUser

- (NSString*)screenName {
    return [self.dictionary objectForKey:@"screen_name"];
}

- (void) logAllUserParams {
    NSLog(@"========= ALL USER PARAMS ==========");
    NSLog(@"%@",self.dictionary);
}

@end
