//
//  MPBeacon.h
//  MPBeacon
//
//  Created by Yazid Azahari on 11/30/13.
//  Copyright (c) 2013 Yazid Azahari. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MultipeerConnectivity;
@import CoreLocation;
@import CoreBluetooth;

@protocol MPBeaconDelegate <NSObject>
@optional
-(void)connectedBeaconsDidUpdate;
@end

@interface MPBeacon : NSObject <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, CLLocationManagerDelegate, CBPeripheralManagerDelegate, MCSessionDelegate> {
    id<MPBeaconDelegate> delegate;
}

@property (assign) id<MPBeaconDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *connectedBeacons;

-(id)initWithUUIDAndIdentifier:(NSString *)UUID andServiceIdentifier:(NSString *)serviceIdentifier;
-(void)start;
-(void)stop;

@end
