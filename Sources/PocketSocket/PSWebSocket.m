#import "PSWebSocket.h"
#import "PSWebSocketDriver.h"
#import "PSWebSocketBuffer.h"
#import <Security/Security.h>
#import <CFNetwork/CFNetwork.h>

@interface PSWebSocket () <NSStreamDelegate, PSWebSocketDriverDelegate> {
    PSWebSocketMode _mode;
    NSMutableURLRequest *_request;
    dispatch_queue_t _workQueue;
    PSWebSocketDriver *_driver;
    PSWebSocketBuffer *_inputBuffer;
    PSWebSocketBuffer *_outputBuffer;
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    PSWebSocketReadyState _readyState;
    BOOL _secure;
    BOOL _negotiatedSSL;
    BOOL _opened;
    BOOL _closeWhenFinishedOutput;
    BOOL _sentClose;
    BOOL _failed;
    BOOL _pumpingInput;
    BOOL _pumpingOutput;
    NSInteger _closeCode;
    NSString *_closeReason;
    NSMutableArray *_pingHandlers;
}
@end

@implementation PSWebSocket

#pragma mark - Class Methods

+ (BOOL)isWebSocketRequest:(NSURLRequest *)request {
    return [PSWebSocketDriver isWebSocketRequest:request];
}

#pragma mark - Properties

@synthesize inputPaused = _inputPaused, outputPaused = _outputPaused;

- (PSWebSocketReadyState)readyState {
    __block PSWebSocketReadyState value;
    [self executeWorkAndWait:^{
        value = _readyState;
    }];
    return value;
}

#pragma mark - Initialization

+ (instancetype)clientSocketWithRequest:(NSURLRequest *)request {
    return [[self alloc] initClientSocketWithRequest:request];
}

- (instancetype)initClientSocketWithRequest:(NSURLRequest *)request {
    if((self = [super init])) {
        _mode = PSWebSocketModeClient;
        _request = [request mutableCopy];
        _readyState = PSWebSocketReadyStateConnecting;
        _workQueue = dispatch_queue_create("com.pocketsocket.websocket", DISPATCH_QUEUE_SERIAL);
        _driver = [PSWebSocketDriver clientDriverWithRequest:_request];
        _driver.delegate = self;
        _secure = [_request.URL.scheme hasPrefix:@"https"] || [_request.URL.scheme hasPrefix:@"wss"];
        _negotiatedSSL = YES;
        _inputBuffer = [[PSWebSocketBuffer alloc] init];
        _outputBuffer = [[PSWebSocketBuffer alloc] init];
        _pingHandlers = [NSMutableArray array];
        [self setupStreams];
    }
    return self;
}

- (void)setupStreams {
    NSURL *URL = _request.URL;
    NSString *host = URL.host;
    UInt32 port = (UInt32)(URL.port.integerValue ?: (_secure ? 443 : 80));
    
    NSInputStream *input;
    NSOutputStream *output;
    [NSStream getStreamsToHostWithName:host port:port inputStream:&input outputStream:&output];
    _inputStream = input;
    _outputStream = output;
    
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

#pragma mark - Actions

- (void)open {
    [self executeWork:^{
        if (_opened || _readyState != PSWebSocketReadyStateConnecting) return;
        _opened = YES;
        [_driver start];
        [_inputStream open];
        [_outputStream open];
        [self pumpInput];
        [self pumpOutput];
    }];
}

- (void)send:(id)message {
    NSParameterAssert(message);
    [self executeWork:^{
        if(_readyState != PSWebSocketReadyStateOpen) return;
        if([message isKindOfClass:[NSString class]]) {
            [_driver sendText:message];
        } else if([message isKindOfClass:[NSData class]]) {
            [_driver sendBinary:message];
        }
    }];
}

- (void)ping:(NSData *)pingData handler:(void (^)(NSData *pongData))handler {
    [self executeWork:^{
        if(handler) [_pingHandlers addObject:handler];
        [_driver sendPing:pingData];
    }];
}

- (void)close {
    [self closeWithCode:1000 reason:nil];
}

- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason {
    [self executeWork:^{
        if(_readyState >= PSWebSocketReadyStateClosing) return;
        _readyState = PSWebSocketReadyStateClosing;
        _closeCode = code;
        _closeReason = reason;
        [_driver sendCloseCode:code reason:reason];
        [self disconnectGracefully];
    }];
}

#pragma mark - Pumping

- (void)pumpInput {
    if (_pumpingInput || _inputPaused || _readyState >= PSWebSocketReadyStateClosing) return;
    _pumpingInput = YES;
    uint8_t buffer[4096];
    NSInteger len = [_inputStream read:buffer maxLength:sizeof(buffer)];
    if(len > 0) [_driver execute:buffer maxLength:len];
    _pumpingInput = NO;
}

- (void)pumpOutput {
    if (_pumpingOutput || _outputPaused) return;
    _pumpingOutput = YES;
    if(_outputBuffer.hasBytesAvailable) {
        NSInteger len = [_outputStream write:_outputBuffer.bytes maxLength:_outputBuffer.bytesAvailable];
        _outputBuffer.offset += len;
    }
    _pumpingOutput = NO;
}

#pragma mark - Stream Delegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
    switch(event) {
        case NSStreamEventOpenCompleted: break;
        case NSStreamEventHasBytesAvailable: [self pumpInput]; break;
        case NSStreamEventHasSpaceAvailable: [self pumpOutput]; break;
        case NSStreamEventErrorOccurred: [self disconnect]; break;
        case NSStreamEventEndEncountered: [self disconnect]; break;
        default: break;
    }
}

#pragma mark - Disconnect

- (void)disconnectGracefully {
    _closeWhenFinishedOutput = YES;
    [self pumpOutput];
}

- (void)disconnect {
    [_inputStream close];
    [_outputStream close];
    [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    _inputStream.delegate = nil;
    _outputStream.delegate = nil;
}

#pragma mark - Helper Methods

- (void)executeWork:(void (^)(void))block {
    dispatch_async(_workQueue, block);
}

- (void)executeWorkAndWait:(void (^)(void))block {
    if (dispatch_get_specific((__bridge const void * _Nonnull)(_workQueue))) {
        block();
    } else {
        dispatch_sync(_workQueue, block);
    }
}

- (void)executeDelegate:(void (^)(void))block {
    dispatch_async(_delegateQueue ?: dispatch_get_main_queue(), block);
}

- (void)executeDelegateAndWait:(void (^)(void))block {
    dispatch_sync(_delegateQueue ?: dispatch_get_main_queue(), block);
}

- (void)notifyDelegateDidOpen {
    [self executeDelegate:^{ [_delegate webSocketDidOpen:self]; }];
}

- (void)notifyDelegateDidReceiveMessage:(id)message {
    [self executeDelegate:^{ [_delegate webSocket:self didReceiveMessage:message]; }];
}

- (void)notifyDelegateDidFailWithError:(NSError *)error {
    [self executeDelegate:^{ [_delegate webSocket:self didFailWithError:error]; }];
}

- (void)notifyDelegateDidCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self executeDelegate:^{ [_delegate webSocket:self didCloseWithCode:code reason:reason wasClean:wasClean]; }];
}

- (void)notifyDelegateDidFlushInput {
    [self executeDelegate:^{ if ([_delegate respondsToSelector:@selector(webSocketDidFlushInput:)]) [_delegate webSocketDidFlushInput:self]; }];
}

- (void)notifyDelegateDidFlushOutput {
    [self executeDelegate:^{ if ([_delegate respondsToSelector:@selector(webSocketDidFlushOutput:)]) [_delegate webSocketDidFlushOutput:self]; }];
}

#pragma mark - Dealloc

- (void)dealloc {
    [self disconnect];
}

@end
