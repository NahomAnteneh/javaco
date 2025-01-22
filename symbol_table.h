// symbol_table.h
#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

typedef enum
{
    SYMBOL_CATEGORY_VARIABLE,
    SYMBOL_CATEGORY_METHOD,
    SYMBOL_CATEGORY_CLASS,
    SYMBOL_CATEGORY_PARAMETER
} SymbolCategory;

typedef enum
{
    SYMBOL_SCOPE_GLOBAL,
    SYMBOL_SCOPE_LOCAL,
    SYMBOL_SCOPE_CLASS,
    SYMBOL_SCOPE_METHOD
} SymbolScope;

typedef struct SymbolEntry
{
    char *name;
    char *type;
    char *value;
    SymbolCategory category;
    SymbolScope scope;
    struct SymbolEntry *next;
} SymbolEntry;

typedef struct SymbolTable
{
    SymbolEntry *entries;
    struct SymbolTable *parent; // Parent scope for nested lookup
} SymbolTable;

// Function prototypes
SymbolTable *create_scope(char *name, SymbolTable *parent);
void insert_symbol(SymbolTable *table, char *name, char *type, SymbolCategory category, SymbolScope scope);
SymbolEntry *lookup_symbol(SymbolTable *table, char *name);
void destroy_scope(SymbolTable *table);

#endif
