//
//  CWModel.m
//  LiveMinutes
//
//  Created by Clément Wehrung on 01/05/2014.
//  Copyright (c) 2014 Live Minutes. All rights reserved.
//

#import <objc/runtime.h>

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
                if ([expectedClass isSubclassOfClass:NSDate.class] && [remoteValue isKindOfClass:NSNumber.class]) {
                    remoteValue = [NSDate dateFromJavascriptTimestamp:remoteValue];
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
	if ( property == NULL )
		return ( NULL );

    const char * attrs = property_getAttributes( property );
	if ( attrs == NULL )
		return ( NULL );
    
	static char buffer[256];
	const char * e = strchr( attrs, ',' );
	if ( e == NULL )
		return ( NULL );
    
	int len = (int)(e - attrs);
	memcpy( buffer, attrs, len );
	buffer[len] = '\0';

    char *attribute = strtok(buffer, ",");
    if (*attribute == 'T') attribute++; else attribute = NULL;
    
    if (attribute == NULL) return NSNull.class;

    // At this point, buffer => T@"NSObject"
    NSString *className = [[NSString alloc] initWithUTF8String:buffer];
    className = [className substringWithRange:NSMakeRange(3, className.length - 4)];
    Class class = NSClassFromString(className);
    
    return class;
}

@end
