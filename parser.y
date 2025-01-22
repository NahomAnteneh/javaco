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

typedef struct Error {
    int line;
    char *message;
    struct Error *next;
} Error;

Error *error_list = NULL;

void add_error(int line, const char *msg) {
    Error *new_error = (Error *)malloc(sizeof(Error));
    new_error->line = line;
    new_error->message = strdup(msg);
    new_error->next = error_list;
    error_list = new_error;
}

void print_errors() {
    Error *current = error_list;
    while (current) {
        fprintf(stderr, "Error at line %d: %s\n", current->line, current->message);
        Error *temp = current;
        current = current->next;
        free(temp->message);
        free(temp);
    }
}

void yyerror(const char *msg) {
    char error_message[256];
    snprintf(error_message, sizeof(error_message), "%s at '%s'", msg, yytext);
    add_error(yylineno, error_message);
}

SymbolTable *current_symbol_table = NULL;

bool symbol_exists(char *name) {
    SymbolEntry *entry = current_symbol_table->entries;
    while (entry) {
        if (strcmp(entry->name, name) == 0) return true;
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

void check_method_exists(char *method_name, char *object_name) {
    SymbolEntry *entry = lookup_symbol(current_symbol_table, object_name);
    if (!entry) {
        yyerror("Undeclared object");
    } else {
        SymbolTable *object_scope = entry->scope;
        SymbolEntry *method = lookup_symbol(object_scope, method_name);
        if (!method || method->category != SYMBOL_CATEGORY_METHOD) {
            yyerror("Undefined method");
        }
    }
}

void check_array_exists(char *array_name, char *object_name) {
    SymbolEntry *entry = lookup_symbol(current_symbol_table, object_name);
    if (!entry) {
        yyerror("Undeclared object");
    } else {
        SymbolTable *object_scope = entry->scope;
        SymbolEntry *array = lookup_symbol(object_scope, array_name);
        if (!array || array->category != SYMBOL_CATEGORY_VARIABLE) {
            yyerror("Undefined array");
        }
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
%token <intVal> INTEGER_LITERAL
%token FLOAT_LITERAL CHAR_LITERAL
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
%type <stringVal> method_invocation array_access object_chain

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
        enter_scope($3);
    }
    class_body RBRACE
    {
        exit_scope();
    }
    ;

class_body:
    class_body member_declaration
    | member_declaration
    ;

member_declaration:
    variable_declaration
    | method_declaration
    ;

access_modifier:
    PUBLIC
    | PRIVATE
    | PROTECTED
    | /* empty */
    ;

variable_declaration:
    access_modifier static_modifier type IDENTIFIER SEMICOLON
    {
        if (symbol_exists($4)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($3);
    }
    | access_modifier static_modifier type IDENTIFIER ASSIGN expression SEMICOLON
    {
        if (symbol_exists($4)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($3);
    }
    | type IDENTIFIER SEMICOLON
    {
        if (symbol_exists($2)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $2, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($2); free($1);
    }
    | type IDENTIFIER ASSIGN expression SEMICOLON
    {
        if (symbol_exists($2)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $2, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($2); free($1);
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
    access_modifier static_modifier type IDENTIFIER
    {
        enter_scope($4);
    }
    LPAREN parameter_list RPAREN LBRACE block_statements RBRACE
    {
        exit_scope();
    }
    ;

parameter_list:
    parameter_list COMMA parameter
    | parameter
    | /* empty */
    ;

parameter:
    type IDENTIFIER
    {
        if (symbol_exists($2)) {
            yyerror("Parameter redeclared");
        } else {
            insert_symbol(current_symbol_table, $2, $1, SYMBOL_CATEGORY_PARAMETER, current_symbol_table);
        }
        free($2); free($1);
    }
    ;

block:
    LBRACE { enter_scope("block"); } block_statements RBRACE { exit_scope(); }
    ;

block_statements:
    block_statements statement
    | statement
    ;

statement:
    variable_declaration
    | assignment_statement
    | array_declaration
    | switch_statement
    | if_statement
    | while_statement
    | for_statement
    | enhanced_for_statement
    | return_statement
    | break_statement
    | continue_statement
    | try_statement
    | method_call_statement
    | block
    ;

assignment_statement:
    IDENTIFIER ASSIGN expression SEMICOLON
    {
        if (!symbol_exists($1)) {
            yyerror("Undeclared variable");
        }
        free($1);
    }
    ;

method_call_statement:
    method_invocation SEMICOLON
    ;

method_invocation:
    IDENTIFIER LPAREN argument_list RPAREN
    {
        SymbolEntry *method = lookup_symbol(current_symbol_table, $1);
        if (!method || method->category != SYMBOL_CATEGORY_METHOD) {
            yyerror("Undefined method");
        }
        free($1);
        $$ = NULL;
    }
    | object_chain DOT IDENTIFIER LPAREN argument_list RPAREN
    {
        check_method_exists($3, $1);
        free($1); free($3);
        $$ = NULL;
    }
    ;
    
object_chain:
    IDENTIFIER
    | object_chain DOT IDENTIFIER
    ;

argument_list:
    argument_list COMMA expression
    | expression
    | method_invocation
    | /* empty */
    ;

if_statement:
    IF LPAREN expression RPAREN statement %prec THEN
    | IF LPAREN expression RPAREN statement ELSE statement
    ;

while_statement:
    WHILE LPAREN expression RPAREN statement
    {
        enter_scope("while");
    }
    statement
    {
        exit_scope();
    }
    ;

for_statement:
    FOR LPAREN for_init SEMICOLON expression_opt SEMICOLON for_update_opt RPAREN
    {
        enter_scope("for");
    }
    statement
    {
        exit_scope();
    }
    ;

for_init:
    local_variable_declaration
    | assignment_expression
    | /* empty */
    ;

local_variable_declaration:
    type IDENTIFIER ASSIGN expression
    {
        if (symbol_exists($2)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $2, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($2); free($1);
    }
    | type IDENTIFIER
    {
        if (symbol_exists($2)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $2, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($2); free($1);
    }
    ;

assignment_expression:
    IDENTIFIER ASSIGN expression
    {
        if (!symbol_exists($1)) {
            yyerror("Undeclared variable");
        }
        free($1);
    }
    ;

expression_opt:
    /* empty */
    | expression
    ;

for_update_opt:
    /* empty */
    | expression
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

array_declaration:
    type LBRACKET RBRACKET IDENTIFIER SEMICOLON
    {
        if (symbol_exists($4)) {
            yyerror("Array redeclared");
        } else {
            insert_symbol(current_symbol_table, $4, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($1);
    }
    | type LBRACKET RBRACKET IDENTIFIER ASSIGN array_initializer SEMICOLON
    {
        if (symbol_exists($4)) {
            yyerror("Array redeclared");
        } else {
            insert_symbol(current_symbol_table, $4, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($1);
    }
    ;

array_initializer:
    LBRACE array_elements RBRACE
    ;

array_elements:
    array_elements COMMA expression
    | expression
    ;

enhanced_for_statement:
    FOR LPAREN type IDENTIFIER COLON expression RPAREN
    {
        enter_scope("enhanced_for");
    }
    statement
    {
        if (symbol_exists($4)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($3);
        exit_scope();
    }
    ;

switch_statement:
    SWITCH LPAREN expression RPAREN LBRACE
    {
        enter_scope("switch");
    }
    switch_block RBRACE
    {
        exit_scope();
    }
    ;

switch_block:
    switch_block switch_label block_statements
    | switch_label block_statements
    ;

switch_label:
    CASE expression COLON
    | DEFAULT COLON
    ;

try_statement:
    TRY block catch_clauses finally_clause
    | TRY block catch_clauses
    | TRY block finally_clause
    ;

catch_clauses:
    catch_clauses catch_clause
    | catch_clause
    ;

catch_clause:
    CATCH LPAREN type IDENTIFIER RPAREN
    {
        enter_scope("catch");
    }
    block
    {
        if (symbol_exists($4)) {
            yyerror("Exception variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($3);
        exit_scope();
    }
    ;

finally_clause:
    FINALLY block
    ;

array_access:
    IDENTIFIER LBRACKET expression RBRACKET
    {
        SymbolEntry *entry = lookup_symbol(current_symbol_table, $1);
        if (!entry) {
            yyerror("Undeclared variable");
        } else if (entry->category != SYMBOL_CATEGORY_VARIABLE) {
            yyerror("Not an array variable");
        }
        free($1);
    }
    | object_chain DOT IDENTIFIER LBRACKET expression RBRACKET
    {
        check_array_exists($3, $1);
        free($1); free($3);
    }
    ;

object_creation:
    NEW IDENTIFIER LPAREN argument_list RPAREN
    {
        // Handle object creation
    }
    ;

primary:
    IDENTIFIER
    {
        SymbolEntry *entry = lookup_symbol(current_symbol_table, $1);
        if (!entry) {
            yyerror("Undeclared variable");
        } else if (entry->category == SYMBOL_CATEGORY_METHOD) {
            yyerror("Method called without parentheses");
        }
        free($1);
    }
    | INTEGER_LITERAL
    | FLOAT_LITERAL
    | STRING_LITERAL
    | CHAR_LITERAL
    | TRUE
    | FALSE
    | NULL_LITERAL
    | LPAREN expression RPAREN
    ;

unary_expression:
    primary
    | MINUS primary
    | NOT primary
    | BITWISE_NOT primary
    | INCREMENT primary
    | DECREMENT primary
    ;

binary_expression:
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
    | expression BITWISE_AND expression
    | expression BITWISE_OR expression
    | expression BITWISE_XOR expression
    | expression LEFT_SHIFT expression
    | expression RIGHT_SHIFT expression
    | expression UNSIGNED_RIGHT_SHIFT expression
    ;

expression:
    unary_expression
    | binary_expression
    | array_access
    | method_invocation
    | object_creation
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
    current_symbol_table = create_scope("global", NULL);

    printf("Java Compiler - Parsing Started\n");
    if (yyparse() == 0) {
        printf("Parsing Completed Successfully\n");
        print_symbol_table(current_symbol_table);
    } else {
        printf("Parsing Failed\n");
    }

    print_errors();
    
    destroy_scope(current_symbol_table);
    fclose(input_file);
    return 0;
}