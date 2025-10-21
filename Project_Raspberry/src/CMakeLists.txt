#Caminhos para as pastas includes
set(COMPONENTS_PATH ${CMAKE_CURRENT_LIST_DIR}/../lib/components)
set(PROTOCOLS_PATH ${CMAKE_CURRENT_LIST_DIR}/../lib/protocols)
set(SCREENS_PATH ${CMAKE_CURRENT_LIST_DIR}/../lib/screens)
set(TASKS_PATH ${CMAKE_CURRENT_LIST_DIR}/../lib/tasks)

# Agrupamento de fontes por componente
#ANALOGIC
set(ANALOG_COMPONENT_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/components/analog/ds18b20.c
    ${CMAKE_CURRENT_LIST_DIR}/components/analog/ph4502c.c
    ${CMAKE_CURRENT_LIST_DIR}/components/analog/tds_meter.c
)

#DIGITAL
set(DIGITAL_COMPONENT_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/components/digital/buttons.c
)

#I2C
set(I2C_PROTOCOL_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/protocols/i2c/i2c_configs.c
)

set(I2C_COMPONENT_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/components/i2c/ads1115.c
)

#OLED
set(OLED_COMPONENT_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/components/oled/oled_display.c
    ${CMAKE_CURRENT_LIST_DIR}/components/oled/oled_environment.c
    ${CMAKE_CURRENT_LIST_DIR}/components/oled/oled_prints.c
    ${CMAKE_CURRENT_LIST_DIR}/components/oled/ssd1306_text.c
)

#Agrupando telas para o OLED
set(SCREENS_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/screens/default_screen.c
    ${CMAKE_CURRENT_LIST_DIR}/screens/ph_screen.c
    ${CMAKE_CURRENT_LIST_DIR}/screens/tds_screen.c
    ${CMAKE_CURRENT_LIST_DIR}/screens/temperature_screen.c
    ${CMAKE_CURRENT_LIST_DIR}/screens/notifications_screen.c
)

#Agrupando de fontes por tarefas
set(TASK_SOURCES
    ${CMAKE_CURRENT_LIST_DIR}/tasks/task_display.c
)

add_executable(filtercore
    main.c
    ${I2C_PROTOCOL_SOURCES}
    ${I2C_COMPONENT_SOURCES}
    ${ANALOG_COMPONENT_SOURCES}
    ${DIGITAL_COMPONENT_SOURCES}
    ${OLED_COMPONENT_SOURCES}
    ${SCREEN_SOURCES}
    ${TASK_SOURCES}
)

# Corrige a saída para build/ em vez de build/src/
set_target_properties(filtercore PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

target_sources(filtercore PRIVATE
    ${FREERTOS_KERNEL_PATH}/portable/MemMang/heap_4.c
)

target_include_directories(filtercore PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_LIST_DIR}/../lib
    ${PROTOCOLS_PATH}/i2c
    ${COMPONENTS_PATH}/i2c
    ${COMPONENTS_PATH}/analog
    ${COMPONENTS_PATH}/digital
    ${COMPONENTS_PATH}/oled
    ${COMPONENTS_PATH}/oled/fonts
    ${SCREENS_PATH}
    ${TASKS_PATH}     
)

target_link_libraries(filtercore 
    pico_stdlib
    pico_time 
    FreeRTOS-Kernel
    hardware_i2c
    hardware_adc
    hardware_dma
    hardware_pwm
    hardware_clocks
    hardware_gpio
)

pico_add_extra_outputs(filtercore)
