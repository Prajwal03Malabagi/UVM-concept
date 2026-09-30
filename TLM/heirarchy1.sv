import uvm_pkg::*;
`include "uvm_macros.svh"
class tx extends uvm_sequence_item;
`uvm_object_utils(tx)

	rand bit[7:0]a;
	rand bit[7:0]b;

	constraint c1{a!=b;}
	
	function void do_print(uvm_printer printer);
		printer.print_field("a",a,8,UVM_BIN);
		printer.print_field("b",b,8,UVM_BIN);
	endfunction
endclass

class sub1 extends uvm_component;
`uvm_component_utils(sub1)
uvm_blocking_put_port#(tx) put_port;
tx t1;
function new(string name="s1",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	put_port=new("put_port",this);
endfunction

task run_phase(uvm_phase phase);
	`uvm_info("comp1","put port",UVM_LOW);
	t1=tx::type_id::create("t1");
	t1.randomize();
	put_port.put(t1);
endtask
endclass

class comp1 extends uvm_component;
`uvm_component_utils(comp1)
uvm_blocking_put_port#(tx) put_port;
tx t1;
sub1 s1;
function new(string name="c1",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	put_port=new("put_port",this);
	s1=sub1::type_id::create("s1",this);
endfunction

function void connect_phase(uvm_phase phase);
s1.put_port.connect(this.put_port);
endfunction
endclass


class sub2 extends uvm_component;
`uvm_component_utils(sub2)
uvm_blocking_put_imp#(tx,sub2)put_imp;
tx t1;
	function new(string name="sub2",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		put_imp=new("put_imp",this);
	endfunction
	
	task put(tx t1);
//	t1=tx::type_id::create("t1");
		this.t1=t1;
		$display("sub2");
		t1.print();
	endtask
endclass


class comp2 extends uvm_component;
`uvm_component_utils(comp2)
uvm_blocking_put_export#(tx)put_exp;
tx t1;
sub2 s2;
	function new(string name="comp2",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		put_exp=new("put_exp",this);
		s2=sub2::type_id::create("s2",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		put_exp.connect(s2.put_imp);
	endfunction

		
endclass



class test extends uvm_test;
`uvm_component_utils(test)
comp1 c1;
comp2 c2;
function new(string name="test",uvm_component parent);
	super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
	c1=comp1::type_id::create("c1",this);
	c2=comp2::type_id::create("c2",this);
endfunction

function void connect_phase(uvm_phase phase);
	c1.put_port.connect(c2.put_exp);
endfunction
endclass

module mod;

	initial 
		run_test("test");
endmodule
