;;; kotlin-ts-mode.el --- A mode for editing Kotlin files based on tree-sitter

;; Author: Alex Figl-Brick <alex@alexbrick.me>
;; Package-Requires: ((emacs "29"))

;;; Commentary:

;;; Code:

(require 'treesit)

(defvar kotlin-ts-indent-offset 4)

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

;; Based on https://github.com/fwcd/tree-sitter-kotlin/pull/50
(defvar kotlin--treesit-settings
  (treesit-font-lock-rules
   :language 'kotlin
   :feature 'keyword
   '(
     ;; `it` keyword inside lambdas
     ;; FIXME: This will highlight the keyword outside of lambdas since tree-sitter
     ;;        does not allow us to check for arbitrary nestation
     ((simple_identifier) @font-lock-keyword-face (:equal @font-lock-keyword-face "it"))

     ;; `field` keyword inside property getter/setter
     ;; FIXME: This will highlight the keyword outside of getters and setters
     ;;        since tree-sitter does not allow us to check for arbitrary nestation
     ((simple_identifier) @font-lock-keyword-face (:equal @font-lock-keyword-face "field"))

     ;; `this` this keyword inside classes
     (this_expression "this") @font-lock-keyword-face

     ;; `super` keyword inside classes
     (super_expression) @font-lock-keyword-face

     ["val" "var" "enum" "class" "object" "interface"] @font-lock-keyword-face

     (package_header "package" @font-lock-keyword-face)

     (import_header "import" @font-lock-keyword-face)

     (type_alias "typealias" @font-lock-keyword-face)
     [
      (class_modifier)
      (member_modifier)
      (function_modifier)
      (property_modifier)
      (platform_modifier)
      (variance_modifier)
      (parameter_modifier)
      (visibility_modifier)
      (reification_modifier)
      (inheritance_modifier)
      ] @font-lock-keyword-face

     (companion_object "companion" @font-lock-keyword-face)
     (function_declaration "fun" @font-lock-keyword-face)

     (jump_expression ["throw" "return" "return@" "continue" "continue@" "break" "break@"] @font-lock-keyword-face)

     ["if" "else" "when"] @font-lock-keyword-face

     ["for" "do" "while" "in"] @font-lock-keyword-face

     ["try" "catch" "throw" "finally"] @font-lock-keyword-face

     (type_test "is" @font-lock-keyword-face)

     (prefix_expression "!" @font-lock-negation-char-face)
     )

   :language 'kotlin
   :feature 'comment
   '(
     [(comment) (shebang_line)] @font-lock-comment-face
     )

   :language 'kotlin
   :feature 'string
   '(
     (character_literal) @font-lock-string-face
     [(line_string_literal) (multi_line_string_literal)] @font-lock-string-face
     )

   :language 'kotlin
   :feature 'definition
   '(
     (function_declaration (simple_identifier) @font-lock-function-name-face)
     (parameter (simple_identifier) @font-lock-variable-name-face)
     (class_parameter (simple_identifier) @font-lock-variable-name-face)
     (variable_declaration (simple_identifier) @font-lock-variable-name-face)
     )

   :language 'kotlin
   :feature 'number
   '(
     [(integer_literal) (long_literal) (hex_literal) (bin_literal) (unsigned_literal) (real_literal)] @font-lock-number-face
     )

   :language 'kotlin
   :feature 'type
   '(
     (type_identifier) @font-lock-type-face
     (call_expression (simple_identifier) @font-lock-type-face
                      (:match "^[A-Z]" @font-lock-type-face))
     )

   :language 'kotlin
   :feature 'constant
   '(
     ["null" (boolean_literal)] @font-lock-constant-face
     )


   :language 'kotlin
   :feature 'builtin
   '(
     (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "listOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "arrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "arrayOfNulls"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "byteArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "shortArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "intArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "longArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "ubyteArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "ushortArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "uintArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "ulongArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "floatArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "doubleArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "booleanArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "charArrayOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptyArray"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mapOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "setOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "listOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptyMap"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptySet"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "emptyList"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mutableMapOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mutableSetOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "mutableListOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "print"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "println"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "error"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "TODO"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "run"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "runCatching"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "repeat"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "lazy"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "lazyOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "enumValues"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "enumValueOf"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "assert"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "check"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "checkNotNull"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "require"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "requireNotNull"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "with"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "suspend"))
	 (call_expression (simple_identifier) @font-lock-builtin-face
                      (:equal @font-lock-builtin-face "synchronized"))
     ))
   )

(defvar kotlin-ts--treesit-indent-rules
  (let ((offset kotlin-ts-indent-offset))
    `((kotlin
       ((node-is "}") parent-bol 0)
       ((node-is ")") parent-bol 0)
       ((parent-is "statements") parent-bol 0)
       ((parent-is "class_body") parent-bol ,offset)
       ((parent-is "control_structure_body") parent-bol ,offset)
       ((parent-is "function_body") parent-bol ,offset)
       ((parent-is "lambda_literal") parent-bol ,offset)
       ((parent-is "value_arguments") parent-bol ,offset)
       ))))

(define-derived-mode kotlin-ts-mode prog-mode "Kotlin"
  "Major mode for editing Kotlin using tree-sitter."
  (treesit-parser-create 'kotlin)

  (setq-local comment-start "//"
              comment-padding 1
              comment-start-skip "\\(//+\\|/\\*+\\)\\s *"
              comment-end "")

  ;; Syntax Highlighting
  (setq-local treesit-font-lock-settings kotlin--treesit-settings)
  (setq-local treesit-font-lock-feature-list '((comment number string definition)
                                               (class-name keyword builtin type constant)
                                               (string-interpolation decorator)))

  ;; Indent
  (setq-local treesit-simple-indent-rules kotlin-ts--treesit-indent-rules)

  (treesit-major-mode-setup)

  :syntax-table kotlin-mode-syntax-table
  )

(provide 'kotlin-ts-mode)
;;; kotlin-ts-mode.el ends here
