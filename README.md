# A Odisseia do Assembly

**UC:** Arquitetura de Sistemas Computacionais · **Grupo:** _(João Duarte Bacalhau Pombeiro / nº mecanográfico: 93424)_ _(Manuel Augusto Valente Liendo / nº mecanográfico: 126949)_ _(Abelirio Augusto Galvão Rocha / nº mecanográfico: 142185)_

## Compilar e executar
```
gcc motor.s -o motor        # em máquina de 64 bits: gcc -m32 -no-pie motor.s -o motor
gdb ./motor                 # break no ret de main, run, e depois:
print (int)conta_positivos
print (int)conta_negativos
print (int)conta_zeros
```

## Base do Milestone 1
O contentor (8 posições `.long`, inteiros de 32 bits com sinal), a soma de 64 bits com `cltd` + `addl`/`adcl` e o indicador `excede_32` mantêm-se igual. O código novo foi **acrescentado** depois da soma, sem reescrever o contentor nem a rotina existente.

## Novo comportamento
- **Contadores:** `conta_positivos`, `conta_negativos` e `conta_zeros` (`.long` em `.data`), postos a zero na inicialização.
- **Ciclo (anatomia da Aula 9):** inicialização (`%ecx = 0`, `%edx = $contentor`); condição de paragem `cmpl n_elementos, %ecx` + `jge fim_ciclo`; corpo; atualização (`addl $4, %edx`, `incl %ecx`); `jmp ciclo`.
- **Sem off-by-one:** usa-se `jge` e não `jg`. Com `i` a variar de 0 a 7, o ciclo sai quando `i = 8`; com `jg` faria uma 9.ª iteração, fora do contentor.
- **Terminação garantida:** `%ecx` aumenta 1 em cada iteração e o teste está no topo do ciclo, por isso termina sempre (com `n_elementos = 0` nem entra).
- **Classificação (padrão if-then-else da Aula 8):** `cmpl $0, %eax` → `jle senao_positivo` → ramo then (`incl conta_positivos`) → `jmp fim_if`. No ramo else, um segundo if-then-else separa zero (`jne senao_zero`) de negativo. Usam-se saltos **com sinal** (`jle`) porque os valores estão em C2; com `jbe` (sem sinal), −7 = 0xFFFFFFF9 seria contado como positivo.
- **Acesso ao elemento:** `%edx` guarda o endereço do elemento atual e `movl (%edx), %eax` lê-o. É a forma mais simples de o endereço variar dentro do ciclo, já que o endereçamento direto (rótulo fixo) acede sempre à mesma posição.

## Trace table (caso de teste)
Contentor: `2000000000, 1500000000, -7, 0, 42, -300, 1000000000, 25`

| It. | `%ecx` (i) | `%edx` | `%eax` | Saltos tomados | Ramo | pos | neg | zero |
|---|---|---|---|---|---|---|---|---|
| 1 | 0 | contentor+0 | 2000000000 | nenhum | positivo | 1 | 0 | 0 |
| 2 | 1 | contentor+4 | 1500000000 | nenhum | positivo | 2 | 0 | 0 |
| 3 | 2 | contentor+8 | −7 | `jle`, `jne` | negativo | 2 | 1 | 0 |
| 4 | 3 | contentor+12 | 0 | `jle` | zero | 2 | 1 | 1 |
| 5 | 4 | contentor+16 | 42 | nenhum | positivo | 3 | 1 | 1 |
| 6 | 5 | contentor+20 | −300 | `jle`, `jne` | negativo | 3 | 2 | 1 |
| 7 | 6 | contentor+24 | 1000000000 | nenhum | positivo | 4 | 2 | 1 |
| 8 | 7 | contentor+28 | 25 | nenhum | positivo | 5 | 2 | 1 |
| — | 8 | contentor+32 | — | `jge` (sai) | — | 5 | 2 | 1 |

Valores confirmados no gdb (breakpoints em `ciclo`, `senao_positivo`, `senao_zero` e `fim_if`).

**Resultado final:** positivos = 5, negativos = 2, zeros = 1 (total 8 = `n_elementos` ✔). A soma do Milestone 1 mantém-se: 4 499 999 760, `excede_32` = 1.

**Testes de limite:** com `n_elementos = 0` o ciclo não executa (contadores a 0); com `n_elementos = 1` processa só o primeiro elemento (positivos = 1).
