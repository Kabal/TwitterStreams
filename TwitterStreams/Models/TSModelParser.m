//
//  TSModelParser.m
//  TwitterStreams
//
//  Created by Stuart Hall on 6/03/12.
//  Copyright (c) 2012 Stuart Hall. All rights reserved.
//

#import "TSModelParser.h"

@implementation TSModelParser

static dispatch_queue_t model_processing_queue;
static dispatch_queue_t operation_processing_queue() {
    if (model_processing_queue == NULL)
        model_processing_queue = dispatch_queue_create("com.filtersquad.tsmodelparser.processing", 0);
    return model_processing_queue;
}

+ (void)parseJson:(id)json
          friends:(TSModelParserFriendsList)friends
            tweet:(TSModelParserTweet)tweet
      deleteTweet:(TSModelParserTweet)deleteTweet
           follow:(TSModelParserFollow)follow
         favorite:(TSModelParserFavorite)favorite
       unfavorite:(TSModelParserFavorite)unfavorite
      unsupported:(TSModelParserUnsupported)unsupported {
    dispatch_async(operation_processing_queue(), ^(void) {
        if ([json isKindOfClass:[NSDictionary class]]) {
            if (json[@"friends"]) {
                TSFriendsList* model = [[TSFriendsList alloc] initWithDictionary:json];
                dispatch_async(dispatch_get_main_queue(), ^{
                    friends(model);
                });
            }
            else if (json[@"source"] && json[@"text"]) {
                TSTweet* model = [[TSTweet alloc] initWithDictionary:json];
                dispatch_async(dispatch_get_main_queue(), ^{
                    tweet(model);
                });
            }    
            else if (json[@"delete"]) {
                TSTweet* model = [[TSTweet alloc] initWithDictionary:json[@"status"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    deleteTweet(model);
                });
            }  
            else if (json[@"event"] && [json[@"event"] isEqualToString:@"follow"]) {
                TSFollow* model = [[TSFollow alloc] initWithDictionary:json];
                dispatch_async(dispatch_get_main_queue(), ^{
                    follow(model);
                });
            }  
            else if (json[@"event"] && [json[@"event"] isEqualToString:@"favorite"]) {
                TSFavorite* model = [[TSFavorite alloc] initWithDictionary:json];
                dispatch_async(dispatch_get_main_queue(), ^{
                    favorite(model);
                });
            }
            else if (json[@"event"] && [json[@"event"] isEqualToString:@"unfavorite"]) {
                TSFavorite* model = [[TSFavorite alloc] initWithDictionary:json];
                dispatch_async(dispatch_get_main_queue(), ^{
                    unfavorite(model);
                });
            }
            else {
                // Unknown
                dispatch_async(dispatch_get_main_queue(), ^{
                    unsupported(json);
                });
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                unsupported(json);
            });
        }
    }); 
}

@end
