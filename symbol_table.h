#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

typedef enum
{
    SYMBOL_CATEGORY_VARIABLE,
    SYMBOL_CATEGORY_METHOD,
    SYMBOL_CATEGORY_CLASS,
    SYMBOL_CATEGORY_PARAMETER
} SymbolCategory;

typedef struct SymbolEntry
{
    char *name;
    char *type;
    SymbolCategory category;
    struct SymbolTable *scope;
    struct SymbolEntry *next;
} SymbolEntry;

typedef struct SymbolTable
{
    char *name;
    SymbolEntry *entries;
    struct SymbolTable *parent;
    struct SymbolTable *children;     // Pointer to first child scope
    struct SymbolTable *next_sibling; // Pointer to next sibling in parent's children list
} SymbolTable;

SymbolTable *create_scope(char *name, SymbolTable *parent);
void insert_symbol(SymbolTable *table, char *name, char *type, SymbolCategory category, SymbolTable *scope);
SymbolEntry *lookup_symbol(SymbolTable *table, char *name);
void destroy_scope(SymbolTable *table);

void print_symbol_table(SymbolTable *global_scope);
void print_scope_details(SymbolTable *table, int depth);

#endif