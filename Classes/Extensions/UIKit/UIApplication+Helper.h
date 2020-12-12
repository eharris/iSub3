//
//  UIApplication+Helper.h
//  iSub
//
//  Created by Benjamin Baron on 11/9/20.
//  Copyright © 2020 Ben Baron. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Helper)

+ (UIInterfaceOrientation)orientation;
+ (UIWindow *)keyWindow;
+ (CGFloat)statusBarHeight;

@end
