(* ================================================================
   MiniCompilador.v
   Un compilador verificado "de juguete", en el espiritu de
   McCarthy y Painter (1967) y de CompCert.
   Fuente : expresiones aritmeticas con variables.
   Destino: una maquina de pila.
   Compila con Coq 8.18+ y con The Rocq Prover 9.x:
       coqc MiniCompilador.v
   ================================================================ *)

From Coq Require Import Arith List Lia.
Import ListNotations.

(* ---------- 1. Lenguaje fuente y su semantica ---------- *)

Inductive expr : Type :=
  | Const : nat -> expr
  | Var   : nat -> expr            (* variable identificada por indice *)
  | Plus  : expr -> expr -> expr
  | Minus : expr -> expr -> expr   (* resta truncada de nat *)
  | Mult  : expr -> expr -> expr.

Definition env := nat -> nat.      (* valor de cada variable *)

Fixpoint eval (rho : env) (e : expr) : nat :=
  match e with
  | Const n     => n
  | Var x       => rho x
  | Plus a b    => eval rho a + eval rho b
  | Minus a b   => eval rho a - eval rho b
  | Mult a b    => eval rho a * eval rho b
  end.

(* ---------- 2. Lenguaje destino: maquina de pila ---------- *)

Inductive instr : Type :=
  | IPush : nat -> instr
  | ILoad : nat -> instr
  | IAdd  | ISub | IMul.

Definition code  := list instr.
Definition stack := list nat.

(* Un paso de la maquina; None representa un error de ejecucion
   (pila insuficiente). *)
Definition step (rho : env) (i : instr) (s : stack) : option stack :=
  match i, s with
  | IPush n, _          => Some (n :: s)
  | ILoad x, _          => Some (rho x :: s)
  | IAdd, b :: a :: s'  => Some (a + b :: s')
  | ISub, b :: a :: s'  => Some (a - b :: s')
  | IMul, b :: a :: s'  => Some (a * b :: s')
  | _, _                => None
  end.

Fixpoint exec (rho : env) (c : code) (s : stack) : option stack :=
  match c with
  | []      => Some s
  | i :: c' => match step rho i s with
               | Some s' => exec rho c' s'
               | None    => None
               end
  end.

(* ---------- 3. El compilador ---------- *)

Fixpoint compile (e : expr) : code :=
  match e with
  | Const n   => [IPush n]
  | Var x     => [ILoad x]
  | Plus a b  => compile a ++ compile b ++ [IAdd]
  | Minus a b => compile a ++ compile b ++ [ISub]
  | Mult a b  => compile a ++ compile b ++ [IMul]
  end.

(* ---------- 4. Teorema de correccion ---------- *)

(* Lema generalizado: ejecutar el codigo de e seguido de cualquier
   continuacion k equivale a apilar el valor de e y seguir con k.
   Esta generalizacion es la que hace funcionar la induccion. *)
Lemma compile_correct_gen :
  forall rho e k s,
    exec rho (compile e ++ k) s = exec rho k (eval rho e :: s).
Proof.
  intros rho e.
  induction e as [n | x | a IHa b IHb | a IHa b IHb | a IHa b IHb];
    intros k s; simpl; try reflexivity;
    rewrite <- !app_assoc, IHa, IHb; reflexivity.
Qed.

(* Teorema principal: el codigo compilado deja exactamente el valor
   de la expresion fuente en la cima de la pila. *)
Theorem compile_correct :
  forall rho e, exec rho (compile e) [] = Some [eval rho e].
Proof.
  intros rho e.
  rewrite <- (app_nil_r (compile e)).
  rewrite compile_correct_gen. reflexivity.
Qed.

(* ---------- 5. Una optimizacion verificada: plegado de constantes ---------- *)

Fixpoint cfold (e : expr) : expr :=
  match e with
  | Plus a b =>
      match cfold a, cfold b with
      | Const n, Const m => Const (n + m)
      | a', Const 0      => a'            (* e + 0  ==>  e *)
      | a', b'           => Plus a' b'
      end
  | Minus a b =>
      match cfold a, cfold b with
      | Const n, Const m => Const (n - m)
      | a', b'           => Minus a' b'
      end
  | Mult a b =>
      match cfold a, cfold b with
      | Const n, Const m => Const (n * m)
      | a', b'           => Mult a' b'
      end
  | _ => e
  end.

Theorem cfold_correct : forall rho e, eval rho (cfold e) = eval rho e.
Proof.
  intros rho e.
  induction e as [n | x | a IHa b IHb | a IHa b IHb | a IHa b IHb];
    simpl; try reflexivity;
    destruct (cfold a) eqn:Ea; destruct (cfold b) eqn:Eb;
    simpl in *; rewrite <- IHa, <- IHb; try reflexivity;
    try (destruct n; simpl; lia); try (destruct n0; simpl; lia).
Qed.

(* Correccion de la cadena completa: optimizar y luego compilar. *)
Theorem pipeline_correct :
  forall rho e, exec rho (compile (cfold e)) [] = Some [eval rho e].
Proof.
  intros. rewrite compile_correct, cfold_correct. reflexivity.
Qed.

(* ---------- 6. Una "optimizacion" incorrecta ---------- *)

(* Intercambiar operandos es valido para + y *, pero no para -.
   Un desarrollador apresurado podria aplicarlo a todo. *)
Fixpoint swap (e : expr) : expr :=
  match e with
  | Plus a b  => Plus  (swap b) (swap a)
  | Minus a b => Minus (swap b) (swap a)   (* error deliberado *)
  | Mult a b  => Mult  (swap b) (swap a)
  | _ => e
  end.

(* El intento de probar  eval (swap e) = eval e  se queda atascado en
   el caso Minus. Coq no deja cerrar la prueba; en su lugar podemos
   demostrar que existe un contraejemplo concreto: *)
Example swap_incorrecto :
  exists rho e, eval rho (swap e) <> eval rho e.
Proof.
  exists (fun _ => 0), (Minus (Const 5) (Const 2)).
  simpl. discriminate.
Qed.

(* ---------- 7. Ejecucion de prueba ---------- *)

Definition rho0 : env := fun x => match x with 0 => 7 | 1 => 3 | _ => 0 end.
(* (x0 + 3) * (x1 - 1) con x0 = 7, x1 = 3  ==>  10 * 2 = 20 *)
Definition ejemplo := Mult (Plus (Var 0) (Const 3)) (Minus (Var 1) (Const 1)).

Compute compile ejemplo.
Compute exec rho0 (compile ejemplo) [].
Compute cfold (Plus (Mult (Const 2) (Const 4)) (Var 0)).

(* Verificamos que ninguna prueba depende de axiomas adicionales. *)
Print Assumptions pipeline_correct.
