//
//  FOperation.m
//  LiveMinutes
//
//  Created by Clément Wehrung on 30/04/2014.
//  Copyright (c) 2014 Live Minutes. All rights reserved.
//

#import "FOperation.h"

@interface FOperation ()

@property (nonatomic, assign, readwrite) FirebaseHandle handle;
@property (nonatomic, strong) NSInvocation *invocation;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (strong, atomic) NSThread *thread;

@end

@implementation FOperation

- (id)initWithRef:(Firebase *)ref
{
    if (self = [super init]) {
        _ref = ref;
        [self validate];
    }
    return self;
}

- (void)dealloc
{
    _invocation = nil;
}

- (void)validate
{
    assert(self.ref != nil);
}

- (void)start {
    
    [self validate];
    
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        
        self.executing = YES;
        self.thread = [NSThread currentThread];
    }
    
    [self.invocation invoke];
    [self.invocation getReturnValue:&_handle];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_5_1) {
        // Make sure to run the runloop in our background thread so it can process downloaded data
        // Note: we use a timeout to work around an issue with NSURLConnection cancel under iOS 5
        //       not waking up the runloop, leading to dead threads (see https://github.com/rs/SDWebImage/issues/466)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, false);
    }
    else {
        CFRunLoopRun();
    }
}

- (void)cancel {
    @synchronized (self) {
        if (self.thread) {
            [self performSelector:@selector(cancelInternalAndStop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }
        else {
            [self cancelInternal];
        }
    }
}

- (void)cancelInternalAndStop {
    [self cancelInternal];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];
    
    [self.ref removeObserverWithHandle:self.handle];
    
    if (self.isExecuting) self.executing = NO;
    if (!self.isFinished) self.finished = YES;
    
    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    self.ref = nil;
    self.handle = 0;
    self.thread = nil;
    self.invocation = nil;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
}

#pragma mark - Firebase

- (NSInvocation *)invocationWithSelector:(SEL)selector
{
    NSMethodSignature *signature  = [self methodSignatureForSelector:selector];
    NSInvocation      *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    [invocation setTarget:_ref];
    [invocation setSelector:selector];
    
    return invocation;
}

- (void) observeEventType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block
{
    [self validate];
    
    _invocation = [self invocationWithSelector:_cmd];
    [_invocation setArgument:&eventType atIndex:2];
    [_invocation setArgument:&block atIndex:3];
    
    [_invocation retainArguments];
}

- (void) observeEventType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block
{
    [self validate];
    
    _invocation = [self invocationWithSelector:_cmd];
    [_invocation setArgument:&eventType atIndex:2];
    [_invocation setArgument:&block atIndex:3];
    
    [_invocation retainArguments];
}

- (void) observeEventType:(FEventType)eventType withBlock:(void (^)(FDataSnapshot* snapshot))block withCancelBlock:(void (^)(NSError* error))cancelBlock
{
    [self validate];
    
    _invocation = [self invocationWithSelector:_cmd];
    [_invocation setArgument:&eventType atIndex:2];
    [_invocation setArgument:&block atIndex:3];
    [_invocation setArgument:&cancelBlock atIndex:4];
    
    [_invocation retainArguments];
}

- (void) observeEventType:(FEventType)eventType andPreviousSiblingNameWithBlock:(void (^)(FDataSnapshot* snapshot, NSString* prevName))block withCancelBlock:(void (^)(NSError* error))cancelBlock
{
    [self validate];
    
    _invocation = [self invocationWithSelector:_cmd];
    [_invocation setArgument:&eventType atIndex:2];
    [_invocation setArgument:&block atIndex:3];
    [_invocation setArgument:&cancelBlock atIndex:4];
    
    [_invocation retainArguments];
}

@end
