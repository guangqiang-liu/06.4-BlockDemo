//
//  main.m
//  06.4-block捕获对象类型的变量
//
//  Created by 刘光强 on 2020/2/5.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"

typedef void(^MyBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        MyBlock block;
        
        {
            // person默认是__strong修饰
            __strong Person *person = [[Person alloc] init];
            person.age = 10;
            
//            __weak typeof(Person) *weakP = person;
            
            // block变量强引用着^{}，编译器就会进行`copy`操作，将这个block从栈拷贝到堆上
            block = ^{
                NSLog(@"-%d", person.age);
            };
        }
       
        // 执行block，上面的person对象已经出了函数作用域，但是还没有释放
        block();
    }
    return 0;
}
