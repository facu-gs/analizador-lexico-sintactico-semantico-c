#ifndef TPIAUXH
#define TPIAUXH
#define YYLTYPE YYLTYPE

#include <stdint.h>
#include <stdbool.h>
#include "tipos.h"


void appendTypeAll(typeNode_t ** list, typeNode_t * types); //TODO: Implementar

void inicializarUbicacion(void);
void reinicializarUbicacion(void);

mainNode_t * appendSymbol(mainNode_t ** list, char * identifier, typeNode_t * type, bool isFunction, bool isModifiable, int declarationLine);
void pushSymbol(mainNode_t ** list, char * identifier, typeNode_t * type, bool isFunction, bool isModifiable, int declarationLine);
void frontBackSplitSymbols(mainNode_t * source, mainNode_t ** frontRef, mainNode_t ** backRef);
mainNode_t * sortedMergeSymbols(mainNode_t * a, mainNode_t * b, int sortCriteria(mainNode_t *, mainNode_t *));
void sortSymbols(mainNode_t ** list, int sortCriteria(mainNode_t *, mainNode_t *));
mainNode_t * searchSymbol(mainNode_t * list, char * value);
void insertOrderedSymbol(mainNode_t **list, char * identifier, typeNode_t * type, bool isFunction, bool isModifiable, int declarationLine, int sortCriteria(mainNode_t *, mainNode_t *));
void listByCriteria(mainNode_t *list, bool criteria(mainNode_t *), void callback(mainNode_t *));
void appendType(typeNode_t ** list, dataType_t * type, uint8_t referenceLevel);
int typeLength(typeNode_t * list);
bool alphabeticAscIdentifierCriteria(mainNode_t * a, mainNode_t * b);
bool listFunctionsCriteria(mainNode_t * node);
bool listVariablesCriteria(mainNode_t * node);
void variablesReportCallback(mainNode_t * node);
void appendReport(reportNode_t ** list, char * estructura, int numeroLinea, int numeroColumna);
void imprimirReporteDeFunciones(mainNode_t *list);
void imprimirReporteDeVariables(mainNode_t *list);
int escapedCharValue(char a);
char * appendString(char * str1, char * str2);
char * makeCopy(char * str);
void typeNodeCopy(typeNode_t * destination, typeNode_t * source);
typeNode_t * makeTypeNodeCopy(typeNode_t * source);
char * repeat (char c , int count);
bool compararTipos(typeNode_t * t1, typeNode_t * t2);
int largoNumero(int numero);

#endif