//
//  OpenVPNPacket.m
//  OpenVPN Adapter
//
//  Created by Sergey Abramchuk on 15.01.2018.
//

#import "OpenVPNPacket.h"

#include <arpa/inet.h>

@interface OpenVPNPacket () {
    NSData *_data;
    NSNumber *_protocolFamily;
}

@end

@implementation OpenVPNPacket

- (instancetype)initWithVPNData:(NSData *)data {
    if (self = [super init]) {
        // Get network protocol family from data prefix
        NSUInteger prefix_size = sizeof(uint32_t);
        
        uint32_t protocol = PF_UNSPEC;
        [data getBytes:&protocol length:prefix_size];
        protocol = CFSwapInt32BigToHost(protocol);
        
        NSRange range = NSMakeRange(prefix_size, data.length - prefix_size);
        NSData *packetData = [data subdataWithRange:range];
        
        _data = packetData;
        _protocolFamily = @(protocol);
    }
    return self;
}

- (instancetype)initWithPacketFlowData:(NSData *)data protocolFamily:(NSNumber *)protocolFamily {
    if (self = [super init]) {
        _data = data;
        _protocolFamily = protocolFamily;
    }
    return self;
}

- (NSData *)vpnData {
    // OpenVPN expects a four-byte protocol-family prefix before the packet payload.
    // NB! NSNumber can hold negative values or values wider than this uint32_t field.
    // Check both bounds before reading unsignedIntValue, which would otherwise hide
    // the sign or truncate high bits and encode a different protocol family.
    // Once checked, convert the prefix to network byte order (big-endian) so it has
    // the same wire format regardless of the host's integer width or byte order.
    if (_protocolFamily.longLongValue < 0 || _protocolFamily.unsignedLongLongValue > UINT32_MAX) {
        [NSException raise:NSInvalidArgumentException
                    format:@"The packet protocol family must fit in an unsigned 32-bit prefix."];
    }
    uint32_t prefix = CFSwapInt32HostToBig(_protocolFamily.unsignedIntValue);
    NSUInteger prefix_size = sizeof(uint32_t);
    
    NSMutableData *data = [NSMutableData dataWithCapacity:prefix_size + _data.length];
    
    [data appendBytes:&prefix length:prefix_size];
    [data appendData:_data];
    
    return data;
}

- (NSData *)packetFlowData {
    return _data;
}

- (NSNumber *)protocolFamily {
    return _protocolFamily;
}

@end
