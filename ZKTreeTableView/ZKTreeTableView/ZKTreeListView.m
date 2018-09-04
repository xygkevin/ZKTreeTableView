//
//  ZKTreeListView.m
//  ZKTreeTableView
//
//  Created by bestdew on 2018/8/29.
//  Copyright © 2018年 bestdew. All rights reserved.
//
//                      d*##$.
// zP"""""$e.           $"    $o
//4$       '$          $"      $
//'$        '$        J$       $F
// 'b        $k       $>       $
//  $k        $r     J$       d$
//  '$         $     $"       $~
//   '$        "$   '$E       $
//    $         $L   $"      $F ...
//     $.       4B   $      $$$*"""*b
//     '$        $.  $$     $$      $F
//      "$       R$  $F     $"      $
//       $k      ?$ u*     dF      .$
//       ^$.      $$"     z$      u$$$$e
//        #$b             $E.dW@e$"    ?$
//         #$           .o$$# d$$$$c    ?F
//          $      .d$$#" . zo$>   #$r .uF
//          $L .u$*"      $&$$$k   .$$d$$F
//           $$"            ""^"$$$P"$P9$
//          JP              .o$$$$u:$P $$
//          $          ..ue$"      ""  $"
//         d$          $F              $
//         $$     ....udE             4B
//          #$    """"` $r            @$
//           ^$L        '$            $F
//             RN        4N           $
//              *$b                  d$
//               $$k                 $F
//               $$b                $F
//                 $""               $F
//                 '$                $
//                  $L               $
//                  '$               $
//                   $               $

#import "ZKTreeListView.h"
#import "ZKTreeManager.h"

@interface ZKTreeListView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ZKTreeManager *manager;

@end

@implementation ZKTreeListView

#pragma mark -- Init
- (instancetype)init
{
    return [self initWithFrame:CGRectZero style:ZKTreeListViewStyleNone];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame style:ZKTreeListViewStyleNone];;
}

- (instancetype)initWithFrame:(CGRect)frame style:(ZKTreeListViewStyle)style
{
    if (self = [super initWithFrame:frame]) {
        self.frame = frame;
        self.autoExpand = YES;
        self.showExpandAnimation = YES;
        self.defaultExpandLevel = 0;
        self.style = style ? style : ZKTreeListViewStyleNone;
        [self addSubview:self.tableView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [super initWithCoder:aDecoder];
}

#pragma mark -- Layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.tableView.frame = self.bounds;
}

#pragma mark -- Public Method
- (void)reloadData
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.manager = [[ZKTreeManager alloc] initWithItems:self.items andExpandLevel:self.defaultExpandLevel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier
{
    if (cellClass) {
        NSAssert(![cellClass isKindOfClass:[ZKTreeListViewCell class]],
                 @"<cellClass>必须是<ZKTreeListViewCell>的子类");
    }
    
    self.identifier = identifier;
    [self.tableView registerClass:cellClass forCellReuseIdentifier:identifier];
}

- (void)expandAllItems:(BOOL)isExpand
{
    [self expandItemWithLevel:(isExpand ? NSIntegerMax : 0)];
}

- (void)expandItemWithLevel:(NSInteger)expandLevel
{
    __weak typeof(self) weakSelf = self;
    
    [self.manager expandItemWithLevel:expandLevel completed:^(NSArray *noExpandArray) {
        [weakSelf tableView:weakSelf.tableView didSelectItems:noExpandArray isExpand:NO];
    } andCompleted:^(NSArray *expandArray) {
        [weakSelf tableView:weakSelf.tableView didSelectItems:expandArray isExpand:YES];
    }];
}

- (NSArray *)getShowItems
{
    return self.manager.showItems;
}

- (NSArray *)getAllItems
{
    return [self.manager getAllItems];
}

- (CGFloat)containerViewWidthWithLevel:(NSInteger)level
{
    CGFloat indentationWith = 0.f;
    if (level <= 0) {
        indentationWith = 16.f;
    } else if (level == 1) {
        indentationWith = 48.f;
    } else {
        indentationWith = 68.f + (level - 2) * 20.f;
    }
    return self.bounds.size.width - indentationWith;
}

- (CGRect)rectInScreenForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    CGRect rectInTableView = [_tableView rectForRowAtIndexPath:indexPath];
    CGRect rectInScreen = [self convertRect:rectInTableView toView:keyWindow];
    
    return rectInScreen;
}

- (NSIndexPath *)indexPathForCell:(ZKTreeListViewCell *)cell
{
    return [_tableView indexPathForCell:cell];
}

- (__kindof ZKTreeListViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [_tableView cellForRowAtIndexPath:indexPath];
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
}

- (void)expandItems:(NSArray<ZKTreeItem *> *)items isExpand:(BOOL)isExpand
{
    [self tableView:_tableView didSelectItems:items isExpand:isExpand];
}

#pragma mark -- Private Method
- (void)tableView:(UITableView *)tableView didSelectItems:(NSArray<ZKTreeItem *> *)items isExpand:(BOOL)isExpand
{
    NSMutableArray *updateIndexPaths = @[].mutableCopy;
    NSMutableArray *tempMutArray = isExpand ? self.manager.showItems : self.manager.showItems.mutableCopy;
    
    for (ZKTreeItem *item in items) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[tempMutArray indexOfObject:item] inSection:0];
        NSInteger updateNum = [self.manager expandItem:item];
        NSArray *tmpArray = [self getUpdateIndexPathsWithCurrentIndexPath:indexPath andUpdateNum:updateNum];
        [updateIndexPaths addObjectsFromArray:tmpArray];
    }
    
    if (self.isShowExpandAnimation) {
        if (isExpand) {
            [tableView insertRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [tableView deleteRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else {
        [tableView reloadData];
    }
}

- (NSArray<NSIndexPath *> *)getUpdateIndexPathsWithCurrentIndexPath:(NSIndexPath *)indexPath andUpdateNum:(NSInteger)updateNum
{
    NSMutableArray *tmpIndexPaths = [NSMutableArray arrayWithCapacity:updateNum];
    for (NSInteger i = 0; i < updateNum; i++) {
        NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1 + i) inSection:indexPath.section];
        [tmpIndexPaths addObject:tmpIndexPath];
    }
    
    return tmpIndexPaths;
}

#pragma mark -- UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZKTreeItem *item = self.manager.showItems[indexPath.row];
    if (self.isAutoExpand && item.childItems.count != 0) {
        [self tableView:tableView didSelectItems:@[item] isExpand:!item.isExpand];
    }
    
    if ([self.delegate respondsToSelector:@selector(treeListView:didSelectRowAtIndexPath:withItem:)]) {
        [self.delegate treeListView:self didSelectRowAtIndexPath:indexPath withItem:item];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(treeListView:heightForItem:)]) {
        ZKTreeItem *item = self.manager.showItems[indexPath.row];
        return [self.delegate treeListView:self heightForItem:item];
    }
    return self.manager.showItems[indexPath.row].itemHeight;
}

#pragma mark -- UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.manager.showItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > self.manager.showItems.count) {
        return nil;
    }
    
    ZKTreeItem *item = self.manager.showItems[indexPath.row];
    ZKTreeListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.identifier forIndexPath:indexPath];
    cell.treeItem = item;
    // 私有属性，这里通过KVC赋值
    [cell setValue:@(_style) forKey:@"showStructureLine"];
    
    return cell;
}

#pragma mark -- Setter && Getter
- (UITableView *)tableView
{
    if (_tableView == nil) {
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (void)setHeaderView:(UIView *)headerView
{
    _headerView = headerView;
    _tableView.tableHeaderView = headerView;
}

- (void)setFooterView:(UIView *)footerView
{
    _footerView = footerView;
    _tableView.tableFooterView = footerView;
}

#pragma mark -- Other
- (void)dealloc
{
    NSLog(@"ZKTreeListView->销毁");
}

@end
