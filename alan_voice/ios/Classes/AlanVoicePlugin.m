//
//  AlanVoicePlugin.m
//  Alan Voice Plugin for Flutter
//
//  Created by Sergey Yuryev on 03.03.2020.
//  Copyright © 2020 Alan AI. All rights reserved.
//

@import AlanSDK;

#import "AlanVoicePlugin.h"

static NSString * const ARGUMENT_LOG_LEVEL = @"logLevel";
static NSString * const ARGUMENT_PROJECT_SERVER = @"projectServer";
static NSString * const ARGUMENT_PROJECT_ID = @"projectId";
static NSString * const ARGUMENT_PROJECT_DIALOG_ID = @"projectDialogId";
static NSString * const ARGUMENT_PROJECT_AUTH_JSON = @"projectAuthJson";
static NSString * const ARGUMENT_PROJECT_PLUGIN_VERSION = @"wrapperVersion";
static NSString * const ARGUMENT_VISUALS = @"visuals";
static NSString * const ARGUMENT_TEXT = @"text";
static NSString * const ARGUMENT_COMMAND = @"command";
static NSString * const ARGUMENT_METHOD_NAME = @"method_name";
static NSString * const ARGUMENT_METHOD_ARGS = @"method_args";

@interface AlanStreamHandler : NSObject<FlutterStreamHandler>
@property (nonatomic) FlutterEventSink emitter;
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events;
- (FlutterError*)onCancelWithArguments:(id)arguments;
- (void)newButtonState:(NSString*)state;
- (void)newCommand:(NSString*)payload;
@end

@implementation AlanStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events
{
    self.emitter = events;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments
{
    self.emitter = nil;
    return nil;
}

- (void)newButtonState:(NSString*)state
{
    if( self.emitter == nil )
    {
        return;
    }
    self.emitter(@[@"button_state_changed", state]);
}

- (void)newCommand:(NSString*)payload
{
    if( self.emitter == nil )
    {
        return;
    }
    if( payload == nil )
    {
        return;
    }
    self.emitter(@[@"command", payload]);
}

- (void)newEvent:(NSString*)event payload:(NSString*)payload
{
    if( self.emitter == nil )
    {
        return;
    }
    if( payload == nil )
    {
        return;
    }
    self.emitter(@[@"event", event, payload]);
}

- (void)onButtonState:(NSString*)state
{
    if( self.emitter == nil )
    {
        return;
    }
    self.emitter(@[@"onButtonState", state]);
}

- (void)onCommand:(NSString*)payload
{
    if( self.emitter == nil )
    {
        return;
    }
    if( payload == nil )
    {
        return;
    }
    self.emitter(@[@"onCommand", payload]);
}

- (void)onEvent:(NSString*)payload
{
    if( self.emitter == nil )
    {
        return;
    }
    if( payload == nil )
    {
        return;
    }
    self.emitter(@[@"onEvent", payload]);
}

@end

@interface AlanVoicePlugin()

/// Alan Button
@property (nonatomic) AlanButton* button;
/// Alan Text
@property (nonatomic) AlanText* text;
/// Event stream handler
@property (nonatomic) AlanStreamHandler* streamHandler;

@end

@implementation AlanVoicePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
    FlutterEventChannel* callBackChannel = [FlutterEventChannel eventChannelWithName:@"alan_voice_callback" binaryMessenger:[registrar messenger]];
    AlanStreamHandler* streamHandler = [[AlanStreamHandler alloc] init];
    [callBackChannel setStreamHandler:streamHandler];
    
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"alan_voice" binaryMessenger:[registrar messenger]];
    AlanVoicePlugin* instance = [[AlanVoicePlugin alloc] initWithStreamHandler: streamHandler];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithStreamHandler:(AlanStreamHandler*)streamHandler
{
    self = [super init];
    if (self)
    {
        self.streamHandler = streamHandler;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( [@"getPlatformVersion" isEqualToString:call.method] )
    {
        [self getPlatformVersionWithCall:call result:result];
    }
    else if( [@"getVersion" isEqualToString:call.method] )
    {
        [self getPlatformVersionWithCall:call result:result];
    }
    else if( [@"addButton" isEqualToString:call.method] )
    {
        [self addButtonWithCall:call result:result];
    }
    else if( [@"setLogLevel" isEqualToString:call.method] )
    {
        [self setLogLevelWithCall:call result:result];
    }
    else if( [@"showButton" isEqualToString:call.method] )
    {
        [self showButtonWithCall:call result:result];
    }
    else if( [@"hideButton" isEqualToString:call.method] )
    {
        [self hideButtonWithCall:call result:result];
    }
    else if( [@"activate" isEqualToString:call.method] )
    {
        [self activateWithCall:call result:result];
    }
    else if( [@"deactivate" isEqualToString:call.method] )
    {
        [self deactivateWithCall:call result:result];
    }
    else if( [@"isActive" isEqualToString:call.method] )
    {
        [self isActiveWithCall:call result:result];
    }
    else if( [@"callProjectApi" isEqualToString:call.method] )
    {
        [self callProjectApiWithCall:call result:result];
    }
    else if( [@"setVisualState" isEqualToString:call.method] )
    {
        [self setVisualStateWithCall:call result:result];
    }
    else if( [@"playText" isEqualToString:call.method] )
    {
        [self playTextWithCall:call result:result];
    }
    else if( [@"playCommand" isEqualToString:call.method] )
    {
        [self playCommandWithCall:call result:result];
    }
    else
    {
        result(FlutterMethodNotImplemented);
    }
}


// MARK: - Plugin methods implementation

- (void)getPlatformVersionWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }
    
    NSString* baseVersion = [NSString stringWithFormat:@"AlanBase: %@", [self.button getVersion]];
    NSString* sdkVersion = [NSString stringWithFormat:@"SDK version: %@", [self.button getSDKVersion]];
    NSString* versionString = [NSString stringWithFormat:@"%@\n%@", baseVersion, sdkVersion];

    result(versionString);
}

- (void)getVersionWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
}

- (void)setLogLevelWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    NSString* logLevel = call.arguments[ARGUMENT_LOG_LEVEL];
    
    if( logLevel == nil  || [logLevel isKindOfClass:[NSNull class]])
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"No logLevel, please provide logLevel argument" details:nil]);
        return;
    }

    NSString* level = [NSString stringWithFormat:@"%@", logLevel];
    if( [level isEqualToString: @"all"] )
    {
        [AlanLog setEnableLogging:YES];
    }
    else
    {
        [AlanLog setEnableLogging:NO];
    }
    
    /// Return success result to flutter
    result([NSNumber numberWithBool:YES]);
}

- (void)addButtonWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    /// Check Alan Button - remove it if it is already created
    if( self.button != nil )
    {
        [self removeButton];
    }

    /// Get params from flutter call
    NSString* projectId = call.arguments[ARGUMENT_PROJECT_ID];
    //NSString* dialogId = call.arguments[ARGUMENT_PROJECT_DIALOG_ID];
    NSString* server = call.arguments[ARGUMENT_PROJECT_SERVER];
    NSString* authJson = call.arguments[ARGUMENT_PROJECT_AUTH_JSON];
    NSString* plugin = call.arguments[ARGUMENT_PROJECT_PLUGIN_VERSION];
    NSDictionary* authDict = [self dictionaryFromString: authJson];
    
    /// At least we should have project Id
    if( projectId == nil  || [projectId isKindOfClass:[NSNull class]])
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"No objectId, please provide objectId argument" details:nil]);
        return;
    }
    
    /// If host is precified it should be not null
    if( [server isKindOfClass:[NSNull class]])
    {
        server = nil;
    }

    /// Get view controller for Alan Button
    UIViewController* rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;

    /// Alan Config setup - project Id, server, dialog Id, data object
    NSString* key = [NSString stringWithFormat:@"%@", projectId];
    NSString* host = server ? [NSString stringWithFormat:@"%@", server] : server;
    NSString* version = [NSString stringWithFormat:@"%@", plugin];
    NSDictionary* dataObject = [[NSDictionary alloc] initWithDictionary:authDict];
    AlanConfig *config = [[AlanConfig alloc] initWithKey:key host:host dataObject:dataObject platform:@"flutter" platformVersion:version];

    /// Alan Button setup - config, position
    self.button = [[AlanButton alloc] initWithConfig:config];
    [self.button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [rootViewController.view addSubview:self.button];
    [rootViewController.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-40.0],
        [NSLayoutConstraint constraintWithItem:self.button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeRight multiplier:1 constant:-20],
        [NSLayoutConstraint constraintWithItem:self.button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:64.0],
        [NSLayoutConstraint constraintWithItem:self.button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:64.0]
    ]];

    /// Alan Text setup - position
    self.text = [[AlanText alloc] initWithFrame:CGRectZero];
    [self.text setTranslatesAutoresizingMaskIntoConstraints:NO];
    [rootViewController.view addSubview:self.text];
    [rootViewController.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.text attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-40.0],
        [NSLayoutConstraint constraintWithItem:self.text attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeRight multiplier:1 constant:-20],
        [NSLayoutConstraint constraintWithItem:self.text attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:rootViewController.view attribute:NSLayoutAttributeLeft multiplier:1 constant:20.0],
        [NSLayoutConstraint constraintWithItem:self.text attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:64.0]
    ]];
    
    __weak typeof(self) weakSelf = self;
    
    self.button.onEvent = ^(NSString* payload) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf)
        {
            [strongSelf.streamHandler onEvent:payload];
        }
    };
    
    self.button.onCommand = ^(NSDictionary *command) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf)
        {
            NSString* payload = [strongSelf stringFromDictionary:command];
            if( payload == nil )
            {
                return;
            }
            [strongSelf.streamHandler onCommand:payload];
        }
    };
    
    self.button.onButtonState = ^(AlanSDKButtonState state) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf)
        {
            NSString* stringState = [strongSelf stateToString:state];
            [strongSelf.streamHandler onButtonState:stringState];
        }
    };

    /// Setup command handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:@"kAlanSDKEventNotification" object:nil];
    
    /// Setup button state handler
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buttonStateNotification:) name:@"kAlanSDKAlanButtonStateNotification" object:nil];

    /// Return success result to flutter
    result([NSNumber numberWithBool:YES]);
}

- (void)removeButtonWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    [self removeButton];
    result([NSNumber numberWithBool:YES]);
}

-(void)removeButton
{
    [self.button removeFromSuperview];
    self.button = nil;
    [self.text removeFromSuperview];
    self.text = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showButtonWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    self.button.hidden = NO;
    result([NSNumber numberWithBool:YES]);
}

- (void)hideButtonWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    self.button.hidden = YES;
    result([NSNumber numberWithBool:YES]);
}

- (void)activateWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    [self.button activate];
    result([NSNumber numberWithBool:YES]);
}

- (void)deactivateWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    [self.button deactivate];
    result([NSNumber numberWithBool:YES]);
}

- (void)isActiveWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    BOOL isActive = [self.button isActive];
    result([NSNumber numberWithBool:isActive]);
}

- (void)callProjectApiWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    NSString* method = call.arguments[ARGUMENT_METHOD_NAME];
    if( method == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide method name" details:nil]);
        return;
    }

    NSString* params = call.arguments[ARGUMENT_METHOD_ARGS];
    if( params == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide arguments" details:nil]);
        return;
    }

    NSDictionary* data = [self dictionaryFromString: params];
    if( data == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide correct params" details:nil]);
        return;
    }

    [self.button callProjectApi:method withData:data callback:^(NSError *error, NSString *object) {
        if( error )
        {
            result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"API error" details:nil]);
        }
        else if( object )
        {
            result(@[method, object, @""]);
        }
        else
        {
            result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"API error" details:nil]);
        }
    }];
}

- (void)setVisualStateWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    NSString* string = call.arguments[ARGUMENT_VISUALS];
    if( string == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide data" details:nil]);
        return;
    }

    NSDictionary* data = [self dictionaryFromString: string];
    if( data == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide correct data" details:nil]);
        return;
    }

    [self.button setVisualState:data];
    result([NSNumber numberWithBool:YES]);
}

- (void)playTextWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    NSString* text = call.arguments[ARGUMENT_TEXT];
    if( text == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide text" details:nil]);
        return;
    }

    [self.button playText:text];
    result([NSNumber numberWithBool:YES]);
}

- (void)playCommandWithCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if( self.button == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Alan Button unavailable" details:nil]);
        return;
    }

    NSString* string = call.arguments[ARGUMENT_COMMAND];
    if( string == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide data" details:nil]);
        return;
    }

    NSDictionary* data = [self dictionaryFromString: string];
    if( data == nil )
    {
        result([FlutterError errorWithCode:@"UNAVAILABLE" message:@"Provide correct data" details:nil]);
        return;
    }

    [self.button playCommand:data];
    result(@[@"", @"", @""]);
}

- (void)handleEvent:(NSNotification*)notification
{
    NSDictionary* userInfo = notification.userInfo;
    if( userInfo == nil)
    {
        return;
    }

    NSString* jsonString = [userInfo objectForKey:@"jsonString"];
    if( jsonString == nil)
    {
        return;
    }
    
    NSString* event = [userInfo objectForKey:@"onEvent"];
    if( event != nil)
    {
        [self.streamHandler newEvent:event payload:jsonString];
    }
    
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = nil;
    id unwrapped = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if( error != nil)
    {
        return;
    }
    if( ![unwrapped isKindOfClass:[NSDictionary class]] )
    {
        return;
    }

    NSDictionary* d = [NSDictionary dictionaryWithDictionary:unwrapped];
    NSDictionary* data = [d objectForKey:@"data"];
    if( data == nil )
    {
        return;
    }

    NSString* payload = [self stringFromDictionary:data];
    if( payload == nil )
    {
        return;
    }
    [self.streamHandler newCommand:payload];
}

- (void)buttonStateNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;

    if( userInfo )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNumber *state = [userInfo objectForKey:@"onButtonState"];
            AlanSDKButtonState buttonState = [state integerValue];
            NSString* stringState = [self stateToString:buttonState];
            [self.streamHandler newButtonState:stringState];
        });
    }
}

// MARK: - Utils

- (NSDictionary *)dictionaryFromString:(NSString*)string
{
    if( string == nil || [string isKindOfClass:[NSNull class]])
    {
        return nil;
    }
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (NSString *)stringFromDictionary:(NSDictionary*)dictionary
{
    if( dictionary == nil || [dictionary isKindOfClass:[NSNull class]])
    {
        return nil;
    }
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    if( !jsonData )
    {
        return nil;
    }
    else
    {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (NSString*)stateToString:(AlanSDKButtonState)state
{
    switch (state)
    {
        case AlanSDKButtonStateOffline:
            return @"OFFLINE";
        case AlanSDKButtonStateConnecting:
            return @"CONNECTING";
        case AlanSDKButtonStateListen:
            return @"LISTEN";
        case AlanSDKButtonStateProcess:
            return @"PROCESS";
        case AlanSDKButtonStateReply:
            return @"REPLY";
        case AlanSDKButtonStateOnline:
            return @"ONLINE";
        case AlanSDKButtonStateIdle:
            return @"IDLE";
        default:
            return @"UNKNOWN";
            
    }
}

@end
