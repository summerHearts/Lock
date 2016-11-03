//
//  ViewController.m
//  Lock
//
//  Created by Kenvin on 2016/11/3.
//  Copyright © 2016年 Kenvin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NSLock
    NSLock *lock = [[NSLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        static void (^RecursiveMethod)(int);
        
        RecursiveMethod = ^(int value) {
            
            [lock lock];
            if (value > 0) {
                NSLog(@"value = %d", value); //*** -[NSLock lock]: deadlock (<NSLock: 0x6000000c90d0> '(null)')
                sleep(2);
                //在我们的线程中，RecursiveMethod是递归调用的。所以每次进入这个block时，都会去加一次锁，而从第二次开始，由于锁已经被使用了且没有解锁，所以它需要等待锁被解除，这样就导致了死锁，线程被阻塞住了
                RecursiveMethod(value - 1);
            }
            [lock unlock];
        };
        
        RecursiveMethod(5);
    });
    
    //NSRecursiveLock实际上定义的是一个递归锁，这个锁可以被同一线程多次请求，而不会引起死锁。NSRecursiveLock类定义的锁可以在同一线程多次lock，而不会造成死锁。递归锁会跟踪它被多少次lock。每次成功的lock都必须平衡调用unlock操作。只有所有的锁住和解锁操作都平衡的时候，锁才真正被释放给其他线程获得。
    
    NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        static void (^RecursiveMethod)(int);
        
        RecursiveMethod = ^(int value) {
            
            [recursiveLock lock];
            if (value > 0) {
                NSLog(@"value = %d", value);
                sleep(2);
                RecursiveMethod(value - 1);
            }
            [recursiveLock unlock];
        };
        
        RecursiveMethod(5);
    });
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        sleep(2);
        BOOL flag = [recursiveLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        if (flag) {
            NSLog(@"lock before date");
            
            [recursiveLock unlock];
        } else {
            NSLog(@"fail to lock before date");
        }
    });

    
    //主线程中
    NSConditionLock *theLock = [[NSConditionLock alloc] init];
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0;i<=2;i++){
            [theLock lock];
            NSLog(@"thread1:%d",i);
            sleep(2);
            [theLock unlockWithCondition:i];
        }
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [theLock lockWhenCondition:2];
        NSLog(@"thread2");
        [theLock unlock];
    });
    
    /*
     在线程1中的加锁使用了lock，所以是不需要条件的，所以顺利的就锁住了，但在unlock的使用了一个整型的条件，它可以开启其它线程中正在等待这把钥匙的临界地，而线程2则需要一把被标识为2的钥匙，所以当线程1循环到最后一次的时候，才最终打开了线程2中的阻塞。但即便如此，NSConditionLock也跟其它的锁一样，是需要lock与unlock对应的，只是lock,lockWhenCondition:与unlock，unlockWithCondition:是可以随意组合的，当然这是与你的需求相关的。
     */
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
