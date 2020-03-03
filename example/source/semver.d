// see : http://semver.org
module semver;

import comp_d;
import std.stdio, std.ascii;
import std.array;
import std.conv: to;

alias grammar = defineGrammar!(`
    ValidSemver:
        VersionCore,
        VersionCore minus PreRelease,
        VersionCore plus Build,
        VersionCore minus PreRelease plus Build,
    ;
    
    VersionCore:
        Major dot Minor dot Patch,
    ;
    Major: NumericIdentifier;
    Minor: NumericIdentifier;
    Patch: NumericIdentifier;
    
    PreRelease: DotSeparatedPreReleaseIdentifiers;
    DotSeparatedPreReleaseIdentifiers:
        PreReleaseIdentifier,
        PreReleaseIdentifier dot DotSeparatedPreReleaseIdentifiers
    ;
    
    Build: DotSeparatedBuildIdentifiers;
    DotSeparatedBuildIdentifiers:
        BuildIdentifier,
        BuildIdentifier dot DotSeparatedBuildIdentifiers
    ;
    
    PreReleaseIdentifier:
        AlphaNumericIdentifier,
        NumericIdentifier
    ;
    
    BuildIdentifier:
        AlphaNumericIdentifier,
        Digits
    ;
    
    AlphaNumericIdentifier:
        NonDigit,
        NonDigit IdentifierCharacters,
        IdentifierCharacters NonDigit,
        IdentifierCharacters NonDigit IdentifierCharacters,
    ;
    NumericIdentifier:
        zero,
        positiveDigit,
        positiveDigit Digits,
    ;
    IdentifierCharacters:
        IdentifierCharacter,
        IdentifierCharacter IdentifierCharacters
    ;
    IdentifierCharacter:
        Digit,
        NonDigit
    ;
    NonDigit:
        letter,
        minus
    ;
    Digits:
        Digit,
        Digit Digits
    ;
    Digit:
        zero,
        positiveDigit
    ;
`);

/+
immutable
    zero = grammar.numberOf("zero"), positiveDigit = grammar.numberOf("positiveDigit"),
    letter = grammar.numberOf("minus"), minus = grammar.numberOf("minus"), plus = grammar.numberOf("plus");
+/
// This is equivalent to the following:
mixin("immutable" ~ grammar.TokenDeclarations ~ ";");
