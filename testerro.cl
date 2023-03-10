class Main inherits IO{
	1valor:Int;
	valor2:Int;	
	resposta:Int; 
	main():Object{{
	1valor<-3;
	valor2<-3;
	
	out_string("resultado soma: ");out_int(resposta);out_string("\n");
	resposta<-1valor-valor2;
	out_string("resultado subitracao: ");out_int(resposta);out_string("\n");
	resposta<-1valor*valor2;
	out_string("resultado multiplicacao: ");out_int(resposta);out_string("\n");
	resposta<-1valor/valor2;
	out_string("resultado divisao: ");out_int(resposta);out_string("\n");
	
	}};


};
