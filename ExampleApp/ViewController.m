//
//  ViewController.m
//  TwitterStreams
//
//  Created by Stuart Hall on 6/03/12.
//  Copyright (c) 2012 Stuart Hall. All rights reserved.
//

#import "ViewController.h"

#import "TSUserStream.h"
#import "TSFilterStream.h"
#import "TSLocationStream.h"

#import "TSModelParser.h"

#import <Accounts/Accounts.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_5_1
#import <Social/Social.h>
#else
#import <Twitter/Twitter.h>
#endif

#import "NSArray+Enumerable.h"

@interface ViewController ()

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) ACAccountStore* accountStore;
@property (nonatomic, strong) NSArray* accounts;
@property (nonatomic, strong) ACAccount* account;
@property (nonatomic, strong) NSMutableArray* tweets;

@property (nonatomic, strong) TSStream* stream;

@end

@implementation ViewController

@synthesize tableView=_tableView;

@synthesize locationManager=_locationManager;
@synthesize tweets=_tweets;
@synthesize accountStore=_accountStore;
@synthesize accounts=_accounts;
@synthesize account=_account;
@synthesize stream=_stream;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Holds the tweet list
    self.tweets = [NSMutableArray array];
    
    // Hide empty seperators
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Get access to their accounts
    self.accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountTypeTwitter = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:accountTypeTwitter
                            withCompletionHandler:^(BOOL granted, NSError *error) {
                                if (granted && !error) {
                                    dispatch_sync(dispatch_get_main_queue(), ^{
                                        self.accounts = [self.accountStore accountsWithAccountType:accountTypeTwitter];
                                        if (self.accounts.count == 0) {
                                            [[[UIAlertView alloc] initWithTitle:nil
                                                                         message:@"Please add a Twitter account in the Settings app"
                                                                        delegate:nil
                                                               cancelButtonTitle:@"OK"
                                                               otherButtonTitles:nil] show];
                                        }
                                        else {
                                            // Let them select the account they want to use
                                            UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"Select your Twitter account:"
                                                                                                delegate:self
                                                                                       cancelButtonTitle:nil
                                                                                  destructiveButtonTitle:nil
                                                                                       otherButtonTitles:nil];
                                            
                                            for (ACAccount* account in self.accounts) {
                                                [sheet addButtonWithTitle:account.accountDescription];
                                            }
                                            
                                            sheet.tag = 0;
                                            
                                            [sheet showInView:self.view];
                                        }
                                    });
                                }
                                else {
                                    dispatch_sync(dispatch_get_main_queue(), ^{
                                        NSString* message = [NSString stringWithFormat:@"Error getting access to accounts : %@", [error localizedDescription]];
                                        [[[UIAlertView alloc] initWithTitle:nil
                                                                     message:message
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil] show];
                                    });
                                }
                            }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *) oldLocation {
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;

    
    [self.stream stop];
    self.stream = [[TSLocationStream alloc] initWithAccount:self.account
                                                 andDelegate:self
                                                 andLocation:newLocation
                                                withDistance:160934 / 4]; //25 miles
    [self.stream start];
    
    if (newLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
        [self.locationManager stopUpdatingLocation];
        self.locationManager.delegate = nil;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (actionSheet.tag) {
        case 0: {
            if (buttonIndex < self.accounts.count) {
                self.account = (self.accounts)[buttonIndex];
                
                // Stream options
                UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"Select stream type:"
                                                                    delegate:self 
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:@"User stream", @"Filter stream", @"Location stream", nil];
                sheet.tag = 1;
                [sheet showInView:self.view];
            }
        }
            break; 
            
        case 1: {
            self.stream = nil;
            
            // Create a stream of the selected types
            switch (buttonIndex) {
                case 0: {
                    self.stream = [[TSUserStream alloc] initWithAccount:self.account
                                                             andDelegate:self
                                                           andAllReplies:YES
                                                        andAllFollowings:YES];
                }
                    break;
                    
                case 1: {
                    self.stream = [[TSFilterStream alloc] initWithAccount:self.account
                                                                     andDelegate:self
                                                                     andKeywords:@[@"stuartkhall", @"discovr"]];

                }
                case 2: {
                    self.locationManager = [[CLLocationManager alloc] init];
                    self.locationManager.delegate = self;
                    self.locationManager.desiredAccuracy = 100;
                    [self.locationManager startUpdatingLocation];
                }
                    break;
            }
            
            if (self.stream)
                [self.stream start];

        }
            break;
    }
}

#pragma mark - TSStreamDelegate

- (void)streamDidReceiveMessage:(TSStream*)stream json:(id)json {
    [TSModelParser parseJson:json
                     friends:^(TSFriendsList *model) {
                         NSLog(@"Got friends list");
                     } tweet:^(TSTweet *model) {
                         // Got a new tweet!
                         [self.tweets insertObject:model atIndex:0];
                         [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                                                                        withRowAnimation:UITableViewRowAnimationNone];
                     } deleteTweet:^(TSTweet *model) {
                         NSLog(@"Delete Tweet");
                     } follow:^(TSFollow *model) {
                         NSLog(@"@%@ Followed @%@", model.source.screenName, model.target.screenName);
                     } favorite:^(TSFavorite *model) {
                         NSLog(@"@%@ favorited tweet by @%@", model.source.screenName, model.tweet.user.screenName);
                     } unfavorite:^(TSFavorite *model) {
                         NSLog(@"@%@ unfavorited tweet by @%@", model.source.screenName, model.tweet.user.screenName);
                     } unsupported:^(id json) {
                         NSLog(@"Unsupported : %@", json); 
                     }];
}

- (void)streamDidReceiveInvalidJson:(TSStream*)stream message:(NSString*)message {
    NSLog(@"--\r\nInvalid JSON!!\r\n--");
}

- (void)streamDidTimeout:(TSStream*)stream {
    NSLog(@"--\r\nStream timeout!!\r\n--");
}

- (void)streamDidFailConnection:(TSStream *)stream {
    NSLog(@"--\r\nStream failed connection!!\r\n--");
    
    // Hack to just restart it, you'll want to handle this nicer :)
    [self.stream performSelector:@selector(start) withObject:nil afterDelay:10];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const kCellIdentifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        // Subtitle cell, with a bit of a tweak
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    }
    
    if (indexPath.row < self.tweets.count) {
        // Format the tweet
        TSTweet* tweet = (self.tweets)[indexPath.row];
        cell.textLabel.text = [@"@" stringByAppendingString:tweet.user.screenName];
        cell.detailTextLabel.text = tweet.text;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.tweets.count) {
        // Calculate how much room we need for the tweet
        TSTweet* tweet = (self.tweets)[indexPath.row];
        return [tweet.text sizeWithFont:[UIFont systemFontOfSize:15]
                      constrainedToSize:CGSizeMake(tableView.bounds.size.width - 20, INT_MAX)
                          lineBreakMode:UILineBreakModeCharacterWrap].height + 40;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
