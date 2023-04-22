class Main inherits IO {
i:Int; 
item: Object;
main(): Object {{
  i<-3;
  let hello: String <- "Hello ",
   world: String <- "World!",
   newline: String <- "\n"
  in
   
   if (not isvoid i) then
   out_string(hello.concat(world.concat(newline)))
   else
   { abort(); 0; }
   fi;

   case item of
	s: String => s;
	o: Object => { abort(); ""; };
    esac;
 }};
};
