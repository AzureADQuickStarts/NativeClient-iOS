//
//  MasterViewController.h
//  QuickStart
//
//  Created by Brandon Werner on 5/21/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong,nonatomic) NSMutableArray *upnArray;
@property (strong,nonatomic) NSMutableArray *filteredUpnArray;
@property (strong,nonatomic) NSMutableArray *objects;
@property IBOutlet UISearchBar *upnSearchBar;

-(void) lookupInGraph:(NSString*)searchString;

@end
