//
//  GoogleSuggestionsManager.h
//  ChinaMusic
//
//  Created by Radu on 5/10/16.
//  Copyright © 2016 Radu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SuggestionsResultBlock)(NSArray *suggestionsArray, NSError *error);

@interface GoogleSuggestionsManager : NSObject

#pragma mark - Initializations
+ (GoogleSuggestionsManager *) sharedManager;

#pragma mark - Fetching data
- (void) fetchSuggestionsForText:(NSString *) text usingBlock:(SuggestionsResultBlock) resultBlock;

@end
