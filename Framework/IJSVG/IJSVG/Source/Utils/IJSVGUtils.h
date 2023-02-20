//
//  IJSVGUtils.h
//  IconJar
//
//  Created by Curtis Hard on 30/08/2014.
//  Copyright (c) 2014 Curtis Hard. All rights reserved.
//

#import <IJSVG/IJSVGCommand.h>
#import <IJSVG/IJSVGGradientUnitLength.h>
#import <IJSVG/IJSVGStringAdditions.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface IJSVGUtils : NSObject

CG_EXTERN const CGSize IJSVGSizeInfinite;
CG_EXTERN const CGSize IJSVGSizeIntrinsic;

CGFloat IJSVGMagnitude(CGPoint point);
CGFloat IJSVGRatio(CGPoint a, CGPoint b);
CGFloat IJSVGAngle(CGPoint a, CGPoint b);
CGFloat IJSVGRadiansToDegrees(CGFloat radians);
CGFloat IJSVGDegreesToRadians(CGFloat degrees);

char IJSVGCharToLower(char c);
BOOL IJSVGCharBufferCaseInsensitiveCompare(const char* str1, const char* str2);
BOOL IJSVGCharBufferCompare(const char* str1, const char* str2);
BOOL IJSVGCharBufferIsHEX(char* buffer);
BOOL IJSVGCharBufferHasPrefix(char* pre, char* str);
BOOL IJSVGCharBufferHasSuffix(char* s1, char* s2);
char* IJSVGTimmedCharBufferCreate(const char* buffer);
void IJSVGTrimCharBuffer(char* buffer);
void IJSVGCharBufferToLower(char* buffer);
size_t IJSVGCharBufferHash(char* buffer);
CGPoint IJSVGPathGetLastQuadraticCommandPoint(CGPathRef path);

IJSVGFloatingPointOptions IJSVGFloatingPointOptionsDefault(void);
IJSVGFloatingPointOptions IJSVGFloatingPointOptionsMake(BOOL round, int precision);

NSString* IJSVGCompressFloatParameterArray(NSArray<NSString*>* stringToCompress);
NSString* IJSVGShortFloatStringWithOptions(CGFloat f, IJSVGFloatingPointOptions options);
NSString* IJSVGShortenFloatString(NSString* string);
NSString* IJSVGPointToCommandString(CGPoint point);
NSString* IJSVGShortFloatString(CGFloat f);
NSString* IJSVGShortFloatStringWithPrecision(CGFloat f, NSInteger precision);

BOOL IJSVGIsLegalCommandCharacter(unichar aChar);
BOOL IJSVGIsSVGLayer(CALayer* layer);
+ (IJSVGCommandType)typeForCommandChar:(char)commandChar;
+ (CGFloat*)commandParameters:(NSString*)command
                        count:(NSInteger*)count;
+ (CGFloat*)parseViewBox:(NSString*)string;
+ (IJSVGWindingRule)windingRuleForString:(NSString*)string;
+ (IJSVGLineJoinStyle)lineJoinStyleForString:(NSString*)string;
+ (IJSVGLineCapStyle)lineCapStyleForString:(NSString*)string;
+ (IJSVGLineJoinStyle)lineJoinStyleForCGLineJoin:(CGLineJoin)lineJoin;
+ (IJSVGLineCapStyle)lineCapStyleForCGLineCap:(CGLineCap)lineCap;
+ (IJSVGUnitType)unitTypeForString:(NSString*)string;
+ (IJSVGBlendMode)blendModeForString:(NSString*)string;
+ (NSString* _Nullable)mixBlendingModeForBlendMode:(IJSVGBlendMode)blendMode;
+ (NSRange)rangeOfParentheses:(NSString*)string;

+ (void)logParameters:(CGFloat*)param
                count:(NSInteger)count;
+ (CGFloat)floatValue:(NSString*)string;
+ (CGFloat)angleBetweenPointA:(NSPoint)point
                       pointb:(NSPoint)point;
+ (NSString* _Nullable)defURL:(NSString*)string;
+ (CGFloat)floatValue:(NSString*)string
    fallBackForPercent:(CGFloat)viewBox;
+ (CGFloat*)scanFloatsFromString:(NSString*)string
                            size:(NSInteger*)length;
+ (CGFloat*)scanFloatsFromCString:(const char*)buffer
                             size:(NSInteger*)length;
+ (CGFloat*)scanFloatsFromCString:(const char*)buffer
                       floatCount:(NSUInteger)floatCount
                        charCount:(NSUInteger)charCount
                             size:(NSInteger*)length;
+ (IJSVGFontTraits)fontStyleStringForString:(NSString*)string;
+ (IJSVGFontTraits)fontWeightTraitForString:(NSString*)string
                                     weight:(CGFloat*)weight;

+ (CGPathRef)newFlippedCGPath:(CGPathRef)path;

+ (CAShapeLayerLineJoin)CGLineJoinForJoinStyle:(IJSVGLineJoinStyle)joinStyle;
+ (CAShapeLayerLineCap)CGLineCapForCapStyle:(IJSVGLineCapStyle)capStyle;
+ (CAShapeLayerFillRule)CGFillRuleForWindingRule:(IJSVGWindingRule)rule;

+ (CGLineCap)CGLineCapForCALineCap:(CAShapeLayerLineCap)lineCap;
+ (CGLineJoin)CGLineJoinForCALineJoin:(CAShapeLayerLineCap)lineJoin;

+ (NSImage*)resizeImage:(NSImage*)anImage
                 toSize:(CGSize)size;

@end
NS_ASSUME_NONNULL_END
