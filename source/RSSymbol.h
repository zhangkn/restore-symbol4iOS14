//
//  RSSymbol.h
//  restore-symbol
//
//  Created by EugeneYang on 16/8/19.
//
//

#import <Foundation/Foundation.h>
#import <mach-o/nlist.h>


#define RS_JSON_KEY_ADDRESS @"address"
#define RS_JSON_KEY_SYMBOL_NAME @"name"

@interface RSSymbol : NSObject


@property (nonatomic, strong) NSString * name;
@property (nonatomic) uint64 address;
@property (nonatomic) uint8_t type;


+ (NSArray<RSSymbol *> *)symbolsWithJson:(NSData *)json;

+ (RSSymbol *)symbolWithName:(NSString *)name address:(uint64)addr;
+ (RSSymbol *)symbolWithName:(NSString *)name address:(uint64)addr type:(uint8)type;



@end
