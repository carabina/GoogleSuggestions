//
//  GoogleSuggestionsManager.m
//  ChinaMusic
//
//  Created by Radu on 5/10/16.
//  Copyright © 2016 Radu. All rights reserved.
//

#import "GoogleSuggestionsManager.h"
#import "TBXML.h"
#import "NSString+HTML.h"

#define kGoogleAutocompleteURLString @"http://google.com/complete/search?output=toolbar&ds=yt&q="

@interface GoogleSuggestionsManager()<NSURLConnectionDelegate>
{
    NSURLConnection *connection;
    SuggestionsResultBlock _completion;
}

@end

@implementation GoogleSuggestionsManager

#pragma mark - Initializations
+ (GoogleSuggestionsManager *) sharedManager
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

#pragma mark - Fetching data
- (void) fetchSuggestionsForText:(NSString *) text usingBlock:(SuggestionsResultBlock) resultBlock
{
    [self recycleConnection];
    if ([self stringIsEmpty:text])
    {
        if (resultBlock)
        {
            resultBlock(nil, nil);
        }
        return;
    }
    
    _completion = nil;
    _completion = [resultBlock copy];
    NSString *validString = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *validURLString = [kGoogleAutocompleteURLString stringByAppendingString:validString];
    NSURL *url = [NSURL URLWithString:validURLString];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10];
    
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void) recycleConnection
{
    if (connection)
    {
        [connection cancel];
        connection = nil;
    }
}

#pragma mark - NSURLConnectionDelegate Methods
- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response
{
    
}

- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data
{
    NSMutableArray *suggestionArray = [[NSMutableArray alloc] init];
    
    if (data)
    {
        TBXML *tbxml = nil;
        @try
        {
            NSError *error = nil;
            tbxml = [[TBXML alloc] initWithXMLData:data error:&error];
            if (error)
            {
                NSLog(@"Parsing error: %@", error.localizedDescription);
                return;
            }
        }
        @catch (NSException *exception)
        {
            NSLog(@"Caught %@: %@", [exception name], [exception reason]);
        }
        
        if (!tbxml)
        {
            return;
        }
        
        //Obtain root element
        TBXMLElement * root = tbxml.rootXMLElement;
        if (root)
        {
            TBXMLElement * elem_complete_sugestion = [TBXML childElementNamed:@"CompleteSuggestion" parentElement:root];
            while (elem_complete_sugestion != nil)
            {
                TBXMLElement * elem_sugestion = [TBXML childElementNamed:@"suggestion" parentElement:elem_complete_sugestion];
                TBXMLAttribute *attribute = elem_sugestion->firstAttribute;
                NSString *sugestionText = [TBXML attributeValue:attribute];
                if (sugestionText)
                {
                    [suggestionArray addObject:[sugestionText stringByConvertingHTMLToPlainText]];
                }
                elem_complete_sugestion = [TBXML nextSiblingNamed:@"CompleteSuggestion" searchFromElement:elem_complete_sugestion];
            }
        }
    }
    
    if (_completion)
    {
        _completion(suggestionArray, nil);
    }
    _completion = nil;
}

- (NSCachedURLResponse *) connection:(NSURLConnection *) connection willCacheResponse:(NSCachedURLResponse *) cachedResponse
{
    return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection
{
    
}

- (void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error
{
    NSLog(@"Connection did fail with error: %@",[error localizedDescription]);
    if (_completion)
    {
        _completion(nil, error);
    }
    _completion = nil;
}

#pragma mark - Helper Methods
- (BOOL) stringIsEmpty:(NSString *) string
{
    BOOL isEmpty = NO;
    if ([string length] == 0)
    {
        isEmpty = YES;
    }
    if (![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
    {
        isEmpty = YES;
    }
    return (!string || isEmpty || [string isKindOfClass:[NSNull class]]);
}

@end
