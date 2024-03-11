(* compiler.ml
 * A template compiler for the compiler course
 *
 * Programmer: Mayer Goldberg, 2024
 *)

#use "pc.ml";;

exception X_not_yet_implemented of string;;
exception X_this_should_not_happen of string;;

let split_to_sublists n = 
  let rec run = function
    | ([], _, f) -> [f []]
    | (s, 0, f) -> (f []) :: (run (s, n, (fun s -> s)))
    | (a :: s, i, f) ->
       (run (s, i - 1, (fun s -> f (a :: s))))
  in function
  | [] -> []
  | s -> run (s, n, (fun s -> s));;

let rec gcd a b =
  match (a, b) with
  | (0, b) -> b
  | (a, 0) -> a
  | (a, b) -> gcd b (a mod b);;

  module Float = struct
    let pow x y =
      if y = 0.0 then 1.0
      else if y > 0.0 then
        let rec pow_positive x y acc =
          if y = 0.0 then acc
          else pow_positive x (y -. 1.0) (acc *. x)
        in
        pow_positive x y 1.0
      else
        let rec pow_negative x y acc =
          if y = 0.0 then acc
          else pow_negative x (y +. 1.0) (acc /. x)
        in
        pow_negative x y 1.0
  end;;

  

type scm_number =
  | ScmInteger of int
  | ScmFraction of (int * int)
  | ScmReal of float;;

type sexpr =
  | ScmVoid
  | ScmNil
  | ScmBoolean of bool
  | ScmChar of char
  | ScmString of string
  | ScmSymbol of string
  | ScmNumber of scm_number
  | ScmVector of (sexpr list)
  | ScmPair of (sexpr * sexpr);;

module type READER = sig
  val nt_sexpr : sexpr PC.parser
end;; (* end of READER signature *)

module Reader : READER = struct
  open PC;;

  type string_part =
    | Static of string
    | Dynamic of sexpr;;

  let unitify nt = pack nt (fun _ -> ());;

  let make_maybe nt none_value =
    pack (maybe nt)
      (function
       | None -> none_value
       | Some(x) -> x);;  

  let rec nt_whitespace str =
    const (fun ch -> ch <= ' ') str
  and nt_end_of_line_or_file str = 
    let nt1 = unitify (char '\n') in
    let nt2 = unitify nt_end_of_input in
    let nt1 = disj nt1 nt2 in
    nt1 str
  and nt_line_comment str =
    let nt1 = char ';' in
    let nt2 = diff nt_any nt_end_of_line_or_file in
    let nt2 = star nt2 in
    let nt1 = caten nt1 nt2 in
    let nt1 = caten nt1 nt_end_of_line_or_file in
    let nt1 = unitify nt1 in
    nt1 str
  and nt_paired_comment str =
    let nt1 = diff (diff nt_any (one_of "{}")) nt_char in
    let nt1 = diff (diff nt1 nt_string) nt_paired_comment in
    let nt1 = unitify nt1 in
    let nt1 = disj nt1 (disj (unitify nt_char) (unitify nt_string)) in
    let nt1 = star (disj nt1 nt_paired_comment) in
    let nt1 = caten (char '{') (caten nt1 (char '}')) in
    let nt1 = unitify nt1 in
    nt1 str
  and nt_sexpr_comment str =
    let nt1 = word "#;" in
    let nt1 = caten nt1 nt_sexpr in
    let nt1 = unitify nt1 in
    nt1 str
  and nt_comment str =
    disj_list
      [nt_line_comment;
       nt_paired_comment;
       nt_sexpr_comment] str
  and nt_void str =
    let nt1 = word_ci "#void" in
    let nt1 = not_followed_by nt1 nt_symbol_char in
    let nt1 = pack nt1 (fun _ -> ScmVoid) in
    nt1 str
  and nt_skip_star str =
    let nt1 = disj (unitify nt_whitespace) nt_comment in
    let nt1 = unitify (star nt1) in
    nt1 str
  and make_skipped_star (nt : 'a parser) =
    let nt1 = caten nt_skip_star (caten nt nt_skip_star) in
    let nt1 = pack nt1 (fun (_, (e, _)) -> e) in
    nt1
  and nt_digit str =
    let nt1 = range '0' '9' in
    let nt1 = pack nt1 (let delta = int_of_char '0' in
                        fun ch -> (int_of_char ch) - delta) in
    nt1 str
  and nt_hex_digit str =
    let nt1 = range_ci 'a' 'f' in
    let nt1 = pack nt1 Char.lowercase_ascii in
    let nt1 = pack nt1 (let delta = int_of_char 'a' - 10 in
                        fun ch -> (int_of_char ch) - delta) in
    let nt1 = disj nt_digit nt1 in
    nt1 str
  and nt_nat str =
    let nt1 = plus nt_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_left
                    (fun num digit -> 10 * num + digit)
                    0
                    digits) in
    nt1 str
  and nt_hex_nat str =
    let nt1 = plus nt_hex_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_left
                    (fun num digit ->
                      16 * num + digit)
                    0
                    digits) in
    nt1 str
  and nt_optional_sign str =
    let nt1 = char '+' in
    let nt1 = pack nt1 (fun _ -> true) in
    let nt2 = char '-' in
    let nt2 = pack nt2 (fun _ -> false) in
    let nt1 = disj nt1 nt2 in
    let nt1 = make_maybe nt1 true in
    nt1 str
  and nt_int str =
    let nt1 = caten nt_optional_sign nt_nat in
    let nt1 = pack nt1
                (fun (is_positive, n) ->
                  if is_positive then n else -n) in
    nt1 str
  and nt_frac str =
    let nt1 = caten nt_int (char '/') in
    let nt1 = pack nt1 (fun (num, _) -> num) in
    let nt2 = only_if nt_nat (fun n -> n != 0) in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1
                (fun (num, den) ->
                  let d = gcd (abs num) (abs den) in
                  let num = num / d
                  and den = den / d in
                  (match num, den with
                   | 0, _ -> ScmInteger 0
                   | num, 1 -> ScmInteger num
                   | num, den -> ScmFraction(num, den))) in
    nt1 str
  and nt_integer_part str =
    let nt1 = plus nt_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_left
                    (fun num digit -> 10.0 *. num +. (float_of_int digit))
                    0.0
                    digits) in
    nt1 str
  and nt_mantissa str =
    let nt1 = plus nt_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_right
                    (fun digit num ->
                      ((float_of_int digit) +. num) /. 10.0)
                    digits
                    0.0) in
    nt1 str
  and nt_exponent str =
    let nt1 = unitify (char_ci 'e') in
    let nt2 = word "*10" in
    let nt3 = unitify (word "**") in
    let nt4 = unitify (char '^') in
    let nt3 = disj nt3 nt4 in
    let nt2 = caten nt2 nt3 in
    let nt2 = unitify nt2 in
    let nt1 = disj nt1 nt2 in
    let nt1 = caten nt1 nt_int in
    let nt1 = pack nt1 (fun (_, n) -> Float.pow 10. (float_of_int n)) in
    nt1 str
  and nt_float str =
    let nt1 = nt_optional_sign in

    (* form-1: 23.{34}{e+4} *)
    let nt2 = nt_integer_part in
    let nt3 = char '.' in
    let nt4 = make_maybe nt_mantissa 0.0 in
    let nt5 = make_maybe nt_exponent 1.0 in
    let nt2 = caten nt2 (caten nt3 (caten nt4 nt5)) in
    let nt2 = pack nt2
                (fun (ip, (_, (mant, expo))) ->
                  (ip +. mant) *. expo) in

    (* form-2: .34{e+4} *)
    let nt3 = char '.' in
    let nt4 = nt_mantissa in
    let nt5 = make_maybe nt_exponent 1.0 in
    let nt3 = caten nt3 (caten nt4 nt5) in
    let nt3 = pack nt3
                (fun (_, (mant, expo)) ->
                  mant *. expo) in

    (* form-3: 12e-4 *)
    let nt4 = caten nt_integer_part nt_exponent in
    let nt4 = pack nt4
                (fun (ip, expo) ->
                  ip *. expo) in
    let nt2 = disj nt2 (disj nt3 nt4) in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (function
                  | (false, x) -> (-. x)
                  | (true, x) -> x) in
    let nt1 = pack nt1 (fun x -> ScmReal x) in
    nt1 str
  and nt_number str =
    let nt1 = nt_float in
    let nt2 = nt_frac in
    let nt3 = pack nt_int (fun n -> ScmInteger n) in
    let nt1 = disj nt1 (disj nt2 nt3) in
    let nt1 = pack nt1 (fun r -> ScmNumber r) in
    let nt1 = not_followed_by nt1 nt_symbol_char in
    nt1 str  
  and nt_boolean str =
    let nt1 = char '#' in
    let nt2 = char_ci 'f' in
    let nt2 = pack nt2 (fun _ -> ScmBoolean false) in
    let nt3 = char_ci 't' in
    let nt3 = pack nt3 (fun _ -> ScmBoolean true) in
    let nt2 = disj nt2 nt3 in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (fun (_, value) -> value) in
    let nt2 = nt_symbol_char in
    let nt1 = not_followed_by nt1 nt2 in
    nt1 str
  and nt_char_simple str =
    let nt1 = const(fun ch -> ' ' < ch) in
    let nt1 = not_followed_by nt1 nt_symbol_char in
    nt1 str
  and make_named_char char_name ch =
    pack (word_ci char_name) (fun _ -> ch)
  and nt_char_named str =
    let nt1 =
      disj_list [(make_named_char "nul" '\000');
                 (make_named_char "alarm" '\007');
                 (make_named_char "backspace" '\008');
                 (make_named_char "page" '\012');
                 (make_named_char "space" ' ');
                 (make_named_char "newline" '\n');
                 (make_named_char "return" '\r');
                 (make_named_char "tab" '\t')] in
    nt1 str
  and nt_char_hex str =
    let nt1 = caten (char_ci 'x') nt_hex_nat in
    let nt1 = pack nt1 (fun (_, n) -> n) in
    let nt1 = only_if nt1 (fun n -> n < 256) in
    let nt1 = pack nt1 (fun n -> char_of_int n) in
    nt1 str  
  and nt_char str =
    let nt1 = word "#\\" in
    let nt2 = disj nt_char_simple (disj nt_char_named nt_char_hex) in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (fun (_, ch) -> ScmChar ch) in
    nt1 str
  and nt_symbol_char str =
    let nt1 = range_ci 'a' 'z' in
    let nt1 = pack nt1 Char.lowercase_ascii in
    let nt2 = range '0' '9' in
    let nt3 = one_of "!$^*_-+=<>?/" in
    let nt1 = disj nt1 (disj nt2 nt3) in
    nt1 str
  and nt_symbol str =
    let nt1 = plus nt_symbol_char in
    let nt1 = pack nt1 string_of_list in
    let nt1 = pack nt1 (fun name -> ScmSymbol name) in
    let nt1 = diff nt1 nt_number in
    nt1 str
  and nt_string_part_simple str =
    let nt1 =
      disj_list [unitify (char '"'); unitify (char '\\'); unitify (word "~~");
                 unitify nt_string_part_dynamic] in
    let nt1 = diff nt_any nt1 in
    nt1 str
  and nt_string_part_meta str =
    let nt1 =
      disj_list [pack (word "\\\\") (fun _ -> '\\');
                 pack (word "\\\"") (fun _ -> '"');
                 pack (word "\\n") (fun _ -> '\n');
                 pack (word "\\r") (fun _ -> '\r');
                 pack (word "\\f") (fun _ -> '\012');
                 pack (word "\\t") (fun _ -> '\t');
                 pack (word "~~") (fun _ -> '~')] in
    nt1 str
  and nt_string_part_hex str =
    let nt1 = word_ci "\\x" in
    let nt2 = nt_hex_nat in
    let nt2 = only_if nt2 (fun n -> n < 256) in
    let nt3 = char ';' in
    let nt1 = caten nt1 (caten nt2 nt3) in
    let nt1 = pack nt1 (fun (_, (n, _)) -> n) in
    let nt1 = pack nt1 char_of_int in
    nt1 str
  and nt_string_part_dynamic str =
    let nt1 = word "~{" in
    let nt2 = nt_sexpr in
    let nt3 = char '}' in
    let nt1 = caten nt1 (caten nt2 nt3) in
    let nt1 = pack nt1 (fun (_, (sexpr, _)) -> sexpr) in
    let nt1 = pack nt1 (fun sexpr ->
                  ScmPair(ScmSymbol "format",
                          ScmPair(ScmString "~a",
                                  ScmPair(sexpr, ScmNil)))) in
    let nt1 = pack nt1 (fun sexpr -> Dynamic sexpr) in
    nt1 str
  and nt_string_part_static str =
    let nt1 = disj_list [nt_string_part_simple;
                         nt_string_part_meta;
                         nt_string_part_hex] in
    let nt1 = plus nt1 in
    let nt1 = pack nt1 string_of_list in
    let nt1 = pack nt1 (fun str -> Static str) in
    nt1 str
  and nt_string_part str =
    disj nt_string_part_static nt_string_part_dynamic str
  and nt_string str =
    let nt1 = char '"' in
    let nt2 = star nt_string_part in
    let nt1 = caten nt1 (caten nt2 nt1) in
    let nt1 = pack nt1 (fun (_, (parts, _)) -> parts) in
    let nt1 = pack nt1
                (function
                 | [] -> ScmString ""
                 | [Static(str)] -> ScmString str
                 | [Dynamic(sexpr)] -> sexpr
                 | parts ->
                    let argl =
                      List.fold_right
                        (fun car cdr ->
                          ScmPair((match car with
                                   | Static(str) -> ScmString(str)
                                   | Dynamic(sexpr) -> sexpr),
                                  cdr))
                        parts
                        ScmNil in
                    ScmPair(ScmSymbol "string-append", argl)) in
    nt1 str
  and nt_vector str =
    let nt_hashtag = PC.char '#' in
    let nt_left_bracket = PC.word "(" in
    let nt_right_bracket = PC.word ")" in
    let nt_many_sexpr = PC.star(PC.caten nt_sexpr (unitify (PC.star nt_whitespace))) in
    let nt_many_sexpr = PC.caten (unitify (PC.caten nt_hashtag nt_left_bracket)) nt_many_sexpr in
    let nt_many_sexpr = PC.caten nt_many_sexpr (unitify nt_right_bracket) in
    let rec make_list sexprs = List.fold_right (fun (sexp , _) acc -> sexp :: acc ) sexprs [] in
    let pack_many_sexps = (fun nt -> pack nt (fun ((_, sexprs), _) -> ScmVector(make_list sexprs))) in
    (pack_many_sexps nt_many_sexpr) str
    
     and nt_list str =
    
      let nt_left_bracket = PC.word "(" in
      let nt_right_bracket = PC.word ")" in
      let nt_dot = PC.word "." in
      let nt_pair = (PC.caten (PC.caten (nt_sexpr) (unitify (caten_list [(PC.star nt_whitespace); nt_dot;(PC.star nt_whitespace)]))) nt_sexpr)  in
      let nt_pair = PC.caten (unitify nt_left_bracket) nt_pair in
      let nt_pair = PC.caten nt_pair (unitify nt_right_bracket) in
      let nt_many_sexpr_naked = PC.star(PC.caten nt_sexpr (unitify (PC.star nt_whitespace))) in
      let nt_many_sexpr = PC.caten (unitify nt_left_bracket) nt_many_sexpr_naked in
      let nt_many_sexpr = PC.caten nt_many_sexpr (unitify nt_right_bracket) in
      let nt_complex_sexpr = PC.caten (PC.caten nt_many_sexpr_naked nt_dot) nt_sexpr in
      let nt_complex_sexpr = PC.caten (unitify nt_left_bracket) nt_complex_sexpr in
      let nt_complex_sexpr = PC.caten nt_complex_sexpr (unitify nt_right_bracket) in
      let rec build_many_sexps listOfSexps = 
        match listOfSexps with
        | (sexp, _) :: rest -> ScmPair(sexp, build_many_sexps rest)
        | _ -> ScmNil in
      let build_pair (leftSexp,rightSexp) = ScmPair(leftSexp, rightSexp) in
      let pack_many_sexps = (fun nt -> pack nt (fun x -> 
        match x with 
        | ( (_, sexprs) , _) -> build_many_sexps sexprs
        | _ -> failwith "shouldnt happen"
        )) in
        let rec pack_complex_sexps = (fun nt -> pack nt (fun x -> 
          let rec run complex = 
            match complex with
            | (( (sexp,_) :: [], ['.']) ,afterDotSexp) -> ScmPair(sexp, afterDotSexp )
            | (( (sexp,_) :: rest, ['.']) ,afterDotSexp) -> ScmPair(sexp, run ((rest, ['.']), afterDotSexp) )
            | _ -> failwith "shouldnt reach here!" in
            
          match x with 
          | ( (_, complex_sexpr) , _) ->  run complex_sexpr
          | _ -> failwith "shouldnt happen"

          )) in
      let pack_pair = (fun nt -> pack nt (fun ((_,( (leftSexp,_),rightSexp)),_) -> build_pair(leftSexp,rightSexp))) in
      disj (*(disj (pack_pair nt_pair)*) (pack_many_sexps nt_many_sexpr) (pack_complex_sexps nt_complex_sexpr) str 

      (*88888888888888888888888888888888888888888888*)
  and make_quoted_form nt_qf qf_name =
    let nt1 = caten nt_qf nt_sexpr in
    let nt1 = pack nt1
                (fun (_, sexpr) ->
                  ScmPair(ScmSymbol qf_name,
                          ScmPair(sexpr, ScmNil))) in
    nt1
  and nt_quoted_forms str =
    let nt1 =
      disj_list [(make_quoted_form (unitify (char '\'')) "quote");
                 (make_quoted_form (unitify (char '`')) "quasiquote");
                 (make_quoted_form
                    (unitify (not_followed_by (char ',') (char '@')))
                    "unquote");
                 (make_quoted_form (unitify (word ",@")) "unquote-splicing")] in
    nt1 str
  and nt_sexpr str = 
    let nt1 =
      disj_list [nt_void; nt_number; nt_boolean; nt_char; nt_symbol;
                 nt_string; nt_quoted_forms; nt_vector; nt_list;] in
    let nt1 = make_skipped_star nt1 in
    nt1 str;;

end;; (* end of struct Reader *)

let read str = (Reader.nt_sexpr str 0).found;;

let rec string_of_sexpr = function
  | ScmVoid -> "#<void>"
  | ScmNil -> "()"
  | ScmBoolean(false) -> "#f"
  | ScmBoolean(true) -> "#t"
  | ScmChar('\000') -> "#\\nul"
  | ScmChar('\n') -> "#\\newline"
  | ScmChar('\r') -> "#\\return"
  | ScmChar('\012') -> "#\\page"
  | ScmChar('\t') -> "#\\tab"
  | ScmChar(' ') -> "#\\space"
  | ScmChar('\007') -> "#\\alarm"
  | ScmChar('\008') -> "#\\backspace"
  | ScmChar(ch) ->
     if (ch < ' ')
     then let n = int_of_char ch in
          Printf.sprintf "#\\x%x" n
     else Printf.sprintf "#\\%c" ch
  | ScmString(str) ->
     Printf.sprintf "\"%s\""
       (String.concat ""
          (List.map
             (function
              | '\n' -> "\\n"
              | '\012' -> "\\f"
              | '\r' -> "\\r"
              | '\t' -> "\\t"
              | '\"' -> "\\\""
              | ch ->
                 if (ch < ' ')
                 then Printf.sprintf "\\x%x;" (int_of_char ch)
                 else Printf.sprintf "%c" ch)
             (list_of_string str)))
  | ScmSymbol(sym) -> sym
  | ScmNumber(ScmInteger n) -> Printf.sprintf "%d" n
  | ScmNumber(ScmFraction(0, _)) -> "0"
  | ScmNumber(ScmFraction(num, 1)) -> Printf.sprintf "%d" num
  | ScmNumber(ScmFraction(num, -1)) -> Printf.sprintf "%d" (- num)
  | ScmNumber(ScmFraction(num, den)) -> Printf.sprintf "%d/%d" num den
  | ScmNumber(ScmReal(x)) -> Printf.sprintf "%f" x
  | ScmVector(sexprs) ->
     let strings = List.map string_of_sexpr sexprs in
     let inner_string = String.concat " " strings in
     Printf.sprintf "#(%s)" inner_string
  | ScmPair(ScmSymbol "quote",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf "'%s" (string_of_sexpr sexpr)
  | ScmPair(ScmSymbol "quasiquote",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf "`%s" (string_of_sexpr sexpr)
  | ScmPair(ScmSymbol "unquote",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf ",%s" (string_of_sexpr sexpr)
  | ScmPair(ScmSymbol "unquote-splicing",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf ",@%s" (string_of_sexpr sexpr)
  | ScmPair(car, cdr) ->
     string_of_sexpr' (string_of_sexpr car) cdr
and string_of_sexpr' car_string = function
  | ScmNil -> Printf.sprintf "(%s)" car_string
  | ScmPair(cadr, cddr) ->
     let new_car_string =
       Printf.sprintf "%s %s" car_string (string_of_sexpr cadr) in
     string_of_sexpr' new_car_string cddr
  | cdr ->
     let cdr_string = (string_of_sexpr cdr) in
     Printf.sprintf "(%s . %s)" car_string cdr_string;;

let print_sexpr chan sexpr = output_string chan (string_of_sexpr sexpr);;

let print_sexprs chan sexprs =
  output_string chan
    (Printf.sprintf "[%s]"
       (String.concat "; "
          (List.map string_of_sexpr sexprs)));;

let sprint_sexpr _ sexpr = string_of_sexpr sexpr;;

let sprint_sexprs chan sexprs =
  Printf.sprintf "[%s]"
    (String.concat "; "
       (List.map string_of_sexpr sexprs));;

let scheme_sexpr_list_of_sexpr_list sexprs =
  List.fold_right (fun car cdr -> ScmPair (car, cdr)) sexprs ScmNil;;

(* the tag-parser *)

exception X_syntax of string;;

type var = 
  | Var of string;;

type lambda_kind =
  | Simple
  | Opt of string;;

type expr =
  | ScmConst of sexpr
  | ScmVarGet of var
  | ScmIf of expr * expr * expr
  | ScmSeq of expr list
  | ScmOr of expr list
  | ScmVarSet of var * expr
  | ScmVarDef of var * expr
  | ScmLambda of string list * lambda_kind * expr
  | ScmApplic of expr * expr list;;

module type TAG_PARSER = sig
  val tag_parse : sexpr -> expr
  val test_cond_expand: sexpr list -> unit
  val macro_expand_cond_ribs: sexpr list -> sexpr
  val test_and_expand: sexpr -> sexpr list -> unit
  val macro_expand_and_clauses: sexpr -> sexpr list -> sexpr
  val scheme_list_to_ocaml: sexpr -> sexpr list * sexpr
end;;

module Tag_Parser : TAG_PARSER = struct
  open Reader;;
  
  let reserved_word_list =
    ["and"; "begin"; "cond"; "do"; "else"; "if"; "lambda";
     "let"; "let*"; "letrec"; "or"; "quasiquote"; "quote";
     "set!"; "unquote"; "unquote-splicing"];;

  let rec scheme_list_to_ocaml = function
    | ScmPair(car, cdr) ->
       ((fun (rdc, last) -> (car :: rdc, last))
          (scheme_list_to_ocaml cdr))  
    | rac -> ([], rac);;

  let is_reserved_word name = List.mem name reserved_word_list;;

  let unsymbolify_var = function
    | ScmSymbol var -> var
    | _ -> raise (X_syntax "not a symbol");;

  let unsymbolify_vars = List.map unsymbolify_var;;

  let list_contains_unquote_splicing =
    ormap (function
        | ScmPair (ScmSymbol "unquote-splicing",
                   ScmPair (_, ScmNil)) -> true
        | _ -> false);;

  let rec macro_expand_qq = function
    | ScmNil -> ScmPair (ScmSymbol "quote", ScmPair (ScmNil, ScmNil))
    | (ScmSymbol _) as sexpr ->
       ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))
    | ScmPair (ScmSymbol "unquote", ScmPair (sexpr, ScmNil)) -> sexpr
    | ScmPair (ScmPair (ScmSymbol "unquote",
                        ScmPair (car, ScmNil)),
               cdr) ->
       let cdr = macro_expand_qq cdr in
       ScmPair (ScmSymbol "cons", ScmPair (car, ScmPair (cdr, ScmNil)))
    | ScmPair (ScmPair (ScmSymbol "unquote-splicing",
                        ScmPair (sexpr, ScmNil)),
               ScmNil) ->
       sexpr
    | ScmPair (ScmPair (ScmSymbol "unquote-splicing",
                        ScmPair (car, ScmNil)), cdr) ->
       let cdr = macro_expand_qq cdr in
       ScmPair (ScmSymbol "append",
                ScmPair (car, ScmPair (cdr, ScmNil)))
    (* (a . b) --> (cons a b) *)
    | ScmPair (car, cdr) -> 
        let expanded_car=  macro_expand_qq car in
        let expanded_cdr= macro_expand_qq cdr in
        ScmPair (ScmSymbol "cons" , ScmPair(expanded_car, ScmPair(expanded_cdr, ScmNil)) )

       (* raise (X_not_yet_implemented "hw 1") *)
    | ScmVector sexprs ->
       if (list_contains_unquote_splicing sexprs)
       then let sexpr = macro_expand_qq
                          (scheme_sexpr_list_of_sexpr_list sexprs) in
            ScmPair (ScmSymbol "list->vector",
                     ScmPair (sexpr, ScmNil))
       else let sexprs = 
              (scheme_sexpr_list_of_sexpr_list
                 (List.map macro_expand_qq sexprs)) in
            ScmPair (ScmSymbol "vector", sexprs)
    | sexpr -> sexpr;;
    (* (and (expr) (dit)) --> (if expr dit #f) *)
  let rec macro_expand_and_clauses expr = function
    | [] -> expr
    | expr' :: exprs ->
       let dit = macro_expand_and_clauses expr' exprs in
       ScmPair (ScmSymbol "if",
                ScmPair (expr,
                         ScmPair (dit,
                                  ScmPair (ScmBoolean false,
                                           ScmNil))));;

    let test_and_expand exp1 expList =
      print_sexpr stdout (macro_expand_and_clauses exp1 expList)

(* (cond (rib1) (rib2) ...) --> *)
(* 1 ((expr1) (expr2) ...) *)
(* 2 ((expr1) => (expr2)) *)
(* 3 (else (expr1) (expr2) ...) *)
  let rec macro_expand_cond_ribs ribs = 
    match ribs with
    | [] -> ScmBoolean false
    | (cur :: rest) -> 
            match cur with
            | ScmPair(ScmSymbol("else") ,restOfExps) -> 
              ScmPair(ScmSymbol("begin"), restOfExps)
            | ScmPair(exp, ScmPair( ScmSymbol("=>") , expf)) ->
              let lambda1 = ScmPair (ScmSymbol "lambda", ScmPair (ScmNil, expf)) in 
              let lambda2 = ScmPair (ScmSymbol "lambda", ScmPair (ScmNil, ScmPair((macro_expand_cond_ribs rest), ScmNil ))) in
              let valueAssignment1 = ScmPair (ScmSymbol("value"),ScmPair (exp, ScmNil)) in
              let valueAssignment2 = ScmPair (ScmSymbol("f"),ScmPair (lambda1, ScmNil)) in
              let valueAssignment3 = ScmPair (ScmSymbol("rest"),ScmPair (lambda2, ScmNil)) in
              let ifExp = ScmPair (ScmSymbol "if", ScmPair (ScmSymbol("value"), ScmPair (ScmPair( ScmPair(ScmSymbol("f"),ScmNil) , ScmPair(ScmSymbol("value") , ScmNil) ), ScmPair (ScmPair(ScmSymbol("rest"),ScmNil), ScmNil)))) in
              ScmPair (ScmSymbol "let", ScmPair (ScmPair(valueAssignment1, ScmPair(valueAssignment2, ScmPair(valueAssignment3, ScmNil))), ScmPair(ifExp ,ScmNil)))
            | ScmPair(test, exps) -> 
              (* ScmPair (ScmSymbol "if", ScmPair (test, ScmPair (exps, ScmPair (macro_expand_cond_ribs rest, ScmNil))))  *)
                ScmPair (ScmSymbol "if", ScmPair (test, ScmPair (ScmPair(ScmSymbol("begin"), exps), ScmPair (macro_expand_cond_ribs rest, ScmNil)))) 
              
    | _ -> failwith "shouldnt happen";;
    (* raise (X_not_yet_implemented "hw 1");; *)
    (* ScmPair(ScmSymbol("f"),ScmNil)  ->  ScmPair( ScmPair(ScmSymbol("f"),ScmNil) , ScmPair("value" , ScmNil) ) *)
    let test_cond_expand ribs =
      print_sexpr stdout (macro_expand_cond_ribs 
      (List.fold_left (fun acc cur -> 
        (read cur) :: acc) ribs [])
      )

  let is_list_of_unique_names =
    let rec run = function
      | [] -> true
      | (name : string) :: rest when not (List.mem name rest) -> run rest
      | _ -> false
    in run;;

  let rec tag_parse sexpr =
    match sexpr with
    | ScmVoid | ScmBoolean _ | ScmChar _ | ScmString _ | ScmNumber _ ->
       ScmConst sexpr
    | ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil)) ->
       ScmConst sexpr
    | ScmPair (ScmSymbol "quasiquote", ScmPair (sexpr, ScmNil)) ->
       tag_parse (macro_expand_qq sexpr)
    | ScmSymbol var ->
       if (is_reserved_word var)
       then raise (X_syntax "Variable cannot be a reserved word")
       else ScmVarGet(Var var)
    | ScmPair (ScmSymbol "if",
               ScmPair (test, ScmPair (dit, ScmNil))) ->
       ScmIf(tag_parse test,
             tag_parse dit,
             tag_parse ScmVoid)
    | ScmPair (ScmSymbol "if",
               ScmPair (test, ScmPair (dit, ScmPair (dif, ScmNil)))) ->
       ScmIf(tag_parse test,
             tag_parse dit,
             tag_parse dif)
    | ScmPair (ScmSymbol "or", ScmNil) -> tag_parse (ScmBoolean false)
    | ScmPair (ScmSymbol "or", ScmPair (sexpr, ScmNil)) -> tag_parse sexpr
    | ScmPair (ScmSymbol "or", sexprs) ->
       (match (scheme_list_to_ocaml sexprs) with
        | (sexprs', ScmNil) -> ScmOr (List.map tag_parse sexprs')
        | _ -> raise (X_syntax "Improper or-expression"))
    | ScmPair (ScmSymbol "begin", ScmNil) -> ScmConst(ScmVoid)
    | ScmPair (ScmSymbol "begin", ScmPair (sexpr, ScmNil)) ->
       tag_parse sexpr
    | ScmPair (ScmSymbol "begin", sexprs) ->
       (match (scheme_list_to_ocaml sexprs) with
        | (sexprs', ScmNil) -> ScmSeq(List.map tag_parse sexprs')
        | _ -> raise (X_syntax "Improper sequence"))
    | ScmPair (ScmSymbol "set!",
               ScmPair (ScmSymbol var,
                        ScmPair (expr, ScmNil))) ->
       if (is_reserved_word var)
       then raise (X_syntax "cannot assign a reserved word")
       else ScmVarSet(Var var, tag_parse expr)
    | ScmPair (ScmSymbol "define",
               ScmPair (ScmPair (var, params),
                        exprs)) ->
       tag_parse
         (ScmPair (ScmSymbol "define",
                   ScmPair (var,
                            ScmPair (ScmPair (ScmSymbol "lambda",
                                              ScmPair (params, exprs)),
                                     ScmNil))))
    | ScmPair (ScmSymbol "define",
               ScmPair (ScmSymbol var,
                        ScmPair (expr, ScmNil))) ->
       if (is_reserved_word var)
       then raise (X_syntax "cannot define a reserved word")
       else ScmVarDef(Var var, tag_parse expr)
    | ScmPair (ScmSymbol "lambda", ScmPair (params, exprs)) ->
       let expr = tag_parse (ScmPair(ScmSymbol "begin", exprs)) in
       (match (scheme_list_to_ocaml params) with
        | params, ScmNil ->
           let params = unsymbolify_vars params in
           if is_list_of_unique_names params
           then ScmLambda(params, Simple, expr)
           else raise (X_syntax "duplicate function parameters")
        | params, ScmSymbol opt ->
           let params = unsymbolify_vars params in
           if is_list_of_unique_names (params @ [opt])
           then ScmLambda(params, Opt opt, expr)
           else raise (X_syntax "duplicate function parameters")
        | _ -> raise (X_syntax "invalid parameter list"))
    | ScmPair (ScmSymbol "let", ScmPair (ribs, exprs)) ->
       let ribs = (match (scheme_list_to_ocaml ribs) with
                   | ribs, ScmNil -> ribs
                   | _ -> raise (X_syntax "invalid lambda-ribs")) in
       let params =
         scheme_sexpr_list_of_sexpr_list
           (List.map (function
                | ScmPair (var, ScmPair (_, ScmNil)) -> var
                | _ -> raise (X_syntax "invalid lambda-rib structure"))
              ribs) in
       let args =
         scheme_sexpr_list_of_sexpr_list
           (List.map (function
                | ScmPair (_, ScmPair (arg, ScmNil)) -> arg
                | _ -> raise (X_syntax "invalid lambda-rib structure"))
              ribs) in
       tag_parse
         (ScmPair (ScmPair (ScmSymbol "lambda",
                            ScmPair (params, exprs)),
                   args))
    | ScmPair (ScmSymbol "let*", ScmPair (ScmNil, exprs)) ->
       tag_parse (ScmPair (ScmSymbol "let", ScmPair (ScmNil, exprs)))
    | ScmPair (ScmSymbol "let*",
               ScmPair
                 (ScmPair
                    (ScmPair (var, ScmPair (value, ScmNil)), ScmNil),
                  exprs)) ->
       tag_parse
         (ScmPair (ScmSymbol "let",
                   ScmPair
                     (ScmPair
                        (ScmPair (var,
                                  ScmPair (value, ScmNil)), ScmNil),
                      exprs)))
    | ScmPair (ScmSymbol "let*",
               ScmPair (ScmPair (ScmPair (var,
                                          ScmPair (arg, ScmNil)),
                                 ribs),
                        exprs)) ->
       tag_parse
         (ScmPair (ScmSymbol "let",
                   ScmPair (ScmPair (ScmPair (var,
                                              ScmPair (arg, ScmNil)),
                                     ScmNil),
                            ScmPair (ScmPair (ScmSymbol "let*",
                                              ScmPair (ribs, exprs)),
                                     ScmNil))))
    | ScmPair (ScmSymbol "letrec", ScmPair (ribs, exprs)) ->               (*   ScmPair (ScmSymbol "set!", ScmPair (var, ScmPair (expr, ScmNil))) *)
      let ribs= match scheme_list_to_ocaml ribs with 
      | (ribs1 , ScmNil) -> ribs1 
      | _ -> raise ( X_this_should_not_happen "improper ribs structure!")   in
      let vars= List.map 
      (fun binding -> match binding with
      | ScmPair( variable , _ ) -> variable
      | _ -> raise ( X_this_should_not_happen "improper binding sexp! (variables)")) ribs in
      let vars_sexp_list=  (List.fold_right (fun curr_var var_lst -> curr_var :: var_lst) vars [] ) in (* create a proper list of the variables in the lambda*)
      let set_vars_sexps= (List.map 
      (fun binding -> match binding with 
      | ScmPair(variable, ScmPair( arg_val ,ScmNil)) -> ScmPair(ScmSymbol "set!" , ScmPair(variable, ScmPair(arg_val , ScmNil) ))
      | _ -> raise ( X_this_should_not_happen "improper binding sexp!") ) ribs) in  
      let rest_of_body_exps= match scheme_list_to_ocaml exprs with 
      | (body_exps , ScmNil) -> body_exps
      | _ ->  raise ( X_this_should_not_happen "improper body s-exprs structure!") in
      let body_exps= scheme_sexpr_list_of_sexpr_list ( set_vars_sexps @  rest_of_body_exps) in
      (*       let print_body_exps=  print_sexpr Stdlib.stdout body_exps in*)
      let begin_sexper= scheme_sexpr_list_of_sexpr_list ((ScmSymbol "begin") :: (set_vars_sexps @ rest_of_body_exps))  in
      (* let print_begin_exp= print_sexpr Stdlib.stdout begin_sexper in*)
      let body_exp= tag_parse begin_sexper in
      let vars_exps= List.map (fun var_sexp -> match var_sexp with (*turn lambda variabe sexps into exps*)
                    | ScmSymbol sym -> sym
                    | _ ->  raise ( X_this_should_not_happen "variable isn't a symbol!") ) vars      in
       let final_exp= ScmApplic( ScmLambda(vars_exps, 
                                Simple, body_exp) ,
                         (List.fold_left (fun whatever_list curr_var -> ScmConst(ScmSymbol "whatever") :: whatever_list ) [] vars_exps ) )  in (*make sure the list holds the values whatever for every param!*)
      final_exp
    | ScmPair (ScmSymbol "and", ScmNil) -> tag_parse (ScmBoolean true)
    | ScmPair (ScmSymbol "and", exprs) ->
       (match (scheme_list_to_ocaml exprs) with
        | expr :: exprs, ScmNil ->
           tag_parse (macro_expand_and_clauses expr exprs)
        | _ -> raise (X_syntax "malformed and-expression"))
    | ScmPair (ScmSymbol "cond", ribs) ->
      let rec transformRibsToListOfRibs x = match x with
      | ScmPair(rib, rest) -> rib :: transformRibsToListOfRibs(rest)
      | ScmNil -> []  
      in
       tag_parse (macro_expand_cond_ribs (transformRibsToListOfRibs ribs))
    | ScmPair (proc, args) ->
       let proc =
         (match proc with
          | ScmSymbol var ->
             if (is_reserved_word var)
             then raise (X_syntax
                           (Printf.sprintf
                              "reserved word %s in proc position"
                              var))
             else proc
          | proc -> proc) in
       (match (scheme_list_to_ocaml args) with
        | args, ScmNil ->
           ScmApplic (tag_parse proc, List.map tag_parse args)
        | _ -> raise (X_syntax "malformed application"))
    | sexpr -> raise (X_syntax
                       (Printf.sprintf
                          "Unknown form: \n%a\n"
                          sprint_sexpr sexpr));;
end;; (* end of struct Tag_Parser *)

let parse str = Tag_Parser.tag_parse (read str);;

let rec sexpr_of_expr = function
  | ScmConst((ScmSymbol _) as sexpr)
    | ScmConst(ScmNil as sexpr)
    | ScmConst(ScmPair _ as sexpr)
    | ScmConst((ScmVector _) as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))
  | ScmConst(sexpr) -> sexpr
  | ScmVarGet(Var var) -> ScmSymbol var
  | ScmIf(test, dit, ScmConst ScmVoid) ->
     let test = sexpr_of_expr test in
     let dit = sexpr_of_expr dit in
     ScmPair (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmNil)))
  | ScmIf(e1, e2, ScmConst (ScmBoolean false)) ->
     let e1 = sexpr_of_expr e1 in
     (match (sexpr_of_expr e2) with
      | ScmPair (ScmSymbol "and", exprs) ->
         ScmPair (ScmSymbol "and", ScmPair(e1, exprs))
      | e2 -> ScmPair (ScmSymbol "and", ScmPair (e1, ScmPair (e2, ScmNil))))
  | ScmIf(test, dit, dif) ->
     let test = sexpr_of_expr test in
     let dit = sexpr_of_expr dit in
     let dif = sexpr_of_expr dif in
     ScmPair
       (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmPair (dif, ScmNil))))
  | ScmOr([]) -> ScmBoolean false
  | ScmOr([expr]) -> sexpr_of_expr expr
  | ScmOr(exprs) ->
     ScmPair (ScmSymbol "or",
              scheme_sexpr_list_of_sexpr_list
                (List.map sexpr_of_expr exprs))
  | ScmSeq([]) -> ScmVoid
  | ScmSeq([expr]) -> sexpr_of_expr expr
  | ScmSeq(exprs) ->
     ScmPair(ScmSymbol "begin", 
             scheme_sexpr_list_of_sexpr_list
               (List.map sexpr_of_expr exprs))
  | ScmVarSet(Var var, expr) ->
     let var = ScmSymbol var in
     let expr = sexpr_of_expr expr in
     ScmPair (ScmSymbol "set!", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmVarDef(Var var, expr) ->
     let var = ScmSymbol var in
     let expr = sexpr_of_expr expr in
     ScmPair (ScmSymbol "define", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmLambda(params, Simple, expr) ->
     let params = scheme_sexpr_list_of_sexpr_list
                    (List.map (fun str -> ScmSymbol str) params) in
     let expr = sexpr_of_expr expr in
     ScmPair (ScmSymbol "lambda",
              ScmPair (params,
                       ScmPair (expr, ScmNil)))
  | ScmLambda([], Opt opt, expr) ->
     let expr = sexpr_of_expr expr in
     let opt = ScmSymbol opt in
     ScmPair
       (ScmSymbol "lambda",
        ScmPair (opt, ScmPair (expr, ScmNil)))
  | ScmLambda(params, Opt opt, expr) ->
     let expr = sexpr_of_expr expr in
     let opt = ScmSymbol opt in
     let params = List.fold_right
                    (fun param sexpr -> ScmPair(ScmSymbol param, sexpr))
                    params
                    opt in
     ScmPair
       (ScmSymbol "lambda", ScmPair (params, ScmPair (expr, ScmNil)))
  | ScmApplic (ScmLambda (params, Simple, expr), args) ->
     let ribs =
       scheme_sexpr_list_of_sexpr_list
         (List.map2
            (fun param arg -> ScmPair (ScmSymbol param, ScmPair (arg, ScmNil)))
            params
            (List.map sexpr_of_expr args)) in
     let expr = sexpr_of_expr expr in
     ScmPair
       (ScmSymbol "let",
        ScmPair (ribs,
                 ScmPair (expr, ScmNil)))
  | ScmApplic (proc, args) ->
     let proc = sexpr_of_expr proc in
     let args =
       scheme_sexpr_list_of_sexpr_list
         (List.map sexpr_of_expr args) in
     ScmPair (proc, args);;

let string_of_expr expr =
  Printf.sprintf "%a" sprint_sexpr (sexpr_of_expr expr);;

let print_expr chan expr =
  output_string chan
    (string_of_expr expr);;

let print_exprs chan exprs =
  output_string chan
    (Printf.sprintf "[%s]"
       (String.concat "; "
          (List.map string_of_expr exprs)));;

let sprint_expr _ expr = string_of_expr expr;;

let sprint_exprs chan exprs =
  Printf.sprintf "[%s]"
    (String.concat "; "
       (List.map string_of_expr exprs));;

(* semantic analysis *)

type app_kind = Tail_Call | Non_Tail_Call;;

type lexical_address =
  | Free
  | Param of int
  | Bound of int * int;;

type var' = Var' of string * lexical_address;;

type expr' =
  | ScmConst' of sexpr
  | ScmVarGet' of var'
  | ScmIf' of expr' * expr' * expr'
  | ScmSeq' of expr' list
  | ScmOr' of expr' list
  | ScmVarSet' of var' * expr'
  | ScmVarDef' of var' * expr'
  | ScmBox' of var'
  | ScmBoxGet' of var'
  | ScmBoxSet' of var' * expr'
  | ScmLambda' of string list * lambda_kind * expr'
  | ScmApplic' of expr' * expr' list * app_kind;;

module type SEMANTIC_ANALYSIS = sig
  val annotate_lexical_address : expr -> expr'
  val annotate_tail_calls : expr' -> expr'
  val auto_box : expr' -> expr'
  val semantics : expr -> expr'  
  val tag_lexical_address_for_var : string -> string list -> string list list -> var'
  val lookup_in_rib : 'a -> 'a list -> int option
  val lookup_in_env : 'a -> 'a list list -> (int * int) option
end;; (* end of signature SEMANTIC_ANALYSIS *)

module Semantic_Analysis : SEMANTIC_ANALYSIS = struct

  (* Example:
     Semantic_Analysis.lookup_in_rib 5 [2;5;1;3;5];;
- : int option = Some 1
 *)
  let rec lookup_in_rib name = function
    | [] -> None
    | name' :: rib ->
       if name = name'
       then Some(0)
       else (match (lookup_in_rib name rib) with
             | None -> None
             | Some minor -> Some (minor + 1));;
 (* Example:
    Semantic_Analysis.lookup_in_env 8 [[4;1;6]; [3] ; [2; 4; 8]];;
- : (int * int) option = Some (2, 2)
 *)
  let rec lookup_in_env name = function
    | [] -> None
    | rib :: env ->
       (match (lookup_in_rib name rib) with
        | None ->
           (match (lookup_in_env name env) with
            | None -> None
            | Some(major, minor) -> Some(major + 1, minor))
        | Some minor -> Some(0, minor));;

(*  Examples:

Semantic_Analysis.tag_lexical_address_for_var "b" ["a"; "b";"c"] [["a";] ; ["b";]];;
- : var' = Var' ("b", Param 1)

Semantic_Analysis.tag_lexical_address_for_var "b" ["a"; "c"] [["a";] ; ["b";]];;
- : var' = Var' ("b", Bound (1, 0)) 

Semantic_Analysis.tag_lexical_address_for_var "b" ["a"; "c"] [["a";] ; ["d";] ;["c";]];;
- : var' = Var' ("b", Free) 
*)
  let tag_lexical_address_for_var name params env = 
    match (lookup_in_rib name params) with
    | None ->
       (match (lookup_in_env name env) with
        | None -> Var' (name, Free)
        | Some(major, minor) -> Var' (name, Bound (major, minor)))
    | Some minor -> Var' (name, Param minor);;

  let rec appendListToList acc subject = 
    match acc with
    | [] -> subject
    | hd :: t1 -> hd :: (appendListToList t1 subject)
  ;;

  let rec map lis func = 
    match lis with
    | [] -> []
    | ele :: rest -> (func ele) :: (map rest func)
  ;;

  (* run this first *)
  let annotate_lexical_address pe =
    let rec accumulateEnvironment expression params env = 
      match expression with
      | ScmConst(sexpr) -> ScmConst'(sexpr)
      | ScmVarGet(Var(varName) as var) -> ScmVarGet'(tag_lexical_address_for_var varName params env)
      | ScmIf(test, thenDo, elseDo) -> ScmIf'((accumulateEnvironment test params env) , (accumulateEnvironment thenDo params env), (accumulateEnvironment elseDo params env) )
      | ScmSeq(exp_list) -> ScmSeq'(map exp_list (fun x -> accumulateEnvironment x params env))
      | ScmOr(exp_list) -> ScmOr'(map exp_list (fun x -> accumulateEnvironment x params env))
      | ScmVarSet(Var(varName) as var , exp) -> ScmVarSet'((tag_lexical_address_for_var varName params env) , (accumulateEnvironment exp params env))
      | ScmVarDef(Var(varName) as var, exp) ->  ScmVarDef'((tag_lexical_address_for_var varName [] [[]]) , (accumulateEnvironment exp params env))
      | ScmLambda(param_list, kind, exp) -> 
          let ans = match kind with
          | Simple -> ScmLambda'(param_list, kind, accumulateEnvironment exp param_list (params :: env))
          | Opt(someString) -> ScmLambda'(param_list, kind, (accumulateEnvironment exp (param_list @ [someString]) ( params :: env) ) ) (*come back here if issues arise*)
          | _ -> failwith "shouldnt happen" in
           ans
      | ScmApplic(exp, exp_list) -> ScmApplic'( (accumulateEnvironment exp params env), (map exp_list (fun x -> accumulateEnvironment x params env)), Non_Tail_Call)
      | _ -> raise (X_not_yet_implemented "hw 2  shouldn't reach here") in

    accumulateEnvironment pe [] [[]];;
(*commited in February 16th - tail-calls annotation*)

  (* run this second *)
 
(* helper functions for annotate_tail_calls*)

let rec all_but_last lst= match lst with
| [] -> []
| last :: [] -> []
| car :: cdr ->  car :: (all_but_last cdr)
      ;;

let rec last_only lst= match lst with 
|  last :: [] -> last
| car :: cdr -> (last_only cdr)
    ;;
  (* run this second *)
  let annotate_tail_calls pe = 
    let rec annotate_tail_calls' in_tail_pos curr_exp= match curr_exp with
    | ScmConst' const_exp ->  ScmConst' const_exp
    | ScmVarGet' expr1 -> ScmVarGet' expr1 
    | ScmIf' (test',then',else') -> ScmIf' ( (annotate_tail_calls' false test') , (annotate_tail_calls' in_tail_pos then') , (annotate_tail_calls' in_tail_pos else') )
    | ScmOr' or_exprs ->  (match or_exprs with 
        | [] -> ScmOr' or_exprs
        | [first_or_exprs] -> ScmOr' [(annotate_tail_calls' in_tail_pos first_or_exprs)]
        | many_or_exprs ->
          let last_expr= (last_only many_or_exprs) in
          let first_exprs= (all_but_last many_or_exprs) in
          ScmOr' ( ( List.map (annotate_tail_calls' false) first_exprs) @ [(annotate_tail_calls' in_tail_pos last_expr)] ) (* only last OR expression is in tail pos!!*)
        )
    | ScmVarSet' (var,expr) -> ScmVarSet' (var, (annotate_tail_calls' false expr)) (* body is never in tail-pos, after it's execution there is a mov instruction*)
    |  ScmVarDef' (var , expr) -> ScmVarDef' (var , (annotate_tail_calls' false expr)) (* same as above.. body never in tail-pos*)
    | ScmBox' var -> ScmBox' var
    | ScmBoxGet' var -> ScmBoxGet' var
    | ScmBoxSet' (var,expr) -> ScmBoxSet' (var, (annotate_tail_calls' false expr)) (* same as above.. body never in tail-pos*)
    | ScmLambda' (params, kind, body) -> ScmLambda'(params, kind, (annotate_tail_calls' true body)) (*  here is where we have to set the flag to true - for any applications inside the lambda body expr..  *)
    (* | ScmApplic' (lambda_expr, args, Non_Tail_Call) -> 
     (* let tail_annotated_args= List.map ()*)
      let in_tail= in_tail_pos in
      (match in_tail with 
      | true -> ScmApplic'( ( annotate_tail_calls' in_tail_pos lambda_expr) , args , Tail_Call) (*if in tail pos - then it's a tail call!*)
      | false -> ScmApplic'( ( annotate_tail_calls' in_tail_pos lambda_expr) ,  args , Non_Tail_Call) (*otherwise not a tail call!*)
      ) *)
      | ScmApplic' (lambda_expr, args, Non_Tail_Call) -> 
        let rec run args = match args with 
        | [] -> []
        | arg :: [] -> ( annotate_tail_calls' false arg) :: []
        | arg :: rest -> ( annotate_tail_calls' false arg) :: (run rest) 
        | _ -> failwith "this should not happen!!"
          in
              let in_tail= in_tail_pos in
              (match in_tail with 
              | true -> ScmApplic'( ( annotate_tail_calls' false lambda_expr) , (run args) , Tail_Call) (*if in tail pos - then it's a tail call!*)
              | false -> ScmApplic'( ( annotate_tail_calls' in_tail_pos lambda_expr) , (run args) , Non_Tail_Call) (*otherwise not a tail call!*)
              )

        
    | ScmSeq' seq_of_exprs ->  (match seq_of_exprs with
        | [] -> ScmSeq' []
        | [expr] -> ScmSeq' [(annotate_tail_calls' in_tail_pos expr)]
        | exprs_list -> 
          let last_expr= (last_only exprs_list) in
          let first_exprs= (all_but_last exprs_list) in
          ScmSeq'( (List.map (annotate_tail_calls' false) first_exprs) @  [(annotate_tail_calls' in_tail_pos last_expr)] )
                                )
      
      in (annotate_tail_calls' false pe)
    
          ;;
  (* auto_box *)

  let copy_list = List.map (fun si -> si);;

  let combine_pairs =
    List.fold_left
      (fun (rs1, ws1) (rs2, ws2) -> (rs1 @ rs2, ws1 @ ws2))
      ([], []);;

  let find_reads_and_writes =
    let rec run name expr params env =
      match expr with
      | ScmConst' _ -> ([], [])
      | ScmVarGet' (Var' (_, Free)) -> ([], [])
      | ScmVarGet' (Var' (name', _) as v) when name = name' -> ([(v, env)], [])
      | ScmVarGet' (Var' (name', _)) -> ([], [])
      | ScmBox' _ -> ([], [])
      | ScmBoxGet' _ -> ([], [])
      | ScmBoxSet' (_, expr) -> run name expr params env
      | ScmIf' (test, dit, dif) ->
         let (rs1, ws1) = (run name test params env) in
         let (rs2, ws2) = (run name dit params env) in
         let (rs3, ws3) = (run name dif params env) in
         (rs1 @ rs2 @ rs3, ws1 @ ws2 @ ws3)
      | ScmSeq' exprs ->
         combine_pairs
           (List.map
              (fun expr -> run name expr params env)
              exprs)
      | ScmVarSet' (Var' (_, Free), expr) -> run name expr params env
      | ScmVarSet' ((Var' (name', _) as v), expr) ->
         let (rs1, ws1) =
           if name = name'
           then ([], [(v, env)])
           else ([], []) in
         let (rs2, ws2) = run name expr params env in
         (rs1 @ rs2, ws1 @ ws2)
      | ScmVarDef' (_, expr) -> run name expr params env
      | ScmOr' exprs ->
         combine_pairs
           (List.map
              (fun expr -> run name expr params env)
              exprs)
      | ScmLambda' (params', Simple, expr) ->
         if (List.mem name params')
         then ([], [])
         else run name expr params' ((copy_list params) :: env)
      | ScmLambda' (params', Opt opt, expr) ->
         let params' = params' @ [opt] in
         if (List.mem name params')
         then ([], [])
         else run name expr params' ((copy_list params) :: env)
      | ScmApplic' (proc, args, app_kind) ->
         let (rs1, ws1) = run name proc params env in
         let (rs2, ws2) = 
           combine_pairs
             (List.map
                (fun arg -> run name arg params env)
                args) in
         (rs1 @ rs2, ws1 @ ws2)
    in
    fun name expr params ->
    run name expr params [];;
  
  let cross_product as' bs' =
    List.concat (List.map (fun ai ->
                     List.map (fun bj -> (ai, bj)) bs')
                   as');;

  let should_box_var name expr params =
    let (reads, writes) = find_reads_and_writes name expr params in
    let rsXws = cross_product reads writes in
    let rec run = function
      | [] -> false
      | ((Var' (n1, Param _), _),
         (Var' (n2, Param _), _)) :: rest -> run rest
      | ((Var' (n1, Param _), _),
         (Var' (n2, Bound _), _)) :: _
        | ((Var' (n1, Bound _), _),
           (Var' (n2, Param _), _)) :: _ -> true
      | ((Var' (n1, Bound _), env1),
         (Var' (n2, Bound _), env2)) :: _
           when (not ((find_var_rib name env1) ==
                        (find_var_rib name env2))) -> true
      | _ :: rest -> run rest
    and find_var_rib name = function
      | [] -> raise (X_this_should_not_happen "var must occur in env")
      | rib :: _ when (List.mem name rib) -> (rib : string list)
      | _ :: env -> find_var_rib name env
    in run rsXws;;  

  let box_sets_and_gets name body =
    let rec run expr =
      match expr with
      | ScmConst' _ -> expr
      | ScmVarGet' (Var' (_, Free)) -> expr
      | ScmVarGet' (Var' (name', _) as v) ->
         if name = name'
         then ScmBoxGet' v
         else expr
      | ScmBox' _ -> expr
      | ScmBoxGet' _ -> expr
      | ScmBoxSet' (v, expr) -> ScmBoxSet' (v, run expr)
      | ScmIf' (test, dit, dif) ->
         ScmIf' (run test, run dit, run dif)
      | ScmSeq' exprs -> ScmSeq' (List.map run exprs)
      | ScmVarSet' (Var' (_, Free) as v, expr') ->
         ScmVarSet'(v, run expr')
      | ScmVarSet' (Var' (name', _) as v, expr') ->
         if name = name'
         then ScmBoxSet' (v, run expr')
         else ScmVarSet' (v, run expr')
      | ScmVarDef' (v, expr) -> ScmVarDef' (v, run expr)
      | ScmOr' exprs -> ScmOr' (List.map run exprs)
      | (ScmLambda' (params, Simple, expr)) as expr' ->
         if List.mem name params
         then expr'
         else ScmLambda' (params, Simple, run expr)
      | (ScmLambda' (params, Opt opt, expr)) as expr' ->
         if List.mem name (params @ [opt])
         then expr'
         else ScmLambda' (params, Opt opt, run expr)
      | ScmApplic' (proc, args, app_kind) ->
         ScmApplic' (run proc, List.map run args, app_kind)
    in
    run body;;

  let make_sets =
    let rec run minor names params =
      match names, params with
      | [], _ -> []
      | name :: names', param :: params' ->
         if name = param
         then let v = Var' (name, Param minor) in
              (ScmVarSet' (v, ScmBox' v)) :: (run (minor + 1) names' params')
         else run (minor + 1) names params'
      | _, _ -> raise (X_this_should_not_happen
                        "no free vars should be found here")
    in
    fun box_these params -> run 0 box_these params;;

  let rec auto_box expr =
    match expr with
    | ScmConst' _ -> expr
    | ScmVarGet' _ -> expr
    | ScmBox' _ -> expr
    | ScmBoxGet' _ -> expr
    | ScmBoxSet' (v, expr) ->
       ScmBoxSet' (v, auto_box expr)
    | ScmIf' (test, dit, dif) ->
       ScmIf' (auto_box test, auto_box dit, auto_box dif)
    | ScmSeq' exprs -> ScmSeq' (List.map auto_box exprs)
    | ScmVarSet' (v, expr) -> ScmVarSet' (v, auto_box expr)
    | ScmVarDef' (v, expr) -> ScmVarDef' (v, auto_box expr)
    | ScmOr' exprs -> ScmOr' (List.map auto_box exprs)
    | ScmLambda' (params, Simple, expr') ->
       let box_these =
         List.filter
           (fun param -> should_box_var param expr' params)
           params in
       let new_body = 
         List.fold_left
           (fun body name -> box_sets_and_gets name body)
           (auto_box expr')
           box_these in
       let new_sets = make_sets box_these params in
       let new_body = 
         match box_these, new_body with
         | [], _ -> new_body
         | _, ScmSeq' exprs -> ScmSeq' (new_sets @ exprs)
         | _, _ -> ScmSeq'(new_sets @ [new_body]) in
       ScmLambda' (params, Simple, new_body)
    | ScmLambda' (params, Opt opt, expr') ->
       let params' = params @ [opt] in
       let box_these =
         List.filter
           (fun param -> should_box_var param expr' params')
           params' in
       let new_body = 
         List.fold_left
           (fun body name -> box_sets_and_gets name body)
           (auto_box expr')
           box_these in
       let new_sets = make_sets box_these params' in
       let new_body = 
         match box_these, new_body with
         | [], _ -> new_body
         | _, ScmSeq' exprs -> ScmSeq' (new_sets @ exprs)
         | _, _ -> ScmSeq' (new_sets @ [new_body]) in
       ScmLambda' (params, Opt opt, new_body)
    | ScmApplic' (proc, args, app_kind) ->
       ScmApplic' (auto_box proc, List.map auto_box args, app_kind);;

  let semantics expr =
    auto_box
      (annotate_tail_calls
         (annotate_lexical_address expr));;

end;; (* end of module Semantic_Analysis *)

let sem str = Semantic_Analysis.semantics (parse str);;

let sexpr_of_var' (Var' (name, _)) = ScmSymbol name;;

let rec sexpr_of_expr' = function
  | ScmConst' (ScmVoid) -> ScmVoid
  | ScmConst' ((ScmBoolean _) as sexpr) -> sexpr
  | ScmConst' ((ScmChar _) as sexpr) -> sexpr
  | ScmConst' ((ScmString _) as sexpr) -> sexpr
  | ScmConst' ((ScmNumber _) as sexpr) -> sexpr
  | ScmConst' ((ScmSymbol _) as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))
  | ScmConst'(ScmNil as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))
  | ScmConst' ((ScmVector _) as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))      
  | ScmVarGet' var -> sexpr_of_var' var
  | ScmIf' (test, dit, ScmConst' ScmVoid) ->
     let test = sexpr_of_expr' test in
     let dit = sexpr_of_expr' dit in
     ScmPair (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmNil)))
  | ScmIf' (e1, e2, ScmConst' (ScmBoolean false)) ->
     let e1 = sexpr_of_expr' e1 in
     (match (sexpr_of_expr' e2) with
      | ScmPair (ScmSymbol "and", exprs) ->
         ScmPair (ScmSymbol "and", ScmPair(e1, exprs))
      | e2 -> ScmPair (ScmSymbol "and", ScmPair (e1, ScmPair (e2, ScmNil))))
  | ScmIf' (test, dit, dif) ->
     let test = sexpr_of_expr' test in
     let dit = sexpr_of_expr' dit in
     let dif = sexpr_of_expr' dif in
     ScmPair
       (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmPair (dif, ScmNil))))
  | ScmOr'([]) -> ScmBoolean false
  | ScmOr'([expr']) -> sexpr_of_expr' expr'
  | ScmOr'(exprs) ->
     ScmPair (ScmSymbol "or",
              scheme_sexpr_list_of_sexpr_list
                (List.map sexpr_of_expr' exprs))
  | ScmSeq' ([]) -> ScmVoid
  | ScmSeq' ([expr]) -> sexpr_of_expr' expr
  | ScmSeq' (exprs) ->
     ScmPair (ScmSymbol "begin", 
              scheme_sexpr_list_of_sexpr_list
                (List.map sexpr_of_expr' exprs))
  | ScmVarSet' (var, expr) ->
     let var = sexpr_of_var' var in
     let expr = sexpr_of_expr' expr in
     ScmPair (ScmSymbol "set!", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmVarDef' (var, expr) ->
     let var = sexpr_of_var' var in
     let expr = sexpr_of_expr' expr in
     ScmPair (ScmSymbol "define", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmLambda' (params, Simple, expr) ->
     let expr = sexpr_of_expr' expr in
     let params = scheme_sexpr_list_of_sexpr_list
                    (List.map (fun str -> ScmSymbol str) params) in
     ScmPair (ScmSymbol "lambda",
              ScmPair (params,
                       ScmPair (expr, ScmNil)))
  | ScmLambda' ([], Opt opt, expr) ->
     let expr = sexpr_of_expr' expr in
     let opt = ScmSymbol opt in
     ScmPair
       (ScmSymbol "lambda",
        ScmPair (opt, ScmPair (expr, ScmNil)))
  | ScmLambda' (params, Opt opt, expr) ->
     let expr = sexpr_of_expr' expr in
     let opt = ScmSymbol opt in
     let params = List.fold_right
                    (fun param sexpr -> ScmPair(ScmSymbol param, sexpr))
                    params
                    opt in
     ScmPair
       (ScmSymbol "lambda", ScmPair (params, ScmPair (expr, ScmNil)))
  | ScmApplic' (ScmLambda' (params, Simple, expr), args, app_kind) ->
     let ribs =
       scheme_sexpr_list_of_sexpr_list
         (List.map2
            (fun param arg -> ScmPair (ScmSymbol param, ScmPair (arg, ScmNil)))
            params
            (List.map sexpr_of_expr' args)) in
     let expr = sexpr_of_expr' expr in
     ScmPair
       (ScmSymbol "let",
        ScmPair (ribs,
                 ScmPair (expr, ScmNil)))
  | ScmApplic' (proc, args, app_kind) ->
     let proc = sexpr_of_expr' proc in
     let args =
       scheme_sexpr_list_of_sexpr_list
         (List.map sexpr_of_expr' args) in
     ScmPair (proc, args)
  (* for reversing macro-expansion... *)
  | _ -> raise (X_not_yet_implemented
                 "not for homework: reversing more macro-expanded forms");;

let string_of_expr' expr =
  Printf.sprintf "%a" sprint_sexpr (sexpr_of_expr' expr);;

let print_expr' chan expr =
  output_string chan
    (string_of_expr' expr);;

let print_exprs' chan exprs =
  output_string chan
    (Printf.sprintf "[%s]"
       (String.concat "; "
          (List.map string_of_expr' exprs)));;

let sprint_expr' _ expr = string_of_expr' expr;;

let sprint_exprs' chan exprs =
  Printf.sprintf "[%s]"
    (String.concat "; "
       (List.map string_of_expr' exprs));;

(* *)

let file_to_string input_file =
  let in_channel = open_in input_file in
  let rec run () =
    try 
      let ch = input_char in_channel in ch :: (run ())
    with End_of_file ->
      ( close_in in_channel;
	[] )
  in string_of_list (run ());;

let string_to_file output_file out_string =
  let out_channel = open_out output_file in
  ( output_string out_channel out_string;
    close_out out_channel );;

let remove_duplicates =
  let rec run singles = function
    | [] -> singles
    | sexpr :: sexprs when List.mem sexpr singles -> run singles sexprs
    | sexpr :: sexprs -> run (singles @ [sexpr]) sexprs
  in fun sexprs -> run [] sexprs;;

module type CODE_GENERATION =
  sig
    val compile_scheme_string : string -> string -> unit
    val compile_scheme_file : string -> string -> unit
    val compile_and_run_scheme_string : string -> string -> unit
    val global_bindings_table : (string * string) list
    val list_and_last: 'a list -> ('a list * 'a) option
    val collect_constants: expr' list -> sexpr list
    val add_sub_constants : sexpr list -> sexpr list
    val search_constant_address : sexpr -> (sexpr * 'a * 'b) list -> 'a
    type initialized_data
    val const_repr : sexpr -> 'a -> (sexpr * int * 'b) list -> initialized_data list * int
    val make_constants_table :  expr' list -> (sexpr * int * initialized_data list) list
    val asm_comment_of_sexpr : sexpr -> string
    val asm_of_representation : sexpr -> initialized_data list -> string
    val asm_of_constants_table : (sexpr * int * initialized_data list) list -> string
    val collect_free_vars : expr' list -> string list
    val make_free_vars_table: expr' list -> (string * string) list
    val make_if_else : unit ->string
    val code_gen : expr' list -> string
  end;;

module Code_Generation : CODE_GENERATION = struct
  let word_size = 8;;
  let label_start_of_constants_table = "L_constants";;
  let comment_length = 20;;

  let global_bindings_table =
    [ (* 1-10 *)
      ("null?", "L_code_ptr_is_null");
      ("pair?", "L_code_ptr_is_pair");
      ("void?", "L_code_ptr_is_void");
      ("char?", "L_code_ptr_is_char");
      ("string?", "L_code_ptr_is_string");
      ("interned-symbol?", "L_code_ptr_is_symbol");
      ("vector?", "L_code_ptr_is_vector");
      ("procedure?", "L_code_ptr_is_closure");
      ("real?", "L_code_ptr_is_real");
      ("fraction?", "L_code_ptr_is_fraction");
      (* 11-20 *)
      ("boolean?", "L_code_ptr_is_boolean");
      ("number?", "L_code_ptr_is_number");
      ("collection?", "L_code_ptr_is_collection");
      ("cons", "L_code_ptr_cons");
      ("display-sexpr", "L_code_ptr_display_sexpr");
      ("write-char", "L_code_ptr_write_char");
      ("car", "L_code_ptr_car");
      ("cdr", "L_code_ptr_cdr");
      ("string-length", "L_code_ptr_string_length");
      ("vector-length", "L_code_ptr_vector_length");
      (* 21-30*)
      ("real->integer", "L_code_ptr_real_to_integer");
      ("exit", "L_code_ptr_exit");
      ("integer->real", "L_code_ptr_integer_to_real");
      ("fraction->real", "L_code_ptr_fraction_to_real");
      ("char->integer", "L_code_ptr_char_to_integer");
      ("integer->char", "L_code_ptr_integer_to_char");
      ("trng", "L_code_ptr_trng");
      ("zero?", "L_code_ptr_is_zero");
      ("integer?", "L_code_ptr_is_integer");
      ("__bin-apply", "L_code_ptr_bin_apply");
      (* 31-40*)
      ("__bin-add-rr", "L_code_ptr_raw_bin_add_rr");
      ("__bin-sub-rr", "L_code_ptr_raw_bin_sub_rr");
      ("__bin-mul-rr", "L_code_ptr_raw_bin_mul_rr");
      ("__bin-div-rr", "L_code_ptr_raw_bin_div_rr");
      ("__bin-add-qq", "L_code_ptr_raw_bin_add_qq");
      ("__bin-sub-qq", "L_code_ptr_raw_bin_sub_qq");
      ("__bin-mul-qq", "L_code_ptr_raw_bin_mul_qq");
      ("__bin-div-qq", "L_code_ptr_raw_bin_div_qq");
      ("__bin-add-zz", "L_code_ptr_raw_bin_add_zz");
      ("__bin-sub-zz", "L_code_ptr_raw_bin_sub_zz");
      (* 41-50 *)      
      ("__bin-mul-zz", "L_code_ptr_raw_bin_mul_zz");
      ("__bin-div-zz", "L_code_ptr_raw_bin_div_zz");
      ("error", "L_code_ptr_error");
      ("__bin-less-than-rr", "L_code_ptr_raw_less_than_rr");
      ("__bin-less-than-qq", "L_code_ptr_raw_less_than_qq");
      ("__bin-less-than-zz", "L_code_ptr_raw_less_than_zz");
      ("__bin-equal-rr", "L_code_ptr_raw_equal_rr");
      ("__bin-equal-qq", "L_code_ptr_raw_equal_qq");
      ("__bin-equal-zz", "L_code_ptr_raw_equal_zz");
      ("quotient", "L_code_ptr_quotient");
      (* 51-60 *)
      ("remainder", "L_code_ptr_remainder");
      ("set-car!", "L_code_ptr_set_car");
      ("set-cdr!", "L_code_ptr_set_cdr");
      ("string-ref", "L_code_ptr_string_ref");
      ("vector-ref", "L_code_ptr_vector_ref");
      ("vector-set!", "L_code_ptr_vector_set");
      ("string-set!", "L_code_ptr_string_set");
      ("make-vector", "L_code_ptr_make_vector");
      ("make-string", "L_code_ptr_make_string");
      ("numerator", "L_code_ptr_numerator");
      (* 61-70 *)
      ("denominator", "L_code_ptr_denominator");
      ("eq?", "L_code_ptr_is_eq");
      ("__integer-to-fraction", "L_code_ptr_integer_to_fraction");
      ("logand", "L_code_ptr_logand");
      ("logor", "L_code_ptr_logor");
      ("logxor", "L_code_ptr_logxor");
      ("lognot", "L_code_ptr_lognot");
      ("ash", "L_code_ptr_ash");
      ("symbol?", "L_code_ptr_is_symbol");
      ("uninterned-symbol?", "L_code_ptr_is_uninterned_symbol");
      (* 71-80 *)
      ("gensym?", "L_code_ptr_is_uninterned_symbol");
      ("interned-symbol?", "L_code_ptr_is_interned_symbol");
      ("gensym", "L_code_ptr_gensym");
      ("frame", "L_code_ptr_frame");
      ("break", "L_code_ptr_break");
    ];;

  let list_and_last =
    let rec run a = function
      | [] -> ([], a)
      | b :: s ->
         let (s, last) = run b s in
         (a :: s, last)
    in function
    | [] -> None
    | a :: s -> Some (run a s);;

  let collect_constants =
    let rec run = function
      | ScmVarGet' (Var' (v, Free)) -> [ScmString v]
      | ScmVarGet' _ | ScmBox' _ | ScmBoxGet' _ -> []
      | ScmConst' sexpr -> [sexpr]
      | ScmIf' (test, dit, dif) ->
         (run test) @ (run dit) @ (run dif)
      | ScmSeq' exprs' -> runs exprs'
      | ScmOr' exprs' -> runs exprs'
      | ScmVarDef' (Var' (v, Free), expr') 
        | ScmVarSet' (Var' (v, Free), expr') ->
         (ScmString v) :: (run expr')
      | ScmVarSet' (_, expr') 
        | ScmVarDef' (_, expr') 
        | ScmBoxSet' (_, expr') 
        | ScmLambda' (_, _, expr') -> run expr'
      | ScmApplic' (expr', exprs', _) -> (run expr') @ (runs exprs')
    and runs exprs' =
      List.fold_left (fun consts expr' -> consts @ (run expr')) [] exprs'
    in
    fun exprs' ->
    (List.map
       (fun (scm_name, _) -> ScmString scm_name)
       global_bindings_table)
    @ (runs exprs');;

  let add_sub_constants =
    let rec run sexpr = match sexpr with
      | ScmVoid | ScmNil | ScmBoolean _ -> []
      | ScmChar _ | ScmString _ | ScmNumber _ -> [sexpr]
      | ScmSymbol sym -> [ScmString sym; ScmSymbol sym]
      | ScmPair (car, cdr) -> (run car) @ (run cdr) @ [sexpr]
      | ScmVector sexprs -> (runs sexprs) @ [sexpr]
    and runs sexprs =
      List.fold_left (fun full sexpr -> full @ (run sexpr)) [] sexprs
    in fun exprs' ->
       [ScmVoid; ScmNil; ScmBoolean false; ScmBoolean true; ScmChar '\000']
       @ (runs exprs');;

  type initialized_data =
    | RTTI of string
    | Byte of int
    | ASCII of string
    | Quad of int
    | QuadFloat of float
    | ConstPtr of int;;

  let search_constant_address =
    let rec run sexpr = function                     (* receives a *)
      | [] -> raise (X_this_should_not_happen
                      (Printf.sprintf
                         "The constant %a was not found in the constants table"
                         sprint_sexpr sexpr))
      | (sexpr', loc, _repr) :: sexprs when sexpr = sexpr' -> loc
      | _ :: sexprs -> run sexpr sexprs
    in run;;

  let const_repr sexpr loc table = match sexpr with
    | ScmVoid -> ([RTTI "T_void"], 1)
    | ScmNil -> ([RTTI "T_nil"], 1)
    | ScmBoolean false ->
       ([RTTI "T_boolean_false"], 1)
    | ScmBoolean true ->
       ([RTTI "T_boolean_true"], 1)
    | ScmChar ch ->
       ([RTTI "T_char"; Byte (int_of_char ch)], 2)
    | ScmString str ->
       let count = String.length str in
       ([RTTI "T_string"; Quad count; ASCII str],
        1 + word_size + count)
    | ScmSymbol sym ->
       let addr = search_constant_address (ScmString sym) table in
       ([RTTI "T_interned_symbol"; ConstPtr addr], 1 + word_size)
    | ScmNumber (ScmInteger n) ->
       ([RTTI "T_integer"; Quad n], 1 + word_size)
    | ScmNumber (ScmFraction (numerator, denominator)) ->
       ([RTTI "T_fraction"; Quad numerator; Quad denominator],
        1 + 2 * word_size)
    | ScmNumber (ScmReal x) ->
       ([RTTI "T_real"; QuadFloat x], 1 + word_size)
    | ScmVector s ->
       let addrs =
         List.map
           (fun si -> ConstPtr (search_constant_address si table)) s in
       let count = List.length s in
       ((RTTI "T_vector") :: (Quad count) :: addrs,
        1 + (count + 1) * word_size)
    | ScmPair (car, cdr) ->
       let (addr_car, addr_cdr) =
         (search_constant_address car table,
          search_constant_address cdr table) in
       ([RTTI "T_pair"; ConstPtr addr_car; ConstPtr addr_cdr],
        1 + 2 * word_size);;

  let make_constants_table =
    let rec run table loc = function
      | [] -> table
      | sexpr :: sexprs ->
         let (repr, len) = const_repr sexpr loc table in
         run (table @ [(sexpr, loc, repr)]) (loc + len) sexprs
    in
    fun exprs' ->
    run [] 0
      (remove_duplicates
         (add_sub_constants
            (remove_duplicates
               (collect_constants exprs'))));;    

  let asm_comment_of_sexpr sexpr =
    let str = string_of_sexpr sexpr in
    let str =
      if (String.length str) <= comment_length
      then str
      else (String.sub str 0 comment_length) ^ "..." in
    "; " ^ str;;

  let asm_of_representation sexpr =
    let str = asm_comment_of_sexpr sexpr in
    let run = function
      | [RTTI str] -> Printf.sprintf "\tdb %s" str
      | [RTTI "T_char"; Byte byte] ->
         Printf.sprintf "\tdb T_char, 0x%02X\t%s" byte str
      | [RTTI "T_string"; Quad length; ASCII const_str] ->
         Printf.sprintf "\tdb T_string\t%s\n\tdq %d%s"
           str length
           (let s = list_of_string const_str in
            let s = List.map
                      (fun ch -> Printf.sprintf "0x%02X" (int_of_char ch))
                      s in
            let s = split_to_sublists 8 s in
            let s = List.map (fun si -> "\n\tdb " ^ (String.concat ", " si)) s in
            String.concat "" s)
      | [RTTI "T_interned_symbol"; ConstPtr addr] ->
         Printf.sprintf "\tdb T_interned_symbol\t%s\n\tdq %s + %d"
           str label_start_of_constants_table addr
      | [RTTI "T_integer"; Quad n] ->
         Printf.sprintf "\tdb T_integer\t%s\n\tdq %d" str n
      | [RTTI "T_fraction"; Quad numerator; Quad denominator] ->
         Printf.sprintf "\tdb T_fraction\t%s\n\tdq %d, %d"
           str
           numerator denominator
      | [RTTI "T_real"; QuadFloat x] ->
         Printf.sprintf "\tdb T_real\t%s\n\tdq %f" str x
      | (RTTI "T_vector") :: (Quad length) :: addrs ->
         Printf.sprintf "\tdb T_vector\t%s\n\tdq %d%s"
           str length
           (let s = List.map
                      (function
                       | ConstPtr ptr ->
                          Printf.sprintf "%s + %d"
                            label_start_of_constants_table ptr
                       | _ -> raise
                               (X_this_should_not_happen
                                  "incorrect representation for a vector"))
                      addrs in
            let s = split_to_sublists 3 s in
            let s = List.map (fun si -> "\n\tdq " ^ (String.concat ", " si)) s in
            String.concat "" s)
      | [RTTI "T_pair"; ConstPtr car; ConstPtr cdr] ->
         Printf.sprintf "\tdb T_pair\t%s\n\tdq %s + %d, %s + %d"
           str
           label_start_of_constants_table car
           label_start_of_constants_table cdr
      | _ -> raise (X_this_should_not_happen "invalid representation!")
    in run;;

  let asm_of_constants_table =
    let rec run = function
      | [] -> ""
      | (sexpr, loc, repr) :: rest ->
         (Printf.sprintf "\t; %s + %d:\n" label_start_of_constants_table loc)
         ^ (asm_of_representation sexpr repr) ^ "\n" ^ (run rest)
    in
    fun table ->
    Printf.sprintf "%s:\n%s"
      label_start_of_constants_table (run table);;

  let collect_free_vars pe =
    let rec run = function
    | ScmVarGet' (Var' (v, Free)) -> [v] 
    | ScmVarGet' _ -> []
    | ScmBox' (Var' (v, Free)) -> [v]  
    | ScmBox' _ -> []
    | ScmBoxGet' (Var' (v, Free)) -> [v]
    | ScmBoxGet' _ -> []
    | ScmConst' sexpr -> []
    | ScmIf' (test, dit, dif) ->
       (run test) @ (run dit) @ (run dif)
    | ScmSeq' exprs' -> runs exprs'
    | ScmOr' exprs' -> runs exprs'
    | ScmVarDef' (Var' (v, Free), expr') 
      | ScmVarSet' (Var' (v, Free), expr') ->
       (v) :: (run expr')
    | ScmVarSet' (_, expr') 
      | ScmVarDef' (_, expr') 
      | ScmBoxSet' (_, expr') 
      | ScmLambda' (_, _, expr') -> run expr'
    | ScmApplic' (expr', exprs', _) -> (run expr') @ (runs exprs')
    and runs exprs' =
      List.fold_left (fun consts expr' -> consts @ (run expr')) [] exprs'
    in
    (List.map
         (fun (scm_name, _) -> scm_name)
         global_bindings_table)
      @ (remove_duplicates (runs pe));;
    

  let make_free_vars_table =
    let rec run index = function
      | [] -> []
      | v :: vars ->
         let x86_label = Printf.sprintf "free_var_%d" index in
         (v, x86_label) :: (run (index + 1) vars)
    in fun exprs' -> run 0 (collect_free_vars exprs');;

  let search_free_var_table =
    let rec run v = function
      | [] -> raise (X_this_should_not_happen
                      (Printf.sprintf
                         "The variable %s was not found in the free-var table"
                         v))
      | (v', x86_label) :: _ when v = v' -> x86_label
      | _ :: table -> run v table
    in run;;

  let asm_of_global_bindings global_bindings_table free_var_table =
    String.concat "\n"
      (List.map
         (fun (scheme_name, asm_code_ptr) ->
           let free_var_label =
             search_free_var_table scheme_name free_var_table in
           (Printf.sprintf "\t; building closure for %s\n" scheme_name)
           ^ (Printf.sprintf "\tmov rdi, %s\n" free_var_label)
           ^ (Printf.sprintf "\tmov rsi, %s\n" asm_code_ptr)
           ^ "\tcall bind_primitive\n")
         global_bindings_table);;
  
  let asm_of_free_vars_table fvars_table consts_table=
    let tmp = 
      List.map
        (fun (scm_var, asm_label) ->
          let addr =
            search_constant_address (ScmString scm_var) consts_table in
          (Printf.sprintf "%s:\t; location of %s\n" 
             asm_label scm_var)
          ^ "\tdq .undefined_object\n"
          ^ ".undefined_object:\n"
          ^ "\tdb T_undefined\n"
          ^ (Printf.sprintf "\tdq L_constants + %d\n"
               addr))
        fvars_table in
    String.concat "\n" tmp;;

  let make_make_label prefix =
    let index = ref 0 in
    fun () ->
    (index := !index + 1;
     Printf.sprintf "%s_%04x" prefix !index);;

  (* added by me for final project - roy 27 february*)
    let make_then_label= make_make_label ".L_then";;
    let make_else_label= make_make_label ".L_else";;

    let make_lambda_opt_arity_ok=
      make_make_label ".L_lambda_opt_arity_check_ok";;

    let make_opt_arg_empty=
    make_make_label ".Label_opt_arg_empty";;
    
    
    let make_build_opt_list=
    make_make_label ".Label_build_opt_list";;

    let make_push_up_the_stack= 
    make_make_label ".Label_push_up_the_stack";;

    let make_update_opt_list=
    make_make_label ".Label_update_built_opt_list";;

    let make_update_rsp_opt_list_case=
    make_make_label ".Label_update_rsp";;

    let make_push_down_the_stack=
    make_make_label ".Label_push_down_the_stack";;

    let make_push_empty_list_and_update_rsp=
    make_make_label ".Label_push_empty_list_and_update_rsp";;

    let make_lambda_opt_stack_fix_end=
    make_make_label ".Label_lambda_opt_stack_fix_end";;

    let make_push_args_label=
    make_make_label ".Label_PUSH_ARGS";;

    let make_fml_label=
    make_make_label ".Label_FML"
   (* added by me for final project - roy 27 february*)

  
  let make_if_else = make_make_label ".L_if_else";;
  let make_if_end = make_make_label ".L_if_end";;
  let make_or_end = make_make_label ".L_or_end";;
  let make_lambda_simple_loop_env =
    make_make_label ".L_lambda_simple_env_loop";;
  let make_lambda_simple_loop_env_end =
    make_make_label ".L_lambda_simple_env_end";;
  let make_lambda_simple_loop_params =
    make_make_label ".L_lambda_simple_params_loop";;
  let make_lambda_simple_loop_params_end =
    make_make_label ".L_lambda_simple_params_end";;
  let make_lambda_simple_code = make_make_label ".L_lambda_simple_code";;
  let make_lambda_simple_end = make_make_label ".L_lambda_simple_end";;
  let make_lambda_simple_arity_ok =
    make_make_label ".L_lambda_simple_arity_check_ok";;

  let make_lambda_opt_loop_env =
    make_make_label ".L_lambda_opt_env_loop";;
  let make_lambda_opt_loop_env_end =
    make_make_label ".L_lambda_opt_env_end";;
  let make_lambda_opt_loop_params =
    make_make_label ".L_lambda_opt_params_loop";;
  let make_lambda_opt_loop_params_end =
    make_make_label ".L_lambda_opt_params_end";;
  let make_lambda_opt_code = make_make_label ".L_lambda_opt_code";;
  let make_lambda_opt_end = make_make_label ".L_lambda_opt_end";;
  let make_lambda_opt_arity_exact =
    make_make_label ".L_lambda_opt_arity_check_exact";;
  let make_lambda_opt_arity_more =
    make_make_label ".L_lambda_opt_arity_check_more";;
  let make_lambda_opt_stack_ok =
    make_make_label ".L_lambda_opt_stack_adjusted";;
  let make_lambda_opt_loop =
    make_make_label ".L_lambda_opt_stack_shrink_loop";;
  let make_lambda_opt_loop_exit =
    make_make_label ".L_lambda_opt_stack_shrink_loop_exit";;
  let make_tc_applic_recycle_frame_loop =
    make_make_label ".L_tc_recycle_frame_loop";;
  let make_tc_applic_recycle_frame_done =
    make_make_label ".L_tc_recycle_frame_done";;

    let code_gen exprs' =
      let consts = make_constants_table exprs' in
      let free_vars = make_free_vars_table exprs' in
      let rec run params env = function
        | ScmConst' sexpr ->
           let addr = search_constant_address sexpr consts in
           Printf.sprintf "\tmov rax, L_constants + %d\n" addr
        | ScmVarGet' (Var' (v, Free)) ->
           let label = search_free_var_table v free_vars in
           (Printf.sprintf
              "\tmov rax, qword [%s]\t; free var %s\n"
              label v)
           ^ "\tcmp byte [rax], T_undefined\n"
           ^ "\tje L_error_fvar_undefined\n"
        | ScmVarGet' (Var' (v, Param minor)) ->
           Printf.sprintf "\tmov rax, PARAM(%d)\t; param %s\n"
             minor v
        | ScmVarGet' (Var' (v, Bound (major, minor))) ->
           "\tmov rax, ENV\n"
           ^ (Printf.sprintf "\tmov rax, qword [rax + 8 * %d]\n" major)
           ^ (Printf.sprintf
                "\tmov rax, qword [rax + 8 * %d]\t; bound var %s\n" minor v)
        | 
          ScmIf' (test, dit, dif) ->                                                    (*DONE*)
            let label_else = (make_if_else ()) in
            let label_exit = (make_if_end ()) in
             (run params env test)
            ^ (Printf.sprintf "\ncmp rax, L_constants + %d" (search_constant_address (ScmBoolean false) consts) )
            ^ (Printf.sprintf "\nje %s;\n" label_else)
            ^ (run params env dit)
            ^ (Printf.sprintf "\njmp %s;\n" label_exit)
            ^ (Printf.sprintf "%s:\n" label_else)
            ^ (run params env dif)
            ^ (Printf.sprintf "\n%s:\n" label_exit)
           (* raise (X_not_yet_implemented "final project") *)
        | ScmSeq' exprs' ->
           String.concat "\n"
             (List.map (run params env) exprs')
        | ScmOr' exprs' ->
           let label_end = make_or_end () in
           let asm_code = 
             (match (list_and_last exprs') with
              | Some (exprs', last_expr') ->
                 let exprs_code =
                   String.concat ""
                     (List.map
                        (fun expr' ->
                          let expr_code = run params env expr' in
                          expr_code
                          ^ "\tcmp rax, sob_boolean_false\n"
                          ^ (Printf.sprintf "\tjne %s\n" label_end))
                        exprs') in
                 let last_expr_code = run params env last_expr' in
                 exprs_code
                 ^ last_expr_code
                 ^ (Printf.sprintf "%s:\n" label_end)
              (* and just in case someone messed up the tag-parser: *)
              | None -> run params env (ScmConst' (ScmBoolean false)))
           in asm_code

        | ScmVarSet' (Var' (v, Free), expr') ->
          let valToSet = (run params env expr') in
          let mov1 = (Printf.sprintf "\nmov qword [%s], rax; ~~~\n"  (search_free_var_table v free_vars)) in
          let mov2 = (Printf.sprintf "\tmov rax, L_constants + %d\n" (search_constant_address (ScmVoid) consts) ) in
          (valToSet ^ mov1 ^ mov2)
          (* raise (X_not_yet_implemented "final project")   *)         (* DONE *)

        | ScmVarSet' (Var' (v, Param minor), ScmBox' _) -> (*allocate mem for the param, update the new value in mem allocated and set param to be the box address*)
          
             
          (Printf.sprintf "\n\tmov rdi , 8\n")
          ^ (Printf.sprintf "\tcall malloc ;;allocated mem will be in rax\n")
          ^ (Printf.sprintf "\tlea rbx , [rbp+8*4+8*%d];; param stack address\n" minor)
          ^ (Printf.sprintf "\tmov rcx, [rbx] ;;param val\n ")
          ^ (Printf.sprintf "\tmov [rax] ,rcx ;;set the boxed-val\n")
          ^ (Printf.sprintf "\tmov [rbx] ,rax ;;store the boxed param in the stack \n")
          ^ (Printf.sprintf "\tmov rax, L_constants + %d\n" (search_constant_address ( ScmVoid) consts) )
          
        
          
          (* raise (X_not_yet_implemented "final project") *)

        | ScmVarSet' (Var' (v, Param minor), expr') ->
          let valToSet = (run params env expr') in
          valToSet
          ^ (Printf.sprintf "\n\tlea rcx, [rbp+8*4+8*%d]\n" minor)
          ^ (Printf.sprintf "\tmov [rcx] , rax \n")
          ^ (Printf.sprintf "mov rax, L_constants + %d\n" (search_constant_address ( ScmVoid) consts) )
          (* raise (X_not_yet_implemented "final project")   *)           (* DONE *)
        | ScmVarSet' (Var' (v, Bound (major, minor)), expr') ->
          let valToSet = (run params env expr') in
          valToSet
          ^ (Printf.sprintf "\n\tmov rcx, [rbp+8*2] ;;env-deref\n" )
          ^ (Printf.sprintf "\tmov rbx , [rcx+8*%d] \n" major)
          ^ (Printf.sprintf "\tmov [rbx+8*%d] ,rax ;;set the new value! \n" minor) 
          ^ (Printf.sprintf "\tmov rax, L_constants + %d\n" (search_constant_address ( ScmVoid) consts) )
          (* raise (X_not_yet_implemented "final project")   *)           (* DONE *)
        | ScmVarDef' (Var' (v, Free), expr') ->
           let label = search_free_var_table v free_vars in
           (run params env expr')
           ^ (Printf.sprintf "\tmov qword [%s], rax\n" label)
           ^ "\tmov rax, sob_void\n"
        | ScmVarDef' (Var' (v, Param minor), expr') ->
           raise (X_not_yet_implemented "Support local definitions (param)")
        | ScmVarDef' (Var' (v, Bound (major, minor)), expr') ->
           raise (X_not_yet_implemented "Support local definitions (bound)")
        | ScmBox' _ ->
           raise (X_this_should_not_happen "only parameters are boxed!")
        | ScmBoxGet' var' ->
           (run params env (ScmVarGet' var'))
           ^ "\tmov rax, qword [rax]\n"
        
        | ScmBoxSet' (var', expr') ->
           let val_to_set= (run params env expr') in
           let get_boxed_var= (run params env (ScmVarGet' var')) in (*NOTE: WE WANT TO RETURN THE BOX-ADDRESS, NOT THE VAL!! SO DON'T USE ScmBoxGet' var'      !!!!!!!!!!!*)
           val_to_set 
           ^ (Printf.sprintf "\n\tpush rax ;;backup the val to set on the stack\n")
           ^ get_boxed_var
           ^ (Printf.sprintf "\tpop qword [rax] ;;store val-to-set in boxed address\n")
           ^ (Printf.sprintf "\tmov rax, L_constants + %d\n" (search_constant_address ( ScmVoid) consts) )
          (*  raise (X_not_yet_implemented "final project")*)

        | ScmLambda' (params', Simple, body) ->
           let label_loop_env = make_lambda_simple_loop_env ()
           and label_loop_env_end = make_lambda_simple_loop_env_end ()
           and label_loop_params = make_lambda_simple_loop_params ()
           and label_loop_params_end = make_lambda_simple_loop_params_end ()
           and label_code = make_lambda_simple_code ()
           and label_arity_ok = make_lambda_simple_arity_ok ()
           and label_end = make_lambda_simple_end ()
           in
           "\tmov rdi, (1 + 8 + 8)\t; sob closure\n"
           ^ "\tcall malloc\n"
           ^ "\tpush rax\n"
           ^ (Printf.sprintf "\tmov rdi, 8 * %d\t; new rib\n" params)
           ^ "\tcall malloc\n"
           ^ "\tpush rax\n"
           ^ (Printf.sprintf "\tmov rdi, 8 * %d\t; extended env\n" (env + 1))
           ^ "\tcall malloc\n"
           ^ "\tmov rdi, ENV\n"
           ^ "\tmov rsi, 0\n"
           ^ "\tmov rdx, 1\n"
           ^ (Printf.sprintf "%s:\t; ext_env[i + 1] <-- env[i]\n"
                label_loop_env)
           ^ (Printf.sprintf "\tcmp rsi, %d\n" env)
           ^ (Printf.sprintf "\tje %s\n" label_loop_env_end)
           ^ "\tmov rcx, qword [rdi + 8 * rsi]\n"
           ^ "\tmov qword [rax + 8 * rdx], rcx\n"
           ^ "\tinc rsi\n"
           ^ "\tinc rdx\n"
           ^ (Printf.sprintf "\tjmp %s\n" label_loop_env)
           ^ (Printf.sprintf "%s:\n" label_loop_env_end)
           ^ "\tpop rbx\n"
           ^ "\tmov rsi, 0\n"
           ^ (Printf.sprintf "%s:\t; copy params\n" label_loop_params)
           ^ (Printf.sprintf "\tcmp rsi, %d\n" params)
           ^ (Printf.sprintf "\tje %s\n" label_loop_params_end)
           ^ "\tmov rdx, qword [rbp + 8 * rsi + 8 * 4]\n"
           ^ "\tmov qword [rbx + 8 * rsi], rdx\n"
           ^ "\tinc rsi\n"
           ^ (Printf.sprintf "\tjmp %s\n" label_loop_params)
           ^ (Printf.sprintf "%s:\n" label_loop_params_end)
           ^ "\tmov qword [rax], rbx\t; ext_env[0] <-- new_rib \n"
           ^ "\tmov rbx, rax\n"
           ^ "\tpop rax\n"
           ^ "\tmov byte [rax], T_closure\n"
           ^ "\tmov SOB_CLOSURE_ENV(rax), rbx\n"
           ^ (Printf.sprintf "\tmov SOB_CLOSURE_CODE(rax), %s\n" label_code)
           ^ (Printf.sprintf "\tjmp %s\n" label_end)
           ^ (Printf.sprintf "%s:\t; lambda-simple body\n" label_code)
           ^ (Printf.sprintf "\tcmp qword [rsp + 8 * 2], %d\n"
                (List.length params'))
           ^ (Printf.sprintf "\tje %s\n" label_arity_ok)
           ^ "\tpush qword [rsp + 8 * 2]\n"
           ^ (Printf.sprintf "\tpush %d\n" (List.length params'))
           ^ "\tjmp L_error_incorrect_arity_simple\n"
           ^ (Printf.sprintf "%s:\n" label_arity_ok)
           ^ "\tenter 0, 0\n"
           ^ (run (List.length params') (env + 1) body)
           ^ "\tleave\n"
           ^ (Printf.sprintf "\tret AND_KILL_FRAME(%d)\n" (List.length params'))
           ^ (Printf.sprintf "%s:\t; new closure is in rax\n" label_end)

    (**************)
    (**************)
           (**************)
        | ScmLambda' (params', Opt opt, body) ->                         (*implemented for final project*)
          let label_loop_env = make_lambda_opt_loop_env ()
           and label_loop_env_end = make_lambda_opt_loop_env_end ()
           and label_loop_params = make_lambda_opt_loop_params()
           and label_loop_params_end =  make_lambda_opt_loop_params_end()
           and label_code =  make_lambda_opt_code ()
           and label_arity_ok_opt = make_lambda_opt_arity_ok ()
           and label_end = make_lambda_opt_end ()
           and label_opt_arg_empty= make_opt_arg_empty ()
           and label_build_opt_list= make_build_opt_list()
           and label_update_built_opt_list= make_update_opt_list ()
           and label_push_up_the_stack= make_push_up_the_stack ()
           and label_push_down_the_stack= make_push_down_the_stack ()
           and label_update_arg_count_and_rsp_non_empt= make_update_rsp_opt_list_case ()
           and label_stack_fix_end= make_lambda_opt_stack_fix_end ()
           and label_push_empty_list_update_rsp= make_push_empty_list_and_update_rsp ()
           and param_count= (List.length params') + 1                                      (*added 1 for optional param*)
           in
           "\tmov rdi, (1 + 8 + 8)\t; sob closure\n"
           ^ "\tcall malloc\n"
           ^ "\tpush rax\n"
           ^ (Printf.sprintf "\tmov rdi, 8 * %d\t; new rib\n" param_count) (*changed from params to : params+1*)
           ^ "\tcall malloc\n"
           ^ "\tpush rax\n"
           ^ (Printf.sprintf "\tmov rdi, 8 * %d\t; extended env\n" (env + 1))
           ^ "\tcall malloc\n"
           ^ "\tmov rdi, ENV\n"
           ^ "\tmov rsi, 0\n"
           ^ "\tmov rdx, 1\n"
           ^ (Printf.sprintf "%s:\t; ext_env[i + 1] <-- env[i]\n"
                label_loop_env)
           ^ (Printf.sprintf "\tcmp rsi, %d\n" env)
           ^ (Printf.sprintf "\tje %s\n" label_loop_env_end)
           ^ "\tmov rcx, qword [rdi + 8 * rsi]\n"
           ^ "\tmov qword [rax + 8 * rdx], rcx\n"
           ^ "\tinc rsi\n"
           ^ "\tinc rdx\n"
           ^ (Printf.sprintf "\tjmp %s\n" label_loop_env)
           ^ (Printf.sprintf "%s:\n" label_loop_env_end)
           ^ "\tpop rbx\n"
           ^ "\tmov rsi, 0\n"
           ^ (Printf.sprintf "%s:\t; copy params\n" label_loop_params)
           ^ (Printf.sprintf "\tcmp rsi, %d\n" param_count) (*cahnged from params to : params+1*)
           ^ (Printf.sprintf "\tje %s\n" label_loop_params_end)
           ^ "\tmov rdx, qword [rbp + 8 * rsi + 8 * 4]\n"
           ^ "\tmov qword [rbx + 8 * rsi], rdx\n"
           ^ "\tinc rsi\n"
           ^ (Printf.sprintf "\tjmp %s\n" label_loop_params)
           ^ (Printf.sprintf "%s:\n" label_loop_params_end)
           ^ "\tmov qword [rax], rbx\t; ext_env[0] <-- new_rib \n"
           ^ "\tmov rbx, rax\n"
           ^ "\tpop rax\n"
           ^ "\tmov byte [rax], T_closure\n"
           ^ "\tmov SOB_CLOSURE_ENV(rax), rbx\n"
           ^ (Printf.sprintf "\tmov SOB_CLOSURE_CODE(rax), %s\n" label_code)
           ^ (Printf.sprintf "\tjmp %s\n" label_end)
           ^ (Printf.sprintf "%s:\t; lambda-opt body\n ;;BODY_CODE\n" label_code)     (* here the body code starts*)
           ^ ((Printf.sprintf "\tmov r9 ,[rsp+8*2] ;;arg-count\n"))
           ^ (Printf.sprintf "\tsub r9 ,%d\n" param_count) 
           ^ (Printf.sprintf "\tmov rcx, r9 ; rcx will have the value: args_count - param_count\n" )
           ^ (Printf.sprintf "\tcmp rcx, -1\n")
           ^ (Printf.sprintf "\tjge %s\n" label_arity_ok_opt)
           ^ (Printf.sprintf "\tpush qword [rsp+8*2] ;;arg-count for run-time error func\n")  
           ^ (Printf.sprintf "\tpush %d ;;param-count for run-time error func\n" param_count)  
           ^ (Printf.sprintf "\tjmp L_error_incorrect_arity_opt ;;print runtime error for incorrect num of args! \n" )
           ^ (Printf.sprintf "%s:\n" label_arity_ok_opt)
           ^ (Printf.sprintf "\tmov rbx, sob_nil\n")
           ^ (Printf.sprintf "\tmov r8, [rsp+8*2] ;;r8 will hold arg-count\n") 
           ^ (Printf.sprintf "\tlea rdx, [rsp + 8*2 + r8*8] ;address of first arg\n")
           ^ (Printf.sprintf "\tpush rdx ;;back it up on the stack\n")
           ^ (Printf.sprintf "\tcmp rcx, -1\n")
           ^ (Printf.sprintf "\tje %s\n" label_opt_arg_empty)
           ^ (Printf.sprintf "\tmov rsi, 0\n")
           ^ (Printf.sprintf "\tlea r10, [r8-%d+1] ;;this will be the length of the optional list! \n" param_count) (*  mov r10 ,  |Args|- |Params|+1 *)
           ^ (Printf.sprintf "%s:\n" label_build_opt_list)  (*Label_build_opt_list:*)
           ^ (Printf.sprintf "\tcmp rsi, r10\n") 
           ^ (Printf.sprintf "\tje %s\n" label_update_built_opt_list) (*je Label_update_built_opt_list*)
           ^ (Printf.sprintf "\tmov rdi, (1 + 8 + 8) ;;amount of memory for malloc sys-call in rdi\n")
           ^ (Printf.sprintf "\tcall malloc ;; new ptr allocated will be in rax\n")
           ^ (Printf.sprintf "\tmov r11 , [rdx] ;; value of current arg in the to-be optlist\n")
           ^ (Printf.sprintf "\tmov byte [rax] , T_pair ;;RRTI for pair\n")
           ^ (Printf.sprintf "\tmov SOB_PAIR_CAR(rax) , r11\n")
           ^ (Printf.sprintf "\tmov SOB_PAIR_CDR(rax) , rbx ;; rbx- the list we created so far\n")
           ^ (Printf.sprintf "\tmov rbx, rax ;; store list we created so far in rbx\n")
           ^ (Printf.sprintf "\tinc rsi\n")
           ^ (Printf.sprintf "\tsub rdx, 8 ;;mov to next arg\n")
           ^ (Printf.sprintf "\tjmp %s\n" label_build_opt_list) (*jmp .Label_build_opt_list*)
           ^ (Printf.sprintf "%s:\n" label_update_built_opt_list) (* Label_update_built_opt_list: *)
           ^ (Printf.sprintf "\tpop rdx\n")
           ^ (Printf.sprintf "\tmov [rdx] , rbx ;;updating the built-opt-list in the appropriate location on the stack\n")
           ^ (Printf.sprintf "\tmov r10 , %d - 1 + 3 ;; 3 for env, ret-add, arg-cout, r10 holds the num of words to push UP the stack\n" param_count )
           ^ (Printf.sprintf "\tlea rdi, [r8 - %d] ;;how many words to push over? ;;|Args|-|Params|\n" param_count)
           ^ (Printf.sprintf "\tlea rdx, [rsp+ 8*2 + 8*(%d-1)] ;; ADDRESS OF LAST NON OPT-PARAM! \n" param_count)
           ^ (Printf.sprintf "\tmov r13, [rdx] ;;FOR DEBUG-CHECK THE VALUE HERE IS THE first PARAM\n") (*FOR DEBUG REMOVE LATER*)
           ^ (Printf.sprintf "\tmov rsi, 0\n")
           ^ (Printf.sprintf "%s:  ;;here we push the params-1+env+ret+arg-count up the stack\n" label_push_up_the_stack) (*    Label_push_up_the_stack: *)
           ^ (Printf.sprintf "\tcmp rsi, r10\n")
           ^ (Printf.sprintf "\tje %s\n" label_update_arg_count_and_rsp_non_empt) (* MAYBE CHANGE THIS LABLE'S NAME!!*)
           ^ (Printf.sprintf "\tmov rcx, [rdx] ;; load the value to be pushed up the stack\n")
           ^ (Printf.sprintf "\tmov [rdx+8*rdi], rcx ;;copy it to the pushed memory address upon the stack\n")
           ^ (Printf.sprintf "\tinc rsi\n")
           ^ (Printf.sprintf "\tsub rdx, 8 ;;move to next value to be pushed (moving down)\n")
           ^ (Printf.sprintf "\tjmp %s ;; go back to push loop\n" label_push_up_the_stack) (*jmp Label_push_up_the_stack*)
           ^ (Printf.sprintf "%s: ;;updating rsp and arg-count\n" label_update_arg_count_and_rsp_non_empt)
           ^ (Printf.sprintf "\tlea rsp, [rsp+8*rdi]\n")
           ^ (Printf.sprintf "\tmov qword [rsp+8*2] , %d ;;updating the new arg-count to be param-count\n" param_count )
           ^ (Printf.sprintf "\tmov qword r13 ,[rsp+8*2] ;; r13 must hold arg-count!! DEBUG THIS\n")              (*FOR DEBUG REMOVE LATER*)
           ^ (Printf.sprintf "\tjmp %s\n" label_stack_fix_end) (*jmp .Label_lambda_opt_stack_fix_end*)
           ^ (Printf.sprintf "%s: ;;fixing for the case where opt-arg is nil\n" label_opt_arg_empty) (*.Label_opt_arg_empty:*)
           ^ (Printf.sprintf "\tpop rcx ;;now rcx will have the address where we push the empty opt-list to!\n")
           ^ (Printf.sprintf "\tlea rdi, [rsp-8]\n")
           ^ (Printf.sprintf "\tmov rsi, 0\n")
           ^ (Printf.sprintf "\tlea r9, [r8+3] ;num of words in the stack to push down by 1 address\n")        (*   mov r9, 3+|Args| ;num of words in the stack to push down by 1 address *)
           ^ (Printf.sprintf "%s:\n" label_push_down_the_stack) (* .Label_push_down_the_stack: *)
           ^ (Printf.sprintf "\tcmp rsi , r9\n") 
           ^ (Printf.sprintf "\tje %s\n" label_push_empty_list_update_rsp)
           ^ (Printf.sprintf "\tmov rdx, [rdi+8] ;;load the value of the word above\n")
           ^ (Printf.sprintf "\tmov [rdi] , rdx ;;update the word bellow to word above\n")
           ^ (Printf.sprintf "\tadd rdi, 8 ;;move up one word\n")
           ^ (Printf.sprintf "\tinc rsi ;;counter++ \n")
           ^ (Printf.sprintf "\tjmp %s\n" label_push_down_the_stack) (* go back to loop*)
           ^ (Printf.sprintf "%s:\n" label_push_empty_list_update_rsp) (* Label_push_empty_list_and_update_rsp: *)
           ^ (Printf.sprintf "\tsub rsp, 8\n")
           ^ (Printf.sprintf"\tmov [rcx], rbx\n")
           ^ (Printf.sprintf "\tmov qword [rsp+8*2], %d ;;update arg-count to be param-count\n" param_count)   (*end of Label_push_empty_list_and_update_rsp: *)
           ^ (Printf.sprintf "%s: \n" label_stack_fix_end)
           ^ "\tenter 0, 0\n"
           ^ (run param_count  (env + 1) body)
           ^ "\tleave\n"
           ^ (Printf.sprintf "\tret AND_KILL_FRAME(%d)\n" (param_count))
           ^ (Printf.sprintf "\n;;BODY CODE ENDS HERE!!! ---\n")
           ^ (Printf.sprintf "%s: ; new closure is in rax\n" label_end)


(*JUNK*)

        | 
        ScmApplic' (proc, args, Non_Tail_Call) ->             (*------- should be fixed -----*) (*for final project*) 
            let args_count= (List.length args) in
            let push_args_label= make_push_args_label () in
           let fml_label= make_fml_label () in
            let push_args_on_stack=
              (List.fold_right 
                      (fun arg push_on_stack_code ->
                             let arg_calc_code = (run params env arg) in
                             push_on_stack_code ^ (Printf.sprintf "\n%s" arg_calc_code) ^ "\tpush rax\n"  )
                      args
                      (Printf.sprintf "%s: \n" push_args_label) )
                                  in 
              let push_arg_count=(Printf.sprintf "\tpush %d ; -------arg-count\n\n%s:\n" args_count fml_label) in
              let eval_closure= (run params env proc) in 
              let check_if_closure= "\tcmp byte [rax], T_closure" in
              let runtime_error_if_not_closure= "\n\tjne L_error_non_closure" in
              let lex_env_ptr_push="\n\tpush SOB_CLOSURE_ENV(rax)" in
              let call_body_code= "\n\tcall SOB_CLOSURE_CODE(rax) ;stack will be cleaned by the CALLEE!!!\n" in
              
              push_args_on_stack ^ push_arg_count ^ eval_closure ^ check_if_closure ^ runtime_error_if_not_closure ^ lex_env_ptr_push ^ call_body_code 
              (*ours...................................*)
        | ScmApplic' (proc, args, Tail_Call) -> 
           let args_code =
             String.concat ""
               (List.map
                  (fun arg ->
                    let arg_code = run params env arg in
                    arg_code
                    ^ "\tpush rax\n")
                  (List.rev args))
           and proc_code = run params env proc
           and label_recycle_frame_loop =
             make_tc_applic_recycle_frame_loop ()
           and label_recycle_frame_done =
             make_tc_applic_recycle_frame_done ()
           in
           "\t; preparing a tail-call\n"
           ^ args_code
           ^ (Printf.sprintf "\tpush %d\t; arg count\n" (List.length args))
           ^ proc_code
           ^ "\tcmp byte [rax], T_closure\n"
           ^ "\tjne L_error_non_closure\n"
           ^ "\tpush SOB_CLOSURE_ENV(rax)\n\n"
           ^ "\t; recycling the current frame\n"
           ^ "\tpush qword [rbp + 8 * 1]\t; preserve old return address\n"
           ^ "\tpush qword [rbp + 8 * 0]\t; preserve old frame-pointer\n"
           ^ (Printf.sprintf "\tmov rcx, %d + 4\n" (List.length args))
           ^ "\tmov rbx, COUNT\n"
           ^ "\tlea rbx, [rbp + 8 * rbx + 8 * 3]\n"
           ^ "\tlea rdx, [rbp - 8 * 1]\n"
           ^ (Printf.sprintf "%s:\n"
                label_recycle_frame_loop)
           ^ "\tcmp rcx, 0\n"
           ^ (Printf.sprintf "\tje %s\n"
                label_recycle_frame_done)
           ^ "\tmov rsi, qword [rdx]\n"
           ^ "\tmov qword [rbx], rsi\n"
           ^ "\tdec rcx\n"
           ^ "\tsub rbx, 8 * 1\n"
           ^ "\tsub rdx, 8 * 1\n"
           ^ (Printf.sprintf "\tjmp %s\n"
                label_recycle_frame_loop)
           ^ (Printf.sprintf "%s:\n"
                label_recycle_frame_done)
           ^ "\tlea rsp, [rbx + 8 * 1]\n"
           ^ "\tpop rbp\t; the proc will restore it!\n"
           ^ "\tjmp SOB_CLOSURE_CODE(rax)\n"
      and runs params env exprs' =
        List.map
          (fun expr' ->
            let code = run params env expr' in
            let code =
              code
              ^ "\n\tmov rdi, rax"
              ^ "\n\tcall print_sexpr_if_not_void\n" in
            code)
          exprs' in
      let codes = runs 0 0 exprs' in
      let code = String.concat "\n" codes in
      let code =
        (file_to_string "prologue-1.asm")
        ^ (asm_of_constants_table consts)
        ^ (asm_of_free_vars_table free_vars consts)
        ^ (file_to_string "prologue-2.asm")
        ^ (asm_of_global_bindings global_bindings_table free_vars)
        ^ "\n"
        ^ code
        ^ (file_to_string "epilogue.asm") in
      code;;

  let compile_scheme_string file_out user =
    let init = file_to_string "init.scm" in
    let source_code = (init ^ "\n" ^ user) in
    let sexprs = (PC.star Reader.nt_sexpr source_code 0).found in
    let exprs = List.map Tag_Parser.tag_parse sexprs in
    let exprs' = List.map Semantic_Analysis.semantics exprs in
    let asm_code = code_gen exprs' in
    (string_to_file file_out asm_code;
     Printf.printf "!!! Compilation finished. Time to assemble!\n");;  

  let compile_scheme_file file_in file_out =
    compile_scheme_string file_out (file_to_string file_in);;
 (* to auto-test, call the output file "output" !! *)
  let compile_and_run_scheme_string file_out_base user =
      let init = file_to_string "init.scm"  in 
    let source_code = init ^ "\n" ^  user in
    let sexprs = (PC.star Reader.nt_sexpr source_code 0).found in
    let exprs = List.map Tag_Parser.tag_parse sexprs in
    let exprs' = List.map Semantic_Analysis.semantics exprs in
    let asm_code = code_gen exprs' in
    ( string_to_file (Printf.sprintf "%s.asm" file_out_base) asm_code;
      match (Sys.command
               (Printf.sprintf
                  "make %s" file_out_base )) with
      | 0  -> let _ = Sys.command (Printf.sprintf "./%s" file_out_base) in ()
      | n -> (Printf.printf "!!! Failed with code %d\n" n; ()));;

end;; (* end of Code_Generation struct *)

(* end-of-input *)



let test = Code_Generation.compile_and_run_scheme_string "output";;

(*REMOEVE LATER*)
let compile= Code_Generation.compile_scheme_string "output";;



(* 1 - end of list, 0 - success *)
let rec test_quadruple quadruples index = 
  match (quadruples, index) with
  | (q :: rest, 0) ->  (match q with
      | (r , p , s, c) -> (if (read r) = p then 
        (if (Tag_Parser.tag_parse p) = s then 
            (if (Semantic_Analysis.semantics s) = c then 0 else failwith ("failed semantics: "^ r))
        else failwith ("failed parse: "^ r))
                          else failwith ("failed read: "^r))
      | _ -> failwith "shouldnt happen, failed")
      
  | (q :: [], x) -> 1
  | (q::rest, x) -> (test_quadruple rest (index-1))
  | _ -> failwith "shouldnt happen";;

  (* use instruction:
     #use "compiler.ml";;
     #use "tests_hub/max_tests.ml";;
     test_all quadruples;; *)
  let test_all quadruples = 
    let rec run index = 
      match (test_quadruple quadruples index) with
       | 0 -> (run (index+1))
       | 1 -> "success"
       | _ -> "fail" in
    run 0
  ;;

