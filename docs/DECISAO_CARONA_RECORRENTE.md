# Decisão: carona recorrente

“Carona recorrente” significa uma série semanal, com um ou mais dias da semana,
horário e primeira ocorrência futura. O padrão continua sendo carona única.

- O feed exibe a próxima ocorrência da série.
- Após o horário, o backend avança a série para o próximo dia configurado.
- A série fica ativa até o motorista cancelá-la; pausa e edição usam o fluxo de
  manutenção da oferta existente.
- Filtros de data consideram a próxima ocorrência, e não a data original.
- A numeração dos dias segue ISO-8601: segunda-feira é 1 e domingo é 7.

