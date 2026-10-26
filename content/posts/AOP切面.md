---
title: AOP切面(java新手)
date: 2025-11-23 18:30:00+08:00
draft: false
categories: ["技术"]
tags:
- Java
- AOP切面
- Web开发
- 基础编程
---

# AOP切面(java新手)

## 🌟 一、为什么要用 AOP？

想象一下：你在开发一个电商网站，有几十个接口，比如

- 用户登录
- 下单
- 查看商品
- 修改地址
- 支付订单

这些功能都属于“业务逻辑”（核心功能）。但你发现，**每个接口都需要做两件事**：

1. **记录日志**（谁在什么时候调用了哪个接口？）
2. **检查用户有没有权限**（比如普通用户不能删别人订单）

如果不用 AOP，你可能会在**每个方法里手动写日志和权限检查代码**，像这样

问题来了：

- 代码重复！每个方法都要写一样的日志和权限。
- 业务逻辑被“污染”了，看不清核心功能。
- 如果哪天要改日志格式？得改几十个地方！

👉 **AOP 就是为了解决这种“横着切”的公共问题而生的！**

👉 **AOP 就是为了解决这种“横着切”的公共问题而生的！**

> ✅ **AOP 的核心思想**：
>  把那些**和业务无关但又到处要用的功能**（比如日志、权限、事务、防重提交）**抽出来**，写在一个地方，自动“织入”到需要的地方。
>  业务代码只管做自己的事，干净清爽！

## 🧩 二、怎么理解 AOP？用两个真实例子

## ✅ 自动记录接口日志（最常见！）

#### 场景：

你想知道哪些用户调用了哪些接口、花了多长时间。

#### 不用 AOP（麻烦）：

每个 Controller 方法里手写 `logger.info(...)`。

#### 用 AOP（优雅）：

1. **定义一个“切面”类**（专门处理日志）：

```java
@Aspect
@Component
public class LogAspect {

    private static final Logger logger = LoggerFactory.getLogger(LogAspect.class);

    // 定义“切入点”：所有 Controller 包下的 public 方法
    @Pointcut("execution(public * com.example.controller..*.*(..))")
    public void controllerMethods() {}

    // 在方法执行前记录开始
    @Before("controllerMethods()")
    public void logBefore(JoinPoint joinPoint) {
        String methodName = joinPoint.getSignature().getName();
        Object[] args = joinPoint.getArgs();
        logger.info("调用方法: {}, 参数: {}", methodName, Arrays.toString(args));
    }

    // 在方法执行后记录耗时
    @Around("controllerMethods()")
    public Object logTime(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.currentTimeMillis();
        Object result = joinPoint.proceed(); // 执行原方法
        long time = System.currentTimeMillis() - start;
        logger.info("方法 {} 耗时 {}ms", joinPoint.getSignature().getName(), time);
        return result;
    }
}
```

1. **你的业务代码完全不用改！**

```java
@RestController
public class OrderController {
    @PostMapping("/order")
    public String createOrder(@RequestBody Order order) {
        // 只写业务逻辑！日志自动加上了
        orderService.save(order);
        return "success";
    }
}
```

✅ **效果**：只要调用 `/order`，AOP 自动帮你打日志、算时间，**业务代码零侵入**！

#### 看懂 AOP 是怎么运行的

🌟 **先说清楚：AOP 到底是怎么“插进去”的？**

> 🔑 **核心原理一句话**：
>  Spring 在启动时，会偷偷把你的业务类（比如 `OrderController`）**替换成一个“代理对象”**。
>  当你调用 `createOrder()` 时，其实先执行的是 AOP 里的代码，然后再去调真正的业务方法。

这就像你点外卖：

- 你以为直接联系厨师（业务方法）
- 其实中间有个“智能前台”（代理对象）：先检查你是不是会员（权限）、记录你点了什么（日志），再通知厨房做菜

------

现在我们来逐行解读两个例子。

------

#### ✅ 自动记录接口日志（逐行详解）

**第一步：定义切面类（LogAspect.java）**

```java
@Aspect
@Component
public class LogAspect {
```

- `@Aspect`：告诉 Spring：“我是一个切面类，里面装的是横切逻辑（比如日志）”
- `@Component`：让 Spring 能扫描到这个类，并把它放进容器里（否则不会生效）

> 💡 就像你告诉公司：“我是专门负责打卡考勤的人”，公司才会让你上岗。

```java
    @Pointcut("execution(public * com.example.controller..*.*(..))")
    public void controllerMethods() {}
```

- `@Pointcut`：定义“在哪些地方插入逻辑”

- 表达式含义（大白话）：

  - `execution(...)`：匹配方法执行

  - `public *`：任意返回值的 public 方法

  - ```
    com.example.controller..*.*(..)
    ```

    - `com.example.controller`：包名
    - `..`：包括所有子包（比如 controller.user, controller.order）
    - `*.*(..)`：任意类的任意方法，任意参数

    ✅ 这句话的意思是：**所有 Controller 包下的 public 方法，都是我的目标！**

    > 💡 这个方法本身是空的，只是个“标记”，方便后面引用，就像给一堆门贴上“红色标签”，后面说“所有红标签的门都要检查”。

------

```java
    @Before("controllerMethods()")
    public void logBefore(JoinPoint joinPoint) {
        String methodName = joinPoint.getSignature().getName();
        Object[] args = joinPoint.getArgs();
        logger.info("调用方法: {}, 参数: {}", methodName, Arrays.toString(args));
    }
```

- `@Before("controllerMethods()")`：在“红标签的门”被打开**之前**，执行这个方法

-  `JoinPoint joinPoint`：代表“当前正在被调用的那个方法”的上下文信息
  - `joinPoint.getSignature().getName()` → 获取方法名，比如 `"createOrder"`
  - `joinPoint.getArgs()` → 获取传入的参数，比如 `[Order{id=1, userId=123}]`

✅ 效果：用户一调接口，立刻打印：
 `调用方法: createOrder, 参数: [Order{id=1, userId=123}]`

> 💡 就像门卫在你进门时问：“你是谁？来干嘛？”然后记在本子上。

------

```java
    @Around("controllerMethods()")
    public Object logTime(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.currentTimeMillis();
        Object result = joinPoint.proceed(); // ⭐ 关键！执行真正的业务方法
        long time = System.currentTimeMillis() - start;
        logger.info("方法 {} 耗时 {}ms", joinPoint.getSignature().getName(), time);
        return result;
    }
```

- `@Around`：**环绕通知**——最强大的通知类型，可以在方法前后都干活

- `ProceedingJoinPoint`：是 `JoinPoint` 的升级版，多了 `.proceed()` 方法

-    `joinPoint.proceed()`：**真正去调用原始的业务方法**（比如 `orderService.save(order)`）

​              这行代码之前：相当于“前置通知”

​              这行代码之后：相当于“后置通知”

✅ 执行流程：

1. 记录开始时间
2. **执行真正的 createOrder()**
3. 计算耗时
4. 打印日志
5. 把业务方法的返回值原样返回（不能丢！）

> 💡 就像快递员送包裹：
>
> - 先扫码登记（记录开始）
> - 然后真的去送货（proceed）
> - 送到后回传签收单（return result）
> - 同时记录用了多久

### 验证测试结果

### 🧪 场景回顾

你有这样一个 Controller：

```java
@RestController
public class OrderController {

    private final Logger logger = LoggerFactory.getLogger(OrderController.class);

    @PostMapping("/order")
    public String createOrder(@RequestBody Order order) {
        // 模拟业务处理：比如保存订单
        logger.info("【业务层】正在保存订单: {}", order);
        return "订单创建成功！";
    }
}
```

同时，你有一个 AOP 切面类（简化版）：

```java
@Aspect
@Component
public class LogAspect {

    private static final Logger logger = LoggerFactory.getLogger(LogAspect.class);

    @Pointcut("execution(public * com.example.controller..*.*(..))")
    public void controllerMethods() {}

    @Before("controllerMethods()")
    public void logBefore(JoinPoint joinPoint) {
        String methodName = joinPoint.getSignature().getName();
        Object[] args = joinPoint.getArgs();
        logger.info(">>> [AOP前置] 调用方法: {}, 参数: {}", methodName, Arrays.toString(args));
    }

    @Around("controllerMethods()")
    public Object logTime(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.currentTimeMillis();
        logger.info(">>> [AOP环绕开始] 准备执行方法: {}", joinPoint.getSignature().getName());

        // ⭐ 关键：真正执行 createOrder()
        Object result = joinPoint.proceed();

        long time = System.currentTimeMillis() - start;
        logger.info(">>> [AOP环绕结束] 方法 {} 执行完毕，耗时: {} ms", 
                    joinPoint.getSignature().getName(), time);
        return result;
    }
}
```

> 💡 注意：`@Before` 和 `@Around` 同时存在时，**`@Around` 会包裹 `@Before`**（因为 `@Around` 是最外层的代理逻辑）。

------

##### 🖥️ 假设你发送一个请求：

```http
POST http://localhost:8080/order
Content-Type: application/json

{
  "userId": 1001,
  "productId": 2002,
  "amount": 99.9
}
```

##### ✅ 程序执行顺序 + 控制台输出（逐行）

当 Spring Boot 收到这个请求，会发生以下事情：

##### **第一步：进入 `@Around`（最外层）**

```log
>>> [AOP环绕开始] 准备执行方法: createOrder
```

##### 第二步：执行 `@Before`

```
>>> [AOP前置] 调用方法: createOrder, 参数: [Order(userId=1001, productId=2002, amount=99.9)]
```

> 🔍 参数显示的是 `Order` 对象的 `toString()` 结果。如果你没重写 `toString()`，可能显示类似 `com.example.Order@1a2b3c`。建议给 `Order` 加 Lombok 的 `@Data` 或手动重写 `toString()`。

##### 第三步：执行真正的业务方法 `createOrder()`

```
【业务层】正在保存订单: Order(userId=1001, productId=2002, amount=99.9)
```

##### 第四步：回到 `@Around`，记录耗时并返回

```
>>> [AOP环绕结束] 方法 createOrder 执行完毕，耗时: 15 ms
```

> 💡 耗时是模拟值，实际可能是几毫秒到几十毫秒。

------

##### 📋 最终完整控制台输出（按顺序）

```
>>> [AOP环绕开始] 准备执行方法: createOrder
>>> [AOP前置] 调用方法: createOrder, 参数: [Order(userId=1001, productId=2002, amount=99.9)]
【业务层】正在保存订单: Order(userId=1001, productId=2002, amount=99.9)
>>> [AOP环绕结束] 方法 createOrder 执行完毕，耗时: 15 ms
```

同时，HTTP 接口会正常返回：

```
"订单创建成功！"
```

------

##### 🎯 关键结论

1. **AOP 的日志先于业务代码打印** → 说明它确实在“前面”拦截了。
2. **业务逻辑完全不受影响** → 该保存订单还是保存，该返回结果还是返回。
3. **你不用在每个方法里写日志** → 只要方法在 `controller` 包下，自动生效！
4. **性能监控也自动完成** → 耗时直接算出来了，可用于报警或优化。

------

### 💡 小贴士（避免踩坑）

- 如果没看到 AOP 日志？检查：
  - 切面类是否加了 `@Component`
  - Spring Boot 主启动类是否扫描到了切面包（通常默认扫描主类所在包及子包）
  - 方法是不是 `public`（Spring AOP 默认只代理 public 方法）
- 不想用 `@Before` + `@Around` 两个？其实只用 `@Around` 就够了，它能干所有事！

### 我的疑问：为什么 `@Around` 比 `@Before` 先执行？

#### ✅ 简短答案：

> **不是 `@Around` 比 `@Before` “先执行”，而是 `@Around` 包裹了 `@Before` 和业务方法。**
>  控制台看起来 `@Around` 的“开始日志”先打印，是因为它在最外层。

------

#### 🧠 详细解释（关键！）

Spring AOP 的底层是通过 **代理模式** 实现的。当一个方法同时被 `@Before` 和 `@Around` 切入时，**Spring 只会生成一个代理对象**，而这个代理的逻辑结构是这样的：

```java
// 伪代码：Spring 生成的代理逻辑
public Object createOrderProxy(Order order) {
    // ———————— @Around 的开头 ————————
    log(">>> [AOP环绕开始] 准备执行方法: createOrder");
    
    try {
        // ———————— 执行所有 @Before ————————
        log(">>> [AOP前置] 调用方法: createOrder, 参数: ...");
        
        // ———————— 执行真正的业务方法 ————————
        Object result = realTarget.createOrder(order);
        
        // ———————— 执行 @AfterReturning（如果有）————
        
        return result;
    } finally {
        // ———————— @Around 的结尾 ————————
        log(">>> [AOP环绕结束] 方法 createOrder 耗时: ... ms");
    }
}
```

所以实际执行顺序是：

```java
@Around 开始部分
   ↓
@Before
   ↓
真正的业务方法（createOrder）
   ↓
@After / @AfterReturning（如果有）
   ↓
@Around 结束部分
```

✅ 因此：

- `@Around` 的 **第一行代码**（记录开始时间）最先执行 → 所以你看到它先打印。
- 但 `@Before` 是在 `@Around` **内部**、业务方法**之前**执行的。

> 🔸 类比：
>  你点外卖：
>
> - 骑手（`@Around`）先说：“我出发去取餐了！”（打印开始）
> - 到店后，店员（`@Before`）说：“已接单，正在打包！”
> - 厨师（业务方法）开始炒菜
> - 骑手拿到餐后说：“送餐完成，共用时25分钟！”（打印结束）

所以**不是谁“优先级高”**，而是 `@Around` 是一个“大盒子”，把 `@Before` 和业务代码都装进去了。

## ✅ 防止重复提交（幂等性控制）

#### 场景：

用户狂点“支付”按钮，可能造成重复扣款！你需要**5秒内同一个用户+同一个商品只能下单一次**。

你需要借助 **Spring 的 SpEL（Spring Expression Language）引擎** 来解析表达式

#### 步骤 1：创建一个工具类（推荐）

```java
import org.springframework.core.LocalVariableTableParameterNameDiscoverer;
import org.springframework.expression.ExpressionParser;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.expression.spel.support.StandardEvaluationContext;

public class SpelUtil {

    private static final ExpressionParser PARSER = new SpelExpressionParser();
    private static final LocalVariableTableParameterNameDiscoverer NAME_DISCOVERER 
        = new LocalVariableTableParameterNameDiscoverer();

    public static String parse(String spel, Object[] args, Class<?> targetClass) {
        if (spel == null || spel.isEmpty()) {
            return "";
        }

        // 获取方法参数名（比如 order, userId）
        String[] paramNames = NAME_DISCOVERER.getParameterNames(targetClass.getDeclaredMethods()[0]); // 简化版，实际需匹配方法

        // 创建上下文
        StandardEvaluationContext context = new StandardEvaluationContext();
        for (int i = 0; i < args.length; i++) {
            context.setVariable(paramNames[i], args[i]);
        }

        // 解析表达式
        return PARSER.parseExpression(spel).getValue(context, String.class);
    }
}
```

> 💡 但上面代码有缺陷（方法匹配不准确），更稳妥的做法是结合 AOP 的 `MethodSignature`。

------

#### 步骤 2：在切面中正确使用（完整可运行版）

```java
@Aspect
@Component
public class IdempotentAspect {

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Around("@annotation(idempotent)")
    public Object checkIdempotent(ProceedingJoinPoint joinPoint, Idempotent idempotent) throws Throwable {
        // 1. 获取方法签名
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();

        // 2. 获取参数名（需要编译时保留参数名：Java 8+ 默认开启，或加 -parameters）
        String[] paramNames = signature.getParameterNames();
        Object[] args = joinPoint.getArgs();

        // 3. 构建 SpEL 上下文
        StandardEvaluationContext context = new StandardEvaluationContext();
        for (int i = 0; i < paramNames.length; i++) {
            context.setVariable(paramNames[i], args[i]);
        }

        // 4. 解析表达式，得到真实 key
        String keyExpression = idempotent.key(); // 如 "#order.userId + '-' + #order.productId"
        String realKey = new SpelExpressionParser()
                .parseExpression(keyExpression)
                .getValue(context, String.class);

        // 5. 构造 Redis 锁 key
        String lockKey = "idempotent:" + realKey;

        // 6. 尝试加锁
        Boolean isSet = redisTemplate.opsForValue()
                .setIfAbsent(lockKey, "1", idempotent.expire(), TimeUnit.SECONDS);

        if (Boolean.TRUE.equals(isSet)) {
            return joinPoint.proceed();
        } else {
            throw new RuntimeException("请勿重复提交！");
        }
    }
}
```

------

### 🧪 举个实际运行例子

**你的 Controller：**

```java
@PostMapping("/comment")
@Idempotent(key = "#userId + '-' + #productId", expire = 10)
public String addComment(
    @RequestParam Long userId,
    @RequestParam Long productId,
    @RequestBody String content) {
    // 业务逻辑
}
```

**用户请求：**

```
POST /comment?userId=1001&productId=2002
Body: "很好！"
```

**切面执行时：**

- `keyExpression = "#userId + '-' + #productId"`
- `paramNames = ["userId", "productId", "content"]`
- `args = [1001L, 2002L, "很好！"]`
- SpEL 解析后：`realKey = "1001-2002"`
- `lockKey = "idempotent:1001-2002"`

✅ 完美实现“同一用户对同一商品10秒内只能评论一次”

### 逐行解释

#### 🧩 整体目标

我们要实现一个功能：

> 当用户调用 `/comment` 接口时，如果短时间内重复提交（比如连续点两次按钮），系统只处理一次，第二次就提示“请勿重复提交”。

为了做到这一点，我们使用了：

- **AOP（面向切面编程）**：在方法执行前后插入逻辑。
- **SpEL（Spring Expression Language）**：动态从方法参数中提取数据拼成唯一 key。
- **Redis**：用它做分布式锁，确保同一个请求不会被重复处理。

------

#### 第一部分：`SpelUtil.java`（工具类）

```java
import org.springframework.core.LocalVariableTableParameterNameDiscoverer;
import org.springframework.expression.ExpressionParser;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.expression.spel.support.StandardEvaluationContext;
```

✅ **大白话：**

这些是 Spring 提供的“工具包”，用来：

- 获取方法的参数名字（比如 `userId`、`productId`）
- 解析像 `"#userId + '-' + #productId"` 这样的表达式
- 创建一个“变量容器”，把参数值放进去，让表达式能读到

✅ **语法原理：**

- `LocalVariableTableParameterNameDiscoverer`：通过 Java 字节码获取方法参数名（需要编译时保留参数名，Java 8+ 默认支持）。
- `SpelExpressionParser`：Spring 的表达式解析器，能理解 `#xxx` 这种写法。
- `StandardEvaluationContext`：表达式运行时的上下文环境，相当于一个“变量表”。

##### 1、public class SpelUtil{}

------

```java
public class SpelUtil {

    private static final ExpressionParser PARSER = new SpelExpressionParser();
    private static final LocalVariableTableParameterNameDiscoverer NAME_DISCOVERER 
        = new LocalVariableTableParameterNameDiscoverer();
```

✅ **大白话：**

创建两个“万能工具”：

- 一个叫 `PARSER`，专门负责“读懂”像 `#userId + '-' + #productId` 这样的字符串。
- 一个叫 `NAME_DISCOVERER`，专门负责“猜出”方法的参数叫什么名字（比如第一个参数是不是叫 `userId`）。

它们都是 `static final`，意思是整个程序只用一份，省资源。

**🧩 第一行：`public class SpelUtil`**

**💬 大白话：**

这是一个叫 `SpelUtil` 的“工具箱”，专门用来处理 Spring 表达式（SpEL）相关的事情。
 比如：把 `"#userId + '-' + #productId"` 这种字符串变成真正的值。

> 就像你有一个“计算器工具类”，别人可以直接拿来算表达式，不用自己从头写。

**🔬 语法原理：**

- `public`：公开类，其他包也能用。
- `class SpelUtil`：定义一个普通 Java 类。
- 命名习惯：以 `Util` 结尾，表示这是个**工具类**（通常只包含静态方法，不实例化）。

------

**🧩 第二行：`private static final ExpressionParser PARSER = new SpelExpressionParser();`**

我们拆成几个关键词来看：

✅ `private`

- 只有这个类内部能访问，外面不能直接调用 `PARSER`。
- 符合封装原则：工具的“零件”不暴露给用户。

✅ `static`

- **属于类本身，不属于某个对象**。
- 整个程序运行期间，只创建**一份** `PARSER`。
- 调用时不用 `new SpelUtil()`，直接通过类名隐式使用（因为是私有的，其实外部也看不到）。

> 🌰 比如：全公司共用一台打印机，不是每人买一台。

✅ `final`

- 这个变量一旦赋值，就不能再改了。
- 防止不小心被覆盖，保证线程安全（因为它是无状态的，可以安全共享）。

✅ `ExpressionParser PARSER`

- `ExpressionParser` 是 Spring 提供的接口，代表“表达式解析器”。
- `PARSER` 是变量名，全大写是常量命名习惯（虽然 Java 没强制，但大家都这么写）。

✅ `new SpelExpressionParser()`

- 创建一个具体的解析器实例。
- `SpelExpressionParser` 是 Spring 实现 `ExpressionParser` 接口的类，专门解析 **SpEL（Spring Expression Language）** 表达式。

🎯 它能理解：

- `#name`
- `#order.price > 100`
- `'Hello ' + #user.name`
- `T(java.lang.Math).random()`（调用静态方法）

- ）

------

💬 **整体大白话总结这行：**

> “我准备了一个万能的‘表达式翻译官’，叫 `PARSER`，它一辈子就干一件事：把像 `#userId + '-' + #productId` 这样的字符串，翻译成真正的值。”

而且这个翻译官是：

- 全局唯一的（`static`）
- 不会被换掉（`final`）
- 别人看不见（`private`），只能通过我提供的方法间接使用

**🧩 第三行：`private static final LocalVariableTableParameterNameDiscoverer NAME_DISCOVERER = ...`**

同样拆解：

**✅ `LocalVariableTableParameterNameDiscoverer`**

这是 Spring 提供的一个**参数名发现器**。

💬 **大白话：**

> “我想知道某个方法的参数到底叫什么名字，比如是叫 `userId` 还是 `uid`？
>  但 Java 编译后，默认会把参数名变成 `arg0`, `arg1`……
>  这个工具能从字节码里‘挖出’原始的参数名！”

🔬 **技术细节：**

- 它通过读取 `.class` 文件中的 **LocalVariableTable**（本地变量表）来获取真实参数名。
- **前提**：编译时必须保留调试信息（Java 8+ 默认开启，或显式加 `-g` 或 `-parameters`）。
- 如果没保留，它会返回 `null`！

> ⚠️ 所以这个工具**不可靠**——这也是为什么你在 AOP 中应该用 `MethodSignature.getParameterNames()`，而不是它！

------

**✅ `NAME_DISCOVERER`**

- 变量名，意思是“参数名发现者”。
- 同样是 `private static final`：全局唯一、不可变、内部使用。

------

💬 整体大白话总结这行：

> “我还准备了一个‘考古学家’，叫 `NAME_DISCOVERER`，它的任务是从编译后的代码里，把方法参数的原始名字‘挖’出来，比如 `userId`、`productId`。”

但要注意：

> 这个“考古学家”有时候会空手而归（如果编译时没留线索）！

------

##### 2、public static String parse()

```java
    public static String parse(String spel, Object[] args, Class<?> targetClass) {
        if (spel == null || spel.isEmpty()) {
            return "";
        }
```

**✅ 大白话：**

这是一个工具方法，输入：

- 一段表达式（比如 `"#userId + '-' + #productId"`）
- 方法的实际参数值（比如 `[1001, 2002]`）
- 方法所在的类（比如 `CommentController.class`）

如果表达式是空的，就直接返回空字符串。

------

##### 3、NAME_DISCOVERER.getParameterNames

```java
        // 获取方法参数名（比如 order, userId）
        String[] paramNames = NAME_DISCOVERER.getParameterNames(targetClass.getDeclaredMethods()[0]); // 简化版，实际需匹配方法
```

**✅ 大白话（⚠️注意这里有问题）：**

这行代码想拿到方法的参数名字，比如 `userId`, `productId`。

但它有个 **严重问题**：`targetClass.getDeclaredMethods()[0]` 是随便拿类里的第一个方法！
 如果这个类有多个方法，很可能拿错！

> 🚨 所以这个 `SpelUtil` 其实是个“简化版示例”，**不能直接用在生产环境**。后面我们会看到正确的做法在 `IdempotentAspect` 里。

**✅ 语法原理：**

- `getDeclaredMethods()` 返回类中所有方法（包括 private）。
- `[0]` 表示取第一个，但不一定是你要的那个方法。



------

##### 4、StandardEvaluationContext context

```java
// 创建上下文
StandardEvaluationContext context = new StandardEvaluationContext();
for (int i = 0; i < args.length; i++) {
    context.setVariable(paramNames[i], args[i]);
}
```

🧩 第一行：`StandardEvaluationContext context = new StandardEvaluationContext();`

**💬 大白话**：

> “我要开始算一个表达式了，先准备一个‘小本子’，用来记变量。”

就像你做数学题前，老师说：“已知：x = 5，y = 3”，这个“已知条件”的地方，就是 **上下文（context）**。

在这里，这个“小本子”叫 `context`，它是 Spring 专门用来让 **SpEL 表达式** 能读到变量的地方。

🎯 举个生活例子：

你想算：`#userId + '-' + #productId`
 但 Spring 不知道 `#userId` 是多少啊！
 所以你要先告诉它：“听着，我现在告诉你：`userId=1001`，`productId=2002`”
 这个“告诉”的过程，就需要一个“记事本”——就是这个 `context`。

------

**🔬 语法原理：**

- `StandardEvaluationContext` 是 Spring 提供的一个类，表示 **SpEL 表达式的运行环境**。
- 它可以存储：
  - 变量（variables）
  - 函数（functions）
  - 类型查找器（type locators）等
- 在求值时，表达式会从这个上下文中查找 `#xxx` 这样的变量。

✅ 简单说：没有它，`#userId` 就是“无名之辈”，有了它，`#userId` 才有值。

------

**🧩 第二部分：`for` 循环**

```java
for (int i = 0; i < args.length; i++) {
    context.setVariable(paramNames[i], args[i]);
}
```

我们拆开来看。

------

**💬 大白话：**

> “我现在有一堆参数：
>
> - 参数名字是：`["userId", "productId", "content"]`
> - 实际值是：`[1001, 2002, "好评！"]`
>
> 我要把它们一个个放进‘小本子’里，变成：
>
> - `userId = 1001`
> - `productId = 2002`
> - `content = "好评！"`
>
> 这样后面算表达式的时候，就能用 `#userId` 拿到 1001 了。”

------

**🔬 语法原理：**

**`paramNames[i]`：参数名**

- 来自 `signature.getParameterNames()`

- 比如方法是：

  ```
  public String addComment(Long userId, Long productId, String content)
  ```

- 那么 `paramNames = ["userId", "productId", "content"]`

> ⚠️ 注意：必须编译时加 `-parameters` 参数，否则可能得到 `arg0, arg1, arg2`

**`args[i]`：参数值**

- 来自 `joinPoint.getArgs()`

- 是实际传进来的数据，比如：

  ```
  [1001L, 2002L, "服务很好！"]
  ```

**`context.setVariable(name, value)`**

- 把一个变量注册到 SpEL 上下文中
- 之后在表达式中就可以用 `#name` 来引用它

✅ 举例：

| 代码                                     | 效果                            |
| ---------------------------------------- | ------------------------------- |
| `context.setVariable("userId", 1001)`    | 之后 `#userId` 就等于 `1001`    |
| `context.setVariable("content", "好评")` | 之后 `#content` 就等于 `"好评"` |

------

**🎯 举个完整例子**

假设你调用了这个接口：



##### 5、return PARSER.parseExpression(spel)

✅ 代码行：

```
return PARSER.parseExpression(spel).getValue(context, String.class);
```

这行代码是整个 `SpelUtil.parse()` 方法的“最后一击”——真正去执行 SpEL 表达式，得到结果。

------

**🧠 大白话解释（像聊天一样）**

想象你写了一个“数学题”一样的字符串：

> ```
> "#userId + '-' + #productId"
> ```

这其实不是一个普通字符串，而是一个“待计算的公式”。
 现在你要让 Spring 帮你“算出答案”。

这个过程分三步：

1. **把公式读一遍** → `parseExpression(spel)`

Spring 说：“哦，这是个拼接字符串的表达式，要用到 `#userId` 和 `#productId`。”

**看看变量有没有** → 需要一个“上下文”（context）”

1. **看看变量有没有** → 需要一个“上下文”（context）
    就像你做数学题时，老师说：“已知 x=1001, y=2002”，这里的 context 就是“已知条件”。
2. **开始计算结果** → `.getValue(context, String.class)`
    Spring 拿着上下文里的值，代入公式：
   - `#userId` → 1001
   - `#productId` → 2002
   - 拼起来就是 `"1001-2002"`

最后把这个结果返回出去。

🔚 所以这行代码的意思就是：

> “请把 `spel` 这个表达式，结合我给的参数值（context），算出一个字符串结果。”

------

**🔬 语法原理拆解**

我们把它拆成三部分来看：

1️⃣ `PARSER`

```
private static final ExpressionParser PARSER = new SpelExpressionParser();
```

- `ExpressionParser` 是 Spring 提供的接口，专门用来解析表达式。
- `SpelExpressionParser` 是它的实现类。
- `PARSER` 是一个静态对象，整个程序只创建一次，效率高。

👉 它的作用：把字符串变成可执行的“表达式对象”。

------

2️⃣ `.parseExpression(spel)`

```
PARSER.parseExpression(spel)
```

- 把传进来的字符串（比如 `"#userId + '-' + #productId"`）解析成一个内部结构（AST，抽象语法树）。
- 这一步只是“编译”，还没执行。
- 如果表达式写错了，比如 `#user.idd`（拼错字段），这里会抛异常。

✅ 举个例子：

| 输入                           | 结果               |
| ------------------------------ | ------------------ |
| `"#name"`                      | 取变量 name 的值   |
| `"#order.price * 0.9"`         | 取 price 的 90%    |
| `"T(java.lang.Math).random()"` | 调用 Java 静态方法 |

SpEL 功能很强，甚至能调方法、访问属性、做判断！

3️⃣ `.getValue(context, String.class)`

```
.getValue(context, String.class)
```

这才是真正的“运行”！

- `context`：就是之前设置好的“变量环境”，里面有 `userId=1001`, `productId=2002`
- `String.class`：表示你希望返回一个字符串类型的结果

Spring 会：

1. 找到 `#userId` → 从 context 中取出 `1001`
2. 找到 `#productId` → 取出 `2002`
3. 中间的 `'-'` 是字符串常量（注意单引号）
4. 拼接成 `"1001-2002"`
5. 转成 `String` 类型返回

------

**🧪 举个实际例子**

假设：

```
spel = "#userId + '-' + #productId"
args = [1001, 2002]
paramNames = ["userId", "productId"]
```

那么：

```
context.setVariable("userId", 1001);
context.setVariable("productId", 2002);
```

执行：

```
PARSER.parseExpression("#userId + '-' + #productId").getValue(context, String.class)
```

👉 返回结果是字符串：`"1001-2002"`

#### 第二部分：`IdempotentAspect.java`（真正的核心）

```java
@Aspect
@Component
public class IdempotentAspect {
```

✅ 大白话：

这是一个“切面类”，Spring 会自动扫描它（因为加了 `@Component`），并在有 `@Idempotent` 注解的方法上“插入额外逻辑”。

- `@Aspect`：告诉 Spring：“我是一个切面”
- `@Component`：告诉 Spring：“把我当普通 Bean 管理起来”

------

##### 1、@Autowired

```java
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
```

✅ 大白话：

注入 Redis 操作工具，用来存“锁”。比如存一个 key：`idempotent:1001-2002`，表示这个组合正在处理中。

------

##### 2、@Around

```java
    @Around("@annotation(idempotent)")
    public Object checkIdempotent(ProceedingJoinPoint joinPoint, Idempotent idempotent) throws Throwable {
```

🧩 第一部分：`@Around("@annotation(idempotent)")`

**💬 大白话解释：**

> “当某个方法上加了 `@Idempotent` 注解的时候，请先别急着执行它，让我先插一脚！”

这句话的意思是：

- 我要监听所有被 `@Idempotent` 标记的方法。
- 在这些方法**真正执行之前**，先运行我这个 `checkIdempotent` 方法。
- 我可以决定：是放行让它执行？还是直接拦下来？

🎯 就像你在门口装了个“门禁系统”，每个人进门前都要刷一下卡。

------

**🔬 语法原理：**

- `@Around` 是 **AOP（面向切面编程）** 的一种通知类型，叫“环绕通知”。
  - 它是最强大的一种通知，可以：
    - 在方法前做事情 ✅
    - 决定是否执行原方法 ✅
    - 在方法后做事情 ✅
    - 修改返回值 ✅
    - 捕获异常 ✅
- `"@annotation(idempotent)"` 是一个 **切点表达式（Pointcut Expression）**
  - 意思是：“匹配所有标注了 `@Idempotent` 注解的方法”
  - 其中 `idempotent` 是参数名，对应后面方法里的 `Idempotent idempotent`

📌 举个类比：

| 类比                 | 对应                           |
| -------------------- | ------------------------------ |
| 学校大门             | 被拦截的方法（如 addComment）  |
| 学生刷脸进门         | 方法被调用                     |
| 保安拦人检查         | `@Around` 切面逻辑             |
| 只有戴校徽的人才能进 | `@annotation(idempotent)` 条件 |

------

🧩 第二部分：方法签名

```java
public Object checkIdempotent(ProceedingJoinPoint joinPoint, Idempotent idempotent)
```

我们拆开看每个部分。

------

1️⃣ `public Object`

- 返回类型是 `Object`，因为我们要返回**原方法的执行结果**。
- 原方法可能是 `String`、`Map`、`void` 等，所以用最通用的 `Object` 接住。

🎯 大白话：
 “我不管你是返回字符串还是数字，我都原样交回去。”

------

2️⃣ `ProceedingJoinPoint joinPoint`

这是 AOP 的核心对象之一。

**💬 大白话：**

> “你拦住的那个正在被调用的方法，我现在把它‘打包’成一个对象，叫 `joinPoint`，你可以通过它知道：
>
> - 它是谁？（哪个类的哪个方法）
> - 它有哪些参数？
> - 它的参数叫什么名字？
> - 我现在要不要让它继续执行？”

**🔬 语法原理：**

- `JoinPoint`：代表“连接点”，即程序执行过程中的某个点（比如方法调用）。
- `ProceedingJoinPoint` 是它的子接口，多了 `.proceed()` 方法，表示“继续执行原方法”。
- 常见方法：
  - `getArgs()` → 获取参数值
  - `getSignature()` → 获取方法签名
  - `proceed()` → 放行，让原方法执行

🎯 关键作用：**控制流程是否继续向下走**

------

3️⃣ `Idempotent idempotent`

💬 大白话：

> “你不是在方法上写了 `@Idempotent(key = '...', expire = 10)` 吗？
>  我现在把那个注解本身拿过来，读里面的配置。”

比如你可以拿到：

- `idempotent.key()` → `"#userId + '-' + #productId"`
- `idempotent.expire()` → `10`

这就实现了“配置驱动”：不同方法可以用不同的 key 和过期时间。

**🔬 语法原理：**

- Spring AOP 支持自动注入注解对象到通知方法中。

- 条件：参数名必须和`@Around` 表达式中的变量一致。

  - `@Around("@annotation(idempotent)")`
  - 方法参数：`Idempotent idempotent`
  - 名字要对得上！

  ✅ 正确：

  ```
  @Around("@annotation(myAnno)")
  public void advice(MyAnnotation myAnno) { ... }
  ```

  ❌ 错误：

  ```
  @Around("@annotation(myAnno)")
  public void advice(MyAnnotation wrongName) { ... } // 找不到
  ```

  ------

  🧩 第三部分：`throws Throwable`

  💬 大白话：

  > “我在检查的时候可能会出错，比如 Redis 连不上、表达式写错了……
  >  如果真出了问题，我就把错误往上抛，让别人处理。”

  因为我们要调用 `joinPoint.proceed()`，它本身就会抛异常（比如业务逻辑异常），所以我们也要声明 `throws Throwable`。

  > `Throwable` 是所有错误和异常的“老祖宗”，包括 `Exception` 和 `Error`。

  ------

  🎯 整体理解（再串一遍）

  ```
  @Around("@annotation(idempotent)")
  public Object checkIdempotent(ProceedingJoinPoint joinPoint, Idempotent idempotent) throws Throwable {
  ```

  🔁 相当于你说：

  > “Spring 啊，请你监听所有加了 `@Idempotent` 注解的方法。
  >  当它们被调用时，先别执行，把我这个方法叫起来：
  >  把‘被拦截的方法’包装成 `joinPoint`，把注解本身当作 `idempotent` 参数传给我。
  >  我会根据注解里的配置，判断要不要放行。
  >  如果一切正常，我就让它继续执行；否则就直接抛异常拦住。
  >  出了问题我也拦不住，那就往上扔错误。”

  ------

  **🧪 举个生活化的例子**

  想象你在电影院买票：

```java
@PostMapping("/buyTicket")
@Idempotent(key = "#userId + '-' + #movieId", expire = 60)
public String buyTicket(@RequestParam Long userId, @RequestParam Long movieId) {
    // 扣钱、出票
}
```

当你点击“买票”按钮两次：

1. 第一次：
   - AOP 拦截 → `checkIdempotent` 执行
   - 算 key：`"1001-2002"`
   - Redis 没有这个 key → 设置成功 → 放行 → 买票成功 ✅
2. 第二次（1 秒后）：
   - AOP 又拦截
   - 算同样的 key：`"1001-2002"`
   - Redis 已存在 → 不放行 → 抛异常 ❌ “请勿重复提交”

👉 就像售票员说：“你刚买过这张票了，不能再买！”

**✅ 总结一句话**

> ```
> @Around("@annotation(idempotent)")
> public Object checkIdempotent(ProceedingJoinPoint joinPoint, Idempotent idempotent) throws Throwable
> ```
>
> 就像是一个“智能门卫”：
>
> - **谁来都要查**：所有带 `@Idempotent` 的方法
> - **手里有名单**：`idempotent` 注解里的配置（key、过期时间）
> - **能拦也能放**：通过 `joinPoint.proceed()` 控制是否执行原方法
> - **出事要上报**：可能抛异常，所以声明 `throws Throwable`

------

##### 3、MethodSignature signature = ......

```java
        // 1. 获取方法签名
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
```

**✅ 大白话：**

拿到“被调用的方法”本身，比如 `addComment(...)` 这个方法对象。

- `getSignature()`：拿到方法的“身份证”（签名）
- 强转成 `MethodSignature` 是为了能进一步获取参数名

##### 4、signature.getParameterNames()

✅ 大白话：

这才是**正确的方式**获取参数名！

- `signature.getParameterNames()`：直接从方法签名里拿参数名数组，比如 `["userId", "productId", "content"]`
- `joinPoint.getArgs()`：拿到实际传入的参数值，比如 `[1001, 2002, "好评！"]`

> ✅ 对比前面 `SpelUtil` 的错误做法，这里才是对的！

------

##### 5、StandardEvaluationContext context

```java
        // 3. 构建 SpEL 上下文
        StandardEvaluationContext context = new StandardEvaluationContext();
        for (int i = 0; i < paramNames.length; i++) {
            context.setVariable(paramNames[i], args[i]);
        }
```

🧩 第一行：`StandardEvaluationContext context = new StandardEvaluationContext();`

**💬 大白话：**

> “我要开始算一个表达式了，先准备一个‘小本子’，用来记变量。”

就像你做数学题前，老师说：“已知：x = 5，y = 3”，这个“已知条件”的地方，就是 **上下文（context）**。

在这里，这个“小本子”叫 `context`，它是 Spring 专门用来让 **SpEL 表达式** 能读到变量的地方。

🎯 举个生活例子：

 你想算：`#userId + '-' + #productId`

 但 Spring 不知道 `#userId` 是多少啊！

 所以你要先告诉它：“听着，我现在告诉你：`userId=1001`，`productId=2002`”

 这个“告诉”的过程，就需要一个“记事本”——就是这个 `context`。

------

**🔬 语法原理：**

- `StandardEvaluationContext` 是 Spring 提供的一个类，表示 **SpEL 表达式的运行环境**。
- 它可以存储：
  - 变量（variables）
  - 函数（functions）
  - 类型查找器（type locators）等
- 在求值时，表达式会从这个上下文中查找 `#xxx` 这样的变量。

✅ 简单说：没有它，`#userId` 就是“无名之辈”，有了它，`#userId` 才有值

------

**🧩 第二部分：`for` 循环**

```java
for (int i = 0; i < args.length; i++) {
    context.setVariable(paramNames[i], args[i]);
}
```

我们拆开来看。

------

**💬 大白话：**

> “我现在有一堆参数：
>
> - 参数名字是：`["userId", "productId", "content"]`
> - 实际值是：`[1001, 2002, "好评！"]`
>
> 我要把它们一个个放进‘小本子’里，变成：
>
> - `userId = 1001`
> - `productId = 2002`
> - `content = "好评！"`
>
> 这样后面算表达式的时候，就能用 `#userId` 拿到 1001 了。”

------

**🔬 语法原理：**

**`paramNames[i]`：参数名**

- 来自 `signature.getParameterNames()`

- 比如方法是：

  ```
  public String addComment(Long userId, Long productId, String content)
  ```

- 那么 `paramNames = ["userId", "productId", "content"]`

> ⚠️ 注意：必须编译时加 `-parameters` 参数，否则可能得到 `arg0, arg1, arg2`

**`args[i]`：参数值**

- 来自 `joinPoint.getArgs()`

- 是实际传进来的数据，比如：

  ```
  [1001L, 2002L, "服务很好！"]
  ```

**`context.setVariable(name, value)`**

- 把一个变量注册到 SpEL 上下文中
- 之后在表达式中就可以用 `#name` 来引用它

✅ 举例：

| 代码                                     | 效果                            |
| ---------------------------------------- | ------------------------------- |
| `context.setVariable("userId", 1001)`    | 之后 `#userId` 就等于 `1001`    |
| `context.setVariable("content", "好评")` | 之后 `#content` 就等于 `"好评"` |

------

**🎯 举个完整例子**

假设你调用了这个接口：

```
@PostMapping("/comment")
@Idempotent(key = "#userId + '-' + #productId")
public String addComment(
    @RequestParam Long userId,      // 实际值：1001
    @RequestParam Long productId,   // 实际值：2002
    @RequestBody String content) {  // 实际值："服务很棒"
    // ...
}
```

那么：

| 变量         | 值                                   |
| ------------ | ------------------------------------ |
| `paramNames` | `["userId", "productId", "content"]` |
| `args`       | `[1001, 2002, "服务很棒"]`           |

循环执行后，`context` 里就存了：

| 变量名      | 值           |
| ----------- | ------------ |
| `userId`    | `1001`       |
| `productId` | `2002`       |
| `content`   | `"服务很棒"` |

然后你写表达式：

```
"#userId + '-' + #productId"
```

Spring 就能从 `context` 中找到：

- `#userId` → `1001`
- `#productId` → `2002`
- 拼成 `"1001-2002"`

🎯 成功生成 Redis 的 key！

------

##### 6、String keyExpression = idempotent.key()

🧩 第一行：`String keyExpression = idempotent.key();`

**💬 大白话：**

> “先看看用户在注解里写了什么表达式。”

比如你在 Controller 方法上这么写：

```java
@Idempotent(key = "#userId + '-' + #productId", expire = 10)
2public String addComment(Long userId, Long productId, ...) { ... }
```

那么 `idempotent.key()` 就会返回字符串：

```java
"#userId + '-' + #productId"
```

这个字符串不是普通文本，而是一个“模板”或“公式”，等着我们去“填空”。

🎯 就像你写了一个 Excel 公式：`=A1 & "-" & B1`，但还没代入真实单元格的值。

------

🔬 语法原理：

`idempotent` 是方法上的 `@Idempotent` 注解对象（由 Spring AOP 自动注入）。

`key()` 是注解中的一个属性（方法），返回 `String` 类型。

注解定义大概是这样的：

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Idempotent {
    String key();     // ← 这就是 .key() 的来源
    int expire() default 5;
}
```

✅ 所以这行代码只是**读取配置**，没有计算。

------

**🧩 第二行（核心）：解析并求值**

```java
String realKey = new SpelExpressionParser()
        .parseExpression(keyExpression)
        .getValue(context, String.class);
```

我们拆成三步来看：

------

✅ 第一步：`new SpelExpressionParser()`

**💬 大白话：**

> “请召唤一位‘表达式翻译官’！”

这位翻译官专门负责读懂像 `"#userId + '-' + #productId"` 这样的“Spring 表达式语言（SpEL）”。

**🔬 语法原理：**

- `SpelExpressionParser` 是 Spring 提供的标准 SpEL 解析器。
- 每次 `new` 一个也可以，但通常建议复用（不过这里只用一次，问题不大）。
- 它实现了 `ExpressionParser` 接口。

------

✅ 第二步：`.parseExpression(keyExpression)`

**💬 大白话：**

> “翻译官，请把这段‘咒语’（表达式）先理解一下，准备好怎么算。”

比如输入：

```java
"#userId + '-' + #productId"
```

翻译官会分析出：

- 这是一个字符串拼接操作
- 需要用到两个变量：`userId` 和 `productId`
- 中间夹着一个固定的 `'-'` 字符串

⚠️ 注意：这时候**还没算结果**，只是“编译”好了，准备执行。

🔬 语法原理：

- 返回一个 `Expression` 对象。
- 如果表达式语法错误（比如少引号、括号不匹配），这里会抛 `ParseException`。

✅ 举例合法表达式：

| 表达式                         | 含义                |
| ------------------------------ | ------------------- |
| `"#name"`                      | 取变量 name 的值    |
| `"#user.age > 18"`             | 判断年龄是否大于 18 |
| `"T(java.lang.Math).random()"` | 调用静态方法        |

✅ 第三步：`.getValue(context, String.class)`

**💬 大白话：**

> “现在，请结合我给你的‘变量本子’（context），把这个表达式真正算出来，并且结果要是一个字符串！”

比如：

- `context` 里有：`userId=1001`, `productId=2002`
- 表达式是：`"#userId + '-' + #productId"`
- 算出来就是：`"1001-2002"`

然后把它赋值给 `realKey`。

**🔬 语法原理：**

- ```
  getValue(EvaluationContext context, Class<T> desiredResultType)
  ```

  - `context`：提供变量环境（之前通过 `setVariable` 设置的）
  - `String.class`：告诉 Spring：“我要的结果类型是 String”

- Spring 会自动做类型转换（比如数字转字符串）

✅ 如果结果不是字符串，但能转成字符串（比如 `Long`），也会成功。
 ❌ 如果完全无法转换（比如返回一个对象又没重写 `toString`），可能报错。

------

**🎯 完整流程图（大白话版）**

```
用户写注解：
  @Idempotent(key = "#userId + '-' + #productId")

↓

程序读取：
  keyExpression = "#userId + '-' + #productId"

↓

准备变量本子（context）：
  userId → 1001
  productId → 2002

↓

表达式翻译官开工：
  把 "#userId" 替换成 1001
  把 "#productId" 替换成 2002
  拼上中间的 '-'

↓

得到真实 key：
  realKey = "1001-2002"

↓

用它去 Redis 加锁：idempotent:1001-2002
```

**💡 高级技巧（可选了解）**

SpEL 支持很多强大功能：

```java
// 三元运算
"#userId != null ? #userId : 'guest'"

// 调用方法（需注册）
"#content.trim().length() > 0"

// 访问对象属性（如果参数是对象）
"#order.user.id"
```

但要注意：**默认不能调用任意方法**（出于安全），需要额外配置 `EvaluationContext`

✅ 总结一句话

> ```java
> String realKey = new SpelExpressionParser()
>         .parseExpression(keyExpression)
>         .getValue(context, String.class);
> ```
>
> 就像是：
>
> “请把用户写的表达式模板（如 `#userId + '-' + #productId`），
>  结合当前方法的实际参数值，
>  动态计算出一个唯一的字符串 key。”

这个 key 将用于 Redis 锁，实现“防重复提交”的核心逻辑。

------

#####    7、String lockKey = "idempotent:" + realKey;

```
 // 5. 构造 Redis 锁 key
        String lockKey = "idempotent:" + realKey;

        // 6. 尝试加锁
        Boolean isSet = redisTemplate.opsForValue()
                .setIfAbsent(lockKey, "1", idempotent.expire(), TimeUnit.SECONDS);

        if (Boolean.TRUE.equals(isSet)) {
            return joinPoint.proceed();
        } else {
            throw new RuntimeException("请勿重复提交！");
        }
    }
```

**🧩 第5步：构造 Redis 锁 key**

```java
String lockKey = "idempotent:" + realKey;
```

**💬 大白话：**

> “我要在 Redis 里存一个‘标记’，表示这个请求正在处理中。
>  为了避免和其他功能冲突，我给它加个前缀 `idempotent:`，这样一看就知道是幂等锁。”

比如：

- `realKey = "1001-2002"`
- 那么最终的 Redis key 就是：`"idempotent:1001-2002"`

🎯 就像你在图书馆借书，书上贴个标签：“此书已借出（幂等锁）”，别人就不要再借了。

------

**🔬 语法原理：**

- 字符串拼接，简单直接。
- **前缀设计是最佳实践**：避免不同业务模块的 key 冲突。
- 常见命名规范：`业务名:标识符`，如 `order:create:12345`、`user:login:abc`

------

**🧩 第6步：尝试加锁**

```java
Boolean isSet = redisTemplate.opsForValue()
        .setIfAbsent(lockKey, "1", idempotent.expire(), TimeUnit.SECONDS);
```

这行是整个幂等性的**灵魂所在**！我们拆开看。

------

**💬 大白话：**

> “去 Redis 问一句：
>  ‘有没有人已经占用了 `idempotent:1001-2002` 这个位置？’
>
> - 如果**没人占** → 我现在把它占住，值设为 `"1"`，并且 **10 秒后自动释放**（过期）。
> - 如果**已经有人占了** → 说明这是重复请求，别执行了！”

这就是典型的 **分布式锁** 实现方式之一（轻量级）。

> ⚠️ 注意：这里不是真正的“互斥锁”（不支持可重入、无 watch dog），但对“防重复提交”场景完全够用！

------

**🔬 语法原理：**

**`redisTemplate.opsForValue()`**

- Spring Data Redis 提供的操作 Redis 字符串（String 类型）的 API。
- 相当于 Redis 的 `SET`, `GET`, `INCR` 等命令封装。

**`.setIfAbsent(key, value, timeout, unit)`**

- 对应 Redis 命令：

  ```
  SET key value NX EX expireSeconds
  ```

  - `NX` = Not eXists（只有 key 不存在时才设置）
  - `EX` = Expire（设置过期时间，单位秒）

✅ 返回值：

- `true`：设置成功（第一次请求）
- `false`：key 已存在（重复请求）

**参数说明：**

| 参数                  | 含义                                                         |
| --------------------- | ------------------------------------------------------------ |
| `lockKey`             | 要设置的 key，如 `"idempotent:1001-2002"`                    |
| `"1"`                 | value 值，其实内容不重要，只要占位就行（也可以写用户ID、时间戳等） |
| `idempotent.expire()` | 过期时间，比如 `10`（来自注解配置）                          |
| `TimeUnit.SECONDS`    | 时间单位，这里是“秒”                                         |

> ✅ 自动过期非常重要！防止程序崩溃导致锁永远不释放（死锁）。

------

**🧩 第7步：判断是否加锁成功**

```java
if (Boolean.TRUE.equals(isSet)) {
    return joinPoint.proceed();
} else {
    throw new RuntimeException("请勿重复提交！");
}
```

------

**💬 大白话：**

> “看看刚才占位置成功没：
>
> - **成功了** → 放行！让原方法正常执行（比如保存评论）。
> - **失败了** → 直接报错：‘你点太快了，请勿重复提交！’ 不执行任何业务逻辑。”

这就实现了“同一个请求（相同 key）在短时间内只能成功一次”。

------

**🔬 语法原理：**

`Boolean.TRUE.equals(isSet)`

- 为什么不用 `isSet == true`？
  - 因为 `isSet` 是 `Boolean` 对象（可能为 `null`！）
  - 如果 Redis 操作异常，某些情况下可能返回 `null`
  - `Boolean.TRUE.equals(...)` 可以安全避免空指针异常（NPE）

✅ 推荐写法：永远用 `Boolean.TRUE.equals(obj)` 判断布尔对象。

**`joinPoint.proceed()`**

- AOP 中的关键方法：**继续执行被拦截的原始方法**
- 返回值就是原方法的返回结果
- 如果原方法抛异常，这里也会抛出来

**`throw new RuntimeException(...)`**

- 主动中断流程，不让重复请求进入业务层
- 异常会被 Spring 全局异常处理器捕获（如果你有写的话），返回友好提示

------

**🎯 完整流程回顾（生活化比喻）**

想象你在抢演唱会门票：

- **你点击“抢票”按钮** → 请求到达 `/buyTicket?userId=1001&showId=2002`**
- **系统检查**：Redis 里有没有 `idempotent:1001-2002`？
  - ❌ **没有** → 系统说：“好，给你占个座！”（`setIfAbsent` 成功）
    - 然后真正去扣库存、生成订单（`proceed()`）
    - 10 秒后座位自动释放
  - ✅ **已经有了** → 系统说：“你已经抢过了，别点了！”（抛异常）

------

#### 第三部分：@PostMapping("/comment")

```java
@PostMapping("/comment")
@Idempotent(key = "#userId + '-' + #productId", expire = 10)
public String addComment(
    @RequestParam Long userId,
    @RequestParam Long productId,
    @RequestBody String content) {
    // 业务逻辑
}
```

**🧩 第一行：`@PostMapping("/comment")**`

**💬 大白话：**

> “当用户用 POST 方式访问 `/comment` 这个网址时，请调用下面这个方法。”

比如用户在网页上点“提交评论”按钮，浏览器就会发一个 POST 请求到：

```
1POST http://yourserver.com/comment
```

**🔬 语法原理：**

- `@PostMapping` 是 Spring MVC 的注解，用于映射 **HTTP POST 请求** 到 Java 方法。
- 等价于 `@RequestMapping(method = RequestMethod.POST, path = "/comment")`
- 常用于**创建资源**（如提交表单、发表评论、下单等）

✅ 它告诉 Spring：“这个方法专门处理 POST /comment 请求”。

------

**🧩 第二行：`@Idempotent(key = "#userId + '-' + #productId", expire = 10)`**

**💬 大白话：**

> “这个接口要防重复提交！
>  判断是否重复的标准是：**同一个用户（userId）对同一个商品（productId）**。
>  如果 10 秒内重复提交，就直接拒绝！”

举个例子：

- 用户 A（userId=1001）给商品 B（productId=2002）写评论 → ✅ 成功
- 用户 A 再次给商品 B 写评论（10 秒内）→ ❌ “请勿重复提交！”
- 用户 A 给商品 C（productId=3003）写评论 → ✅ 成功（因为 productId 不同）
- 用户 B（userId=1002）给商品 B 写评论 → ✅ 成功（因为 userId 不同）

🎯 所以 `#userId + '-' + #productId` 就是“唯一指纹”。

------

**🔬 语法原理：**

`@Idempotent`

- 这是你**自定义的注解**（不是 Spring 自带的），用来标记“需要幂等控制”的方法。
- 它必须配合前面写的 `IdempotentAspect` 切面才能生效。

`key = "#userId + '-' + #productId"`

- 这是一个 **SpEL（Spring Expression Language）表达式**
- `#userId` 和 `#productId` 对应下面方法的**参数名**
- Spring AOP 会动态替换为实际值，拼成字符串

`expire = 10`

- 表示 Redis 锁的**过期时间是 10 秒**
- 单位通常是秒（由切面代码决定）

> ⚠️ 注意：表达式中的变量名 **必须和方法参数名完全一致**！

------

🧩 方法签名部分

```java
public String addComment(
    @RequestParam Long userId,
    @RequestParam Long productId,
    @RequestBody String content) {
```

我们逐个参数看。

------

✅ 参数1：`@RequestParam Long userId`

💬 大白话：

> “从 URL 的查询参数（query param）里拿 `userId` 的值。”

比如请求是：

```
1POST /comment?userId=1001&productId=2002
2Content-Type: application/json
3
4"服务很好！"
```

那么 `userId` 就会被赋值为 `1001`。

**🔬 语法原理：**

- `@RequestParam`：绑定 HTTP 请求的 **URL 参数**（即 `?userId=1001` 中的部分）
- 默认参数名就是变量名（`userId`），也可以显式指定：`@RequestParam("uid") Long userId`

------

**✅ 参数2：`@RequestParam Long productId`**

同理：

- 从 `?productId=2002` 中获取值
- 赋给 `productId` 变量

------

**✅ 参数3：`@RequestBody String content`**

**💬 大白话：**

> “把 HTTP 请求的**正文内容（body）** 当成字符串读进来。”

比如前端发送的 JSON 或纯文本：

```
"这次购物体验非常棒！"
```

或

```
{"text": "很棒"}   // 但这里你用的是 String，所以会收到整个 JSON 字符串
```

> 💡 注意：如果你希望自动解析 JSON 对象，应该用 `@RequestBody CommentDTO content`，而不是 `String`。

**🔬 语法原理：**

- `@RequestBody`：绑定 HTTP 请求的 **body 内容**
- Spring 会用 `HttpMessageConverter`（如 Jackson）把 body 转成 Java 对象
- 这里转成 `String`，所以直接拿到原始字符串

------

🎯 为什么 `content` 没出现在 SpEL 表达式里？

你在注解里写的是：

```
1@Idempotent(key = "#userId + '-' + #productId", ...)
```

没有用 `#content`，这是**故意设计**的！

**💬 大白话解释：**

> “我们只关心‘谁’对‘哪个商品’评论，不关心‘评论内容是什么’。
>  即使内容不同，只要是同一个用户对同一个商品，10 秒内也只能提交一次。”

✅ 这是合理的业务逻辑：防止手抖重复点“提交”，而不是防止内容不同。

如果你想“内容变了就算新评论”，那可以改成：

```
1@Idempotent(key = "#userId + '-' + #productId + '-' + #content", ...)
```

但通常没必要，而且 `content` 可能很长，导致 Redis key 太大。

------

**🔄 整体执行流程回顾**顾

1. 用户发送请求：

   ```
   POST /comment?userId=1001&productId=2002
   Body: "好评！"
   ```

2. Spring MVC 匹配到 `addComment` 方法

3. AOP 发现方法有 `@Idempotent`，触发 `IdempotentAspect`

4. 切面提取参数：

   - `userId = 1001`
   - `productId = 2002`
   - `content = "好评！"`（虽然没用到）

5. 计算 SpEL 表达式：

   - `"#userId + '-' + #productId"` → `"1001-2002"`

6. 构造 Redis key：`"idempotent:1001-2002"`

7. 尝试加锁：

   - 第一次：成功 → 执行 `addComment` 业务逻辑
   - 重复：失败 → 抛异常“请勿重复提交！”

------

**❗ 常见错误排查（小白注意）**

| 问题             | 原因                       | 解决方案                         |
| ---------------- | -------------------------- | -------------------------------- |
| `#userId` 找不到 | 编译时未保留参数名         | Maven/Gradle 加 `-parameters`    |
| 表达式报错       | 参数名拼写错误             | 确保 `#xxx` 和方法参数名完全一致 |
| Redis key 太长   | 用了 `#content` 且内容很长 | 避免在 key 中包含大字段          |
| 幂等失效         | `expire` 时间太短          | 根据业务调整，比如 30 秒         |

------

**✅ 最佳实践建议**

1. **key 设计要短而唯一**：只包含必要字段（用户ID、商品ID、订单号等）
2. **expire 时间合理**：比业务最大耗时略长（如 10~60 秒）
3. **不要依赖 content**：除非业务明确要求“内容不同就算新请求”
4. **返回友好提示**：用自定义异常 + 全局异常处理器返回 JSON

例如：

```
throw new IdempotentException("请勿重复提交");
```

然后全局捕获，返回：

```
{ "code": 400, "msg": "请勿重复提交" }
```

------

💡 总结一句话

> ```java
> @PostMapping("/comment")
> @Idempotent(key = "#userId + '-' + #productId", expire = 10)
> public String addComment(@RequestParam Long userId, @RequestParam Long productId, @RequestBody String content)
> ```
>
> 就像是在说：
>
> “凡是通过 POST 提交到 /comment 的请求，
>  只要是同一个用户（userId）对同一个商品（productId）的操作，
>  10 秒内只允许成功一次，其余全部拦截！