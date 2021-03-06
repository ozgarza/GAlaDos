%{
/*
*Hector Jesus De La Garza Ponce 	619971
*Oziel Alonzo Garza Lopez 			805074

*Compilador GAlaDos
*/
extern char * yytext;
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "uthash.h"
#include "tablasVarProc.h"
#include "codigosOperaciones.h"
#include "pilas.h"
#include "utilerias.h"
#include "cuadruplos.h"
#define YYERROR_VERBOSE 1
	
//------------------------------------Variables de Control-----------------------------------------------
void yyerror( const char *str )
{
	fprintf( stderr, "error: %s\n", str );
}

//Contador temporal de dimensiones
int numeroDimensiones = 0;
char nombreMatrizActual[25];


//Globales miscelaneas de Control
int tamanioIdentificadores = 25;
int cantidadParametros = 0;
int cantidadParametrosFuncion = 0;
int esFuncion = 0;
int esMatriz = 0;
int esObjeto = 0;
int herenciaActiva = 0;
int direccionParametro = 0;

//Globales de control para validacion de parametros
int seccVariablesLocales = 0;
int seccVariablesGlobales = 0;
int seccFuncionesDeclaracion = 0;
int seccFuncionesImplementacion = 0;
int regresoNecesario = 0;

//Variables para la creacion de variables en la tabla
int direccionVariable;
char nombreObjeto[25];
char nombreObjetoActual[25];
char nombreVariable[25];
char nombreVariableActual[25];
char nombreVariableRetorno[25];
unsigned short tipoVariable;
char nombreProcedimiento[25];
char nombreProcedimientoActual[25];
int direccionVariableConstante;
nodo *nodoAuxiliar;

//Pilas operaciones
pila *operandos;
pila *operadores;

//Pilas Avail
pila *availEntero;
pila *availDecimal;
pila *availTexto;
pila *availBoolean;

//Pila saltos 
pila *pilaSaltos;

//Contador de cuadruplos
int contadorIndice = 0;

//Variables para control
nodoOperando *operando;
nodoOperador *operador;
nodoOperador *salto;
directorio *variable;
directorioProcedimientos *funcion;

//Variables para control de memoria
int cantidadVariablesConstante = 1000;
int cantidadVariablesTemp = 1000;
int cantidadVariablesLocal = 1000;
int cantidadVariablesGlobal = 1000;

//Direcciones base para memoria
int baseMemoriaConstante = 13000;
int baseMemoriaTemp = 9000;
int baseMemoriaLocal = 5000;
int baseMemoriaGlobal = 1000;


//Usado para calculo de direcciones
int cursorEntero = 1;
int cursorDecimal = 2;
int cursorTexto = 3;
int cursorBooleano = 4;

//Division de la memoria
//Por el momento solo son 1000 direcciones por cada tipo
//****************************
//Constantes
//De la 13,000 hasta la 16,999
int memoriaEnteroConstante;
int memoriaDecimalConstante;
int memoriaTextoConstante;
int memoriaBooleanoConstante;

//Temporales
//De la 9,000 hasta la 12,999
int memoriaEnteroTemp;
int memoriaDecimalTemp;
int memoriaTextoTemp;
int memoriaBooleanoTemp;

//Locales
//De la 5,000 hasta la 8,999
int memoriaEnteroLocal;
int memoriaDecimalLocal;
int memoriaTextoLocal;
int memoriaBooleanoLocal;
//****************************

//Locales
//De la 1,000 hasta la 4,999
int memoriaEnteroGlobal;
int memoriaDecimalGlobal;
int memoriaTextoGlobal;
int memoriaBooleanoGlobal;
//****************************

//Variables de Retorno de las funciones
//De las 0 a la 999
int memoriaVariablesRetorno;

//cuboSemantico
static int cuboSemantico[5][5][14];

//Lista de cuadruplos
cuadruplos *listaCuadruplos = NULL;

//Declaracion e inicializacion de la estructura objetos
directorioObjetos *objetos = NULL;

//Variables directorio objetos para manipulacion de herencia
directorioObjetos *objetoHeredado = NULL;

//Variables para la busqueda de clases
directorioObjetos *objetoBuscar = NULL;

//Declaracion para la tabla de constates
directorio *constantes = NULL;

//Decalracion para la tabla de retorno
directorio *retornos = NULL;

//**************************************************************************************************************
//----------------------------------------FUNCIONES DE CONTROL--------------------------------------------------
//**************************************************************************************************************

//Funcion encargada de meter en la pila de operandos un nuevo valor
void pushPilaOperandos(directorio *variable){
	//Creamos la nueva variable para agregar a la pila de variables
	operando = (nodoOperando*)malloc(sizeof(nodoOperando));

	//Rellenamos los nuevos valores para la variable
	if(variable == NULL){
		operando->temp = -1;
		operando->tipo = -1; 
		strcpy(operando->nombre, "/n");
		operando->direccion = -1;
	} else {
		operando->temp = 0;
		operando->tipo = variable->tipo; 
		strcpy(operando->nombre, variable->nombre);
		operando->direccion = variable->direccion;
	}
	push(operandos,operando);
}

//Funcion encargada de meter en la pila de operadores un nuevo valor
void pushPilaOperadores(int valor){
	//Creamos el nodo operandor que se le hara push en la pila operadores
	operador = (nodoOperador*)malloc(sizeof(nodoOperador));
	operador->operador = valor;
		
	//Metemos la multiplicacion en la pila de operadores
	push(operadores, operador);
}

//Funcion encargada de meter en la pila de saltos un nuevo valor
void pushPilaSaltos(int valor){
	//Creamos el nodo operandor que se le hara push en la pila operadores
	salto = (nodoOperador*)malloc(sizeof(nodoOperador));
	salto->operador = valor;

	//Metemos la multiplicacion en la pila de operadores
	push(pilaSaltos, salto);
}

//Funcion encargada de limpiar de las constantes de texto las comillas dobles
void limpiarString(){

	int indice = 1;
	char stringLimpio[25];

	//Se copia en un nuevo string cada dato del string menos las comillas
	while(nombreVariable[indice] != '"'){
		stringLimpio[indice - 1] = nombreVariable[indice];
		indice = indice + 1;
	}

	//Se le indica al string su terminacion
	stringLimpio[indice - 1] = '\0';

	//Se copia los datos de los strings
	strncpy(nombreVariable, stringLimpio, tamanioIdentificadores);
}

//Funcion encargada de inicializar las direcciones de las variables en el caso de una herencia de clases
void calcularMemoriaHeredada(){
	//Cargamos los datos del objeto heredado en el hijo
	objetoHeredado = buscarObjeto(objetos, nombreObjetoActual);
	
	//Barrido de todos los datos globales de clase
	for(variable = objetoHeredado->variablesGlobales; variable!= NULL; variable=(struct directorio*)(variable->hh.next)) {

		//Dependiendo el tipo de la variable la igualaremos a la memoria para que las nuevas variables no se sobrescriban en memoria
		switch(variable->tipo){

			//Variables Enteras Globales
			case 0:
				//Checamos si la variable es dimensionada para que aumentarle los datos correspondientes
				if (variable->dimensionada != 0) {
					//Es Dimensionada, direccion base más tamaño
					memoriaEnteroGlobal = variable->direccion + variable->tamanio;
				} else{
						//No es Dimensionada, direccion base
					memoriaEnteroGlobal = variable->direccion;
				}	
				break;

			//Variables Decimales Globales
			case 1:
				//Checamos si la variable es dimensionada para que aumentarle los datos correspondientes
				if (variable->dimensionada != 0) {
					//Es Dimensionada, direccion base más tamaño
					memoriaDecimalGlobal = variable->direccion + variable->tamanio;
				} else{
					//No es Dimensionada, direccion base
					memoriaDecimalGlobal = variable->direccion;
				}	
				break;

			//Variables Texto Globales
			case 2:
				//Checamos si la variable es dimensionada para que aumentarle los datos correspondientes
				if (variable->dimensionada != 0) {
					//Es Dimensionada, direccion base más tamaño
					memoriaTextoGlobal = variable->direccion + variable->tamanio;
				} else{
					//No es Dimensionada, direccion base
					memoriaTextoGlobal = variable->direccion;
				}	
				break;

			//Variables Booleano Globales
			case 3:
				//Checamos si la variable es dimensionada para que aumentarle los datos correspondientes
				if (variable->dimensionada != 0) {
					//Es Dimensionada, direccion base más tamaño
					memoriaBooleanoGlobal = variable->direccion + variable->tamanio;
				} else{
					//No es Dimensionada, direccion base
					memoriaBooleanoGlobal = variable->direccion;
				}	
				break;
		}
	}
}

//Metodo que se encarga de determinar que direccion de memoria se debera aumentar y guardarla en direccionVariable
void asignarMemoriaVariable(){
	//Checamos en que seccion nos encontramos al momento de crear una variable
	if (seccVariablesGlobales == 1) {
			//Estamos en las variables Globales
			//Determinar que tipo de variable tomaremos el dato
		switch(tipoVariable){
			case 0:
				if (memoriaEnteroGlobal < (baseMemoriaGlobal + cantidadVariablesGlobal * cursorEntero)) {
					direccionVariable = memoriaEnteroGlobal;
					memoriaEnteroGlobal++;
				} else{
					printf("Error: memoria insuficiente de tipo global-entero\n");
					exit(1);
				}	
			break;

			case 1:
				if (memoriaDecimalGlobal < (baseMemoriaGlobal + cantidadVariablesGlobal * cursorDecimal)) {
					direccionVariable = memoriaDecimalGlobal;
					memoriaDecimalGlobal++;
				} else{
					printf("Error: memoria insuficiente de tipo global-decimal\n");
					exit(1);
				}
			break;

			case 2:
				if (memoriaTextoGlobal < (baseMemoriaGlobal + cantidadVariablesGlobal * cursorTexto)) {
					direccionVariable = memoriaTextoGlobal;
					memoriaTextoGlobal++;
				} else{
					printf("Error: memoria insuficiente de tipo global-Texto\n");
					exit(1);
				}
			break;

			case 3:
				if (memoriaBooleanoGlobal < (baseMemoriaGlobal + cantidadVariablesGlobal * cursorBooleano)) {
					direccionVariable = memoriaBooleanoGlobal;
					memoriaBooleanoGlobal++;
				} else{
					printf("Error: memoria insuficiente de tipo global-Booleano\n");
					exit(1);
				}
			break;
		}

	} else if (seccVariablesLocales == 1) {
		switch(tipoVariable){
			case 0:
				if (memoriaEnteroLocal < (baseMemoriaLocal + cantidadVariablesLocal * cursorEntero)) {
					direccionVariable = memoriaEnteroLocal;
					memoriaEnteroLocal++;
				} else{
					printf("Error: memoria insuficiente de tipo Local-entero\n");
					exit(1);
				}
			break;

			case 1:
				if (memoriaDecimalLocal < (baseMemoriaLocal + cantidadVariablesLocal * cursorDecimal)) {
					direccionVariable = memoriaDecimalLocal;
					memoriaDecimalLocal++;
				} else{
					printf("Error: memoria insuficiente de tipo Local-decimal\n");
					exit(1);
				}
			break;

			case 2:
				if (memoriaTextoLocal < (baseMemoriaLocal + cantidadVariablesLocal * cursorTexto)) {
					direccionVariable = memoriaTextoLocal;
					memoriaTextoLocal++;
				} else{
					printf("Error: memoria insuficiente de tipo Local-Texto\n");
					exit(1);
				}
			break;

			case 3:
				if (memoriaBooleanoLocal < (baseMemoriaLocal + cantidadVariablesLocal * cursorBooleano)) {
					direccionVariable = memoriaBooleanoLocal;
					memoriaBooleanoLocal++;
				} else{
					printf("Error: memoria insuficiente de tipo Local-Booleano\n");
					exit(1);
				}
			break;
		}
	}
}

//Metodo que se encarga de determinar que direccion de memoria se debera aumentar y guardarla en direccionVariable
void asignarMemoriaVariableConstante(int tipoConstate){
	//Checamos en que seccion nos encontramos al momento de crear una variable
	//Estamos en las variables Globales
	//Determinar que tipo de variable tomaremos el dato
	switch(tipoConstate){
		case 0:
		if (memoriaEnteroConstante < (baseMemoriaConstante + cantidadVariablesConstante * cursorEntero)) {
			direccionVariableConstante = memoriaEnteroConstante;
			memoriaEnteroConstante++;
		} else{
			printf("Error: memoria insuficiente de tipo Constante-entero\n");
			exit(1);
		}	
		break;

		case 1:
			if (memoriaDecimalConstante < (baseMemoriaConstante + cantidadVariablesConstante * cursorDecimal)) {
				direccionVariableConstante = memoriaDecimalConstante;
				memoriaDecimalConstante++;
			} else{
				printf("Error: memoria insuficiente de tipo Constante-decimal\n");
				exit(1);
			}
			break;

		case 2:
			if (memoriaTextoConstante < (baseMemoriaConstante + cantidadVariablesConstante * cursorTexto)) {
				direccionVariableConstante = memoriaTextoConstante;
				memoriaTextoConstante++;
			} else{
				printf("Error: memoria insuficiente de tipo Constante-Texto\n");
				exit(1);
			}
			break;

		case 3:
			if (memoriaBooleanoConstante < (baseMemoriaConstante + cantidadVariablesConstante * cursorBooleano)) {
				direccionVariableConstante = memoriaBooleanoConstante;
				memoriaBooleanoConstante++;
			} else{
				printf("Error: memoria insuficiente de tipo Constante-Booleano\n");
				exit(1);
			}
			break;
	}
}

//Metodo que se encarga de determinar que direccion de memoria se debera aumentar y guardarla en direccionVariable
void asignarMemoriaVariableRetorno(){
	if (memoriaVariablesRetorno < 1000) {
		direccionVariable = memoriaVariablesRetorno;
		memoriaVariablesRetorno++;
	} else{
		printf("Error: memoria insuficiente de tipo retorno\n");
		exit(1);
	}	
}

//Metodo que reinizializa los datos de las direcciones de temporales
void calcularMemoriaTemporal(){
	memoriaEnteroTemp = baseMemoriaTemp + (cantidadVariablesTemp * 0);
	memoriaDecimalTemp = baseMemoriaTemp + (cantidadVariablesTemp * 1);
	memoriaTextoTemp = baseMemoriaTemp + (cantidadVariablesTemp * 2);
	memoriaBooleanoTemp = baseMemoriaTemp + (cantidadVariablesTemp * 3);
}

//Metodo que reinizializa los datos de las direcciones de locales
void calcularMemoriaLocal(){
	memoriaEnteroLocal = baseMemoriaLocal + (cantidadVariablesLocal * 0);
	memoriaDecimalLocal = baseMemoriaLocal + (cantidadVariablesLocal * 1);
	memoriaTextoLocal =	baseMemoriaLocal + (cantidadVariablesLocal * 2);
	memoriaBooleanoLocal = baseMemoriaLocal + (cantidadVariablesLocal * 3);
}

//Metodo que reinizializa los datos de las direcciones de globales
void calcularMemoriaGlobal(){
	memoriaEnteroGlobal = baseMemoriaGlobal + (cantidadVariablesGlobal * 0);
	memoriaDecimalGlobal = baseMemoriaGlobal + (cantidadVariablesGlobal * 1);
	memoriaTextoGlobal = baseMemoriaGlobal + (cantidadVariablesGlobal * 2);
	memoriaBooleanoGlobal = baseMemoriaGlobal + (cantidadVariablesGlobal * 3);
}

//Metodo que reinizializa los datos de las direcciones de temporales
void calcularMemoriaRetorno(){
	memoriaVariablesRetorno = 0;
}

//Metodo que inicializa las diferentes tipos de memoria del lenguaje
void calcularMemoriaVirtual(){
	//Memoria Temporal
	calcularMemoriaTemporal();
	
	//Memoria Local
	calcularMemoriaLocal();

	//Memoria Global
	calcularMemoriaGlobal();

	//Memoria de variables de retorno
	calcularMemoriaRetorno();
	
	//Memoria Constante
	memoriaEnteroConstante = baseMemoriaConstante + (cantidadVariablesConstante * 0);
	memoriaDecimalConstante = baseMemoriaConstante + (cantidadVariablesConstante * 1);
	memoriaTextoConstante = baseMemoriaConstante + (cantidadVariablesConstante * 2);
	memoriaBooleanoConstante = baseMemoriaConstante + (cantidadVariablesConstante * 3);
}

//Metodo que agrega a la tabla de constantes el tipo de variable que se tiene
void agregarTablaConstantes(char *nombre, int tipo){
	directorio *temp;

	//Buscar si anteriormente se ha insertado la constante en la tabla
	temp = buscarConstante(constantes, nombre);

	//Si la constante no se ha agregado anteriormente meterla con su direccion apropiada
	if (temp == NULL) {
		//Obtiene la direccion de la constante apropiada
		asignarMemoriaVariableConstante(tipo);
		constantes = agregarConstante(constantes, nombre, tipo, direccionVariableConstante);
	}
}

//Metodo que se encarga de inicializar el avail de temporales
void inicializarTemporales(){
	//liberacion de espacio en memoria
	free(availEntero);
	free(availDecimal);
	free(availTexto);
	free(availBoolean);

	//Creacion de las pilas de Avail en Memoria
	availEntero = malloc(sizeof(pila));
	availEntero->tamanio = 0;
	availEntero->primero = NULL;

	availDecimal = malloc(sizeof(pila));
	availDecimal->tamanio = 0;
	availDecimal->primero = NULL;

	availTexto = malloc(sizeof(pila));
	availTexto->tamanio = 0;
	availTexto->primero = NULL;

	availBoolean = malloc(sizeof(pila));
	availBoolean->tamanio = 0;
	availBoolean->primero = NULL;

	//Inicializacion de las 4 pilas de avail
	inicializarAvail(availEntero, availDecimal, availTexto, availBoolean, &memoriaEnteroTemp, &memoriaDecimalTemp, &memoriaTextoTemp, &memoriaBooleanoTemp);
}

//Metodo que se encarga de crear e inicializar las estructuras necesarias para el compilador
void inicializarCompilador(){
	//Accion numero 1
	//Inicializacion de estructuras

	//Calculamos la memoria a usar
	calcularMemoriaVirtual();

	//Creacion de las pilas en memoria
	operandos = malloc(sizeof(pila));
	operandos->tamanio = 0;
	operandos->primero = NULL;

	operadores = malloc(sizeof(pila));
	operadores->tamanio = 0;
	operadores->primero = NULL;

	//Creacion de las pilas de Avail en Memoria
	availEntero = malloc(sizeof(pila));
	availEntero->tamanio = 0;
	availEntero->primero = NULL;

	availDecimal = malloc(sizeof(pila));
	availDecimal->tamanio = 0;
	availDecimal->primero = NULL;

	availTexto = malloc(sizeof(pila));
	availTexto->tamanio = 0;
	availTexto->primero = NULL;

	availBoolean = malloc(sizeof(pila));
	availBoolean->tamanio = 0;
	availBoolean->primero = NULL;

	//Inicializacion de pila de Saltos
	pilaSaltos = malloc(sizeof(pila));
	pilaSaltos->tamanio = 0;
	pilaSaltos->primero = NULL;

	//Inicializacion del Avial
	inicializarAvail(availEntero, availDecimal, availTexto, availBoolean, &memoriaEnteroTemp, &memoriaDecimalTemp, &memoriaTextoTemp, &memoriaBooleanoTemp);

	//Inicializacion del CuboSemantico
	inicializarSemantica(cuboSemantico);
}

//**************************************************************************************************************
//-----------------------------------FUNCIONES WRAPPERS PARA GENERAR CUADRUPLOS---------------------------------
//**************************************************************************************************************

void generarEndAccess(){
	listaCuadruplos = generarCuadruploEndAccess(listaCuadruplos, &contadorIndice);
}

void generarAccess(){
	listaCuadruplos = generarCuadruploAccess(listaCuadruplos, nombreVariable, variable->clase, nombreProcedimientoActual, nombreObjetoActual, &contadorIndice);
}

void generarOro(){
	listaCuadruplos = generarCuadruploOro(listaCuadruplos, nombreVariable, nombreObjeto, nombreProcedimientoActual, nombreObjetoActual, &contadorIndice);
}

void  generarMultiplicacionDivision(){
	listaCuadruplos = generarCuadruploSequencial(1 , listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarSumaResta(){
	listaCuadruplos = generarCuadruploSequencial(2 , listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarRelacional(){
	listaCuadruplos = generarCuadruploSequencial(3, listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarAndOr(){
	listaCuadruplos = generarCuadruploSequencial(4, listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarAsignacion(){
	listaCuadruplos = generarCuadruploSequencial(5 , listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarLectura(){
	listaCuadruplos = generarCuadruploSequencial(6 , listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void  generarEscritura(){
	listaCuadruplos = generarCuadruploSequencial(7 , listaCuadruplos, operandos, operadores, cuboSemantico, &contadorIndice, availEntero, availDecimal, availTexto, availBoolean);
}

void generarAccion1Ciclo(){
		listaCuadruplos = generarCuadruploAccion1(listaCuadruplos, operandos, pilaSaltos, &contadorIndice);
}

void generarAccion2Ciclo(){
		listaCuadruplos = generarCuadruploAccion2Ciclo(listaCuadruplos, pilaSaltos, &contadorIndice);
}

void generarAccion1If(){
	listaCuadruplos = generarCuadruploAccion1(listaCuadruplos, operandos, pilaSaltos, &contadorIndice);
}

void generarAccion2If(){
	listaCuadruplos = generarCuadruploAccion2If(listaCuadruplos,  operandos, pilaSaltos, &contadorIndice);
}

void generarAccion3If(){
	listaCuadruplos = generarCuadruploAccion3If(listaCuadruplos, operandos, pilaSaltos, &contadorIndice);
}

void generarGoto(){
	listaCuadruplos = generarCuadruploGoto(listaCuadruplos, &contadorIndice);
}

void rellenarGoto(){
	listaCuadruplos = generarCuadruploAccion3If(listaCuadruplos, operandos, pilaSaltos, &contadorIndice);
}

void generarEndProc(){
	listaCuadruplos = generarCuadruploEndProc(listaCuadruplos, &contadorIndice);
}

void generarParam(){
	listaCuadruplos = generarCuadruploParam(listaCuadruplos, &direccionParametro, operandos, &contadorIndice);
}

void generarGosub(){
	listaCuadruplos = generarCuadruploGosub(listaCuadruplos, funcion->direccionCuadruplo, &contadorIndice);
}

void generarFinPrograma(){
	listaCuadruplos = generarCuadruploEndProgram(listaCuadruplos, &contadorIndice);
}

void generarEra(){
	//Generacion de diferentes tipos de era dependiendo de si es un objeto o no
	if (esObjeto == 0) {
		//Si no es un objeto el era se realiza con el nombre de la clase actual
		listaCuadruplos = generarCuadruploEra(listaCuadruplos, nombreProcedimiento, nombreObjetoActual, &contadorIndice);	
	} else if (esObjeto == 1){
		//Si es un objeto el era se realiza con el nombre de la clase del objeto
		listaCuadruplos = generarCuadruploEra(listaCuadruplos, nombreProcedimiento, nombreObjeto, &contadorIndice);
	} else {
		printf("Error critico de control de llamadas a objetos\n");
		exit(1);
	}
}

void generarReturn(){
	//Buscamos el dato de la variable de retorno de la funcion
	funcion = buscarFuncion(objetos, nombreObjetoActual, nombreProcedimientoActual);

	//Verificamos que la funcion pueda regresar alguna dato de funcion
	if (funcion->regresa != -1) {
		//Obtenemos el nombre de la variable de retorno
		sprintf(nombreVariableRetorno, "%s%i", nombreProcedimientoActual, funcion->regresa);

		//Buscamos la variable de retorno
		variable = buscarVariablesRetorno(retornos, nombreVariableRetorno);

		//Generamos el return del cuadruplo aqui se checara si es posible realizarlo o no
		listaCuadruplos = generarCuadruploReturn(listaCuadruplos, operandos, variable->tipo, variable->direccion, variable->nombre ,&contadorIndice);
	} else {
		printf("Error en funcion %s: No se puede regresar un dato cuando se especifica como nada\n", nombreProcedimientoActual);
		exit(1);
	}
}

void generarTemporalFuncion(char *objetoABuscar){
	//obtenemos el tipo de variable que regresa la funcion la forma de objeto->funcion()
	funcion = buscarFuncion(objetos, objetoABuscar, nombreProcedimiento);
	
	//Verificamos que la funcion sea adecuada para una expresion
	if (funcion->regresa != -1) {
		//Obtenemos el nombre de la variable de retorno
		sprintf(nombreVariableRetorno, "%s%i", nombreProcedimiento, funcion->regresa);

		//Buscamos la variable de retorno
		variable = buscarVariablesRetorno(retornos, nombreVariableRetorno);

		//Generamos el cuadruplo de la variable
		listaCuadruplos = generarCuadruploTemporalFuncion(listaCuadruplos, operandos, variable->tipo, variable->direccion, variable->nombre , availEntero, availDecimal, availTexto, availBoolean, &contadorIndice);
	} 
}

void generarVerifica(int dimension){
	//Dependiendo del la dimension se genera un verifica con diferentes datos	
	if(dimension == 1){
		//Para la dimension 1 se toma el valor superior del primer arreglo
		listaCuadruplos = generaCuadruploVerifica(listaCuadruplos, operandos,  variable->lsuperior1, &contadorIndice );
	} else if( dimension == 2) {
		//Para la dimension 2 se toma el valor superior del primer arreglo
		listaCuadruplos = generaCuadruploVerifica(listaCuadruplos, operandos,  variable->lsuperior2, &contadorIndice );
	}
}

void generarDesplazamiento(int dimension){

	//Buscamos los datos de la matriz
	variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreMatrizActual);
	if (variable == NULL) {
		variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
	} 

	//Dependiendo de si es arreglo o matriz generamos diferentes cuadruplo
	if(variable->dimensionada == 1){
		//Generacion de sumaMat para arreglo
		listaCuadruplos = generaCuadruploSUMAarreglo(listaCuadruplos, operandos, variable->direccion, availEntero, &contadorIndice);
	} else if(variable->dimensionada == 2 && dimension == 1) {

		//Generar multimat = (S1 * m1)
		listaCuadruplos = generarCuadruploMULTIarreglo(listaCuadruplos, operandos, variable->m1, availEntero, &contadorIndice);
	} else if(variable->dimensionada == 2 && dimension == 2) {

		//Segunda accion Matrices para acumular el cambio se realiza una simple suma
		//Se agrega la operacion de Suma
		pushPilaOperadores(OP_SUMA);

		//Se realiza la acumulacion de valores
		generarSumaResta();

		//Ultima accion Matrices para obtener el direccion
		listaCuadruplos = generaCuadruploSUMAarreglo(listaCuadruplos, operandos, variable->direccion, availEntero, &contadorIndice);
	}
}

//**************************************************************************************************************
//---------------------------------------------------MAIN-------------------------------------------------------
//**************************************************************************************************************

int main()
{

	yyparse();
	// imprimirObjetos(objetos, constantes, retornos);
	// printf("\n\n");
	// imprimeCuadruplos(listaCuadruplos, 0);
	// printf("\n\n");
	// imprimeCuadruplos(listaCuadruplos, 2);
	generarDatos(objetos, constantes, retornos);
	generarObj(listaCuadruplos);
	return 0;
}

//**************************************************************************************************************
//-------------------------------------------------TOKENS-------------------------------------------------------
//**************************************************************************************************************

%}

%union
{
	char* sval;
	unsigned short ival;
};

%token DOSPUNTOS
%token COMA
%token ES
%token CREAROBJETO
%token VARIABLES_GLOBALES
%token VARIABLES_LOCALES
%token DECLARA_OBJETOS
%token DECLARA_FUNCIONES
%token IMPLEMENTA_FUNCIONES
%token ATRIBUTOS_GLOBALES
%token <ival> BOOLEANO
%token <ival> ENTERO
%token <ival> DECIMAL
%token <ival> TEXTO
%token NADA
%token CLASE
%token <ival> MATRIZENTERA
%token <ival> MATRIZDECIMAL
%token REGRESA
%token HIJODE
%token EJECUTARPROGRAMA
%token LEERDELTECLADO
%token DESPLIEGA
%token SI
%token SINO
%token ENTONCES
%token MIENTRAS
%token FLECHA
%token CONCATENA
%token IGUAL
%token MAS
%token MENOS
%token POR
%token ENTRE
%token PUNTOYCOMA
%token APARENTESIS
%token CPARENTESIS
%token ALLAVE
%token CLLAVE
%token ACORCHETE
%token CCORCHETE
%token AMPERSAND
%token BARRA
%token COMPARA
%token NEGACION
%token MAYORQUE
%token MENORQUE
%token MAYORIGUAL
%token MENORIGUAL
%token <sval> CTEENTERA
%token <sval> CTETEXTO
%token <sval> CTEBOOLEANO
%token <sval> CTEDECIMAL
%token <sval> IDENTIFICADOR
%start programa
%%

//**************************************************************************************************************
//-------------------------------------------------REGLAS-------------------------------------------------------
//**************************************************************************************************************

programa:
	{
		//Inicializamos las diferentes estructuras de control para el compilador
		inicializarCompilador();

		//Metemos el contador en la pila de saltos
		pushPilaSaltos(contadorIndice);
		
		//cuadruplo 0 sera un goto a ejecutarPrograma
		generarGoto();

	}
	declara_objetos 
	{
		//Reiniciar el calculo de las memoria global
		calcularMemoriaGlobal();

		//Agregar main a tabla de objetos, siempre habra que haber un main
		strncpy(nombreObjetoActual, "main", tamanioIdentificadores);
		objetos = agregarObjeto(objetos, nombreObjetoActual);
		
	}
		variables_globales declara_funciones implementa_funciones EJECUTARPROGRAMA
	{
		//Rellenamos el goto para que apunte a ejecutar programa
		rellenarGoto();

		//LLenamos los datos a la tabla correspondiente
		strncpy(nombreProcedimientoActual, "ejecutarProgama", tamanioIdentificadores);
		objetos = agregarFuncion(objetos, nombreObjetoActual , nombreProcedimientoActual);

		//Entramos a una nueva funcion se debe inicializar los locaes
		calcularMemoriaLocal();

		//Entramos a una nueva seccion debemos inicializar los temporales
		inicializarTemporales();
		
	} 
	ALLAVE variables_locales bloque CLLAVE
	{	
		//Generar el cuadruplo de fin de programa
		generarFinPrograma();

		//Desplegar mensaje de terminacion de compilacion
		printf("Programa Compilado\n");
	}
	;

variables_globales:
	VARIABLES_GLOBALES
	{
		//Prendemos la bandera de variablesGLobales
		seccVariablesGlobales=1;
	} 
	bloque_variables
	{
		//Al salir del bloque apagamos la bandera de variables globales
		seccVariablesGlobales=0;
	};

bloque_variables:
	ACORCHETE bloque_variables_rep CCORCHETE
	;

bloque_variables_rep:
	/* empty */
	| declara_variables bloque_variables_rep
	;

declara_variables:
	ENTERO IDENTIFICADOR PUNTOYCOMA
	{	
		//Determinamos el tipo de variable
		//Obtenemos el texto del identificador
		//Calculamos la direccion para asignarle dependiendo el tipo de la variable
		tipoVariable = $1;
		strncpy(nombreVariable, $2, tamanioIdentificadores);
		asignarMemoriaVariable();
		//Checar la bandera de variables
		if(seccVariablesGlobales == 1){
			//Agregar a tabla de variables globales					
			objetos = agregarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;

		} else if(seccVariablesLocales == 1){	
			//Agregar a tabla de variables locales de la funcion
			objetos = agregarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;
		}
	}
	|
	DECIMAL IDENTIFICADOR PUNTOYCOMA
	{	
		//Determinamos el tipo de variable
		//Obtenemos el texto del identificador
		//Calculamos la direccion para asignarle dependiendo el tipo de la variable
		tipoVariable = $1;
		strncpy(nombreVariable, $2, tamanioIdentificadores);
		asignarMemoriaVariable();
		//Checar la bandera de variables
		if(seccVariablesGlobales == 1){
			//Agregar a tabla de variables globales					
			objetos = agregarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;

		} else if(seccVariablesLocales == 1){	
			//Agregar a tabla de variables locales de la funcion
			objetos = agregarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;
		}
	}
	|
	TEXTO IDENTIFICADOR PUNTOYCOMA
	{	
		//Determinamos el tipo de variable
		//Obtenemos el texto del identificador
		//Calculamos la direccion para asignarle dependiendo el tipo de la variable
		tipoVariable = $1;
		strncpy(nombreVariable, $2, tamanioIdentificadores);
		asignarMemoriaVariable();
		//Checar la bandera de variables
		if(seccVariablesGlobales == 1){
			//Agregar a tabla de variables globales					
			objetos = agregarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;

		} else if(seccVariablesLocales == 1){	
			//Agregar a tabla de variables locales de la funcion
			objetos = agregarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;
		}
	}
	|
	BOOLEANO IDENTIFICADOR PUNTOYCOMA
	{	
		//Determinamos el tipo de variable
		//Obtenemos el texto del identificador
		//Calculamos la direccion para asignarle dependiendo el tipo de la variable
		tipoVariable = $1;
		strncpy(nombreVariable, $2, tamanioIdentificadores);
		asignarMemoriaVariable();
		//Checar la bandera de variables
		if(seccVariablesGlobales == 1){
			//Agregar a tabla de variables globales					
			objetos = agregarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;

		} else if(seccVariablesLocales == 1){	
			//Agregar a tabla de variables locales de la funcion
			objetos = agregarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, tipoVariable, direccionVariable);
			tipoVariable = -1;
		}
	}
	|
	MATRIZDECIMAL IDENTIFICADOR
	{
		//Determinamos el tipo de variable
		//Obtenemos el texto del identificador
		//Calculamos la direccion para asignarle dependiendo el tipo de la variable
		tipoVariable = 1;
		strncpy(nombreVariable, $2, tamanioIdentificadores);
		asignarMemoriaVariable();

		//Obtenemos los valores de las variables
		if (seccVariablesGlobales == 1) {
			//Agregar la variable, si existe se marcara error
			objetos = agregarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable, tipoVariable, direccionVariable);
		} else if (seccVariablesLocales == 1) {

			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);

			//La variable no se encontro
			if (variable == NULL) {
				//Si esta variable entonces la tomamos si no es asi marcaremos un error			
				objetos = agregarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, tipoVariable, direccionVariable);
			} else {
				printf("Error: La variable ya esta declarada\n");
				exit(1);
			}
		}

		//Contador que nos permitira saber si sera de 1 o 2 dimensiones el arreglo
		numeroDimensiones = 0;
		
	}
	dimensiones PUNTOYCOMA
	{
		//Obtener la variable recien creada y darle sus propiedades, tiene prioridad variables locales
		if (seccVariablesGlobales == 1) {
			//Accedemos a la variable recien creada
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual,  nombreVariable);
		} else if (seccVariablesLocales == 1) {
			//Accedemos a la variable recien creada
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);
		}

		//Calculo del tamaño
		variable->tamanio = ((variable->lsuperior1 + 1) * (variable->lsuperior2 + 1));
		//Calculo de la m1
		variable->m1 = variable->tamanio / (variable->lsuperior1 + 1);

		//Aumento de las respectivas memorias con respecto al tamaño del arreglo o matriz
		if (seccVariablesGlobales == 1) {
			//Aumento de las variables globales
			memoriaDecimalGlobal = memoriaDecimalGlobal + variable->tamanio - 1;
		} else if (seccVariablesLocales == 1) {
			//Aumento de las variables locales
			memoriaDecimalLocal = memoriaDecimalLocal + variable->tamanio - 1;
		}
	}
	|
	MATRIZENTERA IDENTIFICADOR
	{
		//Determinamos el tipo de variable
		//Obtenemos el texto del identificador
		//Calculamos la direccion para asignarle dependiendo el tipo de la variable
		tipoVariable = 0;
		strncpy(nombreVariable, $2, tamanioIdentificadores);
		asignarMemoriaVariable();

		//Obtenemos los valores de las variables
		if (seccVariablesGlobales == 1) {
			//Agregar la variable, si existe se marcara error
			objetos = agregarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable, tipoVariable, direccionVariable);	
		} else if (seccVariablesLocales == 1) {
			//Buscamos si la variable local ya ha sido creada
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);

			//La variable no se encontro
			if (variable == NULL) {
				//Si esta variable entonces la tomamos si no es asi marcaremos un error			
				objetos = agregarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, tipoVariable, direccionVariable);
			} else {
				printf("Error: La variable ya esta declarada\n");
				exit(1);
			}
		}
		//Contador que nos permitira saber si sera de 1 o 2 dimensiones el arreglo
		numeroDimensiones = 0;
	}
	dimensiones PUNTOYCOMA
	{	
		//Obtener la variable recien creada y darle sus propiedades, tiene prioridad variables locales
		if (seccVariablesGlobales == 1) {
			//Acceso a la variable global recien creada
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual,  nombreVariable);
		} else if (seccVariablesLocales == 1) {
			//Acceso a la variable local recien creada
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);
		}

		//Calculo del tamaño
		variable->tamanio = ((variable->lsuperior1 + 1) * (variable->lsuperior2 + 1));
		//Calculo de la m1
		variable->m1 = variable->tamanio / (variable->lsuperior1 + 1);
		
		//Aumento de las respectivas memorias con respecto al tamaño del arreglo o matriz
		if (seccVariablesGlobales == 1) {
			//Aumento de las variables globales
			memoriaEnteroGlobal = memoriaEnteroGlobal + variable->tamanio - 1;
		} else if (seccVariablesLocales == 1) {
			//Aumento de las variables locales
			memoriaEnteroLocal = memoriaEnteroLocal + variable->tamanio - 1;
		}
	}
	|
	CREAROBJETO IDENTIFICADOR
	{	
		//Determinar en que seccion se crea el objeto
		if(seccVariablesGlobales == 1){
			printf("Funcionalidad aun no implementada.\n Declarar objetos en la seccion de Locales");
			exit(1);
		} else if (seccVariablesLocales == 1) {
			//Guardamos el identificador de la variable
			strncpy(nombreVariable, $2, tamanioIdentificadores);
		}
	}
	ES IDENTIFICADOR
	{
		//Guardamos el identificador del objeto
		strncpy(nombreObjeto, $5, tamanioIdentificadores);
	}
	PUNTOYCOMA
	{	
		//Buscamos que exista la clase si no existe terminara
		objetoBuscar = buscarObjeto(objetos, nombreObjeto);

		//Agregamos la variable a la tabla de variables locales
		objetos = agregarVariablesObjeto(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, nombreObjeto);

		//Creacion del era es por esto que solo podra estar en variables locales
		generarOro();
	} 
	;

dimensiones:
	ACORCHETE CTEENTERA CCORCHETE
	{	
		//Aumentamos el numero de dimensiones en 1
		numeroDimensiones++;

		//Identificamos en que seccion nos encontramos
		if (seccVariablesGlobales == 1) {
			//Accedemos a la variable recien creada
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual,  nombreVariable);
		} else if (seccVariablesLocales == 1) {
			//Accedemos a la variable recien creada
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);
		}

		//declaramos el nuevo arreglo, matriz con las dimensiones correctas
		variable->dimensionada = numeroDimensiones;

		//obtenemos el valor de la parte superior (primer dimension)
		variable->lsuperior1 = atoi($2);
	}
	dimensiones_rep
	;

dimensiones_rep:
	/*empty*/
	| ACORCHETE CTEENTERA CCORCHETE
	{	
		//Aumentamos el numero de dimensiones en 1
		numeroDimensiones++;
		//Identificamos en que seccion nos encontramos
		if (seccVariablesGlobales == 1) {
			//Accedemos a la variable recien creada
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual,  nombreVariable);
		} else if (seccVariablesLocales == 1) {
			//Accedemos a la variable recien creada
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);
		}

		//declaramos el nuevo arreglo, matriz con las dimensiones correctas
		variable->dimensionada = numeroDimensiones;
		
		//obtenemos el valor de la parte superior (primer dimension)
		variable->lsuperior2 = atoi($2);	
	}
	;

dimensiones2:
	/*Empty*/
	|
	ACORCHETE 
	{
		//Buscamos los datos de la variable en locales y globales
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		} 

		//Desplegamos errores dependiendo de como se haya definido esa variable
		if(variable->dimensionada == 0 ){
			printf("Error: la variable %s no es dimensionada",  nombreMatrizActual);
			exit(1);
		} else if(variable->dimensionada == 1){
			printf("Error: la variable %s no es matriz", nombreMatrizActual);
			exit(1);
		}
	} serexpresion2 
	{
		//Buscamos los datos de la variable en locales y globales
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		}

		//Generamos el cuadruplo verifica
		generarVerifica(2);

		//Generamos el cuadruplo de desplazamiento final
		generarDesplazamiento(2);
	}
	CCORCHETE
	;

serexpresion: 
	expresion expresion_and_or
	;

expresion_and_or:
	/*empty*/
	| AMPERSAND 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_AND);
	}
	serexpresion 
	{	
		//Generar cuadruplo logico
		generarAndOr();
	}
	| BARRA 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_OR);
	}
	serexpresion 
	{
		//Generar cuadruplo logico
		generarAndOr();
	}
	;

expresion:
	exp expresion_condicional
	;

expresion_condicional:
	/*empty*/
	| op_booleanos exp
	{
		//Aqui va la generacion del cuadruplo de checar
		generarRelacional();
	}
	;

op_booleanos:
	COMPARA 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_IGUAL);
	}
	| NEGACION 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_DIFERENTE);
	}
	| MAYORQUE 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MAYORQUE);
	}
	| MENORQUE 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MENORQUE);
	}
	| MAYORIGUAL 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MAYORIGUAL);
	}
	| MENORIGUAL
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MENORIGUAL);
	} 
	;

exp:
	termino
	{
		//Generamos el cuadruplo de suma-resta dependiendo del operador en la pila de operadores
		generarSumaResta();	
	} 
	exp_suma_resta
	;

exp_suma_resta:
	/*Empty*/
	| MAS 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_SUMA);
	}
	exp 
	| MENOS 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_RESTA);
	}
	exp
	;

termino:
	factor
	{
		//Generamos el cuadruplo de multiplicacion-division dependiendo del operador en la pila de operadores
		generarMultiplicacionDivision();
	} 
	termino_multi_divide
	;

termino_multi_divide:
	/*Empty*/
	| POR
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MULTIPLICACION);
	} 
	termino 
	| 
	ENTRE
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_DIVISION);
	} 
	termino
	;

factor:
	APARENTESIS
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_APARENTESIS);
	} 
	serexpresion CPARENTESIS
	{
		//Encontramos el cirre del parentesis lo sacamos de la pila
		pop(operadores);	
	}
	| var_cte
	;

var_cte:
	CTEENTERA
	{
		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		agregarTablaConstantes(nombreVariable, 0);

		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 

	| CTEDECIMAL
	{
		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		agregarTablaConstantes(nombreVariable, 1);

		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 
	| CTETEXTO
	{

		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);

		//Limpia el string de cualquir caracter no deseado
		limpiarString();

		agregarTablaConstantes(nombreVariable, 2);
		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 
	| CTEBOOLEANO
	{
		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		agregarTablaConstantes(nombreVariable, 3);

		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 
	| identificadorOLlamadaAFuncion	
	;

identificadorOLlamadaAFuncion:
	IDENTIFICADOR 
	{
		//Obtenemos el nombre de la variable que desamos usar
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		esFuncion = 0;
		esMatriz = 0;
	}  
	opcionalFuncion
	{	
		//Verificamos que sea solo una variable y no un identificador
		if (esFuncion == 0 && esMatriz == 0) {
			
			//Aqui habra un posible error por no manejar lo de las funciones
			//Debemos checar primero que ademas la variable no sea una constante
			variable = buscarConstante(constantes, nombreVariable);

			if (variable == NULL) {
				//Obtenemos los valores de las variables
				variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);

				//La variable no se encontro
				if (variable == NULL) {
					//Si esta variable entonces la tomamos si no es asi marcaremos un error
					variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable);
				}

				//crearemos un nodoOperando para agregarlo a la pila
				pushPilaOperandos(variable);	
			}
			
		}

		//Volvemos a inicializar
		esFuncion = 0;
		esMatriz = 0;
	}
	;

opcionalFuncion:
	/*Empty*/
	| llama_funcion_opcional APARENTESIS 
	{	
		//Inicializacion de los datos
		esFuncion = 1;
		cantidadParametros = 0;

		//Si no esta en formato de objeto->funcion el primer identificador es de la funcion
		if (esObjeto == 0) {
			strncpy(nombreProcedimiento, nombreVariable, tamanioIdentificadores);

			//Se debe verificar que exista (Se busca en el objeto actual)
			funcion = buscarFuncion(objetos, nombreObjetoActual, nombreProcedimiento);

		} else if (esObjeto == 1){
	
			//Buscar que la variable sea un objeto
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);
			if (variable == NULL) {

				printf("La variable %s no es un objeto \n", nombreVariable);
				exit(1);
			} 

			//Buscar que la funcion este especificada en la clase
			funcion = buscarFuncion(objetos, variable->clase, nombreProcedimiento);
			
			//Generacion del access
			generarAccess();
	
		}

		//Verificamos que exista, si no marcamos un error
		if (funcion == NULL){
			printf("Error no existe la funcion %s \n", nombreProcedimiento);
			exit(1);
		}		

		//Creacion del ERA
		generarEra();

	}
	parametros_funcion CPARENTESIS
	{
		//en caso de que no hubiera parametros checar
		if (cantidadParametros == 0) {
			if(funcion->parametros != NULL){
				printf("Se esperaban voleres en la funcion %s", nombreProcedimiento);
				exit(1);
			}
		}

		//Generar el Gosub
		generarGosub();

		//Verificar si es un objeto el que llama la funcion
		if (esObjeto == 1){
			
			//Generar el cuadruploEndAccess que permitira a la maquina saber que ya no debe usar las variables del objeto
			generarEndAccess();

			//Buscar los datos de la variable
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariableActual);

			//Determinamos si la funcion regresa un tipo de dato buscandola en la clase
			generarTemporalFuncion(variable->clase);

		} else {
			//Caso si no es una objeto
			//Se generar el temporal y se mete en la pila
			generarTemporalFuncion(nombreObjetoActual);
		}

		//Apagamos la bandera
		esObjeto = 0;
	}
	| ACORCHETE 
	{
		//Inicializacion parametros
		esMatriz = 1;

		//Al saber que es una matriz guardamos temporalmente el nombre de la matriz para futuras referencias
		strncpy(nombreMatrizActual, nombreVariable, tamanioIdentificadores);

		//Buscamos los datos de la variabl
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		}

		//Determinamos si esta ha sido declarada como una matriz o arreglo
		if(variable->dimensionada == 0){
			printf("Error: la variable no es dimensionada \n");
			exit(1);
		}
	} serexpresion2 
	{
		//Buscamos la matriz y cargamos sus datos
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		} 
		
		//Generamos el primer verifica
		generarVerifica(1);

		//Generamos el desplazamiento
		generarDesplazamiento(1);
	}
	CCORCHETE dimensiones2
	;

opcionalFuncion2:
	llama_funcion_opcional APARENTESIS 
	{	
		//Inicializacion de los datos
		esFuncion = 1;
		cantidadParametros = 0;

		//Si no esta en formato de objeto->funcion el primer identificador es de la funcion
		if (esObjeto == 0) {
			strncpy(nombreProcedimiento, nombreVariable, tamanioIdentificadores);

			//Se debe verificar que exista (Se busca en el objeto actual)
			funcion = buscarFuncion(objetos, nombreObjetoActual, nombreProcedimiento);

		} else if (esObjeto == 1){
			
			//Buscar que la variable sea un objeto
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);
			if (variable == NULL) {

				printf("La variable %s no es un objeto \n", nombreVariable);
				exit(1);
			} 

			//Buscar que la funcion este especificada en la clase
			funcion = buscarFuncion(objetos, variable->clase, nombreProcedimiento);
			
			//Generacion del access
			generarAccess();
	
		}

		//Verificamos que exista, si no marcamos un error
		if (funcion == NULL){
			printf("Error no existe la funcion %s \n", nombreProcedimiento);
			exit(1);
		}		

		//Creacion del ERA
		generarEra();

	}
	parametros_funcion CPARENTESIS
	{
		//En caso de que no hubiera parametros checar
		if (cantidadParametros == 0) {
			if(funcion->parametros != NULL){
				printf("Se esperaban voleres en la funcion %s", nombreProcedimiento);
				exit(1);
			}
		}

		//Generar el Gosub
		generarGosub();

		//Verificar si es un objeto el que llama la funcion
		if (esObjeto == 1){

			//Generar el cuadruploEndAccess que permitira a la maquina saber que ya no debe usar las variables del objeto
			generarEndAccess();

			//Buscar los datos de la variable
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariableActual);

			//Determinamos si la funcion regresa un tipo de dato buscandola en la clase
			generarTemporalFuncion(variable->clase);

		} else {
			//Aqui se debe generar el temporal y se mete en la pila
			//Caso si no es una obejto
			generarTemporalFuncion(nombreObjetoActual);
		}

		//Apagamo la bandera
		esObjeto = 0;
	}
	;

parametros_funcion:
	/*Empty*/
	| serexpresion2 
	{	
		//aumentamos en 1 la cantidad de parametros al entrar
		cantidadParametros++;

		//Tenemos que buscar en el objeto actual si no esta en modo de objeto->funcion();
		if (esObjeto == 0) {
			//Realizamos las busquedas en el objetoActual
			strncpy(nombreObjeto, nombreObjetoActual, tamanioIdentificadores);
		}

		//Se saca el valor de la pila de Operandos
		nodoAuxiliar = pop(operandos);

		//Verificamos que el tipo del parametro sea el mismo 
		direccionParametro = checarParametro(objetos, nombreObjeto, nombreProcedimiento, cantidadParametros, ((nodoOperando*)(nodoAuxiliar->dato))->tipo);
			
		push(operandos, ((nodoOperando*)(nodoAuxiliar->dato)));

		//Generacion de los parametros
		generarParam();

	}
	rep_parametros
	;

rep_parametros:
	/*Empty*/
	| COMA parametros_funcion
	;

declara_objetos:
	DECLARA_OBJETOS ACORCHETE declara_objetos_rep CCORCHETE;

declara_objetos_rep:
	/*Empty*/
	| objeto declara_objetos_rep
	;

objeto:
	CLASE IDENTIFICADOR
	{	
		//Reseteamos la herencia
		herenciaActiva = 0;

		//Reiniciar el calculo de las memoria global
		calcularMemoriaGlobal();
		
		//Obtenemos el nombre de la clase para guardalo
		strncpy(nombreObjetoActual, $2, tamanioIdentificadores);
	} 
	objeto_herencia
	{
		//Checamos que se haya tenido una herencia si es asi debemos recalcular las variables globales
		if (herenciaActiva == 1) {
			
			//Calculamos la memoria respecto a los valores antiguos de las variables globales heredadas
			calcularMemoriaHeredada();
		} else {
			//Esta funcion se encargara de agregar la nueva clase si esta ya se encuentra declarada marcara un error
			objetos = agregarObjeto(objetos, nombreObjetoActual);
		}
	} 
	ALLAVE atributos_globales declara_funciones implementa_funciones CLLAVE;

objeto_herencia:
	/*Empty*/
	| HIJODE IDENTIFICADOR
	{
		//Activamos la herencia
		herenciaActiva = 1;

		//Nombramos el objeto padre
		strncpy(nombreObjeto, $2, tamanioIdentificadores);

		//Activamos la herencia del objetoactual = hijo, con el objeto padre = objetos
		objetos = herenciaObjetos(objetos, nombreObjetoActual, nombreObjeto);
	}
	;

atributos_globales:
	ATRIBUTOS_GLOBALES
	{
		//Prendemos la bandera de variablesGLobales
		seccVariablesGlobales=1;
	} 
	bloque_variables
	{
		//Al salir del bloque apagamos la bandera de variables globales
		seccVariablesGlobales=0;
	}
	;

declara_funciones:
	{
		//Recordar en la seccion que nos encontramos
		seccFuncionesDeclaracion = 1;
	}
	DECLARA_FUNCIONES ACORCHETE declara_funciones_rep CCORCHETE
	{
		//Olvidar en la seccion que nos encontramos
		seccFuncionesDeclaracion = 0;
	}
	;

declara_funciones_rep:
	/*Empty*/
	| declaracion_prototipos declara_funciones_rep
	;

declaracion_prototipos:
	IDENTIFICADOR 
	{
		//Reseteo de las variables
		calcularMemoriaLocal();

		//Especificamos que estamos metiendo variables en la seccion de Locales
		seccVariablesLocales = 1;

		//Cargamos los datos en la tablas especiales
		strncpy(nombreProcedimientoActual, $1, tamanioIdentificadores);
		objetos = agregarFuncion(objetos, nombreObjetoActual, nombreProcedimientoActual);

		//Inicializacion de la cantidad de parametros
		cantidadParametros = 0;
	}
	APARENTESIS parametros CPARENTESIS REGRESA declaracion_prototipos_regresa PUNTOYCOMA
	{
		//Encontramos la funcion que ya estaba definida
		funcion = buscarFuncion(objetos, nombreObjetoActual, nombreProcedimientoActual);

		//Checamos que el usuario haya puesto todos los parametros
		cantidadParametrosFuncion = HASH_COUNT(funcion->parametros);

		//Verificacion de la cantidad de parametros
		if (cantidadParametros != cantidadParametrosFuncion) {
			printf("Error en implementacion de funcion %s: No se definieron los %i que se esperaban\n", nombreProcedimientoActual, cantidadParametrosFuncion);
			exit(1);
		} else {
			//Asignarle a la funcion actual el tipo de dato que regresara en este caso nada
			funcion->permiso = 0;

			//Salimos de la seccion de variables locales
			seccVariablesLocales = 0;
			
			//Obtenemos el id unico para la variable de retorno que usaremos
			sprintf(nombreVariableRetorno, "%s%i", nombreProcedimientoActual, funcion->regresa);

			//Buscamos en las constantes
			variable = buscarVariablesRetorno(retornos, nombreVariableRetorno);


			if (variable == NULL) {
				
				//Si la funcion no regresa nada no es necesario que ocupe espacio
				if (funcion->regresa != -1) {
					//Calculamos la direccion de la variable de retorno a usar
					asignarMemoriaVariableRetorno();

					//Agregamos la variable de retorno al directorio de datos
					retornos = agregarVariablesRetorno(retornos, nombreVariableRetorno, funcion->regresa, direccionVariable);
				}
				
			}
			
		}
	}
	;

declaracion_prototipos_regresa:
	tipo
	{
		//Checamos en que parte estamos
		funcion = buscarFuncion(objetos, nombreObjetoActual, nombreProcedimientoActual);

		//Asignarle a la funcion actual el tipo de dato que regresara
		funcion->regresa = tipoVariable;
	}
	| NADA
	{
		//Checamos en que parte estamos
		funcion = buscarFuncion(objetos, nombreObjetoActual, nombreProcedimientoActual);

		//Asignarle a la funcion actual el tipo de dato que regresara
		funcion->regresa = -1;	
	}
	;

parametros:
	/*Empty*/
	| parametros_rep
	;

parametros_rep:
	IDENTIFICADOR 
	{
		//Aumentamos en uno la cuenta de los parametros
		cantidadParametros++;

		//Actualizar el temporal con el nombre del parametro
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		
	}
	DOSPUNTOS tipo 
	{	
		//Dependiendo en la seccion que se encuentre se realizan diferentes acciones semanticas

		//Seccion Declaracion
		if (seccFuncionesDeclaracion == 1) {
			//Obtenemos la memoria a usar
			asignarMemoriaVariable();

			//Agregar la variable a la tabla de parametros
			objetos = agregarParametros(objetos, nombreObjetoActual, nombreProcedimientoActual, tipoVariable, cantidadParametros, direccionVariable);

			//Agregar el parametro a la tabla de variables locales de la funcion
			objetos = agregarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual, nombreVariable, tipoVariable, direccionVariable);	
		}
		
		//Seccion Implementacion
		if (seccFuncionesImplementacion == 1) {
			
			//Temporalmente estamos en la seccion de locales
			seccVariablesLocales = 1;

			//Chequeo semantico de la cantidad de parametros y su tipo de dato
			//Checamos que la variable exista en el scope
			variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);

			//La variable no se encontro
			if (variable == NULL) {
				//Si esta variable entonces la tomamos si no es asi marcaremos un error
				variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable);
			}

			//Verificamos que los tipos de datos sean los mismo
			checarParametro(objetos, nombreObjetoActual, nombreProcedimientoActual, cantidadParametros, tipoVariable);

			//Recoremos las variables que ya tenemos definidas para aumentar su contador
			asignarMemoriaVariable();

			//Salimos de la seccion de locales
			seccVariablesLocales = 0;
		}
	} 
	parametros_rep1
	;

parametros_rep1:
	/*Empty*/
	| COMA parametros_rep
	;

tipo:	
	ENTERO
	{
		//Obtenemos el valor del tipo
		tipoVariable=$1;
	}
	| DECIMAL 
	{
		//Obtenemos el valor del tipo
		tipoVariable=$1;
	}
	| BOOLEANO 
	{
		//Obtenemos el valor del tipo
		tipoVariable=$1;
	}
	| TEXTO 
	{
		//Obtenemos el valor del tipo
		tipoVariable=$1;
	}
	| MATRIZENTERA 
	{
		//Obtenemos el valor del tipo
		tipoVariable=$1;
	}
	| MATRIZDECIMAL
	{
		//Obtenemos el valor del tipo
		tipoVariable=$1;
	}
	;

implementa_funciones:
	{
		//Entramos a la seccion de implementacion de funciones
		seccFuncionesImplementacion = 1;
	}
	IMPLEMENTA_FUNCIONES ACORCHETE implementa_funciones_rep CCORCHETE
	{
		//Salimos de la seccion de implementacion de funciones
		seccFuncionesImplementacion = 0;
	}
	;

implementa_funciones_rep:
	/*Empty*/
	| funciones implementa_funciones_rep
	;

funciones:
	IDENTIFICADOR 
	{
		//Inicializamos la bandera de necesidad Retorno
		regresoNecesario = 0;

		//Actualizar el temporal con el nombre de la funcion
		strncpy(nombreProcedimientoActual, $1, tamanioIdentificadores);
	} 
	APARENTESIS 
	{
		//Entramos a una nueva funcion se debe inicializar los locaes
		calcularMemoriaLocal();

		//Entramos a una nueva seccion debemos inicializar los temporales
		inicializarTemporales();

		//Inicializamos la cantidad de parametros
		cantidadParametros = 0;
	}
	parametros CPARENTESIS ALLAVE variables_locales
	{
		//Agregar a la tabla de procedimientos el inicio del cuadruplo de la funcion		
		funcion = buscarFuncion(objetos, nombreObjetoActual, nombreProcedimientoActual);

		//Checamos que el usuario haya puesto todos los parametros
		cantidadParametrosFuncion = HASH_COUNT(funcion->parametros);

		//Verificacion de la cantidad de parametros
		if (cantidadParametros != cantidadParametrosFuncion) {
			printf("Error en implementacion de funcion %s: No se definieron los %i que se esperaban\n", nombreProcedimientoActual, cantidadParametrosFuncion);
			exit(1);
		} else {
			//Asignarle a la funcion actual el tipo de dato que regresara en este caso nada
			funcion->direccionCuadruplo = contadorIndice;

			//Asegurarnos que la funcion regrese un valor
			if (funcion->regresa == -1) {
				regresoNecesario = 0;
			} else {
				regresoNecesario = 1;
			}
		}

	} bloque CLLAVE
	{
		//Verificamos si es necesario tener por lo menos 1 return en alguna parte de la funcion
		if (regresoNecesario == 1) {
			printf("Error en funcion %s: Se espera regresar un valor\n", nombreProcedimientoActual);
			exit(1);
		}
		
		//Generamos el fin del bloque
		generarEndProc();
	}
	;

variables_locales:
	VARIABLES_LOCALES 
	{
		//Prendemos la bandera de variablesGLobales
		seccVariablesLocales=1;	
	}
	bloque_variables
	{
		//Al salir del bloque apagamos la bandera de variables globales
		seccVariablesLocales=0;
	}
	;

bloque:
	/*Empty*/
	| estatuto bloque
	;

estatuto:
	decideEstatuto PUNTOYCOMA
	| escritura PUNTOYCOMA
	| regresa PUNTOYCOMA
	| lectura PUNTOYCOMA
	| condicional
	| ciclo
	;

decideEstatuto:
	IDENTIFICADOR 
	{
		//Obtenemos el nombre de la variable que desamos usar
		strncpy(nombreVariable, $1, tamanioIdentificadores);

		//Inicializacion de los datos necesarios para saber si es una matriz o llamada a funcion
		esFuncion = 0;
		esMatriz = 0;
	}  
	estatutoOAsignacion
	;


estatutoOAsignacion:
	asignacion 
	|
	opcionalFuncion2
	;

llama_funcion_opcional:
	/*Empty*/
	| FLECHA IDENTIFICADOR
	{
		//Prendemos la bandera de ser un objeto llamando una funcion
		esObjeto = 1;

		//Obtenemos el nombre del funcionamiento y lo guardamos
		strncpy(nombreProcedimiento, $2, tamanioIdentificadores);
		
		//Obtenemos el nombre de la variableActual = nombre del objeto
		strncpy(nombreVariableActual, nombreVariable, tamanioIdentificadores);
	}
	;

asignacion:
	ACORCHETE 
	{
		//Inicializacion parametros
		esMatriz = 1;

		//Guardamos el nombre de la matriz en su correspondiente string
		strncpy(nombreMatrizActual, nombreVariable, tamanioIdentificadores);

		//Buscamos los datos de la variable en locales y globales
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		} 

		//Verificamos que sea un array o matriz
		if(variable->dimensionada == 0){
			printf("Error: la variable no es dimensionada \n");
			exit(1);
		}
	} serexpresion2 
	{
		//Buscamos los datos de la variable en locales o globales
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		} 

		//Generamos el primer verifica
		generarVerifica(1);

		//Generamos el desplazamiento
		generarDesplazamiento(1);
	}
	CCORCHETE dimensiones2 IGUAL
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_ASIGNACION);		 
	}
	serexpresion
	{
		//Funcion experimental solo funcionara con expresiones y id
		generarAsignacion();
	}
	| IGUAL
	{	
		//Obtenemos los valores de las variables si no existen exit
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable);
		}

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);

		//Metemos el operador de asignacion '=' en la pila de operadores
		pushPilaOperadores(OP_ASIGNACION);
	} 
	serexpresion
	{
		//Funcion experimental solo funcionara con expresiones y id
		generarAsignacion();
	}
	;

lectura:
	LEERDELTECLADO
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_LECTURA);
	}
 	APARENTESIS IDENTIFICADOR
 	{
		//Obtenemos el nombre de la variable que desamos usar
		strncpy(nombreVariable, $4, tamanioIdentificadores);

		//Checar si es una matriz
		esMatriz = 0;
	} 
	lectura_matriz
	{	
		//la variable a guardar no es matriz
		if (esMatriz == 0) {

			//Debemos checar primero que ademas la variable no sea una constante
			variable = buscarConstante(constantes, nombreVariable);

			if (variable == NULL) {
				//Obtenemos los valores de las variables
				variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);

				//La variable no se encontro
				if (variable == NULL) {
					//Si esta variable entonces la tomamos si no es asi marcaremos un error
					variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable);
				}

				//crearemos un nodoOperando para agregarlo a la pila
				pushPilaOperandos(variable);	
			}
		}
		
		//Reseteamos la bandera de Matriz
		esMatriz = 0;
	}
	CPARENTESIS
	{
		//Generamos el cuadruplos de Lectura
		generarLectura();
	}
	;

lectura_matriz:
	/*Empty*/
	|ACORCHETE 
	{
		//Inicializacion parametros
		esMatriz = 1;

		//Al saber que es una matriz guardamos temporalmente el nombre de la matriz para futuras referencias
		strncpy(nombreMatrizActual, nombreVariable, tamanioIdentificadores);

		//Buscamos los datos de la variabl
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		} 

		//Determinamos si esta ha sido declarada como una matriz o arreglo
		if(variable->dimensionada == 0){
			printf("Error: la variable no es dimensionada \n");
			exit(1);
		}
	} serexpresion2 
	{
		//Buscamos la matriz y cargamos sus datos
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreMatrizActual);
		if (variable == NULL) {
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreMatrizActual);
		}

		//Generamos el primer verifica
		generarVerifica(1);

		//Generamos el desplazamiento
		generarDesplazamiento(1);
	}
	CCORCHETE dimensiones2
	;
	
escritura:
	DESPLIEGA APARENTESIS 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_ESCRITURA);
	}
	escritura_valores CPARENTESIS 
	{	
		//Generamos el cuadruplo de despliega
		generarEscritura();

		//Metemos el operador en la pila de operadores para lograr el efecto de salto de linea
		pushPilaOperadores(OP_ESCRITURA);
		
		//crearemos un nodoOperando para agregarlo a la pila DUMMY para lograr el efecto de salto de linea
		pushPilaOperandos(NULL);

		//Generamos el cuadruplo de despliega salto de linea nuevo
		generarEscritura();
	}
	;

escritura_valores:
	serexpresion escritura_valores1
	;

escritura_valores1:
	/*Empty*/
	| CONCATENA
	{
		//Generamos un cuadruplo de escritura por cada valor que se tenga
		generarEscritura();

		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_ESCRITURA);

	} escritura_valores
	;

regresa:
	REGRESA serexpresion
	{	
		//Desactivamos el regreso necesario porque almenos se especifico una vez un return
		if (regresoNecesario == 1) {
			regresoNecesario = 0;
		}

		//Generamos el "return" que en reailidad sera una asignacion del resultado a su variable global
		generarReturn();

		//Generamos el ENDPROC al momento de encontrar un return para no seguir ejecutando
		generarEndProc();
	}
	;


condicional:
	SI APARENTESIS serexpresion CPARENTESIS 
	{	
		//Generamos las acciones semanticas de un inicio de if
	 	generarAccion1If();
	}
	ALLAVE bloque CLLAVE condicional_if
	{	
		//Generamos las acciones semanticas de un fin de if
		generarAccion3If();
	}
	;

condicional_if:
	/*Empty*/
	| SINO 
	{
		//Generamos las acciones semanticas de un inicio de else
		generarAccion2If();
	}
	ALLAVE bloque CLLAVE
	;

ciclo:
	MIENTRAS 
	{	
		//Metemos en la pila de saltos el contador actual
		pushPilaSaltos(contadorIndice);
	}
	APARENTESIS serexpresion 
	{
		//Generamos el goto en falso para la expresion
		generarAccion1Ciclo();
	} 
	CPARENTESIS ALLAVE bloque CLLAVE 
	{	
		//Generamos el goto para regresar a evaluar la expresion
		generarAccion2Ciclo();
	}
	;

serexpresion2: 
	expresion2 expresion_and_or2
	;

expresion_and_or2:
	/*empty*/
	| AMPERSAND 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_AND);
	}
	serexpresion2 
	{	
		//Generar cuadruplo logico
		generarAndOr();
	}
	| BARRA 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_OR);
	}
	serexpresion2 
	{
		//Generar cuadruplo logico
		generarAndOr();
	}
	;

expresion2:
	exp2 expresion_condicional2
	;

expresion_condicional2:
	/*empty*/
	| op_booleanos2 exp2
	{
		//Aqui va la generacion del cuadruplo de checar
		generarRelacional();
	}
	;

op_booleanos2:
	COMPARA 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_IGUAL);
	}
	| NEGACION 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_DIFERENTE);
	}
	| MAYORQUE 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MAYORQUE);
	}
	| MENORQUE 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MENORQUE);
	}
	| MAYORIGUAL 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MAYORIGUAL);
	}
	| MENORIGUAL
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MENORIGUAL);
	} 
	;

exp2:
	termino2
	{	
		//Generamos el cuadruplo de suma-resta dependiendo del operador en la pila de operadores
		generarSumaResta();	
	} 
	exp_suma_resta2
	;

exp_suma_resta2:
	/*Empty*/
	| MAS 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_SUMA);
	}
	exp2
	| MENOS 
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_RESTA);
	}
	exp2
	;

termino2:
	factor2
	{
		//Generamos el cuadruplo de multiplicacion-division dependiendo del operador en la pila de operadores
		generarMultiplicacionDivision();
	} 
	termino_multi_divide2
	;

termino_multi_divide2:
	/*Empty*/
	| POR
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_MULTIPLICACION);
	} 
	termino2 
	| 
	ENTRE
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_DIVISION);
	} 
	termino2
	;

factor2:
	APARENTESIS
	{
		//Metemos el operador en la pila de operadores
		pushPilaOperadores(OP_APARENTESIS);
	} 
	serexpresion2 CPARENTESIS
	{
		//Encontramos el cirre del parentesis lo sacamos de la pila
		pop(operadores);	
	} 
	| var_cte2
	;

var_cte2:
	CTEENTERA
	{
		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		agregarTablaConstantes(nombreVariable, 0);

		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 

	| CTEDECIMAL
	{
		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		agregarTablaConstantes(nombreVariable, 1);

		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 
	| CTETEXTO
	{

		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		
		//Limpia el string de cualquir caracter no deseado
		limpiarString();

		agregarTablaConstantes(nombreVariable, 2);
		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 
	| CTEBOOLEANO
	{
		//Obtenemos el valor de la constante
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		agregarTablaConstantes(nombreVariable, 3);

		variable = buscarConstante(constantes, nombreVariable);

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	} 
	| IDENTIFICADOR
	{
		//Obtenemos el nombre de la variable que desamos usar
		strncpy(nombreVariable, $1, tamanioIdentificadores);
		//Obtenemos los valores de las variables
		variable = buscarVariablesLocales(objetos, nombreObjetoActual, nombreProcedimientoActual,  nombreVariable);

		//La variable no se encontro
		if (variable == NULL) {
			//Si esta variable entonces la tomamos si no es asi marcaremos un error
			variable = buscarVariablesGlobales(objetos, nombreObjetoActual, nombreVariable);
		}

		//crearemos un nodoOperando para agregarlo a la pila
		pushPilaOperandos(variable);
	}	
	;