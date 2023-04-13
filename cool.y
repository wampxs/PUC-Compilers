%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"
  #include "list.h"

  extern char *curr_filename;

  #define YYLTYPE int
  #define cool_yylloc curr_lineno

    extern int node_lineno;
      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;


    #define SET_NODELOC(Current)  \
    node_lineno = Current;

    void yyerror(char *s);
    extern int yylex();

    Program ast_root;
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}

    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      char *error_msg;
    }

    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283

     %type <program> program
     %type <classes> class_list
     %type <class_> class
     %type <features> features_list
     %type <features> features
     %type <feature> feature
     %type <formals> formal_list
     %type <formal> formal
     %type <expression> expression

    %right ASSIGN
    %left NOT
    %nonassoc LE '<' '='
    %left '+' '-'
    %left '*' '/'
    %left ISVOID
    %left '~'
    %left '@'
    %left '.'

    %%
    program     : class_list {

                    @$ = @1; ast_root = program($1); }
                ;

    class_list  : class {

                    $$ = single_Classes($1);
                    /* per variable declaration, "used in semantic analysis" */
                    parse_results = $$; }
                | class_list class {
                    $$ = append_Classes($1,single_Classes($2));
                    parse_results = $$; }
                ;

    class     : CLASS TYPEID '{' features_list '}' ';' {
                    /* The class_ constructor builds a Class_ tree node with four arguments as children  */
                    $$ = class_($2, idtable.add_string("Object"), $4, stringtable.add_string(curr_filename)); }
                | CLASS TYPEID INHERITS TYPEID '{' features_list '}' ';' {
                    $$ = class_($2, $4, $6, stringtable.add_string(curr_filename)); };

  features_list   : features { $$ = $1; }
              | { $$ = nil_Features(); };

  features    : feature ';' { $$ = single_Features($1); }
              | features feature ';' { $$ = append_Features($1, single_Features($2)); };

  feature     : OBJECTID '(' formal_list ')' ':' TYPEID '{' expression '}' { $$ = method($1, $3, $6, $8); }
              | OBJECTID ':' TYPEID { $$ = attr($1, $3, no_expr()); }
              | OBJECTID ':' TYPEID ASSIGN expression { $$ = attr($1, $3, $5); };

  formal_list : formal { $$ = single_Formals($1); }
              | formal_list ',' formal { $$ = append_Formals($1, single_Formals($3)); };

  formal      : OBJECTID ':' TYPEID { $$ = formal($1, $3); };
    %%

    void yyerror(char *s)
    {
      extern int curr_lineno;

      cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
      << s << " at or near ";
      print_cool_token(yychar);
      cerr << endl;
      omerrs++;

      if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
    }
