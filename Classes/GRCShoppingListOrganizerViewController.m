//
// MIT License
//
// Copyright (c) 2008-2023 Sophiestication Software, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "GRCShoppingListOrganizerViewController.h"

#import "GRCShoppingListPickerViewController.h"
#import "GRCAislePickerViewController.h"

#import "GRCAisle.h"
#import "GRCShoppingList+Private.h"

#import "NSString+Additions.h"
#import "UIActionSheet+Additions.h"

@interface GRCShoppingListOrganizerViewController()<GRCShoppingListPickerViewDelegateAccessory, GRCAislePickerViewDelegate>

@property(nonatomic, copy) NSSet* shoppingListItems;
@property(nonatomic, strong) GRCShoppingList* shoppingList;
@property(nonatomic, strong) GRCAisle* aisle;

@property(nonatomic, strong) GRCShoppingListPickerViewController* shoppingListPicker;
@property(nonatomic, strong) GRCAislePickerViewController* aislePicker;

@property(nonatomic, strong) UIBarButtonItem* cancelButtonItem;

@end

@implementation GRCShoppingListOrganizerViewController

#pragma mark - Construction & Destruction

- (id)initWithItems:(NSSet*)shoppingListItems shoppingList:(GRCShoppingList*)shoppingList {
	if((self = [super initWithNavigationBarClass:nil toolbarClass:nil])) {
		self.shoppingListItems = shoppingListItems;

		self.shoppingList = shoppingList;
		self.aisle = (id)[NSNull null];

		[self initButtonItems];
		[self initShoppingListPicker];
		[self initAislePicker];
		
		self.viewControllers = @[ self.shoppingListPicker, self.aislePicker ];
	}
	
	return self;
}

#pragma mark - GRCShoppingListOrganizerViewController

- (void)cancel:(id)sender {
	if([[self delegate] respondsToSelector:@selector(shoppingListOrganizerViewControllerDidCancel:)]) {
		[(id<GRCShoppingListOrganizerViewDelegate>)[self delegate] shoppingListOrganizerViewControllerDidCancel:self];
	}
}

#pragma mark - GRCShoppingListPickerViewDelegate

- (void)shoppingListPicker:(GRCShoppingListPickerViewController*)picker didFinishPickingShoppingList:(GRCShoppingList*)shoppingList {
	self.shoppingList = shoppingList;
	self.aisle = (id)[NSNull null];

	[self didFinishOrganizingItems];
}

- (void)shoppingListPickerDidCancel:(GRCShoppingListPickerViewController*)picker {
	[self cancel:picker];
}

#pragma mark - GRCShoppingListPickerViewDelegateAccessory

- (BOOL)shoppingListPicker:(GRCShoppingListPickerViewController*)picker shouldShowAccessoryButtonForShoppingList:(GRCShoppingList*)shoppingList {
	// if(shoppingList == self.shoppingList) { return NO; }
	return YES;
}

- (void)shoppingListPicker:(GRCShoppingListPickerViewController*)picker accessoryButtonTappedForShoppingList:(GRCShoppingList*)shoppingList {
	self.shoppingList = shoppingList;
	self.aisle = (id)[NSNull null];

	[self pushViewController:[self aislePicker] animated:YES];
}

#pragma mark - GRCAislePickerViewDelegate

- (BOOL)shouldAislePicker:(GRCAislePickerViewController*)picker pickAisle:(GRCAisle*)aisle {
	return YES;
}

- (void)aislePicker:(GRCAislePickerViewController*)picker didFinishPickingAisle:(GRCAisle*)aisle {
	self.aisle = aisle;
	[self didFinishOrganizingItems];
}

#pragma mark - Private

- (void)initButtonItems {
	self.cancelButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
		target:self
		action:@selector(cancel:)];
}

- (void)initShoppingListPicker {
	GRCShoppingListStore* shoppingListStore = self.shoppingList.store;

	GRCShoppingListPickerViewController* shoppingListPicker = [[GRCShoppingListPickerViewController alloc]
		initWithShoppingListStore:shoppingListStore
		style:UITableViewStylePlain];
		
	shoppingListPicker.delegate = self;
	
	shoppingListPicker.allowsModifications = NO;
	
	NSInteger numberOfItems = self.shoppingListItems.count;
	NSString* prompt;
	
	if(numberOfItems > 1) {
		NSString* formatString = NSLocalizedString(@"SHOPPINGLIST_ORGANIZER_NAVIGATIONITEM_PROMPT", @"");
		NSString* numberOfItemsString = [NSNumberFormatter localizedStringFromNumber:@(numberOfItems) numberStyle:NSNumberFormatterNoStyle];
		prompt = [NSString stringWithFormat:formatString, numberOfItemsString];
	} else {
		NSString* formatString = NSLocalizedString(@"SHOPPINGLIST_ORGANIZER_NAVIGATIONITEM_PROMPT_SINGULAR", @"");

		NSString* name = [[[self shoppingListItems] anyObject] title];
		name = [name quotedStringWithLocale:nil]; // uses current locale

		prompt = [NSString stringWithFormat:formatString, name];
	}
	
	shoppingListPicker.navigationItem.prompt = prompt;
	
	shoppingListPicker.navigationItem.rightBarButtonItem = self.cancelButtonItem;
		
	self.shoppingListPicker = shoppingListPicker;
}

- (void)initAislePicker {
	GRCShoppingListStore* shoppingListStore = self.shoppingList.store;

	GRCAislePickerViewController* aislePicker = [[GRCAislePickerViewController alloc]
		initWithShoppingListStore:shoppingListStore
		style:UITableViewStylePlain];
	
	aislePicker.delegate = self;
	
	aislePicker.allowsModifications = NO;
	aislePicker.showsSelectionIndicator = NO;
	
	NSInteger numberOfItems = self.shoppingListItems.count;
	NSString* prompt;
	
	if(numberOfItems > 1) {
		NSString* formatString = NSLocalizedString(@"SHOPPINGLIST_ORGANIZER_AISLE_NAVIGATIONITEM_PROMPT", @"");
		NSString* numberOfItemsString = [NSNumberFormatter localizedStringFromNumber:@(numberOfItems) numberStyle:NSNumberFormatterNoStyle];
		prompt = [NSString stringWithFormat:formatString, numberOfItemsString];
	} else {
		NSString* formatString = NSLocalizedString(@"SHOPPINGLIST_ORGANIZER_AISLE_NAVIGATIONITEM_PROMPT_SINGULAR", @"");

		NSString* name = [[[self shoppingListItems] anyObject] title];
		name = [name quotedStringWithLocale:nil]; // uses current locale

		prompt = [NSString stringWithFormat:formatString, name];
	}
	
	aislePicker.navigationItem.prompt = prompt;
	
	aislePicker.navigationItem.rightBarButtonItem = self.cancelButtonItem;
	
	self.aislePicker = aislePicker;
}

- (void)didFinishOrganizingItems {
	if([self shouldPresentCopyAndMoveSheet]) {
		[self presentCopyAndMoveSheet:self];
	} else {
		[self notifiyDelegateAboutActionIfNeeded:GRCShoppingListOrganizerActionMove];
	}
}

- (BOOL)shouldPresentCopyAndMoveSheet {
	GRCShoppingList* sourceShoppingList = [[[self shoppingListItems] anyObject] shoppingList];
	return ![[self shoppingList] isEqual:sourceShoppingList];
}

- (void)presentCopyAndMoveSheet:(id)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Add Copy button
    UIAlertAction* copyAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"COPY_BUTTONITEM", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self notifiyDelegateAboutActionIfNeeded:GRCShoppingListOrganizerActionCopy];
                                                       }];
    [alertController addAction:copyAction];
    
    // Add Move button
    UIAlertAction* moveAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"MOVE_BUTTONITEM", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self notifiyDelegateAboutActionIfNeeded:GRCShoppingListOrganizerActionMove];
                                                       }];
    [alertController addAction:moveAction];
    
    // Add Cancel button
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"CANCEL_BUTTONITEM", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self deselectContentTableViewSelectionIfNeededAnimated:YES];
                                                         }];
    [alertController addAction:cancelAction];
    
    // For iPad support - set the source for the popover
    UIPopoverPresentationController *popover = alertController.popoverPresentationController;
    if (popover) {
        if ([sender isKindOfClass:[UIBarButtonItem class]]) {
            popover.barButtonItem = sender;
        } else if ([sender isKindOfClass:[UIView class]]) {
            popover.sourceView = (UIView *)sender;
            popover.sourceRect = [(UIView *)sender frame];
        } else {
            popover.sourceView = self.view;
            popover.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),
                                            CGRectGetMidY(self.view.bounds),
                                            0, 0);
        }
    }
    
    // Present the alert controller
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)notifiyDelegateAboutActionIfNeeded:(GRCShoppingListOrganizerAction)action {
	id<GRCShoppingListOrganizerViewDelegate> delegate = (id)self.delegate;
	
	if([delegate respondsToSelector:@selector(shoppingListOrganizerViewController:shouldPerformAction:items:shoppingList:aisle:)]) {
		[delegate shoppingListOrganizerViewController:self
			shouldPerformAction:action
			items:[self shoppingListItems]
			shoppingList:[self shoppingList]
			aisle:[self aisle]];
	}
}

- (void)deselectContentTableViewSelectionIfNeededAnimated:(BOOL)animated {
	UIViewController* contentViewController = self.topViewController;
	if(![contentViewController respondsToSelector:@selector(tableView)]) { return; }

	UITableView* tableView = [(id)contentViewController tableView];

	NSIndexPath* indexPath = [tableView indexPathForSelectedRow];
	if(!indexPath) { return; }

	[tableView deselectRowAtIndexPath:indexPath animated:animated];
}

@end
