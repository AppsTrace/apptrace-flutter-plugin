#import "ApptraceFlutterPlugin.h"
#import <ApptraceSDK/ApptraceSDK.h>

static NSString * const kMethodGetInstall = @"getInstall";
static NSString * const kMethodRegisterWakeUp = @"registerWakeUp";
static NSString * const kMethodInit = @"init";
static NSString * const kMethodDisableClipboard = @"disableClipboard";

static NSString * const kOnFlutterInstallRspEvent = @"onInstallResponse";
static NSString * const kOnFlutterWakeUpRspEvent = @"onWakeUpResponse";

static NSString * const kCode = @"code";
static NSString * const kMsg = @"msg";
static NSString * const kParamsData = @"paramsData";

@interface ApptraceFlutterPlugin ()<ApptraceDelegate>

@property (nonatomic, strong) FlutterMethodChannel * methodChannel;
@property (nonatomic, strong) NSDictionary *wakeUpTraceDict;
@property (nonatomic, assign) BOOL hasRegisterWakeUp;
@property (nonatomic, assign) BOOL hasInit;
@property (nonatomic, strong) NSUserActivity *cacheUserActivity;

@end

@implementation ApptraceFlutterPlugin

+ (ApptraceFlutterPlugin *)shared {
    static ApptraceFlutterPlugin * sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ApptraceFlutterPlugin alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Private

- (void)_initSDK {
    ApptraceFlutterPlugin *plugin = [ApptraceFlutterPlugin shared];
    
    if (plugin.hasInit) {
        return;
    }
    
    [Apptrace initWithDelegate:plugin];
    
    plugin.hasInit = YES;
    
    if (plugin.cacheUserActivity) {
        [plugin _handleUniversalLink:plugin.cacheUserActivity];
        
        plugin.cacheUserActivity = nil;
    }
}

- (void)_getInstall {
    ApptraceFlutterPlugin *plugin = [ApptraceFlutterPlugin shared];
    
    [Apptrace getInstall:^(AppInfo * _Nullable appData) {
        if (appData == nil) {
            NSDictionary *ret = [ApptraceFlutterPlugin  _parseToResultDict:-1 msg:@"Extract data fail." paramsData:@""];
            
            [plugin _dispatchEventToFlutter:kOnFlutterInstallRspEvent result:ret];
            
            return;
        }
        
        NSDictionary *ret = [ApptraceFlutterPlugin _parseToResultDict:200 msg:@"Success" paramsData:appData.paramsData];
        
        [plugin _dispatchEventToFlutter:kOnFlutterInstallRspEvent result:ret];
    } fail:^(NSInteger code, NSString * _Nonnull message) {
        NSDictionary *ret = [ApptraceFlutterPlugin _parseToResultDict:code msg:message paramsData:@""];
        
        [plugin _dispatchEventToFlutter:kOnFlutterInstallRspEvent result:ret];
    }];
}

- (void)_registerWakeUp {
    ApptraceFlutterPlugin *plugin = [ApptraceFlutterPlugin shared];
    
    plugin.hasRegisterWakeUp = YES;
    
    if (plugin.wakeUpTraceDict.count > 0) {
        [plugin _dispatchEventToFlutter:kOnFlutterWakeUpRspEvent result:plugin.wakeUpTraceDict];
        
        plugin.wakeUpTraceDict = nil;
    }
}

- (BOOL)_handleUniversalLink:(NSUserActivity * _Nullable)userActivity {
    ApptraceFlutterPlugin *plugin = [ApptraceFlutterPlugin shared];
    
    if (plugin.hasInit) {
        return [Apptrace handleUniversalLink:userActivity];
    } else {
        plugin.cacheUserActivity = userActivity;
        
        return NO;
    }
}

- (void)_dispatchEventToFlutter:(NSString *)method result:(NSDictionary *)result {
    [self.methodChannel invokeMethod:method arguments:result];
}

+ (NSDictionary *)_parseToResultDict:(NSInteger)code 
                                 msg:(NSString *)msg
                          paramsData:(NSString *)paramsData {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    dict[kCode] = [@(code) stringValue];
    dict[kMsg] = msg ?: @"";
    dict[kParamsData] = paramsData ?: @"";
    
    return dict;
}

#pragma mark - ApptraceDelegate

- (void)handleWakeUp:(AppInfo *)appData {
    if (appData == nil) {
        return;
    }
    
    NSDictionary *ret = [ApptraceFlutterPlugin _parseToResultDict:200 msg:@"Success" paramsData:appData.paramsData];
    
    ApptraceFlutterPlugin *plugin = [ApptraceFlutterPlugin shared];
    
    if (plugin.hasRegisterWakeUp) {
        [plugin _dispatchEventToFlutter:kOnFlutterWakeUpRspEvent result:ret];
        
        plugin.wakeUpTraceDict = nil;
    } else {
        plugin.wakeUpTraceDict = ret;
    }
}

#pragma mark - FlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"apptrace_flutter_plugin" binaryMessenger:[registrar messenger]];
    ApptraceFlutterPlugin *plugin = [ApptraceFlutterPlugin shared];
    plugin.methodChannel = channel;
    
    [registrar addApplicationDelegate:plugin];
    [registrar addMethodCallDelegate:plugin channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([kMethodGetInstall isEqualToString:call.method]) {
        [self _getInstall];
    } else if ([kMethodRegisterWakeUp isEqualToString:call.method]) {
        [self _registerWakeUp];
    } else if ([kMethodInit isEqualToString:call.method]) {
        BOOL enableClipboard = YES;
        
        if ([call.arguments isKindOfClass:[NSDictionary class]]) {
            NSNumber *enableClipboardNumberValue = [call.arguments objectForKey:@"enableClipboard"];
            if ([enableClipboardNumberValue isKindOfClass:[NSNumber class]]) {
                enableClipboard = enableClipboardNumberValue.boolValue;
            }
        }
        if (!enableClipboard) {
            [Apptrace disableClipboard];
        }
        
        [self _initSDK];
    } else if ([kMethodDisableClipboard isEqualToString:call.method]) {
        [Apptrace disableClipboard];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication*)application continueUserActivity:(NSUserActivity*)userActivity restorationHandler:(void (^)(NSArray*))restorationHandler {
    return [self _handleUniversalLink:userActivity];
}

@end
