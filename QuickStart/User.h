#import <Foundation/Foundation.h>

@interface User : NSObject {
    NSString *upn;
    NSString *name;
}

@property (nonatomic, copy) NSString *upn;
@property (nonatomic, copy) NSString *name;

+ (id)NameOfUpn:(NSString*)upn name:(NSString*)name;

@end