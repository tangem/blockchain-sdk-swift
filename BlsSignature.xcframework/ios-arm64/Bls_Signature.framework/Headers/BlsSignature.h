#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlsSignature: NSObject

+ (NSString *)augSchemeMplG2Map:(NSString *)hashPublicKey and:(NSString*)hashMessage with:(NSError **)error;
+ (NSString *)aggregate: (NSArray<NSString *> *)signatures with:(NSError **)error;
+ (NSString *)verify:(NSArray<NSString *> *)signatures with:(NSString *)publicKey and:(NSString*)message with:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
