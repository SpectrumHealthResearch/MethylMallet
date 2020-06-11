#include "hashmap.h"

#define BUCKETS 1999
#define MAX_LEN  100

static Node *h[BUCKETS];

static unsigned int hash(char *key)
{
  unsigned int hashval=0L;
  while (*key != '\0')
    hashval = hashval * 31 + *key++;
  return (unsigned int) hashval % BUCKETS;
}

Node *h_get(char *key)
{
  for (Node *p = h[hash(key)]; p != NULL; p = p->next)
    if (strcmp(p->key, key) == 0)
      return p;
  return NULL;
}

int h_pop(char *key, char *dest)
{
  Node *p = h_get(key);

  if (p != NULL) {
    strcpy(dest, p->val);
    memset(p->val, '\0', sizeof(p->val));
    return 1;
  } else {
    memset(dest, '\0', sizeof(dest));
    return 0;
  }
}

void h_ins(char *key, char *val)
{
  Node *p = h_get(key);
  unsigned int hashval;

  if (p == NULL) {
    p = (Node *) malloc(sizeof(*p));
    p->key = (char *) malloc(sizeof(char) * MAX_LEN);
    p->val = (char *) malloc(sizeof(char) * MAX_LEN);
    strcpy(p->key, key);
    strcpy(p->val, val);
    hashval = hash(key);
    p->next = h[hashval];
    h[hashval] = p;
  } else {
    strcpy(p->val, val);
  }
}

#undef BUCKETS
#undef MAX_LEN
