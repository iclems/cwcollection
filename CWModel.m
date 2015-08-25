//
//  CWModel.m
//
//  Created by Clément Wehrung on 01/05/2014.
//  Copyright (c) 2014 Clément Wehrung. All rights reserved.
//

#import <objc/runtime.h>

#import "CWCollectionModelProtocol.h"
#import "CWModel.h"
#import "NSDate+JavascriptTimestamp.h"

@implementation CWModel

- (id)initWithIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        self.identifier = identifier;
    }
    return self;
}

/**
 * managedProperties defines the list of the automatically synced properties.
 * It provides a binding between the local property name and the remote key.
 * { local: remote }
 */

- (NSDictionary *)managedProperties
{
    return @{};
}

- (BOOL)updateWithDictionary:(NSDictionary *)dictionary
{
    if (!(dictionary && [dictionary isKindOfClass:NSDictionary.class])) return NO;
    
    BOOL didChange = NO;
    NSDictionary *managedProperties = self.managedProperties;
    
    for (NSString *localPropertyName in managedProperties)
    {
        NSString *remotePropertyName = managedProperties[localPropertyName];
        id remoteValue = dictionary[remotePropertyName];
        id currentValue = [self valueForKey:localPropertyName];
        
        if (remoteValue && ![remoteValue isKindOfClass:NSNull.class] && !(currentValue && [currentValue isEqual:remoteValue])) {
            
            Class expectedClass = [self classExpectedByPropertyNamed:localPropertyName];
            
            if (![remoteValue isKindOfClass:expectedClass]) {
                // Convert NSNumber => NSDate with assumption that NSNumber represents a JavaScript timestamp
                if ([expectedClass isSubclassOfClass:[NSDate class]] && [remoteValue isKindOfClass:[NSNumber class]]) {
                    remoteValue = [NSDate dateFromJavascriptTimestamp:remoteValue];
                }
                else if ([expectedClass isSubclassOfClass:[NSString class]]) {
                    remoteValue = [NSString stringWithFormat:@"%@", remoteValue];
                }
            }
            
            [self setValue:remoteValue forKey:localPropertyName];
            
            didChange = YES;
        }
    }
    
    return didChange;
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *export = [NSMutableDictionary dictionary];
    NSDictionary *managedProperties = self.managedProperties;

    for (NSString *localPropertyName in managedProperties)
    {
        NSString *remotePropertyName = managedProperties[localPropertyName];
        id localValue = [self valueForKey:localPropertyName];

        // TODO: should we return NSNull for non-set values ?
        if (localValue) {
            
            // Convert NSDate => NSNumber with JavaScript timestamp
            if ([localValue isKindOfClass:NSDate.class]) {
                localValue = [NSDate javascriptTimestampFromDate:localValue];
            }
            
            export[remotePropertyName] = localValue;
        }
    }
    
    return export;
}

#pragma mark - Properties Handling

- (Class)classExpectedByPropertyNamed:(NSString *)propertyName
{
    objc_property_t property = class_getProperty( self.class, [propertyName UTF8String] );
    if ( property == NULL ) { return ( NULL ); }
    
    const char * type = property_getAttributes(property);
    
    NSString * typeString = [NSString stringWithUTF8String:type];
    NSArray * attributes = [typeString componentsSeparatedByString:@","];
    NSString * typeAttribute = [attributes objectAtIndex:0];
    NSString * propertyType = [typeAttribute substringFromIndex:1];
    const char * rawPropertyType = [propertyType UTF8String];
    
    if (strcmp(rawPropertyType, @encode(float)) == 0) {
        //it's a float
    } else if (strcmp(rawPropertyType, @encode(int)) == 0) {
        //it's an int
    } else if (strcmp(rawPropertyType, @encode(id)) == 0) {
        //it's some sort of object
    } else {
        // According to Apples Documentation you can determine the corresponding encoding values
    }
    
    if ([typeAttribute hasPrefix:@"T@"]) {
        NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];  //turns @"NSDate" into NSDate
        Class typeClass = NSClassFromString(typeClassName);
        if (typeClass != nil) {
            return typeClass;
        }
    }
    
    return nil;
}

@end
