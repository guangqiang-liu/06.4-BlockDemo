# 06.4-block捕获对象类型的变量

前面讲解的block变量捕获，我们讲解了block捕获基本数据类型的情况，下面我们再来分析下捕获对象类型的auto变量，分析下block的底层内存布局情况，我们创建一个新工程，创建一个`Person`类，代码如下：

`Person`类：

```
@interface Person : NSObject

@property (nonatomic, assign) int age;
@end


@implementation Person

- (void)dealloc {
    NSLog(@"%s",__func__);
}
@end
```

`main`函数：

```
typedef void(^MyBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        MyBlock block;
        
        {
            // person默认是__strong修饰符修饰的
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
```

我们执行命令`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m`将`main.m`文件转换为c++文件，转换后代码如下：

`main`：函数

```
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool;
        
        MyBlock block;
        {
            Person *person = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"));
            
            ((void (*)(id, SEL, int))(void *)objc_msgSend)((id)person, sel_registerName("setAge:"), 10);

            block = &__main_block_impl_0(
                                         __main_block_func_0,
                                         &__main_block_desc_0_DATA,
                                         person,
                                         570425344
                                         );
        }
        
        // 执行block
        block->FuncPtr(block);
    }
    return 0;
}
```

`block`结构体：

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
    
  // 在block结构体内部，person对象是强指针引用还是弱指针引用，取决于block内部访问的auto变量是__strong修饰还是__weak修饰的
  Person *__strong person;
    
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, Person *__strong _person, int flags=0) : person(_person) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

`__main_block_desc_0`：结构体：

```
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
    
    // 只有在block内部访问了auto对象类型的变量时，才会有`copy`和`dispose`函数指针存在，因为只有访问的是对象类型才需要进行内存管理相关操作
    
    // copy函数指针，指向__main_block_copy_0函数
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  
    // dispose函数指针，指向__main_block_dispose_0函数
  void (*dispose)(struct __main_block_impl_0*);
}
```

`__main_block_copy_0`函数：

```
// 当block调用copy操作，将block从栈拷贝到堆上时，就会调用此函数
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {
    /**
    _Block_object_assign:负责内存管理相关操作，也就是说这个函数会根据block结构体内部捕获的变量的引用类型进行内存管理：
     1.如果block结构体内捕获的变量是__strong类型的指针，那么这个指针就对block外面的对象进行强引用，进行retain操作，引用计数器+1
     2.如果block结构体内捕获的变量是__weak类型的指针，那么这个指针就对block外面的对象进行弱引用
     */
    _Block_object_assign(
                         (void*)&dst->person,
                         (void*)src->person,
                         3/*BLOCK_FIELD_IS_OBJECT*/
                         );
}
```

`__main_block_dispose_0`函数：

```
// 当堆中的block需要销毁时，会调用此函数
static void __main_block_dispose_0(struct __main_block_impl_0*src) {
    // block结构体内的强指针断开对外部auto变量的强引用时，进行release操作，引用计数器-1
    _Block_object_dispose(
                          (void*)src->person,
                          3/*BLOCK_FIELD_IS_OBJECT*/
                          );
}
```

block捕获对象类型auto变量底层结构分析总结如图：

![](https://imgs-1257778377.cos.ap-shanghai.myqcloud.com/QQ20200205-202220@2x.png)


讲解示例代码Demo地址：[https://github.com/guangqiang-liu/06.4-BlockDemo]()


## 更多文章
* ReactNative开源项目OneM(1200+star)：**[https://github.com/guangqiang-liu/OneM](https://github.com/guangqiang-liu/OneM)**：欢迎小伙伴们 **star**
* iOS组件化开发实战项目(500+star)：**[https://github.com/guangqiang-liu/iOS-Component-Pro]()**：欢迎小伙伴们 **star**
* 简书主页：包含多篇iOS和RN开发相关的技术文章[http://www.jianshu.com/u/023338566ca5](http://www.jianshu.com/u/023338566ca5) 欢迎小伙伴们：**多多关注，点赞**
* ReactNative QQ技术交流群(2000人)：**620792950** 欢迎小伙伴进群交流学习
* iOS QQ技术交流群：**678441305** 欢迎小伙伴进群交流学习