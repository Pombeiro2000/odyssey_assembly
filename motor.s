# =====================================================================
#  A ODISSEIA DO ASSEMBLY — Milestone 2: O Decisor
#  ASC · ESTGA / Universidade de Aveiro
#  Sintaxe AT&T (GAS), IA-32.  Compilar: gcc -m32 -no-pie motor.s -o motor
#
#  M1: soma os 8 elementos do contentor num acumulador de 64 bits.
#  M2: classifica cada elemento (positivo / negativo / zero) num ciclo.
# =====================================================================

        .data

# ===================== DADOS DO MILESTONE 1 ==========================
# Contentor: 8 inteiros de 32 bits com sinal (elemento i em contentor+4*i)
contentor:
        .long  2000000000, 1500000000, -7, 0, 42, -300, 1000000000, 25

n_elementos:
        .long  8

# Soma em 64 bits = soma_alta:soma_baixa (como EDX:EAX)
soma_baixa:
        .long  0
soma_alta:
        .long  0
excede_32:
        .long  0                    # 0 = a soma cabe em 32 bits com sinal

# ===================== DADOS DO MILESTONE 2 ==========================
# Contadores (no fim: soma dos tres = n_elementos)
n_positivos:
        .long  0
n_negativos:
        .long  0
n_zeros:
        .long  0

        .text
        .globl main

main:
        xorl   %eax, %eax           # poe acumuladores a 0 (rotina repetivel)
        movl   %eax, soma_baixa
        movl   %eax, soma_alta
        movl   %eax, excede_32

# =====================================================================
#  MILESTONE 1 — O CONTENTOR: soma total + verificacao de overflow
# =====================================================================
#  cltd estende o elemento com sinal para 64 bits (edx:eax);
#  addl soma a parte baixa e adcl a alta + carry (CF).
#  mov e cltd nao alteram flags, logo o CF chega intacto ao adcl.
# ---------------------------------------------------------------------
        movl   contentor, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        movl   contentor+4, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        movl   contentor+8, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        movl   contentor+12, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        movl   contentor+16, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        movl   contentor+20, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        movl   contentor+24, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

        movl   contentor+28, %eax
        cltd
        addl   %eax, soma_baixa
        adcl   %edx, soma_alta

# Overflow: a soma cabe em 32 bits se soma_alta == extensao de sinal de soma_baixa
        movl   soma_baixa, %eax
        cltd
        xorl   soma_alta, %edx      # 0 se forem iguais
        movl   %edx, excede_32

# =====================================================================
#  MILESTONE 2 — O DECISOR: ciclo que classifica cada elemento
#  (reutiliza o contentor e n_elementos do Milestone 1)
# =====================================================================
#  %esi = ponteiro para o elemento atual, %ecx = elementos em falta.
#  Teste no inicio: termina sempre (ecx desce ate 0) e nao entra se n = 0.
# ---------------------------------------------------------------------
        xorl   %eax, %eax
        movl   %eax, n_positivos
        movl   %eax, n_negativos
        movl   %eax, n_zeros
        movl   $contentor, %esi
        movl   n_elementos, %ecx

ciclo:
        cmpl   $0, %ecx
        je     fim_ciclo

        movl   (%esi), %eax         # elemento atual

        cmpl   $0, %eax             # as flags servem aos dois saltos seguintes
        jl     e_negativo           # saltos COM sinal (jl/jg), nao jb/ja
        jg     e_positivo
        incl   n_zeros              # nenhum salto -> zero
        jmp    proximo
e_positivo:
        incl   n_positivos
        jmp    proximo
e_negativo:
        incl   n_negativos

proximo:
        addl   $4, %esi             # proximo .long = +4 bytes
        decl   %ecx
        jmp    ciclo
fim_ciclo:

# ===================== FIM DO PROGRAMA ================================
        xorl   %eax, %eax           # main devolve 0
        ret

        .section .note.GNU-stack,"",@progbits
