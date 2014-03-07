//
//  shareData.h
//  toeic_BI
//
//  Created by hirata on 2014/01/30.
//  Copyright (c) 2014年 hirata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface shareData : NSObject
+ (id)instance;

// データをキーとともに追加します
- (void)setData:(id)anObject forKey:(id) aKey;

// 指定したキーに対応するデータを返します
- (id)getDataForKey:(id)aKey;

// 指定したキーと、それに対応するデータを、辞書から削除します
- (void)removeDataForKey:(id)aKey;

@end