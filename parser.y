%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "symbol_table.h"

extern FILE *yyin;
extern int yylineno;
extern int yycolumn;
extern char *yytext;

int yylex(void);

void yyerror(const char *msg) {
    fprintf(stderr, "Error at line %d: %s near '%s'\n", yylineno, msg, yytext);
    exit(1);
}


SymbolTable *current_symbol_table = NULL;

bool symbol_exists(char *name) {
    SymbolEntry *entry = current_symbol_table->entries;
    while (entry)
    {
        if (strcmp(entry->name, name) == 0)
        {
            return true;
        }
        entry = entry->next;
    }
    return false;
}

void enter_scope(char *scope_name) {
    current_symbol_table = create_scope(scope_name, current_symbol_table);
}

void exit_scope() {
    if (current_symbol_table) {
        current_symbol_table = current_symbol_table->parent;
    }
}

%}

%code requires {
    #include "symbol_table.h"
}

%union {
    int intVal;
    float floatVal;
    char* stringVal;
    char charVal;
}

%token <stringVal> IDENTIFIER STRING_LITERAL
%token <intVal> INTEGER_LITERAL NUMBER
%token FLOAT_LITERAL
%token CHAR_LITERAL
%token ABSTRACT ASSERT BOOLEAN BREAK BYTE CASE CATCH CHAR CLASS CONST
%token CONTINUE DEFAULT DO DOUBLE ELSE ENUM EXTENDS FINAL FINALLY FLOAT STRING
%token FOR IF IMPLEMENTS IMPORT INSTANCEOF INT INTERFACE LONG NATIVE NEW
%token PACKAGE PRIVATE PROTECTED PUBLIC RETURN SHORT STATIC STRICTFP SUPER
%token SWITCH SYNCHRONIZED THIS THROW THROWS TRANSIENT TRY VOID VOLATILE WHILE
%token TRUE FALSE NULL_LITERAL
%token PLUS MINUS MULT DIV MOD INCREMENT DECREMENT EQ NEQ GT LT GTE LTE
%token AND OR NOT BITWISE_AND BITWISE_OR BITWISE_XOR BITWISE_NOT LEFT_SHIFT
%token RIGHT_SHIFT UNSIGNED_RIGHT_SHIFT ASSIGN PLUS_ASSIGN MINUS_ASSIGN
%token MULT_ASSIGN DIV_ASSIGN MOD_ASSIGN AND_ASSIGN OR_ASSIGN XOR_ASSIGN
%token LEFT_SHIFT_ASSIGN RIGHT_SHIFT_ASSIGN UNSIGNED_RIGHT_SHIFT_ASSIGN
%token SEMICOLON COMMA DOT LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET COLON

%type <stringVal> type

%nonassoc THEN
%nonassoc ELSE

%left OR
%left AND
%left BITWISE_OR
%left BITWISE_XOR
%left BITWISE_AND
%left EQ NEQ
%left GT LT GTE LTE
%left LEFT_SHIFT RIGHT_SHIFT UNSIGNED_RIGHT_SHIFT
%left PLUS MINUS
%left MULT DIV MOD
%right NOT BITWISE_NOT
%right INCREMENT DECREMENT

%%
program:
    program class_declaration
    | class_declaration
    ;

class_declaration:
    access_modifier CLASS IDENTIFIER LBRACE
    {
        current_symbol_table = create_scope($3, current_symbol_table);
    }
    class_body RBRACE
    {
        exit_scope();
    }
    ;

access_modifier:
    PUBLIC
    | PRIVATE
    | PROTECTED
    | /* empty */
    ;

class_body:
    class_body member_declaration
    | member_declaration
    ;

member_declaration:
    variable_declaration
    | method_declaration
    ;

variable_declaration:
    access_modifier static_modifier type IDENTIFIER SEMICOLON
    {
        if (!symbol_exists($4)) {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, SYMBOL_SCOPE_LOCAL);
        } else {
            printf("Variable %s already declared.\n", $4);
        }
    }
    | static_modifier type IDENTIFIER ASSIGN expression SEMICOLON
    {
        if (!symbol_exists($3)) {
            insert_symbol(current_symbol_table, $3, $2, SYMBOL_CATEGORY_VARIABLE, SYMBOL_SCOPE_LOCAL);
        } else {
            printf("Variable %s already declared.\n", $3);
        }
    }
    ;

static_modifier:
    STATIC
    | /* empty */
    ;

type:
    INT { $$ = strdup("int"); }
    | FLOAT { $$ = strdup("float"); }
    | DOUBLE { $$ = strdup("double"); }
    | BOOLEAN { $$ = strdup("boolean"); }
    | CHAR { $$ = strdup("char"); }
    | STRING { $$ = strdup("String"); }
    | VOID { $$ = strdup("void"); }
    | type LBRACKET RBRACKET { 
        $$ = malloc(strlen($1) + 3);
        sprintf($$, "%s[]", $1);
        free($1);
    }
    ;

method_declaration:
    access_modifier static_modifier type IDENTIFIER LPAREN parameter_list RPAREN block
    ;

parameter_list:
    parameter_list COMMA parameter
    | parameter
    | /* empty */
    ;

parameter:
    type IDENTIFIER
    ;

block:
    LBRACE block_statements RBRACE
    ;

block_statements:
    block_statements statement
    | statement
    ;

statement:
    variable_declaration
    | assignment_statement
    | if_statement
    | while_statement
    | for_statement
    | return_statement
    | break_statement
    | continue_statement
    | method_call_statement
    | block
    ;

assignment_statement:
    IDENTIFIER ASSIGN expression SEMICOLON
    ;

method_call_statement:
    method_invocation SEMICOLON
    ;

method_invocation:
    object_chain DOT IDENTIFIER LPAREN argument_list RPAREN
    | IDENTIFIER LPAREN argument_list RPAREN
    ;

object_chain:
    IDENTIFIER
    | object_chain DOT IDENTIFIER
    ;

argument_list:
    argument_list COMMA expression
    | expression | method_invocation
    | /* empty */
    ;

if_statement:
    IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN statement ELSE statement
    ;

while_statement:
    WHILE LPAREN expression RPAREN statement
    ;

for_statement:
    FOR LPAREN assignment_statement expression SEMICOLON expression RPAREN statement
    ;

return_statement:
    RETURN expression SEMICOLON
    | RETURN SEMICOLON
    ;

break_statement:
    BREAK SEMICOLON
    ;

continue_statement:
    CONTINUE SEMICOLON
    ;

expression:
    expression PLUS expression
    | expression MINUS expression
    | expression MULT expression
    | expression DIV expression
    | expression MOD expression
    | expression GT expression
    | expression LT expression
    | expression GTE expression
    | expression LTE expression
    | expression EQ expression
    | expression NEQ expression
    | expression AND expression
    | expression OR expression
    | NOT expression
    | LPAREN expression RPAREN
    | IDENTIFIER
    | NUMBER
    | FLOAT_LITERAL
    | STRING_LITERAL
    | CHAR_LITERAL
    | TRUE | FALSE
    ;

%%

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <source_file.java>\n", argv[0]);
        return 1;
    }

    FILE *input_file = fopen(argv[1], "r");
    if (!input_file) {
        perror("Error opening file");
        return 1;
    }

    yyin = input_file;

    printf("Java Compiler - Parsing Started\n");
    if (yyparse() == 0) {
        printf("Parsing Completed Successfully\n");
    } else {
        printf("Parsing Failed\n");
    }

    fclose(input_file);
    return 0;
}
