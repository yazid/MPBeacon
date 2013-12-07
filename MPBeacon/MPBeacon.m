//
//  MPBeacon.m
//  MPBeacon
//
//  Created by Yazid Azahari on 11/30/13.
//  Copyright (c) 2013 Yazid Azahari. All rights reserved.
//

#import "MPBeacon.h"

@interface MPBeacon()

@property (nonatomic, strong) NSString *UUID;
@property (nonatomic, strong) NSString *serviceIdentifier;
@property (nonatomic, strong) NSNumber *deviceHash;
@property (nonatomic, strong) NSMutableDictionary *myBeaconInfo;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *broadcastBeaconRegion;
@property (nonatomic, strong) CLBeaconRegion *scanBeaconRegion;
@property (nonatomic, strong) NSDictionary *beaconPeripheralData;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSMutableDictionary *detectedBeacons;
@property (nonatomic, strong) NSMutableDictionary *storedBeaconData;
@property (assign) BOOL isConnected;

@end

@implementation MPBeacon

@synthesize connectedBeacons;

-(id)initWithUUIDAndIdentifier:(NSString *)UUID andServiceIdentifier:(NSString *)serviceIdentifier
{
    if (self = [super init])
    {
        [self setUUID:UUID];
        [self setServiceIdentifier:serviceIdentifier];
        
        NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        self.deviceHash = [NSNumber numberWithInteger:[idfv hash]];
        NSString *deviceHashUnsignedShort = [NSString stringWithFormat:@"%i",[self.deviceHash unsignedShortValue]];
        
        NSLog(@"ID for Vendor: %@", idfv);
        NSLog(@"ID Hash Unsigned Short: %@", deviceHashUnsignedShort);
        
        //self.peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
        self.peerID = [[MCPeerID alloc] initWithDisplayName:deviceHashUnsignedShort];
        self.session = [[MCSession alloc] initWithPeer:self.peerID];
        [self.session setDelegate:self];
        
        self.myBeaconInfo = [[NSMutableDictionary alloc] initWithObjects:@[[UIDevice currentDevice].name,deviceHashUnsignedShort] forKeys:@[@"deviceName",@"beaconKey"]];
        
        // Advertising multipeer
        self.advertiser = [[MCNearbyServiceAdvertiser alloc]initWithPeer:self.peerID discoveryInfo:self.myBeaconInfo serviceType:_serviceIdentifier];
        [self.advertiser setDelegate:self];
        
        // Browsing multipeer
        self.browser = [[MCNearbyServiceBrowser alloc]initWithPeer:self.peerID serviceType:_serviceIdentifier];
        [self.browser setDelegate:self];
        
        // Broadcasting beacon
        NSNumber *peerIDHash = [NSNumber numberWithUnsignedInteger:[self.peerID hash]];
        NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:_UUID];
        self.broadcastBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:[self.deviceHash unsignedShortValue] identifier:_serviceIdentifier];
        
        self.beaconPeripheralData = [self.broadcastBeaconRegion peripheralDataWithMeasuredPower:nil];
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                         queue:nil
                                                                       options:nil];
        
        
        // Detecting beacons
        self.scanBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:_serviceIdentifier];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager startMonitoringForRegion:self.scanBeaconRegion];
        
        self.connectedBeacons = [[NSMutableArray alloc] init];
        self.detectedBeacons = [[NSMutableDictionary alloc] init];
        self.storedBeaconData = [[NSMutableDictionary alloc] init];
        self.isConnected = NO;
    }
    return self;
}

-(void)start
{
    [self startAdvertisingAndStopBrowsing];
    
    [self locationManager:self.locationManager didStartMonitoringForRegion:self.scanBeaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [self.locationManager startRangingBeaconsInRegion:self.scanBeaconRegion];
}

-(void)stop
{
    
}

-(void)startAdvertisingAndStopBrowsing
{
    [self.advertiser startAdvertisingPeer];
    NSLog(@"Advertising...");
    
    [self performSelector:@selector(stopAdvertisingAndStartBrowsing) withObject:nil afterDelay:5];
}

-(void)stopAdvertisingAndStartBrowsing
{
    if(!self.isConnected){
        [self.advertiser stopAdvertisingPeer];

        [self.browser startBrowsingForPeers];
        NSLog(@"Browsing...");
        
        [self performSelector:@selector(startAdvertisingAndStopBrowsing) withObject:nil afterDelay:5];
    }
}

#pragma browser delegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    //if(![[self.session connectedPeers] containsObject:peerID])
    //{
        NSData *myBeaconData = [NSKeyedArchiver archivedDataWithRootObject:self.myBeaconInfo];
        [browser invitePeer:peerID toSession:self.session withContext:myBeaconData timeout:10];
        self.isConnected = YES;
        [self.storedBeaconData setValue:info forKey:[info valueForKey:@"beaconKey"]];
    
        NSLog(@"Invitation sent to %@.", [info valueForKey:@"deviceName"]);
    //}
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Peer lost: %@", peerID.displayName);
}

#pragma advertiser delegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    //if(![[self.session connectedPeers] containsObject:peerID])
    //{
        invitationHandler(YES, self.session);
        NSMutableDictionary *hostBeaconData = (NSMutableDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:context];
        [self.storedBeaconData setValue:hostBeaconData forKey:[hostBeaconData valueForKey:@"beaconKey"]];
    
        NSLog(@"Invitation from %@ accepted.", [hostBeaconData valueForKey:@"deviceName"]);
        self.isConnected = YES;
    //}
}



-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Powered On");
        [self.peripheralManager startAdvertising:self.beaconPeripheralData];
    } else if (peripheral.state == CBPeripheralManagerStatePoweredOff) {
        NSLog(@"Powered Off");
        [self.peripheralManager stopAdvertising];
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self.locationManager startRangingBeaconsInRegion:self.scanBeaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    //[self.locationManager stopRangingBeaconsInRegion:self.scanBeaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            [self.locationManager startRangingBeaconsInRegion:self.scanBeaconRegion];
            
            break;
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
        default:
            // stop ranging beacons, etc
            NSLog(@"No beacons detected");
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if ([beacons count] > 0) {
        // Handle your found beacons here
        for(CLBeacon *beacon in beacons)
        {
            NSNumber *beaconDeviceHash = beacon.major;
            NSString *beaconKey = [beaconDeviceHash stringValue];
            
            [self.detectedBeacons setValue:beacon forKey:beaconKey];
            
            //NSLog(@"%@ is %@",[beacon.major stringValue],proximityLabel);
            
            [self syncBeaconData];
        }
    }
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected){
        NSLog(@"Peer connected: %@", peerID.displayName);
    } else if (state == MCSessionStateNotConnected){
        NSLog(@"Connection lost: %@", peerID.displayName);
        
        if([self.session.connectedPeers count]==0){
            self.isConnected = NO;
            [self stopAdvertisingAndStartBrowsing];
        } else {
            self.isConnected = YES;
        }
    }
    
    [self.connectedBeacons removeAllObjects];
    for(MCPeerID *peer in [self.session connectedPeers])
    {
        NSString *beaconKey = peer.displayName;
        CLBeacon *beacon = [self.detectedBeacons valueForKey:beaconKey];
        
        NSMutableDictionary *beaconData = [[NSMutableDictionary alloc] initWithDictionary:[self.storedBeaconData valueForKey:beaconKey]];
        [beaconData setValue:peer forKey:@"peerID"];
        [beaconData setValue:beacon forKey:@"beacon"];
        [beaconData setValue:[self getLabelFromProximity:beacon.proximity] forKey:@"proximityLabel"];
        
        [self.connectedBeacons addObject:beaconData];
    }
    if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(connectedBeaconsDidUpdate)]){
        [self.delegate connectedBeaconsDidUpdate];
    }
}

-(void)syncBeaconData
{
    for(NSMutableDictionary *beaconData in self.connectedBeacons)
    {
        NSString *beaconKey = [beaconData valueForKey:@"beaconKey"];
        CLBeacon *beacon = [self.detectedBeacons valueForKey:beaconKey];
        
        [beaconData setValue:beacon forKey:@"beacon"];
        [beaconData setValue:[self getLabelFromProximity:beacon.proximity] forKey:@"proximityLabel"];
        
        if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(connectedBeaconsDidUpdate)]){
            [self.delegate connectedBeaconsDidUpdate];
        }
    }
}

-(NSString *)getLabelFromProximity:(int)proximity
{
    NSString *proximityLabel = @"";
    
    if (proximity == CLProximityUnknown) {
        proximityLabel = @"Unknown Proximity";
    } else if (proximity == CLProximityImmediate) {
        proximityLabel = @"Immediate";
    } else if (proximity == CLProximityNear) {
        proximityLabel = @"Near";
    } else if (proximity == CLProximityFar) {
        proximityLabel = @"Far";
    }
    
    return proximityLabel;
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

@end
