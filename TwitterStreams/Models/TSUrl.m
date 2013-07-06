//
//  TSUrl.m
//  TwitterStreams
//
//  Created by Stuart Hall on 7/03/12.
//  Copyright (c) 2012 Stuart Hall. All rights reserved.
//

#import "TSUrl.h"

@implementation TSUrl

- (NSString*)url {
    return (self.dictionary)[@"url"];
}

- (NSString*)displayUrl {
    return (self.dictionary)[@"display_url"];
}

- (NSString*)expandedUrl {
    return (self.dictionary)[@"expanded_url"];
}

- (NSArray*)indicies {  
    return (self.dictionary)[@"indicies"];
}

@end
