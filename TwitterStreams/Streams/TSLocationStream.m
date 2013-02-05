//
//  TSLocationStream.m
//  TwitterStreams
//
//  Created by Matthew Crandall on 2/5/13.
//  Copyright (c) 2013 Stuart Hall. All rights reserved.
//

#import "TSLocationStream.h"
#import <MapKit/MapKit.h>

@implementation TSLocationStream

- (id)initWithAccount:(ACAccount*)account
          andDelegate:(id<TSStreamDelegate>)delegate
          andLocation:(CLLocation *)location
         withDistance:(CLLocationDistance)distance {
    //convert location and distance
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, distance, distance);
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSString stringWithFormat:@"%f,%f,%f,%f", region.center.longitude - region.span.longitudeDelta, region.center.latitude - region.span.latitudeDelta, region.center.longitude + region.span.longitudeDelta, region.center.latitude + region.span.latitudeDelta], @"locations",
                                       nil];
    
    return [super initWithEndpoint:@"https://userstream.twitter.com/1.1/user.json"
                     andParameters:parameters
                        andAccount:account
                       andDelegate:delegate];
}

@end
