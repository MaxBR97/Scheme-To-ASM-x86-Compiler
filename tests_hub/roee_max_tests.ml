let quadruples = [
  ("a", ScmSymbol "a", ScmVarGet (Var "a"), ScmVarGet' (Var' ("a", Free)))

;

  ("1234", ScmNumber (ScmInteger 1234), ScmConst (ScmNumber (ScmInteger 1234)),
   ScmConst' (ScmNumber (ScmInteger 1234)))

;

  ("(if a b c)",
   ScmPair
     (ScmSymbol "if",
      ScmPair
        (ScmSymbol "a", ScmPair (ScmSymbol "b", ScmPair (ScmSymbol "c", ScmNil)))),
   ScmIf (ScmVarGet (Var "a"), ScmVarGet (Var "b"), ScmVarGet (Var "c")),
   ScmIf' (ScmVarGet' (Var' ("a", Free)), ScmVarGet' (Var' ("b", Free)),
           ScmVarGet' (Var' ("c", Free))))

;

  ("(if a b)",
 ScmPair
  (ScmSymbol "if", ScmPair (ScmSymbol "a", ScmPair (ScmSymbol "b", ScmNil))),
 ScmIf (ScmVarGet (Var "a"), ScmVarGet (Var "b"), ScmConst ScmVoid),
 ScmIf' (ScmVarGet' (Var' ("a", Free)), ScmVarGet' (Var' ("b", Free)),
  ScmConst' ScmVoid))

;

("(a b 'c)",
 ScmPair
  (ScmSymbol "a",
   ScmPair
    (ScmSymbol "b",
     ScmPair
      (ScmPair (ScmSymbol "quote", ScmPair (ScmSymbol "c", ScmNil)), ScmNil))),
 ScmApplic (ScmVarGet (Var "a"),
  [ScmVarGet (Var "b"); ScmConst (ScmSymbol "c")]),
 ScmApplic' (ScmVarGet' (Var' ("a", Free)),
  [ScmVarGet' (Var' ("b", Free)); ScmConst' (ScmSymbol "c")], Non_Tail_Call))

;

("'''a",
 ScmPair
  (ScmSymbol "quote",
   ScmPair
    (ScmPair
      (ScmSymbol "quote",
       ScmPair
        (ScmPair (ScmSymbol "quote", ScmPair (ScmSymbol "a", ScmNil)),
         ScmNil)),
     ScmNil)),
 ScmConst
  (ScmPair
    (ScmSymbol "quote",
     ScmPair
      (ScmPair (ScmSymbol "quote", ScmPair (ScmSymbol "a", ScmNil)), ScmNil))),
 ScmConst'
  (ScmPair
    (ScmSymbol "quote",
     ScmPair
      (ScmPair (ScmSymbol "quote", ScmPair (ScmSymbol "a", ScmNil)), ScmNil))))

;

("'`,',@`a",
 ScmPair
  (ScmSymbol "quote",
   ScmPair
    (ScmPair
      (ScmSymbol "quasiquote",
       ScmPair
        (ScmPair
          (ScmSymbol "unquote",
           ScmPair
            (ScmPair
              (ScmSymbol "quote",
               ScmPair
                (ScmPair
                  (ScmSymbol "unquote-splicing",
                   ScmPair
                    (ScmPair
                      (ScmSymbol "quasiquote",
                       ScmPair (ScmSymbol "a", ScmNil)),
                     ScmNil)),
                 ScmNil)),
             ScmNil)),
         ScmNil)),
     ScmNil)),
 ScmConst
  (ScmPair
    (ScmSymbol "quasiquote",
     ScmPair
      (ScmPair
        (ScmSymbol "unquote",
         ScmPair
          (ScmPair
            (ScmSymbol "quote",
             ScmPair
              (ScmPair
                (ScmSymbol "unquote-splicing",
                 ScmPair
                  (ScmPair
                    (ScmSymbol "quasiquote", ScmPair (ScmSymbol "a", ScmNil)),
                   ScmNil)),
               ScmNil)),
           ScmNil)),
       ScmNil))),
 ScmConst'
  (ScmPair
    (ScmSymbol "quasiquote",
     ScmPair
      (ScmPair
        (ScmSymbol "unquote",
         ScmPair
          (ScmPair
            (ScmSymbol "quote",
             ScmPair
              (ScmPair
                (ScmSymbol "unquote-splicing",
                 ScmPair
                  (ScmPair
                    (ScmSymbol "quasiquote", ScmPair (ScmSymbol "a", ScmNil)),
                   ScmNil)),
               ScmNil)),
           ScmNil)),
       ScmNil))))

;

("`(,a b ,c d ,@d ,@e)",
 ScmPair
  (ScmSymbol "quasiquote",
   ScmPair
    (ScmPair
      (ScmPair (ScmSymbol "unquote", ScmPair (ScmSymbol "a", ScmNil)),
       ScmPair
        (ScmSymbol "b",
         ScmPair
          (ScmPair (ScmSymbol "unquote", ScmPair (ScmSymbol "c", ScmNil)),
           ScmPair
            (ScmSymbol "d",
             ScmPair
              (ScmPair
                (ScmSymbol "unquote-splicing",
                 ScmPair (ScmSymbol "d", ScmNil)),
               ScmPair
                (ScmPair
                  (ScmSymbol "unquote-splicing",
                   ScmPair (ScmSymbol "e", ScmNil)),
                 ScmNil)))))),
     ScmNil)),
 ScmApplic (ScmVarGet (Var "cons"),
  [ScmVarGet (Var "a");
   ScmApplic (ScmVarGet (Var "cons"),
    [ScmConst (ScmSymbol "b");
     ScmApplic (ScmVarGet (Var "cons"),
      [ScmVarGet (Var "c");
       ScmApplic (ScmVarGet (Var "cons"),
        [ScmConst (ScmSymbol "d");
         ScmApplic (ScmVarGet (Var "append"),
          [ScmVarGet (Var "d"); ScmVarGet (Var "e")])])])])]),
 ScmApplic' (ScmVarGet' (Var' ("cons", Free)),
  [ScmVarGet' (Var' ("a", Free));
   ScmApplic' (ScmVarGet' (Var' ("cons", Free)),
    [ScmConst' (ScmSymbol "b");
     ScmApplic' (ScmVarGet' (Var' ("cons", Free)),
      [ScmVarGet' (Var' ("c", Free));
       ScmApplic' (ScmVarGet' (Var' ("cons", Free)),
        [ScmConst' (ScmSymbol "d");
         ScmApplic' (ScmVarGet' (Var' ("append", Free)),
          [ScmVarGet' (Var' ("d", Free)); ScmVarGet' (Var' ("e", Free))],
          Non_Tail_Call)],
        Non_Tail_Call)],
      Non_Tail_Call)],
    Non_Tail_Call)],
  Non_Tail_Call))

;

("(define (square x) (* x x))",
 ScmPair
  (ScmSymbol "define",
   ScmPair
    (ScmPair (ScmSymbol "square", ScmPair (ScmSymbol "x", ScmNil)),
     ScmPair
      (ScmPair
        (ScmSymbol "*",
         ScmPair (ScmSymbol "x", ScmPair (ScmSymbol "x", ScmNil))),
       ScmNil))),
 ScmVarDef (Var "square",
  ScmLambda (["x"], Simple,
   ScmApplic (ScmVarGet (Var "*"),
    [ScmVarGet (Var "x"); ScmVarGet (Var "x")]))),
 ScmVarDef' (Var' ("square", Free),
  ScmLambda' (["x"], Simple,
   ScmApplic' (ScmVarGet' (Var' ("*", Free)),
    [ScmVarGet' (Var' ("x", Param 0)); ScmVarGet' (Var' ("x", Param 0))],
    Tail_Call))))

;

("(letrec ((fact (lambda (n) (if (zero? n) 1 (* n (fact (- n 1))))))) (fact 5))",
 ScmPair
  (ScmSymbol "letrec",
   ScmPair
    (ScmPair
      (ScmPair
        (ScmSymbol "fact",
         ScmPair
          (ScmPair
            (ScmSymbol "lambda",
             ScmPair
              (ScmPair (ScmSymbol "n", ScmNil),
               ScmPair
                (ScmPair
                  (ScmSymbol "if",
                   ScmPair
                    (ScmPair
                      (ScmSymbol "zero?", ScmPair (ScmSymbol "n", ScmNil)),
                     ScmPair
                      (ScmNumber (ScmInteger 1),
                       ScmPair
                        (ScmPair
                          (ScmSymbol "*",
                           ScmPair
                            (ScmSymbol "n",
                             ScmPair
                              (ScmPair
                                (ScmSymbol "fact",
                                 ScmPair
                                  (ScmPair
                                    (ScmSymbol "-",
                                     ScmPair
                                      (ScmSymbol "n",
                                       ScmPair
                                        (ScmNumber (ScmInteger 1), ScmNil))),
                                   ScmNil)),
                               ScmNil))),
                         ScmNil)))),
                 ScmNil))),
           ScmNil)),
       ScmNil),
     ScmPair
      (ScmPair (ScmSymbol "fact", ScmPair (ScmNumber (ScmInteger 5), ScmNil)),
       ScmNil))),
 ScmApplic
  (ScmLambda (["fact"], Simple,
    ScmSeq
     [ScmVarSet (Var "fact",
       ScmLambda (["n"], Simple,
        ScmIf (ScmApplic (ScmVarGet (Var "zero?"), [ScmVarGet (Var "n")]),
         ScmConst (ScmNumber (ScmInteger 1)),
         ScmApplic (ScmVarGet (Var "*"),
          [ScmVarGet (Var "n");
           ScmApplic (ScmVarGet (Var "fact"),
            [ScmApplic (ScmVarGet (Var "-"),
              [ScmVarGet (Var "n"); ScmConst (ScmNumber (ScmInteger 1))])])]))));
      ScmApplic (ScmVarGet (Var "fact"),
       [ScmConst (ScmNumber (ScmInteger 5))])]),
  [ScmConst (ScmSymbol "whatever")]),
 ScmApplic'
  (ScmLambda' (["fact"], Simple,
    ScmSeq'
     [ScmVarSet' (Var' ("fact", Param 0), ScmBox' (Var' ("fact", Param 0)));
      ScmBoxSet' (Var' ("fact", Param 0),
       ScmLambda' (["n"], Simple,
        ScmIf'
         (ScmApplic' (ScmVarGet' (Var' ("zero?", Free)),
           [ScmVarGet' (Var' ("n", Param 0))], Non_Tail_Call),
         ScmConst' (ScmNumber (ScmInteger 1)),
         ScmApplic' (ScmVarGet' (Var' ("*", Free)),
          [ScmVarGet' (Var' ("n", Param 0));
           ScmApplic' (ScmBoxGet' (Var' ("fact", Bound (0, 0))),
            [ScmApplic' (ScmVarGet' (Var' ("-", Free)),
              [ScmVarGet' (Var' ("n", Param 0));
               ScmConst' (ScmNumber (ScmInteger 1))],
              Non_Tail_Call)],
            Non_Tail_Call)],
          Tail_Call))));
      ScmApplic' (ScmBoxGet' (Var' ("fact", Param 0)),
       [ScmConst' (ScmNumber (ScmInteger 5))], Tail_Call)]),
  [ScmConst' (ScmSymbol "whatever")], Non_Tail_Call))

;

("(letrec ((fact (lambda (n) (if (zero? n) 1 (* n (fact1 (- n 1))))))(fact1 (lambda (n) (if (zero? n) 1 (* n (fact2 (- n 1))))))(fact2 (lambda (n) (if (zero? n) 1 (* n (fact3 (- n 1))))))(fact3 (lambda (n) (if (zero? n) 1 (* n (fact (- n 1))))))) (fact 5))",
 ScmPair
  (ScmSymbol "letrec",
   ScmPair
    (ScmPair
      (ScmPair
        (ScmSymbol "fact",
         ScmPair
          (ScmPair
            (ScmSymbol "lambda",
             ScmPair
              (ScmPair (ScmSymbol "n", ScmNil),
               ScmPair
                (ScmPair
                  (ScmSymbol "if",
                   ScmPair
                    (ScmPair
                      (ScmSymbol "zero?", ScmPair (ScmSymbol "n", ScmNil)),
                     ScmPair
                      (ScmNumber (ScmInteger 1),
                       ScmPair
                        (ScmPair
                          (ScmSymbol "*",
                           ScmPair
                            (ScmSymbol "n",
                             ScmPair
                              (ScmPair
                                (ScmSymbol "fact1",
                                 ScmPair
                                  (ScmPair
                                    (ScmSymbol "-",
                                     ScmPair
                                      (ScmSymbol "n",
                                       ScmPair
                                        (ScmNumber (ScmInteger 1), ScmNil))),
                                   ScmNil)),
                               ScmNil))),
                         ScmNil)))),
                 ScmNil))),
           ScmNil)),
       ScmPair
        (ScmPair
          (ScmSymbol "fact1",
           ScmPair
            (ScmPair
              (ScmSymbol "lambda",
               ScmPair
                (ScmPair (ScmSymbol "n", ScmNil),
                 ScmPair
                  (ScmPair
                    (ScmSymbol "if",
                     ScmPair
                      (ScmPair
                        (ScmSymbol "zero?", ScmPair (ScmSymbol "n", ScmNil)),
                       ScmPair
                        (ScmNumber (ScmInteger 1),
                         ScmPair
                          (ScmPair
                            (ScmSymbol "*",
                             ScmPair
                              (ScmSymbol "n",
                               ScmPair
                                (ScmPair
                                  (ScmSymbol "fact2",
                                   ScmPair
                                    (ScmPair
                                      (ScmSymbol "-",
                                       ScmPair
                                        (ScmSymbol "n",
                                         ScmPair
                                          (ScmNumber (ScmInteger 1), ScmNil))),
                                     ScmNil)),
                                 ScmNil))),
                           ScmNil)))),
                   ScmNil))),
             ScmNil)),
         ScmPair
          (ScmPair
            (ScmSymbol "fact2",
             ScmPair
              (ScmPair
                (ScmSymbol "lambda",
                 ScmPair
                  (ScmPair (ScmSymbol "n", ScmNil),
                   ScmPair
                    (ScmPair
                      (ScmSymbol "if",
                       ScmPair
                        (ScmPair
                          (ScmSymbol "zero?",
                           ScmPair (ScmSymbol "n", ScmNil)),
                         ScmPair
                          (ScmNumber (ScmInteger 1),
                           ScmPair
                            (ScmPair
                              (ScmSymbol "*",
                               ScmPair
                                (ScmSymbol "n",
                                 ScmPair
                                  (ScmPair
                                    (ScmSymbol "fact3",
                                     ScmPair
                                      (ScmPair
                                        (ScmSymbol "-",
                                         ScmPair
                                          (ScmSymbol "n",
                                           ScmPair
                                            (ScmNumber (ScmInteger 1),
                                             ScmNil))),
                                       ScmNil)),
                                   ScmNil))),
                             ScmNil)))),
                     ScmNil))),
               ScmNil)),
           ScmPair
            (ScmPair
              (ScmSymbol "fact3",
               ScmPair
                (ScmPair
                  (ScmSymbol "lambda",
                   ScmPair
                    (ScmPair (ScmSymbol "n", ScmNil),
                     ScmPair
                      (ScmPair
                        (ScmSymbol "if",
                         ScmPair
                          (ScmPair
                            (ScmSymbol "zero?",
                             ScmPair (ScmSymbol "n", ScmNil)),
                           ScmPair
                            (ScmNumber (ScmInteger 1),
                             ScmPair
                              (ScmPair
                                (ScmSymbol "*",
                                 ScmPair
                                  (ScmSymbol "n",
                                   ScmPair
                                    (ScmPair
                                      (ScmSymbol "fact",
                                       ScmPair
                                        (ScmPair
                                          (ScmSymbol "-",
                                           ScmPair
                                            (ScmSymbol "n",
                                             ScmPair
                                              (ScmNumber (ScmInteger 1),
                                               ScmNil))),
                                         ScmNil)),
                                     ScmNil))),
                               ScmNil)))),
                       ScmNil))),
                 ScmNil)),
             ScmNil)))),
     ScmPair
      (ScmPair (ScmSymbol "fact", ScmPair (ScmNumber (ScmInteger 5), ScmNil)),
       ScmNil))),
 ScmApplic
  (ScmLambda (["fact"; "fact1"; "fact2"; "fact3"], Simple,
    ScmSeq
     [ScmVarSet (Var "fact",
       ScmLambda (["n"], Simple,
        ScmIf (ScmApplic (ScmVarGet (Var "zero?"), [ScmVarGet (Var "n")]),
         ScmConst (ScmNumber (ScmInteger 1)),
         ScmApplic (ScmVarGet (Var "*"),
          [ScmVarGet (Var "n");
           ScmApplic (ScmVarGet (Var "fact1"),
            [ScmApplic (ScmVarGet (Var "-"),
              [ScmVarGet (Var "n"); ScmConst (ScmNumber (ScmInteger 1))])])]))));
      ScmVarSet (Var "fact1",
       ScmLambda (["n"], Simple,
        ScmIf (ScmApplic (ScmVarGet (Var "zero?"), [ScmVarGet (Var "n")]),
         ScmConst (ScmNumber (ScmInteger 1)),
         ScmApplic (ScmVarGet (Var "*"),
          [ScmVarGet (Var "n");
           ScmApplic (ScmVarGet (Var "fact2"),
            [ScmApplic (ScmVarGet (Var "-"),
              [ScmVarGet (Var "n"); ScmConst (ScmNumber (ScmInteger 1))])])]))));
      ScmVarSet (Var "fact2",
       ScmLambda (["n"], Simple,
        ScmIf (ScmApplic (ScmVarGet (Var "zero?"), [ScmVarGet (Var "n")]),
         ScmConst (ScmNumber (ScmInteger 1)),
         ScmApplic (ScmVarGet (Var "*"),
          [ScmVarGet (Var "n");
           ScmApplic (ScmVarGet (Var "fact3"),
            [ScmApplic (ScmVarGet (Var "-"),
              [ScmVarGet (Var "n"); ScmConst (ScmNumber (ScmInteger 1))])])]))));
      ScmVarSet (Var "fact3",
       ScmLambda (["n"], Simple,
        ScmIf (ScmApplic (ScmVarGet (Var "zero?"), [ScmVarGet (Var "n")]),
         ScmConst (ScmNumber (ScmInteger 1)),
         ScmApplic (ScmVarGet (Var "*"),
          [ScmVarGet (Var "n");
           ScmApplic (ScmVarGet (Var "fact"),
            [ScmApplic (ScmVarGet (Var "-"),
              [ScmVarGet (Var "n"); ScmConst (ScmNumber (ScmInteger 1))])])]))));
      ScmApplic (ScmVarGet (Var "fact"),
       [ScmConst (ScmNumber (ScmInteger 5))])]),
  [ScmConst (ScmSymbol "whatever"); ScmConst (ScmSymbol "whatever");
   ScmConst (ScmSymbol "whatever"); ScmConst (ScmSymbol "whatever")]),
 ScmApplic'
  (ScmLambda' (["fact"; "fact1"; "fact2"; "fact3"], Simple,
    ScmSeq'
     [ScmVarSet' (Var' ("fact", Param 0), ScmBox' (Var' ("fact", Param 0)));
      ScmVarSet' (Var' ("fact1", Param 1), ScmBox' (Var' ("fact1", Param 1)));
      ScmVarSet' (Var' ("fact2", Param 2), ScmBox' (Var' ("fact2", Param 2)));
      ScmVarSet' (Var' ("fact3", Param 3), ScmBox' (Var' ("fact3", Param 3)));
      ScmBoxSet' (Var' ("fact", Param 0),
       ScmLambda' (["n"], Simple,
        ScmIf'
         (ScmApplic' (ScmVarGet' (Var' ("zero?", Free)),
           [ScmVarGet' (Var' ("n", Param 0))], Non_Tail_Call),
         ScmConst' (ScmNumber (ScmInteger 1)),
         ScmApplic' (ScmVarGet' (Var' ("*", Free)),
          [ScmVarGet' (Var' ("n", Param 0));
           ScmApplic' (ScmBoxGet' (Var' ("fact1", Bound (0, 1))),
            [ScmApplic' (ScmVarGet' (Var' ("-", Free)),
              [ScmVarGet' (Var' ("n", Param 0));
               ScmConst' (ScmNumber (ScmInteger 1))],
              Non_Tail_Call)],
            Non_Tail_Call)],
          Tail_Call))));
      ScmBoxSet' (Var' ("fact1", Param 1),
       ScmLambda' (["n"], Simple,
        ScmIf'
         (ScmApplic' (ScmVarGet' (Var' ("zero?", Free)),
           [ScmVarGet' (Var' ("n", Param 0))], Non_Tail_Call),
         ScmConst' (ScmNumber (ScmInteger 1)),
         ScmApplic' (ScmVarGet' (Var' ("*", Free)),
          [ScmVarGet' (Var' ("n", Param 0));
           ScmApplic' (ScmBoxGet' (Var' ("fact2", Bound (0, 2))),
            [ScmApplic' (ScmVarGet' (Var' ("-", Free)),
              [ScmVarGet' (Var' ("n", Param 0));
               ScmConst' (ScmNumber (ScmInteger 1))],
              Non_Tail_Call)],
            Non_Tail_Call)],
          Tail_Call))));
      ScmBoxSet' (Var' ("fact2", Param 2),
       ScmLambda' (["n"], Simple,
        ScmIf'
         (ScmApplic' (ScmVarGet' (Var' ("zero?", Free)),
           [ScmVarGet' (Var' ("n", Param 0))], Non_Tail_Call),
         ScmConst' (ScmNumber (ScmInteger 1)),
         ScmApplic' (ScmVarGet' (Var' ("*", Free)),
          [ScmVarGet' (Var' ("n", Param 0));
           ScmApplic' (ScmBoxGet' (Var' ("fact3", Bound (0, 3))),
            [ScmApplic' (ScmVarGet' (Var' ("-", Free)),
              [ScmVarGet' (Var' ("n", Param 0));
               ScmConst' (ScmNumber (ScmInteger 1))],
              Non_Tail_Call)],
            Non_Tail_Call)],
          Tail_Call))));
      ScmBoxSet' (Var' ("fact3", Param 3),
       ScmLambda' (["n"], Simple,
        ScmIf'
         (ScmApplic' (ScmVarGet' (Var' ("zero?", Free)),
           [ScmVarGet' (Var' ("n", Param 0))], Non_Tail_Call),
         ScmConst' (ScmNumber (ScmInteger 1)),
         ScmApplic' (ScmVarGet' (Var' ("*", Free)),
          [ScmVarGet' (Var' ("n", Param 0));
           ScmApplic' (ScmBoxGet' (Var' ("fact", Bound (0, 0))),
            [ScmApplic' (ScmVarGet' (Var' ("-", Free)),
              [ScmVarGet' (Var' ("n", Param 0));
               ScmConst' (ScmNumber (ScmInteger 1))],
              Non_Tail_Call)],
            Non_Tail_Call)],
          Tail_Call))));
      ScmApplic' (ScmBoxGet' (Var' ("fact", Param 0)),
       [ScmConst' (ScmNumber (ScmInteger 5))], Tail_Call)]),
  [ScmConst' (ScmSymbol "whatever"); ScmConst' (ScmSymbol "whatever");
   ScmConst' (ScmSymbol "whatever"); ScmConst' (ScmSymbol "whatever")],
  Non_Tail_Call))

;

("(and)", ScmPair (ScmSymbol "and", ScmNil), ScmConst (ScmBoolean true),
 ScmConst' (ScmBoolean true))

;

("(and e)", ScmPair (ScmSymbol "and", ScmPair (ScmSymbol "e", ScmNil)),
 ScmVarGet (Var "e"), ScmVarGet' (Var' ("e", Free)))

;

("(and e1 e2 e3 e4)",
 ScmPair
  (ScmSymbol "and",
   ScmPair
    (ScmSymbol "e1",
     ScmPair
      (ScmSymbol "e2",
       ScmPair (ScmSymbol "e3", ScmPair (ScmSymbol "e4", ScmNil))))),
 ScmIf (ScmVarGet (Var "e1"),
  ScmIf (ScmVarGet (Var "e2"),
   ScmIf (ScmVarGet (Var "e3"), ScmVarGet (Var "e4"),
    ScmConst (ScmBoolean false)),
   ScmConst (ScmBoolean false)),
  ScmConst (ScmBoolean false)),
 ScmIf' (ScmVarGet' (Var' ("e1", Free)),
  ScmIf' (ScmVarGet' (Var' ("e2", Free)),
   ScmIf' (ScmVarGet' (Var' ("e3", Free)), ScmVarGet' (Var' ("e4", Free)),
    ScmConst' (ScmBoolean false)),
   ScmConst' (ScmBoolean false)),
  ScmConst' (ScmBoolean false)))

;

("(let* ((a 1) (b 2) (a (+ a b)) (b (* a b))) (list a b))",
 ScmPair
  (ScmSymbol "let*",
   ScmPair
    (ScmPair
      (ScmPair (ScmSymbol "a", ScmPair (ScmNumber (ScmInteger 1), ScmNil)),
       ScmPair
        (ScmPair (ScmSymbol "b", ScmPair (ScmNumber (ScmInteger 2), ScmNil)),
         ScmPair
          (ScmPair
            (ScmSymbol "a",
             ScmPair
              (ScmPair
                (ScmSymbol "+",
                 ScmPair (ScmSymbol "a", ScmPair (ScmSymbol "b", ScmNil))),
               ScmNil)),
           ScmPair
            (ScmPair
              (ScmSymbol "b",
               ScmPair
                (ScmPair
                  (ScmSymbol "*",
                   ScmPair (ScmSymbol "a", ScmPair (ScmSymbol "b", ScmNil))),
                 ScmNil)),
             ScmNil)))),
     ScmPair
      (ScmPair
        (ScmSymbol "list",
         ScmPair (ScmSymbol "a", ScmPair (ScmSymbol "b", ScmNil))),
       ScmNil))),
 ScmApplic
  (ScmLambda (["a"], Simple,
    ScmApplic
     (ScmLambda (["b"], Simple,
       ScmApplic
        (ScmLambda (["a"], Simple,
          ScmApplic
           (ScmLambda (["b"], Simple,
             ScmApplic (ScmVarGet (Var "list"),
              [ScmVarGet (Var "a"); ScmVarGet (Var "b")])),
           [ScmApplic (ScmVarGet (Var "*"),
             [ScmVarGet (Var "a"); ScmVarGet (Var "b")])])),
        [ScmApplic (ScmVarGet (Var "+"),
          [ScmVarGet (Var "a"); ScmVarGet (Var "b")])])),
     [ScmConst (ScmNumber (ScmInteger 2))])),
  [ScmConst (ScmNumber (ScmInteger 1))]),
 ScmApplic'
  (ScmLambda' (["a"], Simple,
    ScmApplic'
     (ScmLambda' (["b"], Simple,
       ScmApplic'
        (ScmLambda' (["a"], Simple,
          ScmApplic'
           (ScmLambda' (["b"], Simple,
             ScmApplic' (ScmVarGet' (Var' ("list", Free)),
              [ScmVarGet' (Var' ("a", Bound (0, 0)));
               ScmVarGet' (Var' ("b", Param 0))],
              Tail_Call)),
           [ScmApplic' (ScmVarGet' (Var' ("*", Free)),
             [ScmVarGet' (Var' ("a", Param 0));
              ScmVarGet' (Var' ("b", Bound (0, 0)))],
             Non_Tail_Call)],
           Tail_Call)),
        [ScmApplic' (ScmVarGet' (Var' ("+", Free)),
          [ScmVarGet' (Var' ("a", Bound (0, 0)));
           ScmVarGet' (Var' ("b", Param 0))],
          Non_Tail_Call)],
        Tail_Call)),
     [ScmConst' (ScmNumber (ScmInteger 2))], Tail_Call)),
  [ScmConst' (ScmNumber (ScmInteger 1))], Non_Tail_Call))

;

("(cond (else e1 e2 e3))",
 ScmPair
  (ScmSymbol "cond",
   ScmPair
    (ScmPair
      (ScmSymbol "else",
       ScmPair
        (ScmSymbol "e1",
         ScmPair (ScmSymbol "e2", ScmPair (ScmSymbol "e3", ScmNil)))),
     ScmNil)),
 ScmSeq [ScmVarGet (Var "e1"); ScmVarGet (Var "e2"); ScmVarGet (Var "e3")],
 ScmSeq'
  [ScmVarGet' (Var' ("e1", Free)); ScmVarGet' (Var' ("e2", Free));
   ScmVarGet' (Var' ("e3", Free))])

;

("(cond ((p? e1) e2 e3) ((q? e4) e5) (else e1 e2 e3))",
 ScmPair
  (ScmSymbol "cond",
   ScmPair
    (ScmPair
      (ScmPair (ScmSymbol "p?", ScmPair (ScmSymbol "e1", ScmNil)),
       ScmPair (ScmSymbol "e2", ScmPair (ScmSymbol "e3", ScmNil))),
     ScmPair
      (ScmPair
        (ScmPair (ScmSymbol "q?", ScmPair (ScmSymbol "e4", ScmNil)),
         ScmPair (ScmSymbol "e5", ScmNil)),
       ScmPair
        (ScmPair
          (ScmSymbol "else",
           ScmPair
            (ScmSymbol "e1",
             ScmPair (ScmSymbol "e2", ScmPair (ScmSymbol "e3", ScmNil)))),
         ScmNil)))),
 ScmIf (ScmApplic (ScmVarGet (Var "p?"), [ScmVarGet (Var "e1")]),
  ScmSeq [ScmVarGet (Var "e2"); ScmVarGet (Var "e3")],
  ScmIf (ScmApplic (ScmVarGet (Var "q?"), [ScmVarGet (Var "e4")]),
   ScmVarGet (Var "e5"),
   ScmSeq [ScmVarGet (Var "e1"); ScmVarGet (Var "e2"); ScmVarGet (Var "e3")])),
 ScmIf'
  (ScmApplic' (ScmVarGet' (Var' ("p?", Free)),
    [ScmVarGet' (Var' ("e1", Free))], Non_Tail_Call),
  ScmSeq' [ScmVarGet' (Var' ("e2", Free)); ScmVarGet' (Var' ("e3", Free))],
  ScmIf'
   (ScmApplic' (ScmVarGet' (Var' ("q?", Free)),
     [ScmVarGet' (Var' ("e4", Free))], Non_Tail_Call),
   ScmVarGet' (Var' ("e5", Free)),
   ScmSeq'
    [ScmVarGet' (Var' ("e1", Free)); ScmVarGet' (Var' ("e2", Free));
     ScmVarGet' (Var' ("e3", Free))])))

;

("(cond ((a? e1) e2) ((b? e2) e3 e4) ((foo x) => grab) (else e5 e6))",
 ScmPair
  (ScmSymbol "cond",
   ScmPair
    (ScmPair
      (ScmPair (ScmSymbol "a?", ScmPair (ScmSymbol "e1", ScmNil)),
       ScmPair (ScmSymbol "e2", ScmNil)),
     ScmPair
      (ScmPair
        (ScmPair (ScmSymbol "b?", ScmPair (ScmSymbol "e2", ScmNil)),
         ScmPair (ScmSymbol "e3", ScmPair (ScmSymbol "e4", ScmNil))),
       ScmPair
        (ScmPair
          (ScmPair (ScmSymbol "foo", ScmPair (ScmSymbol "x", ScmNil)),
           ScmPair (ScmSymbol "=>", ScmPair (ScmSymbol "grab", ScmNil))),
         ScmPair
          (ScmPair
            (ScmSymbol "else",
             ScmPair (ScmSymbol "e5", ScmPair (ScmSymbol "e6", ScmNil))),
           ScmNil))))),
 ScmIf (ScmApplic (ScmVarGet (Var "a?"), [ScmVarGet (Var "e1")]),
  ScmVarGet (Var "e2"),
  ScmIf (ScmApplic (ScmVarGet (Var "b?"), [ScmVarGet (Var "e2")]),
   ScmSeq [ScmVarGet (Var "e3"); ScmVarGet (Var "e4")],
   ScmApplic
    (ScmLambda (["value"; "f"; "rest"], Simple,
      ScmIf (ScmVarGet (Var "value"),
       ScmApplic (ScmApplic (ScmVarGet (Var "f"), []),
        [ScmVarGet (Var "value")]),
       ScmApplic (ScmVarGet (Var "rest"), []))),
    [ScmApplic (ScmVarGet (Var "foo"), [ScmVarGet (Var "x")]);
     ScmLambda ([], Simple, ScmVarGet (Var "grab"));
     ScmLambda ([], Simple,
      ScmSeq [ScmVarGet (Var "e5"); ScmVarGet (Var "e6")])]))),
 ScmIf'
  (ScmApplic' (ScmVarGet' (Var' ("a?", Free)),
    [ScmVarGet' (Var' ("e1", Free))], Non_Tail_Call),
  ScmVarGet' (Var' ("e2", Free)),
  ScmIf'
   (ScmApplic' (ScmVarGet' (Var' ("b?", Free)),
     [ScmVarGet' (Var' ("e2", Free))], Non_Tail_Call),
   ScmSeq' [ScmVarGet' (Var' ("e3", Free)); ScmVarGet' (Var' ("e4", Free))],
   ScmApplic'
    (ScmLambda' (["value"; "f"; "rest"], Simple,
      ScmIf' (ScmVarGet' (Var' ("value", Param 0)),
       ScmApplic'
        (ScmApplic' (ScmVarGet' (Var' ("f", Param 1)), [], Non_Tail_Call),
        [ScmVarGet' (Var' ("value", Param 0))], Tail_Call),
       ScmApplic' (ScmVarGet' (Var' ("rest", Param 2)), [], Tail_Call))),
    [ScmApplic' (ScmVarGet' (Var' ("foo", Free)),
      [ScmVarGet' (Var' ("x", Free))], Non_Tail_Call);
     ScmLambda' ([], Simple, ScmVarGet' (Var' ("grab", Free)));
     ScmLambda' ([], Simple,
      ScmSeq'
       [ScmVarGet' (Var' ("e5", Free)); ScmVarGet' (Var' ("e6", Free))])],
    Non_Tail_Call))))

;

("(lambda (a b c . d) (a (lambda (x y . z) (a b c x (lambda w (list a b c d e f g x y z w))))))",
 ScmPair
  (ScmSymbol "lambda",
   ScmPair
    (ScmPair
      (ScmSymbol "a",
       ScmPair (ScmSymbol "b", ScmPair (ScmSymbol "c", ScmSymbol "d"))),
     ScmPair
      (ScmPair
        (ScmSymbol "a",
         ScmPair
          (ScmPair
            (ScmSymbol "lambda",
             ScmPair
              (ScmPair
                (ScmSymbol "x", ScmPair (ScmSymbol "y", ScmSymbol "z")),
               ScmPair
                (ScmPair
                  (ScmSymbol "a",
                   ScmPair
                    (ScmSymbol "b",
                     ScmPair
                      (ScmSymbol "c",
                       ScmPair
                        (ScmSymbol "x",
                         ScmPair
                          (ScmPair
                            (ScmSymbol "lambda",
                             ScmPair
                              (ScmSymbol "w",
                               ScmPair
                                (ScmPair
                                  (ScmSymbol "list",
                                   ScmPair
                                    (ScmSymbol "a",
                                     ScmPair
                                      (ScmSymbol "b",
                                       ScmPair
                                        (ScmSymbol "c",
                                         ScmPair
                                          (ScmSymbol "d",
                                           ScmPair
                                            (ScmSymbol "e",
                                             ScmPair
                                              (ScmSymbol "f",
                                               ScmPair
                                                (ScmSymbol "g",
                                                 ScmPair
                                                  (ScmSymbol "x",
                                                   ScmPair
                                                    (ScmSymbol "y",
                                                     ScmPair
                                                      (ScmSymbol "z",
                                                       ScmPair
                                                        (ScmSymbol "w",
                                                         ScmNil)))))))))))),
                                 ScmNil))),
                           ScmNil))))),
                 ScmNil))),
           ScmNil)),
       ScmNil))),
 ScmLambda (["a"; "b"; "c"], Opt "d",
  ScmApplic (ScmVarGet (Var "a"),
   [ScmLambda (["x"; "y"], Opt "z",
     ScmApplic (ScmVarGet (Var "a"),
      [ScmVarGet (Var "b"); ScmVarGet (Var "c"); ScmVarGet (Var "x");
       ScmLambda ([], Opt "w",
        ScmApplic (ScmVarGet (Var "list"),
         [ScmVarGet (Var "a"); ScmVarGet (Var "b"); ScmVarGet (Var "c");
          ScmVarGet (Var "d"); ScmVarGet (Var "e"); ScmVarGet (Var "f");
          ScmVarGet (Var "g"); ScmVarGet (Var "x"); ScmVarGet (Var "y");
          ScmVarGet (Var "z"); ScmVarGet (Var "w")]))]))])),
 ScmLambda' (["a"; "b"; "c"], Opt "d",
  ScmApplic' (ScmVarGet' (Var' ("a", Param 0)),
   [ScmLambda' (["x"; "y"], Opt "z",
     ScmApplic' (ScmVarGet' (Var' ("a", Bound (0, 0))),
      [ScmVarGet' (Var' ("b", Bound (0, 1)));
       ScmVarGet' (Var' ("c", Bound (0, 2)));
       ScmVarGet' (Var' ("x", Param 0));
       ScmLambda' ([], Opt "w",
        ScmApplic' (ScmVarGet' (Var' ("list", Free)),
         [ScmVarGet' (Var' ("a", Bound (1, 0)));
          ScmVarGet' (Var' ("b", Bound (1, 1)));
          ScmVarGet' (Var' ("c", Bound (1, 2)));
          ScmVarGet' (Var' ("d", Bound (1, 3)));
          ScmVarGet' (Var' ("e", Free)); ScmVarGet' (Var' ("f", Free));
          ScmVarGet' (Var' ("g", Free));
          ScmVarGet' (Var' ("x", Bound (0, 0)));
          ScmVarGet' (Var' ("y", Bound (0, 1)));
          ScmVarGet' (Var' ("z", Bound (0, 2)));
          ScmVarGet' (Var' ("w", Param 0))],
         Tail_Call))],
      Tail_Call))],
   Tail_Call)))

;

("(lambda (x) (list (lambda () x) (lambda (y) (set! x y))))",
 ScmPair
  (ScmSymbol "lambda",
   ScmPair
    (ScmPair (ScmSymbol "x", ScmNil),
     ScmPair
      (ScmPair
        (ScmSymbol "list",
         ScmPair
          (ScmPair
            (ScmSymbol "lambda",
             ScmPair (ScmNil, ScmPair (ScmSymbol "x", ScmNil))),
           ScmPair
            (ScmPair
              (ScmSymbol "lambda",
               ScmPair
                (ScmPair (ScmSymbol "y", ScmNil),
                 ScmPair
                  (ScmPair
                    (ScmSymbol "set!",
                     ScmPair (ScmSymbol "x", ScmPair (ScmSymbol "y", ScmNil))),
                   ScmNil))),
             ScmNil))),
       ScmNil))),
 ScmLambda (["x"], Simple,
  ScmApplic (ScmVarGet (Var "list"),
   [ScmLambda ([], Simple, ScmVarGet (Var "x"));
    ScmLambda (["y"], Simple, ScmVarSet (Var "x", ScmVarGet (Var "y")))])),
 ScmLambda' (["x"], Simple,
  ScmSeq'
   [ScmVarSet' (Var' ("x", Param 0), ScmBox' (Var' ("x", Param 0)));
    ScmApplic' (ScmVarGet' (Var' ("list", Free)),
     [ScmLambda' ([], Simple, ScmBoxGet' (Var' ("x", Bound (0, 0))));
      ScmLambda' (["y"], Simple,
       ScmBoxSet' (Var' ("x", Bound (0, 0)),
        ScmVarGet' (Var' ("y", Param 0))))],
     Tail_Call)]))

;

("(lambda (x y) (list y (begin (set! y 'moshe) 'yossi) (lambda () x) (lambda (y) (set! x y))))",
 ScmPair
  (ScmSymbol "lambda",
   ScmPair
    (ScmPair (ScmSymbol "x", ScmPair (ScmSymbol "y", ScmNil)),
     ScmPair
      (ScmPair
        (ScmSymbol "list",
         ScmPair
          (ScmSymbol "y",
           ScmPair
            (ScmPair
              (ScmSymbol "begin",
               ScmPair
                (ScmPair
                  (ScmSymbol "set!",
                   ScmPair
                    (ScmSymbol "y",
                     ScmPair
                      (ScmPair
                        (ScmSymbol "quote",
                         ScmPair (ScmSymbol "moshe", ScmNil)),
                       ScmNil))),
                 ScmPair
                  (ScmPair
                    (ScmSymbol "quote", ScmPair (ScmSymbol "yossi", ScmNil)),
                   ScmNil))),
             ScmPair
              (ScmPair
                (ScmSymbol "lambda",
                 ScmPair (ScmNil, ScmPair (ScmSymbol "x", ScmNil))),
               ScmPair
                (ScmPair
                  (ScmSymbol "lambda",
                   ScmPair
                    (ScmPair (ScmSymbol "y", ScmNil),
                     ScmPair
                      (ScmPair
                        (ScmSymbol "set!",
                         ScmPair
                          (ScmSymbol "x", ScmPair (ScmSymbol "y", ScmNil))),
                       ScmNil))),
                 ScmNil))))),
       ScmNil))),
 ScmLambda (["x"; "y"], Simple,
  ScmApplic (ScmVarGet (Var "list"),
   [ScmVarGet (Var "y");
    ScmSeq
     [ScmVarSet (Var "y", ScmConst (ScmSymbol "moshe"));
      ScmConst (ScmSymbol "yossi")];
    ScmLambda ([], Simple, ScmVarGet (Var "x"));
    ScmLambda (["y"], Simple, ScmVarSet (Var "x", ScmVarGet (Var "y")))])),
 ScmLambda' (["x"; "y"], Simple,
  ScmSeq'
   [ScmVarSet' (Var' ("x", Param 0), ScmBox' (Var' ("x", Param 0)));
    ScmApplic' (ScmVarGet' (Var' ("list", Free)),
     [ScmVarGet' (Var' ("y", Param 1));
      ScmSeq'
       [ScmVarSet' (Var' ("y", Param 1), ScmConst' (ScmSymbol "moshe"));
        ScmConst' (ScmSymbol "yossi")];
      ScmLambda' ([], Simple, ScmBoxGet' (Var' ("x", Bound (0, 0))));
      ScmLambda' (["y"], Simple,
       ScmBoxSet' (Var' ("x", Bound (0, 0)),
        ScmVarGet' (Var' ("y", Param 0))))],
     Tail_Call)]))

;

("(lambda (x) (x (lambda (y) (x (lambda (y) (x (lambda (y) (x x))))))))",
 ScmPair
  (ScmSymbol "lambda",
   ScmPair
    (ScmPair (ScmSymbol "x", ScmNil),
     ScmPair
      (ScmPair
        (ScmSymbol "x",
         ScmPair
          (ScmPair
            (ScmSymbol "lambda",
             ScmPair
              (ScmPair (ScmSymbol "y", ScmNil),
               ScmPair
                (ScmPair
                  (ScmSymbol "x",
                   ScmPair
                    (ScmPair
                      (ScmSymbol "lambda",
                       ScmPair
                        (ScmPair (ScmSymbol "y", ScmNil),
                         ScmPair
                          (ScmPair
                            (ScmSymbol "x",
                             ScmPair
                              (ScmPair
                                (ScmSymbol "lambda",
                                 ScmPair
                                  (ScmPair (ScmSymbol "y", ScmNil),
                                   ScmPair
                                    (ScmPair
                                      (ScmSymbol "x",
                                       ScmPair (ScmSymbol "x", ScmNil)),
                                     ScmNil))),
                               ScmNil)),
                           ScmNil))),
                     ScmNil)),
                 ScmNil))),
           ScmNil)),
       ScmNil))),
 ScmLambda (["x"], Simple,
  ScmApplic (ScmVarGet (Var "x"),
   [ScmLambda (["y"], Simple,
     ScmApplic (ScmVarGet (Var "x"),
      [ScmLambda (["y"], Simple,
        ScmApplic (ScmVarGet (Var "x"),
         [ScmLambda (["y"], Simple,
           ScmApplic (ScmVarGet (Var "x"), [ScmVarGet (Var "x")]))]))]))])),
 ScmLambda' (["x"], Simple,
  ScmApplic' (ScmVarGet' (Var' ("x", Param 0)),
   [ScmLambda' (["y"], Simple,
     ScmApplic' (ScmVarGet' (Var' ("x", Bound (0, 0))),
      [ScmLambda' (["y"], Simple,
        ScmApplic' (ScmVarGet' (Var' ("x", Bound (1, 0))),
         [ScmLambda' (["y"], Simple,
           ScmApplic' (ScmVarGet' (Var' ("x", Bound (2, 0))),
            [ScmVarGet' (Var' ("x", Bound (2, 0)))], Tail_Call))],
         Tail_Call))],
      Tail_Call))],
   Tail_Call)))

;

("(let ((a 1) (b 2) (c 3)) (+ a b c))",
 ScmPair
  (ScmSymbol "let",
   ScmPair
    (ScmPair
      (ScmPair (ScmSymbol "a", ScmPair (ScmNumber (ScmInteger 1), ScmNil)),
       ScmPair
        (ScmPair (ScmSymbol "b", ScmPair (ScmNumber (ScmInteger 2), ScmNil)),
         ScmPair
          (ScmPair
            (ScmSymbol "c", ScmPair (ScmNumber (ScmInteger 3), ScmNil)),
           ScmNil))),
     ScmPair
      (ScmPair
        (ScmSymbol "+",
         ScmPair
          (ScmSymbol "a",
           ScmPair (ScmSymbol "b", ScmPair (ScmSymbol "c", ScmNil)))),
       ScmNil))),
 ScmApplic
  (ScmLambda (["a"; "b"; "c"], Simple,
    ScmApplic (ScmVarGet (Var "+"),
     [ScmVarGet (Var "a"); ScmVarGet (Var "b"); ScmVarGet (Var "c")])),
  [ScmConst (ScmNumber (ScmInteger 1)); ScmConst (ScmNumber (ScmInteger 2));
   ScmConst (ScmNumber (ScmInteger 3))]),
 ScmApplic'
  (ScmLambda' (["a"; "b"; "c"], Simple,
    ScmApplic' (ScmVarGet' (Var' ("+", Free)),
     [ScmVarGet' (Var' ("a", Param 0)); ScmVarGet' (Var' ("b", Param 1));
      ScmVarGet' (Var' ("c", Param 2))],
     Tail_Call)),
  [ScmConst' (ScmNumber (ScmInteger 1));
   ScmConst' (ScmNumber (ScmInteger 2));
   ScmConst' (ScmNumber (ScmInteger 3))],
  Non_Tail_Call))

;

("(or e1 e2 e3)",
 ScmPair
  (ScmSymbol "or",
   ScmPair
    (ScmSymbol "e1",
     ScmPair (ScmSymbol "e2", ScmPair (ScmSymbol "e3", ScmNil)))),
 ScmOr [ScmVarGet (Var "e1"); ScmVarGet (Var "e2"); ScmVarGet (Var "e3")],
 ScmOr'
  [ScmVarGet' (Var' ("e1", Free)); ScmVarGet' (Var' ("e2", Free));
   ScmVarGet' (Var' ("e3", Free))])

;

("(or e1 e2)",
 ScmPair
  (ScmSymbol "or",
   ScmPair (ScmSymbol "e1", ScmPair (ScmSymbol "e2", ScmNil))),
 ScmOr [ScmVarGet (Var "e1"); ScmVarGet (Var "e2")],
 ScmOr' [ScmVarGet' (Var' ("e1", Free)); ScmVarGet' (Var' ("e2", Free))])

;

("(or e)", ScmPair (ScmSymbol "or", ScmPair (ScmSymbol "e", ScmNil)),
 ScmVarGet (Var "e"), ScmVarGet' (Var' ("e", Free)))

;

("(or)", ScmPair (ScmSymbol "or", ScmNil), ScmConst (ScmBoolean false),
 ScmConst' (ScmBoolean false))

;

("(define fact (lambda (n) (if (zero? n) 1 `(* ,n ,(fact (- n 1))))))",
 ScmPair
  (ScmSymbol "define",
   ScmPair
    (ScmSymbol "fact",
     ScmPair
      (ScmPair
        (ScmSymbol "lambda",
         ScmPair
          (ScmPair (ScmSymbol "n", ScmNil),
           ScmPair
            (ScmPair
              (ScmSymbol "if",
               ScmPair
                (ScmPair (ScmSymbol "zero?", ScmPair (ScmSymbol "n", ScmNil)),
                 ScmPair
                  (ScmNumber (ScmInteger 1),
                   ScmPair
                    (ScmPair
                      (ScmSymbol "quasiquote",
                       ScmPair
                        (ScmPair
                          (ScmSymbol "*",
                           ScmPair
                            (ScmPair
                              (ScmSymbol "unquote",
                               ScmPair (ScmSymbol "n", ScmNil)),
                             ScmPair
                              (ScmPair
                                (ScmSymbol "unquote",
                                 ScmPair
                                  (ScmPair
                                    (ScmSymbol "fact",
                                     ScmPair
                                      (ScmPair
                                        (ScmSymbol "-",
                                         ScmPair
                                          (ScmSymbol "n",
                                           ScmPair
                                            (ScmNumber (ScmInteger 1),
                                             ScmNil))),
                                       ScmNil)),
                                   ScmNil)),
                               ScmNil))),
                         ScmNil)),
                     ScmNil)))),
             ScmNil))),
       ScmNil))),
 ScmVarDef (Var "fact",
  ScmLambda (["n"], Simple,
   ScmIf (ScmApplic (ScmVarGet (Var "zero?"), [ScmVarGet (Var "n")]),
    ScmConst (ScmNumber (ScmInteger 1)),
    ScmApplic (ScmVarGet (Var "cons"),
     [ScmConst (ScmSymbol "*");
      ScmApplic (ScmVarGet (Var "cons"),
       [ScmVarGet (Var "n");
        ScmApplic (ScmVarGet (Var "cons"),
         [ScmApplic (ScmVarGet (Var "fact"),
           [ScmApplic (ScmVarGet (Var "-"),
             [ScmVarGet (Var "n"); ScmConst (ScmNumber (ScmInteger 1))])]);
          ScmConst ScmNil])])])))),
 ScmVarDef' (Var' ("fact", Free),
  ScmLambda' (["n"], Simple,
   ScmIf'
    (ScmApplic' (ScmVarGet' (Var' ("zero?", Free)),
      [ScmVarGet' (Var' ("n", Param 0))], Non_Tail_Call),
    ScmConst' (ScmNumber (ScmInteger 1)),
    ScmApplic' (ScmVarGet' (Var' ("cons", Free)),
     [ScmConst' (ScmSymbol "*");
      ScmApplic' (ScmVarGet' (Var' ("cons", Free)),
       [ScmVarGet' (Var' ("n", Param 0));
        ScmApplic' (ScmVarGet' (Var' ("cons", Free)),
         [ScmApplic' (ScmVarGet' (Var' ("fact", Free)),
           [ScmApplic' (ScmVarGet' (Var' ("-", Free)),
             [ScmVarGet' (Var' ("n", Param 0));
              ScmConst' (ScmNumber (ScmInteger 1))],
             Non_Tail_Call)],
           Non_Tail_Call);
          ScmConst' ScmNil],
         Non_Tail_Call)],
       Non_Tail_Call)],
     Tail_Call)))))

;

("(begin expr)",
 ScmPair (ScmSymbol "begin", ScmPair (ScmSymbol "expr", ScmNil)),
 ScmVarGet (Var "expr"), ScmVarGet' (Var' ("expr", Free)))

;

("(begin expr1 expr2 expr3)",
 ScmPair
  (ScmSymbol "begin",
   ScmPair
    (ScmSymbol "expr1",
     ScmPair (ScmSymbol "expr2", ScmPair (ScmSymbol "expr3", ScmNil)))),
 ScmSeq
  [ScmVarGet (Var "expr1"); ScmVarGet (Var "expr2"); ScmVarGet (Var "expr3")],
 ScmSeq'
  [ScmVarGet' (Var' ("expr1", Free)); ScmVarGet' (Var' ("expr2", Free));
   ScmVarGet' (Var' ("expr3", Free))])

;
("(lambda (x) x x x x x)",
 ScmPair
  (ScmSymbol "lambda",
   ScmPair
    (ScmSymbol "x",
     ScmPair
      (ScmSymbol "x",
       ScmPair
        (ScmSymbol "x",
         ScmPair
          (ScmSymbol "x",
           ScmPair (ScmSymbol "x", ScmPair (ScmSymbol "x", ScmNil))))))),
 ScmLambda ([], Opt "x",
  ScmSeq
   [ScmVarGet (Var "x"); ScmVarGet (Var "x"); ScmVarGet (Var "x");
    ScmVarGet (Var "x"); ScmVarGet (Var "x")]),
 ScmLambda' ([], Opt "x",
  ScmSeq'
   [ScmVarGet' (Var' ("x", Param 0)); ScmVarGet' (Var' ("x", Param 0));
    ScmVarGet' (Var' ("x", Param 0)); ScmVarGet' (Var' ("x", Param 0));
    ScmVarGet' (Var' ("x", Param 0))]))
];;