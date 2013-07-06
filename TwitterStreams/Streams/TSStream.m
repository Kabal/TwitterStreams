//
//  TSStream.m
//
//  Created by Stuart Hall on 6/03/12.
//  Copyright (c) 2012 Stuart Hall. All rights reserved.
//

#import "TSStream.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
#import <Social/Social.h>
#else
#import <Twitter/Twitter.h>
#endif
#import <Accounts/Accounts.h>

@interface TSStream ()

@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSTimer* keepAliveTimer;
@property (nonatomic, weak) id<TSStreamDelegate> delegate;
@property (nonatomic, strong) ACAccount* account;
@property (nonatomic, strong) NSMutableDictionary* parameters;
@property (nonatomic, strong) NSString* endpoint;

@end

@implementation TSStream

@synthesize connection=_connection;
@synthesize keepAliveTimer=_keepAliveTimer;
@synthesize delegate=_delegate;
@synthesize account=_account;
@synthesize parameters=_parameters;
@synthesize endpoint=_endpoint;

- (void)dealloc {
    [self.connection cancel];
    
    [self.keepAliveTimer invalidate];
    
    
}

- (id)initWithEndpoint:(NSString*)endpoint
         andParameters:(NSDictionary*)parameters
            andAccount:(ACAccount*)account
           andDelegate:(id<TSStreamDelegate>)delegate {
    self = [super init];
    if (self) {
        // Save the parameters
        self.delegate = delegate;
        self.account = account;
        self.endpoint = endpoint;
        
        // Use length delimited so we can count the bytes
        self.parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
        (self.parameters)[@"delimited"] = @"length";
    }
    return self;
}

#pragma mark - Public methods

- (void)start {
    // Our actually request
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                             requestMethod:SLRequestMethodPOST
                                                       URL:[NSURL URLWithString:self.endpoint]
                                               parameters:self.parameters];
#else
    TWRequest *request = [[TWRequest alloc]
                          initWithURL:[NSURL URLWithString:self.endpoint]
                          parameters:self.parameters
                          requestMethod:TWRequestMethodPOST];
#endif
    
    // Set the current account for authentication, or even just rate limit
    [request setAccount:self.account];
    
    // Use the signed request to start a connection
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
    self.connection = [NSURLConnection connectionWithRequest:request.preparedURLRequest
                                                    delegate:self];
#else
    self.connection = [NSURLConnection connectionWithRequest:request.signedURLRequest
                                                    delegate:self];
#endif
    
    // Start the keepalive timer and connection
    [self resetKeepalive];
    [self.connection start];
    
}

- (void)stop {
    [self.connection cancel];
    [self.keepAliveTimer invalidate];
    self.connection = nil;
}

#pragma mark - Keep Alive

- (void)resetKeepalive {
    [self.keepAliveTimer invalidate];
    self.keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:40 
                                                           target:self 
                                                         selector:@selector(onTimeout)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)onTimeout {
    // Timeout
    [self stop];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamDidTimeout:)])
        [self.delegate streamDidTimeout:self];
    
    // Try and restart
    [self start];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    int bytesExpected = 0;
    NSMutableString* message = nil;
    
    NSString* response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    for (NSString* part in [response componentsSeparatedByString:@"\r\n"]) {
        int length = [part intValue];
        if (length > 0) {
            // New message
            message = [NSMutableString string];
            bytesExpected = length;
        }
        else if (bytesExpected > 0 && message) {
            if (message.length < bytesExpected) {
                // Append the data
                [message appendString:part];
                
                if (message.length < bytesExpected) {
                    // Newline counts
                    [message appendString:@"\r\n"];
                }
                
                if (message.length == bytesExpected) {
                    // Success!
                    NSError *error = nil;
                    id json = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
                    
                    // Alert the delegate
                    if (!error && json) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(streamDidReceiveMessage:json:)])
                            [self.delegate streamDidReceiveMessage:self json:json];
                        [self resetKeepalive];
                    }
                    else  {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(streamDidReceiveInvalidJson:message:)])
                            [self.delegate streamDidReceiveInvalidJson:self message:message];
                    }
                    
                    // Reset
                    message = nil;
                    bytesExpected = 0;
                }
            }
        }
        else {
            // Keep alive
            [self resetKeepalive];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamDidFailConnection:)])
        [self.delegate streamDidFailConnection:self];

}

@end
