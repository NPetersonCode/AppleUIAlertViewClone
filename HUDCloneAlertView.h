//
//  CloneAlertView.h
//
//  Created by Nick Peterson on 8/17/16.
//  Copyright © 2016 Company. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HUDCloneAlertView;

@protocol HUDCloneAlertViewDelegate <NSObject>

@optional

- (BOOL)alertViewShouldEnableFirstOtherButton:(HUDCloneAlertView *)alertView;
- (void)alertView:(HUDCloneAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)alertView:(HUDCloneAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)alertViewWillPresent:(HUDCloneAlertView *)alertView;

@end

typedef enum {
    AlertViewStyleDefault,
    AlertViewStyleSecureTextInput,
    AlertViewStylePlainTextInput,
    AlertViewStyleLoginAndPasswordInput
} AlertViewStyle;

@interface HUDCloneAlertView : UIView <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic) NSInteger cancelButtonIndex;
@property (nonatomic, readonly) NSInteger firstOtherButtonIndex;
@property (nonatomic, readonly) NSInteger numberOfButtons;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, weak) id<HUDCloneAlertViewDelegate> delegate;
@property (nonatomic) AlertViewStyle alertViewStyle;
@property (nonatomic) BOOL buttonEnabledFlag;
@property (nonatomic, assign) BOOL isShowing;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (void)addButtonWithTitle:(NSString *)title;
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;
- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

- (void)show;

@end

