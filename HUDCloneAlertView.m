//
//  CloneAlertView.m
//
//  Created by Nick Peterson on 8/17/16.
//  Copyright © 2016 Company. All rights reserved.
//

#import "HUDCloneAlertView.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

//------------------------------------------------------------------------------
#pragma mark - Private Class Extension
//------------------------------------------------------------------------------
@interface HUDCloneAlertView ()

@property (nonatomic, strong) UIView *alertView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;

@property (nonatomic, strong) NSString *cancelButtonTitle;
@property (nonatomic, strong) NSMutableArray *otherButtonsTitles;
@property (nonatomic, strong) NSMutableArray *textFieldArray;

@property (nonatomic, strong) UITableView *buttonTableView;
@property (nonatomic, strong) UITableView *otherTableView;

@property (nonatomic, strong) UITextField *plainTextInputField;
@property (nonatomic, strong) UITextField *secureTextInputField;

@property (nonatomic, weak) id<UITextFieldDelegate>proxyPlainDelegate;
@property (nonatomic, weak) id<UITextFieldDelegate>proxySecureDelegate;

@property (nonatomic) BOOL firstOtherButtonIsEnabled;

@property (nonatomic, strong) UIWindow *window;

@end


//==============================================================================
#pragma mark - AlertView Class Implementation
//==============================================================================
@implementation HUDCloneAlertView

//------------------------------------------------------------------------------
#pragma mark - Initialization
//------------------------------------------------------------------------------

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    self = [super init];
    if (self) {
        
        self.title = title;
        self.message = message;
        self.delegate = delegate;
        self.cancelButtonTitle = cancelButtonTitle;
        self.buttonEnabledFlag = true;
        self.textFieldArray = [[NSMutableArray alloc] init];
        
        if (otherButtonTitles != nil) {
            va_list args;
            va_start(args, otherButtonTitles);
            self.otherButtonsTitles = [[NSMutableArray alloc] initWithObjects:otherButtonTitles, nil];
            id obj;
            while ((obj = va_arg(args, id)) != nil) {
                [self.otherButtonsTitles addObject:obj];
            }
            va_end(args);
        }
        
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.backgroundColor = [UIColor clearColor];
        self.window.hidden = YES;
        self.window.windowLevel = UIWindowLevelAlert;
        self.frame = self.window.frame;
        
        [self.window addSubview:self];
    }
    
    return self;
}

- (void)setupWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles, ... {
    _cancelButtonIndex = -1;
    _firstOtherButtonIndex = -1;
    _cancelButtonTitle = nil;
    
    if (otherButtonTitles != nil) {
        _otherButtonsTitles = [[NSMutableArray alloc] initWithArray:otherButtonTitles];
        _firstOtherButtonIndex = 1;
    }
    
    _numberOfButtons = [_otherButtonsTitles count];
    
    if (cancelButtonTitle != nil) {
        _numberOfButtons++;
        _cancelButtonIndex = 0;
        _cancelButtonTitle = cancelButtonTitle;
    }
    
    if ([self.delegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)]) {
        self.firstOtherButtonIsEnabled = [self.delegate alertViewShouldEnableFirstOtherButton:self];
    } else {
        self.firstOtherButtonIsEnabled = YES;
    }
    
    UIView *dimView = [[UIView alloc]initWithFrame:self.window.frame];
    dimView.backgroundColor = [UIColor blackColor];
    dimView.alpha = 0;
    [self addSubview:dimView];
    [UIView animateWithDuration:0.3
                     animations:^{
                         dimView.alpha = 0.3;
                     }];
    
    CGFloat alertWidth = 270;
    CGFloat textFieldHeight = 30;
    CGFloat padding = 15;
    CGFloat labelWidth = alertWidth - (padding * 2);
    UIFont *titleFont = [UIFont boldSystemFontOfSize:17];
    CGSize titleSize = [self sizeOfString:title withFont:titleFont constrainedToSize:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    
    CGFloat buttonHeight = 44;
    CGFloat rollingY = 0;
    
    UIView *lineView;
    
    if (title != nil) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, rollingY + 15, labelWidth, titleSize.height)];
        self.titleLabel.text = title;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.font = titleFont;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        
        rollingY += titleSize.height;
    }
    
    rollingY += 20;
    
    if (message != nil) {
        UIFont *messageFont = [UIFont boldSystemFontOfSize:13];
        CGSize messageSize = [self sizeOfString:self.message withFont:messageFont constrainedToSize:CGSizeMake(labelWidth, CGFLOAT_MAX)];
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, rollingY, labelWidth, messageSize.height)];
        self.messageLabel.text = message;
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.messageLabel setFont:messageFont];
        self.messageLabel.backgroundColor = [UIColor clearColor];
        
        rollingY += messageSize.height;
    }
    
    rollingY += 20;
    
    if (self.alertViewStyle != AlertViewStyleDefault) {
        if (self.alertViewStyle == AlertViewStyleSecureTextInput) {
            [self.secureTextInputField setFrame:CGRectMake(padding, rollingY, labelWidth, textFieldHeight)];
            UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
            [self.secureTextInputField setLeftViewMode:UITextFieldViewModeAlways];
            [self.secureTextInputField setLeftView:spacerView];
            self.secureTextInputField.secureTextEntry = YES;
            [self.secureTextInputField setFont:[UIFont systemFontOfSize:17]];
            self.secureTextInputField.layer.cornerRadius = 5;
            self.secureTextInputField.backgroundColor = [UIColor whiteColor];
            self.secureTextInputField.clipsToBounds = YES;
            
            rollingY += textFieldHeight + 15;
        }
        else if (self.alertViewStyle == AlertViewStylePlainTextInput) {
            [self.plainTextInputField setFrame:CGRectMake(padding, rollingY, labelWidth, textFieldHeight)];
            UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
            [self.plainTextInputField setLeftViewMode:UITextFieldViewModeAlways];
            [self.plainTextInputField setLeftView:spacerView];
            [self.plainTextInputField setFont:[UIFont systemFontOfSize:17]];
            self.plainTextInputField.layer.cornerRadius = 5;
            self.plainTextInputField.backgroundColor = [UIColor whiteColor];
            self.plainTextInputField.clipsToBounds = YES;
            
            rollingY += textFieldHeight + 15;
        }
        else if (self.alertViewStyle == AlertViewStyleLoginAndPasswordInput) {
            [self.plainTextInputField setFrame:CGRectMake(padding, rollingY, labelWidth, textFieldHeight)];
            UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
            [self.plainTextInputField setLeftViewMode:UITextFieldViewModeAlways];
            [self.plainTextInputField setLeftView:spacerView];
            [self.plainTextInputField setFont:[UIFont systemFontOfSize:17]];
            self.plainTextInputField.layer.cornerRadius = 5;
            self.plainTextInputField.backgroundColor = [UIColor whiteColor];
            self.plainTextInputField.clipsToBounds = YES;
            self.plainTextInputField.placeholder = @"Login";
            
            rollingY += textFieldHeight + 5;
            
            [self.secureTextInputField setFrame:CGRectMake(padding, rollingY, labelWidth, textFieldHeight)];
            UIView *spacerView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
            [self.secureTextInputField setLeftViewMode:UITextFieldViewModeAlways];
            [self.secureTextInputField setLeftView:spacerView2];
            self.secureTextInputField.secureTextEntry = YES;
            [self.secureTextInputField setFont:[UIFont systemFontOfSize:17]];
            self.secureTextInputField.layer.cornerRadius = 5;
            self.secureTextInputField.backgroundColor = [UIColor whiteColor];
            self.secureTextInputField.clipsToBounds = YES;
            self.secureTextInputField.placeholder = @"Password";
            
            rollingY += textFieldHeight + 15;
        }
    }

    if (self.numberOfButtons > 0) {
        lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0, rollingY - 1.0, alertWidth, 1.0)];
        lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        UIView *lineViewInner = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.5, alertWidth, 0.5)];
        lineViewInner.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        lineViewInner.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [lineView addSubview:lineViewInner];
    }
    
    BOOL sideBySideButtons = (self.numberOfButtons == 2);
    BOOL buttonsShouldStack = !sideBySideButtons;
    
    if (sideBySideButtons) {
        CGFloat halfWidth = (alertWidth / 2.0);
        
        UIView *lineVerticalViewInner = [[UIView alloc] initWithFrame:CGRectMake(halfWidth, 0.5, 0.5, buttonHeight + 0.5)];
        lineVerticalViewInner.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        [lineView addSubview:lineVerticalViewInner];
        
        _buttonTableView = [self tableViewWithFrame:CGRectMake(0.0, rollingY, halfWidth, buttonHeight)];
        _otherTableView = [self tableViewWithFrame:CGRectMake(halfWidth, rollingY, halfWidth, buttonHeight)];
        
        rollingY += buttonHeight;
    }
    else {
        NSInteger numberOfOtherButtons = [self.otherButtonsTitles count];
        
        if (numberOfOtherButtons > 0) {
            CGFloat tableHeight = buttonsShouldStack ? numberOfOtherButtons * buttonHeight : buttonHeight;
            _buttonTableView = [self tableViewWithFrame:CGRectMake(0.0, rollingY, alertWidth, tableHeight)];
            
            rollingY += tableHeight;
        }
        
        if (cancelButtonTitle != nil) {
            _otherTableView = [self tableViewWithFrame:CGRectMake(0.0, rollingY, alertWidth, buttonHeight)];
            
            rollingY += buttonHeight;
        }
    }
    
    _buttonTableView.tag = 0;
    _otherTableView.tag = 1;
    
    if (sideBySideButtons) {
        self.alertView = [[UIView alloc] initWithFrame:CGRectMake(self.window.center.x - (alertWidth / 2), self.window.center.y - (rollingY / 2), alertWidth, rollingY)];
    }
    else {
        self.alertView = [[UIView alloc] initWithFrame:CGRectMake(self.window.center.x - (alertWidth / 2), self.window.center.y - (rollingY / 2), alertWidth, rollingY)];
    }
    self.alertView.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:.95];
    self.alertView.opaque = YES;
    self.alertView.layer.cornerRadius = 10;
    self.alertView.clipsToBounds = YES;
    
    [_buttonTableView reloadData];
    [_otherTableView reloadData];
    
    [self.alertView addSubview:self.titleLabel];
    [self.alertView addSubview:self.messageLabel];
    [self.alertView addSubview:self.buttonTableView];
    [self.alertView addSubview:self.otherTableView];
    [self.alertView addSubview:self.plainTextInputField];
    [self.alertView addSubview:self.secureTextInputField];
    [self.alertView addSubview:lineView];
    
    [self addSubview:self.alertView];
}

- (bool)hasCancelButton {
    return (self.cancelButtonTitle != nil);
}

- (void)dealloc {
    NSLog(@"AlertView is being dealloc'd");
}

//------------------------------------------------------------------------------
#pragma mark - Public Methods
//------------------------------------------------------------------------------

- (void)addButtonWithTitle:(NSString *)title {
    [self.otherButtonsTitles addObject:title];
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle;
    if (self.cancelButtonTitle) {
        if (buttonIndex == 0) {
            buttonTitle = self.cancelButtonTitle;
        }
        else {
            buttonTitle = [self.otherButtonsTitles objectAtIndex:buttonIndex -1];
        }
    }
    else {
        buttonTitle = [self.otherButtonsTitles objectAtIndex:buttonIndex];
    }
    return buttonTitle;
}

- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex {
    if (self.plainTextInputField != nil) {
        [self.textFieldArray addObject:self.plainTextInputField];
    }
    if (self.secureTextInputField != nil) {
        [self.textFieldArray addObject:self.secureTextInputField];
    }
    
    UITextField *textField = self.textFieldArray[textFieldIndex];
    return textField;
}

- (void)show {
    if ([self.delegate respondsToSelector:@selector(alertViewWillPresent:)]) {
        [self.delegate alertViewWillPresent:self];
    }
    
    [self setupWithTitle:self.title message:self.message cancelButtonTitle:self.cancelButtonTitle otherButtonTitles:self.otherButtonsTitles];
    
    if (self.plainTextInputField.delegate) {
        self.proxyPlainDelegate = self.plainTextInputField.delegate;
    }
    
    self.plainTextInputField.delegate = self;
    
    if (self.secureTextInputField.delegate) {
        self.proxySecureDelegate = self.secureTextInputField.delegate;
    }
    
    self.secureTextInputField.delegate = self;
    
    [self.window makeKeyAndVisible];
}

- (void)setAlertViewStyle:(AlertViewStyle)alertViewStyle {
    if (_alertViewStyle != alertViewStyle) {
        _alertViewStyle = alertViewStyle;
        
        if (_alertViewStyle == AlertViewStyleSecureTextInput) {
            self.secureTextInputField = [[UITextField alloc] init];
        }
        if (_alertViewStyle == AlertViewStylePlainTextInput) {
            self.plainTextInputField = [[UITextField alloc] init];
        }
        else if (_alertViewStyle == AlertViewStyleLoginAndPasswordInput) {
            self.plainTextInputField = [[UITextField alloc] init];
            self.secureTextInputField = [[UITextField alloc] init];
        }
    }
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    [self dismissWithIndex:buttonIndex];
}

//------------------------------------------------------------------------------
#pragma mark - Private Methods
//------------------------------------------------------------------------------

- (void)dismissWithIndex:(NSInteger)buttonIndex {
    if ([self.delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)]) {
        [self.delegate alertView:(HUDCloneAlertView *)self didDismissWithButtonIndex:buttonIndex];
    }
    [self.alertView endEditing:YES];
    self.window.hidden = YES;
    self.window = nil;
}

- (CGSize)sizeOfString:(NSString *)text withFont:(UIFont *)font constrainedToSize:(CGSize)size {
    if (text == nil) {
        return CGSizeZero;
    }
    
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font}];
    
    CGRect bounds = [attributed boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    return CGSizeMake(ceilf(bounds.size.width), ceilf(bounds.size.height));
}

//------------------------------------------------------------------------------
#pragma mark - UITextField Delegate Methods
//------------------------------------------------------------------------------

- (void)textFieldDidChangeContent:(UITextField *)textField {
    BOOL unlockBool = YES;
    if ([self.delegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)]) {
        unlockBool = [self.delegate alertViewShouldEnableFirstOtherButton:self];
    }
    
    if (unlockBool) {
        self.firstOtherButtonIsEnabled = YES;
        [self.buttonTableView reloadData];
        [self.otherTableView reloadData];
    }
    else {
        self.firstOtherButtonIsEnabled = NO;
        [self.buttonTableView reloadData];
        [self.otherTableView reloadData];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL proxyBool = YES;
    if (textField == self.plainTextInputField) {
        if ([self.proxyPlainDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
            proxyBool &= [self.proxyPlainDelegate textFieldShouldBeginEditing:textField];
        }
    }
    if (textField == self.secureTextInputField) {
        if ([self.proxySecureDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
            proxyBool &= [self.proxySecureDelegate textFieldShouldBeginEditing:textField];
        }
    }
    if (proxyBool) {
        if (self.alertViewStyle == AlertViewStyleLoginAndPasswordInput) {
            if (textField == self.plainTextInputField) {
                [self.secureTextInputField becomeFirstResponder];
            }
            else if(textField == self.secureTextInputField) {
                [self endEditing:YES];
            }
        }
        else if (textField == self.plainTextInputField || self.secureTextInputField) {
            [self endEditing:YES];
        }
    }
    
    return proxyBool;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL proxyBool = YES;
    if (textField == self.plainTextInputField) {
        if ([self.proxyPlainDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
            proxyBool &= [self.proxyPlainDelegate textFieldShouldBeginEditing:textField];
        }
    }
    if (textField == self.secureTextInputField) {
        if ([self.proxySecureDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
            proxyBool &= [self.proxySecureDelegate textFieldShouldBeginEditing:textField];
        }
    }
    if (proxyBool) {
        if (self.alertViewStyle == AlertViewStyleLoginAndPasswordInput) {
            self.plainTextInputField.returnKeyType = UIReturnKeyNext;
        }
        [UIView animateWithDuration:.3 animations:^{
            self.alertView.center = CGPointMake(self.alertView.center.x, self.alertView.center.y - 100);
        }];
    }
    
    return proxyBool;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    BOOL proxyBool = YES;
    if (textField == self.plainTextInputField) {
        if ([self.proxyPlainDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
            proxyBool &= [self.proxyPlainDelegate textFieldShouldEndEditing:textField];
        }
    }
    if (textField == self.secureTextInputField) {
        if ([self.proxySecureDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
            proxyBool &= [self.proxySecureDelegate textFieldShouldEndEditing:textField];
        }
    }
    
    if (proxyBool) {
        [UIView animateWithDuration:.3 animations:^{
            self.alertView.center = CGPointMake(self.alertView.center.x, self.alertView.center.y + 100);
        }];
        [self.alertView endEditing:YES];
    }
    
    return proxyBool;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.plainTextInputField) {
        if ([self.proxyPlainDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
            [self.proxyPlainDelegate textFieldDidBeginEditing:textField];
        }
    }
    if (textField == self.secureTextInputField) {
        if ([self.proxySecureDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
            [self.proxySecureDelegate textFieldDidBeginEditing:textField];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.plainTextInputField) {
        if ([self.proxyPlainDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
            [self.proxyPlainDelegate textFieldDidEndEditing:textField];
        }
    }
    if (textField == self.secureTextInputField) {
        if ([self.proxySecureDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
            [self.proxySecureDelegate textFieldDidEndEditing:textField];
        }
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (textField == self.plainTextInputField) {
        if ([self.proxyPlainDelegate respondsToSelector:@selector(textFieldShouldClear:)]) {
            return [self.proxyPlainDelegate textFieldShouldClear:textField];
        }
    }
    if (textField == self.secureTextInputField) {
        if ([self.proxySecureDelegate respondsToSelector:@selector(textFieldShouldClear:)]) {
            return [self.proxySecureDelegate textFieldShouldClear:textField];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.plainTextInputField) {
        if ([self.proxyPlainDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            return [self.proxyPlainDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
        }
    }
    if (textField == self.secureTextInputField) {
        if ([self.proxySecureDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            return [self.proxySecureDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
        }
    }
    return YES;
}

//------------------------------------------------------------------------------
#pragma mark - TableView & DataSource Methods
//------------------------------------------------------------------------------

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *labelText;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    cell.textLabel.text = [self.otherButtonsTitles objectAtIndex:indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor colorWithRed:0 green:0.46 blue:1 alpha:1];
    cell.backgroundColor = [UIColor clearColor];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0, cell.frame.size.height - 0.5, cell.frame.size.width, 0.5)];
    lineView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [cell addSubview:lineView];
    
    NSInteger buttonIndex;
    BOOL boldButton = NO;
    BOOL lastRow = NO;
    
    if (self.numberOfButtons == 1) {
        buttonIndex = 0;
        
        if ([self hasCancelButton]) {
            labelText = self.cancelButtonTitle;
        }
        else {
            labelText = self.otherButtonsTitles[0];
        }
        
        boldButton = YES;
        lastRow = YES;
    }
    else if (self.numberOfButtons == 2) {
        buttonIndex = tableView.tag;
        
        if ([self hasCancelButton]) {
            if (buttonIndex == 0) {
                labelText = self.cancelButtonTitle;
            }
            else {
                labelText = self.otherButtonsTitles[0];
            }
        }
        else {
            labelText = self.otherButtonsTitles[buttonIndex];
        }
        
        boldButton = buttonIndex == 0;
        lastRow = YES;
    }
    else {
        buttonIndex = indexPath.row;
        
        if (tableView.tag == 1) {
            labelText = self.cancelButtonTitle;
            
            boldButton = YES;
            lastRow = YES;
        }
        else {
            labelText = self.otherButtonsTitles[buttonIndex];
            
            if (![self hasCancelButton] && buttonIndex == ([self.otherButtonsTitles count] - 1)) {
                boldButton = YES;
            }
            
            buttonIndex++;
        }
    }
    
    if (buttonIndex == 1) {
        if (!self.firstOtherButtonIsEnabled) {
            cell.textLabel.textColor = [UIColor darkGrayColor];
            [cell setUserInteractionEnabled:NO];
        }
    }
    
    cell.tag = buttonIndex;
    lineView.hidden = lastRow;
    cell.textLabel.font = boldButton ? [UIFont boldSystemFontOfSize:17.0] : [UIFont systemFontOfSize:17.0];
    cell.textLabel.text = labelText;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.numberOfButtons <= 2) {
        return 1;
    }
    else {
        if (tableView.tag == 0) {
            return [self.otherButtonsTitles count];
        }
        else {
            return 1;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (UITableViewCell *)buttonCellForIndex:(NSInteger)buttonIndex {
    UITableView *theTableView;
    NSInteger rowIndex = 0;
    
    if (self.numberOfButtons == 1) {
        theTableView = self.buttonTableView;
        rowIndex = 0;
    }
    else if (self.numberOfButtons == 2) {
        if (buttonIndex == self.cancelButtonIndex) {
            theTableView = self.buttonTableView;
        }
        else {
            theTableView = self.otherTableView;
        }
    }
    else {
        if (buttonIndex == self.cancelButtonIndex) {
            theTableView = self.otherTableView;
        }
        else {
            theTableView = self.buttonTableView;
            rowIndex = 1;
        }
    }
    
    return [theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:0]];
}

- (UITableView *)tableViewWithFrame:(CGRect)frame {
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.scrollEnabled = NO;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    return tableView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSInteger buttonIndex = cell.tag;
    
    if ([self.delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [self.delegate alertView:(HUDCloneAlertView *)self clickedButtonAtIndex:buttonIndex];
    }
    
    [self dismissWithIndex:buttonIndex];
}

@end
