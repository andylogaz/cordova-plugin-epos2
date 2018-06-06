#import "ePOS2Plugin.h"

#import <Cordova/CDVAvailability.h>

static NSDictionary *printerTypeMap;

@interface epos2Plugin()<Epos2DiscoveryDelegate, Epos2PtrReceiveDelegate>
@end

@implementation epos2Plugin

- (void)pluginInitialize
{
    printerTarget = nil;
    printerSeries = EPOS2_TM_M10;
    lang = EPOS2_MODEL_ANK;

    printerTypeMap = @{
        @"TM-M10":    [NSNumber numberWithInt:EPOS2_TM_M10],
        @"TM-M30":    [NSNumber numberWithInt:EPOS2_TM_M30],
        @"TM-P10":    [NSNumber numberWithInt:EPOS2_TM_P20],
        @"TM-P60":    [NSNumber numberWithInt:EPOS2_TM_P60],
        @"TM-P60II":  [NSNumber numberWithInt:EPOS2_TM_P60II],
        @"TM-P80":    [NSNumber numberWithInt:EPOS2_TM_P80],
        @"TM-T20":    [NSNumber numberWithInt:EPOS2_TM_T20],
        @"TM-T60":    [NSNumber numberWithInt:EPOS2_TM_T60],
        @"TM-T70":    [NSNumber numberWithInt:EPOS2_TM_T70],
        @"TM-T81":    [NSNumber numberWithInt:EPOS2_TM_T81],
        @"TM-T82":    [NSNumber numberWithInt:EPOS2_TM_T82],
        @"TM-T83":    [NSNumber numberWithInt:EPOS2_TM_T83],
        @"TM-T88":    [NSNumber numberWithInt:EPOS2_TM_T88],
        @"TM-T88VI":  [NSNumber numberWithInt:EPOS2_TM_T88],
        @"TM-T90":    [NSNumber numberWithInt:EPOS2_TM_T90],
        @"TM-T90KP":  [NSNumber numberWithInt:EPOS2_TM_T90KP],
        @"TM-U220":   [NSNumber numberWithInt:EPOS2_TM_U220],
        @"TM-U330":   [NSNumber numberWithInt:EPOS2_TM_U330],
        @"TM-L90":    [NSNumber numberWithInt:EPOS2_TM_L90],
        @"TM-H6000":  [NSNumber numberWithInt:EPOS2_TM_H6000]
    };
}

- (void)startDiscover:(CDVInvokedUrlCommand *)command
{
    self.discoverCallbackId = command.callbackId;

    // stop running discovery first
    int result = EPOS2_SUCCESS;

    while (YES) {
        result = [Epos2Discovery stop];

        if (result != EPOS2_ERR_PROCESSING) {
            break;
        }
    }

    NSLog(@"[epos2] startDiscover: %@", command.callbackId);

    Epos2FilterOption *filteroption_ = [[Epos2FilterOption alloc] init];
    [filteroption_ setDeviceType:EPOS2_TYPE_PRINTER];

    result = [Epos2Discovery start:filteroption_ delegate:self];
    if (EPOS2_SUCCESS != result) {
        NSLog(@"[epos2] Error in startDiscover()");
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in discovering printer."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void) onDiscovery:(Epos2DeviceInfo *)deviceInfo
{
    NSLog(@"[epos2] onDiscovery: %@ (%@)", [deviceInfo getTarget], [deviceInfo getDeviceName]);
    NSDictionary *info = @{
        @"target": [deviceInfo getTarget],
        @"deviceType": [NSNumber numberWithInt:[deviceInfo getDeviceType]],
        @"deviceName": [deviceInfo getDeviceName],
        @"ipAddress" : [deviceInfo getIpAddress],
        @"macAddress": [deviceInfo getMacAddress],
        @"bdAddress": [deviceInfo getBdAddress],
    };
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:self.discoverCallbackId];
}

- (void)stopDiscover:(CDVInvokedUrlCommand *)command
{
    NSLog(@"[epos2] stopDiscover()");
    int result = EPOS2_SUCCESS;

    while (YES) {
        result = [Epos2Discovery stop];

        if (result != EPOS2_ERR_PROCESSING) {
            break;
        }
    }

    if (EPOS2_SUCCESS != result) {
        NSLog(@"[epos2] Error in stopDiscover()");
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in stop discovering printer."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}


-(void)connectPrinter:(CDVInvokedUrlCommand *)command
{
    NSString* target = [command.arguments objectAtIndex:0];
    int typeEnum = -1;

    // device type is provided
    if ([command.arguments count] > 1) {
        // map device type string to EPOS2_* constant
        typeEnum = [self printerTypeFromString:[command.arguments objectAtIndex:1]];
        NSLog(@"[epos2] set printerSeries to %@ (%d)", [command.arguments objectAtIndex:1], typeEnum);
        if (typeEnum >= 0) {
            printerSeries = typeEnum;
        }
    }

    int result = EPOS2_SUCCESS;

    // select BT device from accessory list
    if ([target length] == 0) {
        Epos2BluetoothConnection *btConnection = [[Epos2BluetoothConnection alloc] init];
        NSMutableString *BDAddress = [[NSMutableString alloc] init];
        result = [btConnection connectDevice:BDAddress];
        if (result == EPOS2_SUCCESS) {
            target = BDAddress;
        } else {
            CDVPluginResult *cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in bluetooth connect."];
            [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
            return;
        }
    }

    NSLog(@"[epos2] connectPrinter(%@)", target);

    // store the provided target addrss
    printerTarget = target;

    if ([self _connectPrinter]) {
        CDVPluginResult *cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
        [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
    } else {
        CDVPluginResult *cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in connect  printer."];
        [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
    }
}

- (void)disconnectPrinter:(CDVInvokedUrlCommand *)command
{
    int result = EPOS2_SUCCESS;
    CDVPluginResult *cordovaResult = nil;

    if (printer == nil) {
        cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
        [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
        return;
    }

    result = [printer endTransaction];
    if (result != EPOS2_SUCCESS) {
        NSLog(@"[epos2] Error in Epos2Printer.endTransaction(): %d", result);
        cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in disconnectPrinter()"];
    }

    result = [printer disconnect];
    if (result != EPOS2_SUCCESS) {
        NSLog(@"[epos2] Error in Epos2Printer.disconnect(): %d", result);
        cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in disconnectPrinter()"];
    }
    [self finalizeObject];

    // return OK result
    if (cordovaResult == nil) {
        cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    }

    [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
}

-(BOOL)_connectPrinter
{
    int result = EPOS2_SUCCESS;

    if (printerTarget == nil) {
        return NO;
    }

    NSLog(@"[epos2] _connectPrinter() to %@", printerTarget);

    // initialize printer
    if (printer == nil) {
        printer = [[Epos2Printer alloc] initWithPrinterSeries:printerSeries lang:lang];
        [printer setReceiveEventDelegate:self];
    }

    result = [printer connect:printerTarget timeout:EPOS2_PARAM_DEFAULT];
    if (result != EPOS2_SUCCESS) {
        NSLog(@"[epos2] Error in Epos2Printer.connect(): %d", result);
        return NO;
    }

    result = [printer beginTransaction];
    if (result != EPOS2_SUCCESS) {
        NSLog(@"[epos2] Error in Epos2Printer.beginTransaction(): %d", result);
        [printer disconnect];
        return NO;
    }

    return YES;
}

- (void)finalizeObject
{
    if (printer == nil) {
        return;
    }

    [printer clearCommandBuffer];

    [printer setReceiveEventDelegate:nil];

    printer = nil;
}

- (void)onPtrReceive:(Epos2Printer *)printerObj code:(int)code status:(Epos2PrinterStatusInfo *)status printJobId:(NSString *)printJobId
{
    NSLog(@"[epos2] onPtrReceive; code: %d, status: %@, printJobId: %@", code, status, printJobId);

    [self disconnectPrinter:nil];
}

- (void)print:(CDVInvokedUrlCommand *)command
{
    Epos2PrinterStatusInfo *status = nil;

    self.printCallbackId = command.callbackId;

    // (re-)connect printer with stored information
    if (printer == nil) {
        if (![self _connectPrinter]) {
            CDVPluginResult *cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in print() command: printer not connected."];
            [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
            return;
        }
    }

    // check printer status
    status = [printer getStatus];

    if (![self isPrintable:status]) {
        CDVPluginResult *cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in print() command: printer is not ready."];
        [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
        return;
    }

    NSArray *printData = command.arguments;

    [self.commandDelegate runInBackground:^{
        int result = EPOS2_SUCCESS;

        for (NSString* data in printData) {
            // NSLog(@"%@", data);
            if ([data isEqualToString:@"\n"]) {
                result = [printer addFeedLine:1];
            } else {
                result = [printer addText:data];
            }

            if (result != EPOS2_SUCCESS) {
                break;
            }
        }

        if (result != EPOS2_SUCCESS) {
            return;
        }

        // feed paper
        result = [printer addFeedLine:3];
        if (result != EPOS2_SUCCESS) {
            NSLog(@"[epos2] Error in Epos2Printer.addFeedLine(): %d", result);
            return;
        }

        // send cut command
        result = [printer addCut:EPOS2_CUT_FEED];
        if (result != EPOS2_SUCCESS) {
            NSLog(@"[epos2] Error in Epos2Printer.addCut(): %d", result);
            return;
        }

        [self printData];
    }];
}

- (void)printData
{
    int result = EPOS2_SUCCESS;

    result = [printer sendData:EPOS2_PARAM_DEFAULT];
    if (result != EPOS2_SUCCESS) {
        [printer disconnect];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in printData()"];
        [self.commandDelegate sendPluginResult:result callbackId:self.printCallbackId];
        return;
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.printCallbackId];
    return;
}

- (void)getPrinterStatus:(CDVInvokedUrlCommand *)command
{
    Epos2PrinterStatusInfo *status = nil;

    // (re-)connect printer with stored information
    if (printer == nil) {
        if (![self _connectPrinter]) {
            CDVPluginResult *cordovaResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in getPrinterStatus(): printer not connected."];
            [self.commandDelegate sendPluginResult:cordovaResult callbackId:command.callbackId];
            return;
        }
    }
    
    // request printer status
    status = [printer getStatus];

    // translate status into a dict for returning
    NSDictionary *info = @{
        @"online": [NSNumber numberWithInt:status.online],
        @"connection": [NSNumber numberWithInt:status.connection],
        @"coverOpen": [NSNumber numberWithInt:status.coverOpen],
        @"paper": [NSNumber numberWithInt:status.paper],
        @"paperFeed": [NSNumber numberWithInt:status.paperFeed],
        @"errorStatus": [NSNumber numberWithInt:status.errorStatus],
        @"isPrintable": [NSNumber numberWithBool:[self isPrintable:status]]
    };
    
    NSLog(@"[epos2] getPrinterStatus(): %@", info);
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)getSupportedModels:(CDVInvokedUrlCommand *)command
{
    NSArray *types = [printerTypeMap allKeys];
    NSLog(@"[epos2] getSupportedModels(): %@", types);
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:types];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (BOOL)isPrintable:(Epos2PrinterStatusInfo *)status
{
    if (status == nil) {
        return NO;
    }

    if (status.connection == EPOS2_FALSE) {
        return NO;
    } else if (status.online == EPOS2_FALSE) {
        return NO;
    } else if (status.coverOpen == EPOS2_TRUE) {
        return NO;
    } else if (status.paper == EPOS2_PAPER_EMPTY) {
        return NO;
    } else if (status.errorStatus != EPOS2_NO_ERR) {
        return NO;
    } else {
        ; // printer is ready
    }

    return YES;
}

- (int)printerTypeFromString:(NSString*)type
{
    NSNumber *match = [printerTypeMap objectForKey:type];
    if (match != nil) {
        return [match intValue];
    } else {
      return -1;
    }
}

@end
