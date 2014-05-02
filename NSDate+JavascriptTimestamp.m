//
//  NSDate+JavascriptTimestamp.m
//  SWAT
//
//  Created by Arush Sehgal on 04/04/2014.
//  Copyright (c) 2014 BRANDiD. All rights reserved.
//

#import "NSDate+JavascriptTimestamp.h"

@implementation NSDate (JavascriptTimestamp)

+ (NSDate *)dateFromJavascriptTimestamp:(id)timestamp {

    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) ([timestamp doubleValue] / 1000)];
    
}

+ (NSNumber *)javascriptTimestampNow {
    return [NSNumber numberWithDouble:round([[NSDate date] timeIntervalSince1970] * 1000)];
}

+ (NSNumber *)javascriptTimestampFromDate:(NSDate *)date {
    return [NSNumber numberWithDouble:round([date timeIntervalSince1970] * 1000)];
}

@end
