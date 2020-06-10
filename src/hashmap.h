#ifndef HASHMAP_H
#define HASHMAP_H

#include <stdlib.h>
#include <string.h>

typedef struct node {
  char *key;
  char *val;
  struct node *next;
} Node;

Node *h_get(char *key);
void h_ins(char *key, char *val);

#endif
