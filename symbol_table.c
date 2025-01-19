// symbol_table.c
#include "symbol_table.h"
#include <stdlib.h>
#include <string.h>

SymbolTable *create_scope(char *name, SymbolTable *parent)
{
    SymbolTable *new_table = (SymbolTable *)malloc(sizeof(SymbolTable));
    new_table->entries = NULL;
    new_table->parent = parent;
    return new_table;
}

void insert_symbol(SymbolTable *table, char *name, char *type, char *category, char *scope)
{
    SymbolEntry *entry = (SymbolEntry *)malloc(sizeof(SymbolEntry));
    entry->name = strdup(name);
    entry->type = strdup(type);
    entry->category = strdup(category);
    entry->scope = strdup(scope);
    entry->next = table->entries;
    table->entries = entry;
}

SymbolEntry *lookup_symbol(SymbolTable *table, char *name)
{
    SymbolEntry *entry = table->entries;
    while (entry)
    {
        if (strcmp(entry->name, name) == 0)
        {
            return entry;
        }
        entry = entry->next;
    }
    return table->parent ? lookup_symbol(table->parent, name) : NULL;
}

void destroy_scope(SymbolTable *table)
{
    SymbolEntry *entry = table->entries;
    while (entry)
    {
        SymbolEntry *temp = entry;
        entry = entry->next;
        free(temp->name);
        free(temp->type);
        free(temp->category);
        free(temp->scope);
        free(temp);
    }
    free(table);
}
