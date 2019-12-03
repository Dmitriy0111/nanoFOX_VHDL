/*
*  File            :   nf_gpio.h
*  Autor           :   Vlasov D.V.
*  Data            :   2019.02.25
*  Language        :   C
*  Description     :   This is constants for working with GPIO
*  Copyright(c)    :   2018 - 2019 Vlasov D.V.
*/

// GPIO registers addr
#define     NF_GPIO_GPI_ADDR    0x00020000
#define     NF_GPIO_GPO_ADDR    0x00020004
#define     NF_GPIO_GPD_ADDR    0x00020008
#define     NF_GPIO_EN_ADDR     0x0002000C
// GPIO registers
#define     NF_GPIO_GPI         (* (volatile unsigned *) NF_GPIO_GPI_ADDR )
#define     NF_GPIO_GPO         (* (volatile unsigned *) NF_GPIO_GPO_ADDR )
#define     NF_GPIO_GPD         (* (volatile unsigned *) NF_GPIO_GPD_ADDR )
#define     NF_GPIO_EN          (* (volatile unsigned *) NF_GPIO_EN_ADDR  )
