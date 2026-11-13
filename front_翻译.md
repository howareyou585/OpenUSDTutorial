# Usd 通用场景描述（核心）翻译 {#usd_page_front}

> 本文档采用对照式翻译：前一段是原英文，后一段是翻译的中文。
> 原文来源：`F:\newton\OpenUSD\pxr\usd\usd\docs\front.md`

---

# Usd : Universal Scene Description (Core) {#usd_page_front}
# Usd：通用场景描述（核心） {#usd_page_front}

\if ( PIXAR_MFB_BUILD )
\mainpage Usd : Universal Scene Description
\endif

---

<b>Usd</b> is the core client-facing module for authoring, composing, and reading Universal Scene Description. USD is designed to encode scalable, hierarchically organized, static and time-sampled data, for the primary purpose of interchanging and augmenting the data between cooperating Digital Content Creation applications.

<b>Usd</b> 是面向客户端的核心模块，用于创作（authoring）、合成（composing）和读取通用场景描述。USD 旨在编码可扩展的、分层组织的、静态和时间采样的数据，主要目的是在协作的数字内容创作（DCC）应用之间交换和增强数据。

---

## Core API Manual {#Usd_ManualDesc}
## 核心 API 手册 {#Usd_ManualDesc}

This manual contains the API documentation for the core Usd module, prefaced with an introduction to the key concepts behind the API, and including a guide to making effective use of the API. In this manual we do not deeply explore the composition semantics that underly Usd scenegraphs - that is the domain of the (forthcoming) <em>Universal Scene Description Composition Compendium</em>. We will discuss some aspects of the composition operators, primarily as they affect authoring workflows and/or scalability and/or import/export.

本手册包含核心 Usd 模块的 API 文档，前言部分介绍了 API 背后的关键概念，并包含一份有效使用该 API 的指南。在本手册中，我们不会深入探讨 Usd 场景图背后的合成语义——那是（即将出版的）<em>通用场景描述合成手册</em>的领域。我们将讨论合成运算符的一些方面，主要涉及那些影响创作工作流和/或可扩展性和/或导入/导出的内容。

---

<!-- This should totally be done with CSS instead of table and hokey spaces -->
<!-- 这完全应该用 CSS 而不是表格和蹩脚的空格来实现 -->

\n

<table border="0">
<tr>
     <td> <b>API Manual</b> </td>
     <td> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </td>
     <td> <b>Key Classes</b></td>
</tr>

<table border="0">
<tr>
     <td> <b>API 手册</b> </td>
     <td> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </td>
     <td> <b>关键类</b></td>
</tr>

<tr>
<td>
<ol>
<li> \subpage Usd_Page_ObjectModel </li>
     <ol type="i">
     <li> \ref Usd_OM_SdfLayer </li>
     <li> \ref Usd_OM_UsdStage </li>
     <li> \ref Usd_OM_UsdPrim </li>
     <li> \ref Usd_OM_UsdProperty </li>
     <li> \ref Usd_OM_UsdAttribute </li>
     <li> \ref Usd_OM_UsdRelationship </li>
     <li> \ref Usd_OM_Metadata </li>
     <li> \ref Usd_OM_OtherObjects </li>
     </ol>
<li> \subpage Usd_Page_Datatypes </li>
     <ol type="i">
     <li> \ref Usd_Datatypes </li>
     <li> \ref Usd_Basic_Datatypes </li>
     <li> \ref Usd_Roles </li>
     <li> \ref Usd_Array_Datatypes </li>
     <li> \ref Usd_Dictionary_Type </li>
     </ol>
<li> \subpage Usd_Page_UTF_8 </li>
     <ol type="i">
     <li> \ref Usd_UTF_8_Overview </li>
     <li> \ref Usd_UTF_8_Encoding </li>
     <li> \ref Usd_UTF_8_Language_Support </li>
     <li> \ref Usd_UTF_8_Identifiers </li>
     <li> \ref Usd_UTF_8_Operation_Reference </li>
     <li> \ref Usd_UTF_8_Encoding_Reference </li>
     </ol>
<li> \subpage Usd_Page_PropertiesOfSceneDescription </li>
     <ol type="i">
     <li> \ref Usd_Ordering </li>
     <li> \ref Usd_ValueResolution </li>
     <li> \ref Usd_PrimSpecifiers </li>
     <li> \ref Usd_ModelHierarchy </li>
     <li> \ref Usd_ActiveInactive </li>
     <li> \ref Usd_Filetypes </li>
     <li> \ref Usd_AssetResolution </li>
     </ol>
<li> \subpage Usd_Page_AdvancedFeatures </li>
     <ol type="i">
     <li> \ref Usd_Page_DynamicFileFormat </li>
     <li> \ref Usd_Page_ScenegraphInstancing </li>
     <li> \ref Usd_Page_ValueClips </li>
     </ol>
<li> \subpage Usd_Page_AuthoringEditing </li>
     <ol type="i">
     <li> \ref Usd_SelectiveEditing </li>
     <li> \ref Usd_Notification </li>
     </ol>
<li> \subpage Usd_Page_CommonIdioms </li>
     <ol type="i">
     <li> \ref Usd_StageTraversal </li>
     <li> \ref Usd_WorkingWithSchemas </li>
     <li> \ref Usd_BoolReturns </li>
     <li> \ref Usd_ErrorReporting </li>
     </ol>
<li> \subpage Usd_Page_BestPractices </li>
     <ol type="i">
     <li> \ref Usd_SharedConstRef </li>
     <li> \ref Usd_DataStreaming </li>
     <li> \ref Usd_Payloads </li>
     </ol>
<li> \subpage Usd_Page_MultiThreading </li>
     <ol type="i">
     <li> \ref Usd_ThreadSafetyModel </li>
     <li> \ref Usd_InternalMultiThreading </li>
     </ol>
<li> \subpage Usd_Page_GeneratingSchemas </li>
     <ol type="i">
     <li> \ref Usd_IsAVsAPISchemas </li>
     <li> \ref Usd_SchemaExtensionPhilosophy </li>
     </ol>
</ol>
</td>

<!-- 英文目录结构翻译说明：
1. Usd_Page_ObjectModel           —— 对象模型
2. Usd_Page_Datatypes             —— 数据类型
3. Usd_Page_UTF_8                 —— UTF-8 支持
4. Usd_Page_PropertiesOfSceneDescription —— 场景描述的属性
5. Usd_Page_AdvancedFeatures      —— 高级特性
6. Usd_Page_AuthoringEditing      —— 创作与编辑
7. Usd_Page_CommonIdioms          —— 常见用法模式
8. Usd_Page_BestPractices         —— 最佳实践
9. Usd_Page_MultiThreading        —— 多线程
10. Usd_Page_GeneratingSchemas    —— 生成 Schema

子项翻译：
- Usd_OM_SdfLayer                —— Sdf Layer（场景描述基础层）
- Usd_OM_UsdStage                —— UsdStage（舞台）
- Usd_OM_UsdPrim                 —— UsdPrim（图元）
- Usd_OM_UsdProperty             —— UsdProperty（属性）
- Usd_OM_UsdAttribute            —— UsdAttribute（特性值）
- Usd_OM_UsdRelationship         —— UsdRelationship（关系）
- Usd_OM_Metadata                —— Metadata（元数据）
- Usd_OM_OtherObjects            —— 其他对象
- Usd_Datatypes                  —— 数据类型
- Usd_Basic_Datatypes            —— 基本数据类型
- Usd_Roles                      —— 角色（语义类型）
- Usd_Array_Datatypes            —— 数组数据类型
- Usd_Dictionary_Type            —— 字典类型
- Usd_UTF_8_Overview             —— UTF-8 概述
- Usd_UTF_8_Encoding             —— UTF-8 编码
- Usd_UTF_8_Language_Support     —— UTF-8 语言支持
- Usd_UTF_8_Identifiers          —— UTF-8 标识符
- Usd_UTF_8_Operation_Reference  —— UTF-8 操作参考
- Usd_UTF_8_Encoding_Reference   —— UTF-8 编码参考
- Usd_Ordering                   —— 排序
- Usd_ValueResolution            —— 值解析（冲突解决）
- Usd_PrimSpecifiers             —— Prim 指定符（def/over/class）
- Usd_ModelHierarchy             —— 模型层级
- Usd_ActiveInactive             —— 激活/停用
- Usd_Filetypes                  —— 文件类型
- Usd_AssetResolution            —— 资产解析
- Usd_Page_DynamicFileFormat     —— 动态文件格式
- Usd_Page_ScenegraphInstancing  —— 场景图实例化
- Usd_Page_ValueClips            —— 值剪辑
- Usd_SelectiveEditing           —— 选择性编辑
- Usd_Notification               —— 通知
- Usd_StageTraversal             —— Stage 遍历
- Usd_WorkingWithSchemas         —— 使用 Schema
- Usd_BoolReturns                —— 布尔返回值
- Usd_ErrorReporting             —— 错误报告
- Usd_SharedConstRef             —— 共享常量引用
- Usd_DataStreaming              —— 数据流式传输
- Usd_Payloads                   —— Payload（延迟加载）
- Usd_ThreadSafetyModel          —— 线程安全模型
- Usd_InternalMultiThreading     —— 内部多线程
- Usd_IsAVsAPISchemas            —— "Is A" vs "API" Schema
- Usd_SchemaExtensionPhilosophy  —— Schema 扩展哲学
-->

<td> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; </td>

<td style="vertical-align: top;">
\n UsdStage owns the scenegraph and provides access to a composition.
\n UsdPrim is the hierarchically nestable unit of scene description.
\n UsdAttribute records time-varying data on prims.
\n UsdRelationship records links to other prims and properties.
\n UsdEditTarget allows editing of any layer/variation contained in a stage.
\n UsdNotice contains notifications that Usd issues when a stage's contents change.
\n UsdSchemaBase is the base class for generated schema classes.
\n UsdTimeCode is an ordinate that can be floating-point or an unvarying 'default'.
</td>

<td style="vertical-align: top;">
\n UsdStage 拥有场景图，并提供对合成结果的访问。
\n UsdPrim 是场景描述中可分层嵌套的基本单元。
\n UsdAttribute 记录 prim 上的时变数据。
\n UsdRelationship 记录到其他 prim 和属性的链接。
\n UsdEditTarget 允许编辑 stage 中包含的任何 layer/变体。
\n UsdNotice 包含 Usd 在 stage 内容变化时发出的通知。
\n UsdSchemaBase 是生成的 schema 类的基类。
\n UsdTimeCode 是一个坐标值，可以是浮点数，也可以是一个不变的"默认"值。
</td>

</tr>
</table>

---

## 翻译说明

### 术语对照表

| 英文术语 | 中文翻译 | 说明 |
|---|---|---|
| Usd | Usd | 保留不译，模块名 |
| Universal Scene Description | 通用场景描述 | USD 的全称 |
| authoring | 创作 | 指"编写/生成场景数据" |
| composing | 合成 | 指把多个 layer 叠加成最终场景 |
| time-sampled | 时间采样的 | 指随时间变化的数据（动画） |
| Digital Content Creation (DCC) | 数字内容创作 | 指 Maya/Blender/Houdini 等软件 |
| scenegraph | 场景图 | prim 的树形数据结构 |
| composition semantics | 合成语义 | 合成引擎如何解决冲突的规则 |
| composition operators | 合成运算符 | sublayer/reference/payload/inherit/specialize/variant |
| layer | 层 | 一个 .usda 文件 |
| stage | 舞台 | 合成后的运行时场景 |
| prim | 图元 | 场景的基本节点 |
| attribute | 特性/属性值 | prim 上有值的数据 |
| relationship | 关系 | prim 上指向其他 prim 的引用 |
| metadata | 元数据 | 关于 prim 的描述信息 |
| schema | 模式/Schema | 领域对象的标准化定义 |
| edit target | 编辑目标 | 指定编辑操作写入哪个 layer |
| notice | 通知 | 事件通知机制 |
| time code | 时间码 | 表示时间点的坐标 |
| value resolution | 值解析 | 合成时解决属性值冲突的过程 |
| prim specifier | prim 指定符 | def/over/class 三种声明方式 |
| model hierarchy | 模型层级 | 用 kind 标记的组织层级 |
| payload | 延迟加载/Payload | 延迟加载的引用 |
| instance / instancing | 实例 / 实例化 | 共享数据的对象复制 |
| value clips | 值剪辑 | 按时间片叠加数据的机制 |

### 关键类说明

| 类名 | 职责 |
|---|---|
| `UsdStage` | 拥有场景图，提供对合成结果的访问 |
| `UsdPrim` | 场景描述中可分层嵌套的基本单元 |
| `UsdAttribute` | 记录 prim 上的时变数据 |
| `UsdRelationship` | 记录到其他 prim 和属性的链接 |
| `UsdEditTarget` | 允许编辑 stage 中包含的任何 layer/变体 |
| `UsdNotice` | 包含 stage 内容变化时的通知 |
| `UsdSchemaBase` | 生成的 schema 类的基类 |
| `UsdTimeCode` | 时间坐标，可以是浮点数或不变的"默认"值 |

---

*原文：`F:\newton\OpenUSD\pxr\usd\usd\docs\front.md`（OpenUSD 26.08）*
