# FilterCore FPGA
- Módulo FPGA: ECP5 LFE5U-45 colorlight i9
- Linguagem: System Verilog
------------------------------------------------------------
# Autores:
- Davi Santos Rodrigues
- Jesiniel Martins Pimenta Júnior;
- Mayron Martins da Silva;
------------------------------------------------------------
Este módulo contempla a implementação do controle de aciona-
mento do sistema de filtragem a partir dos dados digitais
dos sensores de medição analógica.

#Funcionalidades:
- Acionamento automático do sistema de filtragem.
- Acionamento manual do sistema de filtragem.

# Etapas de implementação
1. Sincronização de clock
    - Mantém um mesmo clock para Raspberry Pi Pico W e o FPGA.
2. Acionamento automático de sistema de filtragem
    - Detecção dos estados dos sensores analógicos;
    - Definição de criticidade para acionamento de bomba A;
    - Acionamento da FILTRAGEM DA ÁGUA.
3. Filtragem da água 
    - Verificação de criticidade para acionamento de bomba A;
    - Acionamento com potência máxima de bomba A mediante PWM (filtro A);
    - Detecção de estado do sensor de nível de água (filtro B);
    - Acionamento com potência mínima da bomba B mediante PWM;
    - Tempo para estabilização da filtragem 
    - Reduzação da potência da bomba A;
    - Incremento da potência da bomba B;
4. Acionamento manual de sistema de filtragem
    - Verificação de estado do botão A;
    - Verificação de estado atual de filtragem;
    - Ativação/desativação de FILTRAGEM DA ÁGUA;


