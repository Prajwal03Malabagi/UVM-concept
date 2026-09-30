 import uvm_pkg::*;
`include "uvm_macros.svh"
/*
class base extends uvm_component;
  `uvm_component_utils(base)
  
  function new(string name="base",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    $display("hi");
  endfunction
  
endclass

class comp1 extends base;
  `uvm_component_utils(comp1)
  
  function new(string name="comp1",uvm_component parent);
    super.new(name,parent);
  endfunction
endclass

class comp2 extends base;
  `uvm_component_utils(comp2)
  
  function new(string name="comp2",uvm_component parent);
    super.new(name,parent);
  endfunction
	
function void build_phase(uvm_phase phase);
	$display("HIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII");
endfunction

endclass

*/
class base extends uvm_component;
  `uvm_component_utils(base)

  function new(string name="base",uvm_component parent);
    super.new(name,parent);
  endfunction

	function void build_phase(uvm_phase phase);
	$display("HIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII");
endfunction

endclass

class comp1 extends base;
  `uvm_component_utils(comp1)

  function new(string name="comp1",uvm_component parent);
    super.new(name,parent);
  endfunction
endclass

class comp2 extends comp1;
  `uvm_component_utils(comp2)

  function new(string name="comp2",uvm_component parent);
    super.new(name,parent);
  endfunction
endclass

class comp3 extends comp2;
  `uvm_component_utils(comp3)

  function new(string name="comp3",uvm_component parent);
    super.new(name,parent);
  endfunction
endclass
class env extends uvm_env;
  `uvm_component_utils(env)
  base b[];

  function new(string name="env",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    b=new[4];
    foreach(b[i])
      b[i]=base::type_id::create($sformatf("b[%0d]",i),this);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test)
  env e;
  function new(string name="test",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    e=env::type_id::create("e",this);
    
    set_inst_override_by_type("e.b[1]",base::get_type(),comp1::get_type);
    set_type_override_by_type(base::get_type(),comp2::get_type);
    set_type_override_by_type(base::get_type(),comp2::get_type);
    set_type_override_by_type(base::get_type(),comp1::get_type,1);//cannot replace comp1 with comp2 and the base is comp2 so all type overide base is comp2
    set_type_override_by_type(base::get_type(),comp3::get_type,0);
    
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_root::get().print_topology();
  endfunction
endclass

module mod;
  bit clk;
  
  always clk=~clk;
  
  initial begin
    clk=0;
    run_test("test");
  end
endmodule
