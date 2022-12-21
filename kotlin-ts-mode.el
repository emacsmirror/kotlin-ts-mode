;;; kotlin-ts-mode.el --- A mode for editing Kotlin files based on tree-sitter

;;; Commentary:

;;; Code:

(require 'tree-sitter-hl)
(require 'tree-sitter-indent)

(defvar kotlin-mode-syntax-table
  (let ((st (make-syntax-table)))

    ;; Strings
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\' "\"" st)
    (modify-syntax-entry ?` "\"" st)

    ;; `_' and `@' as being a valid part of a symbol
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?@ "_" st)

    ;; b-style comment
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?* ". 23n" st)
    (modify-syntax-entry ?\n "> b" st)
    (modify-syntax-entry ?\r "> b" st)
    st))

(defconst kotlin-ts-mode-tree-sitter-patterns
  [

;; Operators
(type_parameters ["<" ">"] @punctuation.bracket)
(type_arguments ["<" ">"] @punctuation.bracket)
(indexing_suffix ["[" "]"] @punctuation.bracket)

[
 "+"
 "-"
 "*"
 "/"
 "%"
 "as"
 "as?"
 "++"
 "--"
 "!"
 "+="
 "-="
 "*="
 "/="
 "%="
 "!="
 "=="
 "<"
 ">"
 "<="
 ">="
 "&&"
 "||"
 "?:"
 ] @operator

(comment) @comment

;; Strings
(line_string_literal "${" @punctuation.embedded)
(line_string_literal "}" @punctuation.embedded)
(line_string_literal "$" @punctuation.embedded)
(line_string_literal) @string
(multi_line_string_literal) @string
(character_literal) @string
(character_escape_seq) @escape

;; Numbers
(real_literal) @number
(integer_literal) @number
(hex_literal) @number
(bin_literal) @number
(unsigned_literal) @number
(long_literal) @number

;; Boolean
(boolean_literal) @constant.builtin

;; Keywords
(constructor_delegation_call ["this" "super"] @type.super)
(for_statement ["for" "in"] @keyword)
(if_expression ["if" "else"] @keyword)
(import_alias "as" @keyword)
(import_header "import" @keyword)
(package_header "package" @keyword)
(parameter_modifier) @keyword
(super_expression "super" @type.super)
(this_expression "this" @type.super)
(visibility_modifier) @keyword
(while_statement "while" @keyword)
["break" "continue" "continue@" "return" "return@" "throw" "val" "var"] @keyword

;; Classes
(class_declaration ["class" "interface" "enum"] @keyword)
(class_declaration (type_identifier) @type)
(class_modifier "data" @keyword)
(class_parameter (simple_identifier) @variable.parameter)
(user_type) @type

;; Functions
(function_declaration "fun" @keyword (simple_identifier) @function)
(callable_reference (simple_identifier) @function.call)
(member_modifier) @keyword
(parameter (simple_identifier) @variable.parameter)
(call_expression (simple_identifier) @function.call)
(call_expression (navigation_expression (navigation_suffix (simple_identifier) @function.call)))
(navigation_suffix (simple_identifier) @property)

;; When
(when_expression "when" @keyword)
(when_entry "else" @keyword)
(when_entry "->" @punctuation)
   ]
  )

(defvar kotlin-indent-offset 4 "How far to indent in `kotlin-mode'.")

(defconst tree-sitter-indent-kotlin-scopes
  '((indent-body . (block)))
  )

(define-derived-mode kotlin-ts-mode prog-mode "Kotlin"
  "Major mode for editing Kotlin using tree-sitter."

  (setq-local comment-start "//"
              comment-padding 1
              comment-start-skip "\\(//+\\|/\\*+\\)\\s *"
              comment-end "")

  ;; Syntax Highlighting
  (setq-local tree-sitter-hl-default-patterns kotlin-ts-mode-tree-sitter-patterns)
  (tree-sitter-hl-mode)

  ;; Indentation
  (setq-local indent-line-function #'tree-sitter-indent-line)
  (tree-sitter-indent-mode)

  :syntax-table kotlin-mode-syntax-table
  )

(add-to-list 'tree-sitter-major-mode-language-alist '(kotlin-mode . kotlin))

(provide 'kotlin-ts-mode)
;;; kotlin-ts-mode.el ends here
