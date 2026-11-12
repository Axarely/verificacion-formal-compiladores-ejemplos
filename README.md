# Verificación formal de compiladores: ejemplos de demostración

Ejemplos de la demostración técnica de la investigación *Verificación formal de compiladores: el caso CompCert* (IS-158 Compiladores e Intérpretes, III cuatrimestre 2026).

| Archivo | Qué demuestra |
|---|---|
| `MiniCompilador.v` | Un compilador de expresiones a una máquina de pila demostrado correcto en Coq, con una optimización verificada y otra incorrecta que no se puede demostrar. |
| `desbordamiento.c` | El resultado de un programa con comportamiento indefinido depende del compilador y del nivel de optimización. |
| `fuera_de_limites.c` | El intérprete de referencia de CompCert detiene un acceso fuera de un arreglo. |
| `suma.c` | Programa bien definido para ver los lenguajes intermedios de CompCert. |

## Requisitos (Ubuntu / Debian)

```bash
sudo apt update
sudo apt install -y build-essential git coq ocaml ocaml-findlib menhir libmenhir-ocaml-dev
```

Los ejemplos se probaron con GCC 13.3 y Coq 8.18 (Ubuntu 24.04).

### Instalar CompCert 3.14

La versión 3.14 es compatible con el Coq 8.18 de los repositorios de Ubuntu.

```bash
git clone https://github.com/AbsInt/CompCert.git
cd CompCert
git checkout v3.14
./configure x86_64-linux
make -j4 all
sudo make install
ccomp -version      # The CompCert C verified compiler, version 3.14
```

## Ejecución y resultados esperados

### 1. Minicompilador verificado

```bash
coqc MiniCompilador.v
```

Termina sin errores e imprime:

```
= [ILoad 0; IPush 3; IAdd; ILoad 1; IPush 1; ISub; IMul]
= Some [20]
= Plus (Const 8) (Var 0)
Closed under the global context
```

### 2. Comportamiento indefinido

```bash
gcc -O0 desbordamiento.c -o d0 && ./d0      # siempre_mayor(INT_MAX) = 0
gcc -O2 desbordamiento.c -o d2 && ./d2      # siempre_mayor(INT_MAX) = 1
gcc -O2 -S desbordamiento.c -o -            # siempre_mayor queda como: movl $1, %eax ; ret
ccomp desbordamiento.c -o dc && ./dc        # siempre_mayor(INT_MAX) = 0
```

En ISO C el desbordamiento es indefinido, por eso GCC puede dar 0 o 1. CompCert C lo define como aritmética módulo 2^32, por eso siempre da 0.

### 3. Intérprete de CompCert

```bash
ccomp -interp fuera_de_limites.c
```

```
Stuck state: in function main, expression <loc s> += <loc a+16>
Stuck subexpression: <loc a+16>
ERROR: Undefined behavior
```

Compilado con `gcc`, el mismo programa imprime un valor que cambia entre ejecuciones.

### 4. Lenguajes intermedios de CompCert

```bash
ccomp -dclight -drtl -dltl -dmach -dasm -c suma.c
ls suma.*        # suma.light.c  suma.rtl.0 ... suma.rtl.8  suma.ltl  suma.mach  suma.s
ccomp suma.c -o suma && ./suma      # suma_cuadrados(10) = 385
```

Al enlazar con `ccomp`, el enlazador de Linux puede mostrar el aviso `missing .note.GNU-stack section`; no afecta la ejecución.
