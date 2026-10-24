---
title: servlet基础知识
date: 2025-11-17 23:58:00+08:00
draft: false
categories:
- 编程开发
tags:
- Java
- Servlet
- Web开发
- 编程
permalink: agent-memory/个人随笔站点/site/content/posts/servlet-基础知识
---

# servlet基础知识

作为安全爱好者的基础性研究

Servlet：名字的由来

Servlet = “Server” + “Applet”
 早期 Java 里，Applet 是跑在浏览器里的小程序；Servlet 则是跑在 **服务器端** 的小程序，所以叫 “Server Applet”，简称 Servlet。

------

**它在解决什么问题？**

1. **动态内容**：HTML 只能写静态页面，而网页需要“千人千面”——登录状态、购物车、论坛帖子等都得实时变化。
2. **性能瓶颈**：传统 CGI 为每个请求开一个进程，开销大、响应慢。
3. **跨平台**：CGI 脚本依赖操作系统，移植困难。

ervlet 把“生成动态页面”这件事搬到 Java 世界：一次编写，到处运行；用线程代替进程，性能大幅提升。

------

**作用一句话**

接收浏览器发来的请求 → 在服务器端用 Java 代码处理 → 动态生成 HTML/JSON 等响应内容 → 再送回浏览器。

**底层逻辑与框架**

| 阶段              | 动作                                                         | 关键角色     |
| ----------------- | ------------------------------------------------------------ | ------------ |
| 1. 请求到达       | 浏览器发 HTTP 请求到 Web 服务器（如 Tomcat）                 | Web 服务器   |
| 2. 路由到 Servlet | 服务器根据 URL 把请求交给对应的 Servlet 类                   | Servlet 容器 |
| 3. 生命周期       | 容器负责：加载类 → 创建实例 → 调用 `init()` → 多次 `service()` → 最终 `destroy()` | Servlet 本身 |
| 4. 处理请求       | `service()` 方法根据 HTTP 方法（GET/POST）调用 `doGet()`/`doPost()`，开发者只写业务逻辑 | HttpServlet  |
| 5. 生成响应       | 通过 `HttpServletResponse` 写回 HTML、JSON 或文件            | Servlet      |
| 6. 线程复用       | 同一个 Servlet 实例被多个线程共享，避免频繁创建/销毁         | JVM 线程池   |

**核心优势**

- **高性能**：线程级并发，不是进程级。
- **可移植**：任何支持 Java 的服务器都能跑。
- **功能全**：Session、Cookie、过滤器、监听器一应俱全。
- **可扩展**：配合 JSP、Filter、Listener 构成完整的 Java Web 体系。

## Servlet 的完整生命周期和工作流程

用大白话 + 原理 + 代码演示，**把每一个阶段掰开揉碎**，分析每个阶段它到底做了点什么：

> **从浏览器点下回车开始，到服务器返回网页结束，中间到底发生了什么？**

🧭 **全局流程图（先看个全景）**

```
用户请求 → Tomcat 接收 → 找到对应 Servlet → 创建/复用实例 → 调用 doGet/doPost → 生成响应 → 返回网页
                      ↑         ↑              ↑
                  路由匹配   生命周期     业务逻辑执行
```

### 我们分 **5 个阶段** 来讲：

1. ✅ **阶段一：路由到 Servlet（URL 找类）**
2. ✅ **阶段二：Servlet 生命周期（创建、初始化、销毁）**
3. ✅ **阶段三：处理请求（doGet/doPost）**
4. ✅ **阶段四：生成响应（写回 HTML/JSON）**
5. ✅ **阶段五：线程并发（多个用户同时访问）**

每个阶段都配 **代码 + 逐行解释 + 大白话 + 原理说明**。

------

### 📌 **阶段一：路由到 Servlet（URL 找类）**

💬 大白话：

你访问 `http://localhost:8080/hello`，Tomcat 怎么知道该让哪个 Java 类来处理？
 靠的是 **映射规则**，就像“门牌号”一样，告诉服务器：“/hello 这个地址归 HelloServlet 管”。

🔧 **两种方式设置路由**：

**方式一：用注解（推荐）**

```java
@WebServlet("/hello")
public class HelloServlet extends HttpServlet { ... }
```

**方式二：写 web.xml**

```xml
<servlet>
    <servlet-name>Hello</servlet-name>
    <servlet-class>com.example.HelloServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>Hello</servlet-name>
    <url-pattern>/hello</url-pattern>
</servlet-mapping>
```

👉 无论哪种方式，最终结果都是：**URL → Servlet 类 的映射表**

------

### 📌 阶段二：Servlet 生命周期（创建 → 初始化 → 使用 → 销毁）

Servlet 不是“用一次就扔”，而是“一次创建，长期服役”。

🔄 生命周期三阶段：

| 阶段   | 方法                               | 何时触发             | 调用几次 |
| ------ | ---------------------------------- | -------------------- | -------- |
| 初始化 | `init()`                           | 第一次请求到达时     | 1次      |
| 服务   | `service()` → `doGet()`/`doPost()` | 每次请求             | 多次     |
| 销毁   | `destroy()`                        | 服务器关闭或卸载应用 | 1次      |

> 💡 注意：**一个 Servlet 类只创建一个实例**，但会被多个线程同时调用！

------

#### 📄 代码演示：带生命周期日志的 HelloServlet

```java
package com.example;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

// 1. 告诉 Tomcat：这个类处理 /hello 路径的请求
@WebServlet("/hello")
public class HelloServlet extends HttpServlet {

    private int requestCount = 0; // 记录被访问了多少次

    // 2. 初始化阶段：Tomcat 创建这个类的实例后，自动调用 init()
    @Override
    public void init() throws ServletException {
        System.out.println("🔧 HelloServlet 正在初始化！这是第一次启动！");
        super.init();
    }

    // 3. 服务阶段：每次有请求来，都会调用 service()，它会自动分发到 doGet 或 doPost
    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        System.out.println("⚡ 请求进来了！准备处理...");
        super.service(req, resp); // 调用父类逻辑，根据请求方法决定走 doGet 还是 doPost
    }

    // 4. 处理 GET 请求
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // 每处理一次，计数器 +1
        requestCount++;

        System.out.printf("🟢 正在处理第 %d 次 GET 请求，来自: %s%n",
                requestCount, req.getRemoteAddr());

        // 设置响应内容类型为 HTML
        resp.setContentType("text/html;charset=UTF-8");

        // 获取输出流，用来写回网页内容
        PrintWriter out = resp.getWriter();

        // 写出 HTML 页面
        out.println("<h1>你好，世界！</h1>");
        out.println("<p>你是第 <strong>" + requestCount + "</strong> 个访问者</p>");
        out.println("<p>你的 IP 是：" + req.getRemoteAddr() + "</p>");
    }

    // 5. 当服务器关闭时，自动调用 destroy()
    @Override
    public void destroy() {
        System.out.println("🛑 HelloServlet 正在销毁！再见！");
        super.destroy();
    }
}
```

**🔍 逐行解释（重点！）**

|                  行                  |                             代码                             |
| :----------------------------------: | :----------------------------------------------------------: |
|       `@WebServlet("/hello")`        |        给这个类贴个“门牌号”：谁访问 `/hello`，就找它         |
|        `extends HttpServlet`         | 继承父类，获得处理 HTTP 请求的能力（比如自动区分 GET/POST）  |
|               `init()`               | 第一次请求来之前，Tomcat 会调用一次，适合做“准备工作”（比如连接数据库） |
|             `service()`              | 每次请求都先进这里，然后它自动判断是 GET 还是 POST，再转发给 `doGet` 或 `doPost` |
|         `super.service(...)`         |                 调用父类的标准流程，不要删！                 |
|              `doGet()`               |          专门处理 GET 请求（比如浏览器地址栏访问）           |
|           `requestCount++`           |  记录总共被访问了多少次（注意：这是成员变量！多个线程共享）  |
|      `resp.setContentType(...)`      |        告诉浏览器：“我要返回的是 HTML，用 UTF-8 编码”        |
| `PrintWriter out = resp.getWriter()` |                 拿到“笔”，可以往响应里写内容                 |
|          `out.println(...)`          |                   把 HTML 内容一行行写回去                   |
|             `destroy()`              |   服务器关闭前调用，适合做“收尾工作”（比如关闭数据库连接）   |

### 📌 阶段三：处理请求（doGet/doPost）

**💬 大白话：**

你可以把 `doGet` 想象成一个“服务员”，他每天上班（服务期），只要客人点单（发请求），他就按菜单（代码）上菜（返回网页）。

🔧 **HttpServletRequest 是什么？**

它是“请求包裹”，里面装着：

- 用户的 IP（`getRemoteAddr()`）
- 请求参数（`getParameter("name")`）
- 请求头（User-Agent、Cookie 等）
- Session 信息

**🔧 HttpServletResponse 是什么？**

它是“响应包裹”，你要把生成的内容（HTML、JSON）塞进去，然后“打包发回去”。

------

### 📌 阶段四：生成响应（写回 HTML）

**💬 大白话：**

你不是在写网页，而是在“拼字符串”。
 Java 代码像厨师一样，把 HTML 片段一个个拼起来，最后做成一道“动态菜”。

**🔧 关键点：**

- `resp.getWriter()`：拿到输出流；
- `out.println()`：把内容写出去；
- 内容可以是 HTML、JSON、XML、文件下载等。

------

### 📌 阶段五：线程并发（多个用户同时访问）

**💬 大白话：**

想象你开了家面馆，只有一个厨师（HelloServlet 实例），但来了 10 个客人（10 个请求）。
 怎么办？
 你让 10 个服务员（线程）轮流找厨师下单，厨师做好一碗就递给对应服务员。

👉 **一个 Servlet 实例，被多个线程并发调用。**

**⚠️ 危险点：**

```java
private int requestCount = 0; // 共享变量！
```

如果多个线程同时修改它，可能出现“计数不准”（线程安全问题）。
 但在本例中，我们只是演示，不深究锁机制。

------

### 🧪 实验：亲自验证生命周期

**步骤 1：启动应用**

运行 Spring Boot 或传统 Web 项目，启动 Tomcat。

**步骤 2：第一次访问**

浏览器打开：

```java
http://localhost:8080/hello
```

控制台输出：

```
🔧 HelloServlet 正在初始化！这是第一次启动！
⚡ 请求进来了！准备处理...
🟢 正在处理第 1 次 GET 请求，来自: 127.0.0.1
```

👉 `init()` 只执行了一次！

**步骤 3：刷新几次**

再刷新 2 次页面。

控制台输出：

```
⚡ 请求进来了！准备处理...
🟢 正在处理第 2 次 GET 请求，来自: 127.0.0.1

⚡ 请求进来了！准备处理...
🟢 正在处理第 3 次 GET 请求，来自: 127.0.0.1
```

**步骤 4：关闭服务器**

```
🛑 HelloServlet 正在销毁！再见！
```

👉 `destroy()` 在最后执行！

------

### 🎯 总结：Servlet 工作全流程

| 阶段      | 发生了什么                       | 类比                 |
| --------- | -------------------------------- | -------------------- |
| 1. 路由   | URL → Servlet 类                 | 门牌号找房东         |
| 2. 初始化 | `new HelloServlet()` → `init()`  | 房东搬进来，打扫房子 |
| 3. 服务   | 每次请求 → `service()` → `doGet` | 房东接待租客         |
| 4. 响应   | `resp.getWriter().println(...)`  | 给租客递钥匙         |
| 5. 并发   | 多个线程共享一个实例             | 一个房东服务多个租客 |
| 6. 销毁   | 服务器关闭 → `destroy()`         | 房东搬走，打扫卫生   |

------

#### ✅ 一句话总结

> **Servlet 就是一个长期住在服务器里的“Java 小程序”，它有一个固定的“上岗-工作-下班”流程，能接收请求、动态生成网页、并发服务多人，是 Java Web 的基石。**

------

### 🚀 下一步建议

你现在可以：

1. 把上面的 `HelloServlet` 跑起来，亲眼看看日志；
2. 改成 `doPost`，用 Postman 发 POST 请求；
3. 加一个参数：`?name=小明`，让网页显示“你好，小明！”；
4. 研究 `Filter`（过滤器）——在 Servlet 前后加“安检门”。

## 容器这个东东？

**大白话通俗解释：**
 容器就是“装对象的大盒子”，它在程序启动时就把所有需要的对象一次性“造好”，然后一直管着它们——什么时候用、用多少、用完怎么销毁，都由盒子说了算。你写的类只是“图纸”，容器负责按图纸造东西、把东西放进盒子，并在盒子的生命周期里随时给你调用。

**原理层面：**

1. 启动阶段：容器读配置（XML、注解或 Java 代码），把每个要管理的类变成对象（实例化），并把它们之间的依赖关系也一次性配好。
2. 运行阶段：程序里用到的对象都直接从盒子里拿，容器保证每次拿到的都是“已经装好、随时能用”的完整对象。
3. 销毁阶段：程序关闭，容器把盒子里所有对象一次性清理掉，避免内存泄漏。

**和注解的关系：**
 注解只是“贴标签”，告诉容器“这个类要放进盒子”“这两个对象之间有依赖”。真正干活的还是容器本身——它看到标签后，按标签指示去实例化、装配、管理生命周期。没有容器，注解就只是个标签，什么都不会发生。

**一句话总结：**
 容器 = 自动化“对象管家”，负责“造对象、管对象、销毁对象”，你只需要用注解或配置告诉它“管哪些、怎么管”。

### 我的疑问：容器是如何装东西

Servlet 启动时，容器（Tomcat/Jetty 等）会按下面两步决定“把哪些对象装进容器”：

1. 读配置
    容器先解析 web.xml 或扫描类路径下的注解（@WebServlet、@WebFilter 等）。
2. 这些配置里明确写了“哪个类要被装进容器”，例如：

```xml
<servlet>
    <servlet-name>Hello</servlet-name>
    <servlet-class>com.example.HelloServlet</servlet-class>
</servlet>
```

或

```java
@WebServlet("/hello")
public class HelloServlet extends HttpServlet { ... }
```

只要出现这样的声明，容器就知道“这个类需要被实例化并放进自己的管理池”。

被装进去的对象既可以是官方自带的（比如 HttpServlet、Filter 接口的实现），也可以是你自己写的类。

- 官方提供基础能力（如 HttpServlet、Filter），但具体业务逻辑要你自己写。
- 你写好类后，只要在配置里声明，容器就会把它当成普通对象一样加载、实例化、初始化，然后放进容器里统一管理。

一句话：

“装什么”完全由你在配置里写什么决定；官方只负责提供“能被装”的基础接口和工具，真正的业务对象都是你自定义的。

### 代码片段演示具体过程

**🔍 代码：`@WebServlet("/hello")`**

```java
@WebServlet("/hello")
public class HelloServlet extends HttpServlet { ... }
```

我们分三部分来看：

------

#### ✅ 第一部分：`@WebServlet("/hello")` —— 贴标签的人

**💬 大白话：**

这就像是在你家门上贴了一张“快递员专用贴纸”，写着：

> “快递员（Tomcat）：如果有人寄东西到 `/hello` 这个地址，请送到这家！”

这个注解就是告诉 **Servlet 容器**：“我这个类是一个 Servlet，能处理 `/hello` 这个路径的请求。”

**🧠 原理：**

- `@WebServlet` 是 Java EE 的标准注解（来自 `javax.servlet.annotation.WebServlet`）。
- 当 Tomcat 启动时，它会**扫描整个项目的类路径**（classpath），找所有带有 `@WebServlet` 注解的类。
- 一旦发现，就记录下来：“`HelloServlet` 类负责处理 `/hello` 请求”。

👉 所以说，**不是所有类都会被装进容器，只有你打了标签的才会被发现和加载。**

------

#### ✅ 第二部分：`public class HelloServlet` —— 你要造的房子

**💬 大白话：**

这是你自己设计的一栋小房子（Java 类），你起名叫 `HelloServlet`。

它本来只是图纸（`.java` 文件），没人知道它能干啥。

但因为你贴了 `@WebServlet` 标签，快递公司（Tomcat）就知道：“哦，这栋房子是收快递的驿站，得把它建起来，安排人值班。”

**🧠 原理：**

- Tomcat 发现这个类后，会通过反射（`Class.forName()`）加载它；
- 然后调用 `new HelloServlet()` 创建一个实例；
- 把这个实例放进自己的“Servlet 池”里，准备后续复用。

👉 所以：**类是你写的，对象是容器帮你 new 出来的。**

------

#### ✅ 第三部分：`extends HttpServlet` —— 房子必须符合国家标准

**💬 大白话：**

你想开个驿站，国家规定必须满足几个条件：

- 有收件窗口
- 有发件流程
- 有安全制度

`HttpServlet` 就是“国家认证的驿站模板”。你继承它，就等于承诺：“我家符合标准，能合法接单。”

**🧠 原理：**

- `HttpServlet` 是 JDK 提供的一个抽象类，实现了基本的 HTTP 协议处理逻辑；
- 它内部已经写好了：
  - 如何区分 GET / POST 请求
  - 如何调用 `doGet()` 或 `doPost()`
  - 如何设置响应头等基础功能
- 你只需要重写 `doGet()` 或 `doPost()`，写自己的业务逻辑就行。

比如：

```java
@Override
protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
    resp.getWriter().println("你好，世界！");
}
```

👉 相当于你在“收件窗口”贴了个告示：“来取件的人，每人送一瓶水。”

------

### 🚀 完整流程：从启动到访问，容器是怎么操作的？

| 阶段        | 容器做了什么                                           |
| ----------- | ------------------------------------------------------ |
| 1. 启动     | Tomcat 启动，开始扫描所有 `.class` 文件                |
| 2. 扫描     | 发现 `HelloServlet.class` 上有 `@WebServlet("/hello")` |
| 3. 注册     | 把这个类登记到“路由表”：`/hello → HelloServlet.class`  |
| 4. 实例化   | 调用 `new HelloServlet()` 创建一个实例                 |
| 5. 初始化   | 调用它的 `init()` 方法（只一次）                       |
| 6. 等待请求 | 开始监听 8080 端口                                     |
| 7. 收到请求 | 用户访问 `/hello`，容器查路由表，找到 `HelloServlet`   |
| 8. 分发处理 | 调用该实例的 `service()` → 自动转到 `doGet()`          |
| 9. 返回响应 | 你的代码生成 HTML，返回给浏览器                        |

### ✅ 这些对象是官方的还是自定义的？

| 对象类型       | 来源                             | 举例                                               |
| -------------- | -------------------------------- | -------------------------------------------------- |
| **框架提供的** | 官方（Java EE / Tomcat）         | `HttpServlet`, `HttpServletRequest`, `Filter` 接口 |
| **你自己写的** | 自定义                           | `HelloServlet`, `LoginFilter`, `UserDao`           |
| **容器管理的** | 只要是你打了标签的类，容器都会管 | 所有 `@WebServlet`, `@WebFilter`, `@WebListener`   |

👉 所以答案是：

> **类是你自己写的，但容器根据你打的标签（如 @WebServlet）决定是否把它装进去，并负责它的生命周期。**

------

### 🎯 举个生活化的比喻

想象你在小区里想开一家“代收快递”的小店：

1. **你写了个店** → `public class HelloServlet`
2. **你申请了资质** → `@WebServlet("/hello")`
3. **你用了标准柜台** → `extends HttpServlet`
4. **物业（Tomcat）审核通过** → 扫描到注解，允许入驻
5. **物业给你分配铺位** → 实例化并放入 Servlet 池
6. **居民寄快递写地址 `/hello`** → 浏览器访问 `/hello`
7. **物业把快递转交给你** → 容器调用你的 `doGet()`

如果没有贴资质标签？—— 物业不知道你是个合法驿站，直接忽略你。

------

### ✅ 总结一句话

> `@WebServlet` 是你给类贴的“上岗证”，容器是“人事主管”，它只招聘持证上岗的 Servlet；你写的类是自定义的，但它必须继承 `HttpServlet` 这个“标准模板”，才能被容器识别、创建、管理和调用。

------

## 对象是怎么在网络上传输的

一句话先给结论：
 **TCP 连接建立后，浏览器（客户端）把“纯文本请求”发过去；服务器收到后，由 Servlet 容器先把这段文本解析成 `HttpServletRequest` 对象，再调用你的 Servlet；响应时，你的 Servlet 代码往 `HttpServletResponse` 对象里写数据，容器再把它转成纯文本发回浏览器。**

下面拆成三步，用大白话讲清楚：

------

### 1. 浏览器怎么“发”

浏览器只懂 HTTP 协议，它把请求拼成一段符合 HTTP 格式的纯文本（请求行 + 头 + 空行 + 数据），然后通过 TCP 把这段文本发出去。

 → 它不会“发对象”，发的是**纯文本**。

------

### 2. 服务器怎么“收并转成对象”

Tomcat 这类 Servlet 容器监听在 8080（或 80）端口，收到 TCP 流后：

- 先读取整段文本；
- 按 HTTP 协议规范把文本拆成“请求行、头、正文”等部分；
- 用这些部分填充 `HttpServletRequest` 对象的各个字段（getMethod()、getHeader()、getParameter() 等）；
- 同时准备一个空的 `HttpServletResponse` 对象，交给你的 Servlet 代码往里写响应内容。

→ **“把文本变成对象”这一步，是容器在接收到请求后、调用你代码之前完成的。**

------

### 3. 响应怎么“从对象回到文本”

1. 你的 Servlet 代码往 `HttpServletResponse` 对象里写内容（setHeader、getWriter.println 等）；
2.  容器把对象里的状态和正文再拼成符合 HTTP 协议的纯文本，通过 TCP 发回浏览器；
3.  浏览器收到后，按协议解析这段文本，渲染页面。

→ **“把对象变回文本”这一步，是容器在你的 Servlet 执行完之后、把响应写回网络之前完成的。**

------

一句话再总结：
 **浏览器只和“文本”打交道；容器负责“文本 ↔ 对象”的双向翻译；你写的 Servlet 只需要操作对象，不用管底层 TCP 和 HTTP 文本格式。**

### 响应对象怎么把它写回文本的，然后发回客户端的

简单一句话：
 Servlet 容器把 `HttpServletResponse` 对象里的“状态、头、正文”按 HTTP 协议拼成一段纯文本，再通过 TCP 发回浏览器。

具体过程分三步：

1. 你往对象里写内容
    在 `doGet`/`doPost` 里，你调用

   - `resp.setStatus(200)`
   - `resp.setHeader("Content-Type", "text/html")`
   - `resp.getWriter().println("<h1>OK</h1>")`
     这些数据都先存在 `HttpServletResponse` 对象里，还没发出去。

2. 容器把对象“翻译”成 HTTP 响应文本
    容器在你的方法执行完后，会把对象里的内容按顺序拼成一段符合 HTTP 协议的纯文本：

   ```
   HTTP/1.1 200 OK
   Content-Type: text/html
   Content-Length: 14
   
   <h1>OK</h1>
   ```

1. 这一步就是“把对象写回文本”。
2. 通过 TCP 把文本发回浏览器
    容器拿到这段文本后，调用底层 `Socket` 的输出流，把字节写进 TCP 缓冲区，操作系统再通过网络把字节流送回浏览器。

浏览器收到后，再按 HTTP 协议把这段文本拆开，渲染页面。

### requestInitialized(ServletRequestEvent e) ，描述下里面的逻辑

`requestInitialized(ServletRequestEvent e)` 的执行逻辑可以概括为一条链式流程：

1. **容器感知请求到达**
    当 HTTP 请求进入 Tomcat 时，容器立即为该请求分配一个线程，并决定调用哪些监听器。
2. **创建事件对象**
    容器用当前 `ServletRequest` 实例和 `ServletContext` 构造出一个新的 `ServletRequestEvent` 对象，把请求与上下文绑定到该事件。
3. **触发监听器**
    容器遍历所有已注册的 `ServletRequestListener`，依次调用它们的 `requestInitialized` 方法，并把刚创建的 `ServletRequestEvent` 对象作为实参传入。
4. **执行监听逻辑**
    监听器方法体内的代码开始执行：
   - 通过 `e.getServletRequest()` 拿到原始请求对象；
   - 可以读取请求的 IP、URL、参数等信息；
   - 可以记录日志、统计访问量、设置请求属性等。
5. **继续请求处理**
    监听器执行完毕后，容器继续把请求交给 Filter 链或目标 Servlet，整个请求流程正常进行。

一句话总结：
 容器把“刚到达的请求”包装成一个事件对象，然后挨个通知所有监听器“请求开始了”，监听器拿到事件后即可对请求进行预处理或记录，之后请求继续向下流转。