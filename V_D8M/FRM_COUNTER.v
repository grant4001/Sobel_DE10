module FRM_COUNTER (
 input CLOCK  , 
 input CLR  ,  
 input DE  , 
 output reg [19:0] ADDR 
 
);
//--wr counter -- 
reg rCLR ; 
always @( posedge   CLOCK ) begin 
      rCLR <= CLR  ; 
      if (!rCLR &  CLR  ) ADDR<=0; 
 else if ( DE  )          ADDR<= ADDR+1 ; 

end 

endmodule 