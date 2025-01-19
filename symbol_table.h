// symbol_table.h
#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

typedef struct SymbolEntry
{
    char *name;
    char *type;
    char *category; // Variable, Method, Class
    char *scope;    // Global, Local, etc.
    struct SymbolEntry *next;
} SymbolEntry;

typedef struct SymbolTable
{
    SymbolEntry *entries;
    struct SymbolTable *parent; // Parent scope for nested lookup
} SymbolTable;

// Function prototypes
SymbolTable *create_scope(char *name, SymbolTable *parent);
void insert_symbol(SymbolTable *table, char *name, char *type, char *category, char *scope);
SymbolEntry *lookup_symbol(SymbolTable *table, char *name);
void destroy_scope(SymbolTable *table);

#endif
