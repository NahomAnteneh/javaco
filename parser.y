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
    new_error->message = strdup(msg);  // Ensure msg is formatted before passing
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

void var_error(const char *type, const char *name) {
    char error_msg[256];
    snprintf(error_msg, sizeof(error_msg), "Undeclared %s '%s'", type, name);
    add_error(yylineno, error_msg);
}

void chain_error(const char *part) {
    char error_msg[256];
    snprintf(error_msg, sizeof(error_msg), "Undeclared object '%s' in chain", part);
    add_error(yylineno, error_msg);
}

SymbolTable *current_symbol_table = NULL;

bool symbol_exists(char *name) {
    SymbolTable *current = current_symbol_table;
    while (current) {
        SymbolEntry *entry = current->entries;
        while (entry) {
            if (strcmp(entry->name, name) == 0) return true;
            entry = entry->next;
        }
        current = current->parent;
    }
    return false;
}

bool symbol_exists_in_current_scope(char *name) {
    SymbolTable *current = current_symbol_table;
    SymbolEntry *entry = current->entries;
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

void check_constructor_name(const char *name, int line) {
    if (current_symbol_table && strcmp(name, current_symbol_table->name) != 0) {
        fprintf(stderr, "Error at line %d: Constructor name '%s' must match class name '%s'\n",
                line, name, current_symbol_table->name);
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
    char* typeVal; // Added for type checking
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

%type <typeVal> method_invocation array_access object_chain object_creation
%type <stringVal> type constructor_declaration
%type <typeVal> expression unary_expression binary_expression primary

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
    | constructor_declaration
    ;

constructor_declaration:
    access_modifier IDENTIFIER LPAREN parameter_list RPAREN 
    {
        check_constructor_name($2, yylineno);
        insert_symbol(current_symbol_table, $2, "constructor", 
                     SYMBOL_CATEGORY_METHOD, current_symbol_table);
        enter_scope($2);
        free($2);
    }
    LBRACE block_statements RBRACE 
    {
        exit_scope();
    }
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
        if (symbol_exists_in_current_scope($4)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Variable redeclared: '%s'", $4);
            add_error(yylineno, error_msg);
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($3);
    }
    | access_modifier static_modifier type IDENTIFIER ASSIGN expression SEMICOLON
    {
        if (symbol_exists_in_current_scope($4)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Variable redeclared: '%s'", $4);
            add_error(yylineno, error_msg);
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($3);
    }
    | type IDENTIFIER SEMICOLON
    {
        if (symbol_exists_in_current_scope($2)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Variable redeclared: '%s'", $2);
            add_error(yylineno, error_msg);
        } else {
            insert_symbol(current_symbol_table, $2, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($2); free($1);
    }
    | type IDENTIFIER ASSIGN expression SEMICOLON
    {
        if (symbol_exists_in_current_scope($2)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Variable redeclared: '%s'", $2);
            add_error(yylineno, error_msg);
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
        if (symbol_exists_in_current_scope($4)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Method redeclared: '%s'", $4);
            add_error(yylineno, error_msg);
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_METHOD, current_symbol_table);
            enter_scope($4);
        }
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
        if (symbol_exists_in_current_scope($2)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Parameter redeclared: '%s'", $2);
            add_error(yylineno, error_msg);
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
    | increment_statement
    | decrement_statement
    ;

increment_statement:
    increment_expression SEMICOLON
    ;

increment_expression:
    IDENTIFIER INCREMENT
    {
        if (!symbol_exists($1)) {
            yyerror("Undeclared variable");
        }
        free($1);
    }
    ;

decrement_statement:
    decrement_expression SEMICOLON
    ;

decrement_expression:
    IDENTIFIER DECREMENT
    {
        if (!symbol_exists($1)) {
            yyerror("Undeclared variable");
        }
        free($1);
    }
    ;

assignment_statement:
    IDENTIFIER ASSIGN expression SEMICOLON
    {
        if (!symbol_exists($1)) {
            yyerror("Undeclared variable");
        } else {
            SymbolEntry *var_entry = lookup_symbol(current_symbol_table, $1);
            if (var_entry) {
                if (strcmp(var_entry->type, $3) != 0) {
                    char error_msg[256];
                    snprintf(error_msg, sizeof(error_msg), "Type mismatch: cannot assign %s to %s", $3, var_entry->type);
                    add_error(yylineno, error_msg);
                }
                free($3);
            }
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
        $$ = method ? strdup(method->type) : strdup("unknown");
        free($1);
    }
    | object_chain DOT IDENTIFIER LPAREN argument_list RPAREN
    {
        char *chain_copy = strdup($1);
        char *current_part = strtok(chain_copy, ".");
        SymbolTable *current_scope = current_symbol_table;
        SymbolEntry *entry = NULL;
        char *final_type = "unknown";

        while (current_part) {
            entry = lookup_symbol(current_scope, current_part);
            if (!entry) {
                chain_error(current_part);
                break;
            }
            current_scope = entry->scope;
            current_part = strtok(NULL, ".");
        }

        if (entry) {
            SymbolEntry *method = lookup_symbol(current_scope, $3);
            if (method && method->category == SYMBOL_CATEGORY_METHOD) {
                final_type = method->type;
            } else {
                var_error("method", $3);
            }
        }

        $$ = strdup(final_type);
        free(chain_copy);
        free($1);
        free($3);
    }
    ;

    
object_chain:
    IDENTIFIER { 
        $$ = strdup($1); 
        free($1); 
    }
    | object_chain DOT IDENTIFIER
    {
        $$ = malloc(strlen($1) + strlen($3) + 2);
        sprintf($$, "%s.%s", $1, $3);
        free($1);
        free($3);
    }
    ;

argument_list:
    argument_list COMMA expression
    | expression
    | method_invocation
    | /* empty */
    ;

if_statement:
    IF LPAREN expression RPAREN 
    { enter_scope("if"); } 
    LBRACE block_statements RBRACE
    { exit_scope(); } 
    else_clause
    ;

else_clause:
    /* empty */
    | ELSE 
    { enter_scope("else"); } 
    LBRACE block_statements RBRACE
    { exit_scope(); }
    ;

while_statement:
    WHILE LPAREN expression RPAREN 
    { enter_scope("while"); } 
    LBRACE block_statements RBRACE
    { exit_scope(); }
    ;

for_statement:
    FOR LPAREN for_init SEMICOLON expression_opt SEMICOLON for_update_opt RPAREN
    { enter_scope("for"); }
    statement
    { exit_scope(); }
    ;

for_init:
    local_variable_declaration
    | assignment_expression
    | /* empty */
    ;

local_variable_declaration:
    type IDENTIFIER ASSIGN expression
    {
        if (symbol_exists_in_current_scope($2)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Variable redeclared: '%s'", $2);
            add_error(yylineno, error_msg);
        } else {
            insert_symbol(current_symbol_table, $2, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($2); free($1);
    }
    | type IDENTIFIER
    {
        if (symbol_exists_in_current_scope($2)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Variable redeclared: '%s'", $2);
            add_error(yylineno, error_msg);
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
        if (symbol_exists_in_current_scope($4)) {
            char error_msg[256];
            snprintf(error_msg, sizeof(error_msg), "Array redeclared: '%s'", $4);
            add_error(yylineno, error_msg);
        } else {
            insert_symbol(current_symbol_table, $4, $1, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($1);
    }
    | type LBRACKET RBRACKET IDENTIFIER ASSIGN array_initializer SEMICOLON
    {
        if (symbol_exists_in_current_scope($4)) {
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
        if (symbol_exists_in_current_scope($4)) {
            yyerror("Variable redeclared");
        } else {
            insert_symbol(current_symbol_table, $4, $3, SYMBOL_CATEGORY_VARIABLE, current_symbol_table);
        }
        free($4); free($3);
    }
    statement
    { exit_scope(); }
    ;

switch_statement:
    SWITCH LPAREN expression RPAREN LBRACE
    { enter_scope("switch"); }
    switch_block RBRACE
    { exit_scope(); }
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
    { enter_scope("catch"); }
    block
    {
        if (symbol_exists_in_current_scope($4)) {
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
        if (entry && entry->type) {
            // Extract base type from array type (e.g., "int[]" -> "int")
            char *base_type = strdup(entry->type);
            char *bracket = strstr(base_type, "[]");
            if (bracket) *bracket = '\0';
            $$ = base_type;
        } else {
            $$ = strdup("unknown");
        }
        free($1);
    }
    | object_chain DOT IDENTIFIER LBRACKET expression RBRACKET
    {
        check_array_exists($3, $1);
        // Assume array type resolution similar to above
        $$ = strdup("int");  // Replace with actual type resolution logic
        free($1);
        free($3);
    }
    ;
    
object_creation:
    NEW IDENTIFIER LPAREN argument_list RPAREN
    ;

primary:
    IDENTIFIER
    {
        SymbolEntry *entry = lookup_symbol(current_symbol_table, $1);
        if (!entry) {
            yyerror("Undeclared variable");
            $$ = strdup("unknown");
        } else if (entry->category == SYMBOL_CATEGORY_METHOD) {
            yyerror("Method called without parentheses");
            $$ = strdup("unknown");
        } else {
            $$ = strdup(entry->type);
        }
        free($1);
    }
    | INTEGER_LITERAL { $$ = strdup("int"); }
    | FLOAT_LITERAL { $$ = strdup("float"); }
    | STRING_LITERAL { $$ = strdup("String"); }
    | CHAR_LITERAL { $$ = strdup("char"); }
    | TRUE { $$ = strdup("boolean"); }
    | FALSE { $$ = strdup("boolean"); }
    | NULL_LITERAL { $$ = strdup("null"); }
    | LPAREN expression RPAREN { $$ = $2; }
    ;

unary_expression:
    primary { $$ = $1; }
    | MINUS primary {
        if (strcmp($2, "int") == 0 || strcmp($2, "float") == 0) {
            $$ = $2;
        } else {
            add_error(yylineno, "Unary '-' requires numeric type");
            $$ = strdup("unknown");
        }
        free($2);
    }
    | NOT primary {
        if (strcmp($2, "boolean") == 0) {
            $$ = strdup("boolean");
        } else {
            add_error(yylineno, "Logical '!' requires boolean type");
            $$ = strdup("unknown");
        }
        free($2);
    }
    | BITWISE_NOT primary {
        if (strcmp($2, "int") == 0 || strcmp($2, "char") == 0) {
            $$ = $2;
        } else {
            add_error(yylineno, "Bitwise '~' requires integer type");
            $$ = strdup("unknown");
        }
        free($2);
    }
    | INCREMENT primary {
        if (!symbol_exists($2)) {
            yyerror("Undeclared variable in increment");
        }
        if (strcmp($2, "int") == 0 || strcmp($2, "float") == 0) {
            $$ = $2;
        } else {
            add_error(yylineno, "Increment requires numeric type");
            $$ = strdup("unknown");
        }
        free($2);
    }
    | DECREMENT primary {
        if (!symbol_exists($2)) {
            yyerror("Undeclared variable in decrement");
        }
        if (strcmp($2, "int") == 0 || strcmp($2, "float") == 0) {
            $$ = $2;
        } else {
            add_error(yylineno, "Decrement requires numeric type");
            $$ = strdup("unknown");
        }
        free($2);
    }
    ;

binary_expression:
    expression PLUS expression {
        if (!strcmp($1, "String") || !strcmp($3, "String")) {
            $$ = strdup("String");
        }
        else if ((!strcmp($1, "int") || !strcmp($1, "float")) && 
                (!strcmp($3, "int") || !strcmp($3, "float"))) {
            $$ = (strcmp($1, "float") == 0 || strcmp($3, "float") == 0) 
                ? strdup("float") : strdup("int");
        }
        else {
            add_error(yylineno, "Invalid types for addition");
            $$ = strdup("unknown");
        }
        free($1); free($3);
    }
    | expression MINUS expression
    | expression MULT expression
    | expression DIV expression
    | expression MOD expression {
        // Common handling for arithmetic operations
        char* type = NULL;
        if ((!strcmp($1, "int") || !strcmp($1, "float")) && 
            (!strcmp($3, "int") || !strcmp($3, "float"))) {
            type = (strcmp($1, "float") == 0 || strcmp($3, "float") == 0) 
                ? "float" : "int";
        } else {
            add_error(yylineno, "Invalid types for arithmetic operation");
            type = "unknown";
        }
        $$ = strdup(type);
        free($1); free($3);
    }
    | expression GT expression
    | expression LT expression
    | expression GTE expression
    | expression LTE expression {
        if ((!strcmp($1, "int") || !strcmp($1, "float")) && 
            (!strcmp($3, "int") || !strcmp($3, "float"))) {
            $$ = strdup("boolean");
        } else {
            add_error(yylineno, "Comparison requires numeric types");
            $$ = strdup("unknown");
        }
        free($1); free($3);
    }
    | expression EQ expression
    | expression NEQ expression {
        if (strcmp($1, $3) == 0 || 
            (!strcmp($1, "null") || !strcmp($3, "null"))) {
            $$ = strdup("boolean");
        } else {
            add_error(yylineno, "Type mismatch in equality check");
            $$ = strdup("unknown");
        }
        free($1); free($3);
    }
    | expression AND expression
    | expression OR expression {
        if (strcmp($1, "boolean") == 0 && strcmp($3, "boolean") == 0) {
            $$ = strdup("boolean");
        } else {
            add_error(yylineno, "Logical operators require boolean operands");
            $$ = strdup("unknown");
        }
        free($1); free($3);
    }
    | expression BITWISE_AND expression
    | expression BITWISE_OR expression
    | expression BITWISE_XOR expression {
        if (strcmp($1, "int") == 0 && strcmp($3, "int") == 0) {
            $$ = strdup("int");
        } else {
            add_error(yylineno, "Bitwise operators require integer operands");
            $$ = strdup("unknown");
        }
        free($1); free($3);
    }
    | expression LEFT_SHIFT expression
    | expression RIGHT_SHIFT expression
    | expression UNSIGNED_RIGHT_SHIFT expression {
        if (strcmp($1, "int") == 0 && strcmp($3, "int") == 0) {
            $$ = strdup("int");
        } else {
            add_error(yylineno, "Shift operators require integer operands");
            $$ = strdup("unknown");
        }
        free($1); free($3);
    }
    ;

expression:
    unary_expression
    | binary_expression
    | array_access
    | method_invocation
    | object_creation
    | increment_expression
    | decrement_expression
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