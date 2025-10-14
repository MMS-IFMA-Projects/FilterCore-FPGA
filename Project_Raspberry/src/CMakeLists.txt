#Caminhos para as pastas includes
# set(COMPONENTS_PATH ${CMAKE_CURRENT_LIST_DIR}/../inc/components)
# set(PROTOCOLS_PATH ${CMAKE_CURRENT_LIST_DIR}/../inc/protocols)
# set(TASKS_PATH ${CMAKE_CURRENT_LIST_DIR}/../inc/tasks)

# Agrupamento de fontes por componente
#ANALOGIC
# set(ADC_PROTOCOL_SOURCES
#     ${CMAKE_CURRENT_LIST_DIR}/protocols/adc/adc_configs.c
# )

# set(ANALOG_COMPONENT_SOURCES
#     ${CMAKE_CURRENT_LIST_DIR}/components/analog/guvas12.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/analog/mq135.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/analog/soil_moisture.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/analog/joystick.c
# )

#DIGITAL
# set(DIGITAL_COMPONENT_SOURCES
#     ${CMAKE_CURRENT_LIST_DIR}/components/digital/buttons.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/digital/water_level.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/digital/water_pump.c
# )

#I2C
# set(I2C_PROTOCOL_SOURCES
#     ${CMAKE_CURRENT_LIST_DIR}/protocols/i2c/i2c_configs.c
# )

# set(I2C_COMPONENT_SOURCES
#     ${CMAKE_CURRENT_LIST_DIR}/components/i2c/ads1115.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/i2c/aht10.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/i2c/tsl2591.c
# )

#PWM
# set(PWM_COMPONENT_SOURCES
#     ${CMAKE_CURRENT_LIST_DIR}/components/pwm/buzzer.c
#     ${CMAKE_CURRENT_LIST_DIR}/components/pwm/rgb.c
# )

# Agrupando de fontes por tarefas
# set(TASK_SOURCES
#     ${CMAKE_CURRENT_LIST_DIR}/tasks/task_dig_water_level.c
#     ${CMAKE_CURRENT_LIST_DIR}/tasks/task_i2c_analogs.c 
#     ${CMAKE_CURRENT_LIST_DIR}/tasks/task_i2c_brightness.c 
#     ${CMAKE_CURRENT_LIST_DIR}/tasks/task_i2c_temperature_rh.c
# )

add_executable(filtercore
    main.c
    # ${I2C_PROTOCOL_SOURCES}
    # ${I2C_COMPONENT_SOURCES}
    # ${ADC_PROTOCOL_SOURCES}
    # ${ANALOG_COMPONENT_SOURCES}
    # ${DIGITAL_COMPONENT_SOURCES}
    # ${PWM_COMPONENT_SOURCES}
    # ${TASK_SOURCES}
)

# Corrige a saída para build/ em vez de build/src/
set_target_properties(filtercore PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

target_sources(filtercore PRIVATE
    ${FREERTOS_KERNEL_PATH}/portable/MemMang/heap_4.c
)

target_include_directories(filtercore PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_LIST_DIR}/../lib
    # ${PROTOCOLS_PATH}/i2c
    # ${COMPONENTS_PATH}/i2c
    # ${PROTOCOLS_PATH}/adc
    # ${COMPONENTS_PATH}/analog
    # ${COMPONENTS_PATH}/digital
    # ${COMPONENTS_PATH}/pwm
    # ${TASKS_PATH}     
)

target_link_libraries(filtercore 
    pico_stdlib 
    FreeRTOS-Kernel
    hardware_i2c
    hardware_adc
    hardware_dma
    hardware_pwm
    hardware_clocks
)

pico_add_extra_outputs(filtercore)
