//
//  TSTweet.m
//  TwitterStreams
//
//  Created by Stuart Hall on 6/03/12.
//  Copyright (c) 2012 Stuart Hall. All rights reserved.
//

#import "TSTweet.h"
#import "NSArray+Enumerable.h"

@implementation TSLocationCoordinate2D

@end

@interface TSTweet()
@property (nonatomic, strong) TSUser* cachedUser;
@property (nonatomic, strong) NSArray* cachedUserMentions;
@property (nonatomic, strong) NSArray* cachedUrls;
@property (nonatomic, strong) NSArray* cachedHashtags;
@property (nonatomic, strong) NSDate* cachedCreatedAt;
@property (nonatomic, strong) TSLocationCoordinate2D *cachedLocation;
@end

@implementation TSTweet

@synthesize cachedUser=_cachedUser;
@synthesize cachedUserMentions=_cachedUserMentions;
@synthesize cachedUrls=_cachedUrls;
@synthesize cachedHashtags=_cachedHashtags;
@synthesize cachedCreatedAt=_cachedCreatedAt;
@synthesize cachedLocation=_cachedLocation;


- (void) logAllUserParams {
    NSLog(@"========= ALL TWEET PARAMS ==========");
    NSLog(@"%@",self.dictionary);
}

- (NSNumber *)originalTweetID
{
    if ((self.dictionary)[@"retweeted_status"]){
        return (self.dictionary)[@"retweeted_status"][@"id"];
    }
    else {
        return (self.dictionary)[@"id"];
    }
}

- (NSNumber *)retweetCount
{
    return (self.dictionary)[@"retweet_count"];
}

- (NSString*)text {
    return (self.dictionary)[@"text"];
}

- (TSUser*)user {
    if (!self.cachedUser)
        self.cachedUser = [[TSUser alloc] initWithDictionary:(self.dictionary)[@"user"]];
    
    return self.cachedUser;
}

- (NSArray*)userMentions {
    if (!self.cachedUserMentions) {
        self.cachedUserMentions = [[self.dictionary valueForKeyPath:@"entities.user_mentions"] map:^id(NSDictionary* d) {
            return [[TSUser alloc] initWithDictionary:d];
        }];
    }
    
    return self.cachedUserMentions;
}

- (NSArray*)urls {
    if (!self.cachedUrls) {
        self.cachedUrls = [[self.dictionary valueForKeyPath:@"entities.urls"] map:^id(NSDictionary* d) {
            return [[TSUrl alloc] initWithDictionary:d];
        }];
    }
    
    return self.cachedUrls;
}

- (NSArray*)hashtags {
    if (!self.cachedHashtags) {
        self.cachedHashtags = [[self.dictionary valueForKeyPath:@"entities.hashtags"] map:^id(NSDictionary* d) {
            return [[TSHashtag alloc] initWithDictionary:d];
        }];
    }
    
    return self.cachedHashtags;
}

- (NSDate*)createdAt{
    if(!self.cachedCreatedAt){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss '+0000' yyyy"];
        self.cachedCreatedAt = [dateFormatter dateFromString:[self.dictionary valueForKey:@"created_at"]];
    }
    
    return self.cachedCreatedAt;
}

- (TSLocationCoordinate2D *)location {
    if (!self.cachedLocation) {
        if ((self.dictionary)[@"coordinates"] != [NSNull null]) {
            NSArray *cord = (self.dictionary)[@"coordinates"][@"coordinates"];
            self.cachedLocation = [[TSLocationCoordinate2D alloc] init];
            self.cachedLocation.latitude = [cord[1] doubleValue];
            self.cachedLocation.longitude = [cord[0] doubleValue];
        } else if ((self.dictionary)[@"place"] != [NSNull null]) {
            CGFloat longitude = 0.0f;
            CGFloat latitude = 0.0f;
            NSUInteger i = 0;
            for (NSArray *coords in (self.dictionary)[@"place"][@"bounding_box"][@"coordinates"][0]) {
                longitude += [coords[0] floatValue];
                latitude += [coords[1] floatValue];
                i++;
            }
            longitude /= (float)i;
            latitude /= (float)i;
            self.cachedLocation = [[TSLocationCoordinate2D alloc] init];
            self.cachedLocation.latitude = latitude;
            self.cachedLocation.longitude = longitude;
        }
    }
    
    return self.cachedLocation;
}

- (BOOL) isRetweet
{
    NSRegularExpression *retweetRegExp = [[NSRegularExpression alloc] initWithPattern:@"RT @([^\\s:]+):? (.*$)" options:0 error:nil];
    if ([retweetRegExp numberOfMatchesInString:[self text] options:0 range:NSMakeRange(0, [[self text]length])]){
        return YES;
    }
    else {
        return NO;
    }
    
}

- (NSString *) extractTextFromRetweet
{
    return [self extractPartFromTweetWithIndex:2];
}

- (NSString *) extractUserFromRetweet
{
    return [self extractPartFromTweetWithIndex:1];
}

- (NSString*) extractPartFromTweetWithIndex:(int)index {
    NSRegularExpression *retweetRegExp = [[NSRegularExpression alloc] initWithPattern:@"RT @([^\\s:]+):? (.*$)" options:0 error:nil];
    NSArray *matches = [retweetRegExp matchesInString:[self text] options:0 range:NSMakeRange(0, [[self text] length])];
    NSTextCheckingResult *match = matches[0];
    NSString *originalText = [[self text] substringWithRange:[match rangeAtIndex:index]];
    return originalText;
}

@end
