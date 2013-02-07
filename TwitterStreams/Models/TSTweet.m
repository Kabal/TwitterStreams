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
@property (nonatomic, retain) TSUser* cachedUser;
@property (nonatomic, retain) NSArray* cachedUserMentions;
@property (nonatomic, retain) NSArray* cachedUrls;
@property (nonatomic, retain) NSArray* cachedHashtags;
@property (nonatomic, retain) NSDate* cachedCreatedAt;
@property (nonatomic, retain) TSLocationCoordinate2D *cachedLocation;
@end

@implementation TSTweet

@synthesize cachedUser=_cachedUser;
@synthesize cachedUserMentions=_cachedUserMentions;
@synthesize cachedUrls=_cachedUrls;
@synthesize cachedHashtags=_cachedHashtags;
@synthesize cachedCreatedAt=_cachedCreatedAt;
@synthesize cachedLocation=_cachedLocation;

- (void)dealloc {
    self.cachedUser = nil;
    self.cachedUserMentions = nil;
    self.cachedUrls = nil;
    self.cachedHashtags = nil;
    self.cachedLocation = nil;
    
    [super dealloc];
}

- (void) logAllUserParams {
    NSLog(@"========= ALL TWEET PARAMS ==========");
    NSLog(@"%@",self.dictionary);
}

- (NSNumber *)originalTweetID
{
    if ([self.dictionary objectForKey:@"retweeted_status"]){
        return [[self.dictionary objectForKey:@"retweeted_status"] objectForKey:@"id"];
    }
    else {
        return [self.dictionary objectForKey:@"id"];
    }
}

- (NSNumber *)retweetCount
{
    return [self.dictionary objectForKey:@"retweet_count"];
}

- (NSString*)text {
    return [self.dictionary objectForKey:@"text"];
}

- (TSUser*)user {
    if (!self.cachedUser)
        self.cachedUser = [[[TSUser alloc] initWithDictionary:[self.dictionary objectForKey:@"user"]] autorelease];
    
    return self.cachedUser;
}

- (NSArray*)userMentions {
    if (!self.cachedUserMentions) {
        self.cachedUserMentions = [[self.dictionary valueForKeyPath:@"entities.user_mentions"] map:^id(NSDictionary* d) {
            return [[[TSUser alloc] initWithDictionary:d] autorelease];
        }];
    }
    
    return self.cachedUserMentions;
}

- (NSArray*)urls {
    if (!self.cachedUrls) {
        self.cachedUrls = [[self.dictionary valueForKeyPath:@"entities.urls"] map:^id(NSDictionary* d) {
            return [[[TSUrl alloc] initWithDictionary:d] autorelease];
        }];
    }
    
    return self.cachedUrls;
}

- (NSArray*)hashtags {
    if (!self.cachedHashtags) {
        self.cachedHashtags = [[self.dictionary valueForKeyPath:@"entities.hashtags"] map:^id(NSDictionary* d) {
            return [[[TSHashtag alloc] initWithDictionary:d] autorelease];
        }];
    }
    
    return self.cachedHashtags;
}

- (NSDate*)createdAt{
    if(!self.cachedCreatedAt){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss '+0000' yyyy"];
        self.cachedCreatedAt = [dateFormatter dateFromString:[self.dictionary valueForKey:@"created_at"]];
    }
    
    return self.cachedCreatedAt;
}

- (TSLocationCoordinate2D *)location {
    if (!self.cachedLocation) {
        if ([self.dictionary objectForKey:@"coordinates"] != [NSNull null]) {
            NSArray *cord = [[self.dictionary objectForKey:@"coordinates"] objectForKey:@"coordinates"];
            self.cachedLocation = [[[TSLocationCoordinate2D alloc] init] autorelease];
            self.cachedLocation.latitude = [cord[1] doubleValue];
            self.cachedLocation.longitude = [cord[0] doubleValue];
        } else if ([self.dictionary objectForKey:@"place"] != [NSNull null]) {
            CGFloat longitude = 0.0f;
            CGFloat latitude = 0.0f;
            NSUInteger i = 0;
            for (NSArray *coords in [[[[self.dictionary objectForKey:@"place"] objectForKey:@"bounding_box"] objectForKey:@"coordinates"] objectAtIndex:0]) {
                longitude += [coords[0] floatValue];
                latitude += [coords[1] floatValue];
                i++;
            }
            longitude /= (float)i;
            latitude /= (float)i;
            self.cachedLocation = [[[TSLocationCoordinate2D alloc] init] autorelease];
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
    NSTextCheckingResult *match = [matches objectAtIndex:0];
    NSString *originalText = [[self text] substringWithRange:[match rangeAtIndex:index]];
    return originalText;
}

@end
