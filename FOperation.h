//
//  FOperation.h
//  LiveMinutes
//
//  Created by Clément Wehrung on 30/04/2014.
//  Copyright (c) 2014 Live Minutes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

@interface FOperation : NSOperation

@property (nonatomic, strong) Firebase *ref;
@property (nonatomic, assign, readonly) FirebaseHandle handle;

- (id)initWithRef:(Firebase *)ref;

/**
 * Cancellable Firebase methods
 **/

- (void)observeEventType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block;
- (void)observeEventType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block;
- (void)observeEventType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block withCancelBlock:(void (^)(NSError* error))cancelBlock;
- (void)observeEventType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block withCancelBlock:(void (^)(NSError* error))cancelBlock;

@end
