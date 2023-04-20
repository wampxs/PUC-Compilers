class Main {
  x : Int;
  y : Int <- 3;

  main(): Int { 
    (let x : Int <- 2 in
      case x of
        a : Int => 4;
        b : String => 2;
        c : Main => 1;
      esac
    )
  };
};
