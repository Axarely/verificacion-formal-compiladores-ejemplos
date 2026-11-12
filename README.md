# Verificación formal de compiladores: ejemplos de demostración

Ejemplos de la demostración técnica de la investigación *Verificación formal de compiladores: el caso CompCert* (IS-158 Compiladores e Intérpretes, III cuatrimestre 2026).

| Parte | Archivos | Qué demuestra |
|---|---|---|
| 1. Minicompilador verificado | `MiniCompilador.v` | Preservación semántica, composición de pruebas e imposibilidad de demostrar una optimización incorrecta. |
| 2. Comportamiento indefinido | `desbordamiento.c`, `fuera_de_limites.c` | Dependencia de la corrección respecto a la semántica: GCC y CompCert ante un desbordamiento, y el intérprete de CompCert ante un acceso fuera de un arreglo. |
| 3. Cadena de CompCert | `suma.c` | Lenguajes intermedios y pasadas verificadas de CompCert. |

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

### Parte 1. Minicompilador verificado

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

### Parte 2. Comportamiento indefinido

**a) Desbordamiento de enteros (`desbordamiento.c`)**

```bash
gcc -O0 desbordamiento.c -o d0 && ./d0      # siempre_mayor(INT_MAX) = 0
gcc -O2 desbordamiento.c -o d2 && ./d2      # siempre_mayor(INT_MAX) = 1
gcc -O2 -S desbordamiento.c -o -            # siempre_mayor queda como: movl $1, %eax ; ret
ccomp desbordamiento.c -o dc && ./dc        # siempre_mayor(INT_MAX) = 0
```

En ISO C el desbordamiento es indefinido, por eso GCC puede dar 0 o 1. CompCert C lo define como aritmética módulo 2^32, por eso siempre da 0.

**b) Acceso fuera de un arreglo con el intérprete de CompCert (`fuera_de_limites.c`)**

```bash
ccomp -interp fuera_de_limites.c
```

```
Stuck state: in function main, expression <loc s> += <loc a+16>
Stuck subexpression: <loc a+16>
ERROR: Undefined behavior
```

Compilado con `gcc`, el mismo programa imprime un valor que cambia entre ejecuciones.

### Parte 3. Cadena de CompCert

```bash
ccomp -dclight -drtl -dltl -dmach -dasm -c suma.c
ls suma.*        # suma.light.c  suma.rtl.0 ... suma.rtl.8  suma.ltl  suma.mach  suma.s
ccomp suma.c -o suma && ./suma      # suma_cuadrados(10) = 385
```

Al enlazar con `ccomp`, el enlazador de Linux puede mostrar el aviso `missing .note.GNU-stack section`; no afecta la ejecución.
