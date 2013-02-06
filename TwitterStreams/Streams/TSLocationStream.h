//
//  TSLocationStream.h
//  TwitterStreams
//
//  Created by Matthew Crandall on 2/5/13.
//  Copyright (c) 2013 Stuart Hall. All rights reserved.
//

#import "TSStream.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface TSLocationStream : TSStream
/*!
 @method    initWithAccount:andDelegate:andKeywords:
 
 @abstract
 Initialises and starts a stream
 
 @param
 account    The authenticated account.
 
 @param
 delegate   The delegate.
 
 @param
 location   Center location to filter on.
 
 @param
 distance   Distance from center location to create bounding box for
            tweets.
 
 */
- (id)initWithAccount:(ACAccount*)account
          andDelegate:(id<TSStreamDelegate>)delegate
    andSSWLongitude:(double)swLongitude
     andSWLatitude:(double)swLatitude
    andNELongitude:(double)neLongitude
     andNELatitude:(double)neLatitude;


- (id)initWithAccount:(ACAccount*)account
          andDelegate:(id<TSStreamDelegate>)delegate
          andLocation:(CLLocation *)location
         withDistance:(CLLocationDistance)distance;

- (id)initWithAccount:(ACAccount*)account
          andDelegate:(id<TSStreamDelegate>)delegate
          andRegion:(MKCoordinateRegion)region;

@end
