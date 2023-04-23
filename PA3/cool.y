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
     %type <classes> classlist
     %type <class_> class
     %type <features> featureslist
     %type <features> features
     %type <feature> feature
     %type <formals> formallist
     %type <formal> formal
     %type <expression> expression
     %type <expressions> paramexprpression
     %type <expression> letexpression
     %type <expressions> expressions
     %type <cases> caselist
     %type <case_> singlecase

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
    program     : classlist {

                    @$ = @1; ast_root = program($1); }
                ;

    classlist  : class {

                    $$ = single_Classes($1);
                    /* per variable declaration, "used in semantic analysis" */
                    parse_results = $$; }
                | classlist class {
                    $$ = append_Classes($1,single_Classes($2));
                    parse_results = $$; }
                ;

    class     : CLASS  TYPEID '{' featureslist '}' ';' {
                    /* The class_ constructor builds a Class_ tree node with four arguments as children  */
                    $$ = class_($2, idtable.add_string("Object"), $4, stringtable.add_string(curr_filename)); }
                | CLASS TYPEID INHERITS TYPEID '{' featureslist '}' ';' {
                    $$ = class_($2, $4, $6, stringtable.add_string(curr_filename)); }
                | CLASS TYPEID '{' error '}' ';' { yyclearin; $$ = NULL; }
                | CLASS error '{' featureslist '}' ';' { yyclearin; $$ = NULL; }
                | CLASS error '{' error '}' ';' { yyclearin; $$ = NULL; }
                ;
  featureslist   : features { $$ = $1; }
              | { $$ = nil_Features(); };

  features    : feature ';' { $$ = single_Features($1); }
              | features feature ';' { $$ = append_Features($1, single_Features($2)); };

  feature     : error ';'
              | OBJECTID '(' formallist ')' ':' TYPEID '{' expression '}' { $$ = method($1, $3, $6, $8); }
              | OBJECTID ':' TYPEID { $$ = attr($1, $3, no_expr()); }
              | OBJECTID ':' TYPEID ASSIGN expression { $$ = attr($1, $3, $5); };

  formallist : formal { $$ = single_Formals($1); }
              | formallist ',' formal { $$ = append_Formals($1, single_Formals($3)); };
              | { $$ = nil_Formals(); };

  formal      : OBJECTID ':' TYPEID { $$ = formal($1, $3); };

  expression  : OBJECTID ASSIGN expression { $$ = assign($1, $3); }

                | expression '.' OBJECTID '(' paramexprpression ')' { $$ = dispatch($1, $3, $5); }
                | expression '@' TYPEID '.' OBJECTID '(' paramexprpression ')' { $$ = static_dispatch($1, $3, $5, $7); }
                | OBJECTID '(' paramexprpression ')' { $$ = dispatch(object(idtable.add_string("self")), $1, $3); }
                | IF expression THEN expression ELSE expression FI { $$ = cond($2, $4, $6); }
                | WHILE expression LOOP expression POOL { $$ = loop($2, $4); }
                | '{' expressions '}' { $$ = block($2); }
                | LET letexpression { $$ = $2; }
                | CASE expression OF caselist ESAC { $$ = typcase($2, $4); }
                | NEW TYPEID { $$ = new_($2); }
                | STR_CONST { $$ = string_const($1); }
                | ISVOID expression { $$ = isvoid($2); }
                | INT_CONST { $$ = int_const($1); }
                | BOOL_CONST { $$ = bool_const($1); }
                | '~' expression { $$ = neg($2); }
                | expression '<' expression { $$ = lt($1, $3); }
                | expression LE expression { $$ = leq($1, $3); }
                | expression '=' expression { $$ = eq($1, $3); }
                | expression '+' expression { $$ = plus($1, $3); }
                | expression '-' expression { $$ = sub($1, $3); }
                | expression '*' expression { $$ = mul($1, $3); }
                | expression '/' expression { $$ = divide($1, $3); }
                | NOT expression { $$ = comp($2); }
                | '(' expression ')' { $$ = $2; }
                | OBJECTID { $$ = object($1); };

    letexpression   : OBJECTID ':' TYPEID IN expression { $$ = let($1, $3, no_expr(), $5); }
                | OBJECTID ':' TYPEID ASSIGN expression IN expression { $$ = let($1, $3, $5, $7); }
                | OBJECTID ':' TYPEID ',' letexpression { $$ = let($1, $3, no_expr(), $5); }
                | OBJECTID ':' TYPEID ASSIGN expression ',' letexpression { $$ = let($1, $3, $5, $7); }
                | error IN expression { yyclearin; $$ = NULL; }
                | error ',' letexpression { yyclearin; $$ = NULL; };

    expressions    : expression ';' { $$ = single_Expressions($1); }
                | expressions expression ';' { $$ = append_Expressions($1, single_Expressions($2)); };

    paramexprpression    : expression { $$ = single_Expressions($1); }
                | paramexprpression ',' expression { $$ = append_Expressions($1, single_Expressions($3)); }
                | { $$ = nil_Expressions(); };

    caselist    : singlecase { $$ = single_Cases($1); }
                | caselist singlecase { $$ = append_Cases($1, single_Cases($2)); };
    singlecase     : OBJECTID ':' TYPEID DARROW expression ';' { $$ = branch($1, $3, $5); };

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
