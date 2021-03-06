"
============================================================================
  ParserKit.st -- OMeta like parser implementation
/NS
  Copyright (C) 2011 Mathieu Suen <mathieu@nebu.li>

  The parser have the same syntax that the OMeta one. Although the semantic 
  could differ. For the time being to write expression use the 
  PKParseExpression class. See example at the bottom of the file.

    2012/02/09  This file should be poulate in it a proper unit testing fashon

    2012/03/08 Rule lookup can be optimize at runtime

    2012/03/05 Fix way input consuming. 

    2012/02/22 Many bug fix and start to implement a OMeta parser. 
      - Todo fix the way we walk throw the input. When to consume or not
    the input etc.
      - Some PK*Expression should be singleton

    2011/09/21 Beginning of the expression tree
      - Get the expression tree implementation inspire from OMGrammar
 
    2011/10/20 Beginning of the OMeta implementation
      - Adding the PKParserBase PKRules class

    2011/11/09 Todo merge PKRules with PKParserBase

============================================================================
"

NSObject subclass: Calculator [
	multiply: a with: b [

		^a * b
	]

	value: v [

		^v
	]

	add: a with: b [

		^a + b
	]

	buildValue: tok [

		^tok integerValue
	]
]


NSObject subclass: SmalltalkTool [
	
	run [
		| dict parser b c tExp  oMeta oMetaMatch content contentString match |

		ETTranscript setDebugMode: false.
		self testPKNode.
		oMeta := PKParser alloc initWithNewGrammar: 'Test'.
		oMeta addRule: 'foo'  expression: 'foo' asExp .
		oMeta := PKParser alloc initWithGrammar: '_ActionizedEtoileOMeta'.
		ETTranscript show: oMeta rules; cr.
		ETTranscript show: oMeta; cr.
		ETTranscript show: (oMeta at: 'Char'); cr.
		ETTranscript show: (oMeta match:( '\\n') rule: 'Char').
		ETTranscript show: (oMeta match:('n') rule: 'Char').
		ETTranscript show: (oMeta match:( '\66') rule: 'Char').
		ETTranscript show: (oMeta match:( '\F8') rule: 'Char').
		ETTranscript show: (oMeta match:( '\6E') rule: 'Char').
		ETTranscript show: (oMeta match:( '\6A') rule: 'Char').
		ETTranscript show: (oMeta match:( '\66-\F4') rule: 'Range').
		ETTranscript show: (oMeta match:( 'a-d') rule: 'Range').
		ETTranscript show: (oMeta match:( '[a-d] ') rule: 'Class').
		ETTranscript show: (oMeta match:( '[a-d\34] ') rule: 'Class').
		ETTranscript show: (oMeta match:( '[a-dA-Z]\n') rule: 'Class').
		ETTranscript show: (oMeta match:( '''foo'' bar') rule: 'Literal').
		ETTranscript show: (oMeta match:( '"bar" foo') rule: 'Literal').
		ETTranscript show: (oMeta match:( '. ? ') rule: 'Suffix').
		ETTranscript show: (oMeta match:( '([zf]"oo")?') rule: 'Suffix').
		ETTranscript show: (oMeta match: '' rule: 'Spacing').
		ETTranscript show: (oMeta match: 'One <- .' rule: 'Grammar').
		ETTranscript show: (oMeta match: 'EndOfLine <- "\r\n"' rule: 'Grammar').
		ETTranscript show: (oMeta match: 'Ometa { EndOfLine <- "\r\n" }' rule: 'Ometa').
		ETTranscript show: (oMeta match: 'Foo' rule: 'Identifier').
		oMeta setDelegate: (PKParserASTGenerator new).
		oMetaMatch := oMeta match:  '"\r\n"' rule: 'Literal'.
		ETTranscript show: oMetaMatch description;cr.
		oMetaMatch reduce.
		content := NSFileManager defaultManager contentsAtPath: './ometa.pk'.
		contentString := NSString alloc initWithData: content encoding: 4.
		self testSubgrammar.
		
		
		ETTranscript show: (PKParser loadGrammarsFromString: contentString); cr.
		ETTranscript show: (PKParser getGrammar: 'ActionizedEtoileOMeta') description; cr.

		match := oMeta match: '''test''' rule: 'Literal'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: '[:alnum:]' rule: 'BuiltinRange'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: '.' rule: 'Primary'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: '$' rule: 'Primary'.
		ETTranscript show: match reduce; cr.
		match := oMeta match: 'a-d' rule: 'Range'.
		ETTranscript show: match reduce; cr.
		
		match := oMeta match:( '[a-d] ') rule: 'Class'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '[a-d\34] ') rule: 'Class'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\\t') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\\n') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\\\\') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		match := oMeta match:( '\5F') rule: 'Char'.
		ETTranscript show: match.
		ETTranscript show: match reduce; cr.

		self testFinalParser.
		self testSmalltalkParser.
		self testCalc.
		self testOmetaASTGenerator.
		
		
	]

	testSubgrammar [
		| grammar sub |
		grammar := PKParser alloc initWithNewGrammar: 'PEG'.
		grammar addRule: 'Ab' expression: ('a' asExp or: 'b' asExp).
		ETTranscript show: (grammar match: 'b'  rule: 'Ab').

		sub := grammar subgrammar: 'PEG2'.
		sub addRule: 'Ab' expression: ('c' asExp or: 'd' asExp).
		ETTranscript show: (sub match: 'b'  rule: 'Ab').
		ETTranscript show: (sub match: 'c'  rule: 'Ab').
	]

	testFinalParser [
		| parser parserRules content contentString match |
		ETTranscript show: '------------------------------------'; cr.
		ETTranscript show: '     Testing interpreter parser'; cr.
		ETTranscript show: '------------------------------------'; cr.
		content := NSFileManager defaultManager contentsAtPath: './ometa.pk'.
		contentString := NSString alloc initWithData: content encoding: 4.
		PKParser loadGrammarsFromString: contentString.
		parserRules := PKParser getGrammar: 'ActionizedEtoileOMeta'.
		ETTranscript show: parserRules; cr.
		parser := PKParser alloc initWithGrammar: 'ActionizedEtoileOMeta'.
		match := parser match: '\5F' rule: 'Char'.
		ETTranscript show: match; cr.
		
	]

	testSmalltalkParser [
		| parser parserRules content contentString match rule |
		ETTranscript setDebugMode: false.
		ETTranscript show: '------------------------------------'; cr.
		ETTranscript show: '     Testing smalltalk parser'; cr.
		ETTranscript show: '------------------------------------'; cr.
		content := NSFileManager defaultManager contentsAtPath: './smalltalk.pk'.
		contentString := NSString alloc initWithData: content encoding: 4.
		"Assume that ometa file have been loaded"
		"match := PKParser loadGrammarsFromString:  contentString."
		parser := PKParser alloc initWithGrammar: 'ActionizedEtoileOMeta'.
		match := parser match: contentString rule: 'OmetaList'.
		ETTranscript show: match; cr.

		PKParser loadGrammarsFromString: contentString.
		parser := PKParser alloc initWithGrammar: 'SmalltalkGrammar'.
		parser setDelegate: SmalltalkAstGenerator new. 
		match := parser match: 'NSObject subclass: Foo []' rule: 'SmalltalkClass'.
		ETTranscript show: match reduce; cr.
	]


	testPKNode [
		| parser abStar alphaNumeric parameterized multiAlternate multiSequence |
		ETTranscript show: '------------------------------------'; cr.
		ETTranscript show: '     Testing pk node parser'; cr.
		ETTranscript show: '------------------------------------'; cr.
		abStar := PKRepetitionExpression alloc
					 initWithExpression: 'ab' asExp
					 canBeEmpty: false; yourself.
		parser := abStar or: 'a' asExp.
		parser := ('c' asExp repeat) seq: parser seq: PKEmptyExpression uniqueInstance.
		alphaNumeric  := PKAlphanumericExpression new repeat.
		parameterized := (PKNumericExpression new bind: 'num') parameterTarget: 'num' selector: #isLessThan: arguments: {'7'}.
		multiSequence := PKNArySequenceExpression new.
		multiSequence addExpression: ('c' asExp repeat); addExpression: parser; addExpression: PKEmptyExpression uniqueInstance.
		multiAlternate := PKNAryAlternateExpression new.
		multiAlternate addExpression: ('c' asExp); addExpression: ('d' asExp); addExpression: ('e' asExp).
		multiAlternate := multiAlternate repeat.

		ETTranscript show: (parser parseInput: 'cab' asInputStream); cr.
		ETTranscript show: (multiSequence parseInput: 'cab' asInputStream); cr.
		ETTranscript show: (multiAlternate parseInput: 'cde' asInputStream); cr.
		ETTranscript show: alphaNumeric; cr.
		ETTranscript show: (alphaNumeric parseInput: 'Good34'  asInputStream); cr.
		ETTranscript show: (alphaNumeric parseInput: 'testing4'  asInputStream); cr.
		ETTranscript show: (parameterized parseInput: '6' asInputStream); cr.
		ETTranscript show: (parameterized parseInput: '8' asInputStream); cr.
	]

	testOmetaASTGenerator [
		| parser content contentString match |
		ETTranscript setDebugMode: false.
		ETTranscript show: '------------------------------------'; cr.
		ETTranscript show: '     Testing AST generator parser'; cr.
		ETTranscript show: '------------------------------------'; cr.
		parser := PKParser alloc initWithGrammar: 'ActionizedEtoileOMeta'.
		content := NSFileManager defaultManager contentsAtPath: './ometa.pk'.
		contentString := NSString alloc initWithData: content encoding: 4.

		parser setDelegate: PKParserASTGenerator new.
		match := parser match: contentString rule: 'OmetaList'.

		"ETTranscript show: 'Root action '; show: match matchAction; cr.
		ETTranscript show: 'Match: '; show: match; cr."
		ETTranscript show: match reduce; cr.
	]

	testCalc [
		| parser match content contentString calc |
		ETTranscript setDebugMode: false.
		ETTranscript show: '------------------------------------'; cr.
		ETTranscript show: '     Testing calc parser'; cr.
		ETTranscript show: '------------------------------------'; cr.
		parser := PKParser alloc initWithGrammar: 'ActionizedEtoileOMeta'.
		parser := PKParser alloc initWithGrammar: 'ActionizedEtoileOMeta'.
		parser setDelegate: PKParserRuleGenerator new.

		content := NSFileManager defaultManager contentsAtPath: './simple.pk'.
		contentString := NSString alloc initWithData: content encoding: 4.
		match := parser match: contentString rule: 'OmetaList'.
		ETTranscript show: match; cr.
		calc := PKParser new.
		calc setRules: match reduce.
		calc setDelegate: Calculator new.
		match := (calc match: '1+(2*3)' rule: 'Exp') .
		ETTranscript show: 'Evaluating. '; show: match reduce; cr.
	]
]

