//
//  TSFollow.m
//  TwitterStreams
//
//  Created by Stuart Hall on 6/03/12.
//  Copyright (c) 2012 Stuart Hall. All rights reserved.
//

#import "TSFollow.h"

@implementation TSFollow

- (TSUser*)source {
    return [[TSUser alloc] initWithDictionary:(self.dictionary)[@"source"]];
}

- (TSUser*)target {
    return [[TSUser alloc] initWithDictionary:(self.dictionary)[@"target"]];
}

@end
