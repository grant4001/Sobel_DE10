
module GAMMA_CORRECT 
( 
 input        CLK,  
 input  [7:0] DI_0,  
 input  [7:0] DI_1,  
 input  [7:0] DI_2,  
 output [7:0] DO_0,  
 output [7:0] DO_1,  
 output [7:0] DO_2

);
//---- Dynamic Gamma (Real time GAMMA correction using BEZIER CURVE) ---- 
wire  [9:0] coef1  ; 
wire  [9:0] coef2  ; 


//P1 pp11( . result (coef1) );
//P2 pp22( . result (coef2) );


assign coef1 = 10'haf  ; 
assign coef2 = 10'h1a0 ; 

 BEZIER_CURVE    rr( .CLK(CLK),.P1 ( coef1),   .P2 ( coef2), .T  (  { DI_0[7:0] ,8'h0 }  ), .TT ( DO_0 ));
 BEZIER_CURVE    gg( .CLK(CLK),.P1 ( coef1),   .P2 ( coef2), .T  (  { DI_1[7:0] ,8'h0 }  ), .TT ( DO_1 ));
 BEZIER_CURVE    bb( .CLK(CLK),.P1 ( coef1),   .P2 ( coef2), .T  (  { DI_2[7:0] ,8'h0 }  ), .TT ( DO_2 ));
 
endmodule 
