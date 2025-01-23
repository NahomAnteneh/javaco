%{
#include "y.tab.h"
#include <stdlib.h>
#include <string.h>

int yycolumn = 1;

%}

%option noyywrap
%option yylineno

%%

\n                  { yylineno++; yycolumn = 1; }
[ \t]+              { yycolumn += yyleng; }
\r                  { yycolumn = 1; }

"abstract"          { return ABSTRACT; }
"assert"            { return ASSERT; }
"boolean"           { return BOOLEAN; }
"break"             { return BREAK; }
"byte"              { return BYTE; }
"case"              { return CASE; }
"catch"             { return CATCH; }
"char"              { return CHAR; }
"class"             { return CLASS; }
"const"             { return CONST; }
"continue"          { return CONTINUE; }
"default"           { return DEFAULT; }
"do"                { return DO; }
"double"            { return DOUBLE; }
"else"              { return ELSE; }
"enum"              { return ENUM; }
"extends"           { return EXTENDS; }
"final"             { return FINAL; }
"finally"           { return FINALLY; }
"float"             { return FLOAT; }
"for"               { return FOR; }
"if"                { return IF; }
"implements"        { return IMPLEMENTS; }
"import"            { return IMPORT; }
"instanceof"        { return INSTANCEOF; }
"int"               { return INT; }
"interface"         { return INTERFACE; }
"long"              { return LONG; }
"native"            { return NATIVE; }
"new"               { return NEW; }
"package"           { return PACKAGE; }
"private"           { return PRIVATE; }
"protected"         { return PROTECTED; }
"public"            { return PUBLIC; }
"return"            { return RETURN; }
"short"             { return SHORT; }
"static"            { return STATIC; }
"strictfp"          { return STRICTFP; }
"String"            { return STRING; }
"super"             { return SUPER; }
"switch"            { return SWITCH; }
"synchronized"      { return SYNCHRONIZED; }
"this"              { return THIS; }
"throw"             { return THROW; }
"throws"            { return THROWS; }
"transient"         { return TRANSIENT; }
"try"               { return TRY; }
"void"              { return VOID; }
"volatile"          { return VOLATILE; }
"while"             { return WHILE; }

"true"              { return TRUE; }
"false"             { return FALSE; }

"null"              { return NULL_LITERAL; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.stringVal = strdup(yytext); return IDENTIFIER; }
[0-9]+                  { yylval.intVal = atoi(yytext); return INTEGER_LITERAL; }
[0-9]+\.[0-9]*          { yylval.floatVal = atof(yytext); return FLOAT_LITERAL; }
'([^'\\]|\\.)'          { yylval.charVal = yytext[1]; return CHAR_LITERAL; }
\"([^"\\]|\\.)*\"       { yylval.stringVal = strdup(yytext); return STRING_LITERAL; }

"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MULT; }
"/"                 { return DIV; }
"%"                 { return MOD; }
"++"                { return INCREMENT; }
"--"                { return DECREMENT; }
"=="                { return EQ; }
"!="                { return NEQ; }
">"                 { return GT; }
"<"                 { return LT; }
">="                { return GTE; }
"<="                { return LTE; }
"&&"                { return AND; }
"||"                { return OR; }
"!"                 { return NOT; }
"&"                 { return BITWISE_AND; }
"|"                 { return BITWISE_OR; }
"^"                 { return BITWISE_XOR; }
"~"                 { return BITWISE_NOT; }
"<<"                { return LEFT_SHIFT; }
">>"                { return RIGHT_SHIFT; }
">>>"               { return UNSIGNED_RIGHT_SHIFT; }
"="                 { return ASSIGN; }
"+="                { return PLUS_ASSIGN; }
"-="                { return MINUS_ASSIGN; }
"*="                { return MULT_ASSIGN; }
"/="                { return DIV_ASSIGN; }
"%="                { return MOD_ASSIGN; }
"&="                { return AND_ASSIGN; }
"|="                { return OR_ASSIGN; }
"^="                { return XOR_ASSIGN; }
"<<="               { return LEFT_SHIFT_ASSIGN; }
">>="               { return RIGHT_SHIFT_ASSIGN; }
">>>="              { return UNSIGNED_RIGHT_SHIFT_ASSIGN; }

";"                 { return SEMICOLON; }
","                 { return COMMA; }
"."                 { return DOT; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
"{"                 { return LBRACE; }
"}"                 { return RBRACE; }
"["                 { return LBRACKET; }
"]"                 { return RBRACKET; }
":"                 { return COLON; }

"//".*              { /* Ignore single-line comments */ }
"/*"([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+"/"  { /* Ignore multi-line comments */ }

.                   { yyerror("Invalid character"); }

%%