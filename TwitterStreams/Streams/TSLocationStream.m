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
      andSSWLongitude:(double)swLongitude
        andSWLatitude:(double)swLatitude
       andNELongitude:(double)neLongitude
        andNELatitude:(double)neLatitude {

    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSString stringWithFormat:@"%f,%f,%f,%f", swLongitude, swLatitude, neLongitude, neLatitude], @"locations",
                                       nil];

    return [super initWithEndpoint:@"https://userstream.twitter.com/1.1/user.json"
                     andParameters:parameters
                        andAccount:account
                       andDelegate:delegate];
    
}

- (id)initWithAccount:(ACAccount*)account
          andDelegate:(id<TSStreamDelegate>)delegate
            andRegion:(MKCoordinateRegion)region {
    return [self initWithAccount:account andDelegate:delegate andSSWLongitude:region.center.longitude - region.span.longitudeDelta andSWLatitude:region.center.latitude - region.span.latitudeDelta andNELongitude:region.center.longitude + region.span.longitudeDelta andNELatitude:region.center.latitude + region.span.latitudeDelta];
}

- (id)initWithAccount:(ACAccount*)account
          andDelegate:(id<TSStreamDelegate>)delegate
          andLocation:(CLLocation *)location
         withDistance:(CLLocationDistance)distance {
    
    return [self initWithAccount:account andDelegate:delegate andRegion:MKCoordinateRegionMakeWithDistance(location.coordinate, distance, distance)];
}

@end
