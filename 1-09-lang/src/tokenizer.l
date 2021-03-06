/* Source of the syntax: https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1256.pdf, page 61, part 6.4, C99. */

/* TODO: if comments are stripped by preprocessor, move comments to preprocessor. */

/*
Token syntax in the standard is not a recursive descend grammar. That syntax could be converted to an NFA.
For every scanned character we could be not in a single vertice, but rather in a set. For example, we
could be in a keyword DFA and an identifier DFA combined into a single NFA. If it's either keyword or
identifier, it's accepted by the NFA. But if it's both, it's keyword. Then we could transform NFA of
the whole token syntax into a DFA as NFAs are mathematically equivalent to DFAs: any NFA has a
counterpart DFA that accepts the same set of strings as the initial NFA, and any DFA is already an NFA.
So DFAs and NFAs can scan the same set of strings. If token is a suffix of a keyword, it's an identifier,
if it's longer, it's identifier as well (the keyword DFA just won't accept it, as it's not in keywords
set), but whenever it's accepted by both, bison selects the rule wouldn't accept any continuation of
that word, yes? (TODO: check.) It's a common situation for computer programming languages to have
reserved words, so bison is designed to handle this, I suppose. There are many more non-determenistic
rules in the syntax, but if you make a NFA, then convert it to a DFA, you will parse it. After the token
is accepted, you can check what rules where accepting it. And select which rule is right.
Recursive descend grammar is very similar to regular expressions. Regular expressions in programming
differ from regular expressions in maths in that we are allowed to extract substrings after matching,
which is not a huge deal, right? And mathematically any regular expression is convertible to a DFA and
any DFA is convertible to a regular expression (TODO: not always the same one, or always the same one?
Then I should say and convertible back to the exactly same regular expression). So our recursive descend
is, I think, the same regular expressions with the idea that we can preprocess rules to insert different
equations into the main equation. They are indeed convertible to DFAs then, and while simulating a DFA,
we can extract substrings in our program, so we would do the same that recursive descend does. Recursive
descend syntax has fixed set of rules, so we don't have to emulate an arbitary DFA with an adjacency
matrix, but we can create code for those particular rules. Recursive descend knows a little bit in advance,
it knows if it's a loop or not and when the loop should end, but with a DFA, we can detect cycles with
depth-first search, so we can restore that information.
By making an NFA, we can make our own parser without doing exactly the same bison does, our own way if
it's needed. Of course, if bison does this, we can do as well. And if we would do what bison does (although,
without copying it's code, implementing ourselves), we could make the first version, maybe we would improve
it to be more specialized to our case.
But bison allows to just specify grammar from the standard directly, no additional work. So using bison makes
the tokenizer more obvious to see. And bison is more widely used. More people know about it and there's
information about it, of course. Bison is quickier to do and easier to modify then as well.
*/

/* yywrap function called at the end of file, so the program could open the next file and continue scanning. */
/* We don't support this for now, but we will have to support compiling multiple files, but into a single exe, right? Not to a single .o file. I think. I should check what GCC implementation does. */
/* For debugging you could use "%option noyywrap debug verbose" as well here. */
%option noyywrap

/* To silence warnings -Werror=unused-function for input and yyunput */
%option noinput nounput

/* Getting rid of -Werror=implicit-function for fileno */
/* More info at https://stackoverflow.com/a/46223160 */
%option never-interactive

/* Track line numbers as well.*/
%option yylineno 

%{
	#include "token.h"
%}

/*
token:
	keyword
	identifier
	constant
	string-literal
	punctuator
;
*/

blank [ \t\r]

/*
keyword: one of
	auto  break case char const continue default do double else enum extern
	float for goto if inline int long register restrict return short
	signed sizeof static struct switch typedef union unsigned
	void volatile while _Bool _Complex _Imaginary
*/
/* OLD. keyword (auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|inline|int|long|register|restrict|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|_Bool|_Complex|_Imaginary) */
keyword_auto       auto
keyword_break      break
keyword_case       case
keyword_char       char
keyword_const      const
keyword_continue   continue
keyword_default    default
keyword_do         do
keyword_double     double
keyword_else       else
keyword_enum       enum
keyword_extern     extern
keyword_float      float
keyword_for        for
keyword_goto       goto
keyword_if         if
keyword_inline     inline
keyword_int        int
keyword_long       long
keyword_register   register
keyword_restrict   restrict
keyword_return     return
keyword_short      short
keyword_signed     signed
keyword_sizeof     sizeof
keyword_static     static
keyword_struct     struct
keyword_switch     switch
keyword_typedef    typedef
keyword_union      union
keyword_unsigned   unsigned
keyword_void       void
keyword_volatile   volatile
keyword_while      while
keyword__Bool      _Bool
keyword__Complex   _Complex
keyword__Imaginary _Imaginary

/*

identifier:
	identifier-nondigit
	identifier identifier-nondigit
	identifier digit

identifier-nondigit:
	nondigit
	universal-character-name
	other implementation-defined characters (no in our case)

nondigit: one of
	_ a b c d e f g h i j k l m
	  n o p q r s t u v w x y z
	  A B C D E F G H I J K L M
	  N O P Q R S T U V W X Y Z
digit: one of
	0 1 2 3 4 5 6 7 8 9
*/
nondigit   [_a-zA-Z]
digit      [0-9]
identifier {nondigit}({nondigit}|{digit})*

/*
constant:
	integer-constant
	floating-constant
	enumeration-constant
	character-constant
*/
/* Enum constant is essentially an identifier. We won't have them as a separate entity, otherwise we won't be able to distinguish them from identifiers at tokenizing stage. */
/* Enum members will come as identifiers to the parser. */

/*
integer-constant:
	decimal-constant integer-suffix_opt
	octal-constant integer-suffix_opt
	hexadecimal-constant integer-suffix_opt
*/
/*
integer-suffix:
	unsigned-suffix long-suffix_opt
	unsigned-suffix long-long-suffix
	long-suffix unsigned-suffix_opt
	long-long-suffix unsigned-suffix_opt

unsigned-suffix: one of
	u U
long-suffix: one of
	l L
long-long-suffix: one of
	ll LL
*/
integer_suffix (({unsigned_suffix}{long_suffix}?)|({unsigned_suffix}{long_long_suffix})|({long_suffix}{unsigned_suffix}?)|({long_long_suffix}{unsigned_suffix}?))
/*
nonzero-digit: one of
	1 2 3 4 5 6 7 8 9
*/
nonzero_digit [1-9]
/*
decimal-constant:
	nonzero-digit
	decimal-constant digit
*/
decimal_constant {nonzero_digit}{digit}*
/*
octal-digit: one of
	0 1 2 3 4 5 6 7
*/
octal_digit [0-7]
/*
octal-constant:
	0
	octal-constant octal-digit
*/
octal_constant 0{octal_digit}*
/*
hexadecimal-digit: one of
	0 1 2 3 4 5 6 7 8 9
	a b c d e f
	A B C D E F
*/
hexadecimal_digit [0-9a-fA-F]
/*
hexadecimal-prefix: one of
	0x 0X
*/
hexadecimal_prefix 0[xX]
/*
hexadecimal-constant:
	hexadecimal-prefix hexadecimal-digit
	hexadecimal-constant hexadecimal-digit
*/
hexadecimal_constant {hexadecimal_prefix}{hexadecimal_digit}{hexadecimal_digit}*

/*
floating-constant:
	decimal-floating-constant
	hexadecimal-floating-constant
*/
/*
floating-suffix: one of
	f l F L
*/
floating_suffix [flFL]
/*
fractional-constant:
	digit-sequence_opt . digit-sequence
	digit-sequence .
*/
fractional_constant ({digit_sequence}?\.{digit_sequence})|({digit_sequence}\.)
/*
sign: one of
	+ -
*/
sign [+-]
/*
digit-sequence:
	digit
	digit-sequence digit
*/
digit_sequence {digit}{digit}*
/*
exponent-part:
	e sign_opt digit-sequence
	E sign_opt digit-sequence
*/
exponent_part [eE]{sign}?{digit_sequence}
/*
decimal-floating-constant:
	fractional-constant exponent-part_opt floating-suffix_opt
	digit-sequence exponent-part floating-suffix_opt
*/
decimal_floating_constant (({fractional_constant}{exponent_part}?{floating_suffix}?)|({digit_sequence}{exponent_part}{floating_suffix}?))
/*
hexadecimal-fractional-constant:
	hexadecimal-digit-sequence_opt .
	hexadecimal-digit-sequence
	hexadecimal-digit-sequence .
*/
hexadecimal_fractional_constant (({hexadecimal_digit_sequence}?\.)|{hexadecimal_digit_sequence}|{hexadecimal_digit_sequence}\.)
/*
binary-exponent-part:
	p sign_opt digit-sequence
	P sign_opt digit-sequence
*/
binary_exponent_part [pP]{sign}?{digit_sequence}
/*
hexadecimal-digit-sequence:
	hexadecimal-digit
	hexadecimal-digit-sequence hexadecimal-digit
*/
hexadecimal_digit_sequence {hexadecimal_digit}{hexadecimal_digit}*
/*
hexadecimal-floating-constant:
	hexadecimal-prefix hexadecimal-fractional-constant binary-exponent-part floating-suffix_opt
	hexadecimal-prefix hexadecimal-digit-sequence binary-exponent-part floating-suffix_opt
*/
hexadecimal_floating_constant (({hexadecimal_prefix}{hexadecimal_fractional_constant}{binary_exponent_part}{floating_suffix}?)|({hexadecimal_prefix}{hexadecimal_digit_sequence}{binary_exponent_part}{floating_suffix}?))

/*
simple-escape-sequence: one of
	\' \" \? \\ \a \b \f \n \r \t \v
*/
simple_escape_sequence (\\\'|\\\"|\\\?|\\\\|\\a|\\b|\\f|\\n|\\r|\\t|\\v)
/*
octal-escape-sequence:
	\ octal-digit
	\ octal-digit octal-digit
	\ octal-digit octal-digit octal-digit
*/
octal_escape_sequence (\\{octal_digit}|\\{octal_digit}{octal_digit}|\\{octal_digit}{octal_digit}{octal_digit})
/*
hexadecimal-escape-sequence:
	\x hexadecimal-digit
	hexadecimal-escape-sequence hexadecimal-digit
*/
hexadecimal_escape_sequence (\\x{hexadecimal_digit})(\\x{hexadecimal_digit})*
/*
escape-sequence:
	simple-escape-sequence
	octal-escape-sequence
	hexadecimal-escape-sequence
	universal-character-name
*/
/*
Paragraph 6.4.2.1, semantics:
3. Each universal character name in an identifier shall designate a character whose encoding
     in ISO/IEC 10646 falls into one of the ranges specified in annex D.60) The initial
     character shall not be a universal character name designating a digit. An implementation
     may allow multibyte characters that are not part of the basic source character set to
     appear in identifiers; which characters and their correspondence to universal character
     names is implementation-defined.
*/
/* We don't support universal character names for now. */
escape_sequence ({simple_escape_sequence}|{octal_escape_sequence}|{hexadecimal_escape_sequence})
/*
c-char:
	any member of the source character set except the single-quote ', backslash \, or new-line character
	escape-sequence
*/
c_char ([^'\\\n]|{escape_sequence})
/*
c-char-sequence:
	c-char
	c-char-sequence c-char
*/
c_char_sequence {c_char}{c_char}*
/*
character-constant:
	' c-char-sequence '
	L' c-char-sequence '
*/
character_constant (\'{c_char_sequence}\'|L\'{c_char_sequence}\')

/*
s-char:
	any member of the source character set except the double-quote ", backslash \, or new-line character
	escape-sequence
*/
s_char ([^"\\\n]|{escape_sequence})
/*
s-char-sequence:
	s-char
	s-char-sequence s-char
*/
s_char_sequence {s_char}{s_char}*
/*
string-literal:
	" s-char-sequence_opt "
	L" s-char-sequence_opt "
*/
string_literal (\"{s_char_sequence}?\"|L\"{s_char_sequence}\")

/*
punctuator: one of
	[ ] ( ) { } . ->
	++ -- & * + - ~ !
	/ % << >> < > <= >= == != ^ | && ||
	? : ; ...
	= *= /= %= += -= <<= >>= &= ^= |=
	, # ##
	<: :> <% %> %: %:%:
*/
/* Seems to select the longest case here too. Checked in practice. Great! */
/* punctuator ([\[\](){}.&*+\-~!/%<>^|?:;=,#]|->|"++"|"--"|<<|>>|<=|>=|==|!=|&&|"||"|"..."|"*="|"/="|%=|"+="|-=|<<=|>>=|&=|^=|\|=|##|<:|:>|<%|%>|%:|%:%:) */
punctuator_left_square_bracket         \[
punctuator_right_square_bracket        \]
punctuator_left_parenthesis            \(
punctuator_right_parenthesis           \)
punctuator_left_brace                  \{
punctuator_right_brace                 \}
punctuator_dot                         \.
punctuator_arrow                       ->
punctuator_increment                   \+\+
punctuator_decrement                   --
punctuator_and                         &
punctuator_star                        \*
punctuator_plus                        \+
punctuator_minus                       -
punctuator_tilde                       ~
punctuator_exclamation_mark            !
punctuator_slash                       \/
punctuator_percent                     %
punctuator_shift_left                  <<
punctuator_shift_right                 >>
punctuator_less                        <
punctuator_greater                     >
punctuator_less_equal                  <=
punctuator_greater_equal               >=
punctuator_equal_equal                 ==
punctuator_not_equal                   !=
punctuator_circumflex                  \^
punctuator_or                          \|
punctuator_and_and                     &&
punctuator_or_or                       \|\|
punctuator_question_mark               \?
punctuator_colon                       :
punctuator_semicolon                   ;
punctuator_ellipsis                    \.\.\.
punctuator_equal                       =
punctuator_star_equal                  \*=
punctuator_slash_equal                 \/=
punctuator_percent_equal               %=
punctuator_plus_equal                  \+=
punctuator_minus_equal                 -=
punctuator_shift_left_equal            <<=
punctuator_shift_right_equal           >>=
punctuator_and_equal                   &=
punctuator_circumflex_equal            ^=
punctuator_or_equal                    \|=
punctuator_comma                       \,
punctuator_hash                        \#
punctuator_hash_hash                   \#\#
punctuator_less_colon                  <:
punctuator_colon_greater               >:
punctuator_less_percent                <%
punctuator_percent_greater             %>
punctuator_percent_colon               %:
punctuator_percent_colon_percent_colon %:%:


/*
https://stackoverflow.com/a/25396611
	"This one is easy because in lex/flex, `.` won't match a newline. So the
	following will match from `//` to the end of the line, and then do nothing."
	"//".*
*/

/* https://stackoverflow.com/a/28766594 Flex takes the longest match, so I think, we are good with identifiers! Of course, flex should be well-developed tool for various cases of parsing and tokenizing.*/
/* To do that manually with a recursive descend, I think, we would have to make a tree of reading (DFA) and then make a new grammar, recursive descend grammar. The flex, however, uses regular expressions, which are, without backtracking, mathematically equivalent to DFAs.*/
/*
Paragraph 6.4.2.1, semantics:
4. When preprocessing tokens are converted to tokens during translation phase 7, if a
     preprocessing token could be converted to either a keyword or an identifier, it
     is converted to a keyword.
*/

/* {keyword}                        { return token_process_keyword(yytext); } */

%%
{blank}
\n

"//".*                           { /* ignored */ }
"/*"([^*]|[*][^/])*"*/"          { /* ignored */ }

{keyword_auto}                           { return token_process_keyword_auto();       }
{keyword_break}                          { return token_process_keyword_break();      }
{keyword_case}                           { return token_process_keyword_case();       }
{keyword_char}                           { return token_process_keyword_char();       }
{keyword_const}                          { return token_process_keyword_const();      }
{keyword_continue}                       { return token_process_keyword_continue();   }
{keyword_default}                        { return token_process_keyword_default();    }
{keyword_do}                             { return token_process_keyword_do();         }
{keyword_double}                         { return token_process_keyword_double();     }
{keyword_else}                           { return token_process_keyword_else();       }
{keyword_enum}                           { return token_process_keyword_enum();       }
{keyword_extern}                         { return token_process_keyword_extern();     }
{keyword_float}                          { return token_process_keyword_float();      }
{keyword_for}                            { return token_process_keyword_for();        }
{keyword_goto}                           { return token_process_keyword_goto();       }
{keyword_if}                             { return token_process_keyword_if();         }
{keyword_inline}                         { return token_process_keyword_inline();     }
{keyword_int}                            { return token_process_keyword_int();        }
{keyword_long}                           { return token_process_keyword_long();       }
{keyword_register}                       { return token_process_keyword_register();   }
{keyword_restrict}                       { return token_process_keyword_restrict();   }
{keyword_return}                         { return token_process_keyword_return();     }
{keyword_short}                          { return token_process_keyword_short();      }
{keyword_signed}                         { return token_process_keyword_signed();     }
{keyword_sizeof}                         { return token_process_keyword_sizeof();     }
{keyword_static}                         { return token_process_keyword_static();     }
{keyword_struct}                         { return token_process_keyword_struct();     }
{keyword_switch}                         { return token_process_keyword_switch();     }
{keyword_typedef}                        { return token_process_keyword_typedef();    }
{keyword_union}                          { return token_process_keyword_union();      }
{keyword_unsigned}                       { return token_process_keyword_unsigned();   }
{keyword_void}                           { return token_process_keyword_void();       }
{keyword_volatile}                       { return token_process_keyword_volatile();   }
{keyword_while}                          { return token_process_keyword_while();      }
{keyword__Bool}                          { return token_process_keyword__Bool();      }
{keyword__Complex}                       { return token_process_keyword__Complex();   }
{keyword__Imaginary}                     { return token_process_keyword__Imaginary(); }

{identifier}                             { return token_process_identifier(yytext); }

{decimal_constant}                       { return token_process_integer_constant(TOKEN_INTEGER_CONSTANT_DECIMAL_BASE, yytext); }
{octal_constant}                         { return token_process_integer_constant(TOKEN_INTEGER_CONSTANT_OCTAL_BASE, yytext); }
{hexadecimal_constant}                   { return token_process_integer_constant(TOKEN_INTEGER_CONSTANT_HEXADECIMAL_BASE, yytext); }

{decimal_floating_constant}              { return token_process_floating_constant(TOKEN_FLOATING_CONSTANT_DECIMAL_BASE, yytext); }
{hexadecimal_floating_constant}          { return token_process_floating_constant(TOKEN_FLOATING_CONSTANT_HEXADECIMAL_BASE, yytext); }

{character_constant}                     { return token_process_character_constant(yytext);               }
{string_literal}                         { return token_process_string_literal(yytext);                   }

{punctuator_left_square_bracket}         { return token_process_punctuator_left_square_bracket();         }
{punctuator_right_square_bracket}        { return token_process_punctuator_right_square_bracket();        }
{punctuator_left_parenthesis}            { return token_process_punctuator_left_parenthesis();            }
{punctuator_right_parenthesis}           { return token_process_punctuator_right_parenthesis();           }
{punctuator_left_brace}                  { return token_process_punctuator_left_brace();                  }
{punctuator_right_brace}                 { return token_process_punctuator_right_brace();                 }
{punctuator_dot}                         { return token_process_punctuator_dot();                         }
{punctuator_arrow}                       { return token_process_punctuator_arrow();                       }
{punctuator_increment}                   { return token_process_punctuator_increment();                   }
{punctuator_decrement}                   { return token_process_punctuator_decrement();                   }
{punctuator_and}                         { return token_process_punctuator_and();                         }
{punctuator_star}                        { return token_process_punctuator_star();                        }
{punctuator_plus}                        { return token_process_punctuator_plus();                        }
{punctuator_minus}                       { return token_process_punctuator_minus();                       }
{punctuator_tilde}                       { return token_process_punctuator_tilde();                       }
{punctuator_exclamation_mark}            { return token_process_punctuator_exclamation_mark();            }
{punctuator_slash}                       { return token_process_punctuator_slash();                       }
{punctuator_percent}                     { return token_process_punctuator_percent();                     }
{punctuator_shift_left}                  { return token_process_punctuator_shift_left();                  }
{punctuator_shift_right}                 { return token_process_punctuator_shift_right();                 }
{punctuator_less}                        { return token_process_punctuator_less();                        }
{punctuator_greater}                     { return token_process_punctuator_greater();                     }
{punctuator_less_equal}                  { return token_process_punctuator_less_equal();                  }
{punctuator_greater_equal}               { return token_process_punctuator_greater_equal();               }
{punctuator_equal_equal}                 { return token_process_punctuator_equal_equal();                 }
{punctuator_not_equal}                   { return token_process_punctuator_not_equal();                   }
{punctuator_circumflex}                  { return token_process_punctuator_circumflex();                  }
{punctuator_or}                          { return token_process_punctuator_or();                          }
{punctuator_and_and}                     { return token_process_punctuator_and_and();                     }
{punctuator_or_or}                       { return token_process_punctuator_or_or();                       }
{punctuator_question_mark}               { return token_process_punctuator_question_mark();               }
{punctuator_colon}                       { return token_process_punctuator_colon();                       }
{punctuator_semicolon}                   { return token_process_punctuator_semicolon();                   }
{punctuator_ellipsis}                    { return token_process_punctuator_ellipsis();                    }
{punctuator_equal}                       { return token_process_punctuator_equal();                       }
{punctuator_star_equal}                  { return token_process_punctuator_star_equal();                  }
{punctuator_slash_equal}                 { return token_process_punctuator_slash_equal();                 }
{punctuator_percent_equal}               { return token_process_punctuator_percent_equal();               }
{punctuator_plus_equal}                  { return token_process_punctuator_plus_equal();                  }
{punctuator_minus_equal}                 { return token_process_punctuator_minus_equal();                 }
{punctuator_shift_left_equal}            { return token_process_punctuator_shift_left_equal();            }
{punctuator_shift_right_equal}           { return token_process_punctuator_shift_right_equal();           }
{punctuator_and_equal}                   { return token_process_punctuator_and_equal();                   }
{punctuator_circumflex_equal}            { return token_process_punctuator_circumflex_equal();            }
{punctuator_or_equal}                    { return token_process_punctuator_or_equal();                    }
{punctuator_comma}                       { return token_process_punctuator_comma();                       }
{punctuator_hash}                        { return token_process_punctuator_hash();                        }
{punctuator_hash_hash}                   { return token_process_punctuator_hash_hash();                   }
{punctuator_less_colon}                  { return token_process_punctuator_less_colon();                  }
{punctuator_colon_greater}               { return token_process_punctuator_colon_greater();               }
{punctuator_less_percent}                { return token_process_punctuator_less_percent();                }
{punctuator_percent_greater}             { return token_process_punctuator_percent_greater();             }
{punctuator_percent_colon}               { return token_process_punctuator_percent_colon();               }
{punctuator_percent_colon_percent_colon} { return token_process_punctuator_percent_colon_percent_colon(); }


.                                        { return token_process_invalid_token(yytext); }
%%

/* {punctuator}                     { return token_process_punctuator(yytext); } */

// #define MAX_INTEGER_CONSTANT_LEN 127
