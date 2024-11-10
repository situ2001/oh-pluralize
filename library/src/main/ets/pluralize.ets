// Rule storage - pluralize and singularize need to be run sequentially,
// while other rules can be optimized using an object for instant lookups.

type Rule = [RegExp, string];

const pluralRules: Array<Rule> = [];
const singularRules: Array<Rule> = [];
const uncountables: Map<string, boolean> = new Map<string, boolean>();
const irregularPlurals: Map<string, string> = new Map<string, string>();
const irregularSingles: Map<string, string> = new Map<string, string>();

/**
 * Sanitize a pluralization rule to a usable regular expression.
 *
 * @param  {(RegExp|string)} rule
 * @return {RegExp}
 */
export function sanitizeRule(rule: string | RegExp) {
  if (typeof rule === 'string') {
    return new RegExp('^' + rule + '$', 'i');
  }

  return rule;
}

/**
 * Pass in a word token to produce a function that can replicate the case on
 * another word.
 *
 * @param  {string}   word
 * @param  {string}   token
 * @return {Function}
 */
export function restoreCase(word: string, token: string) {
  // Tokens are an exact match.
  if (word === token) {
    return token;
  }

  // Lower cased words. E.g. "hello".
  if (word === word.toLowerCase()) {
    return token.toLowerCase();
  }

  // Upper cased words. E.g. "WHISKY".
  if (word === word.toUpperCase()) {
    return token.toUpperCase();
  }

  // Title cased words. E.g. "Title".
  if (word[0] === word[0].toUpperCase()) {
    return token.charAt(0).toUpperCase() + token.substr(1).toLowerCase();
  }

  // Lower cased words. E.g. "test".
  return token.toLowerCase();
}

/**
 * Interpolate a regexp string.
 *
 * @param  {string} str
 * @param  {Array}  captures
 * @return {string}
 */
function interpolate(str: string, captures: Array<string>) {
  return str.replace(/\$(\d{1,2})/g, (match, index: string): string => {
    const indexNum = Number(index);
    return captures[indexNum] || '';
  });
}

/**
 * Replace a word using a rule.
 *
 * @param  {string} word
 * @param  {Array}  rule
 * @return {string}
 */
function replace(word: string, rule: Rule) {
  return word.replace(rule[0], (match, index: string, ...rest: string[]): string => {
    let result = interpolate(rule[1], [match, index, ...rest]); // TODO is the replaced `argument` correct?
    if (match === '') {
      const indexNum: number = Number(index);
      return restoreCase(word[indexNum - 1], result);
    }
    return restoreCase(match, result);
  });
}

/**
 * Sanitize a word by passing in the word and sanitization rules.
 *
 * @param  {string}   token
 * @param  {string}   word
 * @param  {Array}    rules
 * @return {string}
 */
function sanitizeWord(token: string, word: string, rules: Array<Rule>): string {
  // Empty string or doesn't need fixing.
  // if (!token.length || uncountables.hasOwnProperty(token)) {
  if (!token.length || uncountables.has(token)) {
    return word;
  }

  let len = rules.length;

  // Iterate over the sanitization rules and use the first one to match.
  while (len--) {
    const rule = rules[len];

    if (rule[0].test(word)) {
      return replace(word, rule);
    }
  }

  return word;
}

/**
 * Replace a word with the updated word.
 *
 * @param  {Object}   replaceMap
 * @param  {Object}   keepMap
 * @param  {Array}    rules
 * @return {Function}
 */
function replaceWord(
  replaceMap: Map<string, string>,
  keepMap: Map<string, string>,
  rules: Array<Rule>
) {
  return (word: string): string => {
    // Get the correct token and case restoration functions.
    let token = word.toLowerCase();
    // Check against the keep object map.
    if (keepMap.has(token)) {
      return restoreCase(word, token);
    }
    // Check against the replacement map for a direct word replacement.
    if (replaceMap.has(token)) {
      return restoreCase(word, replaceMap.get(token)!);
    }
    // Run all the rules against the word.
    return sanitizeWord(token, word, rules);
  };
}

/**
 * Check if a word is part of the map.
 */
function checkWord(replaceMap: Map<string, string>,
  keepMap: Map<string, string>,
  rules: Array<Rule>,
  bool?: boolean) {
  return (word: string): boolean => {
    let token = word.toLowerCase();
    if (keepMap.has(token)) {
      return true;
    }
    if (replaceMap.has(token)) {
      return false;
    }
    return sanitizeWord(token, token, rules) === token;
  };
}

/**
 * Pluralize or singularize a word based on the passed in count.
 *
 * @param  {string}  word      The word to pluralize
 * @param  {number}  count     How many of the word exist
 * @param  {boolean} inclusive Whether to prefix with the number (e.g. 3 ducks)
 * @return {string}
 */
export default function pluralize(word: string, count: number, inclusive: boolean = false): string {
  let pluralized = count === 1
    ? pluralize.singular(word) : pluralize.plural(word);

  return (inclusive ? count + ' ' : '') + pluralized;
}

/**
 * Pluralize a word.
 *
 * @type {Function}
 */
pluralize.plural = replaceWord(
  irregularSingles, irregularPlurals, pluralRules
);

/**
 * Check if a word is plural.
 *
 * @type {Function}
 */
pluralize.isPlural = checkWord(
  irregularSingles, irregularPlurals, pluralRules
);

/**
 * Singularize a word.
 *
 * @type {Function}
 */
pluralize.singular = replaceWord(
  irregularPlurals, irregularSingles, singularRules
);

/**
 * Check if a word is singular.
 *
 * @type {Function}
 */
pluralize.isSingular = checkWord(
  irregularPlurals, irregularSingles, singularRules
);


const addPluralRule = (rule: string | RegExp, replacement: string) => {
  pluralRules.push([sanitizeRule(rule), replacement]);
}
/**
 * Add a pluralization rule to the collection.
 *
 * @param {(string|RegExp)} rule
 * @param {string}          replacement
 */
pluralize.addPluralRule = addPluralRule;

const addSingularRule = (rule: string | RegExp, replacement: string) => {
  singularRules.push([sanitizeRule(rule), replacement]);
};
/**
 * Add a singularization rule to the collection.
 *
 * @param {(string|RegExp)} rule
 * @param {string}          replacement
 */
pluralize.addSingularRule = addSingularRule;

const addUncountableRule = (word: string | RegExp) => {
  if (typeof word === 'string') {
    uncountables.set(word.toLowerCase(), true);
    return;
  }
  // Set singular and plural references for the word.
  pluralize.addPluralRule(word, '$0');
  pluralize.addSingularRule(word, '$0');
}
/**
 * Add an uncountable word rule.
 *
 * @param {(string|RegExp)} word
 */
pluralize.addUncountableRule = addUncountableRule;


const addIrregularRule = (single: string, plural: string) => {
  plural = plural.toLowerCase();
  single = single.toLowerCase();
  irregularSingles.set(single, plural);
  irregularPlurals.set(plural, single);
};
/**
 * Add an irregular word definition.
 *
 * @param {string} single
 * @param {string} plural
 */
pluralize.addIrregularRule = addIrregularRule;

/**
 * Irregular rules.
 */
[
// Pronouns.
  ['I', 'we'],
  ['me', 'us'],
  ['he', 'they'],
  ['she', 'they'],
  ['them', 'them'],
  ['myself', 'ourselves'],
  ['yourself', 'yourselves'],
  ['itself', 'themselves'],
  ['herself', 'themselves'],
  ['himself', 'themselves'],
  ['themself', 'themselves'],
  ['is', 'are'],
  ['was', 'were'],
  ['has', 'have'],
  ['this', 'these'],
  ['that', 'those'],
  ['my', 'our'],
  ['its', 'their'],
  ['his', 'their'],
  ['her', 'their'],
  // Words ending in with a consonant and `o`.
  ['echo', 'echoes'],
  ['dingo', 'dingoes'],
  ['volcano', 'volcanoes'],
  ['tornado', 'tornadoes'],
  ['torpedo', 'torpedoes'],
  // Ends with `us`.
  ['genus', 'genera'],
  ['viscus', 'viscera'],
  // Ends with `ma`.
  ['stigma', 'stigmata'],
  ['stoma', 'stomata'],
  ['dogma', 'dogmata'],
  ['lemma', 'lemmata'],
  ['schema', 'schemata'],
  ['anathema', 'anathemata'],
  // Other irregular rules.
  ['ox', 'oxen'],
  ['axe', 'axes'],
  ['die', 'dice'],
  ['yes', 'yeses'],
  ['foot', 'feet'],
  ['eave', 'eaves'],
  ['goose', 'geese'],
  ['tooth', 'teeth'],
  ['quiz', 'quizzes'],
  ['human', 'humans'],
  ['proof', 'proofs'],
  ['carve', 'carves'],
  ['valve', 'valves'],
  ['looey', 'looies'],
  ['thief', 'thieves'],
  ['groove', 'grooves'],
  ['pickaxe', 'pickaxes'],
  ['passerby', 'passersby'],
  ['canvas', 'canvases']
].forEach((rule): void => {
  return pluralize.addIrregularRule(rule[0], rule[1]);
});

/**
 * Pluralization rules.
 */
[
  [/s?$/i, 's'],
  [/[^\u0000-\u007F]$/i, '$0'],
  [/([^aeiou]ese)$/i, '$1'],
  [/(ax|test)is$/i, '$1es'],
  [/(alias|[^aou]us|t[lm]as|gas|ris)$/i, '$1es'],
  [/(e[mn]u)s?$/i, '$1s'],
  [/([^l]ias|[aeiou]las|[ejzr]as|[iu]am)$/i, '$1'],
  [/(alumn|syllab|vir|radi|nucle|fung|cact|stimul|termin|bacill|foc|uter|loc|strat)(?:us|i)$/i, '$1i'],
  [/(alumn|alg|vertebr)(?:a|ae)$/i, '$1ae'],
  [/(seraph|cherub)(?:im)?$/i, '$1im'],
  [/(her|at|gr)o$/i, '$1oes'],
  [/(agend|addend|millenni|dat|extrem|bacteri|desiderat|strat|candelabr|errat|ov|symposi|curricul|automat|quor)(?:a|um)$/i, '$1a'],
  [/(apheli|hyperbat|periheli|asyndet|noumen|phenomen|criteri|organ|prolegomen|hedr|automat)(?:a|on)$/i, '$1a'],
  [/sis$/i, 'ses'],
  [/(?:(kni|wi|li)fe|(ar|l|ea|eo|oa|hoo)f)$/i, '$1$2ves'],
  [/([^aeiouy]|qu)y$/i, '$1ies'],
  [/([^ch][ieo][ln])ey$/i, '$1ies'],
  [/(x|ch|ss|sh|zz)$/i, '$1es'],
  [/(matr|cod|mur|sil|vert|ind|append)(?:ix|ex)$/i, '$1ices'],
  [/\b((?:tit)?m|l)(?:ice|ouse)$/i, '$1ice'],
  [/(pe)(?:rson|ople)$/i, '$1ople'],
  [/(child)(?:ren)?$/i, '$1ren'],
  [/eaux$/i, '$0'],
  [/m[ae]n$/i, 'men'],
  ['thou', 'you']
].forEach((rule: (string | RegExp)[]): void => {
  return pluralize.addPluralRule(rule[0], rule[1] as string);
});

/**
 * Singularization rules.
 */
[
  [/s$/i, ''],
  [/(ss)$/i, '$1'],
  [/(wi|kni|(?:after|half|high|low|mid|non|night|[^\w]|^)li)ves$/i, '$1fe'],
  [/(ar|(?:wo|[ae])l|[eo][ao])ves$/i, '$1f'],
  [/ies$/i, 'y'],
  [/(dg|ss|ois|lk|ok|wn|mb|th|ch|ec|oal|is|ck|ix|sser|ts|wb)ies$/i, '$1ie'],
  [/\b(l|(?:neck|cross|hog|aun)?t|coll|faer|food|gen|goon|group|hipp|junk|vegg|(?:pork)?p|charl|calor|cut)ies$/i, '$1ie'],
  [/\b(mon|smil)ies$/i, '$1ey'],
  [/\b((?:tit)?m|l)ice$/i, '$1ouse'],
  [/(seraph|cherub)im$/i, '$1'],
  [/(x|ch|ss|sh|zz|tto|go|cho|alias|[^aou]us|t[lm]as|gas|(?:her|at|gr)o|[aeiou]ris)(?:es)?$/i, '$1'],
  [/(analy|diagno|parenthe|progno|synop|the|empha|cri|ne)(?:sis|ses)$/i, '$1sis'],
  [/(movie|twelve|abuse|e[mn]u)s$/i, '$1'],
  [/(test)(?:is|es)$/i, '$1is'],
  [/(alumn|syllab|vir|radi|nucle|fung|cact|stimul|termin|bacill|foc|uter|loc|strat)(?:us|i)$/i, '$1us'],
  [/(agend|addend|millenni|dat|extrem|bacteri|desiderat|strat|candelabr|errat|ov|symposi|curricul|quor)a$/i, '$1um'],
  [/(apheli|hyperbat|periheli|asyndet|noumen|phenomen|criteri|organ|prolegomen|hedr|automat)a$/i, '$1on'],
  [/(alumn|alg|vertebr)ae$/i, '$1a'],
  [/(cod|mur|sil|vert|ind)ices$/i, '$1ex'],
  [/(matr|append)ices$/i, '$1ix'],
  [/(pe)(rson|ople)$/i, '$1rson'],
  [/(child)ren$/i, '$1'],
  [/(eau)x?$/i, '$1'],
  [/men$/i, 'man']
].forEach((rule: (string | RegExp)[]): void => {
  return pluralize.addSingularRule(rule[0], rule[1] as string);
});

/**
 * Uncountable rules.
 */
[
// Singular words with no plurals.
  'adulthood',
  'advice',
  'agenda',
  'aid',
  'aircraft',
  'alcohol',
  'ammo',
  'analytics',
  'anime',
  'athletics',
  'audio',
  'bison',
  'blood',
  'bream',
  'buffalo',
  'butter',
  'carp',
  'cash',
  'chassis',
  'chess',
  'clothing',
  'cod',
  'commerce',
  'cooperation',
  'corps',
  'debris',
  'diabetes',
  'digestion',
  'elk',
  'energy',
  'equipment',
  'excretion',
  'expertise',
  'firmware',
  'flounder',
  'fun',
  'gallows',
  'garbage',
  'graffiti',
  'hardware',
  'headquarters',
  'health',
  'herpes',
  'highjinks',
  'homework',
  'housework',
  'information',
  'jeans',
  'justice',
  'kudos',
  'labour',
  'literature',
  'machinery',
  'mackerel',
  'mail',
  'media',
  'mews',
  'moose',
  'music',
  'mud',
  'manga',
  'news',
  'only',
  'personnel',
  'pike',
  'plankton',
  'pliers',
  'police',
  'pollution',
  'premises',
  'rain',
  'research',
  'rice',
  'salmon',
  'scissors',
  'series',
  'sewage',
  'shambles',
  'shrimp',
  'software',
  'staff',
  'swine',
  'tennis',
  'traffic',
  'transportation',
  'trout',
  'tuna',
  'wealth',
  'welfare',
  'whiting',
  'wildebeest',
  'wildlife',
  'you',
  /pok[eé]mon$/i,
  // Regexes.
  /[^aeiou]ese$/i, // "chinese", "japanese"
  /deer$/i, // "deer", "reindeer"
  /fish$/i, // "fish", "blowfish", "angelfish"
  /measles$/i,
  /o[iu]s$/i, // "carnivorous"
  /pox$/i, // "chickpox", "smallpox"
  /sheep$/i
].forEach(pluralize.addUncountableRule);
