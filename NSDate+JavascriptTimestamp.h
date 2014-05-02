//
//  NSDate+JavascriptTimestamp.h
//  SWAT
//
//  Created by Arush Sehgal on 04/04/2014.
//  Copyright (c) 2014 BRANDiD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (JavascriptTimestamp)

// convert this date to a javascript timestamp
+ (NSNumber *)javascriptTimestampNow;

// convert a string to an NSDate
+ (NSDate *)dateFromJavascriptTimestamp:(id)timestamp;

// convert a date back to a long (in ms)
+ (NSNumber *)javascriptTimestampFromDate:(NSDate *)date;

@end
