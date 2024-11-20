# Pluralize

A pluralize library for OpenHarmony to convert English words between singular and plural forms.

一个用于 OpenHarmony 的对英文单词进行单数化或复数化的工具库

Example: https://github.com/situ2001/oh-pluralize

示例: clone https://github.com/situ2001/oh-pluralize 后用 DevEco-Studio 打开并运行即可

## Installation

```shell
ohpm i pluralize
```

## Common Usage

```javascript
import pluralize from 'pluralize';

// word      要进行单/复数化的单词
// count     该单词的量词数量
// inclusive 是否要将数量添加到单词的前面
pluralize('peach') //=> "peaches"
pluralize('peaches', 1) //=> "peach"
pluralize('peach', 2) //=> "peaches"
pluralize('peach', 2, true) //=> "2 peaches"
pluralize.singular('peaches') //=> "peach"
```

## More API

Some common pluralize/singular rules are included in this library. But that is not for all, you can add your custom rules to this library at runtime. 

该库已经集成了常见的单复数转换规则,但你也可以在运行时添加自定义规则

```javascript
// 需要在后缀为 gex 的单词后面加 ii
pluralize.plural('regex') //=> "regexes"
pluralize.addPluralRule(/gex$/i, 'gexii')
pluralize.plural('regex') //=> "regexii"

// 对复数单词添加其单数形式
pluralize.singular('singles') //=> "single"
pluralize.addSingularRule(/singles$/i, 'singular')
pluralize.singular('singles') //=> "singular"

// 添加不规则的相互转换规则,比如 we 的单数是 I, I 的复数是 we
pluralize.plural('irregular') //=> "irregulars"
pluralize.addIrregularRule('irregular', 'regular')
pluralize.plural('irregular') //=> "regular"

// 添加不可数单词
pluralize.plural('paper') //=> "papers"
pluralize.addUncountableRule('paper')
pluralize.plural('paper') //=> "paper"
```

Besides, you can check if a word is plural or not. 

此外, 你还可以查询单词是否为复数形式.

```javascript
// 查询单词是否为复数/单数形式
pluralize.isPlural('test') //=> false
pluralize.isSingular('test') //=> true
```

## Credit

This library is developed based on the js lib https://github.com/plurals/pluralize. 

该库基于 https://github.com/plurals/pluralize 开发,将其代码迁移并适配到 ETS 语言生态中
