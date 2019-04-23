/*
*  File            :   nf_pars_instr.sv
*  Autor           :   Vlasov D.V.
*  Data            :   2018.11.23
*  Language        :   SystemVerilog
*  Description     :   This is class for parsing instruction from instruction memory
*  Copyright(c)    :   2018 - 2019 Vlasov D.V.
*/

`include "nf_tb.svh"
`include "../inc/nf_cpu.svh" 

import   NF_BTC::*;

class nf_pars_instr extends nf_bt_class;

    task instr_decode( instr_cf instr_cf_check, logic [31 : 0] instr, ref string instr_s, ref string instr_sep );

        // destination and sources registers
        bit     [4  : 0]    ra1       ;
        bit     [4  : 0]    ra2       ;
        bit     [4  : 0]    wa3       ;
        // immediate data
        bit     [19 : 0]    imm_data_u;
        bit     [11 : 0]    imm_data_i;
        bit     [11 : 0]    imm_data_b;
        bit     [11 : 0]    imm_data_s;
        bit     [19 : 0]    imm_data_j;
        // operation type fields
        bit     [1  : 0]    instr_type;
        bit     [4  : 0]    opcode    ;
        bit     [2  : 0]    funct3    ;
        bit     [6  : 0]    funct7    ;

        // destination and sources registers
        ra1         = instr[15 +: 5];
        ra2         = instr[20 +: 5];
        wa3         = instr[7  +: 5];
        // immediate data
        imm_data_u  = instr[12 +: 20];
        imm_data_i  = instr[20 +: 12];
        imm_data_b  = { instr[31] , instr[7] , instr[25 +: 6] , instr[8 +: 4] };
        imm_data_s  = { instr[25 +: 7] , instr[7 +: 5] };
        imm_data_j  = { instr[31] , instr[12 +: 8] , instr[20] , instr[21 +: 10] };
        // operation type fields
        instr_type  = instr[0  +: 2];
        opcode      = instr[0  +: 5];
        funct3      = instr[12 +: 3];
        funct7      = instr[25 +: 7];

        if( instr_cf_check.OP == 'b01100 ) 
        begin
            instr_s =   $psprintf("%s rd  = %4s, rs1 = %4s, rs2 = %4s"          , instr_cf_check.I_NAME , reg_list[wa3] , reg_list[ra1] , reg_list[ra2]                     );
            if( `debug_lev0 )
                instr_sep = $psprintf("R-type  : %b_%b_%b_%b_%b_%b_%b"          , funct7, ra2, ra1, funct3, wa3, opcode, instr_type                                         );
        end
        else if ( 
                    instr_cf_check.OP == 'b00100 ||
                    instr_cf_check.OP == 'b00000 ||
                    instr_cf_check.OP == 'b11001 
                ) 
        begin
            instr_s =   $psprintf("%s rd  = %4s, rs1 = %4s, Imm = 0x%h"         , instr_cf_check.I_NAME , reg_list[wa3] , reg_list[ra1] , imm_data_i                        );
            if( `debug_lev0 )
                instr_sep = $psprintf("I-type  : %b_%b_%b_%b_%b_%b"             , instr[20 +: 12], ra1, funct3, wa3, opcode, instr_type                                     );
        end
        else if ( instr_cf_check.OP == 'b11000 ) 
        begin
            instr_s =   $psprintf("%s rs1 = %4s, rs2 = %4s, Imm = 0x%h"         , instr_cf_check.I_NAME , reg_list[ra1] , reg_list[ra2] , imm_data_b                        );
            if( `debug_lev0 )
                instr_sep = $psprintf("B-type  : %b_%b_%b_%b_%b_%b_%b_%b_%b"    , instr[31], instr[25 +: 6], ra2, ra1, funct3, instr[8  +: 5], instr[7], opcode, instr_type );
        end
        else if ( instr_cf_check.OP == 'b01000 ) 
        begin
            instr_s =   $psprintf("%s rs1 = %4s, rs2 = %4s, Imm = 0x%h"         , instr_cf_check.I_NAME , reg_list[ra1] , reg_list[ra2] , imm_data_s                        );
            if( `debug_lev0 )
                instr_sep = $psprintf("S-type  : %b_%b_%b_%b_%b_%b_%b"          , instr[25 +: 7], ra2, ra1, funct3, instr[7  +: 5], opcode, instr_type                      );
        end
        else if ( 
                    instr_cf_check.OP == 'b01101 ||
                    instr_cf_check.OP == 'b00101 
                ) 
        begin
            instr_s =   $psprintf("%s rd  = %4s, Imm = 0x%h"                    , instr_cf_check.I_NAME , reg_list[wa3] , imm_data_u                                        );
            if( `debug_lev0 )
                instr_sep = $psprintf("U-type  : %b_%b_%b_%b"                   , instr[12 +: 20], wa3, opcode, instr_type                                                  );
        end
        else if ( instr_cf_check.OP == 'b11011 ) 
        begin
            instr_s =   $psprintf("%s rd  = %4s, Imm = 0x%h"                    , instr_cf_check.I_NAME , reg_list[wa3] , imm_data_j                                        );
            if( `debug_lev0 )
                instr_sep = $psprintf("J-type  : %b_%b_%b_%b_%b_%b_%b"          , instr[31], instr[21 +: 10], instr[20], instr[12 +: 8], wa3, opcode, instr_type            );
        end

    endtask : instr_decode

    instr_cf instr_cf_0;

    instr_cf i_list [] = 
                        {
                            LUI,   
                            AUIPC, 
                            JAL,   
                            JALR,  
                            BEQ,   
                            BNE,   
                            BLT,   
                            BGE,   
                            BLTU,  
                            BGEU,  
                            LB,    
                            LH,    
                            LW,    
                            LBU,   
                            LHU,   
                            SB,    
                            SH,    
                            SW,    
                            ADDI,  
                            SLTI,  
                            SLTIU, 
                            XORI,  
                            ORI,   
                            ANDI,  
                            SLLI,  
                            SRLI,  
                            SRAI,  
                            ADD,   
                            SUB,   
                            SLL,   
                            SLT,   
                            SLTU,  
                            XOR,   
                            SRL,   
                            SRA,   
                            OR,    
                            AND   
                        };

    function new();
        $timeformat(-9, 2, " ns", 7);
    endfunction : new

    task pars(logic [31 : 0] instr, ref string instruction_s, ref string instr_sep);

        // operation type fields
        logic   [1  : 0]    instr_type;
        logic   [4  : 0]    opcode    ;
        logic   [2  : 0]    funct3    ;
        logic   [6  : 0]    funct7    ;
        // operation type fields
        instr_type  = instr[0  +: 2];
        opcode      = instr[2  +: 5];
        funct3      = instr[12 +: 3];
        funct7      = instr[25 +: 7];
        instruction_s = "";
        instr_sep     = "";

        instr_cf_0 = { "",instr_type , opcode , funct3 , funct7 };
        casex( instr_cf_0.IT )
            `RVI    :
            begin
                foreach( i_list[i] )
                begin
                    instr_cf_0.I_NAME = i_list[i].I_NAME;
                    casex( instr_cf_0 )
                        i_list[i] : 
                            instr_decode( instr_cf_0 , instr , instruction_s , instr_sep );
                    endcase
                end
                
                instruction_s = {"RVI " , instruction_s};
            end
            `RVC_0  : instruction_s = {"RVC_0"};
            `RVC_1  : instruction_s = {"RVC_1"};
            `RVC_2  : instruction_s = {"RVC_2"};
        endcase

        if( $isunknown(instr) || ( ( instruction_s == "" ) && ( instr != '0 ) ) )
            instruction_s = $psprintf("ERROR! Unknown instruction = %b", instr  );
        else if( instr == '0 )
            instruction_s = $psprintf("Flushed instruction",                    );
        
        if( `debug_lev0 )
        begin
            if( $isunknown(instr) || ( ( instruction_s == "" ) && ( instr != '0 ) ) )
                instr_sep = $psprintf("ERROR! Unknown instruction = %b", instr );
            else if( instr == '0 )
                instr_sep = $psprintf("Flushed : %b", instr );
        end

    endtask : pars

endclass : nf_pars_instr
