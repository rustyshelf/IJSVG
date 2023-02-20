//
//  IJSVGTransform.m
//  IconJar
//
//  Created by Curtis Hard on 01/09/2014.
//  Copyright (c) 2014 Curtis Hard. All rights reserved.
//

#import <IJSVG/IJSVGMath.h>
#import <IJSVG/IJSVGTransform.h>
#import <IJSVG/IJSVGParsing.h>

@implementation IJSVGTransform

- (void)dealloc
{
    (void)free(_parameters), _parameters = NULL;
}

- (id)copyWithZone:(NSZone*)zone
{
    IJSVGTransform* trans = [[self.class alloc] init];
    trans.command = _command;
    trans.parameters = (CGFloat*)malloc(sizeof(CGFloat) * _parameterCount);
    trans.sort = _sort;
    trans.parameterCount = _parameterCount;
    memcpy(trans.parameters, _parameters, sizeof(CGFloat) * _parameterCount);
    return trans;
}

void IJSVGConcatTransformsCTM(CGContextRef context, NSArray<IJSVGTransform*>* transforms)
{
    IJSVGApplyTransform(transforms, ^(IJSVGTransform* transform) {
        CGContextConcatCTM(context, transform.CGAffineTransform);
    });
}

CGAffineTransform IJSVGConcatTransforms(NSArray<IJSVGTransform*>* transforms)
{
    __block CGAffineTransform trans = CGAffineTransformIdentity;
    IJSVGApplyTransform(transforms, ^(IJSVGTransform* transform) {
        trans = CGAffineTransformConcat(trans, transform.CGAffineTransform);
    });
    return trans;
}

NSString* IJSVGTransformAttributeString(CGAffineTransform transform)
{
    return [IJSVGTransform affineTransformToSVGMatrixString:transform];
}

void IJSVGApplyTransform(NSArray<IJSVGTransform*>* transforms, IJSVGTransformApplyBlock block)
{
    for (IJSVGTransform* transform in transforms) {
        block(transform);
    }
};

BOOL IJSVGAffineTransformScalesAndTranslates(CGAffineTransform transform)
{
    if(transform.tx != 0.f || transform.ty != 0.f) {
        CGFloat scaleX = sqrt(pow(transform.a, 2.f) + pow(transform.c, 2.f));
        CGFloat scaleY = sqrt(pow(transform.b, 2.f) + pow(transform.d, 2.f));
        return scaleX != 1.f || scaleY != 1.f;
    }
    return NO;
}

+ (IJSVGTransform*)transformByTranslatingX:(CGFloat)x
                                         y:(CGFloat)y
{
    IJSVGTransform* transform = [[self alloc] init];
    transform.command = IJSVGTransformCommandTranslate;
    transform.parameterCount = 2;
    CGFloat* params = (CGFloat*)malloc(sizeof(CGFloat) * 2);
    params[0] = x;
    params[1] = y;
    transform.parameters = params;
    return transform;
}

+ (IJSVGTransform*)transformByScaleX:(CGFloat)x
                                   y:(CGFloat)y
{
    IJSVGTransform* transform = [[self alloc] init];
    transform.command = IJSVGTransformCommandScale;
    transform.parameterCount = 2;
    CGFloat* params = (CGFloat*)malloc(sizeof(CGFloat) * 2);
    params[0] = x;
    params[1] = y;
    transform.parameters = params;
    return transform;
}

+ (IJSVGTransformCommand)commandForCommandCString:(char*)str
{
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "matrix") == YES) {
        return IJSVGTransformCommandMatrix;
    }
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "translate") == YES) {
        return IJSVGTransformCommandTranslate;
    }
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "translatex") == YES) {
        return IJSVGTransformCommandTranslateX;
    }
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "translatey") == YES) {
        return IJSVGTransformCommandTranslateY;
    }
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "scale") == YES) {
        return IJSVGTransformCommandScale;
    }
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "skewx") == YES) {
        return IJSVGTransformCommandSkewX;
    }
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "skewy") == YES) {
        return IJSVGTransformCommandSkewY;
    }
    if(IJSVGCharBufferCaseInsensitiveCompare(str, "rotate") == YES) {
        return IJSVGTransformCommandRotate;
    }
    return IJSVGTransformCommandNotImplemented;
}

+ (IJSVGTransformCommand)commandForCommandString:(NSString*)str
{
    str = str.lowercaseString;
    if([str isEqualToString:@"matrix"]) {
        return IJSVGTransformCommandMatrix;
    }
    if([str isEqualToString:@"translate"]) {
        return IJSVGTransformCommandTranslate;
    }
    if([str isEqualToString:@"translatex"]) {
        return IJSVGTransformCommandTranslateX;
    }
    if([str isEqualToString:@"translatey"]) {
        return IJSVGTransformCommandTranslateY;
    }
    if([str isEqualToString:@"scale"]) {
        return IJSVGTransformCommandScale;
    }
    if([str isEqualToString:@"skewx"]) {
        return IJSVGTransformCommandSkewX;
    }
    if([str isEqualToString:@"skewy"]) {
        return IJSVGTransformCommandSkewY;
    }
    if([str isEqualToString:@"rotate"]) {
        return IJSVGTransformCommandRotate;
    }
    return IJSVGTransformCommandNotImplemented;
}

+ (NSInteger)sortForTransformCommand:(IJSVGTransformCommand)command
{
    switch (command) {
    case IJSVGTransformCommandScale:
        return 0;
    case IJSVGTransformCommandRotate:
        return 1;
    case IJSVGTransformCommandMatrix:
        return 2;
    case IJSVGTransformCommandTranslateX:
    case IJSVGTransformCommandTranslateY:
    case IJSVGTransformCommandTranslate:
        return -1;
    default:
        return 10;
    }
    return 10;
}

+ (NSArray<IJSVGTransform*>*)transformsForString:(NSString*)string
{
    NSMutableArray<IJSVGTransform*>* transforms = nil;
    transforms = [[NSMutableArray alloc] init];
    
    const char* charString = string.UTF8String;
    IJSVGParsingStringMethod** methods = NULL;
    NSUInteger count = 0;
    methods = IJSVGParsingMethodParseString(charString, &count);
    for(int i = 0; i < count; i++) {
        IJSVGParsingStringMethod* method = methods[i];
        IJSVGTransformCommand commandType;
        commandType = [self.class commandForCommandCString:method->name];
        if(commandType == IJSVGTransformCommandNotImplemented) {
            (void)IJSVGParsingStringMethodRelease(method), method = NULL;
            continue;
        }
        
        // create a new transform object and parse the parameters
        NSInteger count = 0;
        IJSVGTransform* transform = [[self.class alloc] init];
        transform.command = commandType;
        transform.sort = [self.class sortForTransformCommand:commandType];
        transform.parameters = [IJSVGUtils scanFloatsFromCString:method->parameters
                                                            size:&count];
        transform.parameterCount = count;

        // add to the list of transforms to return
        [transforms addObject:transform];
        (void)IJSVGParsingStringMethodRelease(method), method = NULL;
    }
    (void)free(methods), methods = NULL;
    return transforms;
}

+ (NSArray<IJSVGTransform*>*)transformsForString:(NSString*)string
                                           units:(IJSVGUnitType)units
                                          bounds:(CGRect)bounds
{
    NSArray<IJSVGTransform*>* transforms = [self transformsForString:string];
    for(IJSVGTransform* transform in transforms) {
        [transform applyBounds:bounds
              withContentUnits:units];
    }
    return transforms;
}

- (IJSVGTransform*)transformByApplyingUnits:(IJSVGUnitType)units
                                     bounds:(CGRect)bounds
{
    IJSVGTransform* transform = self.copy;
    [transform applyBounds:bounds
          withContentUnits:units];
    return transform;
}

- (void)applyBounds:(CGRect)bounds
   withContentUnits:(IJSVGUnitType)contentUnits
{
    if(contentUnits != IJSVGUnitObjectBoundingBox) {
        return;
    }
    
    // tx and ty of a transform are coordinates, so they
    // have to be scaled into their bounding box if the units
    // dicate so.
    switch(self.command) {
        case IJSVGTransformCommandTranslate: {
            self.parameters[0] *= CGRectGetWidth(bounds);
            if(self.parameterCount == 2) {
                self.parameters[1] *= CGRectGetHeight(bounds);
            }
            break;
        }
        case IJSVGTransformCommandMatrix: {
            self.parameters[4] *= CGRectGetWidth(bounds);
            self.parameters[5] *= CGRectGetHeight(bounds);
            break;
        }
        default:
            break;
    }
}

- (CGAffineTransform)CGAffineTransform
{
    return [self stackIdentity:CGAffineTransformIdentity];
}

- (CGAffineTransform)stackIdentity:(CGAffineTransform)identity
{
    switch (_command) {

    // translate
    case IJSVGTransformCommandTranslate: {
        if(_parameterCount == 1) {
            return CGAffineTransformTranslate(identity, _parameters[0], 0.f);
        }
        return CGAffineTransformTranslate(identity, _parameters[0], _parameters[1]);
    }

    // translateX
    case IJSVGTransformCommandTranslateX: {
        return CGAffineTransformTranslate(identity, _parameters[0], 0.f);
    }

    // translateY
    case IJSVGTransformCommandTranslateY: {
        return CGAffineTransformTranslate(identity, 0.f, _parameters[0]);
    }

    // rotate
    case IJSVGTransformCommandRotate: {
        if(_parameterCount == 1) {
            return CGAffineTransformRotate(identity, (_parameters[0] / 180) * M_PI);
        }
        CGFloat p0 = _parameters[0];
        CGFloat p1 = _parameters[1];
        CGFloat p2 = _parameters[2];
        CGFloat angle = p0 * (M_PI / 180.f);

        identity = CGAffineTransformTranslate(identity, p1, p2);
        identity = CGAffineTransformRotate(identity, angle);
        return CGAffineTransformTranslate(identity, -p1, -p2);
    }

    // scale
    case IJSVGTransformCommandScale: {
        CGFloat p0 = _parameters[0];
        if(_parameterCount == 1) {
            return CGAffineTransformScale(identity, p0, p0);
        }
        CGFloat p1 = _parameters[1];
        return CGAffineTransformScale(identity, p0, p1);
    }

    // matrix
    case IJSVGTransformCommandMatrix: {
        CGFloat p0 = _parameters[0];
        CGFloat p1 = _parameters[1];
        CGFloat p2 = _parameters[2];
        CGFloat p3 = _parameters[3];
        CGFloat p4 = _parameters[4];
        CGFloat p5 = _parameters[5];
        return CGAffineTransformMake(p0, p1, p2, p3, p4, p5);
    }

    // skewX
    case IJSVGTransformCommandSkewX: {
        CGFloat degrees = _parameters[0];
        CGFloat radians = degrees * M_PI / 180.f;
        return CGAffineTransformMake(1.f, 0.f, tan(radians), 1.f, 0.f, 0.f);
    }

    // skewY
    case IJSVGTransformCommandSkewY: {
        CGFloat degrees = _parameters[0];
        CGFloat radians = degrees * M_PI / 180.f;
        return CGAffineTransformMake(1.f, tan(radians), 0.f, 1.f, 0.f, 0.f);
    }

    case IJSVGTransformCommandNotImplemented: {
        return CGAffineTransformIdentity;
    }
    }
    return CGAffineTransformIdentity;
}

+ (NSArray<IJSVGTransform*>*)transformsFromAffineTransform:(CGAffineTransform)affineTransform
{
    NSString* matrix = [self affineTransformToSVGMatrixString:affineTransform];
    return [self transformsForString:matrix];
}

+ (NSString*)affineTransformToSVGTransformComponentString:(CGAffineTransform)transform
                                     floatingPointOptions:(IJSVGFloatingPointOptions)floatingPointOptions
{
    NSArray<NSDictionary*>* trans = [self affineTransformToSVGTransformComponents:transform];
    trans = [self filterUselessAffineTransformComponents:trans];
    NSMutableArray<NSString*>* strings = [[NSMutableArray alloc] initWithCapacity:trans.count];
    for (NSDictionary* dict in trans) {
        NSArray<NSNumber*>* data = dict[@"data"];
        NSString* method = dict[@"name"];
        NSMutableArray* dataStrings = [[NSMutableArray alloc] initWithCapacity:data.count];
        for (NSNumber* number in data) {
            [dataStrings addObject:IJSVGShortFloatStringWithOptions(number.floatValue,
                                                                    floatingPointOptions)];
        }
        [strings addObject:[NSString stringWithFormat:@"%@(%@)", method,
                                     IJSVGCompressFloatParameterArray(dataStrings)]];
    }
    NSString* componentsString = [strings componentsJoinedByString:@" "];
    NSString* matrixString = [self affineTransformToSVGMatrixString:transform
                                               floatingPointOptions:floatingPointOptions];
    return componentsString.length < matrixString.length ? componentsString : matrixString;
}

+ (NSString*)affineTransformToSVGTransformComponentString:(CGAffineTransform)transform
{
    NSArray<NSDictionary*>* trans = [self affineTransformToSVGTransformComponents:transform];
    trans = [self filterUselessAffineTransformComponents:trans];
    NSMutableArray<NSString*>* strings = [[NSMutableArray alloc] initWithCapacity:trans.count];
    for (NSDictionary* dict in trans) {
        NSArray<NSNumber*>* data = dict[@"data"];
        NSString* method = dict[@"name"];
        NSMutableArray* dataStrings = [[NSMutableArray alloc] initWithCapacity:data.count];
        for (NSNumber* number in data) {
            [dataStrings addObject:IJSVGShortFloatString(number.floatValue)];
        }
        [strings addObject:[NSString stringWithFormat:@"%@(%@)", method,
                                     IJSVGCompressFloatParameterArray(dataStrings)]];
    }
    NSString* componentsString = [strings componentsJoinedByString:@" "];
    NSString* matrixString = [self affineTransformToSVGMatrixString:transform];
    return componentsString.length < matrixString.length ? componentsString : matrixString;
}

+ (NSString*)affineTransformToSVGMatrixString:(CGAffineTransform)transform
                         floatingPointOptions:(IJSVGFloatingPointOptions)floatingPointOptions
{
    NSArray<NSString*>* numbers = @[
        IJSVGShortFloatStringWithOptions(transform.a, floatingPointOptions),
        IJSVGShortFloatStringWithOptions(transform.b, floatingPointOptions),
        IJSVGShortFloatStringWithOptions(transform.c, floatingPointOptions),
        IJSVGShortFloatStringWithOptions(transform.d, floatingPointOptions),
        IJSVGShortFloatStringWithOptions(transform.tx, floatingPointOptions),
        IJSVGShortFloatStringWithOptions(transform.ty, floatingPointOptions)
    ];
    return [NSString stringWithFormat:@"matrix(%@)", IJSVGCompressFloatParameterArray(numbers)];
}

+ (NSString*)affineTransformToSVGMatrixString:(CGAffineTransform)transform
{
    NSArray<NSString*>* numbers = @[
        IJSVGShortFloatString(transform.a),
        IJSVGShortFloatString(transform.b),
        IJSVGShortFloatString(transform.c),
        IJSVGShortFloatString(transform.d),
        IJSVGShortFloatString(transform.tx),
        IJSVGShortFloatString(transform.ty)
    ];
    return [NSString stringWithFormat:@"matrix(%@)",
                     IJSVGCompressFloatParameterArray(numbers)];
}

+ (NSArray<NSDictionary*>*)filterUselessAffineTransformComponents:(NSArray<NSDictionary*>*)components
{
    NSMutableArray* comps = [[NSMutableArray alloc] initWithCapacity:components.count];
    NSArray<NSString*>* names = @[ @"translate", @"rotate", @"skewX", @"skewY" ];
    for (NSDictionary* transform in components) {
        NSString* name = transform[@"name"];
        NSArray<NSNumber*>* data = transform[@"data"];
        if([names containsObject:name] && (data.count == 1 || [name isEqualToString:@"rotate"]) &&
            data[0].floatValue == 0.f) {
            continue;
        } else if([name isEqualToString:@"translate"] && data[0].floatValue == 0.f &&
                   data[1].floatValue == 0.f) {
            continue;
        } else if([name isEqualToString:@"scale"] && data[0].floatValue == 1.f
                   && (data.count < 2 || (data.count == 2 && data[1].floatValue == 1.f))) {
            continue;
        } else if([name isEqualToString:@"matrix"] && data[0].floatValue == 1.f &&
                   data[3].floatValue == 1.f && !(data[1].floatValue != 0.f ||
                                                  data[2].floatValue != 0.f ||
                                                  data[4].floatValue != 0.f ||
                                                  data[5].floatValue != 0.f)) {
            continue;
        }
        [comps addObject:transform];
    }
    return comps;
}

+ (NSArray<NSDictionary*>*)affineTransformToSVGTransformComponents:(CGAffineTransform)transform
{
    CGFloat data[6] = {
        transform.a,
        transform.b,
        transform.c,
        transform.d,
        transform.tx,
        transform.ty
    };

    CGFloat sx = hypotf(data[0], data[1]);
    CGFloat sy = ((data[0] * data[3] - data[1] * data[2]) / sx);
    CGFloat colSum = data[0] * data[2] + data[1] * data[3];
    CGFloat rowSum = data[0] * data[1] + data[2] * data[3];
    BOOL scaleBefore = rowSum != 0.f || sx == sy;

    NSMutableArray* transforms = [[NSMutableArray alloc] init];

    // tx, ty -> translate
    if(data[4] != 0.f || data[5] != 0.f) {
        [transforms addObject:@{
            @"name" : @"translate",
            @"data" : @[ @(data[4]), @(data[5]) ]
        }];
    }

    // [sx, 0, tan(a).sy, sy, 0, 0] -> skewX(a).scale(sx,sy)
    if(data[1] == 0.f && data[2] != 0.f) {
        [transforms addObject:@{
            @"name" : @"skewX",
            @"data" : @[ @(IJSVGMathAtan(data[2] / sy))]
        }];

        // [sx, sy.tan(a), 0, sy, 0, 0] -> skewX(a).scale(sx, sy)
    } else if(data[1] != 0.f && data[2] == 0.f) {
        [transforms addObject:@{
            @"name" : @"skewY",
            @"data" : @[ @(IJSVGMathAtan(data[1] / data[0]))]
        }];
        sx = data[0];
        sy = data[3];
    } else if(colSum == 0.f || (sx == 1.f && sy == 1.f) || !scaleBefore) {
        if(!scaleBefore) {
            sx = (data[0] < 0.f ? -1.f : 1.f) * hypotf(data[0], data[2]);
            sy = (data[3] < 0.f ? -1.f : 1.f) * hypotf(data[1], data[3]);
            if(sx != 1.f || sy != 1.f) {
                [transforms addObject:@{
                    @"name" : @"scale",
                    @"data" : (sx == sy) ? @[ @(sx) ] : @[ @(sx), @(sy) ]
                }];
            }
        }

        CGFloat angle = MIN(MAX(-1.f, data[0] / sx), 1.f);
        NSMutableArray<NSNumber*>* rotate = [[NSMutableArray alloc] initWithCapacity:3];
        [rotate addObject:@(IJSVGMathAcos(angle) * ((scaleBefore ? 1.f : sy) * data[1] < 0.f ? -1.f: 1.f))];

        if(rotate[0].floatValue != 0.f) {
            [transforms addObject:@{
                @"name" : @"rotate",
                @"data" : rotate
            }];
        }

        if(rowSum != 0.f && colSum != 0.f) {
            [transforms addObject:@{
                @"name" : @"skewX",
                @"data" : @[ @(IJSVGMathAtan(colSum / (sx * sx)))]
            }];
        }

        // rotate can consume translate
        if(rotate[0].floatValue != 0.f && (data[4] != 0.f || data[5] != 0.f)) {
            [transforms removeObjectAtIndex:0];
            CGFloat cos = data[0] / sx;
            CGFloat sin = data[1] / (scaleBefore ? sx : sy);
            CGFloat x = data[4] * (scaleBefore ? 1.f : sy);
            CGFloat y = data[5] * (scaleBefore ? 1.f : sx);
            CGFloat denom = (powf(1.f - cos, 2.f) + powf(sin, 2.f)) * (scaleBefore ? 1.f : (sx * sy));
            [rotate addObject:@(((1.f - cos) * x - sin * y) / denom)];
            [rotate addObject:@(((1.f - cos) * y + sin * x) / denom)];
        }
    } else if(data[1] != 0.f || data[2] != 0.f) {
        NSDictionary* trans = @{
            @"name" : @"matrix",
            @"data" : @[ @(data[0]), @(data[1]), @(data[2]), @(data[3]), @(data[4]), @(data[5]) ]
        };
        return @[ trans ];
    }

    if(scaleBefore == YES && ((sx != 1.f || sy != 1.f) || transforms.count == 0)) {
        NSDictionary* trans = @{
            @"name" : @"scale",
            @"data" : (sx == sy) ? @[ @(sx) ] : @[ @(sx), @(sy) ]
        };
        [transforms addObject:trans];
    }

    return transforms;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ %@", [super description],
                     [self.class affineTransformToSVGTransformComponentString:self.CGAffineTransform]];
}

@end
