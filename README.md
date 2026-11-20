# A Odisseia do Assembly

**UC:** Arquitetura de Sistemas Computacionais · **Grupo:** _(João Duarte Bacalhau Pombeiro / nº mecanográfico: 93424)_ _(Manuel Augusto Valente Liendo / nº mecanográfico: 126949)_ _(Abelirio Augusto Galvão Rocha / nº mecanográfico: 142185)_

## Compilar e executar
```
gcc motor.s -o motor        # em máquina de 64 bits: gcc -m32 -no-pie motor.s -o motor
gdb ./motor                 # break no ret de main, run, e depois:
print (int)soma_baixa
print (int)soma_alta
print (int)excede_32
print (int)conta_positivos
print (int)conta_negativos
print (int)conta_zeros
```

## Base dos Milestones 1 e 2
O contentor (8 posições `.long`, inteiros de 32 bits com sinal), a soma de 64 bits com `cltd` + `addl`/`adcl`, o indicador `excede_32` e a classificação com o padrão if-then-else (saltos com sinal) mantêm-se. O Milestone 3 **não muda os resultados**, só a organização do código: a lógica passou para funções e o `main` passou a apenas chamá-las.

## Funções (Milestone 3)
Todas têm stack frame própria: prólogo `pushl %ebp` / `movl %esp, %ebp` e epílogo `movl %ebp, %esp` / `popl %ebp` / `ret`. O parâmetro é passado **pela pilha** e lido em `8(%ebp)`.

| Função | Parâmetro (`8(%ebp)`) | Faz | Devolve |
|---|---|---|---|
| `obter_elemento(indice)` | índice *i* | lê `contentor(,%ecx,4)` | `%eax` = contentor[*i*] |
| `somar_elemento(valor)` | valor | `cltd` + `addl`/`adcl` em `soma_alta:soma_baixa` (código do M1) | — |
| `classificar(valor)` | valor | if-then-else com `jle`/`jne` e incrementa o contador (código do M2) | — |

- **Convenção (cdecl):** quem chama faz `pushl` do parâmetro, `call` e depois `addl $4, %esp` para retirar o parâmetro. O `%esp` fica igual ao que era antes da chamada.
- **Endereçamento indexado:** `contentor(,%ecx,4)` = `contentor + i·4`. O fator de escala 4 é o tamanho de um `.long`. É o **único** sítio onde o contentor é lido: desapareceram os rótulos fixos `contentor+4`…`contentor+28` do M1 e o ponteiro `(%edx)` do M2.
- **Registos:** as funções podem alterar `%eax`, `%ecx` e `%edx` (o `cltd` escreve em `%edx`). Por isso o `main` guarda o índice em `%ebx` e o valor em `%esi`, que as funções não alteram. Como `%ebx` e `%esi` são callee-saved, o `main` também tem prólogo/epílogo e guarda-os com `pushl`/`popl`.

## Redução de duplicação
| Antes (M2) | Agora (M3) |
|---|---|
| soma = 8 blocos copiados (`movl contentor+N` / `cltd` / `addl` / `adcl`) | 1 bloco em `somar_elemento`, chamado no ciclo |
| 2 percursos do contentor (soma em linha + ciclo de classificação) | 1 só ciclo: `obter_elemento` → `somar_elemento` → `classificar` |
| a soma só funcionava para 8 elementos | basta mudar `n_elementos` (testado com 0 e 1) |

## Estado da pilha durante uma chamada
Chamada `obter_elemento(3)` (4.ª volta do ciclo), depois do prólogo da função:
```
 endereços altos
 ┌────────────────────────────┐
 │ endereço de retorno (libc) │  ← 4(%ebp de main)
 ├────────────────────────────┤
 │ %ebp antigo (libc)         │  ← %ebp de main
 ├────────────────────────────┤
 │ %ebx antigo                │  -4(%ebp de main)   push do prólogo de main
 ├────────────────────────────┤
 │ %esi antigo                │  -8(%ebp de main)
 ├────────────────────────────┤
 │ 3  (parâmetro indice)      │  8(%ebp)   ← pushl %ebx
 ├────────────────────────────┤
 │ endereço de retorno (main) │  4(%ebp)   ← call obter_elemento
 ├────────────────────────────┤
 │ %ebp de main               │  0(%ebp)   ← pushl %ebp   ◄── %ebp = %esp
 └────────────────────────────┘
 endereços baixos (a pilha cresce para baixo)
```
No epílogo, `movl %ebp, %esp` e `popl %ebp` repõem o `%ebp` de `main`, e o `ret` tira o endereço de retorno. De volta ao `main`, `addl $4, %esp` retira o parâmetro e a pilha fica como estava antes do `pushl %ebx`.

## Resultados (caso de teste)
Contentor: `2000000000, 1500000000, -7, 0, 42, -300, 1000000000, 25`

| Variável | Valor |
|---|---|
| soma (64 bits) | 4 499 999 760 (`soma_alta` = 1, `soma_baixa` = 0x0C388C10) |
| `excede_32` | ≠ 0 (não cabe em 32 bits) |
| positivos / negativos / zeros | 5 / 2 / 1 (total 8 = `n_elementos` ✔) |

São os mesmos valores do Milestone 2. Também se testou `n_elementos = 0` (tudo a 0) e `n_elementos = 1` (soma = 2 000 000 000, positivos = 1).
