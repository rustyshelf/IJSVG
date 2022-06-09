//
//  IJSVGPatternLayer.m
//  IJSVGExample
//
//  Created by Curtis Hard on 07/01/2017.
//  Copyright © 2017 Curtis Hard. All rights reserved.
//

#import <IJSVG/IJSVGPatternLayer.h>
#import <IJSVG/IJSVGTransform.h>
#import <IJSVG/IJSVGUnitRect.h>
#import <IJSVG/IJSVGViewBox.h>

@interface IJSVGPatternLayer ()

@property (nonatomic, assign, readonly) CGSize cellSize;
@property (nonatomic, assign) CGRect viewBox;

@end

@implementation IJSVGPatternLayer

- (BOOL)requiresBackingScale
{
    return YES;
}

- (void)setBackingScaleFactor:(CGFloat)backingScaleFactor
{
    [super setBackingScaleFactor:backingScaleFactor];
    [IJSVGLayer setBackingScaleFactor:backingScaleFactor
                        renderQuality:self.renderQuality
                   recursivelyToLayer:self.pattern];
}

void IJSVGPatternDrawingCallBack(void* info, CGContextRef ctx)
{
    // reassign the layer
    IJSVGPatternLayer* layer = (__bridge IJSVGPatternLayer*)info;
    CGSize size = layer.cellSize;
    CGContextSaveGState(ctx);
    CGRect rect = CGRectMake(0.f, 0.f, size.width, size.height);
    CGContextClipToRect(ctx, rect);
    
    IJSVGViewBoxAlignment alignment = layer.patternNode.viewBoxAlignment;
    IJSVGViewBoxMeetOrSlice meetOrSlice = layer.patternNode.viewBoxMeetOrSlice;
    CGRect viewBox = layer.viewBox;
    IJSVGViewBoxDrawingBlock drawBlock = ^(CGRect computedRect, CGFloat scale[]) {
        [IJSVGLayer renderLayer:layer.pattern
                      inContext:ctx
                        options:IJSVGLayerDrawingOptionNone];
    };
    IJSVGContextDrawViewBox(ctx, viewBox, rect, alignment, meetOrSlice, drawBlock);
    CGContextSaveGState(ctx);
};

- (CALayer<IJSVGDrawableLayer>*)referencingLayer
{
    return [super referencingLayer] ?: self.superlayer;
}

- (void)drawInContext:(CGContextRef)ctx
{
    // holder for callback
    static const CGPatternCallbacks callbacks = { 0, &IJSVGPatternDrawingCallBack, NULL };

    // create base pattern space
    CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
    CGContextSetFillColorSpace(ctx, patternSpace);
    CGColorSpaceRelease(patternSpace);
    
    CALayer<IJSVGDrawableLayer>* layer = (CALayer<IJSVGDrawableLayer>*)self.referencingLayer;
    CGRect rect = layer.boundingBoxBounds;
    
    // get the bounds, we need these as when we render we might need to swap
    // the coordinates over to objectBoundingBox
    IJSVGUnitLength* xLength = _patternNode.x;
    IJSVGUnitLength* yLength = _patternNode.y;
    IJSVGUnitLength* wLength = _patternNode.width;
    IJSVGUnitLength* hLength = _patternNode.height;
        
    // actually do the swap if required
    if(self.patternNode.units == IJSVGUnitObjectBoundingBox) {
        wLength = wLength.lengthByMatchingPercentage;
        hLength = hLength.lengthByMatchingPercentage;
        xLength = xLength.lengthByMatchingPercentage;
        yLength = yLength.lengthByMatchingPercentage;
    }
    
    CGFloat width = [wLength computeValue:rect.size.width];
    CGFloat height = [hLength computeValue:rect.size.height];
    _cellSize = CGSizeMake(width, height);
    
        
    // transform us back into the correct space
    CGAffineTransform transform = CGAffineTransformIdentity;
    if (_patternNode.units == IJSVGUnitUserSpaceOnUse) {
        transform = [IJSVGLayer userSpaceTransformForLayer:layer];
    }
    
    // transform the X and Y shift
    transform = CGAffineTransformConcat(transform, IJSVGConcatTransforms(self.patternNode.transforms));
    transform = CGAffineTransformTranslate(transform,
                                           [xLength computeValue:rect.size.width],
                                           [yLength computeValue:rect.size.height]);
    
    // its possible that this layer is shifted inwards due to a stroke on the
    // parent layer
    transform = CGAffineTransformConcat(transform, [IJSVGLayer userSpaceTransformForLayer:self]);
    
    // who knew that patterns have viewBoxes? Not me, but here is an implementation
    // of it anyway
    if(_patternNode.viewBox != nil && _patternNode.viewBox.isZeroRect == NO) {
        IJSVGUnitRect* nViewBox = _patternNode.viewBox;
        if(_patternNode.contentUnits == IJSVGUnitObjectBoundingBox) {
            nViewBox = [nViewBox copyByConvertingToUnitsLengthType:IJSVGUnitLengthTypePercentage];
        }
        _viewBox = [nViewBox computeValue:rect.size];
    } else {
        // no viewbox is assigned, so just map it 1:1 with its cellSize
        _viewBox = CGRectMake(0.f, 0.f, _cellSize.width, _cellSize.height);
    }
        
    // create the pattern
    CGRect selfBounds = self.boundingBoxBounds;
    CGPatternRef ref = CGPatternCreate((void*)self, selfBounds,
        transform, width, height,
        kCGPatternTilingConstantSpacing,
        true, &callbacks);

    // set the pattern then release it
    CGFloat alpha = 1.f;
    CGContextSetFillPattern(ctx, ref, &alpha);
    CGPatternRelease(ref);

    // fill it
    CGContextFillRect(ctx, selfBounds);
}

- (NSArray<CALayer<IJSVGDrawableLayer>*>*)debugLayers
{
    return @[self.pattern];
}

@end
