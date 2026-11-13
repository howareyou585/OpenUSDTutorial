# 对象模型及各类如何协同工作 {#Usd_Page_ObjectModel}

> 本文档采用对照式翻译：前一段是原英文，后一段是翻译的中文。
> 原文来源：`F:\newton\OpenUSD\pxr\usd\usd\docs\objectModel.md`（OpenUSD 26.08）

---

# Object Model and How the Classes Work Together {#Usd_Page_ObjectModel}
# 对象模型及各类如何协同工作 {#Usd_Page_ObjectModel}

---

## SdfLayer: Shared Data Files {#Usd_OM_SdfLayer}
## SdfLayer：共享数据文件 {#Usd_OM_SdfLayer}

An SdfLayer provides the interface to a persistent (in a file) or in-memory only (via "anonymous" layers) container of scene description. The scene description contained in a layer consists of prims, attributes, relationships, user-metadata on all of the above, and composition operators that specify how the contained scene description should be composed with scene description in other files.

SdfLayer 提供了对场景描述容器的接口，该容器可以是持久化的（在文件中）或仅存在于内存中的（通过"匿名"层）。一个 layer 中包含的场景描述由 prim、属性、关系、上述所有元素上的用户元数据，以及指定如何将所含场景描述与其他文件中的场景描述进行合成的合成运算符组成。

If working directly with an SdfLayer, clients should be aware that Sdf maintains an internal registry of layers that clients have requested to be opened via SdfLayer::FindOrOpen(), SdfLayer::CreateNew() or SdfLayer::CreateAnonymous(). The registry holds only weak pointers (SdfLayerHandle) to the layers it caches, so it is the client's responsibility to retain the strong SdfLayerRefPtr that the above methods return, if they expect the layer to persist. UsdStage takes care of this for the layer for which the stage was opened, and all layers reached during the process of population the stage by traversing composition arcs; the set of "reached" layers may be different for different variant selections on the stage, different activation opinions, and different load-states.

如果直接使用 SdfLayer，客户端应该知道 Sdf 维护着一个内部 layer 注册表，记录客户端通过 SdfLayer::FindOrOpen()、SdfLayer::CreateNew() 或 SdfLayer::CreateAnonymous() 请求打开的 layer。该注册表只持有它缓存的 layer 的弱指针（SdfLayerHandle），因此如果客户端希望 layer 持续存在，客户端有责任保留上述方法返回的强引用 SdfLayerRefPtr。UsdStage 会为打开 stage 所用的那个 layer，以及在遍历合成弧线填充 stage 过程中到达的所有 layer 负责此事；"到达"的 layer 集合可能因 stage 上的不同变体选择、不同的激活意见和不同的加载状态而异。

\note <b>USDeeper: Layer-related plugins</b> Sdf also defines the SdfFileFormat plugin mechanism that provides a file-extension-based extensible registry of plugins that can either generate a layer's worth of scene description procedurally, or translate a different file format into USD's data model and relevant schemas "on the fly". Sdf also uses the Ar Asset Resolution plugin API to resolve layer identifiers to external (e.g. file) assets. The Ar plugin API lets USD clients provide customized behavior for resolving "asset identifiers" and querying asset metadata.

\note <b>深入了解：Layer 相关插件</b> Sdf 还定义了 SdfFileFormat 插件机制，提供一个基于文件扩展名的可扩展插件注册表，这些插件可以程序化地生成一个 layer 所需的场景描述，或"即时"将其他文件格式转换为 USD 的数据模型和相关 schema。Sdf 还使用 Ar 资产解析插件 API 将 layer 标识符解析为外部（如文件）资产。Ar 插件 API 允许 USD 客户端提供自定义行为来解析"资产标识符"和查询资产元数据。

---

## UsdStage: Composed View of an SdfLayer {#Usd_OM_UsdStage}
## UsdStage：SdfLayer 的合成视图 {#Usd_OM_UsdStage}

As described in its class documentation, a UsdStage is the interface to a specific SdfLayer (known as its \em rootLayer), interpreting the data it contains through the composition rules provided by Pcp. Pcp informs the UsdStage about which UsdPrim s should be populated on the stage, and provides PcpPrimIndex objects, per-prim, which allow usd to perform efficient value resolution.

如其类文档所述，UsdStage 是对一个特定 SdfLayer（称为其 \em rootLayer，即根层）的接口，通过 Pcp 提供的合成规则来解释其中包含的数据。Pcp 告知 UsdStage 应该在 stage 上填充哪些 UsdPrim，并按 prim 提供 PcpPrimIndex 对象，使 USD 能够执行高效的值解析。

The primary client-facing aspect and purpose of a UsdStage is that it creates and maintains (as new scene description is authored or mutated) a scenegraph of UsdPrim s that enables efficient scene traversal, data extraction and authoring. A UsdStage can contain any number of "root level" prims, each of which represents a different tree/graph (which may be related to each other via composition operators or relationships). To facilitate traversals that visit all root prims, every UsdStage has an un-named "pseudo-root" prim that is the parent of all root prims; it can be accessed via UsdStage::GetPseudoRoot().

UsdStage 面向客户端的主要方面和目的是：它创建并维护（随着新场景描述被创作或修改）一个由 UsdPrim 组成的场景图，以实现高效的场景遍历、数据提取和创作。一个 UsdStage 可以包含任意数量的"根级别"prim，每个 prim 代表一棵不同的树/图（它们可能通过合成运算符或关系相互关联）。为了方便遍历所有根 prim，每个 UsdStage 都有一个未命名的"伪根"prim，它是所有根 prim 的父节点；可以通过 UsdStage::GetPseudoRoot() 访问它。

An important property of the stage is that it always presents the accurate, fully-composed view of the data in its underlying SdfLayer s. This has impact on authoring/editing, and implies that a UsdStage may perform a potentially substantial amount of work in "recomposing" a scene in response to certain kinds of authoring operations, namely the authoring of composition operators. For example, when one adds a reference to a prim using UsdReferences, the stage on which the prim sits will immediately pull in the scene topology information from the referenced SdfLayer, and repopulate the affected parts of the stage. Something similar occurs even when one changes a variant selection on an existing UsdVariantSet.

stage 的一个重要特性是：它总是呈现其底层 SdfLayer 中数据的准确、完全合成的视图。这对创作/编辑有影响，意味着 UsdStage 在响应某些类型的创作操作（即创作合成运算符）时，可能会执行大量"重新合成"场景的工作。例如，当使用 UsdReferences 给一个 prim 添加引用时，该 prim 所在的 stage 会立即从被引用的 SdfLayer 中拉取场景拓扑信息，并重新填充 stage 的受影响部分。即使在已有的 UsdVariantSet 上更改变体选择时，也会发生类似的事情。

\note <b>USDeeper: Editing Layers Updates Stage.</b> UsdStage recomposes in response to mutations of SdfLayer 's that are composed into the stage. Thus, a UsdStage will remain accurate even if one uses the lower-level Sdf API's to mutate layers, rather than the USD object API's.

\note <b>深入了解：编辑 Layer 会更新 Stage。</b> UsdStage 会响应被合成到 stage 中的 SdfLayer 的变更而重新合成。因此，即使使用较低层级的 Sdf API 来修改 layer，而不是使用 USD 对象 API，UsdStage 也会保持准确。

---

### UsdStage Lifetime and Management {#Usd_OM_UsdStage_Management}
### UsdStage 的生命周期和管理 {#Usd_OM_UsdStage_Management}

SdfLayer and UsdStage are the only objects in USD whose lifetime matters. SdfLayer is the true data container in USD, and if a layer is destroyed before its contents are explicitly serialized (SdfLayer::Save(), SdfLayer::Export()), then data may be lost. If a UsdStage is destroyed, it will drop its retention of all of the SdfLayer s it composes; if that results in a layer-with-changes' refcount to drop to zero, the layer will be destroyed.

SdfLayer 和 UsdStage 是 USD 中仅有的生命周期至关重要的对象。SdfLayer 是 USD 中真正的数据容器，如果一个 layer 在其内容被显式序列化（SdfLayer::Save()、SdfLayer::Export()）之前被销毁，数据可能会丢失。如果一个 UsdStage 被销毁，它会放弃对它所合成的所有 SdfLayer 的持有；如果这导致一个含变更的 layer 的引用计数降为零，该 layer 就会被销毁。

Like SdfLayer, UsdStage is also managed by strong and weak pointers; all stage-creation methods return a UsdStageRefPtr for the client to retain. UsdStages \em can also be managed in a registry, known as a UsdStageCache. Unlike the SdfLayer registry, however:

与 SdfLayer 类似，UsdStage 也通过强指针和弱指针管理；所有 stage 创建方法都返回 UsdStageRefPtr 供客户端保留。UsdStage \em 也可以在一个注册表中管理，称为 UsdStageCache。但与 SdfLayer 注册表不同的是：

\li There isn't a core, global singleton registry - clients can make as many UsdStageCache registries as they need. UsdUtils does provide a singleton that clients can opt to use, if a single, known registry is appropriate. This is useful in scenarios where multiple, collaborating subsystems in a process each need to access data directly from USD, but have estabished API that cannot be perturbed to pass a UsdStagePtr back and forth.

\li 没有核心的全局单例注册表——客户端可以按需创建任意多个 UsdStageCache 注册表。UsdUtils 确实提供了一个单例，如果单个已知注册表是合适的，客户端可以选择使用它。这在以下场景中很有用：一个进程中的多个协作子系统各自需要直接从 USD 访问数据，但已建立的 API 无法改为来回传递 UsdStagePtr。

\li UsdStageCache \em does retain a strong reference to each of the stages it collects, and the cache can be explicitly cleared.

\li UsdStageCache \em 确实对它收集的每个 stage 保留强引用，并且缓存可以被显式清除。

---

## UsdPrim: Nestable Namespace Containers {#Usd_OM_UsdPrim}
## UsdPrim：可嵌套的命名空间容器 {#Usd_OM_UsdPrim}

UsdPrim is the primary object used to interact with composed scene description, and has the largest API of any of the core objects. A UsdPrim represents a \b unique "namespace location" in a hierarchical composition on a UsdStage. Each UsdPrim can contain properties and child UsdPrim's, which is what allows us to build hierarchies. If the following usd example were opened on a UsdStage:

UsdPrim 是用于与合成后的场景描述交互的主要对象，在所有核心对象中拥有最大的 API。一个 UsdPrim 代表 UsdStage 上分层合成中的一个 \b 唯一"命名空间位置"。每个 UsdPrim 可以包含属性和子 UsdPrim，这正是我们能够构建层级结构的基础。如果在 UsdStage 上打开以下 USD 示例：

\code{.unparsed}
#usda 1.0

def "World"
{
    def "Sets"
    {
    }

    over "Fx"
    {
    }
}
\endcode

\code{.unparsed}
#usda 1.0

def "World"
{
    def "Sets"
    {
    }

    over "Fx"
    {
    }
}
\endcode

then we would be able to access the UsdPrim's on the stage, like so:

那么我们就能像这样访问 stage 上的 UsdPrim：

\code
// SdfPath identifiers can be constructed most efficiently by using SdfPath
// API to build up the path incrementally; however, they can always also 
// be constructed from a full string representation; we demonstrate both forms.
SdfPath worldPath = SdfPath("/World");
UsdPrim world = stage->GetPrimAtPath(worldPath);
UsdPrim sets  = stage->GetPrimAtPath(worldPath.AppendChild(TfToken("Sets")));
UsdPrim fx    = stage->GetPrimAtPath(worldPath.AppendChild(TfToken("Fx")));
\endcode

\code
// SdfPath 标识符可以通过使用 SdfPath API 逐步构建路径来最高效地构造；
// 但也始终可以从完整的字符串表示构造；我们演示两种形式。
SdfPath worldPath = SdfPath("/World");
UsdPrim world = stage->GetPrimAtPath(worldPath);
UsdPrim sets  = stage->GetPrimAtPath(worldPath.AppendChild(TfToken("Sets")));
UsdPrim fx    = stage->GetPrimAtPath(worldPath.AppendChild(TfToken("Fx")));
\endcode

\note <b>USDeeper: def vs over?</b> You may have noticed in the example above that the prims \</World\> and \</World/Sets\> were declared as \b def, while \</World/Fx\> was declared as \b over. "def" and "over" are two of the three possible "prim specifiers" that inform USD of the intended purpose of the data authored for a prim in a particular layer. For a deeper explanation, please see Prim Specifiers.

\note <b>深入了解：def 与 over 的区别？</b> 你可能已经注意到，在上面的示例中，prim \</World\> 和 \</World/Sets\> 被声明为 \b def，而 \</World/Fx\> 被声明为 \b over。"def" 和 "over" 是三种可能的"prim 指定符"中的两种，它们告知 USD 在特定 layer 中为 prim 创作的数据的预期用途。如需更深入的解释，请参阅 Prim 指定符。

---

### Retaining and Using UsdPrims Safely {#Usd_OM_UsdPrim_Retention}
### 安全地保留和使用 UsdPrim {#Usd_OM_UsdPrim_Retention}

\todo contents/caching, then , etc

\todo 内容/缓存，等等

<!-- Not ready yet, so commenting out for now.
### UsdPrim is a Proxy for Composed PrimSpecs {#Usd_OM_UsdPrim_Proxy}

<!-- 尚未就绪，暂时注释掉。
### UsdPrim 是合成 PrimSpec 的代理 {#Usd_OM_UsdPrim_Proxy}

Let us consider an extension of the example above that adds a (intra-layer) reference to the \</World/Fx\> prim:

让我们考虑上面示例的一个扩展，给 \</World/Fx\> prim 添加一个（layer 内）引用：

\code{.unparsed}
#usda 1.0

def "World"
{
    def "Sets"
    {
    }

    over "Fx" (
        references = </Effects>
    )
    {
    }
}

def "Effects"
{
    def "Effect_1"
    {
    }

    def "Effect_2"
    {
    }
}
\endcode
-->

---

## UsdProperty: Common Interface for Attributes and Relationships {#Usd_OM_UsdProperty}
## UsdProperty：属性和关系的公共接口 {#Usd_OM_UsdProperty}

## UsdAttribute: Typed, Sampled, Data {#Usd_OM_UsdAttribute}
## UsdAttribute：有类型、可采样的数据 {#Usd_OM_UsdAttribute}

### Time and Timing in USD {#Usd_OM_UsdTimeCode}
### USD 中的时间和时序 {#Usd_OM_UsdTimeCode}

## UsdRelationship: Targetting Namespace Objects {#Usd_OM_UsdRelationship}
## UsdRelationship：指向命名空间对象 {#Usd_OM_UsdRelationship}

---

## General Metadata in USD {#Usd_OM_Metadata}
## USD 中的通用元数据 {#Usd_OM_Metadata}

All of the objects we have described so far, SdfLayer, UsdStage, UsdPrim, and both subclasses of UsdProperty, can possess \em metadata. In USD, metadata serves several critical roles for describing object behavior and meaning, and is defined by the following properties:

到目前为止我们描述的所有对象——SdfLayer、UsdStage、UsdPrim，以及 UsdProperty 的两个子类——都可以拥有 \em 元数据。在 USD 中，元数据在描述对象行为和含义方面扮演着几个关键角色，由以下特性定义：

\li *Metadata is strongly typed*, and can possess a fallback value. Both of these pieces of information can be retrieved, using the metadatum's name, from the SdfSchema singleton. Metadata can have any of the types described in Datatypes.

\li *元数据是强类型的*，可以拥有一个回退值。这两部分信息都可以通过元数据名称从 SdfSchema 单例中获取。元数据可以具有"数据类型"中描述的任何类型。

\li *Metadata is extensible.* The implication of the SdfSchema providing type information about metadata is that all metadata must be registered with USD/Sdf. The SdfSchema itself registers a set of metadata meaningful to the Sdf data model, but any module discoverable by USD's plugin system can extend the known set of metadata, as described in the sdf_plugin_metadata documentation. Core USD, and most of the higher-level schema modules use this mechanism to good effect.

\li *元数据是可扩展的。* SdfSchema 提供元数据类型信息的含义是：所有元数据都必须向 USD/Sdf 注册。SdfSchema 本身注册了一组对 Sdf 数据模型有意义的元数据，但任何可被 USD 插件系统发现的模块都可以扩展已知的元数据集合，如 sdf_plugin_metadata 文档所述。核心 USD 和大多数更高层级的 schema 模块都很好地利用了这个机制。

\li *Metadata is unvarying.* Although metadata values can be overridden in any layer just as UsdAttribute values can be, \em within a given layer, a metadatum can have only a single value - i.e. it cannot be sampled over time. Removing time as an axis of variation allows metadata to be evaluated and stored more efficiently than attribute values, and also means that metadata authored in Value Clips will be ignored by USD.

\li *元数据是不变的。* 虽然元数据值可以像 UsdAttribute 值一样在任何 layer 中被覆盖，但 \em 在给定 layer 内，一个元数据只能有单个值——即它不能随时间采样。移除时间这一变化维度使得元数据的求值和存储比属性值更高效，也意味着在值剪辑中创作的元数据会被 USD 忽略。

\li *Core metadata resolution rules vary.* Attribute Value Resolution is fixed for all attributes, core and custom. Certain of the "core metadata", however, have value resolution behavior other than "strongest opinion wins." A class of metadata used to specify composition behavior (as well as relationships) subscribe to list-editing composition. Other metadata, like attribute \em typeName, adhere to "weakest opinion wins". The prim metadata \em specifier has a highly specialized resolution behavior owing to the way in which overs, defs, and classes combine. *Value resolution behavior may not be changed for extension metadata,* however - all extension metadata will be resolved based on its datatype: strongest wins for primitive datatypes, element-wise strongest wins for dictionaries.

\li *核心元数据的解析规则各不相同。* 属性值解析对所有属性（核心和自定义）都是固定的。然而，某些"核心元数据"的值解析行为不是"最强意见胜出"。用于指定合成行为（以及关系）的一类元数据采用列表编辑合成。其他元数据，如属性 \em typeName，遵循"最弱意见胜出"。prim 元数据 \em specifier 由于 over、def 和 class 的组合方式而具有高度特化的解析行为。*但是，扩展元数据的值解析行为不能被更改*——所有扩展元数据将根据其数据类型解析：基本数据类型最强意见胜出，字典类型按元素逐个最强意见胜出。

---

## Schema and Prim Definition Registry {#Usd_OM_SchemaDefinitionRegistry}
## Schema 和 Prim 定义注册表 {#Usd_OM_SchemaDefinitionRegistry}

The singleton class UsdSchemaRegistry exists to provide access to all available schemas. It queries plugins to find all registered schema types and generates prim definitions from the processed generatedSchema.usda files (generated when a schema.usda file is processed by \em usdGenSchema).

单例类 UsdSchemaRegistry 的存在是为了提供对所有可用 schema 的访问。它查询插件以找到所有注册的 schema 类型，并从处理后的 generatedSchema.usda 文件（当 schema.usda 文件被 \em usdGenSchema 处理时生成）中生成 prim 定义。

A prim definition, provided by the UsdPrimDefinition class, is an encapsulation of the built-in data that is imparted on a prim by the schemas for the prim's complete type signature. The built-in data accessible from a prim definition includes the list of built-in properties, an SdfSpec defining each property, the list of built-in metadata fields, and fallback values for attributes and metadata fields.

由 UsdPrimDefinition 类提供的 prim 定义，是对 prim 的完整类型签名所对应的 schema 赋予 prim 的内置数据的封装。可从 prim 定义访问的内置数据包括：内置属性列表、定义每个属性的 SdfSpec、内置元数据字段列表，以及属性和元数据字段的回退值。

The schema registry creates and provides access to prim definitions for each individual "IsA" and applied API schema. It also provides API to build a composite prim definition for a combination of an "IsA" type with a list of applied API schemas. The prim definition that a prim uses is determined by the combination of its type name and the list of any applied API schemas applied to the prim and is generally what we are referring to when we talk about a UsdPrim's "prim definition".

Schema 注册表为每个单独的"IsA"和应用 API schema 创建并提供 prim 定义。它还提供 API 来为"IsA"类型与应用 API schema 列表的组合构建复合 prim 定义。一个 prim 使用的 prim 定义由其类型名称和应用于该 prim 的应用 API schema 列表的组合决定，这通常就是我们谈论 UsdPrim 的"prim 定义"时所指的内容。

---

## Fallback Prim Types {#Usd_OM_FallbackPrimTypes}
## 回退 Prim 类型 {#Usd_OM_FallbackPrimTypes}

When you create a new "IsA" schema to use as a prim type, there may be an expectation that stages containing prims of your new type will be opened using a version of USD that does not have the new schema. You may want to provide these other, typically older, versions of USD with one or more reasonable alternative prim types to use instead of your type when its schema is not available. We provide the following mechanism for this.

当你创建一个新的"IsA" schema 用作 prim 类型时，可能存在这样的情况：包含你新类型 prim 的 stage 会被一个没有这个新 schema 的 USD 版本打开。你可能希望为这些其他（通常是较旧的）USD 版本提供一个或多个合理的替代 prim 类型，以便在你的 schema 不可用时使用。我们为此提供以下机制。

You can specify an array of \em fallbackTypes tokens as customData for your class in the schema.usda. Schema generation will process this list of fallback types and add it to the dictionary of all prim fallback types that the schema registry provides.

你可以在 schema.usda 中为你的类指定一个 \em fallbackTypes token 数组作为 customData。Schema 生成将处理这个回退类型列表，并将其添加到 schema 注册表提供的所有 prim 回退类型字典中。

To provide the currently registered prim type fallbacks to a version of USD that does not have some of these schemas, they must be recorded into any stages that may want to be opened in one of these versions. At any point before saving or exporting a stage, this can be done by calling the function UsdStage::WriteFallbackPrimTypes to write the schema registry's dictionary of fallback prim types to the stage's root layer metadata.

为了向一个没有某些 schema 的 USD 版本提供当前注册的 prim 类型回退，必须将它们记录到任何可能想要在这些版本中打开的 stage 中。在保存或导出 stage 之前的任何时刻，可以通过调用 UsdStage::WriteFallbackPrimTypes 函数，将 schema 注册表的回退 prim 类型字典写入 stage 的根 layer 元数据。

When a stage is opened and a prim with an unrecognized type name is encountered, the stage's fallback prim types metadata is consulted. If the unrecognized type has a fallback types list in the metadata, all prims with the unrecognized type name will be treated as having the effective schema type of the first recognized type in the list.

当打开一个 stage 并遇到一个无法识别类型名称的 prim 时，会查阅 stage 的回退 prim 类型元数据。如果无法识别的类型在元数据中有一个回退类型列表，所有具有该无法识别类型名称的 prim 将被视为具有列表中第一个被识别类型的有效 schema 类型。

\sa UsdPrim::GetPrimTypeInfo, UsdPrim::IsA, UsdSchemaRegistry::GetFallbackPrimTypes

\sa 另请参阅 UsdPrim::GetPrimTypeInfo, UsdPrim::IsA, UsdSchemaRegistry::GetFallbackPrimTypes

---

## Composition Operator Interfaces: UsdReferences, UsdInherits, UsdVariantSets {#Usd_OM_OtherObjects}
## 合成运算符接口：UsdReferences, UsdInherits, UsdVariantSets {#Usd_OM_OtherObjects}

### ListOps and List Editing {#Usd_OM_ListOps}
### ListOps 和列表编辑 {#Usd_OM_ListOps}

---

## 翻译说明

### 术语对照表

| 英文术语 | 中文翻译 | 说明 |
|---|---|---|
| Object Model | 对象模型 | USD 的核心对象（Stage/Prim/Property/Layer）及其关系 |
| SdfLayer | SdfLayer | 层，保留不译，USD 的底层数据容器 |
| rootLayer | 根层（rootLayer） | 打开 Stage 时指定的主 layer |
| UsdStage | UsdStage | 舞台，保留不译，合成后的场景运行时对象 |
| UsdPrim | UsdPrim | 图元，保留不译，场景的基本节点 |
| UsdProperty | UsdProperty | 属性，保留不译，Attribute 和 Relationship 的基类 |
| UsdAttribute | UsdAttribute | 特性/属性值，保留不译，有值的数据 |
| UsdRelationship | UsdRelationship | 关系，保留不译，指向其他 prim 的引用 |
| UsdReferences | UsdReferences | 引用接口，保留不译 |
| UsdInherits | UsdInherits | 继承接口，保留不译 |
| UsdVariantSets | UsdVariantSets | 变体集接口，保留不译 |
| UsdSchemaRegistry | UsdSchemaRegistry | Schema 注册表，保留不译 |
| UsdPrimDefinition | UsdPrimDefinition | Prim 定义，保留不译 |
| UsdStageCache | UsdStageCache | Stage 缓存，保留不译 |
| SdfPath | SdfPath | 路径标识符，保留不译 |
| SdfSchema | SdfSchema | Schema 定义单例，保留不译 |
| SdfSpec | SdfSpec | 场景描述规范条目，保留不译 |
| anonymous layer | 匿名层 | 仅存在于内存中的 layer |
| composition operators | 合成运算符 | sublayer/reference/payload/inherit/specialize/variant |
| composition arcs | 合成弧线 | prim 级别的合成连接 |
| value resolution | 值解析 | 合成时解决属性值冲突的过程 |
| scenegraph | 场景图 | prim 的树形数据结构 |
| namespace location | 命名空间位置 | prim 在场景图中的唯一路径 |
| pseudo-root | 伪根 | Stage 的虚拟根 prim `/` |
| prim specifier | prim 指定符 | def/over/class 三种声明方式 |
| metadata | 元数据 | 关于对象的描述信息 |
| fallback value | 回退值 | 未设置时的默认值 |
| fallback prim types | 回退 prim 类型 | schema 不可用时的替代类型 |
| strongly typed | 强类型 | 每个值都有明确的类型 |
| extensible | 可扩展 | 允许第三方添加新类型 |
| unvarying | 不变的 | 不随时间变化 |
| IsA schema | "IsA" schema | 表示"是一个"类型继承关系的 schema |
| applied API schema | 应用 API schema | 可叠加到 prim 上的功能扩展 schema |
| plugin system | 插件系统 | USD 的可扩展机制 |
| SdfFileFormat | SdfFileFormat | 文件格式插件机制 |
| Ar Asset Resolution | Ar 资产解析 | 资产路径解析插件 API |
| list-editing composition | 列表编辑合成 | 合成时对列表类型的特殊处理规则 |
| strongest opinion wins | 最强意见胜出 | 合成时强层覆盖弱层 |
| weakest opinion wins | 最弱意见胜出 | 合成时弱层反而胜出（特殊规则） |
| Value Clips | 值剪辑 | 按时间片叠加数据的机制 |
| prim definition | prim 定义 | prim 类型对应的内置数据封装 |
| type signature | 类型签名 | prim 的类型名 + 应用的 API schema 列表 |
| refcount | 引用计数 | 对象的引用计数，降为零时销毁 |
| strong/weak pointer | 强/弱指针 | C++ 的智能指针机制 |
| serialize | 序列化 | 把内存数据写入文件 |
| populate (a stage) | 填充（stage） | 根据 layer 合成出 stage 的 prim 树 |
| variant selection | 变体选择 | 在 VariantSet 上选择某个变体 |
| activation opinions | 激活意见 | 控制 prim 是否 active 的意见 |
| load-states | 加载状态 | payload 是否已加载的状态 |
| customData | customData | 自定义数据，保留不译 |
| usdGenSchema | usdGenSchema | Schema 生成工具，保留不译 |

### 核心对象关系图

```
SdfLayer（数据文件）
    │
    │ 通过 Pcp 合成规则
    ▼
UsdStage（合成后的场景）
    │ 拥有场景图
    ├── UsdPrim（伪根 `/`）
    │   ├── UsdPrim（根 prim，如 /World）
    │   │   ├── UsdPrim（子 prim，如 /World/Sets）
    │   │   └── UsdProperty
    │   │       ├── UsdAttribute（有值的数据）
    │   │       └── UsdRelationship（指向其他 prim）
    │   └── ...
    └── 所有对象都可拥有 Metadata（元数据）
```

### 生命周期要点

| 对象 | 生命周期管理 | 销毁后果 |
|---|---|---|
| SdfLayer | 强引用 SdfLayerRefPtr / 弱引用 SdfLayerHandle | 未保存就销毁 → 数据丢失 |
| UsdStage | 强引用 UsdStageRefPtr / 弱引用 UsdStagePtr | 销毁 → 释放所有 layer 的强引用 |
| UsdStageCache | 显式管理 | 可缓存 stage，需手动清除 |

### 元数据特性速查

| 特性 | 说明 |
|---|---|
| 强类型 | 每个元数据有明确类型 |
| 可扩展 | 可通过插件注册新元数据 |
| 不变的 | 不随时间采样，单个 layer 内单值 |
| 解析规则各异 | 有的"最强胜出"，有的"最弱胜出" |

---

*原文：`F:\newton\OpenUSD\pxr\usd\usd\docs\objectModel.md`（OpenUSD 26.08）*
