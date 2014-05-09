//
//  DatabaseManipulation.m
//  Trouble Call Form
//
//  Created by Developer on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DatabaseManipulation.h"

@implementation DatabaseManipulation

- (id) init
{
    //RKClient *client = [RKClient clientWithBaseURL:@"http://Silverstate"];
    
    return self;
}

- (void) sendRequests {
    //Perform a simple HTTP Get and call me back with the results
    [[RKClient sharedClient] get:@"/cranes.xml" delegate:self];
}

- (void) request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    if ([request isGET])
    {
        
    }
}

@end
