@interface NSArray (JiangFoundation)

/* Additional behavior */

- (void)each:(void (^)(id))block;
- (NSString *)join:(NSString *)sep;
- (NSString *)toString;

/* Functional programming */

- (NSArray *)collect:(id (^)(id))block;
- (NSArray *)map:(id (^)(id))block;
- (NSArray *)select:(BOOL (^)(id))block;

/* Syntax suger */

- (NSArray *)reverse;

@end
