# FilterCore FPGA
- Módulo Embarcado: BITDOGLAB com Raspberry Pi Pico W
- Linguagem: System Verilog
------------------------------------------------------------
# Autores:
- Davi Santos Rodrigues
- Jesiniel Martins Pimenta Júnior;
- Mayron Martins da Silva;
------------------------------------------------------------
Este módulo contempla a implementação da captação dos valo-
res de sensoriamento analógico mediante conversor ADC
ADS1115. Em acréscimo, possui visualização em display OLED
0.96" e controle de paginação com botão B.

#Funcionalidades:
- Obtenção de dados analógicos de sensores e conversão em 
estados digitais.
- Plotagem de valores em display OLED com paginação e con-
trole via botão B.
- Envio de dados de estados para FPGA

# Etapas de implementação
1. Captação de dados de sensores
    - Conexão I2C com ADS1115.
    - Definição de endereço e captação de dados em intervalo
    regular para cada sensor.
    - Conversão em estado digital a partir de criticidade;
    - Conversão para unidade de medida particular.
2. Plotagem de dados
    - Comunicação com display OLED via I2C;
    - Definição de páginas e conteúdo para cada uma;
    - Verificação de mudança de página e plotagem de conteúdo.
3. Envio de dados
    - Sincronização de clock com FPGA;
    - Envio dos estados digitais dos sensores analógicos;
    - Envio do estado do botão A;
