# A Odisseia do Assembly — Milestone 2: O Decisor

**UC:** Arquitetura de Sistemas Computacionais · **Grupo:** _(João Duarte Bacalhau Pombeiro / nº mecanográfico: 93424)_ _(Manuel Augusto Valente Liendo / nº mecanográfico: 126949)_ _(Abelirio Augusto Galvão Rocha / nº mecanográfico: 142185)_

> O Milestone 2 acrescenta a classificação por elemento ao código do Milestone 1 (secção "Milestone 2" no fim). O contentor e a soma do M1 não foram alterados.

## Compilar e executar
```
gcc motor.s -o motor        # em máquina de 64 bits: gcc -m32 -no-pie motor.s -o motor
./motor
```
O programa guarda o resultado em memória. Verifica-se com o gdb, parando na instrução `ret` de `main`:
```
gdb ./motor
(gdb) break *main+<offset do ret>      # ou: disas main, e break no endereço do ret
(gdb) run
(gdb) print (int)soma_baixa
(gdb) print (int)soma_alta
(gdb) print (int)excede_32
```

## Estrutura de dados
- `contentor`: 8 posições `.long` em `.data` (8 × 4 = 32 bytes), acedidas por endereçamento direto: o elemento *i* está em `contentor + 4·i`.
- `n_elementos`: número de posições do contentor (8).
- `soma_alta:soma_baixa`: resultado da soma em 64 bits (mesma convenção que EDX:EAX).
- `excede_32`: 0 se a soma cabe num inteiro de 32 bits com sinal; diferente de 0 caso contrário.

## Porquê `.long` (32 bits)?
O enunciado pede valores inteiros de 32 bits, e o contentor guarda valores positivos, negativos e zero, por isso os valores são tratados **com sinal** (complemento para 2). Um `.byte` só representaria −128 a 127 e um `.word` −32 768 a 32 767, o que é insuficiente. O `.long` dá a gama −2 147 483 648 a 2 147 483 647, coincide com a dimensão dos registos de uso geral (`%eax`…) e permite usar as instruções com sufixo `l` sem conversões.

## Soma e tratamento de overflow
A soma de 8 valores de 32 bits pode não caber em 32 bits. Por isso cada elemento é estendido com sinal para 64 bits com `cltd` (EDX:EAX) e acumulado com **`addl`** na parte baixa e **`adcl`** na parte alta, que soma também a Carry Flag e propaga o transporte. Como `mov` e `cltd` não alteram as flags, o CF produzido pelo `addl` chega intacto ao `adcl`. Com 64 bits a soma de 8 elementos nunca transborda.

No fim, a soma cabe em 32 bits se e só se a parte alta for igual à extensão de sinal da parte baixa: `cltd` sobre `soma_baixa` e `xorl` com `soma_alta` dá 0 nesse caso.

## Decisões
- Só se usa matéria das Aulas 1-6 (movimentação, aritmética e flags), por isso a soma está escrita elemento a elemento, com endereçamento direto.
- Os acumuladores são postos a zero explicitamente (`xorl` + `movl`) para a rotina estar correta mesmo que seja executada mais do que uma vez.
- Só se usam `%eax`/`%edx` (registos que `main` pode alterar livremente) e os resultados ficam em variáveis dedicadas em memória.

## Caso de teste
Contentor: `2000000000, 1500000000, -7, 0, 42, -300, 1000000000, 25`

| Variável | Valor obtido (gdb) |
|---|---|
| `soma_baixa` | 0x0C388C10 |
| `soma_alta` | 1 |
| soma (64 bits) | 4 499 999 760 ✔ |
| `excede_32` | 1 (não cabe em 32 bits) ✔ |

Teste extra (substituindo os valores grandes por −5, −10 e 3): soma = −252, `soma_alta` = −1 (0xFFFFFFFF), `excede_32` = 0 ✔.

---

# Milestone 2 — O Decisor

## Novo comportamento
Depois da soma (M1), o motor percorre o contentor e classifica cada elemento como **positivo**, **negativo** ou **zero**, acumulando três contadores em memória: `n_positivos`, `n_negativos` e `n_zeros`. Verificam-se com o gdb no `ret` de `main`, como no M1 (`print (int)n_positivos`, etc.).

## Classificação (if-then-else, Aula 8)
```
cmpl $0, %eax        # flags de eax - 0
jl   e_negativo      # eax < 0  -> negativo
jg   e_positivo      # eax > 0  -> positivo
incl n_zeros         # senão (eax == 0) -> zero
jmp  proximo
```
- Usam-se `jl`/`jg` (comparação **com sinal**), coerente com o M1, onde os valores são inteiros com sinal. `jb`/`ja` (sem sinal) classificariam os negativos como positivos enormes.
- Um único `cmpl` serve para os dois saltos: nenhuma instrução entre eles altera as flags. O zero é o caso restante, sem teste extra.
- Cada ramo termina com `jmp proximo` para não "cair" no ramo seguinte.

## Ciclo (Aula 9)
- `%esi` aponta para o elemento atual (começa em `contentor`, avança 4 bytes por volta); `%ecx` conta os elementos por processar (começa em `n_elementos`).
- O teste é feito **no início** (`cmpl $0,%ecx` / `je fim_ciclo`), por isso termina sempre: `%ecx` decresce 1 por volta até 0 e, com `n_elementos = 0`, o corpo nem chega a executar. Sem off-by-one: o ciclo corre exatamente `n_elementos` vezes.
- Integração com o M1: o contentor, `n_elementos` e a soma são reutilizados sem alterações; só se acrescentaram os contadores e o ciclo. O acesso é por ponteiro (`(%esi)`); o endereçamento indexado fica para o M3.

## Trace table
Contentor do M1: `2000000000, 1500000000, -7, 0, 42, -300, 1000000000, 25`

| Volta | %ecx (antes) | Elemento | cmpl $0 → salto | Ramo | n_positivos | n_negativos | n_zeros |
|---|---|---|---|---|---|---|---|
| início | 8 | — | — | — | 0 | 0 | 0 |
| 1 | 8 | 2000000000 | jg | positivo | 1 | 0 | 0 |
| 2 | 7 | 1500000000 | jg | positivo | 2 | 0 | 0 |
| 3 | 6 | -7 | jl | negativo | 2 | 1 | 0 |
| 4 | 5 | 0 | nenhum (ZF=1) | zero | 2 | 1 | 1 |
| 5 | 4 | 42 | jg | positivo | 3 | 1 | 1 |
| 6 | 3 | -300 | jl | negativo | 3 | 2 | 1 |
| 7 | 2 | 1000000000 | jg | positivo | 4 | 2 | 1 |
| 8 | 1 | 25 | jg | positivo | 5 | 2 | 1 |
| fim | 0 | — | je fim_ciclo | sai | **5** | **2** | **1** |

Verificação: 5 + 2 + 1 = 8 = `n_elementos` ✔
