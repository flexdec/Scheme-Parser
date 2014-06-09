;;; Fichier : tp2.scm

;;; Ce programme est une version incomplete du TP2.  Vous devez uniquement
;;; changer et ajouter du code dans la premi�re section.

;;;----------------------------------------------------------------------------

;;; Vous devez modifier cette section.  La fonction "traiter" doit
;;; �tre d�finie, et vous pouvez ajouter des d�finitions de fonction
;;; afin de bien d�composer le traitement � faire en petites
;;; fonctions.  Il faut vous limiter au sous-ensemble *fonctionnel* de
;;; Scheme dans votre codage (donc n'utilisez pas set!, set-car!,
;;; begin, etc).

;;; La fonction traiter re�oit en param�tre une liste de caract�res
;;; contenant l'expression lue et retourne une liste de caract�res qui
;;; sera imprim�e comme r�sultat de l'expression entr�e.  Vos
;;; fonctions ne doivent pas faire d'affichage car c'est la fonction
;;; "go" qui se charge de cela.

(define (get-postscript sym)
  (cond ((eq? '+ sym)'add)
        ((eq? '- sym)'sub)
        ((eq? '* sym)'mul)
        ((eq? '/ sym)'div)))

(define (get-func sym)
  (cond ((eq? '+ sym)(lambda(x y)(+ x y)))
        ((eq? '- sym)(lambda(x y)(- x y)))
        ((eq? '/ sym)(lambda(x y)(/ x y)))
        ((eq? '* sym)(lambda(x y)(* x y)))))



;;List of operators
(define operators '(+ - / *))

;;Display errors
(define (display-error e)
  (cond
   ((eq? e 'ERROR_empty_expression)
    (string->list "Expression vide\n"))
   ((eq? e 'ERROR_syntax_error)
    (string->list "Erreur de syntaxe\n"))
   ((eq? e 'ERROR_unknown_char)
    (string->list "Caract�re inconnu\n"))))

;;'(('data. data)'('('lchild. leftchild)'('rchild . rightchild))
(define (make-node data children)
  (if (null? children)
      (list (cons 'data data)'())
      (list (cons 'data data)
            (list (cons 'lchild (car children))
                  (cons 'rchild (cadr children))))))

;;Get children
(define (get-children node)
  (if(not(null? node))(cdr node)))

;;Get data of a node
(define (get-data node)
  (let ((x (assoc 'data node)))
    (if (eq? #f x) '() (cdr x))))

;;Get left child of node
;;If node is empty, returns empty.
;;If node is a leaf and has no children, return empty
(define (get-lchild node)
  (if (null? node) '()
  (let ((x (assoc 'lchild (cadr node))))
    (if (eq? x #f) '() (cdr x)))))

;;Get right child of node
(define (get-rchild node)
  (if (null? node) '()
  (let ((x (assoc 'rchild(cadr node))))
    (if (eq? x #f) '() (cdr x)))))

;;Is node a leaf?
(define (leaf? node)
  (null? (car(get-children node))))

;;Get last two elements of list as a list
;;Used to get last two elements on the stack
(define (get-last-two liste)
  (let ((l (reverse liste)))
    (list (cadr l) (car l))))

(define (remove-last-two liste)
  (let ((l (reverse liste)))
        (reverse(cddr l))))

;;MAIN PARSING FUNCTION
(define (parse tree)
  (define (parse-helper chaine stack tree)
    (cond
     ((and (null? chaine) (not(= 1 (length stack)))) 'ERROR_syntax_error)
     (else (if (null? chaine)
               (car tree)
               (let((c (car chaine)))
                 (cond
                  ((null? c) (car tree))
                  ((number? c)
                   (parse-helper (cdr chaine)
                                 (append stack (list(make-node c '())))
                                 tree))
                  ((symbol? c)
                   (cond
                    ((< (length stack) 2) 'ERROR_syntax_error)
                    (else (parse-helper (cdr chaine)
                                        (append (remove-last-two stack)
                                                (list(make-node c (get-last-two stack))))
                                        (list(make-node c (get-last-two stack)))))))))))))
  (parse-helper tree '() '()))

(define (print-tree tree)
  (define (print-tree-help tree n)
    (print-spaces n)
    (display (get-data tree))
    (newline)
    (cond ((not(leaf? tree))
           (print-tree-help (get-rchild tree) (+ n 1))
           (print-tree-help (get-lchild tree) (+ n 1)))))
  (print-tree-help tree 0))

(define (print-spaces n)
  (cond ((= n 0))
        (else (display "  ")
              (print-spaces (- n 1)))))

(define (display-scheme tree)
  (define (display-scheme-helper tree str)
    (cond((not(leaf? tree))
          (string-append str " (" (symbol->string(get-data tree))
                         (display-scheme-helper (get-lchild tree) str)
                         (display-scheme-helper (get-rchild tree) str) ")"))
         (else
          (string-append str " " (number->string(get-data tree))))))
  (string->list(display-scheme-helper tree "")))

(define (inorder-traversal tree)
  (if(not(leaf? tree)) (inorder-traversal (get-lchild tree)))
  (display (get-data tree))
  (if(not(leaf? tree)) (inorder-traversal (get-rchild tree))))

(define (preorder-traversal tree)
  (display(get-data tree))
 (if(not(leaf? tree)) (preorder-traversal (get-lchild tree)))
 (if(not(leaf? tree)) (preorder-traversal (get-rchild tree))))

(define (postorder-traversal tree)
  (if(not(leaf? tree)) (postorder-traversal (get-lchild tree)))
  (if(not(leaf? tree)) (postorder-traversal (get-rchild tree)))
  (display (get-data tree)))

(define (preprocess input)
  (define (preprocess-helper input numbers output)
    (cond ((and (not(null? numbers))(null? input)) 'ERROR_syntax_error)
          ((and (null? input)(null? output)) 'ERROR_empty_expression)
          ((and (null? input)(null? numbers)(not(null? output))) output)
          (else
           (let ((digit (string->number (list->string(list(car input)))))
                 (num (string->number(list->string numbers)))
                 (sym (string->symbol(list->string(list(car input)))))
                 (numbers? (not(null? numbers))))
             (cond ((number? digit)
                    (preprocess-helper (cdr input)
                                (append numbers (list(car input)))
                                output))
                   ((eq? (car input) #\space)
                    (preprocess-helper (cdr input)
                                '()
                                (if numbers?
                                    (append output (list num))
                                    output)))
                   ((member sym operators)
                    (preprocess-helper (cdr input)
                                '()
                                (if numbers?
                                    (append output (list num) (list sym))
                                    (append output (list sym)))))
                   (else 'ERROR_unknown_char))))))
  (preprocess-helper input '() '()))

;;Get value of current tree
(define (get-value tree)
  (cond ((number? (get-data tree)) (get-data tree))
        (else ((get-func (get-data tree))
               (get-value (get-lchild tree))
               (get-value (get-rchild tree))))))

;;Returns a list rid of the specified item
(define delete
  (lambda (item list)
    (cond
     ((null? list) '())
     ((equal? item (car list)) (delete item (cdr list)))
     (else (cons (car list) (delete item (cdr list)))))))

;;TRAITER EXPRESSION
(define traiter
  (lambda (expr)
    (let((e (preprocess expr)))
      (if (symbol? e) ; preprocessing error
          (display-error e)
          (let((ee (parse e)))
            (cond ((symbol? ee) ; parsing error
                (display-error ee))
                  (else (print-tree ee)
                        (append (string->list "    Scheme: ")
                                (display-scheme ee)
                                '(#\newline)))))))))

;;;----------------------------------------------------------------------------
;;; Ne pas modifier cette section.

(define go
  (lambda ()
    (print "EXPRESSION? ")
    (let ((ligne (read-line)))
      (if (string? ligne)
          (begin
            (for-each write-char (traiter-ligne ligne))
            (go))))))

(define traiter-ligne
  (lambda (ligne)
    (traiter (string->list ligne))))

(go)

;;;----------------------------------------------------------------------------

;;TESTING
;;(print-tree (parse (preprocess (string->list "1 2 + 5 /"))))
;;(parse '())
(define tree1 (parse '(6 1 3 - 1 + 5 * /)))
(get-value tree1)
(display-scheme tree1)
;;(print (get-data tree1))
(print-tree tree1)
(define tree2 (parse '(1 3 +)))
;;(leaf? tree2)

;;(get-data(get-rchild tree2))
;;(get-rchild tree2)
;;(get-data tree2)
;;(parse '())
;;(leaf? tree2)
