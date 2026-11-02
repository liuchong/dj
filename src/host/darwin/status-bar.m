/* AppKit projection only. Service control belongs to the Eliscript backend. */
#import <AppKit/AppKit.h>
#import <CoreServices/CoreServices.h>
#import <sys/file.h>
#import <fcntl.h>
#import <unistd.h>
#import <signal.h>

static NSImage *DJMenuIcon(void) {
    NSImage *image = [NSImage imageWithSize:NSMakeSize(20,20) flipped:YES drawingHandler:^BOOL(NSRect bounds) {
        [NSGraphicsContext saveGraphicsState];
        NSAffineTransform *scale = [NSAffineTransform transform];
        [scale scaleXBy:bounds.size.width / 128.0 yBy:bounds.size.height / 128.0]; [scale concat];
        [NSColor.blackColor setStroke]; [NSColor.blackColor setFill];
        NSBezierPath *links = [NSBezierPath bezierPath]; links.lineWidth = 7;
        links.lineCapStyle = NSLineCapStyleRound; links.lineJoinStyle = NSLineJoinStyleRound;
        [links moveToPoint:NSMakePoint(14,18)]; [links lineToPoint:NSMakePoint(29,18)];
        [links lineToPoint:NSMakePoint(99,110)]; [links lineToPoint:NSMakePoint(114,110)];
        [links moveToPoint:NSMakePoint(14,110)]; [links lineToPoint:NSMakePoint(29,110)];
        [links lineToPoint:NSMakePoint(99,18)]; [links lineToPoint:NSMakePoint(114,18)]; [links stroke];
        NSBezierPath *discs = [NSBezierPath bezierPath]; discs.lineWidth = 3;
        [discs appendBezierPathWithOvalInRect:NSMakeRect(9,40,48,48)];
        [discs appendBezierPathWithOvalInRect:NSMakeRect(71,40,48,48)]; [discs stroke];
        NSBezierPath *letters = [NSBezierPath bezierPath]; letters.lineWidth = 6;
        letters.lineCapStyle = NSLineCapStyleRound; letters.lineJoinStyle = NSLineJoinStyleRound;
        [letters moveToPoint:NSMakePoint(22,49)]; [letters lineToPoint:NSMakePoint(31,49)];
        [letters curveToPoint:NSMakePoint(48,64) controlPoint1:NSMakePoint(41,49) controlPoint2:NSMakePoint(48,54)];
        [letters curveToPoint:NSMakePoint(31,79) controlPoint1:NSMakePoint(48,74) controlPoint2:NSMakePoint(41,79)];
        [letters lineToPoint:NSMakePoint(22,79)]; [letters closePath];
        [letters moveToPoint:NSMakePoint(88,49)]; [letters lineToPoint:NSMakePoint(105,49)]; [letters lineToPoint:NSMakePoint(105,67)];
        [letters curveToPoint:NSMakePoint(90,82) controlPoint1:NSMakePoint(105,77) controlPoint2:NSMakePoint(100,82)];
        [letters lineToPoint:NSMakePoint(84,82)]; [letters stroke];
        NSBezierPath *junction = [NSBezierPath bezierPath];
        [junction moveToPoint:NSMakePoint(64,54)]; [junction lineToPoint:NSMakePoint(74,64)];
        [junction lineToPoint:NSMakePoint(64,74)]; [junction lineToPoint:NSMakePoint(54,64)]; [junction closePath]; [junction fill];
        [NSGraphicsContext restoreGraphicsState]; return YES;
    }];
    image.template = YES; return image;
}

@interface DJControlView : NSView
@property(weak) NSPopover *popover;
@end
@implementation DJControlView
- (BOOL)acceptsFirstResponder { return YES; }
- (void)cancelOperation:(id)sender { (void)sender; [self.popover performClose:nil]; }
@end

@interface DJStatusBar : NSObject <NSApplicationDelegate, NSPopoverDelegate>
@property NSStatusItem *item;
@property NSTextField *statusLine;
@property NSTextField *detailLine;
@property NSButton *startItem;
@property NSButton *stopItem;
@property NSPopover *controllerPanel;
@property NSTask *backend;
@property NSPipe *commands;
@property NSMutableData *buffer;
@property NSString *root;
@property int lockFD;
@end

@implementation DJStatusBar
- (void)showStatus:(NSDictionary *)status {
    NSString *label = [status[@"label"] isKindOfClass:NSString.class] ? status[@"label"] : @"控制器异常";
    NSString *detail = [status[@"detail"] isKindOfClass:NSString.class] ? status[@"detail"] : @"";
    NSString *statusTitle = [@"服务：" stringByAppendingString:label];
    NSString *detailTitle = detail.length ? detail : @"只控制本机 DJ，不启动 AI 客户端";
    if (![self.statusLine.stringValue isEqual:statusTitle]) self.statusLine.stringValue = statusTitle;
    if (![self.detailLine.stringValue isEqual:detailTitle]) self.detailLine.stringValue = detailTitle;
    self.startItem.enabled = [status[@"can_start"] boolValue];
    self.stopItem.enabled = [status[@"can_stop"] boolValue];
    if (![self.item.button.toolTip isEqual:statusTitle]) self.item.button.toolTip = statusTitle;
}
- (NSButton *)panelButton:(NSString *)title action:(SEL)action parent:(NSView *)parent y:(CGFloat)y {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:action];
    button.frame = NSMakeRect(16,y,268,27); button.bezelStyle = NSBezelStyleRounded;
    [parent addSubview:button]; return button;
}
- (NSTextField *)panelLabel:(NSString *)title parent:(NSView *)parent y:(CGFloat)y size:(CGFloat)size {
    NSTextField *label = [NSTextField labelWithString:title];
    label.frame = NSMakeRect(16,y,268,23); label.font = [NSFont systemFontOfSize:size];
    label.lineBreakMode = NSLineBreakByTruncatingTail; [parent addSubview:label]; return label;
}
- (void)sendAction:(NSString *)action {
    if (!self.backend.running) return;
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"action":action} options:0 error:NULL];
    NSMutableData *line = [data mutableCopy]; [line appendBytes:"\n" length:1];
    @try { [self.commands.fileHandleForWriting writeData:line]; } @catch (NSException *ignored) { (void)ignored; }
}
- (void)startService:(id)sender { (void)sender; [self sendAction:@"start"]; }
- (void)stopService:(id)sender { (void)sender; [self sendAction:@"stop"]; }
- (void)refresh:(id)sender { (void)sender; [self sendAction:@"refresh"]; }
- (void)updatePanelState {
    self.item.button.accessibilityValue = self.controllerPanel.shown ? @"已展开" : @"已收起";
}
- (void)popoverDidShow:(NSNotification *)notification { (void)notification; [self updatePanelState]; }
- (void)popoverDidClose:(NSNotification *)notification { (void)notification; [self updatePanelState]; }
- (void)closePanel:(id)sender { (void)sender; [self.controllerPanel performClose:nil]; }
- (void)toggleMenu:(id)sender {
    (void)sender;
    if (self.controllerPanel.shown) { [self.controllerPanel performClose:nil]; return; }
    [self sendAction:@"refresh"];
    [self.controllerPanel showRelativeToRect:self.item.button.bounds ofView:self.item.button preferredEdge:NSMinYEdge];
    [self.controllerPanel.contentViewController.view.window makeKeyWindow];
    [self.controllerPanel.contentViewController.view.window makeFirstResponder:self.controllerPanel.contentViewController.view];
}
- (void)openConfiguration:(id)sender { (void)sender; [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:self.root isDirectory:YES]]; }
- (void)quit:(id)sender { (void)sender; [NSApp terminate:nil]; }
- (void)consume:(NSData *)data {
    [self.buffer appendData:data];
    if (self.buffer.length > 65536) { [self.backend terminate]; self.buffer.length = 0; return; }
    while (self.buffer.length) {
        const unsigned char *bytes = self.buffer.bytes;
        const unsigned char *end = memchr(bytes, '\n', self.buffer.length);
        if (!end) break;
        NSUInteger length = (NSUInteger)(end - bytes);
        NSData *line = [self.buffer subdataWithRange:NSMakeRange(0,length)];
        [self.buffer replaceBytesInRange:NSMakeRange(0,length+1) withBytes:NULL length:0];
        id status = [NSJSONSerialization JSONObjectWithData:line options:0 error:NULL];
        if ([status isKindOfClass:NSDictionary.class] && [status[@"type"] isEqual:@"status"] && self.backend.running)
            [self showStatus:status];
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    NSBundle *bundle = NSBundle.mainBundle;
    self.root = [bundle objectForInfoDictionaryKey:@"DJRootDirectory"];
    NSString *runtime = [bundle objectForInfoDictionaryKey:@"DJRuntimePath"];
    if (!self.root.length || !runtime.length) { [NSApp terminate:nil]; return; }
    NSString *lock = [[self.root stringByAppendingPathComponent:@"run"] stringByAppendingPathComponent:@"controller.lock"];
    self.lockFD = open(lock.fileSystemRepresentation, O_CREAT|O_RDWR|O_CLOEXEC|O_NOFOLLOW, 0600);
    if (self.lockFD < 0 || flock(self.lockFD, LOCK_EX|LOCK_NB) != 0) { [NSApp terminate:nil]; return; }
    self.item = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    self.item.autosaveName = @"DJ.ServiceController";
    self.item.visible = YES;
    self.item.button.image = DJMenuIcon();
    self.item.button.accessibilityLabel = @"DJ 服务控制器";
    self.controllerPanel = [NSPopover new];
    self.controllerPanel.delegate = self;
    self.controllerPanel.behavior = NSPopoverBehaviorApplicationDefined;
    self.controllerPanel.animates = NO;
    NSViewController *content = [NSViewController new];
    DJControlView *view = [[DJControlView alloc] initWithFrame:NSMakeRect(0,0,300,290)];
    view.popover = self.controllerPanel; content.view = view;
    view.accessibilityLabel = @"DJ 服务控制面板";
    [self panelLabel:@"Dispatch Junction" parent:view y:255 size:15];
    self.statusLine = [self panelLabel:@"服务：检查中" parent:view y:229 size:13];
    self.detailLine = [self panelLabel:@"" parent:view y:205 size:11];
    self.detailLine.textColor = NSColor.secondaryLabelColor;
    self.startItem = [self panelButton:@"启动服务" action:@selector(startService:) parent:view y:168];
    self.stopItem = [self panelButton:@"停止服务" action:@selector(stopService:) parent:view y:135];
    [self panelButton:@"立即刷新" action:@selector(refresh:) parent:view y:102];
    [self panelButton:@"打开 DJ 配置目录" action:@selector(openConfiguration:) parent:view y:69];
    NSButton *close = [self panelButton:@"收起" action:@selector(closePanel:) parent:view y:36];
    close.keyEquivalent = @"\033";
    [self panelButton:@"退出控制器（服务继续运行）" action:@selector(quit:) parent:view y:3];
    self.controllerPanel.contentViewController = content;
    self.controllerPanel.contentSize = view.frame.size;
    [self updatePanelState];
    self.item.button.target = self; self.item.button.action = @selector(toggleMenu:);
    [self.item.button sendActionOn:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown];
    NSMenu *mainMenu = [NSMenu new], *appMenu = [NSMenu new];
    NSMenuItem *appEntry = [[NSMenuItem alloc] initWithTitle:@"DJ Control" action:NULL keyEquivalent:@""];
    appEntry.submenu = appMenu; [mainMenu addItem:appEntry];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出控制器（服务继续运行）" action:@selector(quit:) keyEquivalent:@"q"];
    quit.target = self; [appMenu addItem:quit];
    NSApp.mainMenu = mainMenu;
    self.buffer = [NSMutableData data];
    [self showStatus:@{@"state":@"starting", @"label":@"检查中"}];
    self.commands = [NSPipe pipe]; NSPipe *output = [NSPipe pipe];
    self.backend = [[NSTask alloc] init];
    self.backend.executableURL = [NSURL fileURLWithPath:runtime];
    self.backend.arguments = @[[bundle.resourcePath stringByAppendingPathComponent:@"darwin/main.mjs"], self.root];
    self.backend.standardInput = self.commands; self.backend.standardOutput = output;
    self.backend.standardError = [NSFileHandle fileHandleWithNullDevice];
    __weak DJStatusBar *weakSelf = self;
    output.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = handle.availableData;
        if (!data.length) { handle.readabilityHandler = nil; return; }
        dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf consume:data]; });
    };
    self.backend.terminationHandler = ^(NSTask *task) {
        (void)task;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showStatus:@{@"state":@"error", @"label":@"控制器后端已退出", @"detail":@"退出控制器后重新打开；DJ 服务不受影响"}];
        });
    };
    NSError *error = nil;
    if (![self.backend launchAndReturnError:&error])
        [self showStatus:@{@"state":@"error", @"label":@"无法启动控制器后端", @"detail":@"请检查已安装的 Bun 运行时"}];
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)visible {
    (void)sender; (void)visible;
    self.item.visible = YES;
    return NO;
}
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    if (self.backend.running) [self.backend terminate];
    if (self.lockFD >= 0) close(self.lockFD);
}
@end

static DJStatusBar *statusDelegate;

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSURL *applications = [NSFileManager.defaultManager URLsForDirectory:NSApplicationDirectory inDomains:NSLocalDomainMask].firstObject;
        if (argc == 2 && strcmp(argv[1], "--application-directory") == 0) {
            if (!applications) return 1;
            puts(applications.path.fileSystemRepresentation); return 0;
        }
        if (argc == 2 && strcmp(argv[1], "--register-app") == 0)
            return LSRegisterURL((__bridge CFURLRef)NSBundle.mainBundle.bundleURL, true) == noErr ? 0 : 1;
        if (argc == 2 && strcmp(argv[1], "--quit-controller") == 0) {
            NSString *owned = [applications URLByAppendingPathComponent:@"DJ Control.app"].path;
            for (NSRunningApplication *running in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"dev.dispatch-junction.controller"]) {
                if (![running.bundleURL.path isEqual:owned]) continue;
                [running terminate];
                for (int wait = 0; wait < 100 && kill(running.processIdentifier, 0) == 0; wait++) [NSThread sleepForTimeInterval:0.05];
                if (kill(running.processIdentifier, 0) == 0) return 1;
            }
            return 0;
        }
        if (argc != 1) return 2;
        NSApplication *app = NSApplication.sharedApplication;
        statusDelegate = [DJStatusBar new]; statusDelegate.lockFD = -1;
        app.delegate = statusDelegate;
        [app run];
    }
    return 0;
}
