#ifndef TIPOS_H
#define TIPOS_H

#define INICIO_CONTEO_LINEA 1
#define INICIO_CONTEO_COLUMNA 1
#include <stdint.h>
#include <stdbool.h>

typedef struct errorNode{
    char * message;
    int line;
    int column;
    struct errorNode * next;
} errorNode_t;

typedef struct labelNode{
    char * label;
    struct labelNode * next;
} labelNode_t;

typedef struct dataType {
    char * humanName;
    uint8_t additionClass;
} dataType_t;

//El primer elemento de la lista de tipo es el tipo de la variable ó el tipo de devolución de la función. En caso de tratarse de una función, los siguientes elementos serán, en orden, los argumentos recibidos por la misma
typedef struct typeNode {
    dataType_t * type;
    char * modifiers;
    int8_t referenceLevel;
    struct typeNode * next;
    int arraySize;
} typeNode_t;

typedef struct yylval_string {
        char cadena[300];
        char * modificadores;
        typeNode_t * tipo;
} yylval_string_t;


typedef struct reportNode {
    char * estructura;
    int numeroLinea;
    int numeroColumna;
    struct reportNode * next;
} reportNode_t;

typedef struct mainNode {
    char * identifier;
    typeNode_t * type;
    bool isFunction;
    bool isModifiable;
    int declarationLine;
    struct mainNode * next;
} mainNode_t;

typedef struct idWithReferenceLevelNode{
    char identifier [300];
    int referenceLefel;
} idWithReferenceLevelNode_t; 

#endif